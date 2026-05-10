module common.fs_watcher;
import core.sys.windows.windows;
import core.thread;
import std.utf : toUTF16z;

class FsWatcher {

    private string _path;
    private bool   _running = false;
    private Thread _thread;
    private HANDLE _handle = INVALID_HANDLE_VALUE;

    void delegate() onChange;

    void start(string path) {
        _path    = path;
        _running = true;

        _thread = new Thread({
            _handle = CreateFileW(
                _path.toUTF16z,
                FILE_LIST_DIRECTORY,
                FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                null,
                OPEN_EXISTING,
                FILE_FLAG_BACKUP_SEMANTICS,
                null
            );

            if (_handle == INVALID_HANDLE_VALUE) return;

            ubyte[4096] buf;
            DWORD bytesReturned;

            while (_running) {
                auto result = ReadDirectoryChangesW(
                    _handle,
                    buf.ptr,
                    cast(DWORD)buf.length,
                    TRUE,
                    FILE_NOTIFY_CHANGE_FILE_NAME |
                    FILE_NOTIFY_CHANGE_DIR_NAME  |
                    FILE_NOTIFY_CHANGE_LAST_WRITE,
                    &bytesReturned,
                    null,
                    null
                );

                if (!result || !_running) break;

                if (onChange !is null)
                    onChange();
            }

            CloseHandle(_handle);
            _handle = INVALID_HANDLE_VALUE;
        });
        _thread.isDaemon = true;
        _thread.start();
    }

    void stop() {
        _running = false;
        if (_handle != INVALID_HANDLE_VALUE)
            CancelIoEx(_handle, null);
    }
}