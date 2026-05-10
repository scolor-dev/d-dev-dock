module features.editor.syntax;

import dlangui.widgets.editors;
import dlangui.widgets.srcedit;
import dlangui.core.editable;

import dparse.lexer;

import std.conv : to;
import std.utf  : toUTF8;

// でバック
import std.file : exists, readText, write;

// ─── libdparse tok → dlangui TokenCategory マッピング ────────────────────────

private ubyte toCategory(IdType t) nothrow {
    import dparse.lexer : tok;
    // isKeyword の代わりに範囲チェック
    // libdparse では キーワードは特定のID範囲にある
    if (t == tok!"abstract" || t == tok!"alias" || t == tok!"align" ||
        t == tok!"asm" || t == tok!"assert" || t == tok!"auto" ||
        t == tok!"bool" || t == tok!"break" || t == tok!"byte" ||
        t == tok!"case" || t == tok!"cast" || t == tok!"catch" ||
        t == tok!"class" || t == tok!"const" || t == tok!"continue" ||
        t == tok!"debug" || t == tok!"default" || t == tok!"delegate" ||
        t == tok!"delete" || t == tok!"deprecated" || t == tok!"do" ||
        t == tok!"double" || t == tok!"else" || t == tok!"enum" ||
        t == tok!"export" || t == tok!"extern" || t == tok!"false" ||
        t == tok!"final" || t == tok!"finally" || t == tok!"float" ||
        t == tok!"for" || t == tok!"foreach" || t == tok!"foreach_reverse" ||
        t == tok!"function" || t == tok!"goto" || t == tok!"if" ||
        t == tok!"immutable" || t == tok!"import" || t == tok!"in" ||
        t == tok!"inout" || t == tok!"int" || t == tok!"interface" ||
        t == tok!"invariant" || t == tok!"is" || t == tok!"lazy" ||
        t == tok!"long" || t == tok!"mixin" || t == tok!"module" ||
        t == tok!"new" || t == tok!"nothrow" || t == tok!"null" ||
        t == tok!"out" || t == tok!"override" || t == tok!"package" ||
        t == tok!"pragma" || t == tok!"private" || t == tok!"protected" ||
        t == tok!"public" || t == tok!"pure" || t == tok!"real" ||
        t == tok!"ref" || t == tok!"return" || t == tok!"scope" ||
        t == tok!"shared" || t == tok!"short" || t == tok!"static" ||
        t == tok!"struct" || t == tok!"super" || t == tok!"switch" ||
        t == tok!"synchronized" || t == tok!"template" || t == tok!"this" ||
        t == tok!"throw" || t == tok!"true" || t == tok!"try" ||
        t == tok!"typedef" || t == tok!"typeid" || t == tok!"typeof" ||
        t == tok!"ubyte" || t == tok!"uint" || t == tok!"ulong" ||
        t == tok!"union" || t == tok!"unittest" || t == tok!"ushort" ||
        t == tok!"version" || t == tok!"void" || t == tok!"while" ||
        t == tok!"with" || t == tok!"__FILE__" || t == tok!"__LINE__" ||
        t == tok!"__gshared" || t == tok!"__traits" || t == tok!"__vector")
        return TokenCategory.Keyword;

    if (t == tok!"stringLiteral" || t == tok!"wstringLiteral" ||
        t == tok!"dstringLiteral" || t == tok!"characterLiteral")
        return TokenCategory.String;

    if (t == tok!"intLiteral" || t == tok!"uintLiteral" ||
        t == tok!"longLiteral" || t == tok!"ulongLiteral")
        return TokenCategory.Integer;

    if (t == tok!"floatLiteral" || t == tok!"doubleLiteral" ||
        t == tok!"realLiteral")
        return TokenCategory.Float;

    if (t == tok!"comment")
        return TokenCategory.Comment;

    if (t == tok!"identifier")
        return TokenCategory.Identifier;

    if (t == tok!"whitespace")
        return TokenCategory.WhiteSpace;

    return TokenCategory.Op;
}

// ─── SyntaxSupport 実装 ───────────────────────────────────────────────────────

class DSyntaxSupport : SyntaxSupport {

    private EditableContent _content;

    // ── EditableContent アクセサ ──────────────────────────────────────────────

    @property EditableContent content() { return _content; }

    @property SyntaxSupport content(EditableContent c) {
        _content = c;
        return this;
    }

    // ── ハイライト ─────────────────────────────────────────────────────────────

