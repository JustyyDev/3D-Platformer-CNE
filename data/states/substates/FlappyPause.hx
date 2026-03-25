import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;

var menuItems:Array<String> = ["Resume", "Restart", "Exit"];
var curSelected:Int = 0;
var grpText:FlxTypedGroup<FlxText>;

function create() {
    var overlay:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x80000000);
    overlay.scrollFactor.set();
    add(overlay);

    grpText = new FlxTypedGroup();
    add(grpText);

    for (i in 0...menuItems.length) {
        var t:FlxText = new FlxText(0, 300 + (i * 80), FlxG.width, menuItems[i], 42);
        t.setFormat(Paths.font("vcr.ttf"), 42, 0xFFFFFFFF, "center", 1, 0xFF000000);
        t.ID = i;
        grpText.add(t);
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
            FlxG.switchState(new ModState("FlappyState")); 
        } else if (daChoice == "Exit") {
            FlxG.switchState(new ModState("CustomMainMenu"));
        }
    }
}

function changeSelection(change:Int) {
    curSelected += change;
    if (curSelected < 0) curSelected = menuItems.length - 1;
    if (curSelected >= menuItems.length) curSelected = 0;
    
    // FIX: Just use the name, CNE handles the extension
    FlxG.sound.play(Paths.sound("scrollMenu"), 0.5);

    grpText.forEach(function(t:FlxText) {
        t.color = (t.ID == curSelected) ? 0xFFFFFF00 : 0xFFFFFFFF;
        var s:Float = (t.ID == curSelected) ? 1.2 : 1.0;
        t.scale.set(s, s);
    });
}

function destroy() {
    if (parent != null) {
        // FIX: Pass 'this' as the parameter so the parent function is happy
        parent.call("onSubStateClose", [this]);
    }
}