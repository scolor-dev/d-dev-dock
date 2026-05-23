module features.editor.ui.editor_area;
import dlangui;
import dlangui.widgets.srcedit;
import features.editor.ui.editor_pane;
import std.path : baseName;
import std.conv : to;

class EditorArea : VerticalLayout {

    private TabWidget          _tabs;
    private EditorPane[string] _editors;
    private string             _activeFile;
    private int                _newFileCount = 0;

    this() {
        super("editor_area");
        layoutWidth     = FILL_PARENT;
        layoutHeight    = FILL_PARENT;
        backgroundColor = 0x1E1E1E;

        _tabs = new TabWidget("editor_tabs");
        _tabs.layoutWidth  = FILL_PARENT;
        _tabs.layoutHeight = FILL_PARENT;

        _tabs.tabChanged = delegate(string newId, string oldId) {
            _activeFile = newId;
        };

        _tabs.tabClose = delegate(string tabId) {
            _editors.remove(tabId);
            _tabs.removeTab(tabId);
            if (_tabs.tabCount == 0) {
                _activeFile = "";
            } else {
                // アクティブファイルが削除されたタブだった場合
                if (_activeFile == tabId) {
                    _activeFile = _tabs.selectedTabId;
                }
            }
        };

        addChild(_tabs);
    }

    void newFile() {
        _newFileCount++;
        auto tabId    = "new_" ~ _newFileCount.to!string;
        auto baseLabel = ("新規 " ~ _newFileCount.to!string).to!dstring;

        auto pane = new EditorPane(tabId);
        pane.id   = tabId;

        pane.onDirtyChanged = () {
            _tabs.renameTab(tabId, pane.dirty ? baseLabel ~ "*"d : baseLabel);
        };

        _editors[tabId] = pane;
        _tabs.addTab(pane, baseLabel, null, true);
        _tabs.selectTab(tabId);
        _activeFile = tabId;
    }

    void openFile(string path) {
        if (path in _editors) {
            _tabs.selectTab(path);
            return;
        }

        auto baseLabel = path.baseName.to!dstring;
        auto pane = new EditorPane(path);
        pane.id   = path;

        pane.onDirtyChanged = () {
            _tabs.renameTab(path, pane.dirty ? baseLabel ~ "*"d : baseLabel);
        };

        _editors[path] = pane;
        _tabs.addTab(pane, baseLabel, null, true);
        _tabs.selectTab(path);
        _activeFile = path;
    }

    void markClean(string path) {
        if (auto p = path in _editors)
            (*p).markClean();
    }

    EditorPane activeEditor() {
        if (_activeFile.length == 0) return null;
        if (auto p = _activeFile in _editors) return *p;
        return null;
    }

    string activeFilePath() {
        return _activeFile;
    }

    dstring activeFileText() {
        auto ed = activeEditor();
        if (ed is null) return ""d;
        return ed.text;
    }

    void updateFilePath(string oldPath, string newPath) {
        if (oldPath !in _editors) return;
        auto ed = _editors[oldPath];
        _editors.remove(oldPath);
        _editors[newPath] = ed;
        _activeFile = newPath;
    }
}