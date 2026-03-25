import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.backend.scripting.ModState;

var canProceed:Bool = false;
var warningText:FlxText;
var promptText:FlxText;

function create() {
    var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    add(bg);

    var title:FlxText = new FlxText(0, 100, FlxG.width, "WARNING", 64);
    title.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.RED, "center");
    add(title);

    warningText = new FlxText(0, 0, FlxG.width * 0.8, "This mod contains flashing lights and elements that may be sensitive to some players.\n\nProceed at your own risk.", 32);
    warningText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, "center");
    warningText.screenCenter();
    warningText.alpha = 0;
    add(warningText);

    promptText = new FlxText(0, FlxG.height - 100, FlxG.width, "Press ENTER to Continue", 24);
    promptText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, "center");
    promptText.alpha = 0;
    add(promptText);

    FlxTween.tween(warningText, {alpha: 1}, 1, {ease: FlxEase.quadOut, onComplete: function(_) {
        canProceed = true;
        FlxTween.tween(promptText, {alpha: 1}, 1, {ease: FlxEase.quadOut, type: 4});
    }});
}

function update(elapsed:Float) {
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