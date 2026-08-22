import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "local.modelview"

  readonly property bool showIcon: setting("showIcon", false) === true
  readonly property string upAxis: String(setting("upAxis", "+Z"))
  readonly property string watchDirs: String(setting("watchDirs", ""))

  readonly property string pluginDir: {
    var url = Qt.resolvedUrl(".")
    return url.toString().replace(/^file:\/\//, "").replace(/\/$/, "")
  }
  readonly property string openScript: pluginDir + "/scripts/open.sh"

  implicitWidth: showIcon ? button.implicitWidth : 0
  implicitHeight: showIcon ? button.implicitHeight : 0
  visible: showIcon

  function launch(mode) {
    runner.command = [
      "env",
      "MODELVIEW_UP=" + upAxis,
      "MODELVIEW_WATCH_DIRS=" + watchDirs,
      "bash", openScript, mode
    ]
    runner.running = true
  }

  Process {
    id: runner
    running: false
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    visible: root.showIcon
    // Nerd Font: cube
    text: "󰆧"
    slotSize: Style.bar.statusSlot
    tooltipText: "Model View — left: last export, right: pick file"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton)
        root.launch("pick")
      else
        root.launch("last")
    }
  }
}
