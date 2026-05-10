module features.shell.ui.menu.menu_bar;
import dlangui;
import features.file.file_service;
import features.editor.editor_service;
import features.runner.runner_service;

class MenuBar : MainMenu {

    this(Window window) {
        super();
        layoutWidth = WRAP_CONTENT;

        auto fileMenu = new MenuItem(new Action(1, "ファイル"d));
        fileMenu.add(new MenuItem(new Action(101, "新規ファイル"d)));
        fileMenu.add(new MenuItem(new Action(102, "ファイルを開く"d)));
        fileMenu.add(new MenuItem(new Action(103, "フォルダを開く"d)));
        fileMenu.add(new MenuItem(new Action(104, "保存"d)));
        fileMenu.add(new MenuItem(new Action(105, "名前を付けて保存"d)));

        auto editMenu = new MenuItem(new Action(2, "編集"d));
        editMenu.add(new MenuItem(new Action(201, "元に戻す"d)));
        editMenu.add(new MenuItem(new Action(202, "やり直す"d)));
        editMenu.add(new MenuItem(new Action(203, "切り取り"d)));
        editMenu.add(new MenuItem(new Action(204, "コピー"d)));
        editMenu.add(new MenuItem(new Action(205, "貼り付け"d)));

        auto runMenu = new MenuItem(new Action(3, "実行"d));
        runMenu.add(new MenuItem(new Action(301, "実行"d)));
        runMenu.add(new MenuItem(new Action(302, "ビルド"d)));
        runMenu.add(new MenuItem(new Action(303, "デバッグ"d)));

        auto root = new MenuItem();
        root.add(fileMenu);
        root.add(editMenu);
        root.add(runMenu);

        menuItems = root;

        menuItemClick = delegate(MenuItem item) {
            switch (item.action.id) {
                case 101: FileService.instance.newFile();    break;
                case 102: FileService.instance.openFile();   break;
                case 103: FileService.instance.openFolder(); break;
                case 104: FileService.instance.saveFile();   break;
                case 105: FileService.instance.saveFileAs(); break;

                case 201: EditorService.instance.undo();     break;
                case 202: EditorService.instance.redo();     break;
                case 203: EditorService.instance.cut();      break;
                case 204: EditorService.instance.copy();     break;
                case 205: EditorService.instance.paste();    break;

                case 301: RunnerService.instance.run();      break;
                case 302: RunnerService.instance.build();    break;
                case 303: RunnerService.instance.debug_();   break;

                default: break;
            }
            return true;
        };
    }
}