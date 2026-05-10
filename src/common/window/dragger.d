module common.window.dragger;
import dlangui;
import core.sys.windows.windows;
import dlangui.platforms.windows.winapp;
import core.thread;

class Dragger {

    private Window _window;
    private bool _dragging = false;
    private int _offsetX, _offsetY;
    private Thread _dragThread;
    private bool _threadRunning = false;

    this(Window window) {
        _window = window;
    }

    bool onMouseEvent(MouseEvent event) {
        auto hwnd = (cast(Win32Window)_window).windowHandle;

        POINT pt;
        GetCursorPos(&pt);

        if (event.action == MouseAction.ButtonDown &&
            event.button == MouseButton.Left) {
            RECT rc;
            GetWindowRect(hwnd, &rc);
            _offsetX  = pt.x - rc.left;
            _offsetY  = pt.y - rc.top;
            _dragging = true;
            SetCapture(hwnd);

            _threadRunning = true;
            _dragThread = new Thread({
                auto h = (cast(Win32Window)_window).windowHandle;
                while (_threadRunning) {
                    // 左ボタンが離れたら終了
                    if (GetAsyncKeyState(VK_LBUTTON) >= 0) {
                        _dragging      = false;
                        _threadRunning = false;
                        ReleaseCapture();
                        break;
                    }

                    POINT p;
                    GetCursorPos(&p);
                    SetWindowPos(h, null,
                        p.x - _offsetX,
                        p.y - _offsetY,
                        0, 0,
                        SWP_NOSIZE | SWP_NOZORDER | SWP_SHOWWINDOW);

                    Thread.sleep(dur!"msecs"(8));
                }
            });
            _dragThread.isDaemon = true;
            _dragThread.start();
            return true;
        }

        if (event.action == MouseAction.ButtonUp &&
            event.button == MouseButton.Left) {
            if (_dragging) {
                _dragging      = false;
                _threadRunning = false;
                ReleaseCapture();
                return true;
            }
        }

        return false;
    }
}