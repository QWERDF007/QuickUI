#include "quickui/QuiNativeFileDialog.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QRegularExpression>
#include <QWindow>
#include <vector>

#ifdef Q_OS_WIN
#    ifndef NOMINMAX
#        define NOMINMAX
#    endif
#    include <windows.h>
#    include <shobjidl.h>
#    include <wrl/client.h>

#    if defined(_MSC_VER)
#        pragma comment(lib, "ole32.lib")
#        pragma comment(lib, "shell32.lib")
#    endif
#endif

namespace quickui {

#ifdef Q_OS_WIN

namespace {

constexpr DWORD kFolderButtonId = 1001;

class FolderChoiceEventHandler : public IFileDialogEvents, public IFileDialogControlEvents
{
public:
    FolderChoiceEventHandler(IFileOpenDialog *dialog, DWORD buttonId)
        : m_dialog(dialog), m_buttonId(buttonId)
    {
    }

    // IUnknown
    IFACEMETHODIMP QueryInterface(REFIID riid, void **ppv) override
    {
        if (!ppv)
            return E_POINTER;
        if (riid == IID_IUnknown || riid == IID_IFileDialogEvents)
        {
            *ppv = static_cast<IFileDialogEvents *>(this);
            AddRef();
            return S_OK;
        }
        if (riid == IID_IFileDialogControlEvents)
        {
            *ppv = static_cast<IFileDialogControlEvents *>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }

    IFACEMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&m_refCount); }
    IFACEMETHODIMP_(ULONG) Release() override
    {
        long count = InterlockedDecrement(&m_refCount);
        if (count == 0)
            delete this;
        return count;
    }

    // IFileDialogEvents
    IFACEMETHODIMP OnFileOk(IFileDialog *) override { return S_OK; }
    IFACEMETHODIMP OnFolderChanging(IFileDialog *, IShellItem *) override { return S_OK; }
    IFACEMETHODIMP OnFolderChange(IFileDialog *) override { return S_OK; }
    IFACEMETHODIMP OnSelectionChange(IFileDialog *) override { return S_OK; }
    IFACEMETHODIMP OnShareViolation(IFileDialog *, IShellItem *, FDE_SHAREVIOLATION_RESPONSE *) override { return S_OK; }
    IFACEMETHODIMP OnTypeChange(IFileDialog *) override { return S_OK; }
    IFACEMETHODIMP OnOverwrite(IFileDialog *, IShellItem *, FDE_OVERWRITE_RESPONSE *) override { return S_OK; }

    // IFileDialogControlEvents
    IFACEMETHODIMP OnButtonClicked(IFileDialogCustomize *, DWORD dwIDCtl) override
    {
        if (dwIDCtl == m_buttonId && m_dialog)
        {
            bool resolved = false;
            // Check if user has highlighted a folder item in current list
            Microsoft::WRL::ComPtr<IShellItem> pSelected;
            if (SUCCEEDED(m_dialog->GetCurrentSelection(&pSelected)) && pSelected)
            {
                SFGAOF attribs = 0;
                if (SUCCEEDED(pSelected->GetAttributes(SFGAO_FOLDER, &attribs)) && (attribs & SFGAO_FOLDER))
                {
                    PWSTR pszPath = nullptr;
                    if (SUCCEEDED(pSelected->GetDisplayName(SIGDN_FILESYSPATH, &pszPath)) && pszPath)
                    {
                        m_folderPath = QString::fromWCharArray(pszPath);
                        CoTaskMemFree(pszPath);
                        resolved = true;
                    }
                }
            }

            // Otherwise, select the currently opened directory
            if (!resolved)
            {
                Microsoft::WRL::ComPtr<IShellItem> pCurrentFolder;
                if (SUCCEEDED(m_dialog->GetFolder(&pCurrentFolder)) && pCurrentFolder)
                {
                    PWSTR pszPath = nullptr;
                    if (SUCCEEDED(pCurrentFolder->GetDisplayName(SIGDN_FILESYSPATH, &pszPath)) && pszPath)
                    {
                        m_folderPath = QString::fromWCharArray(pszPath);
                        CoTaskMemFree(pszPath);
                        resolved = true;
                    }
                }
            }

            m_folderSelected = resolved;
            m_dialog->Close(S_OK);
        }
        return S_OK;
    }

    IFACEMETHODIMP OnItemSelected(IFileDialogCustomize *, DWORD, DWORD) override { return S_OK; }
    IFACEMETHODIMP OnCheckButtonToggled(IFileDialogCustomize *, DWORD, BOOL) override { return S_OK; }
    IFACEMETHODIMP OnControlActivating(IFileDialogCustomize *, DWORD) override { return S_OK; }

