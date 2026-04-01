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
import funkin.backend.shaders.CustomShader;
import sys.net.Host;
import funkin.backend.system.net.Socket;

var gameState:String = "MENU";
var perspShader:CustomShader;
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
var playerSpeed:Float = 300;
var iAmDead:Bool = false;

var tileGroup:FlxTypedGroup<FlxSprite>;
var tileGlowGroup:FlxTypedGroup<FlxSprite>;
var playerGroup:FlxTypedGroup<FlxSprite>;
var nickTagGroup:FlxTypedGroup<FlxText>;
var vfxGroup:FlxTypedGroup<FlxSprite>;
var playerMap:Dynamic = {};
var playerEyeMap:Dynamic = {};
var playerBeakMap:Dynamic = {};
var playerNickMap:Dynamic = {};
var targetXMap:Dynamic = {};
var targetYMap:Dynamic = {};
var deadMap:Dynamic = {};

var gridCols:Int = 5;
var gridRows:Int = 4;
var tileW:Float = 0;
var tileH:Float = 0;
var gridOffX:Float = 0;
var gridOffY:Float = 0;
var tileStates:Array<Int> = [];
var litTiles:Array<Bool> = [];
var safeTiles:Array<Bool> = [];
var tileFadeTimers:Array<Float> = [];

var roundNum:Int = 0;
var maxRounds:Int = 8;
var musicPlaying:Bool = false;
var musicTimer:Float = 0;
var musicDuration:Float = 5.0;
var revealTimer:Float = 0;
var revealDuration:Float = 2.5;
var roundPhase:String = "IDLE";
var roundActive:Bool = false;
var countdownActive:Bool = false;

var roundText:FlxText;
var phaseText:FlxText;
var statusText:FlxText;
var pulseTimer:Float = 0;

var arenaLeft:Float = 60;
var arenaTop:Float = 90;

var tileColors:Array<Int> = [0xFFFF44AA, 0xFF44AAFF, 0xFF44FF66, 0xFFFFAA00, 0xFFAA44FF, 0xFFFF4444, 0xFF00FFCC, 0xFFFFEE00];

function create() {
    if (FlxG.save.data.flappyNickname != null) myNickname = FlxG.save.data.flappyNickname;
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;
    if (FlxG.save.data.flappyCoins != null) flappyCoins = FlxG.save.data.flappyCoins;

    tileW = (FlxG.width - arenaLeft * 2) / gridCols;
    tileH = (FlxG.height - arenaTop - 60) / gridRows;
    gridOffX = arenaLeft;
    gridOffY = arenaTop;

    FlxG.camera.bgColor = 0xFF0A0614;
    perspShader = new CustomShader("perspective");
    perspShader.skew = 0.18;
    perspShader.depth = 0.6;
    perspShader.tilt = 0.3;
    FlxG.camera.addShader(perspShader);
    uiCam = new FlxCamera(); uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    for (i in 0...gridCols * gridRows) {
        tileStates.push(0);
        litTiles.push(false);
        safeTiles.push(false);
        tileFadeTimers.push(0);
    }

    tileGlowGroup = new FlxTypedGroup(); add(tileGlowGroup);
    tileGroup = new FlxTypedGroup(); add(tileGroup);
    vfxGroup = new FlxTypedGroup(); add(vfxGroup);
    playerGroup = new FlxTypedGroup(); add(playerGroup);
    nickTagGroup = new FlxTypedGroup(); add(nickTagGroup);

    for (r in 0...gridRows) {
        for (c in 0...gridCols) {
            var tx = gridOffX + c * tileW + 2;
            var ty = gridOffY + r * tileH + 2;
            var glow = new FlxSprite(Std.int(tx - 3), Std.int(ty - 3)).makeGraphic(Std.int(tileW - 1), Std.int(tileH - 1), 0xFFFF44AA);
            glow.alpha = 0; tileGlowGroup.add(glow);
            var tile = new FlxSprite(Std.int(tx), Std.int(ty)).makeGraphic(Std.int(tileW - 4), Std.int(tileH - 4), 0xFF1A1028);
            tile.alpha = 0.6; tile.ID = r * gridCols + c; tileGroup.add(tile);
        }
    }

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
    titleText = makeText(0, 30, FlxG.width, "MUSICAL TILES", 64, 0xFFFF44AA);
    subtitleText = makeText(0, 100, FlxG.width, "DON'T GET CAUGHT!", 20, 0xFFCC66FF); subtitleText.alpha = 0.7;
    lobbyText = makeText(0, FlxG.height * 0.78, FlxG.width, "", 22, 0xFFFFEE00);
    typingBg = new FlxSprite(FlxG.width * 0.2, FlxG.height * 0.81).makeGraphic(Std.int(FlxG.width * 0.6), 48, 0xFF1A1A2E); typingBg.alpha = 0.7; typingBg.cameras = [uiCam]; add(typingBg); typingBg.visible = false;
    typingText = makeText(0, FlxG.height * 0.82, FlxG.width, "", 34, 0xFFFFFFFF);
    roundText = makeText(0, 10, FlxG.width, "ROUND 1", 32, 0xFFFF44AA);
    phaseText = makeText(0, 46, FlxG.width, "", 22, 0xFFFFFFFF);
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
    roundText.visible = (s == "PLAYING" || s == "GAMEOVER"); phaseText.visible = (s == "PLAYING");
    statusText.visible = (s == "PLAYING"); statusText.text = "";
    coinText.visible = true; coinIconText.visible = true;
    player.visible = (s == "PLAYING"); playerEye.visible = player.visible; playerBeak.visible = player.visible;

    switch(s) {
        case "MENU": lobbyText.text = "[1] SOLO   [2] MULTI   [ESC] BACK"; FlxG.sound.playMusic(Paths.music("flappy/mainTheme"), 0.8, true); resetTiles();
        case "ROOM_INPUT": lobbyText.text = "ENTER 4-LETTER ROOM CODE";
        case "PLAYING": startRound();
    }
}

