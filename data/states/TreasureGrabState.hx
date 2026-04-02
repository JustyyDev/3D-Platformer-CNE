import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.group.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.addons.display.FlxBackdrop;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.ModSubState;
import funkin.menus.MainMenuState;
import sys.net.Host;
import funkin.backend.system.net.Socket;

var gameState:String = "MENU";
var uiCam:FlxCamera;
var currentFont:String = "vcr.ttf";
var myNickname:String = "Player";
var flappyCoins:Int = 0;
var coinText:FlxText;
var coinIconText:FlxText;
var coinBounce:Float = 1.0;
var coinIconSpin:Float = 0;

var SERVER_IP:String = "144.21.35.78";
var SERVER_PORT:Int = 8080;
var connection:Socket;
var isMultiplayer:Bool = false;
var netConnected:Bool = false;
var netBuffer:String = "";
var pollTimer:FlxTimer;
var typedInput:String = "";
var activeRoomCode:String = "";
var isHost:Bool = false;
var lobbyPlayers:Array<String> = [];
var activePlayers:Array<String> = [];

var titleText:FlxText;
var subtitleText:FlxText;
var lobbyText:FlxText;
var typingText:FlxText;
var typingBg:FlxSprite;
var typingCursorTimer:Float = 0;
var typingCursorBlink:Bool = true;
var lobbySlotGroup:FlxTypedGroup<FlxText>;
var lobbyBgGroup:FlxTypedGroup<FlxSprite>;
var lobbyRoomText:FlxText;
var waitDots:Int = 0;
var waitDotTimer:Float = 0;
var titleGlow:Float = 0;
var playerColors:Array<Int> = [0xFFFFEE00, 0xFF00CCFF, 0xFFFF6699, 0xFF66FF66, 0xFFFF9933, 0xFFCC66FF];

var player:FlxSprite;
var playerEye:FlxSprite;
var playerBeak:FlxSprite;
var playerSpeed:Float = 320;

var coinGroup:FlxTypedGroup<FlxSprite>;
var coinGlowGroup:FlxTypedGroup<FlxSprite>;
var coinLabelGroup:FlxTypedGroup<FlxText>;
var vfxGroup:FlxTypedGroup<FlxSprite>;
var playerGroup:FlxTypedGroup<FlxSprite>;
var nickTagGroup:FlxTypedGroup<FlxText>;
var playerMap:Dynamic = {};
var playerEyeMap:Dynamic = {};
var playerBeakMap:Dynamic = {};
var playerNickMap:Dynamic = {};
var playerScoreMap:Dynamic = {};
var targetXMap:Dynamic = {};
var targetYMap:Dynamic = {};

var roundTimer:Float = 60;
var timerText:FlxText;
var scoreText:FlxText;
var localScore:Int = 0;
var coinSpawnTimer:Float = 0;
var coinSpawnRate:Float = 0.4;
var roundStarted:Bool = false;
var countdownActive:Bool = false;

var powerupTimer:Float = 0;
var hasMagnet:Bool = false;
var magnetTimer:Float = 0;
var hasDouble:Bool = false;
var doubleTimer:Float = 0;
var statusEffect:FlxText;

var arenaLeft:Float = 40;
var arenaRight:Float = 0;
var arenaTop:Float = 80;
var arenaBottom:Float = 0;
var arenaFloor:FlxSprite;
var arenaBorder:FlxSprite;
var serverState:Dynamic = null;

