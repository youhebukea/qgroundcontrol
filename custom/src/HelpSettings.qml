import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

// Override of QGroundControl/AppSettings/HelpSettings.qml — replaces the
// stock QGC help links with this product's own support channels. The alias
// mapping is declared in custom/CMakeLists.txt.
Rectangle {
    objectName: "settingsPage_Help"
    color:          qgcPal.window
    anchors.fill:   parent

    readonly property real _margins: ScreenTools.defaultFontPixelHeight

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    QGCFlickable {
        anchors.margins:    _margins
        anchors.fill:       parent
        contentWidth:       grid.width
        contentHeight:      grid.height
        clip:               true

        GridLayout {
            id:         grid
            columns:    2

            QGCLabel { text: qsTr("联涛智控 产品主页") }
            QGCLabel {
                linkColor:          qgcPal.text
                text:               "<a href=\"https://www.lintor.cn\">www.lintor.cn</a>"
                onLinkActivated:    (link) => Qt.openUrlExternally(link)
            }

            QGCLabel { text: qsTr("联涛智控地面站 用户手册") }
            QGCLabel {
                linkColor:          qgcPal.text
                text:               "<a href=\"https://docs.lintor.cn/gcs\">docs.lintor.cn/gcs</a>"
                onLinkActivated:    (link) => Qt.openUrlExternally(link)
            }

            QGCLabel { text: qsTr("技术支持") }
            QGCLabel {
                linkColor:          qgcPal.text
                text:               "<a href=\"mailto:support@lintor.cn\">support@lintor.cn</a>"
                onLinkActivated:    (link) => Qt.openUrlExternally(link)
            }

            QGCLabel { text: qsTr("基于开源 QGroundControl") }
            QGCLabel {
                linkColor:          qgcPal.text
                text:               "<a href=\"https://qgroundcontrol.com\">https://qgroundcontrol.com</a>"
                onLinkActivated:    (link) => Qt.openUrlExternally(link)
            }
        }
    }
}
