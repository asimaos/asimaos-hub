// Asima Hub: the online app (update downloads, guides and the wiki, what's new, problem reports).
// A Flatpak or AppImage, never part of the Asima OS system image.

#include "asimaosui.h"
#include "feedcheck.h"
#include "hubengine.h"
#include "pccheck.h"
#include "usbwriter.h"

#include <QCommandLineParser>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusVariant>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>
#include <QQmlApplicationEngine>
#include <QtQml/qqmlextensionplugin.h>

Q_IMPORT_QML_PLUGIN(Asima_UiPlugin)

namespace {
// At sign-in Asima Hub looks for a new version and says so in a notification, once per
// version. In a Flatpak the Background portal starts it (the person agrees once); as an AppImage
// an autostart entry does.
void askToCheckAtSignIn()
{
    QSettings settings;
    if (settings.value(QStringLiteral("checkAtSignIn")).toBool())
        return;
    if (QFileInfo::exists(QStringLiteral("/.flatpak-info"))) {
        QDBusMessage m = QDBusMessage::createMethodCall(QStringLiteral("org.freedesktop.portal.Desktop"),
                                                        QStringLiteral("/org/freedesktop/portal/desktop"),
                                                        QStringLiteral("org.freedesktop.portal.Background"),
                                                        QStringLiteral("RequestBackground"));
        m << QString() << QVariantMap{{QStringLiteral("reason"), QObject::tr("Tell you when a new Asima OS version is out")},
                                      {QStringLiteral("autostart"), true},
                                      {QStringLiteral("commandline"), QStringList{QStringLiteral("asimaos-hub"), QStringLiteral("--check")}}};
        QDBusConnection::sessionBus().asyncCall(m);
    } else {
        const QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/autostart");
        QDir().mkpath(dir);
        QFile f(dir + QStringLiteral("/io.github.asimaos.Hub-check.desktop"));
        if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
            f.write(QStringLiteral("[Desktop Entry]\nType=Application\nName=Asima Hub: new versions\nExec=%1 --check\n"
                                   "NoDisplay=true\nX-KDE-autostart-phase=2\n").arg(QCoreApplication::applicationFilePath()).toUtf8());
    }
    settings.setValue(QStringLiteral("checkAtSignIn"), true);
}

// --check: read the feed; a newer version not announced yet gets one notification, whose button
// opens Asima Hub. Then it quits.
int checkForNewVersion(QGuiApplication &app, HubEngine &backend)
{
    QObject::connect(&backend, &HubEngine::feedChanged, &app, [&app, &backend] {
        if (backend.feedState() == QLatin1String("loading"))
            return;
        const QVariantMap latest = backend.latest();
        const QString version = latest.value(QStringLiteral("version")).toString();
        QSettings settings;
        if (!latest.value(QStringLiteral("newer")).toBool() || settings.value(QStringLiteral("announced")).toString() == version) {
            app.quit();
            return;
        }
        settings.setValue(QStringLiteral("announced"), version);
        QDBusMessage m = QDBusMessage::createMethodCall(QStringLiteral("org.freedesktop.Notifications"),
                                                        QStringLiteral("/org/freedesktop/Notifications"),
                                                        QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("Notify"));
        m << QStringLiteral("Asima Hub") << 0u << QStringLiteral("io.github.asimaos.Hub")
          << QObject::tr("Asima OS %1 is available").arg(version)
          << QObject::tr("Download it in Asima Hub; Asima Updater checks and installs it.")
          << QStringList{QStringLiteral("default"), QObject::tr("Open Asima Hub"), QStringLiteral("open"), QObject::tr("Open Asima Hub")}
          << QVariantMap{{QStringLiteral("desktop-entry"), QStringLiteral("io.github.asimaos.Hub")}} << -1;
        QDBusConnection::sessionBus().call(m);
        // The button opens Asima Hub; without a click this ends after ten minutes.
        QDBusConnection::sessionBus().connect(QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("/org/freedesktop/Notifications"),
                                              QStringLiteral("org.freedesktop.Notifications"), QStringLiteral("ActionInvoked"), &backend,
                                              SLOT(onNotificationAction(uint,QString)));
        QTimer::singleShot(10 * 60 * 1000, &app, &QCoreApplication::quit);
    });
    if (!backend.configured())
        return 0;
    backend.refresh();
    return app.exec();
}
// --check-feed FILE: checks FILE against FILE.sig like a feed from the release server and prints, as
// one JSON line, what Asima Hub reads from it (tests; the release step's own check).
int checkFeedFile(HubEngine &engine, const QString &path, const QByteArray &key)
{
    QFile feed(path), sig(path + QStringLiteral(".sig"));
    QString error;
    QJsonObject out;
    if (!feed.open(QIODevice::ReadOnly) || !sig.open(QIODevice::ReadOnly)) {
        error = QStringLiteral("the feed or its .sig can't be read");
    } else if (engine.loadFeed(feed.readAll(), sig.readAll(), key, &error)) {
        const QVariantMap latest = engine.latest();
        out = QJsonObject{{"ok", true},
                          {"latest", latest.value("version").toString()},
                          {"update", latest.value("url").toString()},
                          {"iso", latest.value("iso").toMap().value("url").toString()},
                          {"releases", int(engine.releases().size())},
                          {"news", int(engine.news().size())},
                          {"groups", int(engine.groups().size())},
                          {"reports", engine.canSendReports()},
                          {"hub", engine.hubRelease().value("version").toString()}};
    }
    if (out.isEmpty())
        out = QJsonObject{{"ok", false}, {"error", error}};
    QTextStream(stdout) << QJsonDocument(out).toJson(QJsonDocument::Compact) << '\n';
    return out.value("ok").toBool() ? 0 : 1;
}
} // namespace

