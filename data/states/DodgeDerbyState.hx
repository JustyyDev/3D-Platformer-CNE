import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.group.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.ModSubState;
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
var pollTimer:FlxTimer;
var typedInput:String = "";
var activeRoomCode:String = "";
var isHost:Bool = false;
var lobbyPlayers:Array<String> = [];
var activePlayers:Array<String> = [];
var playerColors:Array<Int> = [0xFFFFEE00, 0xFF00CCFF, 0xFFFF6699, 0xFF66FF66, 0xFFFF9933, 0xFFCC66FF];

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

var player:FlxSprite;
var playerEye:FlxSprite;
var playerBeak:FlxSprite;
var playerSpeed:Float = 280;
var iAmDead:Bool = false;
var hasShield:Bool = false;
var isShrunk:Bool = false;
var isPhased:Bool = false;

var projectiles:FlxTypedGroup<FlxSprite>;
var powerups:FlxTypedGroup<FlxSprite>;
var powerupGlowGroup:FlxTypedGroup<FlxSprite>;
var vfxGroup:FlxTypedGroup<FlxSprite>;
var playerGroup:FlxTypedGroup<FlxSprite>;
var nickTagGroup:FlxTypedGroup<FlxText>;
var playerMap:Dynamic = {};
var playerEyeMap:Dynamic = {};
var playerBeakMap:Dynamic = {};
var playerNickMap:Dynamic = {};
var targetXMap:Dynamic = {};
var targetYMap:Dynamic = {};
var deadMap:Dynamic = {};

var wave:Int = 0;
var waveTimer:Float = 0;
var waveInterval:Float = 6;
var surviveTimer:Float = 0;
var waveText:FlxText;
var timerText:FlxText;
var statusText:FlxText;
var roundActive:Bool = false;
var countdownActive:Bool = false;
var netSendAccum:Float = 0;
var powerupSpawnTimer:Float = 0;
var pulseTimer:Float = 0;
var serverState:Dynamic = null;

var arenaLeft:Float = 40;
var arenaRight:Float = 0;
var arenaTop:Float = 80;
var arenaBottom:Float = 0;

function create() {
    if (FlxG.save.data.flappyNickname != null) myNickname = FlxG.save.data.flappyNickname;
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;
    if (FlxG.save.data.flappyCoins != null) flappyCoins = FlxG.save.data.flappyCoins;

    arenaRight = FlxG.width - 40;
    arenaBottom = FlxG.height - 50;

    FlxG.camera.bgColor = 0xFF06061A;
    uiCam = new FlxCamera(); uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    var floor = new FlxSprite(arenaLeft, arenaTop).makeGraphic(Std.int(arenaRight - arenaLeft), Std.int(arenaBottom - arenaTop), 0xFF0A0A22);
    floor.alpha = 0.5; add(floor);

    var bT = new FlxSprite(arenaLeft - 2, arenaTop - 2).makeGraphic(Std.int(arenaRight - arenaLeft + 4), 2, 0xFF00CCFF);
    var bB = new FlxSprite(arenaLeft - 2, Std.int(arenaBottom)).makeGraphic(Std.int(arenaRight - arenaLeft + 4), 2, 0xFF00CCFF);
    var bL = new FlxSprite(arenaLeft - 2, arenaTop - 2).makeGraphic(2, Std.int(arenaBottom - arenaTop + 4), 0xFF00CCFF);
    var bR = new FlxSprite(Std.int(arenaRight), arenaTop - 2).makeGraphic(2, Std.int(arenaBottom - arenaTop + 4), 0xFF00CCFF);
    bT.alpha = 0.4; bB.alpha = 0.4; bL.alpha = 0.4; bR.alpha = 0.4;
    add(bT); add(bB); add(bL); add(bR);

    projectiles = new FlxTypedGroup(); add(projectiles);
    powerupGlowGroup = new FlxTypedGroup(); add(powerupGlowGroup);
    powerups = new FlxTypedGroup(); add(powerups);
    vfxGroup = new FlxTypedGroup(); add(vfxGroup);
    playerGroup = new FlxTypedGroup(); add(playerGroup);
    nickTagGroup = new FlxTypedGroup(); add(nickTagGroup);

    var skinCol = 0xFFFFEE00;
    if (FlxG.save.data.flappyEquippedSkinId != null) {
        var skins:Array<Dynamic> = [
            {id: "default", color: 0xFFFFEE00}, {id: "ice", color: 0xFF00CCFF}, {id: "bubblegum", color: 0xFFFF6699},
            {id: "neon", color: 0xFF66FF66}, {id: "sunset", color: 0xFFFF9933}, {id: "crimson", color: 0xFFFF0000},
            {id: "golden", color: 0xFFFFD700}, {id: "shadow", color: 0xFF333333}, {id: "royal", color: 0xFF4169E1}
        ];
        for (s in skins) if (s.id == FlxG.save.data.flappyEquippedSkinId) skinCol = s.color;
    }

    player = new FlxSprite(FlxG.width / 2, FlxG.height / 2).makeGraphic(28, 24, skinCol);
    player.antialiasing = true; add(player);
    playerEye = new FlxSprite(0, 0).makeGraphic(8, 8, 0xFFFFFFFF); add(playerEye);
    playerBeak = new FlxSprite(0, 0).makeGraphic(10, 6, 0xFFFF8800); add(playerBeak);

    lobbySlotGroup = new FlxTypedGroup(); add(lobbySlotGroup);
    lobbyBgGroup = new FlxTypedGroup(); add(lobbyBgGroup);

    setupUI();
    goToState("MENU");
}

