/***************************************************************************
 * EQ-Notes Desktop Sticker - KDE Plasma 6
 * Copyright 2026 by Barnak Zlatko <saradnja.barnak@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 ***************************************************************************/

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import QtQuick.LocalStorage as LocalStorage

PlasmoidItem {
    id: root

    property bool coreAvailable: false
    property string eqNotesStoreUrl: "https://store.kde.org/p/2381917"

    Plasma5Support.DataSource {
        id: dependencyCommand
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
            root.coreAvailable = String(data.stdout || "").indexOf("EQNOTES_INSTALLED") !== -1
            if (root.coreAvailable) dependencyDialog.visible = false
            else dependencyDialog.visible = true
        }
    }

    function checkCoreDependency() {
        dependencyCommand.connectSource("kpackagetool6 --type Plasma/Applet --show org.kde.eqnotes >/dev/null 2>&1 && echo EQNOTES_INSTALLED || echo EQNOTES_MISSING")
    }

    Component.onCompleted: checkCoreDependency()

    PlasmaCore.Dialog {
        id: dependencyDialog
        visible: false
        flags: Qt.Window
        location: PlasmaCore.Types.Floating
        type: PlasmaCore.Dialog.Dialog

        mainItem: Rectangle {
            implicitWidth: 390
            implicitHeight: 190
            color: Kirigami.Theme.backgroundColor
            radius: 12
            border.width: 1
            border.color: Kirigami.Theme.disabledTextColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Controls.Label {
                    text: "EQ-Notes Required"
                    font.bold: true
                    font.pixelSize: 18
                    color: Kirigami.Theme.textColor
                    Layout.fillWidth: true
                }

                Controls.Label {
                    text: "EQ-Notes Desktop Sticker requires EQ-Notes to be installed."
                    wrapMode: Text.WordWrap
                    color: Kirigami.Theme.textColor
                    Layout.fillWidth: true
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Controls.Button {
                        text: "Cancel"
                        onClicked: dependencyDialog.visible = false
                    }
                    Controls.Button {
                        text: "Check again"
                        onClicked: root.checkCoreDependency()
                    }
                    Controls.Button {
                        text: "Download EQ-Notes"
                        highlighted: true
                        onClicked: Qt.openUrlExternally(root.eqNotesStoreUrl)
                    }
                }
            }
        }
    }

    implicitWidth: 230
    implicitHeight: 150
    preferredRepresentation: PlasmoidItem.FullRepresentation
    Plasmoid.title: "EQ-Notes: " + (Plasmoid.configuration.title || "Sticker")
    Plasmoid.icon: "view-pim-notes"
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property int importance: Number(Plasmoid.configuration.importance)
    readonly property string paletteName: Plasmoid.configuration.palette || "pastel"
    readonly property int cardRadius: Number(Plasmoid.configuration.radius || 8)

    // --- Svojstva i funkcije za EditNoteDialog ---
    property bool noteWindowOpen: false
    property var activeNote: null
    property bool editMode: false

    // Globalna pozicija i dimenzije stikera za pozicioniranje EditNoteDialog prozora.
    property real dialogAnchorX: 0
    property real dialogAnchorY: 0
    property real dialogAnchorWidth: 230
    property real dialogAnchorHeight: 150

    property var daysModel: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"]
    property var monthsModel: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    property var yearsModel: ["2026", "2027", "2028", "2029", "2030"]
    property var hoursModel: ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23"]
    property var minutesModel: ["00", "05", "10", "15", "20", "25", "30", "35", "40", "45", "50", "55"]

    readonly property color surfaceColor: Kirigami.Theme.backgroundColor
    readonly property color accentColor: Kirigami.Theme.highlightColor
    readonly property color subtleBorder: Qt.rgba(0,0,0,0.15)
    readonly property real stickerRadius: cardRadius

    function stickerColor(imp, noteId) {
        return cardColor()
    }

    function stickerForegroundColor(imp) {
        return foreground()
    }

    function stickerSecondaryTextColor(imp) {
        return secondaryForeground()
    }

    function importanceName(imp) {
        if (imp === 2) return "HIGH"
        if (imp === 0) return "LOW"
        return "NORMAL"
    }

    function dateTimeText(ms) {
        if (!ms || ms <= 0) return ""
        return Qt.formatDateTime(new Date(ms), "dd.MM.yyyy. hh:mm")
    }

    function closeFloatingNote() {
        noteWindowOpen = false
        activeNote = null
        editMode = false
    }
    function unpinSticker() {
    var noteId = Number(Plasmoid.configuration.noteId)

    if (!noteId || isNaN(noteId))
        return

    try {
        var db = LocalStorage.LocalStorage.openDatabaseSync(
            "EQNotesProfil",
            "1.0",
            "EQ-Notes local notes",
            2 * 1024 * 1024
        )

        db.transaction(function(tx) {
            tx.executeSql(
                "CREATE TABLE IF NOT EXISTS sticker_unpin_requests (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "note_id INTEGER NOT NULL, " +
                "requested_at INTEGER NOT NULL)"
            )

            tx.executeSql(
                "INSERT INTO sticker_unpin_requests " +
                "(note_id, requested_at) VALUES (?, ?)",
                [noteId, Date.now()]
            )
        })

    } catch (e) {
        console.log("EQ-Notes: unpin error: " + e)
    }
}

