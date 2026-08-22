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
    target: "local.modelview"

    function last(): string {
      root.run("last", "", "clay")
      return "ok"
    }

    function pick(): string {
      root.run("pick", "", "clay")
      return "ok"
    }

    function open(path: string): string {
      root.run("open", path, "clay")
      return "ok"
    }

    function inspect(path: string): string {
      root.run("inspect", path || "", "clay")
      return "ok"
    }

    // Optional 3D Artist studio-plastic profile (does not replace clay default)
    function studio(): string {
      root.run("last", "", "studio")
      return "ok"
    }

    function studioPick(): string {
      root.run("pick", "", "studio")
      return "ok"
    }
  }
}