function create() {
    if (FlxG.save.data.flappyNickname != null) myNickname = FlxG.save.data.flappyNickname;
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;
    if (FlxG.save.data.flappyCoins != null) flappyCoins = FlxG.save.data.flappyCoins;

    arenaRight = FlxG.width - 40;
    arenaBottom = FlxG.height - 50;

    FlxG.camera.bgColor = 0xFF0E0E1E;
    uiCam = new FlxCamera(); uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    arenaFloor = new FlxSprite(arenaLeft, arenaTop).makeGraphic(Std.int(arenaRight - arenaLeft), Std.int(arenaBottom - arenaTop), 0xFF161628);
    arenaFloor.alpha = 0.6;
    add(arenaFloor);

    var borderTop = new FlxSprite(arenaLeft - 3, arenaTop - 3).makeGraphic(Std.int(arenaRight - arenaLeft + 6), 3, 0xFFFFD700);
    var borderBot = new FlxSprite(arenaLeft - 3, Std.int(arenaBottom)).makeGraphic(Std.int(arenaRight - arenaLeft + 6), 3, 0xFFFFD700);
    var borderL = new FlxSprite(arenaLeft - 3, arenaTop - 3).makeGraphic(3, Std.int(arenaBottom - arenaTop + 6), 0xFFFFD700);
    var borderR = new FlxSprite(Std.int(arenaRight), arenaTop - 3).makeGraphic(3, Std.int(arenaBottom - arenaTop + 6), 0xFFFFD700);
    borderTop.alpha = 0.5; borderBot.alpha = 0.5; borderL.alpha = 0.5; borderR.alpha = 0.5;
    add(borderTop); add(borderBot); add(borderL); add(borderR);

    coinGlowGroup = new FlxTypedGroup(); add(coinGlowGroup);
    coinGroup = new FlxTypedGroup(); add(coinGroup);
    coinLabelGroup = new FlxTypedGroup(); add(coinLabelGroup);
    vfxGroup = new FlxTypedGroup(); add(vfxGroup);
    playerGroup = new FlxTypedGroup(); add(playerGroup);
    nickTagGroup = new FlxTypedGroup(); add(nickTagGroup);

    var skinCol = 0xFFFFEE00;
    if (FlxG.save.data.flappyEquippedSkinId != null) {
        var skins:Array<Dynamic> = [
            {id: "default", color: 0xFFFFEE00}, {id: "ice", color: 0xFF00CCFF}, {id: "bubblegum", color: 0xFFFF6699},
            {id: "neon", color: 0xFF66FF66}, {id: "sunset", color: 0xFFFF9933}, {id: "lavender", color: 0xFFCC66FF},
            {id: "crimson", color: 0xFFFF0000}, {id: "aqua", color: 0xFF00FFCC}, {id: "ghost", color: 0xFFFFFFFF},
            {id: "shadow", color: 0xFF333333}, {id: "pink", color: 0xFFFF1493}, {id: "royal", color: 0xFF4169E1},
            {id: "golden", color: 0xFFFFD700}
        ];
        for (s in skins) if (s.id == FlxG.save.data.flappyEquippedSkinId) skinCol = s.color;
    }

    player = new FlxSprite(FlxG.width / 2, FlxG.height / 2).makeGraphic(34, 28, skinCol);
    player.antialiasing = true; add(player);
    playerEye = new FlxSprite(0, 0).makeGraphic(8, 8, 0xFFFFFFFF); add(playerEye);
    playerBeak = new FlxSprite(0, 0).makeGraphic(12, 7, 0xFFFF8800); add(playerBeak);

    lobbySlotGroup = new FlxTypedGroup(); add(lobbySlotGroup);
    lobbyBgGroup = new FlxTypedGroup(); add(lobbyBgGroup);

    setupUI();
    goToState("MENU");
}

function setupUI() {
    titleText = makeText(0, 40, FlxG.width, "TREASURE GRAB", 64, 0xFFFFD700);
    subtitleText = makeText(0, 110, FlxG.width, "COLLECT FLOCKERS!", 20, 0xFFFF9933); subtitleText.alpha = 0.7;
    lobbyText = makeText(0, FlxG.height * 0.78, FlxG.width, "", 22, 0xFFFFEE00);
    typingBg = new FlxSprite(FlxG.width * 0.2, FlxG.height * 0.81).makeGraphic(Std.int(FlxG.width * 0.6), 48, 0xFF1A1A2E); typingBg.alpha = 0.7; typingBg.cameras = [uiCam]; add(typingBg); typingBg.visible = false;
    typingText = makeText(0, FlxG.height * 0.82, FlxG.width, "", 34, 0xFFFFFFFF);
    timerText = makeText(0, 10, FlxG.width, "60", 42, 0xFFFFFFFF);
    scoreText = makeText(0, 56, FlxG.width, "0 FLOCKERS", 24, 0xFFFFD700);
    coinIconText = makeText(FlxG.width - 240, 10, 30, "F", 20, 0xFFFFD700);
    coinText = makeText(FlxG.width - 210, 10, 190, "" + flappyCoins, 20, 0xFFFFD700); coinText.alignment = "right";
    statusEffect = makeText(0, FlxG.height - 36, FlxG.width, "", 16, 0xFF00FF88);
    lobbyRoomText = makeText(0, FlxG.height * 0.12, FlxG.width, "", 22, 0xFF88CCFF); lobbyRoomText.visible = false;
}

function makeText(x:Float, y:Float, w:Float, text:String, size:Int, color:Int):FlxText {
    var t = new FlxText(x, y, w, text, size);
    t.setFormat(Paths.font(currentFont), size, color, "center", 2, 0xFF000000);
    t.cameras = [uiCam]; add(t); return t;
}

