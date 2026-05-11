module features.shell.ui.output_panel;
import dlangui;
import features.runner.runner_service;
import std.conv : to;

class OutputPanel : VerticalLayout {

    private LogWidget  _log;
    private Button     _btnStop;
    private Button     _btnToggle;
    private bool       _visible = true;
    private int        _expandedHeight = 200;

    this() {
        super("output_panel");
        layoutWidth  = FILL_PARENT;
        layoutHeight = _expandedHeight;
        backgroundColor = 0x1E1E1E;

        // ヘッダー
        auto header = new HorizontalLayout("output_header");
        header.layoutWidth  = FILL_PARENT;
        header.layoutHeight = 28;
        header.backgroundColor = 0x2D2D30;

        auto title = new TextWidget("output_title", "出力"d);
        title.textColor   = 0xCCCCCC;
        title.padding     = Rect(8, 0, 8, 0);
        title.alignment   = Align.Left | Align.VCenter;
        header.addChild(title);

        header.addChild(new HSpacer());

        _btnStop = new Button("btn_stop", "■"d);
        _btnStop.textColor       = 0xCCCCCC;
        _btnStop.backgroundColor = 0x2D2D30;
        _btnStop.layoutWidth     = 28;
        _btnStop.layoutHeight    = 28;
        _btnStop.enabled         = false;
        _btnStop.click = delegate(Widget w) {
            RunnerService.instance.stop();
            return true;
        };
        header.addChild(_btnStop);

        _btnToggle = new Button("btn_toggle", "▼"d);
        _btnToggle.textColor       = 0xCCCCCC;
        _btnToggle.backgroundColor = 0x2D2D30;
        _btnToggle.layoutWidth     = 28;
        _btnToggle.layoutHeight    = 28;
        _btnToggle.click = delegate(Widget w) {
            toggle();
            return true;
        };
        header.addChild(_btnToggle);

        addChild(header);

        // ログ表示
        _log = new LogWidget("output_log");
        _log.layoutWidth  = FILL_PARENT;
        _log.layoutHeight = FILL_PARENT;
        _log.backgroundColor = 0x1E1E1E;
        addChild(_log);

        RunnerService.instance.onFinished = () {
            if (window is null) return;
            window.executeInUiThread({
                _btnStop.enabled = false;
                _btnStop.invalidate();
                _log.appendText("─── 完了 ───\n"d);
            });
        };
    }

    void appendLine(dstring text) {
        _log.appendText(text ~ "\n"d);
    }

    void clear() {
        _log.text = ""d;
    }

    void toggle() {
        _visible = !_visible;
        if (_visible) {
            layoutHeight    = _expandedHeight;
            _log.visibility = Visibility.Visible;
            _btnToggle.text = "▼"d;
        } else {
            layoutHeight    = 28;
            _log.visibility = Visibility.Gone;
            _btnToggle.text = "▲"d;
        }
        invalidate();
        if (parent) parent.requestLayout();
    }

    void onRunStart() {
        _btnStop.enabled = true;
        _btnStop.invalidate();
        clear();
        if (!_visible) toggle();
    }
}