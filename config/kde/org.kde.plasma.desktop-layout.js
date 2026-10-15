var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
    desktopsArray[j].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktopsArray[j].writeConfig("Image", "/usr/share/wallpapers/Raytolfas/wallpaper.png");
    desktopsArray[j].writeConfig("FillMode", 2);
}

var panel = new Panel;
var panelScreen = panel.screen;

panel.location = "bottom";
panel.height = 46;
panel.floating = false;

var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "start-here-raytolfas");
kickoff.writeConfig("useCustomButtonImage", true);
kickoff.writeConfig("customButtonImage", "/usr/share/icons/hicolor/scalable/apps/start-here-raytolfas.svg");

kickoff.currentConfigGroup = ["Shortcuts"];
kickoff.writeConfig("global", "Alt+F1");

panel.addWidget("org.kde.plasma.pager");

var icontasks = panel.addWidget("org.kde.plasma.icontasks");
icontasks.currentConfigGroup = ["General"];
icontasks.writeConfig("launchers", [
    "applications:firefox.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.plasma-systemmonitor.desktop",
    "applications:systemsettings.desktop",
    "applications:raytolfas-android.desktop"
]);
icontasks.writeConfig("indicateAudioStreams", true);
icontasks.writeConfig("maxRows", 1);
icontasks.writeConfig("fill", true);

panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");

var panelClock = panel.addWidget("org.kde.plasma.digitalclock");
panelClock.currentConfigGroup = ["Appearance"];
panelClock.writeConfig("use24hFormat", 2);
panelClock.writeConfig("showSeconds", 0);
panelClock.writeConfig("showDate", false);

panel.addWidget("org.kde.plasma.showdesktop");