function resetData() {
    playerMap = {}; playerEyeMap = {}; playerBeakMap = {}; playerNickMap = {};
    targetXMap = {}; targetYMap = {}; deadMap = {};
}

function resetTiles() {
    for (i in 0...gridCols * gridRows) {
        tileStates[i] = 0; litTiles[i] = false; safeTiles[i] = false; tileFadeTimers[i] = 0;
    }
}

function startRound() {
    iAmDead = false; roundNum = 0; roundActive = false; countdownActive = true;
    resetTiles(); vfxGroup.clear();
    player.x = FlxG.width / 2 - 14; player.y = gridOffY + (gridRows * tileH) / 2;
    player.alpha = 1;
    titleText.visible = false; subtitleText.visible = false; lobbyText.visible = false; typingText.visible = false; typingBg.visible = false;
    roundText.text = "ROUND 1"; phaseText.text = "";

    FlxG.sound.playMusic(Paths.music("flappy/racingTillDawn"), 0, true);
    FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.5);

    var count = 3;
    var ct = new FlxText(0, 0, FlxG.width, "3", 140);
    ct.setFormat(Paths.font(currentFont), 140, 0xFFFFFFFF, "center", 6, 0xFF000000);
    ct.screenCenter(); ct.cameras = [uiCam]; add(ct);

    new FlxTimer().start(1, function(tmr) {
        count--;
        if (count <= 0) {
            tmr.cancel(); ct.text = "MOVE!"; ct.color = 0xFFFF44AA;
            ct.scale.set(1.5, 1.5);
            FlxTween.tween(ct, {alpha: 0}, 0.5, {ease: FlxEase.quadIn, onComplete: function(_) { ct.destroy(); }});
            FlxG.camera.flash(0x33FFFFFF, 0.3); countdownActive = false; roundActive = true;
            beginMusicPhase();
        } else {
            ct.text = Std.string(count); ct.scale.set(1.5, 1.5);
            FlxTween.tween(ct.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.elasticOut});
            ct.color = [0xFFFFEE00, 0xFFFF9900, 0xFFFF4444][3 - count];
            FlxG.camera.shake(0.004, 0.1);
        }
    }, 0);
}