int main(int argc, char *argv[])
{
    AsimaUi::preApplicationSetup();
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("asimaos-hub"));
    app.setApplicationDisplayName(QStringLiteral("Asima Hub"));
    app.setApplicationVersion(QStringLiteral(ASIMAOS_HUB_VERSION));
    app.setOrganizationDomain(QStringLiteral("asimaos.github.io"));
    app.setDesktopFileName(QStringLiteral("io.github.asimaos.Hub"));
    AsimaUi::applicationSetup();

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Asima Hub"));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption demoOpt(QStringLiteral("demo"), QStringLiteral("Show a sample release feed."));
    const QCommandLineOption themeOpt(QStringLiteral("theme"), QStringLiteral("system, light or dark."), QStringLiteral("mode"), QStringLiteral("system"));
    const QCommandLineOption pageOpt(QStringLiteral("page"), QStringLiteral("Page to open."), QStringLiteral("page"), QStringLiteral("updates"));
    const QCommandLineOption stateOpt(QStringLiteral("state"), QStringLiteral("Demo state (screenshots)."), QStringLiteral("state"));
    const QCommandLineOption sizeOpt(QStringLiteral("size"), QStringLiteral("Window size WxH."), QStringLiteral("size"));
    const QCommandLineOption delayOpt(QStringLiteral("delay"), QStringLiteral("Screenshot delay in ms."), QStringLiteral("ms"), QStringLiteral("1800"));
    const QCommandLineOption shotOpt(QStringLiteral("screenshot"), QStringLiteral("Render the window to a PNG and quit."), QStringLiteral("file"));
    const QCommandLineOption checkOpt(QStringLiteral("check"), QStringLiteral("Look for a new version and notify, without a window."));
    const QCommandLineOption checkFeedOpt(QStringLiteral("check-feed"),
                                          QStringLiteral("Check a feed file against FILE.sig and print what Asima Hub reads from it."),
                                          QStringLiteral("file"));
    const QCommandLineOption feedKeyOpt(QStringLiteral("feed-key"), QStringLiteral("With --check-feed: a feed key's public half, in hex."),
                                        QStringLiteral("hex"));
    const QCommandLineOption pcCheckOpt(QStringLiteral("pc-check"), QStringLiteral("Print \"What you'll get on this PC\" as JSON."));
    const QCommandLineOption writeTestOpt(QStringLiteral("write-test"),
                                          QStringLiteral("Write ISO (its SHA-256 in --sha256) to ASIMAOS_HUB_TEST_TARGET and check it."),
                                          QStringLiteral("iso"));
    const QCommandLineOption shaOpt(QStringLiteral("sha256"), QStringLiteral("With --write-test: the ISO's SHA-256."), QStringLiteral("hex"));
    parser.addOptions({demoOpt, themeOpt, pageOpt, stateOpt, sizeOpt, shotOpt, delayOpt, checkOpt, checkFeedOpt, feedKeyOpt,
                       pcCheckOpt, writeTestOpt, shaOpt});
    parser.process(app);

    if (parser.isSet(pcCheckOpt)) {
        const QVariantList items = PcCheck::run();
        const QJsonObject out{{"summary", PcCheck::summary(items)}, {"items", QJsonArray::fromVariantList(items)}};
        QTextStream(stdout) << QJsonDocument(out).toJson(QJsonDocument::Compact) << '\n';
        return 0;
    }
    if (parser.isSet(writeTestOpt)) {
        if (qEnvironmentVariableIsEmpty("ASIMAOS_HUB_TEST_TARGET")) {
            QTextStream(stderr) << "--write-test writes only to ASIMAOS_HUB_TEST_TARGET\n";
            return 2;
        }
        UsbWriter writer(false);
        const int rc = writer.writeAndWait(QStringLiteral("test"), parser.value(writeTestOpt), parser.value(shaOpt));
        const QJsonObject out{{"ok", rc == 0}, {"state", writer.state()}, {"message", writer.message()}};
        QTextStream(stdout) << QJsonDocument(out).toJson(QJsonDocument::Compact) << '\n';
        return rc;
    }

    if (parser.isSet(checkFeedOpt)) {
        qputenv("ASIMAOS_HUB_FEED", QByteArray());   // only the given file, never the release server
        HubEngine engine(false);
        const QByteArray key = parser.isSet(feedKeyOpt) ? QByteArray::fromHex(parser.value(feedKeyOpt).toLatin1()) : FeedCheck::feedKey();
        return checkFeedFile(engine, parser.value(checkFeedOpt), key);
    }

    HubEngine backend(parser.isSet(demoOpt));
    if (parser.isSet(checkOpt)) {
        app.setQuitOnLastWindowClosed(false);
        return checkForNewVersion(app, backend);
    }
    if (!parser.isSet(demoOpt) && !parser.isSet(shotOpt) && backend.configured())
        askToCheckAtSignIn();
    UsbWriter writer(parser.isSet(demoOpt));
    if (parser.isSet(demoOpt) && parser.isSet(stateOpt)) {
        backend.setDemoState(parser.value(stateOpt));
        writer.setDemoState(parser.value(stateOpt));
    }

    QQmlApplicationEngine engine;
    AsimaUi::install(&engine);
    HubEngine::instance = &backend;
    UsbWriter::instance = &writer;
    engine.setInitialProperties({
        {QStringLiteral("startPage"), parser.value(pageOpt)},
        {QStringLiteral("themeMode"), parser.value(themeOpt)},
    });
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule("AsimaHub", "Main");
    if (engine.rootObjects().isEmpty())
        return 1;
    AsimaUi::finishWindow(&engine, parser.value(sizeOpt), parser.value(shotOpt), parser.value(delayOpt).toInt());
    return app.exec();
}
