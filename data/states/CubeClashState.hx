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
import flx3d.Flx3DView;
import away3d.entities.Mesh;
import away3d.primitives.CubeGeometry;

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
var serverState:Dynamic = null;

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

var scene3D:Flx3DView;
var playerCube:Mesh;
var arenaMesh:Mesh;
var wallMeshes:Array<Mesh> = [];
var powerCubeMeshes:Array<Mesh> = [];
var opponentNames:Array<String> = [];
var opponentMeshList:Array<Mesh> = [];

var playerX:Float = 0;
var playerZ:Float = 0;
var playerVX:Float = 0;
var playerVZ:Float = 0;
var playerSize:Float = 20;
var playerSpeedBoost:Float = 1.0;
var arenaRadius:Float = 300;
var iAmDead:Bool = false;
var localScore:Int = 0;
var roundActive:Bool = false;
var countdownActive:Bool = false;
var moveSpeed:Float = 200;
var friction:Float = 0.92;
var roundTimer:Float = 60;
var aliveCount:Int = 0;

var scoreText:FlxText;
var timerText:FlxText;
var statusText:FlxText;
var skinCol:Int = 0xFFFFEE00;

function create() {
    if (FlxG.save.data.flappyNickname != null) myNickname = FlxG.save.data.flappyNickname;
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;
    if (FlxG.save.data.flappyCoins != null) flappyCoins = FlxG.save.data.flappyCoins;

    skinCol = 0xFFFFEE00;
    if (FlxG.save.data.flappyEquippedSkinId != null) {
        var skins:Array<Dynamic> = [
            {id: "default", color: 0xFFFFEE00}, {id: "ice", color: 0xFF00CCFF}, {id: "bubblegum", color: 0xFFFF6699},
            {id: "neon", color: 0xFF66FF66}, {id: "sunset", color: 0xFFFF9933}, {id: "crimson", color: 0xFFFF0000},
            {id: "golden", color: 0xFFFFD700}, {id: "shadow", color: 0xFF333333}, {id: "royal", color: 0xFF4169E1}
        ];
        for (s in skins) if (s.id == FlxG.save.data.flappyEquippedSkinId) skinCol = s.color;
    }

    FlxG.camera.bgColor = 0xFF0D001A;

    uiCam = new FlxCamera();
    uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    scene3D = new Flx3DView(0, 0, FlxG.width, FlxG.height);
    add(scene3D);

    lobbySlotGroup = new FlxTypedGroup(); add(lobbySlotGroup);
    lobbyBgGroup = new FlxTypedGroup(); add(lobbyBgGroup);

    setupUI();
    goToState("MENU");
}

function setupUI() {
    titleText = makeText(0, 40, FlxG.width, "CUBE CLASH", 64, 0xFFFF8844);
    subtitleText = makeText(0, 110, FlxG.width, "3D ARENA BATTLE! LAST CUBE STANDING!", 20, 0xFFFFAA77); subtitleText.alpha = 0.7;
    lobbyText = makeText(0, FlxG.height * 0.78, FlxG.width, "", 22, 0xFFFFEE00);
    typingBg = new FlxSprite(FlxG.width * 0.2, FlxG.height * 0.81).makeGraphic(Std.int(FlxG.width * 0.6), 48, 0xFF1A1A2E); typingBg.alpha = 0.7; typingBg.cameras = [uiCam]; add(typingBg); typingBg.visible = false;
    typingText = makeText(0, FlxG.height * 0.82, FlxG.width, "", 34, 0xFFFFFFFF);
    scoreText = makeText(0, 10, FlxG.width, "", 32, 0xFFFF8844);
    timerText = makeText(0, 46, FlxG.width, "", 22, 0xFFFFAA77);
    statusText = makeText(0, FlxG.height - 40, FlxG.width, "", 16, 0xFF00FF88);
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
    if (s == "MENU") { netDisconnect(); isMultiplayer = false; lobbyPlayers = []; activePlayers = []; }
    titleText.visible = (s == "MENU" || s == "ROOM_INPUT"); subtitleText.visible = (s == "MENU");
    lobbyText.visible = true; typingText.visible = (s == "ROOM_INPUT"); typingBg.visible = typingText.visible;
    scoreText.visible = (s == "PLAYING" || s == "GAMEOVER"); timerText.visible = (s == "PLAYING");
    statusText.visible = (s == "PLAYING"); coinText.visible = true; coinIconText.visible = true;
    scene3D.visible = (s == "PLAYING" || s == "GAMEOVER");

    switch(s) {
        case "MENU": lobbyText.text = "[1] SOLO   [2] MULTI   [ESC] BACK"; FlxG.sound.playMusic(Paths.music("flappy/mainTheme"), 0.8, true);
        case "ROOM_INPUT": lobbyText.text = "ENTER 4-LETTER ROOM CODE";
        case "PLAYING": startRound();
    }
}

