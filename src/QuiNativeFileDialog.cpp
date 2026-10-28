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
#    include <commctrl.h>
#    include <shobjidl.h>
#    include <wrl/client.h>

#    if defined(_MSC_VER)
#        pragma comment(lib, "ole32.lib")
#        pragma comment(lib, "shell32.lib")
#        pragma comment(lib, "comctl32.lib")
#        pragma comment(lib, "user32.lib")
#    endif
#endif

namespace quickui {

#ifdef Q_OS_WIN

namespace {

/**
 * @brief Subclasses dialog HWND to allow the standard native Open (IDOK) button
 * to select either a highlighted folder, a browsed current folder, or a file.
 */
class NativeOpenDialogHandler : public IFileDialogEvents
{
public:
    explicit NativeOpenDialogHandler(IFileOpenDialog *dialog, QuiNativeFileDialog::DialogMode mode)
        : m_dialog(dialog), m_mode(mode)
    {
    }

    ~NativeOpenDialogHandler()
    {
        unhookSubclass();
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
    IFACEMETHODIMP OnFolderChange(IFileDialog *pfd) override
    {
        if (!m_subclassed && pfd)
        {
            Microsoft::WRL::ComPtr<IOleWindow> pOleWindow;
            if (SUCCEEDED(pfd->QueryInterface(IID_PPV_ARGS(&pOleWindow))) && pOleWindow)
            {
                HWND hwndDlg = nullptr;
                if (SUCCEEDED(pOleWindow->GetWindow(&hwndDlg)) && hwndDlg)
                {
                    m_dialogHwnd = hwndDlg;
                    SetWindowSubclass(hwndDlg, SubclassProc, kSubclassId, reinterpret_cast<DWORD_PTR>(this));
                    m_subclassed = true;
                }
            }
        }
        return S_OK;
    }
    IFACEMETHODIMP OnSelectionChange(IFileDialog *) override { return S_OK; }
    IFACEMETHODIMP OnShareViolation(IFileDialog *, IShellItem *, FDE_SHAREVIOLATION_RESPONSE *) override { return S_OK; }
    IFACEMETHODIMP OnTypeChange(IFileDialog *) override { return S_OK; }
    IFACEMETHODIMP OnOverwrite(IFileDialog *, IShellItem *, FDE_OVERWRITE_RESPONSE *) override { return S_OK; }

    void unhookSubclass()
    {
        if (m_subclassed && m_dialogHwnd)
        {
            RemoveWindowSubclass(m_dialogHwnd, SubclassProc, kSubclassId);
            m_subclassed = false;
            m_dialogHwnd = nullptr;
        }
    }

    bool isFolderAccepted() const { return m_folderAccepted; }
    QString folderPath() const { return m_folderPath; }

private:
    static constexpr UINT_PTR kSubclassId = 101;

    static LRESULT CALLBACK SubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam,
                                         UINT_PTR uIdSubclass, DWORD_PTR dwRefData)
    {
        (void)uIdSubclass;
        (void)lParam;
        auto *self = reinterpret_cast<NativeOpenDialogHandler *>(dwRefData);
        if (self && uMsg == WM_COMMAND)
        {
            const WORD id = LOWORD(wParam);
            const WORD code = HIWORD(wParam);
            if (id == IDOK && (code == BN_CLICKED || code == 0) && self->m_mode == QuiNativeFileDialog::FileOrFolder)
            {
                if (self->handleOpenCommand(hWnd))
                {
                    return 0;
                }
            }
        }
        return DefSubclassProc(hWnd, uMsg, wParam, lParam);
    }

    bool handleOpenCommand(HWND hWnd)
    {
        if (!m_dialog)
            return false;

        // 1. If user selected an item in the current Explorer view
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
                    m_folderAccepted = true;
                    PostMessage(hWnd, WM_CLOSE, 0, 0);
                    return true;
                }
            }
            else
            {
                // File item selected: let default Windows Open handling proceed
                return false;
            }
        }

