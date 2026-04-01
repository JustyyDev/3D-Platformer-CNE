import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.group.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.display.FlxBackdrop;
import funkin.backend.scripting.ModState;

var uiCam:FlxCamera;
var currentFont:String = "vcr.ttf";
var bgBackdrop:FlxBackdrop;
var titleGlow:Float = 0;
var cardGroup:FlxTypedGroup<FlxSprite>;
var textGroup:FlxTypedGroup<FlxText>;

var credits:Array<Dynamic> = [
    {name: "JustyTCCD", role: "EVERYTHING CODING WISE", color: 0xFFFFEE00, link: "https://ko-fi.com/justytccd"},
    {name: "Pixabay", role: "PLACEHOLDER ASSETS", color: 0xFF00CCFF, link: "https://pixabay.com"}
];

function create() {
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;

    FlxG.camera.bgColor = 0xFF08081A;
    uiCam = new FlxCamera(); uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    bgBackdrop = new FlxBackdrop(Paths.image('menus/checkeredbg'));
    bgBackdrop.velocity.set(20, 20);
    bgBackdrop.color = 0xFF1A1A2A;
    bgBackdrop.alpha = 0.3;
    add(bgBackdrop);

    cardGroup = new FlxTypedGroup(); add(cardGroup);
    textGroup = new FlxTypedGroup(); add(textGroup);

    var title = new FlxText(0, 30, FlxG.width, "CREDITS", 64);
    title.setFormat(Paths.font(currentFont), 64, 0xFFFFEE00, "center", 4, 0xFF000000);
    title.cameras = [uiCam]; title.ID = 999; textGroup.add(title);

    var sub = new FlxText(0, 100, FlxG.width, "JUSTY'S PARTY PACK", 20);
    sub.setFormat(Paths.font(currentFont), 20, 0xFFCC66FF, "center", 2, 0xFF000000);
    sub.alpha = 0.7; sub.cameras = [uiCam]; textGroup.add(sub);

    var startY = 160;
    var cardH = 90;
    var cardW = Std.int(FlxG.width * 0.7);
    var cardX = Std.int((FlxG.width - cardW) / 2);

    for (i in 0...credits.length) {
        var c = credits[i];
        var yPos = startY + i * (cardH + 16);

        var bg = new FlxSprite(cardX, yPos).makeGraphic(cardW, cardH, 0xFF111122);
        bg.alpha = 0; bg.cameras = [uiCam]; cardGroup.add(bg);
        FlxTween.tween(bg, {alpha: 0.7}, 0.4, {startDelay: i * 0.15, ease: FlxEase.quadOut});

        var stripe = new FlxSprite(cardX, yPos).makeGraphic(5, cardH, c.color);
        stripe.alpha = 0; stripe.cameras = [uiCam]; cardGroup.add(stripe);
        FlxTween.tween(stripe, {alpha: 0.9}, 0.4, {startDelay: i * 0.15});

        var nameText = new FlxText(cardX + 24, yPos + 14, cardW - 40, c.name, 32);
        nameText.setFormat(Paths.font(currentFont), 32, c.color, "left", 2, 0xFF000000);
        nameText.alpha = 0; nameText.cameras = [uiCam]; textGroup.add(nameText);
        FlxTween.tween(nameText, {alpha: 1}, 0.4, {startDelay: i * 0.15 + 0.1});

        var roleText = new FlxText(cardX + 24, yPos + 52, cardW - 40, c.role, 18);
        roleText.setFormat(Paths.font(currentFont), 18, 0xFFAAAAAA, "left", 1, 0xFF000000);
        roleText.alpha = 0; roleText.cameras = [uiCam]; textGroup.add(roleText);
        FlxTween.tween(roleText, {alpha: 0.8}, 0.4, {startDelay: i * 0.15 + 0.15});
    }

    var thankY = startY + credits.length * (cardH + 16) + 30;
    var thankText = new FlxText(0, thankY, FlxG.width, "THANK YOU FOR PLAYING!", 28);
    thankText.setFormat(Paths.font(currentFont), 28, 0xFF44FF66, "center", 2, 0xFF000000);
    thankText.alpha = 0; thankText.cameras = [uiCam]; textGroup.add(thankText);
    FlxTween.tween(thankText, {alpha: 1}, 0.6, {startDelay: credits.length * 0.15 + 0.3});

    var kofiText = new FlxText(0, thankY + 40, FlxG.width, "SUPPORT US ON KO-FI!", 18);
    kofiText.setFormat(Paths.font(currentFont), 18, 0xFFFF6688, "center", 1, 0xFF000000);
    kofiText.alpha = 0; kofiText.cameras = [uiCam]; kofiText.ID = 1; textGroup.add(kofiText);
    FlxTween.tween(kofiText, {alpha: 0.8}, 0.6, {startDelay: credits.length * 0.15 + 0.5});

    var backText = new FlxText(0, FlxG.height - 40, FlxG.width, "[ESC] BACK   [ENTER] OPEN LINK", 16);
    backText.setFormat(Paths.font(currentFont), 16, 0xFF666666, "center", 1, 0xFF000000);
    backText.cameras = [uiCam]; textGroup.add(backText);

    FlxG.sound.playMusic(Paths.music("flappy/mainTheme"), 0.6, true);
}

var curSelected:Int = 0;

function update(elapsed:Float) {
    titleGlow += elapsed * 2;
    textGroup.forEach(function(t:FlxText) {
        if (t.ID == 999) t.scale.set(Math.sin(titleGlow) * 0.04 + 1.0, Math.sin(titleGlow) * 0.04 + 1.0);
    });

    if (FlxG.keys.justPressed.UP && curSelected > 0) { curSelected--; FlxG.sound.play(Paths.sound("scrollMenu")); }
    if (FlxG.keys.justPressed.DOWN && curSelected < credits.length - 1) { curSelected++; FlxG.sound.play(Paths.sound("scrollMenu")); }

    if (FlxG.keys.justPressed.ENTER && curSelected < credits.length) {
        FlxG.openURL(credits[curSelected].link);
        FlxG.camera.flash(0x22FFFFFF, 0.2);
    }

    if (FlxG.keys.justPressed.ESCAPE) FlxG.switchState(new ModState("CustomMainMenu"));
}