function goToState(s:String) {
    gameState = s; typedInput = ""; typingText.text = ""; lobbySlotGroup.clear(); lobbyBgGroup.clear(); lobbyRoomText.visible = false;

    if (s == "MENU") { netDisconnect(); isMultiplayer = false; lobbyPlayers = []; activePlayers = []; resetMultiplayerData(); }

    titleText.visible = (s == "MENU" || s == "ROOM_INPUT");
    subtitleText.visible = (s == "MENU");
    lobbyText.visible = true;
    typingText.visible = (s == "ROOM_INPUT"); typingBg.visible = typingText.visible;
    timerText.visible = (s == "PLAYING"); scoreText.visible = (s == "PLAYING" || s == "GAMEOVER");
    coinText.visible = true; coinIconText.visible = true;
    statusEffect.visible = (s == "PLAYING"); statusEffect.text = "";

    player.visible = (s == "PLAYING"); playerEye.visible = player.visible; playerBeak.visible = player.visible;

    switch(s) {
        case "MENU": lobbyText.text = "[1] SOLO   [2] MULTI   [ESC] BACK"; FlxG.sound.playMusic(Paths.music("flappy/mainTheme"), 0.8, true);
        case "ROOM_INPUT": lobbyText.text = "ENTER 4-LETTER ROOM CODE";
        case "PLAYING": startRound();
        case "GAMEOVER": showResults();
    }
}

function resetMultiplayerData() {
    playerMap = {}; playerEyeMap = {}; playerBeakMap = {}; playerNickMap = {}; playerScoreMap = {};
    targetXMap = {}; targetYMap = {};
}

function startRound() {
    roundTimer = 60; localScore = 0; coinSpawnTimer = 0; coinSpawnRate = 0.4; roundStarted = false; countdownActive = true;
    hasMagnet = false; hasDouble = false; powerupTimer = 0;
    coinGroup.clear(); coinGlowGroup.clear(); coinLabelGroup.clear(); vfxGroup.clear();
    player.x = FlxG.width / 2 - 17; player.y = FlxG.height / 2 - 14;
    titleText.visible = false; subtitleText.visible = false; lobbyText.visible = false; typingText.visible = false; typingBg.visible = false;
    scoreText.text = "0 FLOCKERS"; timerText.text = "60";

    FlxG.sound.playMusic(Paths.music("flappy/racingTillDawn"), 0, true);
    FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.5);

    var count = 3;
    var countText = new FlxText(0, 0, FlxG.width, "3", 140);
    countText.setFormat(Paths.font(currentFont), 140, 0xFFFFFFFF, "center", 6, 0xFF000000);
    countText.screenCenter(); countText.cameras = [uiCam]; add(countText);

    new FlxTimer().start(1, function(tmr) {
        count--;
        if (count <= 0) {
            tmr.cancel(); countText.text = "GRAB!"; countText.color = 0xFFFFD700;
            countText.scale.set(1.5, 1.5);
            FlxTween.tween(countText, {alpha: 0}, 0.5, {ease: FlxEase.quadIn, onComplete: function(_) { countText.destroy(); }});
            FlxG.camera.flash(0x33FFFFFF, 0.3); countdownActive = false; roundStarted = true;
        } else {
            countText.text = Std.string(count); countText.scale.set(1.5, 1.5);
            FlxTween.tween(countText.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.elasticOut});
            countText.color = [0xFFFFEE00, 0xFFFF9900, 0xFFFF4444][3 - count];
            FlxG.camera.shake(0.004, 0.1);
        }
    }, 0);
}

function spawnCoin(isBig:Bool, isPowerup:Int) {
    var cx = FlxG.random.float(arenaLeft + 20, arenaRight - 20);
    var cy = FlxG.random.float(arenaTop + 20, arenaBottom - 20);
    var size = isBig ? 22 : 14;
    var col = 0xFFFFD700;

    if (isPowerup == 1) col = 0xFFFF00FF;
    else if (isPowerup == 2) col = 0xFF00FFCC;
    else if (isBig) col = 0xFFFFF0AA;

    var coin = coinGroup.recycle(FlxSprite);
    if (coin == null) coin = new FlxSprite();
    coin.makeGraphic(size, size, col);
    coin.reset(cx, cy); coin.alpha = 0; coin.ID = isPowerup > 0 ? isPowerup + 100 : (isBig ? 5 : 1);
    coinGroup.add(coin);
    FlxTween.tween(coin, {alpha: 1}, 0.2);

    var glow = coinGlowGroup.recycle(FlxSprite);
    if (glow == null) glow = new FlxSprite();
    glow.makeGraphic(size + 12, size + 12, col); glow.alpha = 0.12;
    glow.reset(cx - 6, cy - 6); coinGlowGroup.add(glow);

    if (isPowerup > 0) {
        var lbl = new FlxText(Std.int(cx - 20), Std.int(cy - 18), 60, isPowerup == 1 ? "x2" : "MAG", 11);
        lbl.setFormat(Paths.font(currentFont), 11, col, "center", 1, 0xFF000000);
        lbl.cameras = [uiCam]; coinLabelGroup.add(lbl);
    }
}

