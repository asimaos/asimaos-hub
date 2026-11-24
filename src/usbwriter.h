#pragma once

#include <QQmlEngine>
#include <QtQml/qqmlregistration.h>

#include <QObject>
#include <QString>
#include <QVariantList>

#include <atomic>

// Writes the downloaded Asima OS ISO to a USB stick (D39). On Linux it goes through UDisks: only
// USB and removable drives are offered (never the disk the system runs from), the stick's
// partitions are unmounted, and UDisks opens the device after the administrator's password. The
// whole stick is written, then read back and compared with the ISO's SHA-256, so a stick that
// doesn't hold exactly the ISO is never called ready.
//
// ASIMAOS_HUB_TEST_TARGET=FILE offers that file as the only "stick" and writes to it directly
// (tests: no device is ever touched). Demo mode shows two sample sticks.
class UsbWriter : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(Writer)
    QML_SINGLETON
    // The sticks: { id, drive, name, detail, size }.
    Q_PROPERTY(QVariantList drives READ drives NOTIFY drivesChanged)
    // The stick being written, or written last.
    Q_PROPERTY(QString target READ target NOTIFY stateChanged)
    // "" | writing | verifying | done | error, with progress 0–1 and a sentence about it.
    Q_PROPERTY(QString state READ state NOTIFY stateChanged)
    Q_PROPERTY(double progress READ progress NOTIFY stateChanged)
    Q_PROPERTY(QString message READ message NOTIFY stateChanged)

public:
    // The one instance main() makes; QML gets it as the Writer singleton (known at build time,
    // so qmllint and the QML compiler see its properties).
    static inline UsbWriter *instance = nullptr;
    static UsbWriter *create(QQmlEngine *, QJSEngine *)
    {
        QJSEngine::setObjectOwnership(instance, QJSEngine::CppOwnership);
        return instance;
    }

    explicit UsbWriter(bool demo, QObject *parent = nullptr);
    ~UsbWriter() override;

    QVariantList drives() const { return m_drives; }
    QString target() const { return m_target; }
    QString state() const { return m_state; }
    double progress() const { return m_progress; }
    QString message() const { return m_message; }

    Q_INVOKABLE void refreshDrives();
    // Erases the stick `driveId` and writes `isoFile` to it; `sha256` is the ISO's, from the feed.
    Q_INVOKABLE void write(const QString &driveId, const QString &isoFile, const QString &sha256);
    Q_INVOKABLE void cancel();

    // Screenshots: writing, written.
    void setDemoState(const QString &state);
    // Tests: write without the window and wait for the end; 0 when the stick holds the ISO.
    int writeAndWait(const QString &driveId, const QString &isoFile, const QString &sha256);

signals:
    void drivesChanged();
    void stateChanged();

private:
    void setState(const QString &state, double progress, const QString &message);
    int openTarget(const QString &driveId, QString *error);
    void run(int fd, const QString &isoFile, const QString &sha256);

    bool m_demo;
    QString m_testTarget;
    QVariantList m_drives;
    QString m_state, m_message, m_target;
    double m_progress = 0;
    std::atomic_bool m_cancel{false};
    QThread *m_thread = nullptr;
};
