module features.file.file_ops;
import std.file;
import std.path;

void createFile(string dir, string name) {
    auto path = buildPath(dir, name);
    if (!path.exists)
        write(path, "");
}

void createFolder(string dir, string name) {
    auto path = buildPath(dir, name);
    if (!path.exists)
        mkdir(path);
}

void deleteFile(string path) {
    if (path.exists && path.isFile)
        remove(path);
}

void deleteFolder(string path) {
    if (path.exists && path.isDir)
        rmdirRecurse(path);
}

void renameEntry(string path, string newName) {
    auto newPath = buildPath(path.dirName, newName);
    rename(path, newPath);
}