import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.backend.scripting.ModState;

var menuItems:Array<String> = ["Resume", "Restart", "Exit"];
var curSelected:Int = 0;
var grpText:FlxTypedGroup<FlxText>;

function create() {
    var overlay:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000);
    overlay.scrollFactor.set();
    add(overlay);
    FlxTween.color(overlay, 0.25, 0x00000000, 0xBB000000);

    var pauseTitle:FlxText = new FlxText(0, 200, FlxG.width, "PAUSED", 72);
    pauseTitle.setFormat(Paths.font("vcr.ttf"), 72, 0xFFFFEE00, "center", 3, 0xFF000000);
    pauseTitle.alpha = 0;
    add(pauseTitle);
    FlxTween.tween(pauseTitle, {alpha: 1, y: 180}, 0.3, {ease: FlxEase.quadOut});

    grpText = new FlxTypedGroup();
    add(grpText);

    for (i in 0...menuItems.length) {
        var t:FlxText = new FlxText(0, 310 + (i * 70), FlxG.width, menuItems[i], 38);
        t.setFormat(Paths.font("vcr.ttf"), 38, 0xFFFFFFFF, "center", 2, 0xFF000000);
        t.ID = i;
        t.alpha = 0;
        grpText.add(t);
        FlxTween.tween(t, {alpha: 0.6}, 0.25, {startDelay: 0.1 + i * 0.06, ease: FlxEase.quadOut});
    }
    changeSelection(0);
}

function update(elapsed:Float) {
    if (controls.UP_P) changeSelection(-1);
    if (controls.DOWN_P) changeSelection(1);

    if (controls.ACCEPT) {
        var daChoice = menuItems[curSelected];
        if (daChoice == "Resume") {
            close();
        } else if (daChoice == "Restart") {
            FlxG.resetState();
        } else if (daChoice == "Exit") {
            FlxG.switchState(new ModState("CustomMainMenu"));
        }
    }
}

function changeSelection(change:Int) {
    curSelected += change;
    if (curSelected < 0) curSelected = menuItems.length - 1;
    if (curSelected >= menuItems.length) curSelected = 0;

    FlxG.sound.play(Paths.sound("scrollMenu"), 0.5);

    grpText.forEach(function(t:FlxText) {
        var selected = t.ID == curSelected;
        t.color = selected ? 0xFFFFEE00 : 0xFFFFFFFF;
        t.alpha = selected ? 1.0 : 0.5;
        var s:Float = selected ? 1.15 : 0.95;
        t.scale.set(s, s);
    });
}

function destroy() {
    if (parent != null) {
        parent.call("onSubStateClose", [this]);
    }
}
