module features.runner.runner_service;
import features.runner.dub_runner;
import features.file.file_dialog;

class RunnerService {

    private static RunnerService _instance;
    private DubRunner _runner;
    private string _projectPath;
    private string _initPath;

    void delegate() onFinished;
    void delegate(string) onProjectInitialized;

    static RunnerService instance() {
        if (_instance is null)
            _instance = new RunnerService();
        return _instance;
    }

    this() {
        _runner = new DubRunner();
        _runner.onFinished = () {
            if (_initPath.length > 0) {
                auto p = _initPath;
                _initPath = null;
                if (onProjectInitialized !is null)
                    onProjectInitialized(p);
            }
            if (onFinished !is null)
                onFinished();
        };
    }

    void setProjectPath(string path) {
        _projectPath = path;
    }

    void run() {
        _runner.run(_projectPath, ["run"]);
    }

    void build() {
        _runner.run(_projectPath, ["build"]);
    }

    void debug_() {
        _runner.run(_projectPath, ["run", "--build=debug"]);
    }

    void init_() {
        auto path = showFolderDialog(null);
        if (path is null) return;
        _initPath = path;
        _projectPath = path;
        _runner.run(path, ["init", "--non-interactive"]);
    }

    void stop() {
        _runner.stop();
    }

    bool isRunning() {
        return _runner.isRunning();
    }
}