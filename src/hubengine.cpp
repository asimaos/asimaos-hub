#include "hubengine.h"
#include "feedcheck.h"
#include "pccheck.h"

#include <QCoreApplication>
#include <QProcess>

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusUnixFileDescriptor>
#include <QDate>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QUrlQuery>

#include <algorithm>
#include <memory>

#ifndef ASIMAOS_HUB_FEED
#define ASIMAOS_HUB_FEED ""
#endif

namespace {

// The running Asima OS: inside a Flatpak the host's os-release is at /run/host.
QString runningVersion()
{
    for (const QString &path : {QStringLiteral("/run/host/os-release"), QStringLiteral("/etc/os-release"),
                                QStringLiteral("/usr/lib/os-release")}) {
        QFile f(path);
        if (!f.open(QIODevice::ReadOnly))
            continue;
        const QString text = QString::fromUtf8(f.readAll());
        if (!text.contains(QLatin1String("ID=asimaos")))
            continue;
        const QRegularExpressionMatch m = QRegularExpression(QStringLiteral("^IMAGE_VERSION=\"?([0-9.]+)"),
                                                             QRegularExpression::MultilineOption).match(text);
        if (m.hasMatch())
            return m.captured(1);
    }
    return {};
}

QString niceDate(const QString &iso)
{
    const QDate d = QDate::fromString(iso, Qt::ISODate);
    return d.isValid() ? QLocale().toString(d, QLocale::LongFormat) : iso;
}

} // namespace

HubEngine::HubEngine(bool demo, QObject *parent)
    : QObject(parent)
    , m_demo(demo)
{
    m_download = QVariantMap{{"active", false}, {"received", 0.0}, {"total", 0.0}, {"done", false}, {"file", QString()}, {"error", QString()}};
    m_isoDownload = m_download;
    m_report = QVariantMap{{"text", QString()}, {"state", QString()}, {"message", QString()}};
    if (m_demo) {
        loadDemo();
        return;
    }
    m_pcCheck = PcCheck::run();
    m_installed = runningVersion();
    const QString feed = qEnvironmentVariableIsSet("ASIMAOS_HUB_FEED") ? qEnvironmentVariable("ASIMAOS_HUB_FEED")
                                                                      : QStringLiteral(ASIMAOS_HUB_FEED);
    m_feedUrl = QUrl(feed);
    if (!m_feedUrl.isValid() || m_feedUrl.scheme() != QLatin1String("https"))
        m_feedUrl = QUrl();
    m_net = new QNetworkAccessManager(this);
    m_feedState = m_feedUrl.isEmpty() ? QStringLiteral("unset") : QString();
    refresh();
}

int HubEngine::compareVersions(const QString &a, const QString &b)
{
    const QStringList x = a.split(QLatin1Char('.')), y = b.split(QLatin1Char('.'));
    for (int i = 0; i < qMax(x.size(), y.size()); ++i) {
        const int p = x.value(i).toInt(), q = y.value(i).toInt();
        if (p != q)
            return p < q ? -1 : 1;
    }
    return 0;
}

void HubEngine::refresh()
{
    if (m_demo || m_feedUrl.isEmpty())
        return;
    m_feedState = QStringLiteral("loading");
    emit feedChanged();
    // The feed, then its signature (feed.json.sig next to it); nothing is used until both are here
    // and the signature verifies with the feed key built into Asima Hub.
    QNetworkRequest req(m_feedUrl);
    req.setTransferTimeout(30000);
    QNetworkReply *reply = m_net->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            failFeed(tr("The release server could not be reached. Check the internet connection."));
            return;
        }
        const QByteArray data = reply->readAll();
        QUrl sigUrl = m_feedUrl;
        sigUrl.setPath(m_feedUrl.path() + QStringLiteral(".sig"));
        QNetworkRequest sigReq(sigUrl);
        sigReq.setTransferTimeout(30000);
        QNetworkReply *sigReply = m_net->get(sigReq);
        connect(sigReply, &QNetworkReply::finished, this, [this, sigReply, data] {
            sigReply->deleteLater();
            QString error;
            if (sigReply->error() != QNetworkReply::NoError)
                failFeed(tr("The release server's news aren't signed, so Asima Hub doesn't show them."));
            else if (!loadFeed(data, sigReply->readAll(), FeedCheck::feedKey(), &error))
                failFeed(error);
        });
    });
}