function collectCoin(c:FlxSprite) {
    var val = c.ID;
    if (val > 100) {
        if (val == 101) { hasDouble = true; doubleTimer = 8; statusEffect.text = "x2 FLOCKERS!"; statusEffect.color = 0xFFFF00FF; }
        else if (val == 102) { hasMagnet = true; magnetTimer = 6; statusEffect.text = "MAGNET!"; statusEffect.color = 0xFF00FFCC; }
        FlxG.camera.flash(0x22FF00FF, 0.15);
    } else {
        var earned = hasDouble ? val * 2 : val;
        localScore += earned;
        flappyCoins += earned;
        scoreText.text = localScore + " FLOCKERS";
        coinText.text = "" + flappyCoins; coinBounce = 1.2;
    }

    spawnCollectVFX(c.x, c.y, c.color);
    c.kill();
}

function spawnCollectVFX(x:Float, y:Float, col:Int) {
    for (i in 0...4) {
        var size = FlxG.random.int(6, 14);
        var p = new FlxSprite(x + FlxG.random.float(-4, 4), y + FlxG.random.float(-4, 4)).makeGraphic(size, size, col);
        p.alpha = 0.7; p.velocity.set(FlxG.random.float(-80, 80), FlxG.random.float(-100, 20));
        vfxGroup.add(p);
        FlxTween.tween(p, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.3, {onComplete: function(_) { p.destroy(); }});
    }
}

function showResults() {
    incrementStat("totalGamesPlayed", 1);
    incrementStat("treasureGrabGamesPlayed", 1);
    unlockAchievement("gen_welcome");
    if (localScore > getStat("treasureGrabHighScore")) saveStat("treasureGrabHighScore", localScore);
    if (localScore >= 100) unlockAchievement("tg_hunter");
    if (localScore >= 500) unlockAchievement("tg_rush");
    incrementStat("treasureGrabTotalCoins", localScore);
    if (getStat("treasureGrabTotalCoins") >= 10000) unlockAchievement("tg_hoarder");
    if (getStat("treasureGrabTotalCoins") >= 100000) unlockAchievement("tg_millionaire");
    FlxG.save.data.flappyCoins = flappyCoins; FlxG.save.flush();
    player.visible = false; playerEye.visible = false; playerBeak.visible = false;
    coinGroup.clear(); coinGlowGroup.clear(); coinLabelGroup.clear();

    if (FlxG.sound.music != null) FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.5);

    var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000);
    overlay.cameras = [uiCam]; add(overlay);
    FlxTween.color(overlay, 0.5, 0x00000000, 0xBB000000);

    var resultTitle = new FlxText(0, 0, FlxG.width, "TIME'S UP!", 64);
    resultTitle.setFormat(Paths.font(currentFont), 64, 0xFFFFD700, "center", 4, 0xFF000000);
    resultTitle.screenCenter(); resultTitle.y -= 80; resultTitle.cameras = [uiCam]; resultTitle.alpha = 0; resultTitle.scale.set(2.5, 2.5); add(resultTitle);
    FlxTween.tween(resultTitle, {alpha: 1}, 0.4, {ease: FlxEase.quadOut});
    FlxTween.tween(resultTitle.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.elasticOut});

    var resultBody = "YOU GRABBED " + localScore + " FLOCKERS!\n\n[ENTER] PLAY AGAIN   [ESC] BACK";
    if (isMultiplayer) {
        var scores:Array<Dynamic> = [{name: myNickname, score: localScore}];
        for (i in 0...activePlayers.length) {
            var nick = activePlayers[i]; var s = Reflect.field(playerScoreMap, nick);
            if (s == null) s = 0; scores.push({name: nick, score: s});
        }
        scores.sort(function(a:Dynamic, b:Dynamic):Int { return b.score - a.score; });
        resultBody = "";
        for (i in 0...scores.length) {
            var medal = i == 0 ? "1ST " : (i == 1 ? "2ND " : (i == 2 ? "3RD " : (i + 1) + "TH "));
            resultBody += medal + scores[i].name + " - " + scores[i].score + "F\n";
        }
        resultBody += "\n[ENTER] PLAY AGAIN   [ESC] BACK";
    }

    var resultInfo = new FlxText(0, 0, FlxG.width, resultBody, 22);
    resultInfo.setFormat(Paths.font(currentFont), 22, 0xFFCCCCCC, "center", 2, 0xFF000000);
    resultInfo.screenCenter(); resultInfo.y += 20; resultInfo.cameras = [uiCam]; resultInfo.alpha = 0; add(resultInfo);
    FlxTween.tween(resultInfo, {alpha: 1}, 0.5, {startDelay: 0.3});
}

