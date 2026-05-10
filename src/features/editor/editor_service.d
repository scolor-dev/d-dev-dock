module features.editor.editor_service;
import features.editor.ui.editor_area;

class EditorService {

    private static EditorService _instance;
    private void delegate(string)[] _onFileOpenedListeners;
    private EditorArea _editorArea;

    static EditorService instance() {
        if (_instance is null)
            _instance = new EditorService();
        return _instance;
    }

    void setEditorArea(EditorArea area) {
        _editorArea = area;
    }

    void addFileOpenedListener(void delegate(string) listener) {
        _onFileOpenedListeners ~= listener;
    }

    void newFile() {
        if (_editorArea is null) return;
        _editorArea.newFile();
    }

    void openFile(string path) {
        foreach (l; _onFileOpenedListeners)
            l(path);
    }

    string activeFilePath() {
        if (_editorArea is null) return "";
        return _editorArea.activeFilePath();
    }

    dstring activeFileText() {
        if (_editorArea is null) return ""d;
        return _editorArea.activeFileText();
    }

    void updateFilePath(string oldPath, string newPath) {
        if (_editorArea is null) return;
        _editorArea.updateFilePath(oldPath, newPath);
    }

    void undo() {
        // TODO
    }

    void redo() {
        // TODO
    }

    void cut() {
        // TODO
    }

    void copy() {
        // TODO
    }

    void paste() {
        // TODO
    }
}