module features.runner.runner_service;

class RunnerService {

    private static RunnerService _instance;
    static RunnerService instance() {
        if (_instance is null)
            _instance = new RunnerService();
        return _instance;
    }

    void run() {
        // TODO
    }

    void build() {
        // TODO
    }

    void debug_() {
        // TODO
    }
}