function startRound() {
    iAmDead = false; localScore = 0; roundActive = false; countdownActive = true;
    playerX = 0; playerZ = 0; playerVX = 0; playerVZ = 0;
    playerSize = 20; playerSpeedBoost = 1.0; arenaRadius = 300;
    roundTimer = 60; aliveCount = isMultiplayer ? lobbyPlayers.length : 4;

    for (m in wallMeshes) scene3D.removeChild(m);
    wallMeshes = [];
    for (c in powerCubeMeshes) scene3D.removeChild(c);
    powerCubeMeshes = [];
    var oi = opponentNames.length - 1;
    while (oi >= 0) { scene3D.removeChild(opponentMeshList[oi]); oi--; }
    opponentNames = []; opponentMeshList = [];

    arenaMesh = new Mesh(new CubeGeometry(600, 4, 600));
    arenaMesh.y = -2;
    scene3D.addChild(arenaMesh);

    playerCube = new Mesh(new CubeGeometry(playerSize, playerSize, playerSize));
    playerCube.y = playerSize / 2;
    scene3D.addChild(playerCube);

    for (i in 0...12) {
        var angle = (i / 12) * Math.PI * 2;
        var wx = Math.cos(angle) * arenaRadius;
        var wz = Math.sin(angle) * arenaRadius;
        var wall = new Mesh(new CubeGeometry(40, 30, 40));
        wall.x = wx; wall.z = wz; wall.y = 15;
        scene3D.addChild(wall);
        wallMeshes.push(wall);
    }

    if (!isMultiplayer) {
        for (i in 0...3) {
            var angle = (i / 3) * Math.PI * 2 + 1.0;
            var name = "BOT" + i;
            var botMesh = new Mesh(new CubeGeometry(20, 20, 20));
            botMesh.x = Math.cos(angle) * 100;
            botMesh.z = Math.sin(angle) * 100;
            botMesh.y = 10;
            scene3D.addChild(botMesh);
            setOpponentMesh(name, botMesh);
        }
    }

    spawnPowerCubes();

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
            tmr.cancel(); ct.text = "CLASH!"; ct.color = 0xFFFF8844; ct.scale.set(1.5, 1.5);
            FlxTween.tween(ct, {alpha: 0}, 0.5, {ease: FlxEase.quadIn, onComplete: function(_) { ct.destroy(); }});
            FlxG.camera.flash(0x33FFFFFF, 0.3); countdownActive = false; roundActive = true;
        } else {
            ct.text = Std.string(count); ct.scale.set(1.5, 1.5);
            FlxTween.tween(ct.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.elasticOut});
            ct.color = [0xFFFFEE00, 0xFFFF9900, 0xFFFF4444][3 - count];
        }
    }, 0);
}

function spawnPowerCubes() {
    for (i in 0...5) {
        var angle = FlxG.random.float(0, Math.PI * 2);
        var dist = FlxG.random.float(40, arenaRadius * 0.7);
        var pc = new Mesh(new CubeGeometry(12, 12, 12));
        pc.x = Math.cos(angle) * dist;
        pc.z = Math.sin(angle) * dist;
        pc.y = 10;
        scene3D.addChild(pc);
        powerCubeMeshes.push(pc);
    }
}