    void updateHighlight(dstring[] lines, TokenPropString[] props,
                         int changeStartLine, int changeEndLine)
    {
        if (lines.length == 0) return;
        
        // 全行を結合して libdparse に渡す（ブロックコメント等を正確に処理するため）
        import std.array : join;
        dstring fullText = lines.join("\n"d);
        string src;
        try { src = toUTF8(fullText); } catch (Exception) { return; }

        // 空ファイルは処理しない
        if (src.length == 0) return;

        // レキサー設定
        LexerConfig cfg;
        cfg.stringBehavior = StringBehavior.source;
        cfg.whitespaceBehavior = WhitespaceBehavior.include;
        auto cache  = StringCache(StringCache.defaultBucketCount);
        auto tokens = getTokensForParser(
            cast(ubyte[]) src, cfg, &cache);

        // props をゼロクリア
        foreach (ref p; props) {
            if (p !is null) p[] = 0;
        }

        // トークンを行・列に変換して props に書き込む
        foreach (ref tok; tokens) {
            int  line = cast(int)tok.line - 1;   // libdparse は 1 始まり
            int  col  = cast(int)tok.column - 1; // 同上

            if (line < 0 || line >= cast(int)props.length) continue;
            if (props[line] is null) continue;

            ubyte cat = toCategory(tok.type);
            size_t len = tok.text.length; // UTF-8 バイト数ではなく文字数が必要
            // tok.text は string なので dstring に変換して文字数を得る
            dstring dtxt;
            try {
                import std.utf : toUTF32;
                string rawText = tok.text.length > 0 ? tok.text : str(tok.type);
                if (rawText.length == 0) continue;
                dtxt = toUTF32(rawText);
            } catch (Exception) { continue; }

            // 複数行にまたがるトークン（ブロックコメント・文字列）を処理
            int curLine = line;
            int curCol  = col;
            foreach (dchar ch; dtxt) {
                if (curLine >= cast(int)props.length) break;
                if (ch == '\n') {
                    curLine++;
                    curCol = 0;
                    continue;
                }
                if (props[curLine] !is null
                 && curCol < cast(int)props[curLine].length) {
                    props[curLine][curCol] = cat;
                }
                curCol++;
            }
        }
    }

    // ── 行コメント（// ...） ──────────────────────────────────────────────────

    @property bool supportsToggleLineComment() { return true; }

    bool canToggleLineComment(TextRange range) { return true; }

    void toggleLineComment(TextRange range, Object source) {
        if (!_content) return;
        import std.string : startsWith, stripLeft;

        int startLine = range.start.line;
        int endLine   = range.end.line;
        if (range.end.pos == 0 && endLine > startLine) endLine--;

        // 全行が "//" で始まっているか判定
        bool allCommented = true;
        foreach (ln; startLine .. endLine + 1) {
            dstring s = _content.line(ln);
            if ((cast(string) toUTF8(s)).stripLeft.startsWith("//"))
                continue;
            allCommented = false;
            break;
        }

        foreach (ln; startLine .. endLine + 1) {
            dstring s = _content.line(ln);
            string  u = toUTF8(s);
            import std.utf : toUTF32;

            if (allCommented) {
                // "//" を除去
                import std.string : indexOf;
                auto idx = u.indexOf("//");
                if (idx >= 0)
                    u = u[0 .. idx] ~ u[idx + 2 .. $];
            } else {
                u = "//" ~ u;
            }

            // 行を置換
            TextRange lr;
            lr.start = TextPosition(ln, 0);
            lr.end   = TextPosition(ln, cast(int)s.length);
            _content.performOperation(
                new EditOperation(EditAction.Replace, lr,
                    [toUTF32(u)]), source);
        }
    }

    // ── ブロックコメント（/* ... */）─────────────────────────────────────────

    @property bool supportsToggleBlockComment() { return false; }

    bool canToggleBlockComment(TextRange range) { return false; }

    void toggleBlockComment(TextRange range, Object source) {}

    // ── 対応括弧 ──────────────────────────────────────────────────────────────

    TextPosition findPairedBracket(TextPosition p) {
        if (!_content) return p;

        int line = p.line;
        int col  = p.pos;
        if (line >= _content.length) return p;

        dstring s = _content.line(line);
        if (col >= cast(int)s.length) return p;

        dchar open  = s[col];
        dchar close;
        int   dir;

        switch (open) {
            case '(': close = ')'; dir =  1; break;
            case ')': close = '('; dir = -1; break;
            case '{': close = '}'; dir =  1; break;
            case '}': close = '{'; dir = -1; break;
            case '[': close = ']'; dir =  1; break;
            case ']': close = '['; dir = -1; break;
            default: return p;
        }

        int depth = 1;
        int curLine = line;
        int curCol  = col + dir;

        while (curLine >= 0 && curLine < _content.length) {
            dstring ls = _content.line(curLine);
            int start = (curLine == line) ? curCol
                      : (dir > 0 ? 0 : cast(int)ls.length - 1);
            int end   = (dir > 0) ? cast(int)ls.length : -1;

            for (int c = start; c != end; c += dir) {
                if (c < 0 || c >= cast(int)ls.length) break;
                if (ls[c] == open)  depth++;
                if (ls[c] == close) depth--;
                if (depth == 0) return TextPosition(curLine, c);
            }
            curLine += dir;
            curCol   = (dir > 0) ? 0 : int.max;
        }
        return p;
    }

    // ── スマートインデント ────────────────────────────────────────────────────

    bool supportsSmartIndents() { return false; }

    void applySmartIndent(EditOperation op, Object source) {}
}