function setupUI() {
    titleText = makeText(0, 40, FlxG.width, "DODGE DERBY", 64, 0xFF00CCFF);
    subtitleText = makeText(0, 110, FlxG.width, "SURVIVE THE STORM!", 20, 0xFF4488FF); subtitleText.alpha = 0.7;
    lobbyText = makeText(0, FlxG.height * 0.78, FlxG.width, "", 22, 0xFFFFEE00);
    typingBg = new FlxSprite(FlxG.width * 0.2, FlxG.height * 0.81).makeGraphic(Std.int(FlxG.width * 0.6), 48, 0xFF1A1A2E); typingBg.alpha = 0.7; typingBg.cameras = [uiCam]; add(typingBg); typingBg.visible = false;
    typingText = makeText(0, FlxG.height * 0.82, FlxG.width, "", 34, 0xFFFFFFFF);
    waveText = makeText(0, 10, FlxG.width, "WAVE 1", 32, 0xFF00CCFF);
    timerText = makeText(0, 46, FlxG.width, "0.0s", 20, 0xFFAAAAAA);
    statusText = makeText(0, FlxG.height - 36, FlxG.width, "", 16, 0xFF00FF88);
    coinIconText = makeText(FlxG.width - 240, 10, 30, "F", 20, 0xFFFFD700);
    coinText = makeText(FlxG.width - 210, 10, 190, "" + flappyCoins, 20, 0xFFFFD700); coinText.alignment = "right";
    lobbyRoomText = makeText(0, FlxG.height * 0.12, FlxG.width, "", 22, 0xFF88CCFF); lobbyRoomText.visible = false;
}

function makeText(x:Float, y:Float, w:Float, text:String, size:Int, color:Int):FlxText {
    var t = new FlxText(x, y, w, text, size);
    t.setFormat(Paths.font(currentFont), size, color, "center", 2, 0xFF000000);
    t.cameras = [uiCam]; add(t); return t;
}

