module features.runner.runner_config;
import std.file : thisExePath;
import std.path : dirName, buildPath;

string dubPath() {
    return buildPath(thisExePath.dirName, "dmd2", "windows", "bin64", "dub.exe");
}

string dmdPath() {
    return buildPath(thisExePath.dirName, "dmd2", "windows", "bin64", "dmd.exe");
}