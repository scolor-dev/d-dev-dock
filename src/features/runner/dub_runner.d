module features.runner.dub_runner;
import std.process;
import core.thread;
import features.runner.runner_config;

class DubRunner {

    private Pid  _pid;
    private bool _running = false;

    void delegate() onFinished;

    bool isRunning() { return _running; }

    void run(string projectPath, string[] args) {
        if (_running) return;
        _running = true;

        auto cmd = [dubPath()] ~ args;

        auto t = new Thread({
            try {
                _pid = spawnProcess(cmd, null, Config.none, projectPath);
                wait(_pid);
            } catch (Exception e) {}
            _running = false;
            if (onFinished !is null)
                onFinished();
        });
        t.isDaemon = true;
        t.start();
    }

    void stop() {
        if (!_running || _pid is null) return;
        try { kill(_pid); } catch (Exception e) {}
        _running = false;
    }
}