function goToState(s:String) {
    gameState = s; typedInput = ""; typingText.text = ""; lobbySlotGroup.clear(); lobbyBgGroup.clear(); lobbyRoomText.visible = false;
    if (s == "MENU") { netDisconnect(); isMultiplayer = false; lobbyPlayers = []; activePlayers = []; resetData(); }
    titleText.visible = (s == "MENU" || s == "ROOM_INPUT"); subtitleText.visible = (s == "MENU");
    lobbyText.visible = true; typingText.visible = (s == "ROOM_INPUT"); typingBg.visible = typingText.visible;
    waveText.visible = (s == "PLAYING" || s == "GAMEOVER"); timerText.visible = (s == "PLAYING");
    statusText.visible = (s == "PLAYING"); statusText.text = "";
    coinText.visible = true; coinIconText.visible = true;
    player.visible = (s == "PLAYING"); playerEye.visible = player.visible; playerBeak.visible = player.visible;

    switch(s) {
        case "MENU": lobbyText.text = "[1] SOLO   [2] MULTI   [ESC] BACK"; FlxG.sound.playMusic(Paths.music("flappy/mainTheme"), 0.8, true);
        case "ROOM_INPUT": lobbyText.text = "ENTER 4-LETTER ROOM CODE";
        case "PLAYING": startRound();
    }
}

function resetData() {
    playerMap = {}; playerEyeMap = {}; playerBeakMap = {}; playerNickMap = {};
    targetXMap = {}; targetYMap = {}; deadMap = {};
}

function startRound() {
    iAmDead = false; wave = 0; waveTimer = 0; surviveTimer = 0; roundActive = false; countdownActive = true;
    hasShield = false; isShrunk = false; isPhased = false; powerupSpawnTimer = 0;
    projectiles.clear(); powerups.clear(); powerupGlowGroup.clear(); vfxGroup.clear();
    player.x = FlxG.width / 2 - 14; player.y = FlxG.height / 2 - 12;
    player.scale.set(1, 1); player.alpha = 1;
    titleText.visible = false; subtitleText.visible = false; lobbyText.visible = false; typingText.visible = false; typingBg.visible = false;

    FlxG.sound.playMusic(Paths.music("flappy/racingTillDawn"), 0, true);
    FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.5);

    var count = 3;
    var ct = new FlxText(0, 0, FlxG.width, "3", 140);
    ct.setFormat(Paths.font(currentFont), 140, 0xFFFFFFFF, "center", 6, 0xFF000000);
    ct.screenCenter(); ct.cameras = [uiCam]; add(ct);

    new FlxTimer().start(1, function(tmr) {
        count--;
        if (count <= 0) {
            tmr.cancel(); ct.text = "DODGE!"; ct.color = 0xFF00CCFF; ct.scale.set(1.5, 1.5);
            FlxTween.tween(ct, {alpha: 0}, 0.5, {ease: FlxEase.quadIn, onComplete: function(_) { ct.destroy(); }});
            FlxG.camera.flash(0x33FFFFFF, 0.3); countdownActive = false; roundActive = true;
            spawnWave();
        } else {
            ct.text = Std.string(count); ct.scale.set(1.5, 1.5);
            FlxTween.tween(ct.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.elasticOut});
            ct.color = [0xFFFFEE00, 0xFFFF9900, 0xFFFF4444][3 - count];
        }
    }, 0);
}

