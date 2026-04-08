import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.backend.scripting.ModState;
import funkin.backend.system.github.GitHub;

var CURRENT_VERSION:String = "0.1.1";
var GITHUB_USER:String = "JustyyDev";
var GITHUB_REPO:String = "3D-Platformer-CNE";

var canProceed:Bool = false;
var warningText:FlxText;
var promptText:FlxText;
var titlePulse:Float = 0;
var titleObj:FlxText;

var updateAvailable:Bool = false;
var updateURL:String = "";
var updateTag:String = "";
var updateBody:String = "";
var updateText:FlxText;
var updateDetailText:FlxText;
var updatePromptText:FlxText;
var updatePanel:FlxSprite;
var showingUpdate:Bool = false;

function create() {
    var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF0A0A0A);
    add(bg);

    // Subtle red vignette strip
    var topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 4, 0xFFFF0000);
    topBar.alpha = 0.6;
    add(topBar);

    titleObj = new FlxText(0, 80, FlxG.width, "WARNING", 72);
    titleObj.setFormat(Paths.font("vcr.ttf"), 72, 0xFFFF2222, "center", 4, 0xFF440000);
    titleObj.alpha = 0;
    add(titleObj);
    FlxTween.tween(titleObj, {alpha: 1}, 0.6, {ease: FlxEase.quadOut});

    warningText = new FlxText(0, 0, FlxG.width * 0.75, "This mod contains flashing lights and elements that may be sensitive to some players.\n\nProceed at your own risk.", 28);
    warningText.setFormat(Paths.font("vcr.ttf"), 28, 0xFFDDDDDD, "center");
    warningText.screenCenter();
    warningText.alpha = 0;
    add(warningText);

    promptText = new FlxText(0, FlxG.height - 100, FlxG.width, "Press ENTER to Continue", 22);
    promptText.setFormat(Paths.font("vcr.ttf"), 22, 0xFFFFEE00, "center");
    promptText.alpha = 0;
    add(promptText);

    // Update UI (hidden by default)
    updatePanel = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF0A0A1A);
    updatePanel.alpha = 0;
    updatePanel.visible = false;
    add(updatePanel);

    updateText = new FlxText(0, 80, FlxG.width, "UPDATE AVAILABLE", 56);
    updateText.setFormat(Paths.font("vcr.ttf"), 56, 0xFF00FF88, "center", 4, 0xFF003322);
    updateText.visible = false;
    add(updateText);

    updateDetailText = new FlxText(0, 0, FlxG.width * 0.7, "", 22);
    updateDetailText.setFormat(Paths.font("vcr.ttf"), 22, 0xFFCCCCCC, "center");
    updateDetailText.screenCenter();
    updateDetailText.visible = false;
    add(updateDetailText);

    updatePromptText = new FlxText(0, FlxG.height - 100, FlxG.width, "[ENTER] Download Update    [ESCAPE] Skip", 20);
    updatePromptText.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFFEE00, "center");
    updatePromptText.visible = false;
    add(updatePromptText);

    FlxTween.tween(warningText, {alpha: 1}, 1, {startDelay: 0.3, ease: FlxEase.quadOut, onComplete: function(_) {
        canProceed = true;
        FlxTween.tween(promptText, {alpha: 1}, 0.8, {ease: FlxEase.quadOut, type: 4});
    }});

    checkForUpdates();
}

function checkForUpdates() {
    try {
        var releases = GitHub.getReleases(GITHUB_USER, GITHUB_REPO, function(e) {});
        if (releases != null && releases.length > 0) {
            var filtered = GitHub.filterReleases(releases, false, false);
            if (filtered != null && filtered.length > 0) {
                var latest = filtered[0];
                var latestTag = StringTools.replace(latest.tag_name, "v", "");
                if (isNewerVersion(latestTag, CURRENT_VERSION)) {
                    updateAvailable = true;
                    updateTag = latest.tag_name;
                    updateURL = latest.html_url;
                    // Prefer zip asset, fallback to release page
                    if (latest.assets != null && latest.assets.length > 0) {
                        for (ai in 0...latest.assets.length) {
                            var asset = latest.assets[ai];
                            if (StringTools.endsWith(asset.name, ".zip")) {
                                updateURL = asset.browser_download_url;
                                break;
                            }
                        }
                    }
                    var desc = latest.body != null ? latest.body : "";
                    if (desc.length > 200) desc = desc.substring(0, 200) + "...";
                    updateBody = desc;
                }
            }
        }
    } catch(e:Dynamic) {
        // Silently fail - no update check if offline
    }
}

