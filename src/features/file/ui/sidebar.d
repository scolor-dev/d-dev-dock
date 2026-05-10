module features.file.ui.sidebar;
import dlangui;
import common.fs_watcher;
import std.file;
import std.path;
import std.conv;

class SideBar : VerticalLayout {

    private TreeWidget _tree;
    private FsWatcher  _watcher;
    private string     _currentPath;

    void delegate(string) onFileSelected;

    this() {
        super("sidebar");
        layoutWidth     = 240;
        layoutHeight    = FILL_PARENT;
        backgroundColor = 0x252526;

        auto label = new TextWidget("sidebar_label", "エクスプローラー"d);
        label.textColor = 0xFFFFFF;
        label.padding   = Rect(12, 8, 12, 8);
        addChild(label);

        _tree = new TreeWidget("file_tree");
        _tree.layoutWidth  = FILL_PARENT;
        _tree.layoutHeight = FILL_PARENT;
        _tree.backgroundColor = 0x252526;

        _tree.selectionChange = delegate(TreeItems w, TreeItem item, bool activated) {
            if (!activated) return;
            if (onFileSelected is null) return;
            auto path = item.id;
            if (path.exists && path.isFile)
                onFileSelected(path);
        };

        addChild(_tree);
    }

    void loadFolder(string path) {
        _currentPath = path;

        if (_watcher !is null) _watcher.stop();
        _watcher = new FsWatcher();
        _watcher.onChange = {
            window.executeInUiThread({
                _reloadTree();
            });
        };
        _watcher.start(path);

        _reloadTree();
    }

    private void _reloadTree() {
        _tree.items.clear();
        auto root = _tree.items.newChild(
            _currentPath,
            _currentPath.baseName.to!dstring
        );
        _addDir(root, _currentPath);
        _tree.invalidate();
    }

    private void _addDir(TreeItem parent, string path) {
        try {
            foreach (entry; dirEntries(path, SpanMode.shallow)) {
                auto name  = entry.name.baseName;
                auto child = parent.newChild(entry.name, name.to!dstring);
                if (entry.isDir)
                    _addDir(child, entry.name);
            }
        } catch (Exception e) {}
    }
}