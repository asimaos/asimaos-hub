#pragma once

#include <QQmlEngine>
#include <QtQml/qqmlregistration.h>

#include <QCryptographicHash>
#include <QFile>
#include <QObject>
#include <QPointer>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>

class QNetworkAccessManager;
class QNetworkReply;

// Data and actions behind Asima Hub, the online app: it is never part of the Asima OS system
// image. Everything online lives here, so the system apps never go on the internet (asimaos
// docs/decisions.md, D2, D27 and D39).
//
// It reads one JSON feed (address: ASIMAOS_HUB_FEED at build time, or the ASIMAOS_HUB_FEED
// environment variable) and its detached signature, feed.json.sig, made with the feed key
// (feedcheck.h). A feed whose signature doesn't verify is refused as a whole:
//
//   { "format": 2,
//     "releases": [ { "version": "2026.12.01.1", "channel": "beta", "date": "2026-12-01", "notes": ["…"],
//                     "update": { "url": "https://…/asimaos-2026.12.01.1-x86_64.aosupd", "size": …, "sha256": "…" },
//                     "iso":    { "url": "https://…/asimaos-2026.12.01.1-x86_64.iso", "size": …, "sha256": "…" } } ],
//     "news":   [ { "date": "2026-12-01", "title": "…", "text": "…", "link": "https://…" } ],
//     "groups": [ { "id": "gaming", "title": "Gaming", "apps": [ { "id": "…", "from": "flathub" } ] } ],
//     "hub":    { "version": "0.2.0", "files": { "appimage": { "url": "…", "sha256": "…" } } },
//     "links":  { "guides": "https://…", "wiki": "https://…", "website": "https://…" },
//     "reports": { "email": "…" } }
//
// Downloads land in the Downloads folder, are checked against the feed's SHA-256 and handed to
// Asima Updater, which checks the release signature again before installing anything.
// Demo mode: a sample feed (design work, screenshots).
class HubEngine : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(Backend)
    QML_SINGLETON
    Q_PROPERTY(bool demo READ demo CONSTANT)
    Q_PROPERTY(QString installed READ installed CONSTANT)            // the running Asima OS version
    Q_PROPERTY(bool configured READ configured CONSTANT)             // a feed address is set
    Q_PROPERTY(QString feedState READ feedState NOTIFY feedChanged)  // loading | ok | error | unset
    Q_PROPERTY(QString feedError READ feedError NOTIFY feedChanged)
    // The newest release: { version, channel, date, size, notes, newer, url, sha256, iso } (empty
    // without a feed); iso: { url, size, sha256 } or empty.
    Q_PROPERTY(QVariantMap latest READ latest NOTIFY feedChanged)
    // Every release in the feed, newest first: { version, date, notes, current }.
    Q_PROPERTY(QVariantList releases READ releases NOTIFY feedChanged)
    // News, newest first: { date, title, text, link }.
    Q_PROPERTY(QVariantList news READ news NOTIFY feedChanged)
    // Guides, wiki, website: { id, title, detail, icon, url }.
    Q_PROPERTY(QVariantList links READ links NOTIFY feedChanged)
    // The update file's and the ISO's download: { active, received, total, done, file, error }
    Q_PROPERTY(QVariantMap download READ download NOTIFY downloadChanged)
    Q_PROPERTY(QVariantMap isoDownload READ isoDownload NOTIFY downloadChanged)
    // "What you'll get on this PC" (pccheck.h): items, and one line about them.
    Q_PROPERTY(QVariantList pcCheck READ pcCheck CONSTANT)
    Q_PROPERTY(QString pcSummary READ pcSummary CONSTANT)
    Q_PROPERTY(bool canSendReports READ canSendReports NOTIFY feedChanged)
    // { text, state ("" | mail | error), message }
    Q_PROPERTY(QVariantMap report READ report NOTIFY reportChanged)

