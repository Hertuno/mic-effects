import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Presets.js" as Presets

// Bar icon + popup for Microphone Effects, drawn as a rack
// of console units rather than a settings list.
//
// The shape of it: the source, the meters and mute/monitor/level are pinned at
// the top and never scroll, because those are what a call needs. Under them a
// rail of stage modules is both the status display (a lit LED means engaged)
// and the selector, and only the stage you pick opens below it. Ten stages and
// their controls therefore cost the height of one stage, not the whole rack.
Panel {
  id: root
  moduleName: "whoiscalebbrown.mic-effects"
  ipcTarget: "whoiscalebbrown.mic-effects"

  // Stock bar: serviceFor() returns the keepLoaded Service.
  // Third-party bars (Islands, clones): serviceFor() is null — use DaemonBridge
  // so the rack still talks to ctl.sock. See Omarchy #13289.
  readonly property var hostedSvc: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor("whoiscalebbrown.mic-effects") : null
  readonly property var svc: hostedSvc || bridge
  DaemonBridge {
    id: bridge
    bridgeActive: !root.hostedSvc
  }

  readonly property var m: svc ? svc.settings : ({})
  readonly property bool connected: svc ? svc.connected : false
  readonly property bool muted: svc ? svc.muted : false
  readonly property bool live: svc ? (svc.active && !muted) : false
  readonly property bool alwaysShow: setting("alwaysShow", true)

  visible: alwaysShow || muted || live
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function close() { controller.hide() }
  function userClose() { controller.hide() }
  function toggle() { opened ? userClose() : open() }

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(fg, 1.45)
  readonly property color eng: Qt.darker(fg, 1.9)
  readonly property color accent: Color.popups.border
  readonly property color menuSurface: Qt.rgba(Color.popups.background.r,
                                                Color.popups.background.g,
                                                Color.popups.background.b, 1)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int rowH: Style.spacing.popupRowHeight
  readonly property int inset: Style.space(11)
  readonly property real popupScale: 1.35

  readonly property var chain: svc ? svc.chain : []
  property string stage: "comp"

  readonly property var stageLabels: ({
    hpf: "HPF", hum: "HUM", nr: "NR", gate: "GATE", comp: "COMP",
    deess: "DE-S", eq: "EQ", pitch: "PITCH", fx: "FX", verb: "VERB", limit: "LIMIT"
  })

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.muted ? "\uf131" : "\uf130"
    active: root.muted || root.live
    useActiveColor: true
    activeColor: root.muted ? Color.urgent : root.fg
    onPressed: function(b) {
      if (b === Qt.RightButton && root.svc) root.svc.toggleMuted()
      else root.toggle()
    }
  }
}
