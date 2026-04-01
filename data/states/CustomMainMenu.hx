import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.addons.display.FlxBackdrop;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.backend.scripting.ModState;
import funkin.options.OptionsMenu;

var games:Array<Dynamic> = [
    {name: "Flockfall", state: "FlockfallState", desc: "DODGE PIPES, EARN FLOCKERS, BATTLE ROYALE!", color: 0xFFFFEE00},
    {name: "Treasure Grab", state: "TreasureGrabState", desc: "GRAB AS MANY FLOCKERS AS YOU CAN IN 60 SECONDS!", color: 0xFFFFD700},
    {name: "Bumper Birds", state: "BumperBirdsState", desc: "PUSH OTHERS OFF THE PLATFORM! LAST BIRD STANDING WINS!", color: 0xFFFF6644},
    {name: "Dodge Derby", state: "DodgeDerbyState", desc: "SURVIVE WAVES OF PROJECTILES! DON'T GET HIT!", color: 0xFF00CCFF},
    {name: "Musical Tiles", state: "MusicalTilesState", desc: "STAND ON LIT TILES WHEN THE MUSIC STOPS!", color: 0xFFFF44AA}
];
var menuItems:Array<String> = [];
var curSelected:Int = 0;
var grpOptions:FlxTypedGroup<FlxText>;
var bgBackdrop:FlxBackdrop;
var sidePanel:FlxSprite;
var titleText:FlxText;
var descText:FlxText;
var titleGlow:Float = 0;
var flockerText:FlxText;
var flockerIcon:FlxText;
var flockerSpin:Float = 0;

function create() {
    for (g in games) menuItems.push(g.name);
    menuItems.push("Shop");
    menuItems.push("Credits");
    menuItems.push("Options");

    bgBackdrop = new FlxBackdrop(Paths.image('menus/checkeredbg'));
    bgBackdrop.velocity.set(30, 30);
    bgBackdrop.color = 0xFF2A2A3A;
    add(bgBackdrop);

    sidePanel = new FlxSprite().makeGraphic(540, FlxG.height, 0xFF000000);
    sidePanel.alpha = 0.5;
    add(sidePanel);

    var accentLine = new FlxSprite(538, 0).makeGraphic(3, FlxG.height, 0xFFFFEE00);
    accentLine.alpha = 0.6;
    add(accentLine);

    titleText = new FlxText(40, 14, 480, "JUSTY'S\nPARTY PACK", 38);
    titleText.setFormat(Paths.font("vcr.ttf"), 38, 0xFFFFEE00, "left");
    add(titleText);

    descText = new FlxText(560, FlxG.height - 80, FlxG.width - 580, "", 16);
    descText.setFormat(Paths.font("vcr.ttf"), 16, 0xFFAAAAAA, "left");
    descText.alpha = 0.7;
    add(descText);

    var flockers = 0;
    if (FlxG.save.data.flappyCoins != null) flockers = FlxG.save.data.flappyCoins;
    flockerIcon = new FlxText(FlxG.width - 240, 14, 30, "F", 20);
    flockerIcon.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFFD700, "center");
    add(flockerIcon);
    flockerText = new FlxText(FlxG.width - 210, 14, 190, "" + flockers, 20);
    flockerText.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFFD700, "right");
    add(flockerText);

    grpOptions = new FlxTypedGroup();
    add(grpOptions);

    for (i in 0...menuItems.length) {
        var yPos = 120 + (i * 58);
        var menuText:FlxText = new FlxText(10, yPos, 520, menuItems[i].toUpperCase(), 36);
        menuText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, "left");
        menuText.ID = i;
        menuText.x -= 20;
        menuText.alpha = 0;
        grpOptions.add(menuText);
        FlxTween.tween(menuText, {alpha: 0.5}, 0.3, {startDelay: i * 0.04, ease: FlxEase.quadOut});
    }

    changeSelection(0);
}

function update(elapsed:Float) {
    if (controls.UP_P) changeSelection(-1);
    if (controls.DOWN_P) changeSelection(1);

    titleGlow += elapsed * 2;
    titleText.alpha = 0.8 + Math.sin(titleGlow) * 0.2;

    flockerSpin += elapsed * 6;
    flockerIcon.scale.set(Math.abs(Math.cos(flockerSpin)) * 0.6 + 0.4, 1.0);

    if (controls.ACCEPT) {
        FlxG.sound.play(Paths.sound("confirmMenu"));

        grpOptions.forEach(function(txt:FlxText) {
            if (txt.ID == curSelected) FlxTween.color(txt, 0.15, txt.color, 0xFFFFFFFF);
        });

        if (curSelected < games.length) {
            FlxG.switchState(new ModState(games[curSelected].state));
        } else {
            var extra = curSelected - games.length;
            if (extra == 0) FlxG.switchState(new ModState("ShopState"));
            else if (extra == 1) FlxG.switchState(new ModState("CreditsState"));
            else if (extra == 2) FlxG.switchState(new OptionsMenu());
        }
    }

    var lerpRatio:Float = FlxMath.bound(elapsed * 10, 0, 1);

    grpOptions.forEach(function(txt:FlxText) {
        var isSel = txt.ID == curSelected;
        var targetX = isSel ? 50 : 40;
        var targetScale = isSel ? 1.05 : 0.92;
        txt.x = FlxMath.lerp(txt.x, targetX, lerpRatio);
        txt.alpha = FlxMath.lerp(txt.alpha, isSel ? 1.0 : 0.4, lerpRatio);
        txt.scale.x = FlxMath.lerp(txt.scale.x, targetScale, lerpRatio);
        txt.scale.y = FlxMath.lerp(txt.scale.y, targetScale, lerpRatio);
    });
}

function changeSelection(change:Int) {
    curSelected += change;
    if (curSelected < 0) curSelected = menuItems.length - 1;
    if (curSelected >= menuItems.length) curSelected = 0;

    FlxG.sound.play(Paths.sound("scrollMenu"));

    grpOptions.forEach(function(txt:FlxText) {
        if (txt.ID == curSelected) {
            if (curSelected < games.length) txt.color = games[curSelected].color;
            else txt.color = 0xFFFFFF00;
        } else {
            txt.color = 0xFFFFFFFF;
        }
    });

    if (curSelected < games.length) descText.text = games[curSelected].desc;
    else if (curSelected == games.length) descText.text = "BUY SKINS, TRAILS AND FLOCKERS";
    else if (curSelected == games.length + 1) descText.text = "";
    else descText.text = "";
}
