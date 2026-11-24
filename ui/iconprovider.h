#pragma once

#include <QQuickImageProvider>

// Serves icons from the system icon theme (Breeze on Asima OS), recoloured to a single tint
// so every icon matches the Asima UI palette in light and dark mode.
// URL form: image://dicon/<icon-name>/<rrggbb or aarrggbb>
class TintedIconProvider : public QQuickImageProvider
{
public:
    TintedIconProvider();
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override;
};