function update(elapsed:Float) {
    titleGlow += elapsed * 2.5;
    if (titleText.visible) titleText.scale.set(Math.sin(titleGlow) * 0.06 + 1.0, Math.sin(titleGlow) * 0.06 + 1.0);
    if (subtitleText.visible) subtitleText.alpha = 0.5 + Math.sin(titleGlow * 1.3) * 0.3;
    if (coinBounce > 1.0) { coinBounce = FlxMath.lerp(coinBounce, 1.0, elapsed * 8); coinText.scale.set(coinBounce, coinBounce); }
    coinIconSpin += elapsed * 6; if (coinIconText != null) coinIconText.scale.set(Math.abs(Math.cos(coinIconSpin)) * 0.6 + 0.4, 1.0);

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
    if (isHost && FlxG.keys.justPressed.ENTER && lobbyPlayers.length >= 2) netSend("START_GAME:cubeclash:0");
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU");
}

function updatePlaying(elapsed:Float) {
    if (countdownActive || !roundActive || iAmDead) return;

    roundTimer -= elapsed;
    if (roundTimer <= 0) roundTimer = 0;

    var l = FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A;
    var r = FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D;
    var u = FlxG.keys.pressed.UP || FlxG.keys.pressed.W;
    var d = FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S;

    if (isMultiplayer) {
        netSend("INPUT:LEFT:" + (l ? "1" : "0"));
        netSend("INPUT:RIGHT:" + (r ? "1" : "0"));
        netSend("INPUT:UP:" + (u ? "1" : "0"));
        netSend("INPUT:DOWN:" + (d ? "1" : "0"));
    }

    if (FlxG.keys.justPressed.SPACE) {
        if (isMultiplayer) netSend("INPUT:DASH");
        else {
            playerVX += (r ? 1 : 0) * 400 - (l ? 1 : 0) * 400;
            playerVZ += (d ? 1 : 0) * 400 - (u ? 1 : 0) * 400;
        }
    }

    if (!isMultiplayer) {
        var accel = moveSpeed * playerSpeedBoost;
        if (l) playerVX -= accel * elapsed;
        if (r) playerVX += accel * elapsed;
        if (u) playerVZ -= accel * elapsed;
        if (d) playerVZ += accel * elapsed;

        playerVX *= Math.pow(friction, elapsed * 60);
        playerVZ *= Math.pow(friction, elapsed * 60);
        playerX += playerVX * elapsed;
        playerZ += playerVZ * elapsed;

        var dist = Math.sqrt(playerX * playerX + playerZ * playerZ);
        if (dist > arenaRadius) {
            iAmDead = true;
            var reward = 5 + Std.int(roundTimer);
            flappyCoins += reward; FlxG.save.data.flappyCoins = flappyCoins; FlxG.save.flush();
            coinText.text = "" + flappyCoins; coinBounce = 1.3;
            showGameOver(reward);
            return;
        }

        arenaRadius -= elapsed * 2;
        if (arenaRadius < 80) arenaRadius = 80;

        updateBots(elapsed);
        checkPowerCubeCollect();
    }

    playerCube.x = playerX;
    playerCube.z = playerZ;
    playerCube.y = playerSize / 2;
    playerCube.rotationY += elapsed * 60;

    if (isMultiplayer && serverState != null) {
        var myS:Dynamic = Reflect.field(serverState.p, myNickname);
        if (myS != null) {
            playerX = FlxMath.lerp(playerX, myS.x, 0.3);
            playerZ = FlxMath.lerp(playerZ, myS.y, 0.3);
            if (myS.sz != null) playerSize = myS.sz;
            if (!myS.alive && !iAmDead) {
                iAmDead = true;
                var reward = 5;
                flappyCoins += reward; FlxG.save.data.flappyCoins = flappyCoins; FlxG.save.flush();
                showGameOver(reward);
                return;
            }
        }
        if (serverState.ar != null) arenaRadius = FlxMath.lerp(arenaRadius, serverState.ar, 0.2);
        if (serverState.tm != null) roundTimer = serverState.tm;

        var fields = Reflect.fields(serverState.p);
        for (fi in 0...fields.length) {
            var nick = fields[fi];
            if (nick == myNickname) continue;
            var ps:Dynamic = Reflect.field(serverState.p, nick);
            if (!hasOpponent(nick)) {
                var idx = fi % playerColors.length;
                var om = new Mesh(new CubeGeometry(20, 20, 20));
                om.y = 10;
                scene3D.addChild(om);
                setOpponentMesh(nick, om);
            }
            var om = getOpponentMesh(nick);
            om.x = FlxMath.lerp(om.x, ps.x, 0.3);
            om.z = FlxMath.lerp(om.z, ps.y, 0.3);
            om.visible = ps.alive;
            om.rotationY += elapsed * 60;
        }
    }

    updateArenaVisuals();

    scoreText.text = "ALIVE: " + aliveCount;
    timerText.text = "TIME: " + Std.int(roundTimer);
    statusText.text = "ARENA: " + Std.int(arenaRadius);
}