public:
    // The one instance main() makes; QML gets it as the Backend singleton (known at build time,
    // so qmllint and the QML compiler see its properties).
    static inline HubEngine *instance = nullptr;
    static HubEngine *create(QQmlEngine *, QJSEngine *)
    {
        QJSEngine::setObjectOwnership(instance, QJSEngine::CppOwnership);
        return instance;
    }

    explicit HubEngine(bool demo, QObject *parent = nullptr);

    bool demo() const { return m_demo; }
    QString installed() const { return m_installed; }
    bool configured() const { return !m_feedUrl.isEmpty(); }
    QString feedState() const { return m_feedState; }
    QString feedError() const { return m_feedError; }
    QVariantMap latest() const { return m_latest; }
    QVariantList releases() const { return m_releases; }
    QVariantList news() const { return m_news; }
    QVariantList links() const { return m_links; }
    QVariantMap download() const { return m_download; }
    QVariantMap isoDownload() const { return m_isoDownload; }
    QVariantList pcCheck() const { return m_pcCheck; }
    QString pcSummary() const;
    bool canSendReports() const { return !m_reportEmail.isEmpty(); }
    QVariantMap report() const { return m_report; }
    // Read from the feed for the steps that come next (app groups, the Hub's own updates).
    QVariantList groups() const { return m_groups; }
    QVariantMap hubRelease() const { return m_hubRelease; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void downloadLatest();                // the update file
    Q_INVOKABLE void downloadIso();                   // the ISO, for a USB stick
    Q_INVOKABLE void cancelDownload();
    // The downloaded update straight to Asima Updater's service (io.github.asimaos.Updater1):
    // checked, installed with the administrator's password, progress in download.install*; where
    // the service can't be reached (another system, an older Flatpak), the file opens instead.
    Q_INVOKABLE void install();
    Q_INVOKABLE void openInUpdater();                 // opens the downloaded file with Asima Updater
    Q_INVOKABLE void restart();                       // after an install: restart into the new version
    Q_INVOKABLE void openLink(const QString &url);
    Q_INVOKABLE void loadReport(const QUrl &file);    // a report saved by Asima Maintenance
    Q_INVOKABLE void setReportText(const QString &text);
    Q_INVOKABLE void sendReport();                    // saves it and opens the mail app

    // Checks a feed against its signature with `key` and, when it verifies, takes it as the
    // current feed. The release server's feed and --check-feed (tests) both come through here.
    bool loadFeed(const QByteArray &data, const QByteArray &signature, const QByteArray &key, QString *error = nullptr);

    // Puts the demo into a state for screenshots: downloading, downloaded, iso-downloading,
    // iso-downloaded, empty, report, unset.
    void setDemoState(const QString &state);

    // "2026.12.01.1" > "2026.11.18.1"
    static int compareVersions(const QString &a, const QString &b);

public slots:
    // --check: the new-version notification's button (org.freedesktop.Notifications ActionInvoked).
    void onNotificationAction(uint id, const QString &action);
    // Asima Updater's job signals.
    void onJobProgress(const QString &job, double progress, const QString &step, const QString &detail);
    void onJobFinished(const QString &job, bool ok, const QString &message);

signals:
    void feedChanged();
    void downloadChanged();
    void reportChanged();
    void toast(const QString &message, const QString &tone);

private:
    void applyFeed(const QJsonObject &feed);
    void failFeed(const QString &message);
    void loadDemo();
    void startDownload(const QString &kind);          // "update" or "iso"
    QVariantMap &stateOf(const QString &kind);
    void setDownload(const QString &kind, const QVariantMap &changes);
    QString targetPath(const QString &kind, const QString &version) const;

    bool m_demo;
    QString m_installed, m_feedState, m_feedError, m_reportEmail, m_activeKind, m_job;
    QUrl m_feedUrl;
    QVariantMap m_latest, m_download, m_isoDownload, m_report, m_hubRelease;
    QVariantList m_releases, m_news, m_links, m_groups, m_pcCheck;
    QNetworkAccessManager *m_net = nullptr;
    QPointer<QNetworkReply> m_reply;
    QFile m_part;
    QCryptographicHash m_hash{QCryptographicHash::Sha256};
    QString m_expectedSha;
    qint64 m_expectedSize = 0;
};