    bool folderSelected() const { return m_folderSelected; }
    QString folderPath() const { return m_folderPath; }

private:
    long m_refCount{1};
    IFileOpenDialog *m_dialog{nullptr};
    DWORD m_buttonId{kFolderButtonId};
    bool m_folderSelected{false};
    QString m_folderPath;
};

HWND resolveParentHwnd(QWindow *parentWindow)
{
    if (parentWindow)
        return reinterpret_cast<HWND>(parentWindow->winId());
    if (auto *focus = QGuiApplication::focusWindow())
        return reinterpret_cast<HWND>(focus->winId());
    return GetActiveWindow();
}

QString executeNativeOpenDialog(QuiNativeFileDialog::DialogMode mode,
                               const QString &title,
                               const QString &initialPath,
                               const QStringList &filters,
                               const QString &folderButtonText,
                               QWindow *parentWindow)
{
    if (QCoreApplication::testAttribute(Qt::AA_DontUseNativeDialogs))
        return QString();

    HRESULT hrCom = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    const bool needUninit = SUCCEEDED(hrCom);

    Microsoft::WRL::ComPtr<IFileOpenDialog> pFileOpen;
    HRESULT hr = CoCreateInstance(CLSID_FileOpenDialog, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&pFileOpen));
    if (FAILED(hr) || !pFileOpen)
    {
        if (needUninit)
            CoUninitialize();
        return QString();
    }

    FILEOPENDIALOGOPTIONS options = 0;
    pFileOpen->GetOptions(&options);
    options |= FOS_FORCEFILESYSTEM | FOS_PATHMUSTEXIST;

    if (mode == QuiNativeFileDialog::Folder)
    {
        options |= FOS_PICKFOLDERS;
    }
    else if (mode == QuiNativeFileDialog::File)
    {
        options |= FOS_FILEMUSTEXIST;
    }
    else // FileOrFolder
    {
        options |= FOS_FILEMUSTEXIST;
    }
    pFileOpen->SetOptions(options);

    if (!title.isEmpty())
    {
        std::wstring wTitle = title.toStdWString();
        pFileOpen->SetTitle(wTitle.c_str());
    }

    // Set initial location
    if (!initialPath.isEmpty())
    {
        QFileInfo fi(initialPath);
        QString folderPath = fi.isDir() ? initialPath : fi.dir().absolutePath();
        if (QDir(folderPath).exists())
        {
            std::wstring wFolder = QDir::toNativeSeparators(folderPath).toStdWString();
            Microsoft::WRL::ComPtr<IShellItem> pFolderItem;
            if (SUCCEEDED(SHCreateItemFromParsingName(wFolder.c_str(), nullptr, IID_PPV_ARGS(&pFolderItem))) && pFolderItem)
            {
                pFileOpen->SetFolder(pFolderItem.Get());
            }
        }
        if (fi.isFile() && mode != QuiNativeFileDialog::Folder)
        {
            std::wstring wFileName = fi.fileName().toStdWString();
            pFileOpen->SetFileName(wFileName.c_str());
        }
    }

    // Parse filters
    std::vector<std::wstring> filterNames;
    std::vector<std::wstring> filterSpecs;
    std::vector<COMDLG_FILTERSPEC> dialogFilters;

    if (mode != QuiNativeFileDialog::Folder)
    {
        static const QRegularExpression parenRx(QStringLiteral(R"(\(([^)]+)\))"));
        for (const auto &f : filters)
        {
            if (f.trimmed().isEmpty())
                continue;
            auto match = parenRx.match(f);
            if (match.hasMatch())
            {
                QString specStr = match.captured(1).trimmed();
                specStr.replace(QStringLiteral(" "), QStringLiteral(";"));
                specStr.replace(QStringLiteral(","), QStringLiteral(";"));
                filterNames.push_back(f.toStdWString());
                filterSpecs.push_back(specStr.toStdWString());
            }
            else
            {
                filterNames.push_back(f.toStdWString());
                filterSpecs.push_back(f.toStdWString());
            }
        }

        if (filterNames.empty())
        {
            filterNames.push_back(L"所有文件 (*.*)");
            filterSpecs.push_back(L"*.*");
        }

        dialogFilters.resize(filterNames.size());
        for (size_t i = 0; i < filterNames.size(); ++i)
        {
            dialogFilters[i].pszName = filterNames[i].c_str();
            dialogFilters[i].pszSpec = filterSpecs[i].c_str();
        }

        pFileOpen->SetFileTypes(static_cast<UINT>(dialogFilters.size()), dialogFilters.data());
        pFileOpen->SetFileTypeIndex(1);
    }

    FolderChoiceEventHandler *pHandler = nullptr;
    DWORD dwCookie = 0;

