#pragma once

#include "Export.h"

#include <QObject>
#include <QString>
#include <QStringList>
#include <QtQml>
#include <QWindow>

namespace quickui {

/**
 * @brief Native file and folder dialog with Windows IFileOpenDialog + IFileDialogCustomize support.
 *
 * Provides a single dialog capable of selecting either a file or a folder,
 * with modern Windows Quick Access, preview, and breadcrumb navigation.
 */
class QUICKUI_EXPORT QuiNativeFileDialog : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(QuiNativeFileDialog)

public:
    enum DialogMode
    {
        FileOrFolder = 0,
        File         = 1,
        Folder       = 2
    };
    Q_ENUM(DialogMode)

    explicit QuiNativeFileDialog(QObject *parent = nullptr);
    ~QuiNativeFileDialog() override = default;

    /**
     * @brief Checks whether the native platform dialog is available and permitted.
     * @return true on Windows when Qt::AA_DontUseNativeDialogs is not set; false otherwise.
     */
    Q_INVOKABLE bool isAvailable() const;

    /**
     * @brief Open native dialog to pick either a file or a folder.
     * @param title Dialog title
     * @param initialPath Initial directory or file path
     * @param filters File filter specs (e.g. "Images (*.png *.jpg)", "All Files (*.*)")
     * @param folderButtonText Text for the folder selection button (default "选择此文件夹")
     * @param parentWindow Optional parent QWindow
     * @return Selected path (with normalized '/' separators), or empty if cancelled
     */
    Q_INVOKABLE QString chooseFileOrFolder(const QString &title = QString(),
                                          const QString &initialPath = QString(),
                                          const QStringList &filters = QStringList(),
                                          const QString &folderButtonText = QStringLiteral("选择此文件夹"),
                                          QWindow *parentWindow = nullptr);

    /**
     * @brief Open native dialog to pick a file.
     */
    Q_INVOKABLE QString chooseFile(const QString &title = QString(),
                                   const QString &initialPath = QString(),
                                   const QStringList &filters = QStringList(),
                                   QWindow *parentWindow = nullptr);

    /**
     * @brief Open native dialog to pick a folder.
     */
    Q_INVOKABLE QString chooseFolder(const QString &title = QString(),
                                     const QString &initialPath = QString(),
                                     QWindow *parentWindow = nullptr);

    /**
     * @brief Helper to convert QUrl to native local file path without damaging percent/spaces/unicode.
     */
    Q_INVOKABLE QString urlToLocalFile(const QUrl &url) const;

    /**
     * @brief Helper to convert native local file path to local file QUrl.
     */
    Q_INVOKABLE QUrl localFileToUrl(const QString &path) const;

    // Static C++ convenience helpers
    static QString toLocalPath(const QUrl &url);
    static QUrl toFileUrl(const QString &path);
    static QString openFileOrFolder(const QString &title = QString(),
                                   const QString &initialPath = QString(),
                                   const QStringList &filters = QStringList(),
                                   const QString &folderButtonText = QStringLiteral("选择此文件夹"),
                                   QWindow *parentWindow = nullptr);

    static QString openFile(const QString &title = QString(),
                            const QString &initialPath = QString(),
                            const QStringList &filters = QStringList(),
                            QWindow *parentWindow = nullptr);

    static QString openFolder(const QString &title = QString(),
                              const QString &initialPath = QString(),
                              QWindow *parentWindow = nullptr);
};

} // namespace quickui