function spawnWave() {
    wave++;
    waveTimer = 0;
    waveText.text = "WAVE " + wave; waveText.scale.set(1.5, 1.5);
    FlxTween.tween(waveText.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.elasticOut});
    FlxG.camera.flash(0x11FF0000, 0.2);

    var baseCount = 3 + wave * 2;
    var baseSpeed = 100 + wave * 20;

    for (i in 0...baseCount) {
        var side = FlxG.random.int(0, 3);
        var sx:Float = 0; var sy:Float = 0; var vx:Float = 0; var vy:Float = 0;
        var size = FlxG.random.int(10, 18 + wave);

        if (side == 0) { sx = FlxG.random.float(arenaLeft, arenaRight); sy = arenaTop - 20; vx = FlxG.random.float(-60, 60); vy = FlxG.random.float(baseSpeed * 0.5, baseSpeed); }
        else if (side == 1) { sx = FlxG.random.float(arenaLeft, arenaRight); sy = arenaBottom + 20; vx = FlxG.random.float(-60, 60); vy = -FlxG.random.float(baseSpeed * 0.5, baseSpeed); }
        else if (side == 2) { sx = arenaLeft - 20; sy = FlxG.random.float(arenaTop, arenaBottom); vx = FlxG.random.float(baseSpeed * 0.5, baseSpeed); vy = FlxG.random.float(-60, 60); }
        else { sx = arenaRight + 20; sy = FlxG.random.float(arenaTop, arenaBottom); vx = -FlxG.random.float(baseSpeed * 0.5, baseSpeed); vy = FlxG.random.float(-60, 60); }

        var col = wave <= 3 ? 0xFFFF4444 : (wave <= 6 ? 0xFFFF8800 : 0xFFFF00FF);
        var p = projectiles.recycle(FlxSprite);
        if (p == null) p = new FlxSprite();
        p.makeGraphic(size, size, col); p.reset(sx, sy); p.velocity.set(vx, vy); p.ID = 0;
        projectiles.add(p);
    }

    if (wave >= 3 && wave % 2 == 0) {
        for (i in 0...Std.int(wave / 2)) {
            var angle = FlxG.random.float(0, Math.PI * 2);
            var spd = baseSpeed * 1.2;
            var bx = FlxG.width / 2 + Math.cos(angle) * 300;
            var by = FlxG.height / 2 + Math.sin(angle) * 300;
            var bp = projectiles.recycle(FlxSprite);
            if (bp == null) bp = new FlxSprite();
            bp.makeGraphic(24, 24, 0xFFFF00FF); bp.reset(bx, by);
            var tdx = (player.x + 14) - bx; var tdy = (player.y + 12) - by;
            var tdist = Math.sqrt(tdx * tdx + tdy * tdy);
            if (tdist > 0) { bp.velocity.set((tdx / tdist) * spd, (tdy / tdist) * spd); }
            bp.ID = 1;
            projectiles.add(bp);
        }
    }
}

function spawnPowerup() {
    var px = FlxG.random.float(arenaLeft + 30, arenaRight - 30);
    var py = FlxG.random.float(arenaTop + 30, arenaBottom - 30);
    var type = FlxG.random.int(0, 2);
    var cols = [0xFF00FF88, 0xFF88CCFF, 0xFFFFCC00];
    var labels = ["SH", "SM", "PH"];

    var pu = powerups.recycle(FlxSprite);
    if (pu == null) pu = new FlxSprite();
    pu.makeGraphic(20, 20, cols[type]); pu.reset(px, py); pu.ID = type; pu.alpha = 0;
    powerups.add(pu);
    FlxTween.tween(pu, {alpha: 1}, 0.3);

    var glow = powerupGlowGroup.recycle(FlxSprite);
    if (glow == null) glow = new FlxSprite();
    glow.makeGraphic(32, 32, cols[type]); glow.alpha = 0.12; glow.reset(px - 6, py - 6);
    powerupGlowGroup.add(glow);
}

function collectPowerup(pu:FlxSprite) {
    var type = pu.ID;
    if (type == 0) { hasShield = true; statusText.text = "SHIELD ACTIVE!"; statusText.color = 0xFF00FF88; new FlxTimer().start(5, function(t) { hasShield = false; statusText.text = ""; }); }
    else if (type == 1) { isShrunk = true; player.scale.set(0.5, 0.5); statusText.text = "SHRUNK!"; statusText.color = 0xFF88CCFF; new FlxTimer().start(6, function(t) { isShrunk = false; player.scale.set(1, 1); statusText.text = ""; }); }
    else if (type == 2) { isPhased = true; player.alpha = 0.3; statusText.text = "PHASED!"; statusText.color = 0xFFFFCC00; new FlxTimer().start(3, function(t) { isPhased = false; player.alpha = 1; statusText.text = ""; }); }
    pu.kill(); FlxG.camera.flash(0x1100FF00, 0.1);
    spawnCollectVFX(pu.x, pu.y, pu.color);
}