    if (mode == QuiNativeFileDialog::FileOrFolder)
    {
        Microsoft::WRL::ComPtr<IFileDialogCustomize> pCustomize;
        if (SUCCEEDED(pFileOpen.As(&pCustomize)) && pCustomize)
        {
            const QString btnText = folderButtonText.trimmed().isEmpty()
                                        ? QStringLiteral("选择此文件夹")
                                        : folderButtonText;
            std::wstring wBtnText = btnText.toStdWString();
            pCustomize->AddPushButton(kFolderButtonId, wBtnText.c_str());
        }

        pHandler = new FolderChoiceEventHandler(pFileOpen.Get(), kFolderButtonId);
        pFileOpen->Advise(pHandler, &dwCookie);
    }

    HWND parentHwnd = resolveParentHwnd(parentWindow);
    HRESULT hrShow = pFileOpen->Show(parentHwnd);

    if (dwCookie)
        pFileOpen->Unadvise(dwCookie);

    QString result;
    if (pHandler && pHandler->folderSelected())
    {
        result = pHandler->folderPath();
    }
    else if (SUCCEEDED(hrShow))
    {
        Microsoft::WRL::ComPtr<IShellItem> pResultItem;
        if (SUCCEEDED(pFileOpen->GetResult(&pResultItem)) && pResultItem)
        {
            PWSTR pszPath = nullptr;
            if (SUCCEEDED(pResultItem->GetDisplayName(SIGDN_FILESYSPATH, &pszPath)) && pszPath)
            {
                result = QString::fromWCharArray(pszPath);
                CoTaskMemFree(pszPath);
            }
        }
    }

    if (pHandler)
        pHandler->Release();

    if (needUninit)
        CoUninitialize();

    return QDir::fromNativeSeparators(result);
}

} // namespace

#endif // Q_OS_WIN

QuiNativeFileDialog::QuiNativeFileDialog(QObject *parent)
    : QObject(parent)
{
}

bool QuiNativeFileDialog::isAvailable() const
{
#ifdef Q_OS_WIN
    return !QCoreApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
#else
    return false;
#endif
}

QString QuiNativeFileDialog::chooseFileOrFolder(const QString &title,
                                               const QString &initialPath,
                                               const QStringList &filters,
                                               const QString &folderButtonText,
                                               QWindow *parentWindow)
{
    return openFileOrFolder(title, initialPath, filters, folderButtonText, parentWindow);
}

QString QuiNativeFileDialog::chooseFile(const QString &title,
                                       const QString &initialPath,
                                       const QStringList &filters,
                                       QWindow *parentWindow)
{
    return openFile(title, initialPath, filters, parentWindow);
}

QString QuiNativeFileDialog::chooseFolder(const QString &title,
                                         const QString &initialPath,
                                         QWindow *parentWindow)
{
    return openFolder(title, initialPath, parentWindow);
}

QString QuiNativeFileDialog::openFileOrFolder(const QString &title,
                                             const QString &initialPath,
                                             const QStringList &filters,
                                             const QString &folderButtonText,
                                             QWindow *parentWindow)
{
#ifdef Q_OS_WIN
    return executeNativeOpenDialog(FileOrFolder, title, initialPath, filters, folderButtonText, parentWindow);
#else
    Q_UNUSED(title);
    Q_UNUSED(initialPath);
    Q_UNUSED(filters);
    Q_UNUSED(folderButtonText);
    Q_UNUSED(parentWindow);
    return QString();
#endif
}

QString QuiNativeFileDialog::openFile(const QString &title,
                                     const QString &initialPath,
                                     const QStringList &filters,
                                     QWindow *parentWindow)
{
#ifdef Q_OS_WIN
    return executeNativeOpenDialog(File, title, initialPath, filters, QString(), parentWindow);
#else
    Q_UNUSED(title);
    Q_UNUSED(initialPath);
    Q_UNUSED(filters);
    Q_UNUSED(parentWindow);
    return QString();
#endif
}

QString QuiNativeFileDialog::openFolder(const QString &title,
                                       const QString &initialPath,
                                       QWindow *parentWindow)
{
#ifdef Q_OS_WIN
    return executeNativeOpenDialog(Folder, title, initialPath, QStringList(), QString(), parentWindow);
#else
    Q_UNUSED(title);
    Q_UNUSED(initialPath);
    Q_UNUSED(parentWindow);
    return QString();
#endif
}

QString QuiNativeFileDialog::urlToLocalFile(const QUrl &url) const
{
    return toLocalPath(url);
}

QUrl QuiNativeFileDialog::localFileToUrl(const QString &path) const
{
    return toFileUrl(path);
}

QString QuiNativeFileDialog::toLocalPath(const QUrl &url)
{
    return url.toLocalFile();
}

QUrl QuiNativeFileDialog::toFileUrl(const QString &path)
{
    return QUrl::fromLocalFile(path);
}

} // namespace quickui
