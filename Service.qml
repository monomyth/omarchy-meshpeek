import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  readonly property string pluginDir: {
    var url = Qt.resolvedUrl(".")
    return url.toString().replace(/^file:\/\//, "").replace(/\/$/, "")
  }
  readonly property string openScript: pluginDir + "/scripts/open.sh"

  function run(mode, path) {
    var cmd = ["bash", openScript, mode]
    if (path && path.length)
      cmd.push(path)
    runner.command = cmd
    runner.running = true
  }

  Process {
    id: runner
    running: false
  }

  IpcHandler {
    target: "local.modelview"

    function last(): string {
      root.run("last", "")
      return "ok"
    }

    function pick(): string {
      root.run("pick", "")
      return "ok"
    }

    function open(path: string): string {
      root.run("open", path)
      return "ok"
    }

    // Manifold/scar check: same clay look + edges
    function inspect(path: string): string {
      root.run("inspect", path || "")
      return "ok"
    }
  }
}