        // 2. If user typed a folder name in the file name box
        PWSTR pszTyped = nullptr;
        if (SUCCEEDED(m_dialog->GetFileName(&pszTyped)) && pszTyped)
        {
            QString typed = QString::fromWCharArray(pszTyped).trimmed();
            CoTaskMemFree(pszTyped);
            if (!typed.isEmpty())
            {
                QFileInfo fiTyped(typed);
                if (fiTyped.isAbsolute() && fiTyped.isDir())
                {
                    m_folderPath = fiTyped.absoluteFilePath();
                    m_folderAccepted = true;
                    PostMessage(hWnd, WM_CLOSE, 0, 0);
                    return true;
                }

                Microsoft::WRL::ComPtr<IShellItem> pCurFolder;
                if (SUCCEEDED(m_dialog->GetFolder(&pCurFolder)) && pCurFolder)
                {
                    PWSTR pszCur = nullptr;
                    if (SUCCEEDED(pCurFolder->GetDisplayName(SIGDN_FILESYSPATH, &pszCur)) && pszCur)
                    {
                        QString curFolder = QString::fromWCharArray(pszCur);
                        CoTaskMemFree(pszCur);
                        QFileInfo fiRel(QDir(curFolder).filePath(typed));
                        if (fiRel.isDir())
                        {
                            m_folderPath = fiRel.absoluteFilePath();
                            m_folderAccepted = true;
                            PostMessage(hWnd, WM_CLOSE, 0, 0);
                            return true;
                        }
                    }
                }

                // If typed is an existing file or other name, let default Windows handler validate
                return false;
            }
        }

        // 3. No file selected and edit box is empty: accept current browsing folder
        Microsoft::WRL::ComPtr<IShellItem> pFolder;
        if (SUCCEEDED(m_dialog->GetFolder(&pFolder)) && pFolder)
        {
            PWSTR pszPath = nullptr;
            if (SUCCEEDED(pFolder->GetDisplayName(SIGDN_FILESYSPATH, &pszPath)) && pszPath)
            {
                m_folderPath = QString::fromWCharArray(pszPath);
                CoTaskMemFree(pszPath);
                m_folderAccepted = true;
                PostMessage(hWnd, WM_CLOSE, 0, 0);
                return true;
            }
        }

        return false;
    }

    long m_refCount{1};
    IFileOpenDialog *m_dialog{nullptr};
    QuiNativeFileDialog::DialogMode m_mode{QuiNativeFileDialog::FileOrFolder};
    bool m_subclassed{false};
    HWND m_dialogHwnd{nullptr};
    bool m_folderAccepted{false};
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
    // FileOrFolder intentionally omits FOS_FILEMUSTEXIST so clicking Open with empty selection can accept the folder
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

    NativeOpenDialogHandler *pHandler = new NativeOpenDialogHandler(pFileOpen.Get(), mode);
    DWORD dwCookie = 0;
    pFileOpen->Advise(pHandler, &dwCookie);

    HWND parentHwnd = resolveParentHwnd(parentWindow);
    HRESULT hrShow = pFileOpen->Show(parentHwnd);

    pHandler->unhookSubclass();
    if (dwCookie)
        pFileOpen->Unadvise(dwCookie);

    QString result;
    if (pHandler->isFolderAccepted())
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
                                               QWindow *parentWindow)
{
    return openFileOrFolder(title, initialPath, filters, parentWindow);
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
                                             QWindow *parentWindow)
{
#ifdef Q_OS_WIN
    return executeNativeOpenDialog(FileOrFolder, title, initialPath, filters, parentWindow);
#else
    Q_UNUSED(title);
    Q_UNUSED(initialPath);
    Q_UNUSED(filters);
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
    return executeNativeOpenDialog(File, title, initialPath, filters, parentWindow);
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
    return executeNativeOpenDialog(Folder, title, initialPath, QStringList(), parentWindow);
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
