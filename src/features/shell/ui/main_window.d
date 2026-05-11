module features.shell.ui.main_window;
import dlangui;
import core.sys.windows.windows;
import dlangui.platforms.windows.winapp;
import features.shell.ui.title_bar;
import features.shell.ui.output_panel;
import features.file.ui.sidebar;
import features.file.file_service;
import features.editor.editor_service;
import features.editor.ui.editor_area;
import features.runner.runner_service;
import common.window.resizer;
import core.thread;


class MainWindow : VerticalLayout {

    private Window _window;
    private SideBar _sidebar;
    private EditorArea _editorArea;
    private OutputPanel _outputPanel;
    private bool _dragging = false;
    private ResizeEdge _edge = ResizeEdge.None;
    private int _startX, _startY;
    private RECT _startRect;
    private Thread _resizeThread;
    private bool _threadRunning = false;

    this(Window window) {
        super("main_window");
        _window = window;
        layoutWidth  = FILL_PARENT;
        layoutHeight = FILL_PARENT;

        _sidebar = new SideBar(window);
        _editorArea = new EditorArea();
        _outputPanel = new OutputPanel();

        EditorService.instance.setEditorArea(_editorArea);

        // フォルダが開かれたらサイドバーに通知
        FileService.instance.addFolderOpenedListener((string path) {
            _sidebar.loadFolder(path);
            RunnerService.instance.setProjectPath(path);
        });

        // ファイルが開かれたらエディタに通知
        FileService.instance.addFileOpenedListener((string path) {
            _editorArea.openFile(path);
        });
        EditorService.instance.addFileOpenedListener((string path) {
            _editorArea.openFile(path);
        });

        // サイドバーのファイルクリック
        _sidebar.onFileSelected = (string path) {
            EditorService.instance.openFile(path);
        };

        addChild(new TitleBar(window));
        addChild(_buildBody());
        addChild(_buildStatusBar());
    }

    override bool onMouseEvent(MouseEvent event) {
        auto hwnd = (cast(Win32Window)_window).windowHandle;

        POINT pt;
        GetCursorPos(&pt);
        int sx = pt.x, sy = pt.y;

        RECT rc;
        GetWindowRect(hwnd, &rc);
        int localX = sx - rc.left;
        int localY = sy - rc.top;
    
        

        if (event.action == MouseAction.Move) {
            if (!_dragging) {
                auto edge = detectEdge(hwnd, localX, localY);
                updateCursor(edge);
            }
        }

        if (event.action == MouseAction.ButtonUp) {
            _sidebar.closeCurrentPopup();
        }

        if (event.action == MouseAction.ButtonDown &&
            event.button == MouseButton.Left) {
            auto edge = detectEdge(hwnd, localX, localY);
            if (edge != ResizeEdge.None) {
                _edge     = edge;
                _dragging = true;
                _startX   = sx;
                _startY   = sy;
                GetWindowRect(hwnd, &_startRect);
                SetCapture(hwnd);

                _threadRunning = true;
                _resizeThread = new Thread({
                    auto h = (cast(Win32Window)_window).windowHandle;
                    while (_threadRunning) {
                        if (GetAsyncKeyState(VK_LBUTTON) >= 0) {
                            _dragging      = false;
                            _threadRunning = false;
                            _edge          = ResizeEdge.None;
                            ReleaseCapture();
                            break;
                        }

                        POINT p;
                        GetCursorPos(&p);

                        RECT cur;
                        GetWindowRect(h, &cur);
                        int l = cur.left;
                        int t = cur.top;
                        int r = cur.right;
                        int b = cur.bottom;

                        final switch (_edge) {
                            case ResizeEdge.Left:        l = p.x; break;
                            case ResizeEdge.Right:       r = p.x; break;
                            case ResizeEdge.Top:         t = p.y; break;
                            case ResizeEdge.Bottom:      b = p.y; break;
                            case ResizeEdge.TopLeft:     l = p.x; t = p.y; break;
                            case ResizeEdge.TopRight:    r = p.x; t = p.y; break;
                            case ResizeEdge.BottomLeft:  l = p.x; b = p.y; break;
                            case ResizeEdge.BottomRight: r = p.x; b = p.y; break;
                            case ResizeEdge.None: break;
                        }

                        if (r - l < 400) r = l + 400;
                        if (b - t < 300) b = t + 300;

                        SetWindowPos(h, null, l, t, r - l, b - t,
                            SWP_NOZORDER | SWP_SHOWWINDOW);

                        Thread.sleep(dur!"msecs"(8));
                    }
                });
                _resizeThread.isDaemon = true;
                _resizeThread.start();
                return true;
            }
        }

        if (event.action == MouseAction.ButtonUp &&
            event.button == MouseButton.Left) {
            if (_dragging) {
                _dragging      = false;
                _threadRunning = false;
                _edge          = ResizeEdge.None;
                ReleaseCapture();
                return true;
            }
        }

        return super.onMouseEvent(event);
    }

    private Widget _buildBody() {
        auto body_ = new HorizontalLayout("body");
        body_.layoutWidth  = FILL_PARENT;
        body_.layoutHeight = FILL_PARENT;
        body_.addChild(_sidebar);

        auto right = new VerticalLayout("right_panel");
        right.layoutWidth  = FILL_PARENT;
        right.layoutHeight = FILL_PARENT;
        right.addChild(_editorArea);
        right.addChild(_outputPanel);

        body_.addChild(right);
        return body_;
    }

    private Widget _buildStatusBar() {
        auto bar = new HorizontalLayout("status_bar");
        bar.layoutWidth  = FILL_PARENT;
        bar.layoutHeight = 24;
        bar.backgroundColor = 0xB03030;

        auto label = new TextWidget("status_label", "準備完了"d);
        label.textColor = 0xFFFFFF;
        label.padding   = Rect(8, 4, 8, 4);
        label.alignment = Align.Left | Align.VCenter;
        bar.addChild(label);

        return bar;
    }

    void setStatus(dstring text) {
        auto label = childById!TextWidget("status_label");
        if (label) label.text = text;
    }

    ~this() {
        _threadRunning = false;
    }
}