bool HubEngine::loadFeed(const QByteArray &data, const QByteArray &signature, const QByteArray &key, QString *error)
{
    const auto fail = [error](const QString &message) {
        if (error)
            *error = message;
        return false;
    };
    if (!FeedCheck::verify(data, signature, key))
        return fail(tr("The release server's news aren't signed by Asima OS, so Asima Hub doesn't show them."));
    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(data, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject() || doc.object().value("format").toInt() != 2)
        return fail(tr("The release server sent something this version of Asima Hub doesn't understand. Update Asima Hub."));
    applyFeed(doc.object());
    return true;
}

void HubEngine::failFeed(const QString &message)
{
    m_feedState = QStringLiteral("error");
    m_feedError = message;
    emit feedChanged();
}

namespace {
// A file the feed points to: an https address, a size and a SHA-256, or nothing.
QVariantMap fileEntry(const QJsonObject &o)
{
    const QUrl url(o.value("url").toString());
    const QString sha = o.value("sha256").toString().toLower();
    static const QRegularExpression hexRx(QStringLiteral("^[0-9a-f]{64}$"));
    if (!url.isValid() || url.scheme() != QLatin1String("https") || !hexRx.match(sha).hasMatch())
        return {};
    return QVariantMap{{"url", url.toString()}, {"size", o.value("size").toDouble()}, {"sha256", sha}};
}
} // namespace