function isNewerVersion(remote:String, local:String):Bool {
    var rParts = remote.split(".");
    var lParts = local.split(".");
    for (i in 0...3) {
        var r = i < rParts.length ? Std.parseInt(rParts[i]) : 0;
        var l = i < lParts.length ? Std.parseInt(lParts[i]) : 0;
        if (r == null) r = 0;
        if (l == null) l = 0;
        if (r > l) return true;
        if (r < l) return false;
    }
    return false;
}

function showUpdateScreen() {
    showingUpdate = true;
    canProceed = false;

    FlxTween.tween(titleObj, {alpha: 0}, 0.3);
    FlxTween.tween(warningText, {alpha: 0}, 0.3);
    FlxTween.tween(promptText, {alpha: 0}, 0.3);

    updatePanel.visible = true;
    updateText.visible = true;
    updateDetailText.visible = true;
    updatePromptText.visible = true;

    FlxTween.tween(updatePanel, {alpha: 0.95}, 0.4);

    updateDetailText.text = "New version: " + updateTag + "\nCurrent: v" + CURRENT_VERSION
        + (updateBody.length > 0 ? "\n\n" + updateBody : "");
    updateDetailText.screenCenter();

    updateText.alpha = 0;
    updateText.scale.set(1.5, 1.5);
    FlxTween.tween(updateText, {alpha: 1}, 0.4, {startDelay: 0.2, ease: FlxEase.quadOut});
    FlxTween.tween(updateText.scale, {x: 1, y: 1}, 0.5, {startDelay: 0.2, ease: FlxEase.elasticOut});

    updateDetailText.alpha = 0;
    FlxTween.tween(updateDetailText, {alpha: 1}, 0.5, {startDelay: 0.4});
    updatePromptText.alpha = 0;
    FlxTween.tween(updatePromptText, {alpha: 1}, 0.5, {startDelay: 0.6});
}

function dismissUpdate() {
    showingUpdate = false;
    FlxTween.tween(updatePanel, {alpha: 0}, 0.3);
    FlxTween.tween(updateText, {alpha: 0}, 0.3);
    FlxTween.tween(updateDetailText, {alpha: 0}, 0.3);
    FlxTween.tween(updatePromptText, {alpha: 0}, 0.3);

    titleObj.alpha = 0;
    warningText.alpha = 0;
    FlxTween.tween(titleObj, {alpha: 1}, 0.4, {startDelay: 0.3});
    FlxTween.tween(warningText, {alpha: 1}, 0.4, {startDelay: 0.3, onComplete: function(_) {
        canProceed = true;
        FlxTween.tween(promptText, {alpha: 1}, 0.5);
    }});
}

function update(elapsed:Float) {
    titlePulse += elapsed * 3;
    if (titleObj.visible && titleObj.alpha > 0) {
        titleObj.alpha = 0.7 + Math.sin(titlePulse) * 0.3;
    }

    if (showingUpdate) {
        if (FlxG.keys.justPressed.ENTER) {
            FlxG.openURL(updateURL);
        }
        if (FlxG.keys.justPressed.ESCAPE) {
            dismissUpdate();
        }
        return;
    }

    if (canProceed && updateAvailable && !showingUpdate) {
        showUpdateScreen();
        return;
    }

    if (canProceed && controls.ACCEPT) {
        canProceed = false;
        FlxG.sound.play(Paths.sound("confirmMenu"));
        
        FlxTween.tween(warningText, {alpha: 0}, 0.5, {ease: FlxEase.quadIn});
        FlxTween.tween(promptText, {alpha: 0}, 0.5, {ease: FlxEase.quadIn});
        
        new FlxTimer().start(0.6, function(_) {
            FlxG.switchState(new ModState("CustomMainMenu"));
        });
    }
}