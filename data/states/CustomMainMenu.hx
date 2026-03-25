import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.addons.display.FlxBackdrop;
import funkin.backend.scripting.ModState;
import funkin.options.OptionsMenu;
import funkin.menus.credits.CreditsMain;

var options:Array<String> = ["Story Mode", "Flappy", "Credits", "Options"];
var curSelected:Int = 0;
var grpOptions:FlxTypedGroup<FlxText>;
var bgBackdrop:FlxBackdrop;
var sidePanel:FlxSprite;

function create() {
    bgBackdrop = new FlxBackdrop(Paths.image('menus/checkeredbg'));
    bgBackdrop.velocity.set(50, 50);
    bgBackdrop.color = 0xFF353535;
    add(bgBackdrop);

    sidePanel = new FlxSprite().makeGraphic(500, FlxG.height, 0xFF000000);
    sidePanel.alpha = 0.4;
    add(sidePanel);

    grpOptions = new FlxTypedGroup();
    add(grpOptions);

    for (i in 0...options.length) {
        var menuText:FlxText = new FlxText(80, 150 + (i * 100), 0, options[i].toUpperCase(), 60);
        menuText.setFormat(Paths.font("vcr.ttf"), 60, FlxColor.WHITE, "left");
        menuText.italic = true;
        menuText.ID = i;
        grpOptions.add(menuText);
    }

    changeSelection(0);
}

function update(elapsed:Float) {
    if (controls.UP_P) changeSelection(-1);
    if (controls.DOWN_P) changeSelection(1);

    if (controls.ACCEPT) {
        var daChoice = options[curSelected];
        FlxG.sound.play(Paths.sound("confirmMenu"));
        
        switch (daChoice) {
            case "Story Mode":
                FlxG.switchState(new StoryMenuState());
            case "Flappy":
                FlxG.switchState(new ModState("FlappyState"));
            case "Credits":
                FlxG.switchState(new CreditsMain());
            case "Options":
                FlxG.switchState(new OptionsMenu());
        }
    }

    var lerpRatio:Float = FlxMath.bound(elapsed * 12, 0, 1);

    grpOptions.forEach(function(txt:FlxText) {
        var targetX = (txt.ID == curSelected) ? 140 : 80;
        txt.x = FlxMath.lerp(txt.x, targetX, lerpRatio);
        txt.alpha = FlxMath.lerp(txt.alpha, (txt.ID == curSelected) ? 1.0 : 0.6, lerpRatio);
    });
}

function changeSelection(change:Int) {
    curSelected += change;
    if (curSelected < 0) curSelected = options.length - 1;
    if (curSelected >= options.length) curSelected = 0;

    FlxG.sound.play(Paths.sound("scrollMenu"));

    grpOptions.forEach(function(txt:FlxText) {
        txt.color = (txt.ID == curSelected) ? 0xFFFFFF00 : 0xFFFFFFFF;
    });
}