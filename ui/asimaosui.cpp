#include "asimaosui.h"
#include "iconprovider.h"

#include <QFont>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>
#include <QTranslator>

namespace {

// Source strings are English and mark regular plurals as "%n file(s)". Without a translation
// file Qt would show the "(s)" literally, so this translator (installed first, so any real
// translation loaded later takes precedence) turns it into "1 file" / "2 files".
class EnglishPlurals : public QTranslator
{
public:
    using QTranslator::QTranslator;
    bool isEmpty() const override { return false; }
    QString translate(const char *, const char *sourceText, const char *, int n) const override
    {
        if (n < 0 || !sourceText)
            return {};
        QString text = QString::fromUtf8(sourceText);
        if (!text.contains(QLatin1String("(s)")))
            return {};
        return text.replace(QLatin1String("(s)"), n == 1 ? QString() : QStringLiteral("s"));
    }
};

} // namespace

namespace AsimaUi {

void preApplicationSetup()
{
    // All Asima OS controls are drawn by Asima UI itself; "Basic" is the neutral base style.
    QQuickStyle::setStyle(QStringLiteral("Basic"));
}

void applicationSetup()
{
    // On Asima OS (KDE Plasma) the platform theme provides Breeze. Elsewhere, fall back to it.
    if (QIcon::themeName().isEmpty() || QIcon::themeName() == QLatin1String("hicolor"))
        QIcon::setThemeName(QStringLiteral("breeze"));
    // Without a desktop platform theme (Asima Rescue on the framebuffer, linuxfb) Qt searches only
    // its own resources for icon themes: add the system's icon folders.
    QStringList iconPaths = QIcon::themeSearchPaths();
    const QStringList dataDirs = qEnvironmentVariable("XDG_DATA_DIRS", QStringLiteral("/usr/local/share:/usr/share"))
                                     .split(QLatin1Char(':'), Qt::SkipEmptyParts);
    for (const QString &dir : dataDirs)
        if (!iconPaths.contains(dir + QStringLiteral("/icons")))
            iconPaths.append(dir + QStringLiteral("/icons"));
    QIcon::setThemeSearchPaths(iconPaths);

    // Asima OS ships Noto Sans as the system font; use it explicitly for consistent metrics.
    if (QFontDatabase::families().contains(QStringLiteral("Noto Sans"))) {
        QFont font(QStringLiteral("Noto Sans"));
        font.setPixelSize(14);
        QGuiApplication::setFont(font);
    }

    QCoreApplication::installTranslator(new EnglishPlurals(qApp));
    // The apps in the person's language: apps/i18n/asimaos_<language>.ts, built into each
    // app. Strings nobody translated yet stay English.
    auto *language = new QTranslator(qApp);
    if (QLocale().language() != QLocale::English
        && language->load(QLocale(), QStringLiteral("asimaos"), QStringLiteral("_"), QStringLiteral(":/i18n")))
        QCoreApplication::installTranslator(language);
    else
        delete language;
}

void install(QQmlEngine *engine)
{
    engine->addImageProvider(QStringLiteral("dicon"), new TintedIconProvider);
}

void finishWindow(QQmlApplicationEngine *engine, const QString &size, const QString &screenshot, int delayMs)
{
    auto *window = engine->rootObjects().isEmpty() ? nullptr : qobject_cast<QQuickWindow *>(engine->rootObjects().constFirst());
    if (!window)
        return;
    const QStringList wh = size.split(QLatin1Char('x'));
    if (wh.size() == 2)
        window->resize(wh[0].toInt(), wh[1].toInt());
    if (!screenshot.isEmpty())
        QTimer::singleShot(delayMs, window, [window, screenshot] {
            window->grabWindow().save(screenshot);
            QCoreApplication::quit();
        });
}

} // namespace AsimaUi