function spawnCollectVFX(x:Float, y:Float, col:Int) {
    for (i in 0...4) {
        var s = FlxG.random.int(6, 14);
        var p = new FlxSprite(x + FlxG.random.float(-4, 4), y + FlxG.random.float(-4, 4)).makeGraphic(s, s, col);
        p.alpha = 0.6; p.velocity.set(FlxG.random.float(-80, 80), FlxG.random.float(-80, 80));
        vfxGroup.add(p);
        FlxTween.tween(p, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.3, {onComplete: function(_) { p.destroy(); }});
    }
}

function killPlayer() {
    if (iAmDead) return;
    if (hasShield) { hasShield = false; statusText.text = "SHIELD BROKE!"; FlxG.camera.flash(0x2200FF00, 0.2); return; }
    if (isPhased) return;
    iAmDead = true; roundActive = false;
    player.color = 0xFF444444;
    FlxG.camera.shake(0.03, 0.4); FlxG.camera.flash(0x66FF0000, 0.3);

    for (i in 0...12) {
        var s = FlxG.random.int(6, 22);
        var shard = new FlxSprite(player.x + FlxG.random.float(-4, 24), player.y + FlxG.random.float(-4, 18)).makeGraphic(s, s, FlxG.random.bool(50) ? 0xFFFF4444 : 0xFFFFAA00);
        shard.alpha = 0.9; shard.velocity.set(FlxG.random.float(-200, 200), FlxG.random.float(-250, 100));
        vfxGroup.add(shard);
        FlxTween.tween(shard, {alpha: 0, "scale.x": 0.05, "scale.y": 0.05}, 0.5, {onComplete: function(_) { shard.destroy(); }});
    }

    var reward = 5 + wave * 2;
    flappyCoins += reward; FlxG.save.data.flappyCoins = flappyCoins; FlxG.save.flush();
    coinText.text = "" + flappyCoins; coinBounce = 1.3;

    if (isMultiplayer) checkMultiEnd();
    else showGameOver(reward);
}

function checkMultiEnd() {
    var alive = 0;
    if (!iAmDead) alive++;
    for (i in 0...activePlayers.length) if (!Reflect.field(deadMap, activePlayers[i])) alive++;
    if (alive <= 1) {
        var won = !iAmDead;
        var reward = won ? 25 + wave * 3 : 5 + wave * 2;
        flappyCoins += (won ? 15 : 0); FlxG.save.data.flappyCoins = flappyCoins; FlxG.save.flush();
        showGameOver(reward);
    }
}

function showGameOver(reward:Int) {
    gameState = "GAMEOVER";
    incrementStat("totalGamesPlayed", 1);
    incrementStat("totalDeaths", 1);
    incrementStat("dodgeDerbyGamesPlayed", 1);
    if (getStat("dodgeDerbyGamesPlayed") >= 1) unlockAchievement("gen_welcome");
    if (wave > getStat("dodgeDerbyHighWave")) saveStat("dodgeDerbyHighWave", wave);
    if (wave >= 10) unlockAchievement("dd_dodge");
    if (wave >= 25) unlockAchievement("dd_matrix");
    if (wave >= 50) unlockAchievement("dd_invincible");
    if (wave >= 100) unlockAchievement("dd_legend");
    if (FlxG.sound.music != null) FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.5);

    var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000);
    overlay.cameras = [uiCam]; add(overlay);
    FlxTween.color(overlay, 0.5, 0x00000000, 0xBB000000);

    var result = "SURVIVED " + wave + " WAVES!";
    var rt = new FlxText(0, 0, FlxG.width, result, 52);
    rt.setFormat(Paths.font(currentFont), 52, 0xFF00CCFF, "center", 4, 0xFF000000);
    rt.screenCenter(); rt.y -= 60; rt.cameras = [uiCam]; rt.alpha = 0; rt.scale.set(2.5, 2.5); add(rt);
    FlxTween.tween(rt, {alpha: 1}, 0.4); FlxTween.tween(rt.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.elasticOut});

    var timeStr = Std.string(Math.floor(surviveTimer * 10) / 10);
    var info = new FlxText(0, 0, FlxG.width, timeStr + " SECONDS   |   +" + reward + " FLOCKERS\n\n[ENTER] RETRY   [ESC] BACK", 22);
    info.setFormat(Paths.font(currentFont), 22, 0xFFCCCCCC, "center", 2, 0xFF000000);
    info.screenCenter(); info.y += 20; info.cameras = [uiCam]; info.alpha = 0; add(info);
    FlxTween.tween(info, {alpha: 1}, 0.5, {startDelay: 0.3});
}