function beginMusicPhase() {
    roundNum++;
    if (roundNum > maxRounds) { gameState = "GAMEOVER"; showResults(); return; }

    roundPhase = "MUSIC";
    musicPlaying = true;
    musicTimer = 0;
    musicDuration = Math.max(2.5, 5.5 - roundNum * 0.35);
    roundText.text = "ROUND " + roundNum;
    phaseText.text = "MUSIC PLAYING..."; phaseText.color = 0xFF44FF66;

    resetTiles();
    for (i in 0...gridCols * gridRows) litTiles[i] = true;
    updateTileVisuals();

    if (FlxG.sound.music != null) FlxG.sound.music.volume = 1.0;
}

function stopMusic() {
    roundPhase = "REVEAL";
    musicPlaying = false;
    revealTimer = 0;
    revealDuration = Math.max(1.5, 2.5 - roundNum * 0.1);
    phaseText.text = "FIND A SAFE TILE!"; phaseText.color = 0xFFFF4444;

    if (FlxG.sound.music != null) FlxG.sound.music.volume = 0.15;
    FlxG.camera.shake(0.008, 0.2);

    var safeCount = Math.max(2, Std.int(gridCols * gridRows * (0.6 - roundNum * 0.05)));
    if (safeCount > gridCols * gridRows - 1) safeCount = gridCols * gridRows - 1;

    for (i in 0...gridCols * gridRows) { safeTiles[i] = false; litTiles[i] = false; }

    var indices:Array<Int> = [];
    for (i in 0...gridCols * gridRows) indices.push(i);
    shuffleArray(indices);

    for (i in 0...safeCount) { safeTiles[indices[i]] = true; litTiles[indices[i]] = true; }

    var roundColor = tileColors[(roundNum - 1) % tileColors.length];
    var idx = 0;
    tileGroup.forEach(function(tile:FlxSprite) {
        if (safeTiles[idx]) {
            tile.color = roundColor;
            FlxTween.color(tile, 0.2, 0xFF1A1028, roundColor);
        } else {
            tile.color = 0xFF1A1028;
        }
        idx++;
    });
    updateTileVisuals();
}

function checkTiles() {
    roundPhase = "CHECK";

    var playerTile = getPlayerTile(player.x + 14, player.y + 12);
    var safe = playerTile >= 0 && playerTile < gridCols * gridRows && safeTiles[playerTile];

    if (!safe && !iAmDead) {
        iAmDead = true;
        FlxG.camera.flash(0x44FF0000, 0.4);
        FlxG.camera.shake(0.02, 0.3);
        spawnDeathVFX(player.x, player.y);
        player.alpha = 0.3;
        statusText.text = "ELIMINATED ON ROUND " + roundNum; statusText.color = 0xFFFF4444;
        if (isMultiplayer) netSend("DEAD:" + roundNum);
    }

    if (isMultiplayer) {
        for (i in 0...activePlayers.length) {
            var nick = activePlayers[i];
            var op:FlxSprite = Reflect.field(playerMap, nick);
            if (op != null && Reflect.field(deadMap, nick) == null) {
                var opTile = getPlayerTile(op.x + 14, op.y + 12);
                var opSafe = opTile >= 0 && opTile < gridCols * gridRows && safeTiles[opTile];
                if (!opSafe) { op.alpha = 0.3; Reflect.setField(deadMap, nick, true); }
            }
        }
    }

    var idx = 0;
    tileGroup.forEach(function(tile:FlxSprite) {
        if (!safeTiles[idx]) {
            FlxTween.color(tile, 0.3, tile.color, 0xFF440000);
            FlxTween.tween(tile, {alpha: 0.2}, 0.3);
        } else {
            FlxTween.color(tile, 0.2, tile.color, 0xFF00FF66);
        }
        idx++;
    });

    new FlxTimer().start(2.0, function(t) {
        if (iAmDead) { gameState = "GAMEOVER"; showResults(); }
        else {
            var idx2 = 0;
            tileGroup.forEach(function(tile:FlxSprite) { tile.alpha = 0.6; tile.color = 0xFF1A1028; idx2++; });
            beginMusicPhase();
        }
    });
}

function getPlayerTile(px:Float, py:Float):Int {
    var col = Std.int((px - gridOffX) / tileW);
    var row = Std.int((py - gridOffY) / tileH);
    if (col < 0 || col >= gridCols || row < 0 || row >= gridRows) return -1;
    return row * gridCols + col;
}

