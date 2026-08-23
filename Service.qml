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

  function run(mode, path, profile) {
    var cmd = ["env"]
    if (profile && profile.length)
      cmd.push("MODELVIEW_PROFILE=" + profile)
    cmd.push("bash", openScript, mode)
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
    target: "local.meshpeek"

    function view(): string {
      root.run("view", "", "clay")
      return "ok"
    }

    function last(): string { return view() }
    function pick(): string { return view() }

    function open(path: string): string {
      root.run("open", path, "clay")
      return "ok"
    }

    function inspect(path: string): string {
      root.run("inspect", path || "", "clay")
      return "ok"
    }

    function studio(): string {
      root.run("view", "", "studio")
      return "ok"
    }
  }
}
