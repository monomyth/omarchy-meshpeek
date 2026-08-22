import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  readonly property string pluginDir: {
    // Plugin files live next to this service entry.
    var url = Qt.resolvedUrl(".")
    return url.toString().replace(/^file:\/\//, "").replace(/\/$/, "")
  }
  readonly property string openScript: pluginDir + "/scripts/open.sh"

  function run(mode, path) {
    var envUp = "+Z"
    var watch = ""
    // Bar widget settings are not available on the service; env overrides from
    // the wrapper bind can set MODELVIEW_UP / MODELVIEW_WATCH_DIRS.
    var cmd = ["bash", openScript, mode]
    if (mode === "open" && path && path.length)
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
  }
}
