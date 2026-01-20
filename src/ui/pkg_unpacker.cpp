#include "pkg_unpacker.h"
#include <QFuture>
#include <QtConcurrent>
#include <QDir>
#include <QStandardPaths>
#include "common/logging/log.h"
#include "common/path_util.h"

PkgUnpacker::PkgUnpacker(QObject* parent) : QObject(parent) {}

PkgUnpacker::~PkgUnpacker() {}

bool PkgUnpacker::openPkg(const QString& filePath) {
    m_currentPkgPath = filePath;
    std::string failreason;
    std::filesystem::path path = Common::FS::PathFromQString(filePath);

    if (!m_pkg.Open(path, failreason)) {
        m_status = QString::fromStdString(failreason);
        emit statusChanged();
        return false;
    }

    m_titleId = QString::fromStdString(std::string(m_pkg.GetTitleID()));

    // Check if this is a patch
    QString pkgFlags = QString::fromStdString(m_pkg.GetPkgFlags());
    m_isPatch = pkgFlags.contains("PATCH");

    PSF psf;
    if (psf.Open(m_pkg.sfo)) {
        auto title = psf.GetString("TITLE");
        if (title) m_title = QString::fromUtf8(title->data(), title->size());

        // Get version if available
        auto app_ver = psf.GetString("APP_VER");
        if (app_ver) m_pkgVersion = QString::fromUtf8(app_ver->data(), app_ver->size());
    }

    // Extract icon0.png to temp for preview if possible
    // For now we'll just set the info

    emit pkgInfoChanged();
    m_status = "Ready to extract";
    emit statusChanged();
    return true;
}

void PkgUnpacker::extract(const QString& destinationPath, bool deleteAfter) {
    if (m_isExtracting) return;

    m_isExtracting = true;
    m_cancelRequested = false;
    m_progress = 0;
    m_status = "Extracting...";
    emit statusChanged();
    emit progressChanged();

    [[maybe_unused]] auto future = QtConcurrent::run([this, destinationPath, deleteAfter]() {
        LOG_INFO(Frontend, "Starting extraction to {}", destinationPath.toStdString());
        std::string failreason;
        std::filesystem::path pkgPath = Common::FS::PathFromQString(m_currentPkgPath);
        std::filesystem::path destPath = Common::FS::PathFromQString(destinationPath);

        // Re-open PKG to ensure clean state (especially after cancel)
        PKG pkg;
        if (!pkg.Open(pkgPath, failreason)) {
            LOG_ERROR(Frontend, "Failed to re-open PKG: {}", failreason);
            m_isExtracting = false;
            m_status = "Error: " + QString::fromStdString(failreason);
            emit statusChanged();
            emit extractionFinished(false, m_status);
            return;
        }

        // PKG::Extract in shadPS4 expects the destination path.
        // It creates a subfolder based on Title ID inside it, or uses it directly for updates.

        LOG_INFO(Frontend, "Calling pkg.Extract");
        if (!pkg.Extract(pkgPath, destPath, failreason)) {
            LOG_ERROR(Frontend, "m_pkg.Extract failed: {}", failreason);
            m_isExtracting = false;
            m_status = "Error: " + QString::fromStdString(failreason);
            emit statusChanged();
            emit extractionFinished(false, m_status);
            return;
        }

        int nfiles = pkg.GetNumberOfFiles();
        LOG_INFO(Frontend, "Extracting {} files", nfiles);
        for (int i = 0; i < nfiles; ++i) {
            if (m_cancelRequested) {
                LOG_INFO(Frontend, "Extraction cancelled by user");
                m_isExtracting = false;
                m_status = "Extraction cancelled";
                emit statusChanged();
                emit extractionFinished(false, m_status);
                        std::cout << "Done" << std::endl;
                return;
            }

            pkg.ExtractFiles(i);
            m_progress = (i + 1) * 100 / nfiles;
            emit progressChanged();
            if (i % 100 == 0 || i == nfiles - 1) {
                LOG_INFO(Frontend, "Extracted {}/{} files", i + 1, nfiles);
            }
        }

        if (deleteAfter && !m_cancelRequested) {
            std::filesystem::remove(pkgPath);
        }

        m_isExtracting = false;
        m_status = "Extraction finished successfully";
        emit statusChanged();
        emit extractionFinished(true, m_status);
    });
}

void PkgUnpacker::cancelExtraction() {
    if (m_isExtracting) {
        LOG_INFO(Frontend, "Cancel requested");
        m_cancelRequested = true;
        m_status = "Cancelling...";
        emit statusChanged();
    }
}

QString PkgUnpacker::checkPatchStatus(const QString& destinationPath) {
    // Returns empty string if no conflict, or a message describing the situation
    if (!m_isPatch) {
        return "";
    }

    std::filesystem::path destPath = Common::FS::PathFromQString(destinationPath);
    std::filesystem::path gamePath = destPath / m_titleId.toStdString();

    // Check if game directory exists
    QDir gameDir(QString::fromStdString(gamePath.string()));
    if (!gameDir.exists()) {
        return "notinstalled"; // Special code for "game not installed"
    }

    // Try to find param.sfo in the installed game
    std::filesystem::path sfoPath = gamePath / "sce_sys" / "param.sfo";
    if (!std::filesystem::exists(sfoPath)) {
        return ""; // No param.sfo found, can't compare
    }

    // Read installed game version
    PSF installedPsf;
    if (!installedPsf.Open(sfoPath)) {
        return ""; // Can't read PSF, allow extraction
    }

    auto installedVer = installedPsf.GetString("APP_VER");
    if (!installedVer) {
        return ""; // No version in installed game
    }

    QString installedVersion = QString::fromUtf8(installedVer->data(), installedVer->size());
    double installedVerNum = installedVersion.toDouble();
    double pkgVerNum = m_pkgVersion.toDouble();

    // Return a JSON-like string with the comparison result
    if (pkgVerNum == installedVerNum) {
        return QString("match|%1|%2").arg(m_pkgVersion, installedVersion);
    } else if (pkgVerNum < installedVerNum) {
        return QString("older|%1|%2").arg(m_pkgVersion, installedVersion);
    } else {
        return QString("newer|%1|%2").arg(m_pkgVersion, installedVersion);
    }
}
