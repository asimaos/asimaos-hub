#include "pccheck.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QLocale>
#include <QRegularExpression>
#include <QSysInfo>

namespace {

QString root(const QString &path)
{
    return qEnvironmentVariable("ASIMAOS_HUB_TEST_SYSROOT") + path;
}

QByteArray readAll(const QString &path)
{
    QFile f(root(path));
    return f.open(QIODevice::ReadOnly) ? f.readAll() : QByteArray();
}

QString readLine(const QString &path)
{
    return QString::fromLatin1(readAll(path)).trimmed();
}

QVariantMap item(const QString &id, const QString &title, const QString &value, const QString &tone,
                 const QString &detail, bool blocks = false)
{
    return {{"id", id}, {"title", title}, {"value", value}, {"tone", tone}, {"detail", detail}, {"blocks", blocks}};
}

// Disks in the makers' units (1 TB = 10^12 bytes), memory in the usual ones (16 GB = 16 × 2^30).
QString gb(qint64 bytes)
{
    return QLocale().formattedDataSize(bytes, 0, QLocale::DataSizeSIFormat);
}

QString ram(qint64 bytes)
{
    return QLocale().formattedDataSize(bytes, 0, QLocale::DataSizeTraditionalFormat);
}

QVariantMap architecture()
{
    const QString arch = qEnvironmentVariable("ASIMAOS_HUB_TEST_ARCH", QSysInfo::currentCpuArchitecture());
    if (arch == QLatin1String("x86_64"))
        return item("arch", QCoreApplication::translate("PcCheck", "Processor"), QCoreApplication::translate("PcCheck", "64-bit"), "ok", QCoreApplication::translate("PcCheck", "Asima OS runs on it."));
    return item("arch", QCoreApplication::translate("PcCheck", "Processor"), arch, "error",
                QCoreApplication::translate("PcCheck", "Asima OS runs only on 64-bit PCs with an Intel or AMD processor (x86_64)."), true);
}

QVariantMap startMode()
{
    if (QFileInfo::exists(root("/sys/firmware/efi")))
        return item("uefi", QCoreApplication::translate("PcCheck", "Start mode"), QCoreApplication::translate("PcCheck", "UEFI"), "ok", QCoreApplication::translate("PcCheck", "Asima OS starts the modern way."));
    // Legacy BIOS only when the firmware's tables can be read: a container shows an empty
    // /sys/firmware, and a sandbox none at all.
    if (QFileInfo::exists(root("/sys/firmware/acpi")) || QFileInfo::exists(root("/sys/firmware/dmi")))
        return item("uefi", QCoreApplication::translate("PcCheck", "Start mode"), QCoreApplication::translate("PcCheck", "Legacy BIOS"), "error",
                    QCoreApplication::translate("PcCheck", "Asima OS needs a UEFI start. Most PCs can switch: in the firmware settings, turn off "
                       "\"CSM\" or \"Legacy\" and choose \"UEFI\"."), true);
    return item("uefi", QCoreApplication::translate("PcCheck", "Start mode"), QCoreApplication::translate("PcCheck", "Can't be read here"), "info",
                QCoreApplication::translate("PcCheck", "Asima OS needs a UEFI start, which most PCs made since 2012 have. The installer checks it."));
}

QVariantMap secureBoot()
{
    // The firmware's SecureBoot variable (EFI global variable GUID): 4 bytes of attributes, then 1
    // when it is on.
    const QString var = QStringLiteral("/sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c");
    if (!QFileInfo::exists(root(var)))
        return item("secureboot", QCoreApplication::translate("PcCheck", "Secure Boot"), QCoreApplication::translate("PcCheck", "Can't be read here"), "info",
                    QCoreApplication::translate("PcCheck", "Either way Asima OS starts. With Secure Boot on, you approve the Asima OS key once, on a blue screen."));
    const QByteArray v = readAll(var);
    if (v.size() >= 5 && v.at(4) == 1)
        return item("secureboot", QCoreApplication::translate("PcCheck", "Secure Boot"), QCoreApplication::translate("PcCheck", "On"), "ok",
                    QCoreApplication::translate("PcCheck", "You approve the Asima OS key once, on a blue screen; then only signed drivers load."));
    return item("secureboot", QCoreApplication::translate("PcCheck", "Secure Boot"), QCoreApplication::translate("PcCheck", "Off"), "info",
                QCoreApplication::translate("PcCheck", "Asima OS starts as it is. Drivers are not locked down until Secure Boot is on."));
}

QVariantMap tpm()
{
    // tpm_version_major needs Linux 5.6; the resource manager (tpmrm0) exists only for TPM 2.0.
    if (readLine("/sys/class/tpm/tpm0/tpm_version_major") == QLatin1String("2") || QFileInfo::exists(root("/sys/class/tpmrm/tpmrm0")))
        return item("tpm", QCoreApplication::translate("PcCheck", "Security chip"), QCoreApplication::translate("PcCheck", "TPM 2.0"), "ok",
                    QCoreApplication::translate("PcCheck", "The disk can unlock by itself at each start, once you switch that on."));
    return item("tpm", QCoreApplication::translate("PcCheck", "Security chip"), QCoreApplication::translate("PcCheck", "No TPM 2.0"), "info",
                QCoreApplication::translate("PcCheck", "Everything works; the disk asks for its passphrase at each start."));
}

QVariantMap memory()
{
    const QRegularExpressionMatch m = QRegularExpression(QStringLiteral("MemTotal:\\s+(\\d+) kB"))
                                          .match(QString::fromLatin1(readAll("/proc/meminfo")));
    if (!m.hasMatch())
        return item("memory", QCoreApplication::translate("PcCheck", "Memory"), QCoreApplication::translate("PcCheck", "Can't be read here"), "info", QCoreApplication::translate("PcCheck", "4 GB or more is recommended."));
    // MemTotal is what is left after the firmware and the graphics take their share: a 4 GB PC
    // shows about 3.3–3.9 GB.
    const qint64 bytes = m.captured(1).toLongLong() * 1024;
    if (bytes >= qint64(3200) * 1024 * 1024)
        return item("memory", QCoreApplication::translate("PcCheck", "Memory"), ram(bytes), "ok", QCoreApplication::translate("PcCheck", "Enough for the desktop, apps and games."));
    return item("memory", QCoreApplication::translate("PcCheck", "Memory"), ram(bytes), "warn", QCoreApplication::translate("PcCheck", "Asima OS works, but slowly: 4 GB or more is recommended."));
}

QVariantMap disk()
{
    // The biggest fixed disk; USB sticks, card readers and virtual disks of the system don't count.
    static const QRegularExpression skip(QStringLiteral("^(loop|ram|zram|sr|fd|dm-|md|nbd)"));
    qint64 best = 0;
    QString bestName;
    for (const QString &name : QDir(root("/sys/block")).entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        if (skip.match(name).hasMatch() || readLine("/sys/block/" + name + "/removable") == QLatin1String("1"))
            continue;
        const qint64 bytes = readLine("/sys/block/" + name + "/size").toLongLong() * 512;
        if (bytes > best) {
            best = bytes;
            bestName = name;
        }
    }
    if (bestName.isEmpty())
        return item("disk", QCoreApplication::translate("PcCheck", "Disk"), QCoreApplication::translate("PcCheck", "Can't be read here"), "info",
                    QCoreApplication::translate("PcCheck", "Asima OS needs a disk of at least 48 GB. The installer checks it."));
    if (best >= qint64(48) * 1000 * 1000 * 1000)
        return item("disk", QCoreApplication::translate("PcCheck", "Disk"), gb(best), "ok",
                    QCoreApplication::translate("PcCheck", "Asima OS takes the whole disk you choose in the installer: back up first, or use a second disk."));
    return item("disk", QCoreApplication::translate("PcCheck", "Disk"), gb(best), "error",
                QCoreApplication::translate("PcCheck", "Asima OS needs a disk of at least 48 GB; a second, bigger disk works too."), true);
}

QVariantMap graphics()
{
    QStringList kinds;
    bool known = false;
    QString tone = QStringLiteral("ok");
    QString detail = QCoreApplication::translate("PcCheck", "The desktop and games run at full speed.");
    const QString pci = QStringLiteral("/sys/bus/pci/devices");
    for (const QString &dev : QDir(root(pci)).entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        if (!readLine(pci + "/" + dev + "/class").startsWith(QLatin1String("0x03")))
            continue;
        const QString vendor = readLine(pci + "/" + dev + "/vendor");
        const int device = readLine(pci + "/" + dev + "/device").toInt(nullptr, 16);
        if (vendor == QLatin1String("0x10de")) {
            // GTX 16xx / RTX 20xx (Turing) and newer get NVIDIA's own driver.
            if (device >= 0x1e00) {
                kinds << QStringLiteral("NVIDIA");
            } else {
                kinds << QCoreApplication::translate("PcCheck", "Older NVIDIA");
                tone = QStringLiteral("warn");
                detail = QCoreApplication::translate("PcCheck", "Older NVIDIA cards (before GTX 16xx / RTX 20xx) run the desktop well, and games more slowly.");
            }
        } else if (vendor == QLatin1String("0x1002")) {
            kinds << QStringLiteral("AMD");
        } else if (vendor == QLatin1String("0x8086")) {
            kinds << QStringLiteral("Intel");
        } else {
            kinds << QCoreApplication::translate("PcCheck", "Other");
            continue;
        }
        known = true;
    }
    if (!kinds.isEmpty() && !known) {
        // A virtual machine's or an unusual card.
        tone = QStringLiteral("info");
        detail = QCoreApplication::translate("PcCheck", "The desktop works; games need an AMD, Intel or NVIDIA card.");
    }
    if (kinds.isEmpty())
        return item("graphics", QCoreApplication::translate("PcCheck", "Graphics"), QCoreApplication::translate("PcCheck", "Can't be read here"), "info",
                    QCoreApplication::translate("PcCheck", "AMD, Intel and NVIDIA graphics all work."));
    kinds.removeDuplicates();
    return item("graphics", QCoreApplication::translate("PcCheck", "Graphics"), kinds.join(QStringLiteral(" + ")), tone, detail);
}

} // namespace

