#pragma once

#include <QString>
#include <QVariantList>

// "What you'll get on this PC" (D39): what Asima OS will do on this computer, read from /sys and
// /proc like the installer's own check. It never refuses anyone: missing features are switched off
// and said so. Only three things stop an install, because Asima OS can't start or fit: a PC that
// isn't 64-bit (x86_64), a start in legacy BIOS mode (it can usually be switched to UEFI), and no
// disk of at least 48 GB. What can't be read (inside a sandbox, for example) is said too.
//
// Each item: { id, title, value, tone (ok | info | warn | error), detail, blocks (bool) }.
// ASIMAOS_HUB_TEST_SYSROOT puts a folder in front of /sys and /proc (tests).
namespace PcCheck {

QVariantList run();

// A fixed sample (a gaming PC), for demo mode and screenshots.
QVariantList demo();

// One line for the top of the page: everything fine, or what to fix first.
QString summary(const QVariantList &items);

} // namespace PcCheck