function update(elapsed:Float) {
    titleGlow += elapsed * 2.5;
    if (titleText.visible) titleText.scale.set(Math.sin(titleGlow) * 0.06 + 1.0, Math.sin(titleGlow) * 0.06 + 1.0);
    if (subtitleText.visible) subtitleText.alpha = 0.5 + Math.sin(titleGlow * 1.3) * 0.3;

    if (coinBounce > 1.0) { coinBounce = FlxMath.lerp(coinBounce, 1.0, elapsed * 8); coinText.scale.set(coinBounce, coinBounce); }
    coinIconSpin += elapsed * 6; if (coinIconText != null) coinIconText.scale.set(Math.abs(Math.cos(coinIconSpin)) * 0.6 + 0.4, 1.0);

    if (player.visible) {
        playerEye.setPosition(player.x + 22, player.y + 5);
        playerBeak.setPosition(player.x + 28, player.y + 10);
    }

    for (i in 0...activePlayers.length) {
        var nick = activePlayers[i];
        var op:FlxSprite = Reflect.field(playerMap, nick);
        var tx = Reflect.field(targetXMap, nick); var ty = Reflect.field(targetYMap, nick);
        if (op != null && tx != null && ty != null) {
            op.x = FlxMath.lerp(op.x, tx, elapsed * 12); op.y = FlxMath.lerp(op.y, ty, elapsed * 12);
        }
        var opE:FlxSprite = Reflect.field(playerEyeMap, nick);
        var opB:FlxSprite = Reflect.field(playerBeakMap, nick);
        var opN:FlxText = Reflect.field(playerNickMap, nick);
        if (op != null && opE != null) opE.setPosition(op.x + 22, op.y + 5);
        if (op != null && opB != null) opB.setPosition(op.x + 28, op.y + 10);
        if (op != null && opN != null) opN.setPosition(op.x - 60, op.y - 18);
    }

    vfxGroup.forEachAlive(function(v:FlxSprite) { if (v.alpha <= 0.01) v.kill(); });

    if (FlxG.keys.justPressed.ESCAPE) {
        if (gameState == "PLAYING") { openSubState(new ModSubState("FlappyPause")); return; }
        else { netDisconnect(); FlxG.switchState(new ModState("CustomMainMenu")); return; }
    }

    switch(gameState) {
        case "MENU": updateMenu();
        case "ROOM_INPUT": updateRoomInput(elapsed);
        case "WAITING": updateWaiting(elapsed);
        case "LOBBY": updateLobby();
        case "PLAYING": updatePlaying(elapsed);
        case "GAMEOVER": if (FlxG.keys.justPressed.ENTER) FlxG.resetState();
    }
}

function updateMenu() {
    if (FlxG.keys.justPressed.ONE) goToState("PLAYING");
    if (FlxG.keys.justPressed.TWO) goToState("ROOM_INPUT");
}

function updateRoomInput(elapsed:Float) {
    handleTyping(4, elapsed);
    if (FlxG.keys.justPressed.ENTER && typedInput.length == 4) {
        activeRoomCode = typedInput; lobbyText.text = "JOINING...";
        netConnect(activeRoomCode, myNickname); isMultiplayer = true; gameState = "WAITING";
    }
}

function updateWaiting(elapsed:Float) {
    waitDotTimer += elapsed; if (waitDotTimer > 0.5) { waitDotTimer = 0; waitDots = (waitDots + 1) % 4; }
    var dots = ""; for (di in 0...waitDots) dots += "."; lobbyText.text = "WAITING" + dots;
}

function updateLobby() {
    if (isHost && FlxG.keys.justPressed.ENTER && lobbyPlayers.length >= 2) netSend("START_GAME:treasuregrab:0");
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU");
}

