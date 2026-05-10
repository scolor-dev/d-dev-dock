module features.file.file_dialog;

version(Windows):

import core.sys.windows.windows;
import core.sys.windows.objbase;

enum COINIT_APARTMENTTHREADED = 0x2;

import core.stdc.wchar_ : wcslen;

import std.conv : to;

alias FILEOPENDIALOGOPTIONS = uint;

enum : FILEOPENDIALOGOPTIONS {
    FOS_OVERWRITEPROMPT   = 0x00000002,
    FOS_STRICTFILETYPES   = 0x00000004,
    FOS_NOCHANGEDIR       = 0x00000008,
    FOS_PICKFOLDERS       = 0x00000020,
    FOS_FORCEFILESYSTEM   = 0x00000040,
    FOS_FILEMUSTEXIST     = 0x00001000,
    FOS_PATHMUSTEXIST     = 0x00000800,
}

enum SIGDN : uint {
    SIGDN_FILESYSPATH = 0x80058000
}

enum CLSCTX_INPROC_SERVER = 0x1;

extern(Windows)
interface IShellItem : IUnknown {
    HRESULT BindToHandler();
    HRESULT GetParent(IShellItem*);
    HRESULT GetDisplayName(SIGDN sigdnName, wchar** ppszName);
}

extern(Windows)
interface IModalWindow : IUnknown {
    HRESULT Show(HWND parent);
}

extern(Windows)
interface IFileDialog : IModalWindow {
    HRESULT SetFileTypes();
    HRESULT SetFileTypeIndex();
    HRESULT GetFileTypeIndex();
    HRESULT Advise();
    HRESULT Unadvise();
    HRESULT SetOptions(FILEOPENDIALOGOPTIONS fos);
    HRESULT GetOptions(FILEOPENDIALOGOPTIONS* pfos);
    HRESULT SetDefaultFolder(IShellItem psi);
    HRESULT SetFolder(IShellItem psi);
    HRESULT GetFolder(IShellItem* ppsi);
    HRESULT GetCurrentSelection(IShellItem* ppsi);
    HRESULT SetFileName(wchar* pszName);
    HRESULT GetFileName(wchar** pszName);
    HRESULT SetTitle(wchar* pszTitle);
    HRESULT SetOkButtonLabel(wchar* pszText);
    HRESULT SetFileNameLabel(wchar* pszLabel);
    HRESULT GetResult(IShellItem* ppsi);
}

extern(Windows)
interface IFileOpenDialog : IFileDialog {
}

__gshared const GUID CLSID_FileOpenDialog =
{
    0xDC1C5A9C,
    0xE88A,
    0x4DDE,
    [0xA5, 0xA1, 0x60, 0xF8, 0x2A, 0x20, 0xAE, 0xF7]
};

__gshared const GUID IID_IFileOpenDialog =
{
    0xD57C7288,
    0xD4AD,
    0x4768,
    [0xBE, 0x02, 0x9D, 0x96, 0x95, 0x32, 0xD9, 0x60]
};

private string shellItemPath(IShellItem item) {
    wchar* rawPath = null;

    auto hr = item.GetDisplayName(
        SIGDN.SIGDN_FILESYSPATH,
        &rawPath
    );

    if (FAILED(hr) || rawPath is null)
        return null;

    scope(exit) CoTaskMemFree(rawPath);

    return to!string(rawPath[0 .. wcslen(rawPath)]);
}

private string showDialog(HWND hwnd, bool folderMode) {
    CoInitializeEx(null, COINIT_APARTMENTTHREADED);
    scope(exit) CoUninitialize();

    IFileOpenDialog dialog;

    auto hr = CoCreateInstance(
        &CLSID_FileOpenDialog,
        null,
        CLSCTX_INPROC_SERVER,
        &IID_IFileOpenDialog,
        cast(void**) &dialog
    );

    if (FAILED(hr) || dialog is null)
        return null;

    scope(exit) dialog.Release();

    FILEOPENDIALOGOPTIONS options;

    hr = dialog.GetOptions(&options);

    if (FAILED(hr))
        return null;

    options |=
        FOS_FORCEFILESYSTEM |
        FOS_PATHMUSTEXIST;

    if (folderMode) {
        options |= FOS_PICKFOLDERS;
    } else {
        options |= FOS_FILEMUSTEXIST;
    }

    hr = dialog.SetOptions(options);

    if (FAILED(hr))
        return null;

    hr = dialog.Show(hwnd);

    // キャンセル
    if (hr == cast(HRESULT)0x800704C7)
        return null;

    if (FAILED(hr))
        return null;

    IShellItem item;

    hr = dialog.GetResult(&item);

    if (FAILED(hr) || item is null)
        return null;

    scope(exit) item.Release();

    return shellItemPath(item);
}

/// IFileOpenDialog を使ってフォルダを選択する
/// 戻り値: 選択されたパス。キャンセルなら null
string showFolderDialog(HWND hwnd) {
    return showDialog(hwnd, true);
}

/// IFileOpenDialog を使ってファイルを選択する
/// 戻り値: 選択されたパス。キャンセルなら null
string showFileDialog(HWND hwnd) {
    return showDialog(hwnd, false);
}