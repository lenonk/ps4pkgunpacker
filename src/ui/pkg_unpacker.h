#pragma once

#include <QObject>
#include <QString>
#include <QThread>
#include <atomic>
#include <filesystem>
#include "core/file_format/pkg.h"
#include "core/file_format/psf.h"

class PkgUnpacker : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString title READ title NOTIFY pkgInfoChanged)
    Q_PROPERTY(QString titleId READ titleId NOTIFY pkgInfoChanged)
    Q_PROPERTY(QString iconPath READ iconPath NOTIFY pkgInfoChanged)
    Q_PROPERTY(QString pkgVersion READ pkgVersion NOTIFY pkgInfoChanged)
    Q_PROPERTY(bool isPatch READ isPatch NOTIFY pkgInfoChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool isExtracting READ isExtracting NOTIFY statusChanged)

public:
    explicit PkgUnpacker(QObject* parent = nullptr);
    ~PkgUnpacker();

    Q_INVOKABLE bool openPkg(const QString& filePath);
    Q_INVOKABLE void extract(const QString& destinationPath, bool deleteAfter);
    Q_INVOKABLE void cancelExtraction();
    Q_INVOKABLE QString checkPatchStatus(const QString& destinationPath);

    QString title() const { return m_title; }
    QString titleId() const { return m_titleId; }
    QString iconPath() const { return m_iconPath; }
    QString pkgVersion() const { return m_pkgVersion; }
    bool isPatch() const { return m_isPatch; }
    int progress() const { return m_progress; }
    QString status() const { return m_status; }
    bool isExtracting() const { return m_isExtracting; }

signals:
    void pkgInfoChanged();
    void progressChanged();
    void statusChanged();
    void extractionFinished(bool success, const QString& message);

private:
    void updateProgress(int current, int total);

    PKG m_pkg;
    QString m_title;
    QString m_titleId;
    QString m_iconPath;
    QString m_pkgVersion;
    bool m_isPatch = false;
    QString m_currentPkgPath;
    int m_progress = 0;
    QString m_status;
    bool m_isExtracting = false;
    std::atomic<bool> m_cancelRequested{false};
};
