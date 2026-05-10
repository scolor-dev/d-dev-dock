module features.editor.ui.editor_pane;
import dlangui;
import dlangui.widgets.srcedit;
import dlangui.core.editable;
import features.editor.syntax;
import std.file  : exists, readText;
import std.conv  : to;
import std.utf   : toUTF32;
import std.path  : baseName, extension;

class EditorPane : SourceEdit {

    private string _path;

    this(string path) {
        super(path);
        _path        = path;
        layoutWidth  = FILL_PARENT;
        layoutHeight = FILL_PARENT;

        if (path.length > 0 && path.exists) {
            try {
                text = toUTF32(readText(path));
            } catch (Exception) {}
        }

        if (path.extension == ".d") {
            content.syntaxSupport = new DSyntaxSupport();
            setTokenHightlightColor(TokenCategory.Keyword,    0x00FB4934);
            setTokenHightlightColor(TokenCategory.String,     0x00B8BB26);
            setTokenHightlightColor(TokenCategory.Comment,    0x00928374);
            setTokenHightlightColor(TokenCategory.Integer,    0x00D3869B);
            setTokenHightlightColor(TokenCategory.Float,      0x00D3869B);
            setTokenHightlightColor(TokenCategory.Identifier, 0x0083A598);
            setTokenHightlightColor(TokenCategory.Op,         0x00D4BE98);
        }
    }

    string path() { return _path; }
}