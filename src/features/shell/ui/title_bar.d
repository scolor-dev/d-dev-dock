module features.shell.ui.title_bar;
import dlangui;
import core.sys.windows.windows;
import dlangui.platforms.windows.winapp;
import features.shell.ui.menu.menu_bar;
import common.window.dragger;

class DragSpacer : HSpacer {
    private Dragger _dragger;

    this(Window window) {
        super();
        _dragger = new Dragger(window);
        layoutWidth = FILL_PARENT;
    }

    override bool onMouseEvent(MouseEvent event) {
        if (event.x < 6 || event.y < 6)
            return super.onMouseEvent(event);
        return _dragger.onMouseEvent(event);
    }
}

class TitleBar : HorizontalLayout {
    private Window _window;
    private bool _isMaximized = false;
    private Button _btnMax;
    private RECT _prevRect;
    private Dragger _dragger;

    this(Window window) {
        super("title_bar");
        _dragger = new Dragger(window);
        _window = window;
        layoutWidth  = FILL_PARENT;
        layoutHeight = 40;
        backgroundColor = 0x202020;
        _build();
    }

    override bool onMouseEvent(MouseEvent event) {
        if (event.x < 6 || event.y < 6)
            return super.onMouseEvent(event);
        return _dragger.onMouseEvent(event);
    }

    private void _build() {
        auto icon = new ImageWidget("title_icon", "d_logo_32");
        icon.padding = Rect(8, 4, 8, 4);
        addChild(icon);

        addChild(new MenuBar(_window));
        addChild(new DragSpacer(_window));

        auto btnMin = new Button("btn_minimize", "─"d);
        btnMin.textColor       = 0xFFFFFF;
        btnMin.backgroundColor = 0x202020;
        btnMin.layoutWidth     = 46;
        btnMin.layoutHeight    = 40;
        btnMin.click = delegate(Widget w) {
            auto hwnd = (cast(Win32Window)_window).windowHandle;
            ShowWindow(hwnd, SW_MINIMIZE);
            return true;
        };
        addChild(btnMin);

        _btnMax = new Button("btn_maximize", "□"d);
        _btnMax.textColor       = 0xFFFFFF;
        _btnMax.backgroundColor = 0x202020;
        _btnMax.layoutWidth     = 46;
        _btnMax.layoutHeight    = 40;
        _btnMax.click = delegate(Widget w) {
            auto hwnd = (cast(Win32Window)_window).windowHandle;
            if (_isMaximized) {
                SetWindowPos(
                    hwnd, HWND_TOP,
                    _prevRect.left, _prevRect.top,
                    _prevRect.right - _prevRect.left,
                    _prevRect.bottom - _prevRect.top,
                    SWP_SHOWWINDOW
                );
                _isMaximized = false;
                _btnMax.text = "□"d;
            } else {
                GetWindowRect(hwnd, &_prevRect);
                RECT workArea;
                SystemParametersInfoA(SPI_GETWORKAREA, 0, &workArea, 0);
                SetWindowPos(
                    hwnd, HWND_TOP,
                    workArea.left, workArea.top,
                    workArea.right - workArea.left,
                    workArea.bottom - workArea.top,
                    SWP_SHOWWINDOW
                );
                _isMaximized = true;
                _btnMax.text = "❐"d;
            }
            return true;
        };
        addChild(_btnMax);

        auto btnClose = new Button("btn_close", "✕"d);
        btnClose.textColor       = 0xFFFFFF;
        btnClose.backgroundColor = 0x202020;
        btnClose.layoutWidth     = 46;
        btnClose.layoutHeight    = 40;
        btnClose.click = delegate(Widget w) {
            _window.close();
            return true;
        };
        addChild(btnClose);
    }
}