void HubEngine::applyFeed(const QJsonObject &feed)
{
    QJsonArray releases = feed.value("releases").toArray();
    QList<QJsonObject> list;
    static const QRegularExpression versionRx(QStringLiteral("^\\d{4}\\.\\d{2}\\.\\d{2}\\.\\d+$"));
    for (const QJsonValue &v : releases) {
        const QJsonObject r = v.toObject();
        if (versionRx.match(r.value("version").toString()).hasMatch())
            list.append(r);
    }
    std::sort(list.begin(), list.end(), [](const QJsonObject &a, const QJsonObject &b) {
        return compareVersions(a.value("version").toString(), b.value("version").toString()) > 0;
    });
    m_releases.clear();
    for (const QJsonObject &r : list) {
        m_releases.append(QVariantMap{
            {"version", r.value("version").toString()},
            {"date", niceDate(r.value("date").toString())},
            {"notes", r.value("notes").toArray().toVariantList()},
            {"current", r.value("version").toString() == m_installed},
        });
    }
    m_latest.clear();
    if (!list.isEmpty()) {
        const QJsonObject r = list.first();
        const QString version = r.value("version").toString();
        const QVariantMap update = fileEntry(r.value("update").toObject());
        m_latest = QVariantMap{
            {"version", version},
            {"channel", r.value("channel").toString()},
            {"date", niceDate(r.value("date").toString())},
            {"size", update.value("size").toDouble()},
            {"notes", r.value("notes").toArray().toVariantList()},
            {"newer", m_installed.isEmpty() || compareVersions(version, m_installed) > 0},
            {"url", update.value("url").toString()},
            {"sha256", update.value("sha256").toString()},
            {"iso", fileEntry(r.value("iso").toObject())},
        };
        // Downloaded before: ready to install.
        if (QFileInfo::exists(targetPath(QStringLiteral("update"), version)) && !m_download.value("active").toBool())
            m_download.insert({{"done", true}, {"file", targetPath(QStringLiteral("update"), version)},
                               {"received", m_latest.value("size")}, {"total", m_latest.value("size")}});
        const QVariantMap iso = m_latest.value("iso").toMap();
        if (!iso.isEmpty() && QFileInfo::exists(targetPath(QStringLiteral("iso"), version)) && !m_isoDownload.value("active").toBool())
            m_isoDownload.insert({{"done", true}, {"file", targetPath(QStringLiteral("iso"), version)},
                                  {"received", iso.value("size")}, {"total", iso.value("size")}});
        emit downloadChanged();
    }
    const QJsonObject links = feed.value("links").toObject();
    m_links.clear();
    const auto addLink = [&](const QString &id, const QString &title, const QString &detail, const QString &icon) {
        const QUrl url(links.value(id).toString());
        if (url.isValid() && url.scheme() == QLatin1String("https"))
            m_links.append(QVariantMap{{"id", id}, {"title", title}, {"detail", detail}, {"icon", icon}, {"url", url.toString()}});
    };
    addLink(QStringLiteral("guides"), tr("Setup and usage guides"), tr("Step by step: the first start, backups, Secure Boot, Android apps, gaming"), QStringLiteral("help-contents"));
    addLink(QStringLiteral("wiki"), tr("Wiki"), tr("Answers for everything else, written by the people who use Asima OS"), QStringLiteral("documentation"));
    addLink(QStringLiteral("website"), tr("Website"), tr("News and the Asima OS downloads"), QStringLiteral("applications-internet"));
    // News, newest first.
    QList<QJsonObject> news;
    for (const QJsonValue &v : feed.value("news").toArray()) {
        const QJsonObject n = v.toObject();
        if (QDate::fromString(n.value("date").toString(), Qt::ISODate).isValid() && !n.value("title").toString().isEmpty())
            news.append(n);
    }
    std::sort(news.begin(), news.end(), [](const QJsonObject &a, const QJsonObject &b) {
        return a.value("date").toString() > b.value("date").toString();
    });
    m_news.clear();
    for (const QJsonObject &n : news) {
        const QUrl link(n.value("link").toString());
        m_news.append(QVariantMap{{"date", niceDate(n.value("date").toString())}, {"title", n.value("title").toString()},
                                  {"text", n.value("text").toString()},
                                  {"link", link.isValid() && link.scheme() == QLatin1String("https") ? link.toString() : QString()}});
    }
    // For the next steps: the app groups (installed by Asima Manager's service) and the Hub's own
    // newest version (Windows and the AppImage update themselves from it).
    m_groups = feed.value("groups").toArray().toVariantList();
    m_hubRelease = feed.value("hub").toObject().toVariantMap();
    static const QRegularExpression mailRx(QStringLiteral("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"));
    const QString email = feed.value("reports").toObject().value("email").toString().trimmed();
    m_reportEmail = mailRx.match(email).hasMatch() ? email : QString();
    m_feedState = QStringLiteral("ok");
    m_feedError.clear();
    emit feedChanged();
}

QString HubEngine::targetPath(const QString &kind, const QString &version) const
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    const QString name = kind == QLatin1String("iso") ? QStringLiteral("asimaos-%1-x86_64.iso") : QStringLiteral("asimaos-%1-x86_64.aosupd");
    return QDir(dir.isEmpty() ? QDir::homePath() : dir).filePath(name.arg(version));
}

QVariantMap &HubEngine::stateOf(const QString &kind)
{
    return kind == QLatin1String("iso") ? m_isoDownload : m_download;
}

void HubEngine::setDownload(const QString &kind, const QVariantMap &changes)
{
    QVariantMap &state = stateOf(kind);
    for (auto it = changes.begin(); it != changes.end(); ++it)
        state.insert(it.key(), it.value());
    emit downloadChanged();
}

void HubEngine::downloadLatest()
{
    startDownload(QStringLiteral("update"));
}

void HubEngine::downloadIso()
{
    startDownload(QStringLiteral("iso"));
}