function updatePlaying(elapsed:Float) {
    if (countdownActive || !roundStarted) return;

    roundTimer -= elapsed;
    if (roundTimer <= 0) { roundTimer = 0; gameState = "GAMEOVER"; showResults(); return; }
    timerText.text = "" + Math.ceil(roundTimer);
    if (roundTimer <= 10) timerText.color = 0xFFFF4444; else timerText.color = 0xFFFFFFFF;

    var spd = playerSpeed * elapsed;
    if (FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A) player.x -= spd;
    if (FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D) player.x += spd;
    if (FlxG.keys.pressed.UP || FlxG.keys.pressed.W) player.y -= spd;
    if (FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S) player.y += spd;
    player.x = FlxMath.bound(player.x, arenaLeft, arenaRight - 34);
    player.y = FlxMath.bound(player.y, arenaTop, arenaBottom - 28);

    if (isMultiplayer) {
        var l = FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A;
        var r = FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D;
        var u = FlxG.keys.pressed.UP || FlxG.keys.pressed.W;
        var d = FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S;
        netSend("INPUT:LEFT:" + (l ? "1" : "0"));
        netSend("INPUT:RIGHT:" + (r ? "1" : "0"));
        netSend("INPUT:UP:" + (u ? "1" : "0"));
        netSend("INPUT:DOWN:" + (d ? "1" : "0"));
        if (serverState != null) {
            var myS:Dynamic = Reflect.field(serverState.p, myNickname);
            if (myS != null) {
                player.x = FlxMath.lerp(player.x, myS.x, 0.3);
                player.y = FlxMath.lerp(player.y, myS.y, 0.3);
                if (myS.score > localScore) {
                    var diff = myS.score - localScore;
                    localScore = myS.score;
                    flappyCoins += diff;
                    scoreText.text = localScore + " FLOCKERS";
                    coinText.text = "" + flappyCoins; coinBounce = 1.2;
                }
            }
        }
    }

    coinSpawnTimer += elapsed;
    var spawnInterval = coinSpawnRate;
    if (roundTimer < 20) spawnInterval = 0.2;
    if (roundTimer < 10) spawnInterval = 0.12;

    if (coinSpawnTimer >= spawnInterval) {
        coinSpawnTimer = 0;
        var roll = FlxG.random.float(0, 1);
        if (roll < 0.03) spawnCoin(false, 1);
        else if (roll < 0.06) spawnCoin(false, 2);
        else if (roll < 0.2) spawnCoin(true, 0);
        else spawnCoin(false, 0);
    }

    if (hasMagnet) {
        magnetTimer -= elapsed;
        if (magnetTimer <= 0) { hasMagnet = false; statusEffect.text = ""; }
        coinGroup.forEachAlive(function(c:FlxSprite) {
            var dx = (player.x + 17) - (c.x + c.width / 2);
            var dy = (player.y + 14) - (c.y + c.height / 2);
            var dist = Math.sqrt(dx * dx + dy * dy);
            if (dist < 120 && dist > 0) {
                var pull = 400 / dist;
                c.x += dx * pull * elapsed * 3;
                c.y += dy * pull * elapsed * 3;
            }
        });
    }

    if (hasDouble) {
        doubleTimer -= elapsed;
        if (doubleTimer <= 0) { hasDouble = false; statusEffect.text = ""; }
    }

    powerupTimer += elapsed;

    coinGroup.forEachAlive(function(c:FlxSprite) {
        var dx = Math.abs((player.x + 17) - (c.x + c.width / 2));
        var dy = Math.abs((player.y + 14) - (c.y + c.height / 2));
        if (dx < 24 && dy < 22) collectCoin(c);
    });

    coinGlowGroup.forEachAlive(function(g:FlxSprite) { g.alpha = 0.08 + Math.sin(powerupTimer * 5) * 0.06; });

    if (coinGroup.countLiving() > 80) {
        var killed = 0;
        coinGroup.forEachAlive(function(c:FlxSprite) { if (killed < 10 && c.ID <= 1) { c.kill(); killed++; } });
    }
}

function handleTyping(max:Int, elapsed:Float) {
    if (FlxG.keys.justPressed.BACKSPACE && typedInput.length > 0) typedInput = typedInput.substring(0, typedInput.length - 1);
    else if (typedInput.length < max) {
        var key = FlxG.keys.firstJustPressed(); var abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        if (key >= 65 && key <= 90) typedInput += abc.charAt(key - 65); else if (key >= 48 && key <= 57) typedInput += abc.charAt(key - 48 + 26);
    }
    typingCursorTimer += elapsed; if (typingCursorTimer >= 0.5) { typingCursorBlink = !typingCursorBlink; typingCursorTimer = 0; }
    typingText.text = "> " + typedInput + (typingCursorBlink ? "_" : "");
}

function netConnect(roomCode:String, nickname:String) {
    netDisconnect();
    try {
        connection = new Socket(); connection.connect(new Host(SERVER_IP), SERVER_PORT); netConnected = true; netBuffer = ""; connection.socket.setBlocking(false);
        new FlxTimer().start(0.3, function(t) {
            try { connection.write("JOIN_ROOM:" + roomCode + ":" + nickname + "\n"); startNetPollTimer(); } catch(e:Dynamic) {}
        });
    } catch(e:Dynamic) {
        netConnected = false; lobbyText.text = "CONNECTION FAILED!";
        new FlxTimer().start(2, function(t) { goToState("MENU"); });
    }
}

