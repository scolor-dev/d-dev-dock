module common.window.resizer;
import dlangui;
import core.sys.windows.windows;
import dlangui.platforms.windows.winapp;

enum RESIZE_BORDER = 6;

enum ResizeEdge {
    None,
    Left, Right, Top, Bottom,
    TopLeft, TopRight, BottomLeft, BottomRight
}

ResizeEdge detectEdge(HWND hwnd, int x, int y) {
    RECT rc;
    GetWindowRect(hwnd, &rc);
    int w = rc.right  - rc.left;
    int h = rc.bottom - rc.top;

    bool left   = x < RESIZE_BORDER;
    bool right  = x > w - RESIZE_BORDER;
    bool top    = y < RESIZE_BORDER;
    bool bottom = y > h - RESIZE_BORDER;

    if (top    && left)  return ResizeEdge.TopLeft;
    if (top    && right) return ResizeEdge.TopRight;
    if (bottom && left)  return ResizeEdge.BottomLeft;
    if (bottom && right) return ResizeEdge.BottomRight;
    if (left)            return ResizeEdge.Left;
    if (right)           return ResizeEdge.Right;
    if (top)             return ResizeEdge.Top;
    if (bottom)          return ResizeEdge.Bottom;
    return ResizeEdge.None;
}

void updateCursor(ResizeEdge edge) {
    switch (edge) {
        case ResizeEdge.Left:
        case ResizeEdge.Right:
            SetCursor(LoadCursorW(null, IDC_SIZEWE));   break;
        case ResizeEdge.Top:
        case ResizeEdge.Bottom:
            SetCursor(LoadCursorW(null, IDC_SIZENS));   break;
        case ResizeEdge.TopLeft:
        case ResizeEdge.BottomRight:
            SetCursor(LoadCursorW(null, IDC_SIZENWSE)); break;
        case ResizeEdge.TopRight:
        case ResizeEdge.BottomLeft:
            SetCursor(LoadCursorW(null, IDC_SIZENESW)); break;
        default:
            SetCursor(LoadCursorW(null, IDC_ARROW));    break;
    }
}