function update(elapsed:Float) {
    titleGlow += elapsed * 2.5;
    if (titleText.visible) titleText.scale.set(Math.sin(titleGlow) * 0.06 + 1.0, Math.sin(titleGlow) * 0.06 + 1.0);
    if (subtitleText.visible) subtitleText.alpha = 0.5 + Math.sin(titleGlow * 1.3) * 0.3;
    if (coinBounce > 1.0) { coinBounce = FlxMath.lerp(coinBounce, 1.0, elapsed * 8); coinText.scale.set(coinBounce, coinBounce); }
    coinIconSpin += elapsed * 6; if (coinIconText != null) coinIconText.scale.set(Math.abs(Math.cos(coinIconSpin)) * 0.6 + 0.4, 1.0);

    if (player.visible) { playerEye.setPosition(player.x + 18, player.y + 4); playerBeak.setPosition(player.x + 22, player.y + 8); }

    for (i in 0...activePlayers.length) {
        var nick = activePlayers[i]; var op:FlxSprite = Reflect.field(playerMap, nick); if (op == null) continue;
        var tx = Reflect.field(targetXMap, nick); var ty = Reflect.field(targetYMap, nick);
        if (tx != null && ty != null) { op.x = FlxMath.lerp(op.x, tx, elapsed * 12); op.y = FlxMath.lerp(op.y, ty, elapsed * 12); }
        var opE:FlxSprite = Reflect.field(playerEyeMap, nick); var opB:FlxSprite = Reflect.field(playerBeakMap, nick); var opN:FlxText = Reflect.field(playerNickMap, nick);
        if (opE != null) opE.setPosition(op.x + 18, op.y + 4); if (opB != null) opB.setPosition(op.x + 22, op.y + 8); if (opN != null) opN.setPosition(op.x - 60, op.y - 16);
    }

    vfxGroup.forEachAlive(function(v:FlxSprite) { if (v.alpha <= 0.01) v.kill(); });

    pulseTimer += elapsed;
    powerupGlowGroup.forEachAlive(function(g:FlxSprite) { g.alpha = 0.08 + Math.sin(pulseTimer * 5) * 0.06; });

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
    if (isHost && FlxG.keys.justPressed.ENTER && lobbyPlayers.length >= 2) netSend("START_GAME:dodgederby:0");
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU");
}

