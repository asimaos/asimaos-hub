#include "usbwriter.h"

#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusMetaType>
#include <QDBusObjectPath>
#include <QDBusUnixFileDescriptor>
#include <QEventLoop>
#include <QFile>
#include <QLocale>
#include <QThread>

#include <cerrno>
#include <fcntl.h>
#include <unistd.h>

using InterfaceMap = QMap<QString, QVariantMap>;
using ObjectMap = QMap<QDBusObjectPath, InterfaceMap>;
Q_DECLARE_METATYPE(InterfaceMap)
Q_DECLARE_METATYPE(ObjectMap)

namespace {

const QString kUDisks = QStringLiteral("org.freedesktop.UDisks2");
const QString kBlock = QStringLiteral("org.freedesktop.UDisks2.Block");
const QString kDrive = QStringLiteral("org.freedesktop.UDisks2.Drive");
const QString kPartition = QStringLiteral("org.freedesktop.UDisks2.Partition");
const QString kFilesystem = QStringLiteral("org.freedesktop.UDisks2.Filesystem");
constexpr qint64 kChunk = 4 * 1024 * 1024;

ObjectMap managedObjects()
{
    qDBusRegisterMetaType<InterfaceMap>();
    qDBusRegisterMetaType<ObjectMap>();
    const QDBusMessage call = QDBusMessage::createMethodCall(kUDisks, QStringLiteral("/org/freedesktop/UDisks2"),
                                                             QStringLiteral("org.freedesktop.DBus.ObjectManager"),
                                                             QStringLiteral("GetManagedObjects"));
    const QDBusMessage reply = QDBusConnection::systemBus().call(call, QDBus::Block, 10000);
    if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty())
        return {};
    return qdbus_cast<ObjectMap>(reply.arguments().first());
}

QString drivePathOf(const InterfaceMap &object)
{
    return object.value(kBlock).value(QStringLiteral("Drive")).value<QDBusObjectPath>().path();
}

bool mounted(const InterfaceMap &object)
{
    // MountPoints is an array of byte strings: mounted when it has one.
    QDBusArgument points = object.value(kFilesystem).value(QStringLiteral("MountPoints")).value<QDBusArgument>();
    if (points.currentType() != QDBusArgument::ArrayType)
        return false;
    bool any = false;
    points.beginArray();
    while (!points.atEnd()) {
        QByteArray point;
        points >> point;
        any = any || !point.isEmpty();
    }
    points.endArray();
    return any;
}

QString sizeText(qint64 bytes)
{
    return QLocale().formattedDataSize(bytes, 0, QLocale::DataSizeSIFormat);
}

// Whole disks only (not their partitions), and only USB or removable drives with media that can be
// written; never one UDisks counts as part of the system. `drive` names the physical drive (its
// model and serial number), so a different disk under the same device name is told apart.
QVariantList usbDrives(const ObjectMap &objects)
{
    QVariantList list;
    for (auto it = objects.begin(); it != objects.end(); ++it) {
        const InterfaceMap &o = it.value();
        if (!o.contains(kBlock) || o.contains(kPartition))
            continue;
        const QVariantMap block = o.value(kBlock);
        const QString drivePath = drivePathOf(o);
        const QVariantMap drive = objects.value(QDBusObjectPath(drivePath)).value(kDrive);
        const bool usb = drive.value(QStringLiteral("ConnectionBus")).toString() == QLatin1String("usb");
        const bool removable = drive.value(QStringLiteral("Removable")).toBool() || drive.value(QStringLiteral("MediaRemovable")).toBool();
        const qint64 size = block.value(QStringLiteral("Size")).toLongLong();
        if (drive.isEmpty() || !(usb || removable) || size <= 0 || block.value(QStringLiteral("HintSystem")).toBool()
            || block.value(QStringLiteral("ReadOnly")).toBool())
            continue;
        const QString name = (drive.value(QStringLiteral("Vendor")).toString() + QLatin1Char(' ')
                              + drive.value(QStringLiteral("Model")).toString()).trimmed();
        const QString device = QString::fromLocal8Bit(block.value(QStringLiteral("Device")).toByteArray()).remove(QChar(0));
        list.append(QVariantMap{{"id", it.key().path()},
                                {"drive", drivePath},
                                {"name", name.isEmpty() ? QCoreApplication::translate("UsbWriter", "USB stick") : name},
                                {"detail", device + QStringLiteral(" · ") + sizeText(size)},
                                {"size", double(size)}});
    }
    return list;
}

} // namespace

UsbWriter::UsbWriter(bool demo, QObject *parent)
    : QObject(parent)
    , m_demo(demo)
    , m_testTarget(qEnvironmentVariable("ASIMAOS_HUB_TEST_TARGET"))
{
    refreshDrives();
}

UsbWriter::~UsbWriter()
{
    if (m_thread) {
        m_cancel = true;
        m_thread->wait();
    }
}

