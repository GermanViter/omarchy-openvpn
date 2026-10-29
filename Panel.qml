import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "germanviter.openvpn"

  property var connections: []
  property bool popupOpen: false
  property string actionUuid: ""
  property string actionKind: ""
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: bar ? Qt.darker(bar.foreground, 1.55) : Qt.darker(Color.foreground, 1.55)
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int activeConnections: Model.activeCount(connections)
  readonly property string buttonText: activeConnections > 0 ? "󰖂 VPN " + activeConnections : "󰖂 VPN"
  readonly property bool busy: actionUuid !== ""

  function close() {
    popupOpen = false
  }

  function togglePopup() {
    popupOpen = !popupOpen
    if (popupOpen) refresh()
  }

  function refresh() {
    listProc.running = true
    activeProc.running = true
  }

  function updateList(raw) {
    connections = Model.markActive(Model.parseConnections(raw), activeOutput)
  }

  function updateActive(raw) {
    activeOutput = raw
    connections = Model.markActive(Model.parseConnections(listOutput), raw)
  }

  function runAction(uuid, kind) {
    if (busy) return
    actionUuid = uuid
    actionKind = kind
    actionProc.command = ["nmcli", "connection", kind, "uuid", uuid]
    actionProc.running = true
  }

  function connectionLabel(connection) {
    return connection.name + (connection.active ? " (connected)" : "")
  }

  property string listOutput: ""
  property string activeOutput: ""

  implicitWidth: button.implicitWidth
  implicitHeight: root.barSize

  Process {
    id: listProc
    command: ["nmcli", "-t", "--escape", "no", "-f", "NAME,UUID,TYPE", "connection", "show"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.listOutput = text
        root.updateList(text)
      }
    }
  }

  Process {
    id: activeProc
    command: ["nmcli", "-t", "--escape", "no", "-f", "NAME,UUID,TYPE", "connection", "show", "--active"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateActive(text)
    }
  }

  Process {
    id: actionProc
    onExited: {
      root.actionUuid = ""
      root.actionKind = ""
      root.refresh()
    }
  }

  Timer {
    interval: 5000
    running: root.popupOpen
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: root.refresh()

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.buttonText
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        Quickshell.execDetached(["nm-connection-editor"])
      } else {
        root.togglePopup()
      }
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    triggerMode: "click"
    contentWidth: popup.fittedContentWidth(Style.space(360))
    contentHeight: popup.fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      width: parent.width
      spacing: Style.spacing.xs

      Text {
        text: "OPENVPN CONNECTIONS"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      PanelSeparator { foreground: root.foreground }

      Repeater {
        model: root.connections

        delegate: Rectangle {
          required property var modelData
          width: content.width
          height: row.implicitHeight + Style.space(12)
          color: rowMouse.containsMouse ? Util.alpha(root.foreground, 0.10) : "transparent"
          radius: Style.cornerRadius

          RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            spacing: Style.space(10)

            Text {
              text: modelData.active ? "󰄬" : "󰖂"
              color: modelData.active ? root.foreground : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
            }

            Text {
              Layout.fillWidth: true
              text: root.connectionLabel(modelData)
              color: modelData.active ? root.foreground : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }

            Text {
              text: root.actionUuid === modelData.uuid ? "…" : (modelData.active ? "Disconnect" : "Connect")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          MouseArea {
            id: rowMouse
            anchors.fill: parent
            enabled: !root.busy
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.runAction(modelData.uuid, modelData.active ? "down" : "up")
          }
        }
      }

      Text {
        visible: root.connections.length === 0
        text: "No OpenVPN profiles found"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }

      Rectangle {
        width: content.width
        height: Style.space(34)
        color: editorMouse.containsMouse ? Util.alpha(root.foreground, 0.10) : "transparent"
        radius: Style.cornerRadius

        Text {
          anchors.centerIn: parent
          text: "Open NetworkManager connection editor"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }

        MouseArea {
          id: editorMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached(["nm-connection-editor"])
        }
      }
    }
  }
}
