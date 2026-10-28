import QtQuick
import QtQuick.Dialogs as QtDialogs
import quickui

Item {
    id: control

    // Dialog controller is not a visual element and must not participate in parent layouts
    parent: null

    property string title: "选择文件或文件夹"
    property var currentFolder: ""
    property string selectedPath: ""
    property var nameFilters: []
    property int dialogMode: QuiFileFolderDialog.DialogMode.FileOrFolder

    visible: fallbackFileDialog.visible || fallbackFolderDialog.visible || _nativeVisible

    // Compatibility properties for bindings / tests
    readonly property url selectedFile: fallbackFileDialog.visible
                                            ? fallbackFileDialog.selectedFile
                                            : nativePicker.localFileToUrl(selectedPath)
    readonly property url selectedFolder: fallbackFolderDialog.visible
                                              ? fallbackFolderDialog.selectedFolder
                                              : nativePicker.localFileToUrl(selectedPath)
    property string acceptLabel: "确认选择"

    enum DialogMode {
        FileOrFolder = 0,
        File = 1,
        Folder = 2
    }

    signal accepted(string path)
    signal rejected()

    property bool _nativeVisible: false

    QuiNativeFileDialog {
        id: nativePicker
    }

    // Fallback dialogs for when Qt::AA_DontUseNativeDialogs is active (e.g. test suites)
    QtDialogs.FileDialog {
        id: fallbackFileDialog
        title: control.title
        acceptLabel: control.acceptLabel
        currentFolder: control._resolvedFolderUrl()
        nameFilters: control.nameFilters
        onAccepted: {
            let p = nativePicker.urlToLocalFile(fallbackFileDialog.selectedFile)
            control.selectedPath = p
            control.accepted(p)
        }
        onRejected: {
            control.rejected()
        }
    }

    QtDialogs.FolderDialog {
        id: fallbackFolderDialog
        title: control.title
        acceptLabel: control.acceptLabel
        currentFolder: control._resolvedFolderUrl()
        onAccepted: {
            let p = nativePicker.urlToLocalFile(fallbackFolderDialog.selectedFolder)
            control.selectedPath = p
            control.accepted(p)
        }
        onRejected: {
            control.rejected()
        }
    }

    function _resolvedFolderUrl() {
        if (!currentFolder) return ""
        let s = currentFolder.toString()
        if (s.startsWith("file:")) return currentFolder
        return nativePicker.localFileToUrl(s)
    }

    function _resolvedFolderStr() {
        if (!currentFolder) return ""
        let s = currentFolder.toString()
        if (s.startsWith("file:")) return nativePicker.urlToLocalFile(currentFolder)
        return s
    }

    function open() {
        if (nativePicker.isAvailable()) {
            _nativeVisible = true
            let res = ""
            let folder = _resolvedFolderStr()
            if (dialogMode === QuiFileFolderDialog.DialogMode.FileOrFolder) {
                res = nativePicker.chooseFileOrFolder(title, folder, nameFilters)
            } else if (dialogMode === QuiFileFolderDialog.DialogMode.File) {
                res = nativePicker.chooseFile(title, folder, nameFilters)
            } else {
                res = nativePicker.chooseFolder(title, folder)
            }
            _nativeVisible = false
            if (res.length > 0) {
                selectedPath = res
                accepted(res)
            } else {
                rejected()
            }
            return
        }

        // Bypassed (e.g. AA_DontUseNativeDialogs in automated tests) or non-Windows
        if (dialogMode === QuiFileFolderDialog.DialogMode.Folder) {
            fallbackFolderDialog.open()
        } else {
            fallbackFileDialog.open()
        }
    }

    function close() {
        _nativeVisible = false
        fallbackFileDialog.close()
        fallbackFolderDialog.close()
    }

    function choosePath() {
        let folder = _resolvedFolderStr()
        let res = ""
        if (dialogMode === QuiFileFolderDialog.DialogMode.FileOrFolder) {
            res = nativePicker.chooseFileOrFolder(title, folder, nameFilters)
        } else if (dialogMode === QuiFileFolderDialog.DialogMode.File) {
            res = nativePicker.chooseFile(title, folder, nameFilters)
        } else {
            res = nativePicker.chooseFolder(title, folder)
        }
        if (res.length > 0) {
            selectedPath = res
            accepted(res)
        }
        return res
    }
}
