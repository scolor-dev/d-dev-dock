module app;
import dlangui;
import features.shell.ui.main_window;

mixin APP_ENTRY_POINT;

extern (C) int UIAppMain(string[] args) {
    embeddedResourceList.addResources(
        embedResourcesFromList!("resources.list")()
    );
    
    Platform.instance.uiTheme = "theme_dark";
    currentTheme.fontFace = "Meiryo UI,Yu Gothic UI,Meiryo";

    Window window = Platform.instance.createWindow(
        "D Dev Dock"d,
        null,
        WindowFlag.Borderless | WindowFlag.Resizable,
        1200, 680
    );

    window.mainWidget = new MainWindow(window);
    window.show();
    return Platform.instance.enterMessageLoop();
}