// The update file or the ISO: one download at a time, into the Downloads folder, resumed where it
// stopped, and kept only when its SHA-256 matches the signed feed.
void HubEngine::startDownload(const QString &kind)
{
    if (m_demo) {
        setDemoState(kind == QLatin1String("iso") ? QStringLiteral("iso-downloading") : QStringLiteral("downloading"));
        return;
    }
    if (m_latest.isEmpty() || m_reply)
        return;
    const QVariantMap entry = kind == QLatin1String("iso") ? m_latest.value("iso").toMap() : m_latest;
    const QUrl url(entry.value("url").toString());
    m_expectedSha = entry.value("sha256").toString();
    m_expectedSize = qint64(entry.value("size").toDouble());
    if (!url.isValid() || url.scheme() != QLatin1String("https") || m_expectedSha.size() != 64) {
        emit toast(tr("The release server lists this file without a safe address or checksum."), QStringLiteral("error"));
        return;
    }
    m_activeKind = kind;
    const QString target = targetPath(kind, m_latest.value("version").toString());
    m_part.setFileName(target + QStringLiteral(".part"));
    m_hash.reset();
    QNetworkRequest req(url);
    // A download that was cut off continues where it stopped (the part so far is hashed again).
    qint64 have = 0;
    if (m_part.exists() && m_part.open(QIODevice::ReadOnly)) {
        while (!m_part.atEnd())
            m_hash.addData(m_part.read(1 << 20));
        have = m_part.size();
        m_part.close();
        req.setRawHeader("Range", "bytes=" + QByteArray::number(have) + "-");
    }
    if (!m_part.open(QIODevice::Append)) {
        emit toast(tr("The Downloads folder can't be written to."), QStringLiteral("error"));
        return;
    }
    setDownload(kind, {{"active", true}, {"done", false}, {"error", QString()}, {"received", double(have)},
                       {"total", double(m_expectedSize)}, {"file", QString()}});
    m_reply = m_net->get(req);
    connect(m_reply, &QNetworkReply::metaDataChanged, this, [this, kind, have] {
        // The server ignored the range: start from the beginning.
        if (have > 0 && m_reply && m_reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() == 200) {
            m_part.resize(0);
            m_hash.reset();
            setDownload(kind, {{"received", 0.0}});
        }
    });
    connect(m_reply, &QNetworkReply::readyRead, this, [this, kind] {
        const QByteArray data = m_reply->readAll();
        m_part.write(data);
        m_hash.addData(data);
        setDownload(kind, {{"received", double(m_part.size())}});
    });
    connect(m_reply, &QNetworkReply::finished, this, [this, kind, target] {
        const bool cancelled = m_reply->error() == QNetworkReply::OperationCanceledError;
        const bool failed = m_reply->error() != QNetworkReply::NoError;
        m_reply->deleteLater();
        m_reply = nullptr;
        m_part.close();
        if (cancelled) {
            setDownload(kind, {{"active", false}});
            return;
        }
        if (failed) {
            setDownload(kind, {{"active", false}, {"error", tr("The download stopped. It continues where it stopped when you try again.")}});
            return;
        }
        const QString sha = QString::fromLatin1(m_hash.result().toHex());
        if (sha != m_expectedSha || (m_expectedSize > 0 && m_part.size() != m_expectedSize)) {
            m_part.remove();
            setDownload(kind, {{"active", false}, {"error", tr("The download was damaged and has been deleted. Try again.")}});
            return;
        }
        QFile::remove(target);
        m_part.rename(target);
        setDownload(kind, {{"active", false}, {"done", true}, {"file", target}});
        emit toast(kind == QLatin1String("iso") ? tr("Downloaded and checked. Write it to a USB stick next.")
                                                : tr("Downloaded and checked. Install it with Asima Updater."),
                   QStringLiteral("ok"));
    });
}

void HubEngine::cancelDownload()
{
    if (m_demo) {
        setDownload(QStringLiteral("update"), {{"active", false}, {"received", 0.0}});
        setDownload(QStringLiteral("iso"), {{"active", false}, {"received", 0.0}});
        return;
    }
    if (m_reply)
        m_reply->abort();
}

namespace {
const QString kUpdater = QStringLiteral("io.github.asimaos.Updater1");
const QString kUpdaterPath = QStringLiteral("/io/github/asimaos/Updater1");
}