void UsbWriter::refreshDrives()
{
    m_drives.clear();
    if (m_demo) {
        m_drives = {QVariantMap{{"id", "demo-1"}, {"name", "SanDisk Cruzer Blade"}, {"detail", "/dev/sdb · 4 GB"}, {"size", 4e9}},
                    QVariantMap{{"id", "demo-2"}, {"name", "Kingston DataTraveler"}, {"detail", "/dev/sdc · 64 GB"}, {"size", 64e9}}};
    } else if (!m_testTarget.isEmpty()) {
        m_drives = {QVariantMap{{"id", "test"}, {"name", tr("Test target (a file)")}, {"detail", m_testTarget}, {"size", 64e9}}};
    } else {
        m_drives = usbDrives(managedObjects());
    }
    emit drivesChanged();
}

void UsbWriter::setState(const QString &state, double progress, const QString &message)
{
    m_state = state;
    m_progress = progress;
    m_message = message;
    emit stateChanged();
}

// The stick, opened for writing: the test file, or the device through UDisks after its partitions
// are unmounted (UDisks asks for the administrator's password). It must still be the stick that
// was listed: a stick pulled out and another disk plugged in under its name is never written.
int UsbWriter::openTarget(const QString &driveId, QString *error)
{
    if (!m_testTarget.isEmpty()) {
        const int fd = ::open(QFile::encodeName(m_testTarget).constData(), O_RDWR | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
        if (fd < 0)
            *error = tr("The test target can't be opened.");
        return fd;
    }
    const ObjectMap objects = managedObjects();
    QVariantMap listed;
    for (const QVariant &v : std::as_const(m_drives))
        if (v.toMap().value(QStringLiteral("id")).toString() == driveId)
            listed = v.toMap();
    bool same = false;
    for (const QVariant &v : usbDrives(objects)) {
        const QVariantMap now = v.toMap();
        same = same || (!listed.isEmpty() && now.value(QStringLiteral("id")) == listed.value(QStringLiteral("id"))
                        && now.value(QStringLiteral("drive")) == listed.value(QStringLiteral("drive"))
                        && now.value(QStringLiteral("size")) == listed.value(QStringLiteral("size")));
    }
    if (!same) {
        *error = tr("The stick is gone or has changed. Press \"Look again\" and choose it again.");
        return -1;
    }
    const QString drive = listed.value(QStringLiteral("drive")).toString();
    for (auto it = objects.begin(); it != objects.end(); ++it) {
        if (drivePathOf(it.value()) != drive || !mounted(it.value()))
            continue;
        QDBusMessage unmount = QDBusMessage::createMethodCall(kUDisks, it.key().path(), kFilesystem, QStringLiteral("Unmount"));
        unmount << QVariantMap();
        if (QDBusConnection::systemBus().call(unmount, QDBus::BlockWithGui, 120000).type() != QDBusMessage::ReplyMessage) {
            *error = tr("The stick is in use. Close the files and apps that use it, then try again.");
            return -1;
        }
    }
    QDBusMessage open = QDBusMessage::createMethodCall(kUDisks, driveId, kBlock, QStringLiteral("OpenDevice"));
    open << QStringLiteral("rw") << QVariantMap{{QStringLiteral("flags"), int(O_EXCL | O_CLOEXEC)}};
    const QDBusMessage reply = QDBusConnection::systemBus().call(open, QDBus::BlockWithGui, 300000);
    if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty()) {
        // Refused or cancelled at the password, or busy (something still holds the stick).
        *error = reply.errorName().startsWith(QLatin1String("org.freedesktop.UDisks2.Error.NotAuthorized"))
            ? tr("Writing to the stick needs the administrator's password.")
            : tr("The stick is in use. Close the files and apps that use it, then try again.");
        return -1;
    }
    const int fd = ::dup(reply.arguments().first().value<QDBusUnixFileDescriptor>().fileDescriptor());
    if (fd < 0)
        *error = tr("The stick can't be opened.");
    return fd;
}

void UsbWriter::write(const QString &driveId, const QString &isoFile, const QString &sha256)
{
    if (m_thread || m_state == QLatin1String("writing") || m_state == QLatin1String("verifying"))
        return;
    if (m_demo) {
        setDemoState(QStringLiteral("writing"));
        return;
    }
    if (!QFile::exists(isoFile) || sha256.size() != 64) {
        setState(QStringLiteral("error"), 0, tr("Download Asima OS first: only a checked download is written."));
        return;
    }
    QString error;
    const int fd = openTarget(driveId, &error);
    if (fd < 0) {
        setState(QStringLiteral("error"), 0, error);
        return;
    }
    m_cancel = false;
    m_target = driveId;
    setState(QStringLiteral("writing"), 0, tr("Writing Asima OS to the stick…"));
    m_thread = QThread::create([this, fd, isoFile, sha256] { run(fd, isoFile, sha256); });
    connect(m_thread, &QThread::finished, this, [this] {
        m_thread->deleteLater();
        m_thread = nullptr;
    });
    m_thread->start();
}

