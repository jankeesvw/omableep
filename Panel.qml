import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Omableep: a soundboard whose pads are arithmetic rather than audio files.
//
// Nothing here ships a sample. `bin/omableep` reads pads.json, renders the pad
// on the spot and pipes the bytes into whatever player the machine has. A pad
// costs a few milliseconds, which is why there is no cache, and why this
// plugin never writes a file anywhere.
//
// Structured after the stock Basecamp plugin: a Panel root owning the
// open/close lifecycle, a BarIconButton in the bar, a KeyboardPanel for the
// card. KeyboardPanel rather than PopupCard because a PopupWindow never gets
// keyboard focus on Wayland, and a soundboard you cannot fire from the number
// row is a soundboard with the point taken out.
Panel {
  id: root

  moduleName: "jankeesvw.omableep"
  ipcTarget: "jankeesvw.omableep"

  // The renderer sits next to this file, so the plugin runs from wherever it
  // was installed without putting anything on $PATH.
  readonly property string script:
    Qt.resolvedUrl("bin/omableep").toString().replace(/^file:\/\//, "")

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // [{ id, label, pads: [{ label }] }], as the renderer hands them over.
  property var boards: []
  property int boardIndex: 0
  property int cursor: 0
  property real gain: 0.7
  property string loadError: ""
  property string playError: ""
  // Set for a moment after a pad fires, so the bar icon acknowledges a press
  // made from a keybinding while the panel is shut.
  property bool flashing: false

  readonly property int columns: 2
  readonly property var board: boards.length > 0 && boardIndex < boards.length
                               ? boards[boardIndex] : null
  readonly property var pads: board ? board.pads : []

  // Panel is a bare Item, so it has no size of its own and the bar would give
  // the widget zero width. Set it here, never from a child that fills this
  // item: that is a loop where nothing decides the size and everything
  // collapses to zero.
  readonly property int barSlot: Style.bar.iconFont + Style.space(14)
  implicitWidth: bar && bar.vertical ? (bar ? bar.barSize : Style.bar.sizeHorizontal) : barSlot
  implicitHeight: bar && bar.vertical ? barSlot : (bar ? bar.barSize : Style.bar.sizeHorizontal)

  // Strip the markup characters out of anything that came from pads.json
  // before it reaches a Text the shell owns. Every Text in this file is pinned
  // to PlainText, but the shared bar tooltip is the shell's component and its
  // textFormat is not ours to set. The renderer strips these too; this is the
  // second of the two places that has to be right.
  function plain(value) {
    return String(value === undefined || value === null ? "" : value)
      .replace(/[<>&]/g, "")
      .slice(0, 40)
  }

  // A for the first board, B for the second, up to the twelfth. The letter is
  // the position rather than something the file gets to name, so it cannot
  // collide with the digits and two boards cannot claim the same key.
  function boardKey(index) {
    return String.fromCharCode(65 + index)
  }

  function selectBoard(index) {
    if (boards.length === 0) return
    boardIndex = ((index % boards.length) + boards.length) % boards.length
    cursor = 0
  }

  function moveCursor(step) {
    if (pads.length === 0) return
    var next = cursor + step
    if (next < 0 || next >= pads.length) return
    cursor = next
  }

  function setGain(value) {
    gain = Math.max(0, Math.min(1, Math.round(value * 20) / 20))
  }

  // Fire a pad on the first free player. The pool is fixed, so holding a key
  // down cannot spawn processes without end; past the last free slot the
  // oldest one is taken over, which is what a hardware pad does too.
  function fire(index) {
    if (!board || index < 0 || index >= pads.length) return
    if (gain <= 0) return

    var slot = null
    for (var i = 0; i < players.count; i++) {
      var candidate = players.itemAt(i)
      if (candidate && !candidate.proc.running) { slot = candidate; break }
    }
    if (slot === null) {
      slot = players.itemAt(root.nextVictim % players.count)
      root.nextVictim = (root.nextVictim + 1) % players.count
      if (slot) slot.stop()
    }
    if (slot) { root.playError = ""; slot.play(board.id, index, gain) }

    flashing = true
    flashTimer.restart()
  }

  property int nextVictim: 0

  // Cut everything that is sounding. The pads are short, but SIREN is a second
  // and a half and RING is two, and there has to be a way to take it back.
  function panic() {
    for (var i = 0; i < players.count; i++) {
      var slot = players.itemAt(i)
      if (slot) slot.stop()
    }
  }

  // No close() of our own. Panel already has one, KeyboardPanel calls it when
  // it closes itself, and shadowing it here only breaks that path: `opened` is
  // read-only, so the override threw on every close. Nothing needs cleaning up
  // when the card goes away either, because a pad that is still sounding
  // should finish; stopping one is what the panic key is for.

  Timer {
    id: flashTimer
    interval: 140
    onTriggered: root.flashing = false
  }

  // ---------------------------------------------------------------- the pool

  // Six players, so a handful of pads can overlap the way they would on a real
  // board, and no more than six processes can ever exist because of this
  // plugin. Each slot owns its Process handle, which is what makes stopping
  // safe: the handle is the identity, so there is no stored pid to be reused
  // by something else between the decision to stop and the signal.
  Repeater {
    id: players
    model: 6

    Item {
      id: slot
      readonly property alias proc: playerProc

      function play(boardId, index, level) {
        playerProc.command = ["/usr/bin/python3", "-I", "-S", root.script,
                              "play", boardId, String(index), level.toFixed(2)]
        playerProc.running = true
      }

      function stop() {
        if (!playerProc.running) return
        playerProc.signal(15)
        killTimer.restart()
      }

      Process {
        id: playerProc
        // No stdout binding at all: this process is started for its side effect
        // and says nothing worth keeping. Anything it did write would be a
        // buffer inside the shell that nobody bounds.

        // A refused pad exits non-zero, and a stop from the panel exits zero,
        // so this fires only for a real failure. Without it a soundboard that
        // has gone silent looks exactly like one nobody pressed.
        onExited: function(code, status) {
          if (code !== 0) root.playError = "a pad could not be played"
        }
      }

      // A player that ignores the polite signal gets two seconds and then does
      // not get a say. Without this a wedged audio sink holds a slot for the
      // rest of the session.
      Timer {
        id: killTimer
        interval: 2000
        onTriggered: if (playerProc.running) playerProc.signal(9)
      }

      Component.onDestruction: if (playerProc.running) playerProc.signal(9)
    }
  }

  Component.onDestruction: root.panic()

  // -------------------------------------------------------------- the boards

  Process {
    id: boardsProc
    running: true
    command: ["/usr/bin/python3", "-I", "-S", root.script, "boards"]

    property string buffer: ""

    // SplitParser with an empty marker rather than StdioCollector: the
    // collector keeps the whole of stdout before anything of ours can look at
    // its length, and this is the one place where output comes back at all.
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (boardsProc.buffer.length > 262144) return
        boardsProc.buffer += chunk
      }
    }

    onExited: function(code, status) {
      var raw = boardsProc.buffer
      boardsProc.buffer = ""
      if (code !== 0 || raw.length === 0 || raw.length > 262144) {
        root.loadError = "could not read pads.json"
        return
      }
      var doc
      try { doc = JSON.parse(raw) } catch (e) {
        root.loadError = "pads.json is not valid JSON"
        return
      }
      if (!doc || doc.ok !== true || !Array.isArray(doc.boards)) {
        root.loadError = "pads.json has no boards"
        return
      }

      // The renderer already caps all of this. Doing it again here costs four
      // lines and means the model this panel installs is bounded by this file
      // as well, rather than by a promise made in another one.
      var cleaned = []
      for (var i = 0; i < doc.boards.length && cleaned.length < 12; i++) {
        var entry = doc.boards[i]
        if (!entry || typeof entry.id !== "string" || !Array.isArray(entry.pads)) continue
        var pads = []
        for (var j = 0; j < entry.pads.length && pads.length < 16; j++) {
          var pad = entry.pads[j]
          if (!pad) continue
          pads.push({ label: root.plain(pad.label) })
        }
        if (pads.length === 0) continue
        cleaned.push({
          id: entry.id,
          label: root.plain(entry.label) || entry.id,
          pads: pads
        })
      }
      if (cleaned.length === 0) {
        root.loadError = "pads.json has no usable boards"
        return
      }
      root.loadError = ""
      root.boards = cleaned
      root.boardIndex = 0
      root.cursor = 0
      // The starting volume comes from pads.json, because the panel has nowhere
      // to remember it: this plugin writes nothing, so the file is the setting.
      if (typeof doc.gain === "number" && isFinite(doc.gain)) root.setGain(doc.gain)
    }
  }

  // ------------------------------------------------------------------ the bar

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: root.barSlot
    tooltipText: root.board
      ? "Omableep · " + root.plain(root.board.label)
      : "Omableep"
    onPressed: function(b) { root.toggle() }

    // Four pads with one lit. A speaker glyph would say "audio", which is not
    // the same claim, and at sixteen pixels four squares survive where a horn
    // with a swirl on it does not.
    iconComponent: Component {
      Item {
        readonly property int cell: Math.round(Style.bar.iconFont * 0.38)
        readonly property int gap: Math.max(1, Math.round(Style.bar.iconFont * 0.12))
        readonly property color tint: root.flashing || root.opened
          ? root.accent : root.foreground

        Grid {
          anchors.centerIn: parent
          columns: 2
          spacing: parent.gap

          Repeater {
            model: 4
            delegate: Rectangle {
              required property int index
              width: parent.parent.cell
              height: parent.parent.cell
              radius: Math.max(1, Math.round(width * 0.22))
              color: index === 0 ? parent.parent.tint : "transparent"
              border.width: index === 0 ? 0 : 1
              border.color: parent.parent.tint
              opacity: index === 0 ? 1.0 : 0.65
            }
          }
        }
      }
    }
  }

  // ---------------------------------------------------------------- the card

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher

    readonly property int desiredWidth: Style.space(300)
    contentWidth: Math.min(desiredWidth,
                           panel.availableCardWidth > 0 ? panel.availableCardWidth : desiredWidth)
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(620))

    // A plain Item rather than PanelKeyCatcher. That component reads keys
    // before its descendants and turns Tab, Enter and Space into signals of
    // its own, and it has no opinion about the number row, which is the whole
    // interface here. Owning Keys.onPressed outright is the only way to get
    // digits, and there is no focus ring to break because the pads are driven
    // by a cursor rather than by Tab.
    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.close()
          event.accepted = true
        } else if (event.key === Qt.Key_Tab) {
          root.selectBoard(root.boardIndex + 1)
          event.accepted = true
        } else if (event.key === Qt.Key_Backtab) {
          root.selectBoard(root.boardIndex - 1)
          event.accepted = true
        } else if (event.key === Qt.Key_Left) {
          root.moveCursor(-1); event.accepted = true
        } else if (event.key === Qt.Key_Right) {
          root.moveCursor(1); event.accepted = true
        } else if (event.key === Qt.Key_Up) {
          root.moveCursor(-root.columns); event.accepted = true
        } else if (event.key === Qt.Key_Down) {
          root.moveCursor(root.columns); event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                   || event.key === Qt.Key_Space) {
          root.fire(root.cursor); event.accepted = true
        } else if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Period) {
          root.panic(); event.accepted = true
        } else if (event.key === Qt.Key_Minus) {
          root.setGain(root.gain - 0.05); event.accepted = true
        } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
          root.setGain(root.gain + 0.05); event.accepted = true
        } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
          root.cursor = event.key - Qt.Key_1
          root.fire(event.key - Qt.Key_1)
          event.accepted = true
        } else if (event.key >= Qt.Key_A && event.key <= Qt.Key_L) {
          // Letters pick a board outright. Tab still walks them, but walking is
          // no good once there are five: you should be able to say which one.
          var wanted = event.key - Qt.Key_A
          if (wanted < root.boards.length) {
            root.selectBoard(wanted)
            event.accepted = true
          }
        }
      }

      ColumnLayout {
        id: content
        width: parent.width
        spacing: Style.space(10)

        // Boards, in the same two columns as the pads below them, each carrying
        // the letter that selects it. The letter is on the tab rather than in
        // the caption line, because a key you have to read a legend for is a
        // key you will not use.
        Grid {
          Layout.fillWidth: true
          columns: root.columns
          spacing: Style.space(6)
          visible: root.boards.length > 1

          Repeater {
            model: root.boards

            delegate: Rectangle {
              required property int index
              required property var modelData
              readonly property bool current: index === root.boardIndex

              width: (content.width - Style.space(6) * (root.columns - 1)) / root.columns
              height: Style.space(26)
              radius: Style.space(4)
              color: current ? Qt.alpha(root.accent, 0.16) : "transparent"
              border.width: 1
              border.color: current ? root.accent : Qt.alpha(root.foreground, 0.22)

              Row {
                anchors.centerIn: parent
                spacing: Style.space(7)

                Text {
                  textFormat: Text.PlainText
                  text: root.boardKey(index)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  color: current ? root.accent : Qt.alpha(root.foreground, 0.45)
                }

                Text {
                  textFormat: Text.PlainText
                  text: root.plain(modelData.label)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.letterSpacing: 1
                  color: current ? root.accent : Qt.alpha(root.foreground, 0.7)
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selectBoard(index)
              }
            }
          }
        }

        // The pads. A plain Item as the cell with the content centred inside
        // it, because a nested layout with fillWidth settles at its own
        // implicit width and packs the row against the left.
        Grid {
          Layout.fillWidth: true
          columns: root.columns
          spacing: Style.space(6)
          visible: root.pads.length > 0

          Repeater {
            model: root.pads

            delegate: Rectangle {
              required property int index
              required property var modelData
              readonly property bool hasCursor: index === root.cursor

              width: (content.width - Style.space(6) * (root.columns - 1)) / root.columns
              height: Style.space(46)
              radius: Style.space(5)
              color: pressArea.pressed
                ? Qt.alpha(root.accent, 0.3)
                : (hasCursor ? Qt.alpha(root.accent, 0.12) : Qt.alpha(root.foreground, 0.05))
              border.width: 1
              border.color: hasCursor ? root.accent : Qt.alpha(root.foreground, 0.16)

              Behavior on color { ColorAnimation { duration: 90 } }

              Text {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: Style.space(6)
                textFormat: Text.PlainText
                text: index < 9 ? String(index + 1) : "·"
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                color: hasCursor ? root.accent : Qt.alpha(root.foreground, 0.45)
              }

              Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Style.space(4)
                width: parent.width - Style.space(10)
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.PlainText
                text: root.plain(modelData.label)
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.letterSpacing: 0.5
                color: hasCursor ? root.accent : root.foreground
              }

              MouseArea {
                id: pressArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.cursor = index; root.fire(index) }
              }
            }
          }
        }

        // Nothing to show, because the renderer could not make sense of the file.
        Text {
          Layout.fillWidth: true
          visible: root.loadError !== "" || root.playError !== ""
          textFormat: Text.PlainText
          text: root.plain(root.loadError !== "" ? root.loadError : root.playError)
          wrapMode: Text.WordWrap
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          color: root.foreground
        }

        // Volume, as a bar rather than a slider: it has five steps that matter
        // and a handle would invite dragging for precision that is not there.
        RowLayout {
          Layout.fillWidth: true
          Layout.topMargin: Style.space(2)
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            text: "VOL"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.letterSpacing: 1
            color: Qt.alpha(root.foreground, 0.5)
          }

          Row {
            Layout.fillWidth: true
            spacing: Style.space(3)

            Repeater {
              model: 20

              delegate: Rectangle {
                required property int index
                readonly property bool lit: index < Math.round(root.gain * 20)

                width: (parent.width - Style.space(3) * 19) / 20
                height: Style.space(10)
                radius: 1
                color: lit ? root.accent : Qt.alpha(root.foreground, 0.14)

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.setGain((index + 1) / 20)
                }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            text: String(Math.round(root.gain * 100))
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: Qt.alpha(root.foreground, 0.5)
          }
        }

        // An icon button gives up its tooltip only to a mouse, so a keyboard
        // has nothing to read. Two dim lines cover the whole interface, split
        // where the meaning splits rather than wherever the words run out.
        Column {
          Layout.fillWidth: true
          Layout.topMargin: Style.space(2)
          spacing: Style.space(2)

          Repeater {
            model: [
              "A-" + root.boardKey(Math.max(0, root.boards.length - 1)) + " board  ·  1-8 fire",
              "arrows move  ·  enter plays",
              "+ - volume  ·  backspace stops  ·  esc"
            ]

            delegate: Text {
              required property string modelData
              width: content.width
              textFormat: Text.PlainText
              text: modelData
              // The card is narrow on purpose, so the legend has to fit inside
              // it rather than run off the edge. Elide is the backstop for a
              // theme whose caption font is wider than the one measured here.
              elide: Text.ElideRight
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: Qt.alpha(root.foreground, 0.45)
            }
          }
        }
      }
    }
  }
}
