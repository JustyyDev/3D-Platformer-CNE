import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.backend.scripting.ModState;

var canProceed:Bool = false;
var warningText:FlxText;
var promptText:FlxText;
var titlePulse:Float = 0;
var titleObj:FlxText;

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

    FlxTween.tween(warningText, {alpha: 1}, 1, {startDelay: 0.3, ease: FlxEase.quadOut, onComplete: function(_) {
        canProceed = true;
        FlxTween.tween(promptText, {alpha: 1}, 0.8, {ease: FlxEase.quadOut, type: 4});
    }});
}

function update(elapsed:Float) {
    // Pulsing title glow
    titlePulse += elapsed * 3;
    titleObj.alpha = 0.7 + Math.sin(titlePulse) * 0.3;

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