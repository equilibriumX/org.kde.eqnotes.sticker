import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    Controls.Label {
        text: "This desktop sticker is linked to its EQ-Notes entry."
        wrapMode: Text.WordWrap
        Kirigami.FormData.isSection: true
    }
    Controls.Label {
        text: "Use the Pin/Unpin control in EQ-Notes to manage this sticker."
        wrapMode: Text.WordWrap
    }
}