function updateTileVisuals() {
    var idx = 0;
    tileGlowGroup.forEach(function(glow:FlxSprite) {
        glow.alpha = litTiles[idx] ? 0.15 : 0;
        if (litTiles[idx]) glow.color = tileColors[(roundNum - 1) % tileColors.length];
        idx++;
    });
}

function shuffleArray(arr:Array<Int>) {
    var n = arr.length;
    for (i in 0...n) {
        var j = FlxG.random.int(i, n - 1);
        var tmp = arr[i]; arr[i] = arr[j]; arr[j] = tmp;
    }
}

function spawnDeathVFX(x:Float, y:Float) {
    for (i in 0...8) {
        var size = FlxG.random.int(6, 16);
        var p = new FlxSprite(x + FlxG.random.float(-6, 6), y + FlxG.random.float(-6, 6)).makeGraphic(size, size, 0xFFFF4444);
        p.alpha = 0.8; p.velocity.set(FlxG.random.float(-120, 120), FlxG.random.float(-140, 40));
        vfxGroup.add(p);
        FlxTween.tween(p, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.4, {onComplete: function(_) { p.destroy(); }});
    }
}

function showResults() {
    var earned = 10 + roundNum * 3;
    if (roundNum >= maxRounds && !iAmDead) earned = 50;
    flappyCoins += earned;
    FlxG.save.data.flappyCoins = flappyCoins; FlxG.save.flush();
    coinText.text = "" + flappyCoins; coinBounce = 1.3;

    player.visible = false; playerEye.visible = false; playerBeak.visible = false;
    phaseText.visible = false;

    if (FlxG.sound.music != null) FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.5);

    var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000);
    overlay.cameras = [uiCam]; add(overlay);
    FlxTween.color(overlay, 0.5, 0x00000000, 0xBB000000);

    var winText = (roundNum >= maxRounds && !iAmDead) ? "YOU SURVIVED!" : "ELIMINATED!";
    var winCol = (roundNum >= maxRounds && !iAmDead) ? 0xFF44FF66 : 0xFFFF4444;
    var resultTitle = new FlxText(0, 0, FlxG.width, winText, 64);
    resultTitle.setFormat(Paths.font(currentFont), 64, winCol, "center", 4, 0xFF000000);
    resultTitle.screenCenter(); resultTitle.y -= 80; resultTitle.cameras = [uiCam]; resultTitle.alpha = 0; resultTitle.scale.set(2.5, 2.5); add(resultTitle);
    FlxTween.tween(resultTitle, {alpha: 1}, 0.4, {ease: FlxEase.quadOut});
    FlxTween.tween(resultTitle.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.elasticOut});

    var body = "SURVIVED " + roundNum + " / " + maxRounds + " ROUNDS\nEARNED " + earned + " FLOCKERS!\n\n[ENTER] PLAY AGAIN   [ESC] BACK";
    if (isMultiplayer) {
        var alive:Array<String> = [];
        if (!iAmDead) alive.push(myNickname);
        for (i in 0...activePlayers.length) {
            var nick = activePlayers[i];
            if (Reflect.field(deadMap, nick) == null) alive.push(nick);
        }
        body = "ROUND " + roundNum + " / " + maxRounds + "\n\n";
        if (alive.length > 0) body += "SURVIVORS: " + alive.join(", ") + "\n";
        else body += "NO SURVIVORS!\n";
        body += "EARNED " + earned + " FLOCKERS!\n\n[ENTER] PLAY AGAIN   [ESC] BACK";
    }

    var resultInfo = new FlxText(0, 0, FlxG.width, body, 22);
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
    pulseTimer += elapsed;

    if (player.visible) {
        playerEye.setPosition(player.x + 18, player.y + 5);
        playerBeak.setPosition(player.x + 22, player.y + 10);
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
        if (op != null && opE != null) opE.setPosition(op.x + 18, op.y + 5);
        if (op != null && opB != null) opB.setPosition(op.x + 22, op.y + 10);
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
    if (isHost && FlxG.keys.justPressed.ENTER && lobbyPlayers.length >= 2) netSend("START_GAME");
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU");
}

