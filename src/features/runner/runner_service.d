module features.runner.runner_service;
import features.runner.dub_runner;

class RunnerService {

    private static RunnerService _instance;
    private DubRunner _runner;
    private string _projectPath;

    void delegate() onFinished;

    static RunnerService instance() {
        if (_instance is null)
            _instance = new RunnerService();
        return _instance;
    }

    this() {
        _runner = new DubRunner();
        _runner.onFinished = () {
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

    void stop() {
        _runner.stop();
    }

    bool isRunning() {
        return _runner.isRunning();
    }
}