void UsbWriter::cancel()
{
    m_cancel = true;
}

// On its own thread: write the ISO, flush it to the stick, then read the stick back and compare.
void UsbWriter::run(int fd, const QString &isoFile, const QString &sha256)
{
    const auto report = [this](const QString &state, double progress, const QString &message) {
        QMetaObject::invokeMethod(this, [=, this] { setState(state, progress, message); }, Qt::QueuedConnection);
    };
    const auto finish = [&](const QString &state, const QString &message) {
        ::close(fd);
        report(state, state == QLatin1String("done") ? 1.0 : 0.0, message);
    };
    QFile iso(isoFile);
    if (!iso.open(QIODevice::ReadOnly))
        return finish(QStringLiteral("error"), tr("The downloaded ISO can't be read."));
    const qint64 total = iso.size();
    QCryptographicHash written(QCryptographicHash::Sha256);
    qint64 done = 0;
    while (!iso.atEnd()) {
        if (m_cancel)
            return finish(QStringLiteral("error"), tr("Stopped. The stick is incomplete: write it again before using it."));
        const QByteArray chunk = iso.read(kChunk);
        if (chunk.isEmpty())
            return finish(QStringLiteral("error"), tr("The downloaded ISO can't be read."));
        for (qint64 off = 0; off < chunk.size();) {
            const ssize_t n = ::write(fd, chunk.constData() + off, size_t(chunk.size() - off));
            if (n < 0 && errno == EINTR)
                continue;
            if (n <= 0)
                return finish(QStringLiteral("error"), tr("Writing stopped: the stick may be full, faulty or unplugged."));
            off += n;
        }
        written.addData(chunk);
        done += chunk.size();
        report(QStringLiteral("writing"), double(done) / total, tr("Writing Asima OS to the stick…"));
    }
    if (::fsync(fd) != 0)
        return finish(QStringLiteral("error"), tr("Writing stopped: the stick may be full, faulty or unplugged."));
    if (QString::fromLatin1(written.result().toHex()).compare(sha256, Qt::CaseInsensitive) != 0)
        return finish(QStringLiteral("error"), tr("The ISO in Downloads has changed since it was checked. Download it again."));

    // Read back from the stick itself, not from memory.
    ::posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
    if (::lseek(fd, 0, SEEK_SET) != 0)
        return finish(QStringLiteral("error"), tr("The stick can't be read back."));
    QCryptographicHash readBack(QCryptographicHash::Sha256);
    QByteArray buffer(kChunk, Qt::Uninitialized);
    for (qint64 left = total; left > 0;) {
        if (m_cancel)
            return finish(QStringLiteral("error"), tr("Stopped. The stick is incomplete: write it again before using it."));
        const ssize_t n = ::read(fd, buffer.data(), size_t(qMin(left, kChunk)));
        if (n < 0 && errno == EINTR)
            continue;
        if (n <= 0)
            return finish(QStringLiteral("error"), tr("The stick can't be read back."));
        readBack.addData(QByteArrayView(buffer.constData(), n));
        left -= n;
        report(QStringLiteral("verifying"), double(total - left) / total, tr("Checking what is on the stick…"));
    }
    if (QString::fromLatin1(readBack.result().toHex()).compare(sha256, Qt::CaseInsensitive) != 0)
        return finish(QStringLiteral("error"), tr("The stick doesn't hold what was written: it may be faulty. Try another stick."));
    finish(QStringLiteral("done"), tr("Ready. Start the PC from the stick: switch it on, press its boot-menu key (often F12, F11, F8 or Esc) and choose the stick."));
}

void UsbWriter::setDemoState(const QString &state)
{
    m_target = QStringLiteral("demo-2");
    if (state == QLatin1String("writing"))
        setState(QStringLiteral("writing"), 0.37, tr("Writing Asima OS to the stick…"));
    else if (state == QLatin1String("written"))
        setState(QStringLiteral("done"), 1.0,
                 tr("Ready. Start the PC from the stick: switch it on, press its boot-menu key (often F12, F11, F8 or Esc) and choose the stick."));
}

int UsbWriter::writeAndWait(const QString &driveId, const QString &isoFile, const QString &sha256)
{
    const auto ended = [this] { return m_state == QLatin1String("done") || m_state == QLatin1String("error"); };
    QEventLoop loop;
    connect(this, &UsbWriter::stateChanged, &loop, [&] {
        if (ended())
            loop.quit();
    });
    write(driveId, isoFile, sha256);
    if (!ended())
        loop.exec();
    while (m_thread)
        QCoreApplication::processEvents(QEventLoop::AllEvents, 50);
    return m_state == QLatin1String("done") ? 0 : 1;
}
