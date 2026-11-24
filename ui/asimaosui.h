#pragma once

#include <QString>

class QQmlApplicationEngine;
class QQmlEngine;

// Asima UI: shared setup for every Asima OS app.
namespace AsimaUi {

// Call before creating QGuiApplication: rendering and style defaults.
void preApplicationSetup();

// Call after creating QGuiApplication: icon theme fallback, default font, English plurals.
void applicationSetup();

// Call on every QML engine: registers the tinted icon provider ("image://dicon/<name>/<rrggbb>").
void install(QQmlEngine *engine);

// For screenshots and tests, after loading the window: resizes it to `size` ("WxH", may be empty)
// and, when `screenshot` names a file, saves the window there as a PNG after `delayMs` and quits.
void finishWindow(QQmlApplicationEngine *engine, const QString &size, const QString &screenshot, int delayMs = 1800);

} // namespace AsimaUi
