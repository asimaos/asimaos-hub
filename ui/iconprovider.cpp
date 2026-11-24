#include "iconprovider.h"

#include <QColor>
#include <QIcon>
#include <QPainter>

TintedIconProvider::TintedIconProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap)
{
}

QPixmap TintedIconProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    const int slash = id.lastIndexOf(QLatin1Char('/'));
    const QString name = slash > 0 ? id.left(slash) : id;
    const QColor tint = slash > 0 ? QColor(QLatin1Char('#') + id.mid(slash + 1)) : QColor();

    const QSize target = requestedSize.isValid() && !requestedSize.isEmpty() ? requestedSize : QSize(24, 24);
    if (size)
        *size = target;

    QPixmap pixmap(target);
    pixmap.fill(Qt::transparent);

    const QIcon icon = QIcon::fromTheme(name);
    if (icon.isNull())
        return pixmap;

    QPainter painter(&pixmap);
    painter.setRenderHint(QPainter::SmoothPixmapTransform);
    icon.paint(&painter, QRect(QPoint(0, 0), target));
    if (tint.isValid()) {
        // Keep the icon's shape (alpha), replace its colours with the tint.
        painter.setCompositionMode(QPainter::CompositionMode_SourceIn);
        painter.fillRect(pixmap.rect(), tint);
    }
    painter.end();
    return pixmap;
}