function netDisconnect() {
    if (pollTimer != null) { pollTimer.cancel(); pollTimer = null; }
    if (connection != null) { try { connection.destroy(); } catch(e:Dynamic) {} connection = null; }
    netConnected = false; netBuffer = "";
}

function netSend(msg:String) {
    if (!netConnected || connection == null) return;
    try { connection.write(msg + "\n"); } catch(e:Dynamic) {}
}

function netPoll() {
    if (!netConnected || connection == null) return;
    try {
        var sock = connection.socket; var c = 0;
        while (c < 20) { c++;
            try {
                var line = sock.input.readLine(); if (line == null) break;
                line = StringTools.trim(line); if (line.length == 0) continue;
                var sublines = line.split("\\n");
                for (si in 0...sublines.length) { var sub = StringTools.trim(sublines[si]); if (sub.length > 0) processNetLine(sub); }
            } catch(inner:Dynamic) { break; }
        }
    } catch(e:Dynamic) {}
}

function startNetPollTimer() {
    if (pollTimer != null) pollTimer.cancel();
    pollTimer = new FlxTimer().start(0.1, function(tmr) { netPoll(); }, 0);
}

function processNetLine(line:String) {
    var parts = line.split(":"); var cmd = parts[0]; parts.splice(0, 1); handleServerMessage(cmd, parts);
}

function handleServerMessage(cmd:String, args:Array<String>) {
    switch(cmd) {
        case "WAITING_FOR_HOST": gameState = "LOBBY"; addLobbyPlayer(myNickname); refreshLobbyUI();
        case "ROOM_FULL": lobbyText.text = "ROOM FULL!"; new FlxTimer().start(2, function(t) { goToState("MENU"); });
        case "START": countdownActive = false; goToState("PLAYING");
        case "GS":
            if (args.length >= 1) {
                try {
                    var gs = haxe.Json.parse(args.join(":"));
                    serverState = gs;
                    if (gs.timer != null) { roundTimer = gs.timer; }
                    var fields = Reflect.fields(gs.p);
                    for (fi in 0...fields.length) {
                        var nick = fields[fi];
                        var ps:Dynamic = Reflect.field(gs.p, nick);
                        if (nick != myNickname) {
                            Reflect.setField(targetXMap, nick, ps.x);
                            Reflect.setField(targetYMap, nick, ps.y);
                            Reflect.setField(playerScoreMap, nick, ps.score);
                            getOpponent(nick);
                        }
                    }
                    if (gs.ph == "gameover" && gameState == "PLAYING") { roundTimer = 0; gameState = "GAMEOVER"; showResults(); }
                } catch(e:Dynamic) {}
            }
        case "PLAYER_LIST":
            if (args.length > 0) {
                lobbyPlayers = [];
                for (pi in 0...args.length) { var pn = StringTools.trim(args[pi]); if (pn.length > 0) lobbyPlayers.push(pn); }
                if (lobbyPlayers.length > 0 && lobbyPlayers[0] == myNickname) isHost = true; else isHost = false;
                if (gameState == "WAITING") { gameState = "LOBBY"; refreshLobbyUI(); }
                else if (gameState == "LOBBY") refreshLobbyUI();
            }
        case "CHAT": {}
    }
}

function getOpponent(nick:String):FlxSprite {
    if (nick == myNickname) return null;
    if (activePlayers.indexOf(nick) == -1) {
        activePlayers.push(nick);
        var col = playerColors[activePlayers.length % playerColors.length];
        var op = new FlxSprite(FlxG.width / 2, FlxG.height / 2).makeGraphic(34, 28, col); op.alpha = 0.5; playerGroup.add(op);
        var opE = new FlxSprite(0, 0).makeGraphic(8, 8, 0xFFFFFFFF); opE.alpha = 0.5; playerGroup.add(opE); Reflect.setField(playerEyeMap, nick, opE);
        var opB = new FlxSprite(0, 0).makeGraphic(12, 7, 0xFFFF8800); opB.alpha = 0.5; playerGroup.add(opB); Reflect.setField(playerBeakMap, nick, opB);
        var opTag = new FlxText(0, 0, 150, nick, 11); opTag.setFormat(Paths.font(currentFont), 11, col, "center", 1, 0xFF000000); opTag.cameras = [uiCam]; opTag.alpha = 0.6; nickTagGroup.add(opTag); Reflect.setField(playerNickMap, nick, opTag);
        Reflect.setField(playerMap, nick, op); Reflect.setField(targetXMap, nick, FlxG.width / 2); Reflect.setField(targetYMap, nick, FlxG.height / 2); Reflect.setField(playerScoreMap, nick, 0);
    }
    return Reflect.field(playerMap, nick);
}