void HubEngine::install()
{
    if (m_demo) {
        setDemoState(QStringLiteral("installing"));
        return;
    }
    auto file = std::make_shared<QFile>(m_download.value("file").toString());
    if (!file->open(QIODevice::ReadOnly)) {
        setDownload(QStringLiteral("update"), {{"done", false}, {"error", tr("The downloaded file is gone. Download it again.")}});
        return;
    }
    setDownload(QStringLiteral("update"), {{"error", QString()}, {"install", "checking"}, {"installProgress", 0.0},
                                            {"installStep", tr("Asima Updater checks the update…")}});
    const auto call = [file](const QString &method) {
        QDBusMessage m = QDBusMessage::createMethodCall(kUpdater, kUpdaterPath, kUpdater, method);
        m << QVariant::fromValue(QDBusUnixFileDescriptor(file->handle()));
        return QDBusConnection::systemBus().asyncCall(m, 600000);
    };
    // Checked first, without a password: signature, newer than this version, not expired, space.
    auto *check = new QDBusPendingCallWatcher(call(QStringLiteral("VerifyUpdate")), this);
    connect(check, &QDBusPendingCallWatcher::finished, this, [this, call, check] {
        check->deleteLater();
        const QDBusPendingReply<QString> checked = *check;
        if (checked.isError()) {
            // No Asima Updater service here (another system, or a Hub without the permission):
            // the file opens in whatever handles it.
            setDownload(QStringLiteral("update"), {{"install", QString()}});
            openInUpdater();
            return;
        }
        const QJsonObject report = QJsonDocument::fromJson(checked.value().toUtf8()).object();
        if (!report.value("ok").toBool()) {
            const QString why = report.value("problems").toArray().first().toString();
            setDownload(QStringLiteral("update"), {{"install", QString()},
                                                    {"error", why.isEmpty() ? tr("Asima Updater refused this update.") : why}});
            return;
        }
        QDBusConnection::systemBus().connect(kUpdater, kUpdaterPath, kUpdater, QStringLiteral("JobProgress"), this,
                                             SLOT(onJobProgress(QString,double,QString,QString)));
        QDBusConnection::systemBus().connect(kUpdater, kUpdaterPath, kUpdater, QStringLiteral("JobFinished"), this,
                                             SLOT(onJobFinished(QString,bool,QString)));
        // The service asks for the administrator's password (polkit) and returns the job at once.
        setDownload(QStringLiteral("update"), {{"installStep", tr("Waiting for the administrator's password…")}});
        auto *apply = new QDBusPendingCallWatcher(call(QStringLiteral("ApplyUpdate")), this);
        connect(apply, &QDBusPendingCallWatcher::finished, this, [this, apply] {
            apply->deleteLater();
            const QDBusPendingReply<QString> job = *apply;
            if (job.isError()) {
                setDownload(QStringLiteral("update"), {{"install", QString()}, {"error", job.error().message()}});
                return;
            }
            m_job = job.value();
            setDownload(QStringLiteral("update"), {{"install", "installing"}, {"installProgress", 0.02}, {"installStep", tr("Starting…")}});
        });
    });
}

void HubEngine::onJobProgress(const QString &job, double progress, const QString &step, const QString &detail)
{
    if (job != m_job)
        return;
    setDownload(QStringLiteral("update"), {{"installProgress", progress},
                                            {"installStep", step == QLatin1String("write") && !detail.isEmpty() ? detail : tr("Installing…")}});
}

void HubEngine::onJobFinished(const QString &job, bool ok, const QString &message)
{
    if (job != m_job)
        return;
    m_job.clear();
    if (ok)
        setDownload(QStringLiteral("update"), {{"install", "installed"}, {"installProgress", 1.0}});
    else
        setDownload(QStringLiteral("update"), {{"install", QString()}, {"error", message + QLatin1Char(' ') + tr("Nothing was changed.")}});
}

void HubEngine::openInUpdater()
{
    const QString file = m_download.value("file").toString();
    // Asima Updater opens .aosupd files: it checks the signature and installs.
    if (m_demo || !QDesktopServices::openUrl(QUrl::fromLocalFile(file)))
        emit toast(tr("Opens the update in Asima Updater."), QStringLiteral("info"));
}