function openFloatingEdit() {
        var noteId = Number(Plasmoid.configuration.noteId)
        var fallbackText = Plasmoid.configuration.text || Plasmoid.configuration.title || ""
        var fallbackImp = Number(Plasmoid.configuration.importance || 1)
        var fallbackDone = Plasmoid.configuration.done === "true" || Plasmoid.configuration.done === true

        // Privremeno inicijalizujemo sa onim što imamo, dok ne pročitamo bazu
        activeNote = {
            id: noteId,
            body: fallbackText,
            importance: fallbackImp,
            done: fallbackDone,
            reminderEnabled: false,
            reminderAt: 0,
            dueAt: 0
        }
        editMode = false
        noteWindowOpen = true

        // Pokušavamo da izvučemo tačan sadržaj i sve parametre direktno iz baze podataka
        try {
            var db = LocalStorage.LocalStorage.openDatabaseSync(
                        "EQNotesProfil", "1.0", "EQ-Notes local notes", 2 * 1024 * 1024)
            db.readTransaction(function(tx) {
                var rs = tx.executeSql("SELECT body, importance, done, reminder_enabled, reminder_at, due_at FROM notes WHERE id = ?", [noteId])
                if (rs.rows.length > 0) {
                    var row = rs.rows.item(0)
                    activeNote = {
                        id: noteId,
                        body: row.body !== undefined ? row.body : fallbackText,
                        importance: row.importance !== undefined ? Number(row.importance) : fallbackImp,
                        done: row.done === 1 || row.done === true,
                        reminderEnabled: row.reminder_enabled === 1 || row.reminder_enabled === true,
                        reminderAt: Number(row.reminder_at || 0),
                        dueAt: Number(row.due_at || 0)
                    }
                }
            })
        } catch (e) {
            console.log("EQ-Notes greška pri čitanju beleške iz baze: " + e)
        }
    }

    function markDone(id) {
        if (!id || isNaN(Number(id)))
            return false

        try {
            var db = LocalStorage.LocalStorage.openDatabaseSync(
                        "EQNotesProfil",
                        "1.0",
                        "EQ-Notes local notes",
                        2 * 1024 * 1024
                    )

            db.transaction(function(tx) {
                tx.executeSql(
                    "UPDATE notes SET done = ?, completed_at = ?, reminder_enabled = ? WHERE id = ?",
                    [1, Date.now(), 0, Number(id)]
                )
            })

            Plasmoid.configuration.done = true
            if (activeNote && Number(activeNote.id) === Number(id)) {
                var updatedNote = Object.assign({}, activeNote)
                updatedNote.done = true
                updatedNote.reminderEnabled = false
                activeNote = updatedNote
            }
            return true
        } catch (e) {
            console.log("EQ-Notes: Mark completed error: " + e)
            return false
        }
    }

    function deleteNote(id) {
        if (!id || isNaN(Number(id)))
            return false

        try {
            var db = LocalStorage.LocalStorage.openDatabaseSync(
                        "EQNotesProfil",
                        "1.0",
                        "EQ-Notes local notes",
                        2 * 1024 * 1024
                    )

            db.transaction(function(tx) {
                tx.executeSql("DELETE FROM notes WHERE id = ?", [Number(id)])
            })

            root.closeFloatingNote()
            return true
        } catch (e) {
            console.log("EQ-Notes: Delete note error: " + e)
            return false
        }
    }

    function makeTimestamp(d, m, y, h, min) {
        return new Date(y, m - 1, d, h, min).getTime()
    }

    function updateNoteDetails(id, body, remEnabled, remAt, dueAt, imp) {

    try {
        var db = LocalStorage.LocalStorage.openDatabaseSync(
                    "EQNotesProfil",
                    "1.0",
                    "EQ-Notes local notes",
                    2 * 1024 * 1024
                )

        db.transaction(function(tx) {

            tx.executeSql(
                "UPDATE notes SET " +
                "body = ?, " +
                "importance = ?, " +
                "reminder_enabled = ?, " +
                "reminder_at = ?, " +
                "due_at = ? " +
                "WHERE id = ?",
                [
                    body,
                    imp,
                    remEnabled ? 1 : 0,
                    remAt,
                    dueAt,
                    id
                ]
            )
        })

        // Ažuriranje podataka samog stikera
        Plasmoid.configuration.text = body
        Plasmoid.configuration.importance = imp

        return true

    } catch (e) {
        console.log("EQ-Notes: Greška pri čuvanju izmene: " + e)
        return false
    }
}
    // ----------------------------------------------

    function openOriginalNote() {
        var noteId = Number(Plasmoid.configuration.noteId)
        if (!noteId || isNaN(noteId)) return

        try {
            var db = LocalStorage.LocalStorage.openDatabaseSync(
                        "EQNotesProfil", "1.0", "EQ-Notes local notes", 2 * 1024 * 1024)

            db.transaction(function(tx) {
                tx.executeSql(
                    "CREATE TABLE IF NOT EXISTS sticker_open_requests (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "note_id INTEGER NOT NULL, " +
                    "requested_at INTEGER NOT NULL)"
                )
                tx.executeSql(
                    "INSERT INTO sticker_open_requests (note_id, requested_at) VALUES (?, ?)",
                    [noteId, Date.now()]
                )
            })
        } catch (e) {
            console.log("EQ-Notes: cannot open original note: " + e)
        }
    }

    function foreground() {
        var mode = Plasmoid.configuration.textColor || "default"
        if (mode === "dark") return "#202124"
        if (mode === "light") return "#ffffff"
        if (importance === 2) return "#ffffff"
        if (paletteName === "plasma") {
            var c = Kirigami.Theme.backgroundColor
            var lum = 0.2126*c.r + 0.7152*c.g + 0.0722*c.b
            return lum < 0.50 ? "#ffffff" : "#202124"
        }
        return importance === 0 ? "#333333" : "#1e1e1e"
    }

    function secondaryForeground() {
        var c = foreground()
        if ((Plasmoid.configuration.textColor || "default") === "default" && importance === 2)
            return Qt.rgba(1, 1, 1, 0.82)
        return Qt.rgba(c.r, c.g, c.b, 0.72)
    }

    function cardColor() {
        if (importance === 2) return "#e53935"
        if (importance === 0) return Kirigami.Theme.alternateBackgroundColor
        var pastel = ["#fff9c4", "#b3e5fc", "#c8e6c9", "#f8bbd0", "#e1bee7", "#ffe0b2"]
        var classic = ["#FFC107", "#03A9F4", "#4CAF50", "#E91E63", "#9C27B0", "#FF5722"]
        var gray = ["#eeeeee", "#d6d6d6", "#c2c2c2", "#aaaaaa", "#969696", "#e2e2e2"]
        var colors = pastel
        if (paletteName === "classic") colors = classic
        else if (paletteName === "gray") colors = gray
        else if (paletteName === "plasma") {
            var plasma = [Kirigami.Theme.highlightColor, Kirigami.Theme.linkColor,
                          Kirigami.Theme.positiveTextColor, Kirigami.Theme.neutralTextColor,
                          Kirigami.Theme.visitedLinkColor, Kirigami.Theme.alternateBackgroundColor]
            var pc = plasma[Math.abs(Number(Plasmoid.configuration.noteId)) % plasma.length]
            return Qt.tint(Kirigami.Theme.alternateBackgroundColor, Qt.rgba(pc.r,pc.g,pc.b,0.24))
        } else if (paletteName === "transparent") {
            var trans = [Qt.rgba(0.98,0.78,0.30,0.34), Qt.rgba(0.28,0.68,0.92,0.32),
                         Qt.rgba(0.34,0.72,0.48,0.32), Qt.rgba(0.91,0.43,0.63,0.30),
                         Qt.rgba(0.62,0.48,0.86,0.32), Qt.rgba(0.94,0.61,0.34,0.32)]
            return trans[Math.abs(Number(Plasmoid.configuration.noteId)) % trans.length]
        }
        return colors[Math.abs(Number(Plasmoid.configuration.noteId)) % colors.length]
    }

    function shortDate() {
        var ms = Number(Plasmoid.configuration.created)
        return ms > 0 ? Qt.formatDate(new Date(ms), "dd.MM.yyyy.") : ""
    }

        fullRepresentation: Item {
        id: stickerRoot
        visible: root.coreAvailable

        implicitWidth: 230
        implicitHeight: Math.max(118, stickerColumn.implicitHeight + 22)

        readonly property real stickerOffsetX:
            Plasmoid.configuration.randomOffset
            ? [-3, 4, -2, 5, 1, -4][Math.abs(Number(Plasmoid.configuration.noteId)) % 6] : 0

        readonly property real stickerOffsetY:
            Plasmoid.configuration.randomOffset
            ? [3, -4, 5, -2, 4, -3][Math.abs(Number(Plasmoid.configuration.noteId)) % 6] : 0

        // SENKA
        Rectangle {
            visible: Boolean(Plasmoid.configuration.shadow)

            anchors.fill: card

            x: card.x + 2
            y: card.y + 5

            radius: card.radius
            color: "#22000000"

            rotation: card.rotation
        }

        // POZADINA STIKERA - ROTIRA SE
        Rectangle {
            id: card

            anchors.fill: parent
            anchors.leftMargin: stickerRoot.stickerOffsetX
            anchors.topMargin: stickerRoot.stickerOffsetY

            radius: root.cardRadius
            antialiasing: true

            rotation: Plasmoid.configuration.rotation
                     ? [-2.0, 1.6, -1.1, 2.2, -1.5, 1.3][Math.abs(Number(Plasmoid.configuration.noteId)) % 6]
                     : 0

            transformOrigin: Item.Center

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.lighter(root.cardColor(), 1.08)
                }

                GradientStop {
                    position: 1.0
                    color: Qt.darker(root.cardColor(), 1.12)
                }
            }

            border.width: 1
            border.color: Qt.rgba(0,0,0,0.16)
        }
        // DUGME ZA ODPINOVANJE
