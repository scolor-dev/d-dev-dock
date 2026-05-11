module features.file.ui.sidebar;
import dlangui;
import dlangui.dialogs.inputbox;
import common.fs_watcher;
import features.file.file_service;
import std.file;
import std.path;
import std.conv;

class SideBar : VerticalLayout {

    private TreeWidget _tree;
    private FsWatcher  _watcher;
    private PopupMenu _currentPopup;
    private string     _currentPath;
    private Window     _window;

    void delegate(string) onFileSelected;

    this(Window window) {
        super("sidebar");
        _window         = window;
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

        _tree.mouseEvent = delegate(Widget w, MouseEvent e) {
            if (e.action == MouseAction.ButtonDown &&
                e.button == MouseButton.Right) {
                auto item = _tree.items.selectedItem;
                if (item !is null)
                    _showContextMenu(item, e.x, e.y);
                return true;
            }
            return false;
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

    private void _showContextMenu(TreeItem item, int x, int y) {
        auto path   = item.id;
        bool isDir_ = path.exists && path.isDir;

        auto menu = new MenuItem();
        if (isDir_) {
            menu.add(new MenuItem(new Action(1, "新規ファイル"d)));
            menu.add(new MenuItem(new Action(2, "新規フォルダ"d)));
        }
        menu.add(new MenuItem(new Action(3, "名前変更"d)));
        menu.add(new MenuItem(new Action(4, "削除"d)));

        auto popup = new PopupMenu(menu);
        popup.menuItemClick = delegate(MenuItem mi) {
            switch (mi.action.id) {
                case 1: _createFile(path);   break;
                case 2: _createFolder(path); break;
                case 3: _rename(path);       break;
                case 4: _delete(path);       break;
                default: break;
            }
            _currentPopup = null;
            return true;
        };

        _currentPopup = popup;
        _window.showPopup(popup, _tree, PopupAlign.Point, x, y);
        popup.setFocus();
    }

    void closeCurrentPopup() {
        if (_currentPopup !is null) {
            _currentPopup.close();
            _currentPopup = null;
        }
    }

    private void _createFile(string dir) {
        new InputBox(
            UIString.fromRaw("新規ファイル"d),
            UIString.fromRaw("ファイル名を入力してください"d),
            _window,
            ""d,
            (dstring result) {
                if (result.length > 0)
                    FileService.instance.createFile(dir, result.to!string);
            }
        ).show();
    }

    private void _createFolder(string dir) {
        new InputBox(
            UIString.fromRaw("新規フォルダ"d),
            UIString.fromRaw("フォルダ名を入力してください"d),
            _window,
            ""d,
            (dstring result) {
                if (result.length > 0)
                    FileService.instance.createFolder(dir, result.to!string);
            }
        ).show();
    }

    private void _rename(string path) {
        new InputBox(
            UIString.fromRaw("名前変更"d),
            UIString.fromRaw("新しい名前を入力してください"d),
            _window,
            path.baseName.to!dstring,
            (dstring result) {
                if (result.length > 0)
                    FileService.instance.renameEntry(path, result.to!string);
            }
        ).show();
    }

    private void _delete(string path) {
        _window.showMessageBox(
            "削除確認"d,
            ("「" ~ path.baseName ~ "」を削除しますか？").to!dstring,
            [ACTION_YES, ACTION_NO],
            0,
            delegate bool(const Action result) {
                if (result.id == ACTION_YES.id)
                    FileService.instance.deleteEntry(path);
                return true;
            }
        );
    }

    private void _reloadTree() {
        _tree.items.clear();
        auto root = _tree.items.newChild(
            _currentPath,
            (_currentPath.baseName ~ "/").to!dstring
        );
        _addDir(root, _currentPath);
        _tree.invalidate();
    }

    private void _addDir(TreeItem parent, string path) {
        try {
            foreach (entry; dirEntries(path, SpanMode.shallow)) {
                auto name  = entry.name.baseName;
                auto label = (name ~ (entry.isDir ? "/" : "")).to!dstring;
                auto child = parent.newChild(entry.name, label);
                if (entry.isDir)
                    _addDir(child, entry.name);
            }
        } catch (Exception e) {}
    }
}