void HubEngine::restart()
{
    if (m_demo) {
        emit toast(tr("Demo mode: the computer would restart now."), QStringLiteral("info"));
        return;
    }
    QDBusInterface login(QStringLiteral("org.freedesktop.login1"), QStringLiteral("/org/freedesktop/login1"),
                         QStringLiteral("org.freedesktop.login1.Manager"), QDBusConnection::systemBus());
    const QDBusMessage r = login.call(QStringLiteral("Reboot"), true);
    if (r.type() == QDBusMessage::ErrorMessage)
        emit toast(tr("Restart the computer to start the new version."), QStringLiteral("info"));
}

void HubEngine::openLink(const QString &url)
{
    if (m_demo || !QDesktopServices::openUrl(QUrl(url)))
        emit toast(tr("Opens %1 in the web browser.").arg(QUrl(url).host()), QStringLiteral("info"));
}

void HubEngine::loadReport(const QUrl &file)
{
    QFile f(file.isLocalFile() ? file.toLocalFile() : file.toString());
    if (!f.open(QIODevice::ReadOnly) || f.size() > 4 * 1024 * 1024) {
        emit toast(tr("That file can't be opened as a problem report."), QStringLiteral("error"));
        return;
    }
    setReportText(QString::fromUtf8(f.readAll()));
}

void HubEngine::setReportText(const QString &text)
{
    m_report.insert("text", text);
    m_report.insert("state", QString());
    emit reportChanged();
}

void HubEngine::sendReport()
{
    const QString text = m_report.value("text").toString().trimmed();
    if (text.isEmpty() || m_reportEmail.isEmpty())
        return;
    // The report is saved next to the downloads, and the mail app opens with the project's address
    // filled in: the person attaches the file and sends it themselves (D39).
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    const QString name = QStringLiteral("asimaos-problem-report-%1.txt")
                             .arg(QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd-HHmm")));
    const QString file = QDir(dir.isEmpty() ? QDir::homePath() : dir).filePath(name);
    if (!m_demo) {
        QFile f(file);
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate) || f.write(text.toUtf8()) < 0) {
            m_report.insert("state", "error");
            m_report.insert("message", tr("The report could not be saved in the Downloads folder."));
            emit reportChanged();
            return;
        }
        f.close();
        QUrl mail(QStringLiteral("mailto:") + m_reportEmail);
        QUrlQuery query;
        query.addQueryItem(QStringLiteral("subject"), tr("Asima OS problem report (%1)")
                                                          .arg(m_installed.isEmpty() ? tr("version unknown") : m_installed));
        query.addQueryItem(QStringLiteral("body"), tr("The report is attached: %1").arg(name));
        mail.setQuery(query);
        QDesktopServices::openUrl(mail);
    }
    m_report.insert("state", "mail");
    m_report.insert("message", tr("Your mail app opens with the address filled in. Attach the report, saved as %1 in Downloads, and send it.")
                                   .arg(name));
    emit reportChanged();
}

// ───────────────────────────────────────────────────────────────────────── demo

QString HubEngine::pcSummary() const
{
    return PcCheck::summary(m_pcCheck);
}