function addLobbyPlayer(nick:String) { if (nick.length == 0) return; for (li in 0...lobbyPlayers.length) if (lobbyPlayers[li] == nick) return; lobbyPlayers.push(nick); }

function refreshLobbyUI() {
    lobbySlotGroup.clear(); lobbyBgGroup.clear(); titleText.visible = false; subtitleText.visible = false; typingText.visible = false; typingBg.visible = false;
    lobbyRoomText.visible = true; lobbyRoomText.text = "ROOM: " + activeRoomCode + "   |   TREASURE GRAB"; lobbyRoomText.y = 20;

    var countText = new FlxText(0, 50, FlxG.width, lobbyPlayers.length + " / 6 PLAYERS", 18);
    countText.setFormat(Paths.font(currentFont), 18, 0xFF88CCFF, "center", 1, 0xFF000000); countText.cameras = [uiCam]; lobbySlotGroup.add(countText);

    var startY = FlxG.height * 0.22; var slotH = 56;
    for (si in 0...6) {
        var slotY = startY + (si * slotH); var hasPlayer = si < lobbyPlayers.length;
        var nick = hasPlayer ? lobbyPlayers[si] : "WAITING..."; var col = hasPlayer ? playerColors[si % playerColors.length] : 0xFF333333; var isMe = hasPlayer && lobbyPlayers[si] == myNickname;
        var cardBg = new FlxSprite(Std.int(FlxG.width * 0.12), Std.int(slotY)).makeGraphic(Std.int(FlxG.width * 0.76), Std.int(slotH - 6), hasPlayer ? 0xFF1A1A2E : 0xFF0D0D18);
        cardBg.alpha = hasPlayer ? 0.65 : 0.3; cardBg.cameras = [uiCam]; lobbyBgGroup.add(cardBg);
        if (hasPlayer) { var stripe = new FlxSprite(Std.int(FlxG.width * 0.12), Std.int(slotY)).makeGraphic(5, Std.int(slotH - 6), col); stripe.cameras = [uiCam]; lobbyBgGroup.add(stripe); }
        var nameStr = hasPlayer ? nick.toUpperCase() : "---"; if (isMe) nameStr = nameStr + "  (YOU)";
        var nameText = new FlxText(Std.int(FlxG.width * 0.2), slotY + 14, Std.int(FlxG.width * 0.6), nameStr, 24);
        nameText.setFormat(Paths.font(currentFont), 24, isMe ? 0xFFFFFFFF : col, "left", 2, 0xFF000000); nameText.cameras = [uiCam]; lobbySlotGroup.add(nameText);
    }

    if (lobbyPlayers.length < 2) lobbyText.text = "[ESC] LEAVE   |   WAITING FOR PLAYERS...";
    else lobbyText.text = (isHost ? "[ENTER] START   |   " : "") + "[ESC] LEAVE";
}

function getStat(key:String):Int {
    var stats:Dynamic = FlxG.save.data.flappyStats;
    if (stats == null) return 0;
    var val:Dynamic = Reflect.field(stats, key);
    if (val == null) return 0;
    return val;
}
function saveStat(key:String, value:Int) {
    var stats:Dynamic = FlxG.save.data.flappyStats;
    if (stats == null) { stats = {}; FlxG.save.data.flappyStats = stats; }
    Reflect.setField(stats, key, value);
    FlxG.save.flush();
}
function incrementStat(key:String, amount:Int) { saveStat(key, getStat(key) + amount); }
function hasAchievement(id:String):Bool {
    var achs:Array<String> = FlxG.save.data.flappyAchievements;
    if (achs == null) return false;
    for (a in achs) if (a == id) return true;
    return false;
}
function unlockAchievement(id:String) {
    if (hasAchievement(id)) return;
    var achs:Array<String> = FlxG.save.data.flappyAchievements;
    if (achs == null) { achs = []; FlxG.save.data.flappyAchievements = achs; }
    achs.push(id);
    FlxG.save.flush();
    showAchievementPopup(id);
}
function showAchievementPopup(id:String) {
    var popup = new FlxText(0, 80, FlxG.width, "ACHIEVEMENT UNLOCKED!\n" + id.toUpperCase(), 20);
    popup.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFFD700, "center", 2, 0xFF000000);
    popup.cameras = [uiCam]; popup.alpha = 0; add(popup);
    FlxTween.tween(popup, {alpha: 1}, 0.3, {onComplete: function(t) {
        FlxTween.tween(popup, {alpha: 0}, 0.5, {startDelay: 2.0, onComplete: function(t2) { popup.destroy(); }});
    }});
}

function destroy() { netDisconnect(); }