Rectangle {
    id: unpinButton

    width: 26
    height: 26

    radius: 8

    anchors.top: parent.top
    anchors.right: parent.right

    anchors.topMargin: 5
    anchors.rightMargin: 32

    z: 100

    color: unpinMouse.containsMouse
           ? "#55ffffff"
           : "#22ffffff"

    border.width: 1
    border.color: "#55000000"

    Text {
        anchors.centerIn: parent

        text: "📌"

        font.pixelSize: 15
    }

    MouseArea {
        id: unpinMouse

        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.unpinSticker()
        }
    }

    Controls.ToolTip.visible: unpinMouse.containsMouse
    Controls.ToolTip.text: "Unpin sticker"
}

        // SADRŽAJ STIKERA - UVEK RAVAN
        ColumnLayout {
            id: stickerColumn

            anchors.fill: parent

            anchors.leftMargin: 10 + stickerRoot.stickerOffsetX
            anchors.topMargin: 10 + stickerRoot.stickerOffsetY
            anchors.rightMargin: 10
            anchors.bottomMargin: 10

            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3

                    color: root.importance === 2 ? "#ffffff"
                          : root.importance === 0 ? "#69b9a0" : "#444444"
                }

                Controls.Label {
                    text: root.importanceName(root.importance)

                    color: root.foreground()

                    font.family: "Sans Serif"
                    font.pixelSize: 8
                    font.bold: true

                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Rectangle {
    id: doneButton

    width: 20
    height: 20
    radius: 10

    color: Plasmoid.configuration.done
           ? "#2e7d32" : Qt.rgba(0,0,0,0.12)

    border.width: 1
    border.color: Plasmoid.configuration.done
                  ? "#1b5e20" : Qt.rgba(0,0,0,0.25)

    Text {
        anchors.centerIn: parent

        text: "✓"
        font.pixelSize: 11
        font.bold: true

        color: Plasmoid.configuration.done
               ? "#ffffff" : "#444444"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            var noteId = Number(Plasmoid.configuration.noteId)
            var newState = !Plasmoid.configuration.done

            try {
                var db = LocalStorage.LocalStorage.openDatabaseSync(
                    "EQNotesProfil",
                    "1.0",
                    "EQ-Notes local notes",
                    2 * 1024 * 1024
                )

                db.transaction(function(tx) {
                    tx.executeSql(
                        "UPDATE notes SET done = ?, " +
                        "completed_at = ?, " +
                        "reminder_enabled = ? WHERE id = ?",
                        [
                            newState ? 1 : 0,
                            newState ? Date.now() : 0,
                            newState ? 0 : 1,
                            noteId
                        ]
                    )
                })

                Plasmoid.configuration.done = newState

            } catch (e) {
                console.log("EQ-Notes: Done update error: " + e)
            }
        }
    }
}
            }

            Controls.Label {
                text: Plasmoid.configuration.title || "EQ-Notes"

                Layout.fillWidth: true

                font.bold: true
                font.family: "Sans Serif"
                font.pixelSize: 16

                color: root.foreground()

                wrapMode: Text.Wrap

                font.strikeout: Plasmoid.configuration.done
            }

            Controls.Label {
                text: root.shortDate()

                Layout.fillWidth: true

                font.family: "Sans Serif"
                font.pixelSize: 8

                color: root.secondaryForeground()
            }
        }

        // KLIK NA STIKER
        TapHandler {
            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.DragThreshold

            onTapped: {
                // Čuvamo globalnu poziciju baš ovog stikera pre otvaranja dijaloga.
                var stickerPos = card.mapToGlobal(Qt.point(0, 0))
                root.dialogAnchorX = stickerPos.x
                root.dialogAnchorY = stickerPos.y
                root.dialogAnchorWidth = card.width
                root.dialogAnchorHeight = card.height
                root.openFloatingEdit()
            }
        }
    }

    EditNoteDialog {
        id: editNoteDialog
    }
}