function updatePlaying(elapsed:Float) {
    if (countdownActive || !roundActive) return;

    surviveTimer += elapsed;
    timerText.text = Std.string(Math.floor(surviveTimer * 10) / 10) + "s";

    if (!iAmDead) {
        var spd = playerSpeed * elapsed;
        if (FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A) player.x -= spd;
        if (FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D) player.x += spd;
        if (FlxG.keys.pressed.UP || FlxG.keys.pressed.W) player.y -= spd;
        if (FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S) player.y += spd;
        player.x = FlxMath.bound(player.x, arenaLeft, arenaRight - 28);
        player.y = FlxMath.bound(player.y, arenaTop, arenaBottom - 24);

        if (isMultiplayer) {
            netSendAccum += elapsed;
            if (netSendAccum >= 0.05) {
                netSendAccum = 0;
                var l = FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A;
                var r = FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D;
                var u = FlxG.keys.pressed.UP || FlxG.keys.pressed.W;
                var d = FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S;
                netSend("INPUT:LEFT:" + (l ? "1" : "0"));
                netSend("INPUT:RIGHT:" + (r ? "1" : "0"));
                netSend("INPUT:UP:" + (u ? "1" : "0"));
                netSend("INPUT:DOWN:" + (d ? "1" : "0"));
            }
            if (serverState != null) {
                var myS:Dynamic = Reflect.field(serverState.p, myNickname);
                if (myS != null) {
                    player.x = FlxMath.lerp(player.x, myS.x, 0.3);
                    player.y = FlxMath.lerp(player.y, myS.y, 0.3);
                    if (!myS.alive && !iAmDead) killPlayer();
                }
            }
        }
    }

    waveTimer += elapsed;
    var nextWaveAt = Math.max(3, waveInterval - wave * 0.3);
    if (waveTimer >= nextWaveAt) spawnWave();

    powerupSpawnTimer += elapsed;
    if (powerupSpawnTimer >= 8) { powerupSpawnTimer = 0; spawnPowerup(); }

    projectiles.forEachAlive(function(p:FlxSprite) {
        if (p.ID == 0) {
            if (p.x < arenaLeft - 30) p.velocity.x = Math.abs(p.velocity.x);
            if (p.x > arenaRight + 10) p.velocity.x = -Math.abs(p.velocity.x);
            if (p.y < arenaTop - 30) p.velocity.y = Math.abs(p.velocity.y);
            if (p.y > arenaBottom + 10) p.velocity.y = -Math.abs(p.velocity.y);
        } else {
            if (p.x < arenaLeft - 80 || p.x > arenaRight + 80 || p.y < arenaTop - 80 || p.y > arenaBottom + 80) p.kill();
        }

        if (!iAmDead) {
            var hitW = isShrunk ? 10 : 20; var hitH = isShrunk ? 8 : 16;
            var dx = Math.abs((player.x + 14) - (p.x + p.width / 2));
            var dy = Math.abs((player.y + 12) - (p.y + p.height / 2));
            if (dx < hitW && dy < hitH) killPlayer();
        }
    });

    powerups.forEachAlive(function(pu:FlxSprite) {
        if (!iAmDead) {
            var dx = Math.abs((player.x + 14) - (pu.x + 10));
            var dy = Math.abs((player.y + 12) - (pu.y + 10));
            if (dx < 20 && dy < 18) collectPowerup(pu);
        }
    });
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
        connection = new Socket(); connection.connect(new Host(SERVER_IP), SERVER_PORT); netConnected = true; connection.socket.setBlocking(false);
        new FlxTimer().start(0.3, function(t) { try { connection.write("JOIN_ROOM:" + roomCode + ":" + nickname + "\n"); startNetPollTimer(); } catch(e:Dynamic) {} });
    } catch(e:Dynamic) { netConnected = false; lobbyText.text = "CONNECTION FAILED!"; new FlxTimer().start(2, function(t) { goToState("MENU"); }); }
}

function netDisconnect() { if (pollTimer != null) { pollTimer.cancel(); pollTimer = null; } if (connection != null) { try { connection.destroy(); } catch(e:Dynamic) {} connection = null; } netConnected = false; }
function netSend(msg:String) { if (!netConnected || connection == null) return; try { connection.write(msg + "\n"); } catch(e:Dynamic) {} }

function netPoll() {
    if (!netConnected || connection == null) return;
    try { var sock = connection.socket; var c = 0;
        while (c < 20) { c++; try { var line = sock.input.readLine(); if (line == null) break; line = StringTools.trim(line); if (line.length == 0) continue;
            var sublines = line.split("\\n"); for (si in 0...sublines.length) { var sub = StringTools.trim(sublines[si]); if (sub.length > 0) processNetLine(sub); }
        } catch(inner:Dynamic) { break; } } } catch(e:Dynamic) {}
}

function startNetPollTimer() { if (pollTimer != null) pollTimer.cancel(); pollTimer = new FlxTimer().start(0.1, function(tmr) { netPoll(); }, 0); }
function processNetLine(line:String) { var parts = line.split(":"); var cmd = parts[0]; parts.splice(0, 1); handleServerMessage(cmd, parts); }