QVariantList PcCheck::run()
{
    return {architecture(), startMode(), secureBoot(), tpm(), memory(), disk(), graphics()};
}

QVariantList PcCheck::demo()
{
    return {
        item("arch", QCoreApplication::translate("PcCheck", "Processor"), QCoreApplication::translate("PcCheck", "64-bit"), "ok",
             QCoreApplication::translate("PcCheck", "Asima OS runs on it.")),
        item("uefi", QCoreApplication::translate("PcCheck", "Start mode"), QCoreApplication::translate("PcCheck", "UEFI"), "ok",
             QCoreApplication::translate("PcCheck", "Asima OS starts the modern way.")),
        item("secureboot", QCoreApplication::translate("PcCheck", "Secure Boot"), QCoreApplication::translate("PcCheck", "On"), "ok",
             QCoreApplication::translate("PcCheck", "You approve the Asima OS key once, on a blue screen; then only signed drivers load.")),
        item("tpm", QCoreApplication::translate("PcCheck", "Security chip"), QCoreApplication::translate("PcCheck", "No TPM 2.0"), "info",
             QCoreApplication::translate("PcCheck", "Everything works; the disk asks for its passphrase at each start.")),
        item("memory", QCoreApplication::translate("PcCheck", "Memory"), ram(qint64(16) << 30), "ok",
             QCoreApplication::translate("PcCheck", "Enough for the desktop, apps and games.")),
        item("disk", QCoreApplication::translate("PcCheck", "Disk"), gb(qint64(1000) * 1000 * 1000 * 1000), "ok",
             QCoreApplication::translate("PcCheck", "Asima OS takes the whole disk you choose in the installer: back up first, or use a second disk.")),
        item("graphics", QCoreApplication::translate("PcCheck", "Graphics"), QStringLiteral("NVIDIA"), "ok",
             QCoreApplication::translate("PcCheck", "The desktop and games run at full speed.")),
    };
}

QString PcCheck::summary(const QVariantList &items)
{
    QStringList fix;
    for (const QVariant &v : items)
        if (v.toMap().value("blocks").toBool())
            fix << v.toMap().value("title").toString().toLower();
    if (fix.isEmpty())
        return QCoreApplication::translate("PcCheck", "Asima OS will run on this PC. What each part means is below.");
    return QCoreApplication::translate("PcCheck", "To install Asima OS, fix this first: %1. Everything else is below.").arg(fix.join(QStringLiteral(", ")));
}