function updatePlaying(elapsed:Float) {
    if (countdownActive || !roundActive) return;
    if (iAmDead) return;

    if (roundPhase == "MUSIC") {
        musicTimer += elapsed;

        var beat = Math.sin(pulseTimer * 8);
        var idx = 0;
        tileGroup.forEach(function(tile:FlxSprite) {
            var wave = Math.sin(pulseTimer * 6 + idx * 0.7);
            var brightness = 0.3 + wave * 0.15;
            tile.alpha = brightness;
            idx++;
        });

        if (musicTimer >= musicDuration) stopMusic();
    }

    if (roundPhase == "REVEAL") {
        revealTimer += elapsed;

        var blink = Math.sin(pulseTimer * 12) > 0;
        var idx = 0;
        tileGlowGroup.forEach(function(glow:FlxSprite) {
            if (safeTiles[idx]) glow.alpha = blink ? 0.25 : 0.08;
            else glow.alpha = 0;
            idx++;
        });

        if (revealTimer >= revealDuration) checkTiles();
    }

    var spd = playerSpeed * elapsed;
    if (FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A) player.x -= spd;
    if (FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D) player.x += spd;
    if (FlxG.keys.pressed.UP || FlxG.keys.pressed.W) player.y -= spd;
    if (FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S) player.y += spd;

    var minX = gridOffX;
    var maxX = gridOffX + gridCols * tileW - 28;
    var minY = gridOffY;
    var maxY = gridOffY + gridRows * tileH - 24;
    player.x = FlxMath.bound(player.x, minX, maxX);
    player.y = FlxMath.bound(player.y, minY, maxY);

    if (isMultiplayer) netSend("POS:" + Std.int(player.x) + ":" + Std.int(player.y));
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
    netConnected = false;
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
        case "POS":
            if (args.length >= 3) {
                var nick = args[2]; Reflect.setField(targetXMap, nick, Std.parseFloat(args[0])); Reflect.setField(targetYMap, nick, Std.parseFloat(args[1])); getOpponent(nick);
            }
        case "DEAD":
            if (args.length >= 1) {
                var nick = args[0];
                var op = Reflect.field(playerMap, nick);
                if (op != null) { op.alpha = 0.3; Reflect.setField(deadMap, nick, true); }
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
        var op = new FlxSprite(FlxG.width / 2, FlxG.height / 2).makeGraphic(28, 24, col); op.alpha = 0.5; playerGroup.add(op);
        var opE = new FlxSprite(0, 0).makeGraphic(8, 8, 0xFFFFFFFF); opE.alpha = 0.5; playerGroup.add(opE); Reflect.setField(playerEyeMap, nick, opE);
        var opB = new FlxSprite(0, 0).makeGraphic(10, 6, 0xFFFF8800); opB.alpha = 0.5; playerGroup.add(opB); Reflect.setField(playerBeakMap, nick, opB);
        var opTag = new FlxText(0, 0, 150, nick, 11); opTag.setFormat(Paths.font(currentFont), 11, col, "center", 1, 0xFF000000); opTag.cameras = [uiCam]; opTag.alpha = 0.6; nickTagGroup.add(opTag); Reflect.setField(playerNickMap, nick, opTag);
        Reflect.setField(playerMap, nick, op); Reflect.setField(targetXMap, nick, FlxG.width / 2); Reflect.setField(targetYMap, nick, FlxG.height / 2);
    }
    return Reflect.field(playerMap, nick);
}

function addLobbyPlayer(nick:String) { if (nick.length == 0) return; for (li in 0...lobbyPlayers.length) if (lobbyPlayers[li] == nick) return; lobbyPlayers.push(nick); }

function refreshLobbyUI() {
    lobbySlotGroup.clear(); lobbyBgGroup.clear(); titleText.visible = false; subtitleText.visible = false; typingText.visible = false; typingBg.visible = false;
    lobbyRoomText.visible = true; lobbyRoomText.text = "ROOM: " + activeRoomCode + "   |   MUSICAL TILES"; lobbyRoomText.y = 20;

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

function destroy() { netDisconnect(); if (perspShader != null) FlxG.camera.removeShader(perspShader); }
