import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.addons.display.FlxBackdrop;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.backend.scripting.ModState;
import funkin.options.OptionsMenu;
import funkin.menus.credits.CreditsMain;

var options:Array<String> = ["Story Mode", "Flappy", "Credits", "Options"];
var curSelected:Int = 0;
var grpOptions:FlxTypedGroup<FlxText>;
var bgBackdrop:FlxBackdrop;
var sidePanel:FlxSprite;
var titleText:FlxText;
var titleGlow:Float = 0;

function create() {
    bgBackdrop = new FlxBackdrop(Paths.image('menus/checkeredbg'));
    bgBackdrop.velocity.set(30, 30);
    bgBackdrop.color = 0xFF2A2A3A;
    add(bgBackdrop);

    sidePanel = new FlxSprite().makeGraphic(520, FlxG.height, 0xFF000000);
    sidePanel.alpha = 0.5;
    add(sidePanel);

    // Accent line on panel edge
    var accentLine = new FlxSprite(518, 0).makeGraphic(3, FlxG.height, 0xFFFFEE00);
    accentLine.alpha = 0.6;
    add(accentLine);

    titleText = new FlxText(60, 50, 440, "3D PLATFORMER", 42);
    titleText.setFormat(Paths.font("vcr.ttf"), 42, 0xFFFFEE00, "left");
    add(titleText);

    grpOptions = new FlxTypedGroup();
    add(grpOptions);

    for (i in 0...options.length) {
        var menuText:FlxText = new FlxText(80, 160 + (i * 90), 0, options[i].toUpperCase(), 52);
        menuText.setFormat(Paths.font("vcr.ttf"), 52, FlxColor.WHITE, "left");
        menuText.ID = i;
        menuText.alpha = 0;
        grpOptions.add(menuText);
        FlxTween.tween(menuText, {alpha: 0.6}, 0.3, {startDelay: i * 0.08, ease: FlxEase.quadOut});
    }

    changeSelection(0);
}

function update(elapsed:Float) {
    if (controls.UP_P) changeSelection(-1);
    if (controls.DOWN_P) changeSelection(1);

    // Title subtle pulse
    titleGlow += elapsed * 2;
    titleText.alpha = 0.8 + Math.sin(titleGlow) * 0.2;

    if (controls.ACCEPT) {
        var daChoice = options[curSelected];
        FlxG.sound.play(Paths.sound("confirmMenu"));
        
        // Flash selected item
        grpOptions.forEach(function(txt:FlxText) {
            if (txt.ID == curSelected) {
                FlxTween.color(txt, 0.15, txt.color, 0xFFFFFFFF);
            }
        });

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

    var lerpRatio:Float = FlxMath.bound(elapsed * 10, 0, 1);

    grpOptions.forEach(function(txt:FlxText) {
        var targetX = (txt.ID == curSelected) ? 120 : 80;
        var targetScale = (txt.ID == curSelected) ? 1.05 : 0.95;
        txt.x = FlxMath.lerp(txt.x, targetX, lerpRatio);
        txt.alpha = FlxMath.lerp(txt.alpha, (txt.ID == curSelected) ? 1.0 : 0.45, lerpRatio);
        txt.scale.x = FlxMath.lerp(txt.scale.x, targetScale, lerpRatio);
        txt.scale.y = FlxMath.lerp(txt.scale.y, targetScale, lerpRatio);
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