void HubEngine::loadDemo()
{
    m_pcCheck = PcCheck::demo();
    m_installed = QStringLiteral("2026.11.18.1");
    const QJsonObject feed = QJsonDocument::fromJson(R"({
      "format": 2,
      "releases": [
        { "version": "2026.12.01.1", "channel": "beta", "date": "2026-12-01",
          "notes": ["KDE Plasma 6.8.4 and Linux 7.3.9", "Android apps start twice as fast",
                    "Asima Maintenance can restore a backup into a new folder"],
          "update": { "url": "https://example.invalid/asimaos-2026.12.01.1-x86_64.aosupd", "size": 3612344320,
                      "sha256": "0000000000000000000000000000000000000000000000000000000000000000" },
          "iso": { "url": "https://example.invalid/asimaos-2026.12.01.1-x86_64.iso", "size": 4617089024,
                   "sha256": "1111111111111111111111111111111111111111111111111111111111111111" } },
        { "version": "2026.11.18.1", "channel": "beta", "date": "2026-11-18",
          "notes": ["Snap, Nix and Android apps (Waydroid) for everyone", "TPM unlock only for genuine Asima OS boot images",
                    "The start menu shows each version's number"] },
        { "version": "2026.11.16.2", "channel": "beta", "date": "2026-11-16",
          "notes": ["Health checks before a start counts as good", "Secure Boot with a Microsoft-signed shim"] }
      ],
      "news": [
        { "date": "2026-12-01", "title": "Asima OS 2026.12.01.1 is out",
          "text": "Plasma 6.8.4, faster Android apps and backups restored into a new folder.",
          "link": "https://github.com/asimaos/asimaos" },
        { "date": "2026-11-25", "title": "Asima Hub on Windows",
          "text": "Soon you can check your PC, download Asima OS and write the USB stick from Windows too." }
      ],
      "links": { "guides": "https://example.invalid/guides", "wiki": "https://example.invalid/wiki",
                 "website": "https://example.invalid/" },
      "reports": { "email": "reports@example.invalid" }
    })").object();
    applyFeed(feed);
}

void HubEngine::setDemoState(const QString &state)
{
    const double total = m_latest.value("size").toDouble();
    if (state == QLatin1String("downloading")) {
        setDownload(QStringLiteral("update"), {{"active", true}, {"received", total * 0.42}, {"total", total}, {"done", false}});
    } else if (state == QLatin1String("downloaded")) {
        setDownload(QStringLiteral("update"), {{"active", false}, {"received", total}, {"total", total}, {"done", true},
                     {"file", QStringLiteral("~/Downloads/asimaos-2026.12.01.1-x86_64.aosupd")}});
    } else if (state == QLatin1String("installing") || state == QLatin1String("installed")) {
        setDemoState(QStringLiteral("downloaded"));
        const bool done = state == QLatin1String("installed");
        setDownload(QStringLiteral("update"), {{"install", done ? "installed" : "installing"}, {"installProgress", done ? 1.0 : 0.46},
                                                {"installStep", tr("Writing the system image: 1.5 of 3.2 GB")}});
    } else if (state == QLatin1String("report")) {
        setReportText(QStringLiteral("# Asima OS problem report\n\nVersion 2026.11.18.1 · Secure Boot on\n\n## Health check\n\n"
                                     "ok   system-files\nok   boot: 2026.11.18.1\nFAIL services: bluetooth.service\n\n"
                                     "## Errors since this start\n\n[   12.410213] bluetoothd[812]: Failed to set mode: Failed (0x03)\n"));
    } else if (state == QLatin1String("iso-downloading") || state == QLatin1String("iso-downloaded")) {
        const double iso = m_latest.value("iso").toMap().value("size").toDouble();
        const bool done = state == QLatin1String("iso-downloaded");
        setDownload(QStringLiteral("iso"), {{"active", !done}, {"received", done ? iso : iso * 0.61}, {"total", iso}, {"done", done},
                                            {"file", done ? QStringLiteral("~/Downloads/asimaos-2026.12.01.1-x86_64.iso") : QString()}});
    } else if (state == QLatin1String("writing") || state == QLatin1String("written")) {
        setDemoState(QStringLiteral("iso-downloaded"));   // a stick is written only from a checked download
    } else if (state == QLatin1String("empty")) {
        // A feed with news but no published version yet.
        m_latest.clear();
        m_releases.clear();
        emit feedChanged();
    } else if (state == QLatin1String("unset")) {
        m_feedUrl = QUrl();
        m_feedState = QStringLiteral("unset");
        m_latest.clear();
        m_releases.clear();
        m_links.clear();
        m_news.clear();
        m_reportEmail.clear();
        emit feedChanged();
    }
}

void HubEngine::onNotificationAction(uint, const QString &action)
{
    if (action == QLatin1String("open") || action == QLatin1String("default"))
        QProcess::startDetached(QCoreApplication::applicationFilePath(), {});
    QCoreApplication::quit();
}