function handleServerMessage(cmd:String, args:Array<String>) {
    switch(cmd) {
        case "WAITING_FOR_HOST": gameState = "LOBBY"; addLobbyPlayer(myNickname); refreshLobbyUI();
        case "ROOM_FULL": lobbyText.text = "ROOM FULL!"; new FlxTimer().start(2, function(t) { goToState("MENU"); });
        case "START": goToState("PLAYING");
        case "GS":
            if (args.length >= 1) {
                try {
                    var gs = haxe.Json.parse(args.join(":"));
                    serverState = gs;
                    if (gs.wave != null) { wave = gs.wave; waveText.text = "WAVE " + wave; }
                    var fields = Reflect.fields(gs.p);
                    for (fi in 0...fields.length) {
                        var nick = fields[fi];
                        var ps:Dynamic = Reflect.field(gs.p, nick);
                        if (nick != myNickname) {
                            Reflect.setField(targetXMap, nick, ps.x);
                            Reflect.setField(targetYMap, nick, ps.y);
                            getOpponent(nick);
                            if (!ps.alive && !Reflect.field(deadMap, nick)) {
                                Reflect.setField(deadMap, nick, true);
                                var op = Reflect.field(playerMap, nick);
                                if (op != null) op.color = 0xFF444444;
                                checkMultiEnd();
                            }
                        }
                    }
                    if (gs.ph == "gameover" && gameState == "PLAYING") checkMultiEnd();
                } catch(e:Dynamic) {}
            }
        case "PLAYER_LIST":
            if (args.length > 0) { lobbyPlayers = [];
                for (pi in 0...args.length) { var pn = StringTools.trim(args[pi]); if (pn.length > 0) lobbyPlayers.push(pn); }
                if (lobbyPlayers.length > 0 && lobbyPlayers[0] == myNickname) isHost = true; else isHost = false;
                if (gameState == "WAITING") { gameState = "LOBBY"; refreshLobbyUI(); } else if (gameState == "LOBBY") refreshLobbyUI();
            }
    }
}

function getOpponent(nick:String):FlxSprite {
    if (nick == myNickname) return null;
    if (activePlayers.indexOf(nick) == -1) {
        activePlayers.push(nick);
        var col = playerColors[activePlayers.length % playerColors.length];
        var op = new FlxSprite(FlxG.width / 2, FlxG.height / 2).makeGraphic(28, 24, col); op.alpha = 0.5; playerGroup.add(op);
        var opE = new FlxSprite(0,0).makeGraphic(8,8,0xFFFFFFFF); opE.alpha = 0.5; playerGroup.add(opE); Reflect.setField(playerEyeMap, nick, opE);
        var opB = new FlxSprite(0,0).makeGraphic(10,6,0xFFFF8800); opB.alpha = 0.5; playerGroup.add(opB); Reflect.setField(playerBeakMap, nick, opB);
        var tag = new FlxText(0,0,150,nick,11); tag.setFormat(Paths.font(currentFont),11,col,"center",1,0xFF000000); tag.cameras=[uiCam]; tag.alpha=0.6; nickTagGroup.add(tag); Reflect.setField(playerNickMap, nick, tag);
        Reflect.setField(playerMap, nick, op); Reflect.setField(deadMap, nick, false); Reflect.setField(targetXMap, nick, FlxG.width/2); Reflect.setField(targetYMap, nick, FlxG.height/2);
    }
    return Reflect.field(playerMap, nick);
}

function addLobbyPlayer(nick:String) { if (nick.length == 0) return; for (li in 0...lobbyPlayers.length) if (lobbyPlayers[li] == nick) return; lobbyPlayers.push(nick); }

function refreshLobbyUI() {
    lobbySlotGroup.clear(); lobbyBgGroup.clear(); titleText.visible = false; subtitleText.visible = false; typingText.visible = false; typingBg.visible = false;
    lobbyRoomText.visible = true; lobbyRoomText.text = "ROOM: " + activeRoomCode + "   |   DODGE DERBY"; lobbyRoomText.y = 20;
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