function updateBots(elapsed:Float) {
    var bi = opponentNames.length - 1;
    while (bi >= 0) {
        var bot = opponentMeshList[bi];
        var angle = Math.atan2(-bot.z, -bot.x);
        angle += FlxG.random.float(-0.5, 0.5);
        bot.x += Math.cos(angle) * 40 * elapsed;
        bot.z += Math.sin(angle) * 40 * elapsed;
        bot.rotationY += elapsed * 80;

        var bdist = Math.sqrt(bot.x * bot.x + bot.z * bot.z);
        if (bdist > arenaRadius) {
            scene3D.removeChild(bot);
            opponentNames.splice(bi, 1);
            opponentMeshList.splice(bi, 1);
            aliveCount--;
            if (aliveCount <= 1 && !iAmDead) {
                var reward = 20 + Std.int(roundTimer);
                flappyCoins += reward; FlxG.save.data.flappyCoins = flappyCoins; FlxG.save.flush();
                coinText.text = "" + flappyCoins; coinBounce = 1.3;
                showGameOver(reward);
            }
        } else {
            var dx = playerX - bot.x;
            var dz = playerZ - bot.z;
            var d = Math.sqrt(dx * dx + dz * dz);
            if (d < 30) {
                var nx = dx / d; var nz = dz / d;
                playerVX += nx * 300;
                playerVZ += nz * 300;
                bot.x -= nx * 10;
                bot.z -= nz * 10;
            }
        }
        bi--;
    }
}

function checkPowerCubeCollect() {
    var i = powerCubeMeshes.length - 1;
    while (i >= 0) {
        var pc = powerCubeMeshes[i];
        pc.rotationY += 3;
        var dx = playerX - pc.x;
        var dz = playerZ - pc.z;
        if (Math.sqrt(dx * dx + dz * dz) < 25) {
            playerSpeedBoost += 0.15;
            playerSize += 3;
            flappyCoins += 2;
            coinBounce = 1.2;
            FlxG.camera.flash(0x11FFFFFF, 0.08);
            scene3D.removeChild(pc);
            powerCubeMeshes.splice(i, 1);
        }
        i--;
    }
    if (powerCubeMeshes.length < 2 && FlxG.random.bool(1)) spawnPowerCubes();
}

function updateArenaVisuals() {
    var scale = arenaRadius / 300;
    arenaMesh.scaleX = scale;
    arenaMesh.scaleZ = scale;
    for (i in 0...wallMeshes.length) {
        var angle = (i / wallMeshes.length) * Math.PI * 2;
        wallMeshes[i].x = Math.cos(angle) * arenaRadius;
        wallMeshes[i].z = Math.sin(angle) * arenaRadius;
    }
}

