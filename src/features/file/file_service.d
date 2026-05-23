module features.file.file_service;
import features.file.file_dialog;
import features.file.file_ops;

class FileService {

    private static FileService _instance;
    private void delegate(string)[] _onFolderOpenedListeners;
    private void delegate(string)[] _onFileOpenedListeners;

    static FileService instance() {
        if (_instance is null)
            _instance = new FileService();
        return _instance;
    }

    void addFolderOpenedListener(void delegate(string) listener) {
        _onFolderOpenedListeners ~= listener;
    }

    void addFileOpenedListener(void delegate(string) listener) {
        _onFileOpenedListeners ~= listener;
    }

    void newFile() {
        import features.editor.editor_service;
        EditorService.instance.newFile();
    }

    void openFile() {
        auto path = showFileDialog(null);
        if (path is null) return;
        foreach (l; _onFileOpenedListeners)
            l(path);
    }

    void openFolder() {
        auto path = showFolderDialog(null);
        if (path is null) return;
        foreach (l; _onFolderOpenedListeners)
            l(path);
    }

    void saveFile() {
        import features.editor.editor_service;
        import std.file : write;
        import std.conv : to;

        auto path = EditorService.instance.activeFilePath();
        if (path.length == 0) return;

        auto text = EditorService.instance.activeFileText();
        try {
            write(path, to!string(text));
            EditorService.instance.markActiveClean();
        } catch (Exception e) {}
    }

    void saveFileAs() {
        import features.editor.editor_service;
        import std.file : write;
        import std.conv : to;
        import core.sys.windows.windows;
        import core.sys.windows.commdlg;
        import core.stdc.wchar_ : wcslen;

        wchar[260] buf;
        buf[] = 0;

        OPENFILENAMEW ofn = OPENFILENAMEW.init;
        ofn.lStructSize = OPENFILENAMEW.sizeof;
        ofn.lpstrFile   = buf.ptr;
        ofn.nMaxFile    = cast(DWORD)buf.length;
        ofn.Flags       = OFN_PATHMUSTEXIST | OFN_OVERWRITEPROMPT | OFN_EXPLORER;

        if (!GetSaveFileNameW(&ofn)) return;

        auto newPath = to!string(buf[0 .. wcslen(buf.ptr)]);
        auto text    = EditorService.instance.activeFileText();

        try {
            write(newPath, to!string(text));
            EditorService.instance.updateFilePath(
                EditorService.instance.activeFilePath(), newPath);
            EditorService.instance.markActiveClean();
        } catch (Exception e) {}
    }

    void createFile(string dir, string name) {
        features.file.file_ops.createFile(dir, name);
    }

    void createFolder(string dir, string name) {
        features.file.file_ops.createFolder(dir, name);
    }

    void deleteEntry(string path) {
        import std.file : isFile, isDir;
        if (path.isFile)
            features.file.file_ops.deleteFile(path);
        else if (path.isDir)
            features.file.file_ops.deleteFolder(path);
    }

    void renameEntry(string path, string newName) {
        features.file.file_ops.renameEntry(path, newName);
    }
}