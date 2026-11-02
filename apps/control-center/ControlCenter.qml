import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: appWindow
    width: 780
    height: 520
    minimumWidth: 680
    minimumHeight: 460
    visible: true
    title: "Control Center"
    color: "#0b0d12"

    Row {
        anchors.fill: parent

        Rectangle {
            width: 172
            height: parent.height
            color: "#080a0e"
            border.color: "#161b26"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 3

                Row {
                    spacing: 8
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    height: 36

                    Image {
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        source: "file:///usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png"
                        sourceSize.width: 40
                        sourceSize.height: 40
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Raytolfas OS"
                        color: "#f1f5f9"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "Noto Sans"
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#161b26"
                }

                Item { width: 1; height: 4 }

                NavButton { text: "About"; active: stackLayout.currentIndex === 0; onClicked: stackLayout.currentIndex = 0 }
                NavButton {
                    text: "Updates"
                    active: stackLayout.currentIndex === 1
                    onClicked: {
                        stackLayout.currentIndex = 1
                        backend.check_for_updates()
                    }
                }
                NavButton {
                    text: "Patches"
                    active: stackLayout.currentIndex === 2
                    onClicked: {
                        stackLayout.currentIndex = 2
                        backend.check_for_patches()
                    }
                }
                NavButton { text: "Subsystems"; active: stackLayout.currentIndex === 3; onClicked: stackLayout.currentIndex = 3 }
                NavButton { text: "Development"; active: stackLayout.currentIndex === 4; onClicked: stackLayout.currentIndex = 4 }
                NavButton {
                    text: "Snapshots"
                    active: stackLayout.currentIndex === 5
                    onClicked: {
                        stackLayout.currentIndex = 5
                        backend.refresh_snapshots()
                    }
                }
                NavButton { text: "Performance"; active: stackLayout.currentIndex === 6; onClicked: stackLayout.currentIndex = 6 }
                NavButton { text: "Appearance"; active: stackLayout.currentIndex === 7; onClicked: stackLayout.currentIndex = 7 }
            }
        }

        StackLayout {
            id: stackLayout
            width: parent.width - 172
            height: parent.height
            currentIndex: 0

            Item {
                Column {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 14

                    SectionHeader { title: "About System" }

                    Rectangle {
                        width: parent.width
                        height: infoCol.implicitHeight + 28
                        color: "#11151d"
                        radius: 8
                        border.color: "#1c2331"

                        Column {
                            id: infoCol
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            InfoRow { label: "System"; value: backend.os_version }
                            InfoRow { label: "Desktop"; value: backend.plasma_version }
                            InfoRow { label: "Kernel"; value: backend.kernel_version }
                            InfoRow { label: "Processor"; value: backend.cpu_info }
                            InfoRow { label: "Memory"; value: backend.ram_info }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 40
                        color: "#11151d"
                        radius: 8
                        border.color: "#1c2331"

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            spacing: 10
                            Text { text: "Website"; color: "#94a3b8"; font.pixelSize: 12; width: 120 }
                            Text {
                                text: "os.raytolfas.com"
                                color: backend.accent_color
                                font.pixelSize: 12
                                font.bold: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally("https://os.raytolfas.com")
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Column {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 14

                    SectionHeader { title: "System Updates" }

                    Rectangle {
                        width: parent.width
                        height: updateCol.implicitHeight + 28
                        color: "#11151d"
                        radius: 8
                        border.color: "#1c2331"

                        Column {
                            id: updateCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 14
                            spacing: 10

                            InfoRow { label: "Current"; value: backend.os_version }
                            InfoRow { label: "Channel"; value: "os.raytolfas.cc/update" }

                            Rectangle { width: parent.width; height: 1; color: "#1c2331" }

                            Row {
                                spacing: 8
                                Rectangle {
                                    width: 7; height: 7; radius: 4
                                    color: backend.update_available ? "#eab308" : (backend.update_checking ? backend.accent_color : "#10b981")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: backend.update_status
                                    color: "#f1f5f9"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: backend.update_changelog
                                color: "#94a3b8"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                width: parent.width
                                visible: backend.update_changelog !== ""
                            }
                        }
                    }

                    Row {
                        spacing: 8

                        ActionButton {
                            text: "Check"
                            btnWidth: 84
                            enabled: !backend.update_checking
                            onClicked: backend.check_for_updates()
                        }

                        ActionButton {
                            text: "Download ISO"
                            btnWidth: 110
                            primary: true
                            visible: backend.update_available
                            enabled: !backend.update_checking
                            onClicked: backend.download_update()
                        }

                        ActionButton {
                            text: "Upgrade from ISO"
                            btnWidth: 128
                            enabled: !backend.update_checking
                            onClicked: backend.choose_and_apply_iso()
                        }
                    }
                }
            }

            Item {
                Column {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 14

                    SectionHeader { title: "Hotfix Patches" }

                    Rectangle {
                        width: parent.width
                        height: patchCol.implicitHeight + 28
                        color: "#11151d"
                        radius: 8
                        border.color: "#1c2331"

                        Column {
                            id: patchCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 14
                            spacing: 10

                            InfoRow { label: "Patch Level"; value: backend.patch_version }
                            InfoRow { label: "Status"; value: backend.patch_available ? "Hotfix available" : "Up to date" }

                            Rectangle { width: parent.width; height: 1; color: "#1c2331" }

                            Row {
                                spacing: 8
                                Rectangle {
                                    width: 7; height: 7; radius: 4
                                    color: backend.patch_available ? "#eab308" : (backend.patch_checking ? backend.accent_color : "#10b981")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: backend.patch_status
                                    color: "#f1f5f9"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: backend.patch_changelog
                                color: "#94a3b8"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                width: parent.width
                                visible: backend.patch_changelog !== ""
                            }
                        }
                    }

                    Row {
                        spacing: 8

                        ActionButton {
                            text: "Check"
                            btnWidth: 84
                            enabled: !backend.patch_checking
                            onClicked: backend.check_for_patches()
                        }

                        ActionButton {
                            text: backend.patch_checking ? "Installing..." : "Apply Patch"
                            btnWidth: 104
                            primary: true
                            visible: backend.patch_available
                            enabled: !backend.patch_checking
                            onClicked: backend.download_patch()
                        }
                    }
                }
            }

            Item {
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 24
                    contentWidth: width
                    contentHeight: subCol.implicitHeight + 24
                    clip: true

                    Column {
                        id: subCol
                        width: parent.width
                        spacing: 8

                        SectionHeader { title: "Subsystems & Modes" }

                        RowCard {
                            title: "Spotlight (Alt+Space)"
                            sub: "Minimal search, calculator, and command runner"
                            btnText: "Open"
                            primary: true
                            onTriggered: backend.launch_spotlight()
                        }

                        RowCard {
                            title: "Console Mode (Win+Shift+G)"
                            sub: "Fullscreen gamepad launcher"
                            btnText: "Launch"
                            onTriggered: backend.launch_console_mode()
                        }

                        RowCard {
                            title: "Desktop Mode"
                            sub: "External display convergence trackpad"
                            btnText: "Trackpad"
                            onTriggered: backend.open_desktop_touchpad()
                        }

                        RowCard {
                            title: "M1 Mobile Shell"
                            sub: "Minimalist mobile workspace preview"
                            btnText: "Open"
                            onTriggered: backend.launch_m1_shell()
                        }

                        RowCard {
                            title: "Waydroid (Android)"
                            sub: backend.waydroid_status
                            btnText: "Setup ARM"
                            onTriggered: backend.setup_android_libndk()
                        }

                        RowCard {
                            title: "Proton-GE (Windows)"
                            sub: backend.proton_version
                            btnText: backend.proton_updating ? "..." : "Update"
                            onTriggered: backend.update_proton_ge()
                        }
                    }
                }
            }

            Item {
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 24
                    contentWidth: width
                    contentHeight: devCol.implicitHeight + 24
                    clip: true

                    Column {
                        id: devCol
                        width: parent.width
                        spacing: 8

                        SectionHeader { title: "Development Tools" }

                        DevCard {
                            title: "Rust"
                            desc: "rustup, rustc, cargo"
                            status: backend.dev_rust_status
                            btnText: "Install"
                            onTriggered: backend.install_dev("rust")
                        }

                        DevCard {
                            title: "Python (uv)"
                            desc: "Fast Python package manager"
                            status: backend.dev_python_status
                            btnText: "Install"
                            onTriggered: backend.install_dev("python")
                        }

                        DevCard {
                            title: "Node.js (fnm)"
                            desc: "Fast Node Manager LTS"
                            status: backend.dev_node_status
                            btnText: "Install"
                            onTriggered: backend.install_dev("node")
                        }

                        DevCard {
                            title: "C / C++"
                            desc: "Clang, LLD, GCC, CMake, Ninja"
                            status: backend.dev_cpp_status
                            btnText: "Install"
                            onTriggered: backend.install_dev("cpp")
                        }

                        DevCard {
                            title: "Podman"
                            desc: "Rootless OCI container engine"
                            status: backend.dev_docker_status
                            btnText: "Install"
                            onTriggered: backend.install_dev("docker")
                        }
                    }
                }
            }

            Item {
                Column {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 12

                    SectionHeader { title: "Btrfs Snapshots" }

                    Rectangle {
                        width: parent.width
                        height: 52
                        color: "#11151d"
                        radius: 8
                        border.color: "#1c2331"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14

                            Column {
                                spacing: 2
                                Text { text: "System State"; color: "#f1f5f9"; font.pixelSize: 12; font.bold: true }
                                Text { text: backend.snapshot_status; color: "#94a3b8"; font.pixelSize: 11 }
                            }

                            Item { Layout.fillWidth: true }

                            ActionButton {
                                text: "Create"
                                btnWidth: 74
                                primary: true
                                enabled: !backend.snapshot_busy
                                onClicked: backend.create_snapshot()
                            }

                            ActionButton {
                                text: "Refresh"
                                btnWidth: 74
                                enabled: !backend.snapshot_busy
                                onClicked: backend.refresh_snapshots()
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: parent.height - 102
                        color: "#11151d"
                        radius: 8
                        border.color: "#1c2331"

                        ListView {
                            anchors.fill: parent
                            anchors.margins: 10
                            clip: true
                            spacing: 6
                            model: backend.snapshots_list

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 38
                                color: "#161b26"
                                radius: 6

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text { text: modelData.name; color: "#f1f5f9"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Text { text: modelData.date; color: "#64748b"; font.pixelSize: 11 }

                                    ActionButton {
                                        text: "Restore"
                                        btnWidth: 68
                                        onClicked: backend.rollback_snapshot_named(modelData.name)
                                    }

                                    ActionButton {
                                        text: "Delete"
                                        btnWidth: 62
                                        onClicked: backend.delete_snapshot_named(modelData.name)
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: backend.snapshots_list.length === 0
                                text: "No Btrfs snapshots yet"
                                color: "#64748b"
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }

            Item {
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 24
                    contentWidth: width
                    contentHeight: perfCol.implicitHeight + 24
                    clip: true

                    Column {
                        id: perfCol
                        width: parent.width
                        spacing: 8

                        SectionHeader { title: "Performance" }

                        RowCard {
                            title: "Turbo Mode (Win+F1)"
                            sub: backend.turbo_active ? "Performance governor active" : "Balanced governor"
                            btnText: backend.turbo_active ? "On" : "Off"
                            primary: backend.turbo_active
                            onTriggered: backend.toggle_turbo()
                        }

                        SettingBar {
                            label: "Gaming Telemetry"
                            Row {
                                spacing: 6
                                ActionButton {
                                    text: backend.gamemode_active ? "GameMode: On" : "GameMode: Off"
                                    btnWidth: 108
                                    primary: backend.gamemode_active
                                    onClicked: backend.toggle_gamemode()
                                }
                                ActionButton {
                                    text: backend.mangohud_active ? "MangoHUD: On" : "MangoHUD: Off"
                                    btnWidth: 108
                                    primary: backend.mangohud_active
                                    onClicked: backend.toggle_mangohud()
                                }
                            }
                        }

                        SettingBar {
                            label: "Power Profile"
                            Row {
                                spacing: 6
                                ActionButton {
                                    text: "Saver"
                                    btnWidth: 68
                                    primary: backend.current_power_profile === "power-saver"
                                    onClicked: backend.set_power_profile("power-saver")
                                }
                                ActionButton {
                                    text: "Balanced"
                                    btnWidth: 76
                                    primary: backend.current_power_profile === "balanced"
                                    onClicked: backend.set_power_profile("balanced")
                                }
                                ActionButton {
                                    text: "Performance"
                                    btnWidth: 92
                                    primary: backend.current_power_profile === "performance"
                                    onClicked: backend.set_power_profile("performance")
                                }
                            }
                        }

                        RowCard {
                            title: "System Cleaner & RAM"
                            sub: backend.clean_status
                            btnText: backend.clean_busy ? "..." : "Clean"
                            primary: true
                            onTriggered: backend.run_system_clean()
                        }

                        RowCard {
                            title: "System Benchmark"
                            sub: "CPU, memory, and NVMe I/O test"
                            btnText: "Run"
                            onTriggered: backend.run_benchmark()
                        }
                    }
                }
            }

            Item {
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 24
                    contentWidth: width
                    contentHeight: appearCol.implicitHeight + 24
                    clip: true

                    Column {
                        id: appearCol
                        width: parent.width
                        spacing: 8

                        SectionHeader { title: "Appearance" }

                        SettingBar {
                            label: "Theme"
                            Row {
                                spacing: 6
                                ActionButton { text: "Dark"; btnWidth: 68; primary: backend.current_theme === "dark"; onClicked: backend.apply_theme("dark") }
                                ActionButton { text: "Light"; btnWidth: 68; primary: backend.current_theme === "light"; onClicked: backend.apply_theme("light") }
                            }
                        }

                        SettingBar {
                            label: "Accent Color"
                            Row {
                                spacing: 8
                                Repeater {
                                    model: ["#0078D4", "#38bdf8", "#8b5cf6", "#ec4899", "#10b981", "#f59e0b", "#ef4444", "#6366f1"]
                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: modelData
                                        border.color: backend.accent_color === modelData ? "#ffffff" : "transparent"
                                        border.width: 2
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: backend.apply_accent_color(modelData)
                                        }
                                    }
                                }
                            }
                        }

                        SettingBar {
                            label: "Panel Layout"
                            Row {
                                spacing: 6
                                ActionButton { text: "Docked"; btnWidth: 70; primary: backend.panel_style === "docked"; onClicked: backend.set_panel_style("docked") }
                                ActionButton { text: "Floating"; btnWidth: 70; primary: backend.panel_style === "floating"; onClicked: backend.set_panel_style("floating") }
                                ActionButton { text: "Compact"; btnWidth: 72; primary: backend.panel_style === "compact"; onClicked: backend.set_panel_style("compact") }
                            }
                        }

                        SettingBar {
                            label: "Window Controls"
                            Row {
                                spacing: 6
                                ActionButton { text: "Right"; btnWidth: 64; primary: backend.window_buttons === "right"; onClicked: backend.set_window_buttons("right") }
                                ActionButton { text: "Left"; btnWidth: 64; primary: backend.window_buttons === "left"; onClicked: backend.set_window_buttons("left") }
                            }
                        }

                        SettingBar {
                            label: "Cursor"
                            Row {
                                spacing: 6
                                ActionButton { text: "Black"; btnWidth: 64; primary: backend.cursor_theme === "Bibata-Modern-Classic"; onClicked: backend.set_cursor_theme("Bibata-Modern-Classic") }
                                ActionButton { text: "Ice"; btnWidth: 58; primary: backend.cursor_theme === "Bibata-Modern-Ice"; onClicked: backend.set_cursor_theme("Bibata-Modern-Ice") }
                                ActionButton { text: "Amber"; btnWidth: 66; primary: backend.cursor_theme === "Bibata-Modern-Amber"; onClicked: backend.set_cursor_theme("Bibata-Modern-Amber") }
                            }
                        }

                        SettingBar {
                            label: "Glass Blur"
                            Row {
                                spacing: 6
                                ActionButton { text: "Subtle"; btnWidth: 62; primary: backend.blur_level === "subtle"; onClicked: backend.set_blur_level("subtle") }
                                ActionButton { text: "Balanced"; btnWidth: 72; primary: backend.blur_level === "balanced"; onClicked: backend.set_blur_level("balanced") }
                                ActionButton { text: "Deep"; btnWidth: 58; primary: backend.blur_level === "deep"; onClicked: backend.set_blur_level("deep") }
                                ActionButton { text: "Max"; btnWidth: 54; primary: backend.blur_level === "ultra"; onClicked: backend.set_blur_level("ultra") }
                            }
                        }

                        SettingBar {
                            label: "Minimize Effect"
                            Row {
                                spacing: 6
                                ActionButton { text: "Lamp"; btnWidth: 68; primary: backend.minimize_effect === "magiclamp"; onClicked: backend.set_minimize_effect("magiclamp") }
                                ActionButton { text: "Scale"; btnWidth: 68; primary: backend.minimize_effect === "scale"; onClicked: backend.set_minimize_effect("scale") }
                            }
                        }

                        SettingBar {
                            label: "Animation Speed"
                            Row {
                                spacing: 6
                                ActionButton { text: "Instant"; btnWidth: 62; primary: backend.anim_speed === "instant"; onClicked: backend.set_anim_speed("instant") }
                                ActionButton { text: "Fast"; btnWidth: 54; primary: backend.anim_speed === "fast"; onClicked: backend.set_anim_speed("fast") }
                                ActionButton { text: "Fluid"; btnWidth: 56; primary: backend.anim_speed === "fluid"; onClicked: backend.set_anim_speed("fluid") }
                                ActionButton { text: "Slow"; btnWidth: 56; primary: backend.anim_speed === "relaxed"; onClicked: backend.set_anim_speed("relaxed") }
                            }
                        }
                    }
                }
            }
        }
    }

    component SectionHeader: Text {
        property string title: ""
        text: title
        color: "#f1f5f9"
        font.pixelSize: 16
        font.bold: true
        bottomPadding: 4
        font.family: "Noto Sans"
    }

    component NavButton: Rectangle {
        property string text: ""
        property bool active: false
        signal clicked()

        width: parent.width
        height: 30
        radius: 6
        color: active ? backend.accent_color : (navMouse.containsMouse ? "#141923" : "transparent")

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            text: parent.text
            color: active ? "#ffffff" : "#94a3b8"
            font.pixelSize: 12
            font.bold: active
            font.family: "Noto Sans"
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component ActionButton: Rectangle {
        property string text: ""
        property int btnWidth: 88
        property bool primary: false
        signal clicked()

        width: btnWidth
        height: 26
        radius: 5
        color: primary ? backend.accent_color : (btnMouse.containsMouse ? "#222b3b" : "#181e2b")
        opacity: primary && btnMouse.containsMouse ? 0.88 : 1.0
        border.color: primary ? "transparent" : "#263042"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: parent.text
            color: primary ? "#ffffff" : "#cbd5e1"
            font.pixelSize: 11
            font.bold: primary
            font.family: "Noto Sans"
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component SettingBar: Rectangle {
        property string label: ""
        default property alias controlContent: rightContainer.data

        width: parent.width
        height: 44
        color: "#11151d"
        radius: 7
        border.color: "#1c2331"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12

            Text {
                text: label
                color: "#e2e8f0"
                font.pixelSize: 12
                font.family: "Noto Sans"
            }

            Item { Layout.fillWidth: true }

            Row {
                id: rightContainer
                spacing: 6
            }
        }
    }

    component RowCard: Rectangle {
        id: rowCardRoot
        property string title: ""
        property string sub: ""
        property string btnText: "Open"
        property bool primary: false
        signal triggered()

        width: parent.width
        height: 50
        color: "#11151d"
        radius: 7
        border.color: "#1c2331"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10

            Column {
                Layout.fillWidth: true
                spacing: 2
                Text { text: title; color: "#f1f5f9"; font.pixelSize: 12; font.bold: true; font.family: "Noto Sans" }
                Text { text: sub; color: "#94a3b8"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width; font.family: "Noto Sans" }
            }

            ActionButton {
                text: btnText
                btnWidth: 78
                primary: rowCardRoot.primary
                onClicked: triggered()
            }
        }
    }

    component DevCard: Rectangle {
        property string title: ""
        property string desc: ""
        property string status: ""
        property string btnText: "Install"
        signal triggered()

        width: parent.width
        height: 48
        color: "#11151d"
        radius: 7
        border.color: "#1c2331"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10

            Column {
                Layout.fillWidth: true
                spacing: 2
                Row {
                    spacing: 8
                    Text { text: title; color: "#f1f5f9"; font.pixelSize: 12; font.bold: true }
                    Text { text: status; color: status === "Not installed" ? "#64748b" : "#10b981"; font.pixelSize: 11 }
                }
                Text { text: desc; color: "#64748b"; font.pixelSize: 11 }
            }

            ActionButton {
                text: btnText
                btnWidth: 74
                enabled: !backend.dev_busy
                onClicked: triggered()
            }
        }
    }

    component InfoRow: Row {
        property string label: ""
        property string value: ""
        spacing: 10
        Text { width: 110; text: label; color: "#94a3b8"; font.pixelSize: 12 }
        Text { text: value; color: "#f1f5f9"; font.pixelSize: 12; font.bold: true }
    }
}