function showGameOver(reward:Int) {
    gameState = "GAMEOVER"; roundActive = false;
    incrementStat("totalGamesPlayed", 1);
    incrementStat("cubeClashGamesPlayed", 1);
    unlockAchievement("gen_welcome");
    if (FlxG.sound.music != null) FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.5);
    var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000); overlay.cameras = [uiCam]; add(overlay);
    FlxTween.color(overlay, 0.5, 0x00000000, 0xBB000000);
    var won = !iAmDead || aliveCount <= 1;
    if (won) {
        incrementStat("totalWins", 1);
        incrementStat("cubeClashWins", 1);
        if (getStat("cubeClashWins") >= 10) unlockAchievement("3d_cubefighter");
        if (getStat("cubeClashWins") >= 100) unlockAchievement("3d_arenalegend");
    }
    var rt = new FlxText(0, 0, FlxG.width, won ? "VICTORY!" : "ELIMINATED!", 52);
    rt.setFormat(Paths.font(currentFont), 52, won ? 0xFF00FF88 : 0xFFFF4444, "center", 4, 0xFF000000);
    rt.screenCenter(); rt.y -= 60; rt.cameras = [uiCam]; rt.alpha = 0; rt.scale.set(2.5, 2.5); add(rt);
    FlxTween.tween(rt, {alpha: 1}, 0.4); FlxTween.tween(rt.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.elasticOut});
    var info = new FlxText(0, 0, FlxG.width, "+" + reward + " FLOCKERS\n\n[ENTER] RETRY   [ESC] BACK", 22);
    info.setFormat(Paths.font(currentFont), 22, 0xFFCCCCCC, "center", 2, 0xFF000000);
    info.screenCenter(); info.y += 20; info.cameras = [uiCam]; info.alpha = 0; add(info);
    FlxTween.tween(info, {alpha: 1}, 0.5, {startDelay: 0.3});
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
                    if (gs.ar != null) arenaRadius = FlxMath.lerp(arenaRadius, gs.ar, 0.2);
                    if (gs.tm != null) roundTimer = gs.tm;
                    var fields = Reflect.fields(gs.p);
                    aliveCount = 0;
                    for (fi in 0...fields.length) {
                        var ps:Dynamic = Reflect.field(gs.p, fields[fi]);
                        if (ps.alive) aliveCount++;
                    }
                    if (gs.ph == "gameover" && gameState == "PLAYING") {
                        if (!iAmDead) {
                            var reward = 20 + Std.int(roundTimer);
                            flappyCoins += reward; FlxG.save.data.flappyCoins = flappyCoins; FlxG.save.flush();
                            coinText.text = "" + flappyCoins; coinBounce = 1.3;
                            showGameOver(reward);
                        }
                    }
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

function addLobbyPlayer(nick:String) { if (nick.length == 0) return; for (li in 0...lobbyPlayers.length) if (lobbyPlayers[li] == nick) return; lobbyPlayers.push(nick); }

function refreshLobbyUI() {
    lobbySlotGroup.clear(); lobbyBgGroup.clear(); titleText.visible = false; subtitleText.visible = false; typingText.visible = false; typingBg.visible = false;
    lobbyRoomText.visible = true; lobbyRoomText.text = "ROOM: " + activeRoomCode + "   |   CUBE CLASH"; lobbyRoomText.y = 20;
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

function getOpponentMesh(name:String):Mesh {
    for (i in 0...opponentNames.length) if (opponentNames[i] == name) return opponentMeshList[i];
    return null;
}
function setOpponentMesh(name:String, mesh:Mesh) {
    for (i in 0...opponentNames.length) { if (opponentNames[i] == name) { opponentMeshList[i] = mesh; return; } }
    opponentNames.push(name); opponentMeshList.push(mesh);
}
function hasOpponent(name:String):Bool {
    for (i in 0...opponentNames.length) if (opponentNames[i] == name) return true;
    return false;
}
function removeOpponent(name:String) {
    for (i in 0...opponentNames.length) { if (opponentNames[i] == name) { opponentNames.splice(i, 1); opponentMeshList.splice(i, 1); return; } }
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
