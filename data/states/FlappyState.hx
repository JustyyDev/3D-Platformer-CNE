import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.group.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxEase;
import flixel.util.FlxColor;
import flixel.addons.display.FlxBackdrop;
import flixel.input.keyboard.FlxKey;
import funkin.backend.shaders.CustomShader;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.ModSubState;
import sys.net.Host;
import funkin.backend.system.net.Socket;

/**
 * FLAPPY MULTIPLAYER ULTRA v2.3
 * Fixes: Full-screen sky, Duplicate fetchLeaderboard error, Difficulty scaling
 */

var gameState:String = "NICKNAME"; 
var inCountdown:Bool = false;

var bird:FlxSprite;
var p2Bird:FlxSprite;
var pipes:FlxTypedGroup<FlxSprite>;
var powerups:FlxTypedGroup<FlxSprite>; 
var vfxGroup:FlxTypedGroup<FlxSprite>; 

var sky:FlxBackdrop;

var titleText:FlxText;
var scoreText:FlxText;
var lobbyText:FlxText;
var typingText:FlxText;
var statusText:FlxText;
var levelText:FlxText; // Level Up UI
var debugLog:FlxText;
var emoteText:FlxText;
var p2EmoteText:FlxText;
var leaderboardGroup:FlxTypedGroup<FlxText>;
var uiCam:FlxCamera;

var pipeTimer:FlxTimer;
var shieldTimerObj:FlxTimer; 
var ghostTimerObj:FlxTimer;

// Difficulty & Stats
var score:Int = 0;
var p2Score:Int = 0;
var currentLevel:Int = 1;
var pipeGap:Float = 230;
var pipeInterval:Float = 1.6;
var pipeSpeed:Float = -300;
var gravity:Float = 1500;
var jumpForce:Float = -500;
var currentFont:String = "vcr.ttf"; 

var hasShield:Bool = false; 
var isGhost:Bool = false;

var SERVER_IP:String = "144.21.35.78"; 
var isMultiplayer:Bool = false;
var connection:Socket;
var p2Dead:Bool = false;
var iAmDead:Bool = false;
var netBuffer:String = ""; 
var connectionEstablished:Bool = false; 

var myNickname:String = "Player";
var typedInput:String = "";
var opponentName:String = "Opponent";

function create() {
    if (FlxG.save.data.flappyNickname != null) myNickname = FlxG.save.data.flappyNickname;

    uiCam = new FlxCamera();
    uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    // FIXED SKY: Covers whole screen regardless of asset height
    sky = new FlxBackdrop(Paths.image('menus/flappy/sky'), 0x01, 0, 0);
    sky.setGraphicSize(0, FlxG.height); 
    sky.updateHitbox();
    sky.velocity.x = -40;
    add(sky);

    pipes = new FlxTypedGroup(); add(pipes);
    powerups = new FlxTypedGroup(); add(powerups);
    vfxGroup = new FlxTypedGroup(); add(vfxGroup);
    leaderboardGroup = new FlxTypedGroup(); add(leaderboardGroup);

    bird = new FlxSprite(300, FlxG.height / 2).makeGraphic(40, 40, 0xFFFFEE00); add(bird);
    p2Bird = new FlxSprite(300, FlxG.height / 2).makeGraphic(40, 40, 0xFFFF3333); 
    p2Bird.alpha = 0.5; p2Bird.visible = false; add(p2Bird);

    setupUI();

    switchState(myNickname == "Player" ? "NICKNAME" : "MENU");

    fetchStatus();
    new FlxTimer().start(10, function(t) { fetchStatus(); }, 0);
}

function setupUI() {
    titleText = new FlxText(0, 100, FlxG.width, "FLAPPY ULTRA", 84);
    titleText.setFormat(Paths.font(currentFont), 84, 0xFFFFFFFF, "center", 2, 0xFF000000);
    titleText.cameras = [uiCam]; add(titleText);

    scoreText = new FlxText(0, 40, FlxG.width, "0", 64);
    scoreText.setFormat(Paths.font(currentFont), 64, 0xFFFFFFFF, "center", 2, 0xFF000000);
    scoreText.cameras = [uiCam]; scoreText.visible = false; add(scoreText);

    levelText = new FlxText(0, 110, FlxG.width, "LEVEL 1", 32);
    levelText.setFormat(Paths.font(currentFont), 32, 0xFF00FFCC, "center", 2, 0xFF000000);
    levelText.cameras = [uiCam]; levelText.visible = false; add(levelText);

    statusText = new FlxText(20, 20, 400, "SERVER: CHECKING...", 20);
    statusText.setFormat(Paths.font(currentFont), 20, 0xFFFFFFFF, "left", 2, 0xFF000000);
    statusText.cameras = [uiCam]; add(statusText);

    debugLog = new FlxText(FlxG.width - 320, 20, 300, "", 14);
    debugLog.setFormat(Paths.font(currentFont), 14, 0xFF00FF00, "right", 1, 0xFF000000);
    debugLog.cameras = [uiCam]; add(debugLog);

    lobbyText = new FlxText(0, FlxG.height * 0.65, FlxG.width, "", 28);
    lobbyText.setFormat(Paths.font(currentFont), 28, 0xFFFFEE00, "center", 2, 0xFF000000);
    lobbyText.cameras = [uiCam]; add(lobbyText);

    typingText = new FlxText(0, FlxG.height * 0.8, FlxG.width, "", 42);
    typingText.setFormat(Paths.font(currentFont), 42, 0xFFFFFFFF, "center", 2, 0xFF000000);
    typingText.cameras = [uiCam]; add(typingText);

    emoteText = new FlxText(0, 0, 200, "", 32);
    emoteText.setFormat(Paths.font(currentFont), 32, 0xFFFFFFFF, "center", 2, 0xFF000000);
    emoteText.cameras = [uiCam]; add(emoteText);

    p2EmoteText = new FlxText(0, 0, 200, "", 32);
    p2EmoteText.setFormat(Paths.font(currentFont), 32, 0xFFFF4444, "center", 2, 0xFF000000);
    p2EmoteText.cameras = [uiCam]; add(p2EmoteText);
}

// --- DIFFICULTY LOGIC ---

function checkDifficulty() {
    var newLevel = Math.floor(score / 10) + 1;
    if (newLevel > currentLevel) {
        currentLevel = newLevel;
        pipeSpeed -= 35; 
        pipeGap = Math.max(160, pipeGap - 10);
        pipeInterval = Math.max(0.7, pipeInterval - 0.12);
        
        startPipeTimer(); // Restart with faster timing
        
        levelText.text = "LEVEL " + currentLevel;
        levelText.scale.set(1.5, 1.5);
        FlxTween.tween(levelText.scale, {x: 1, y: 1}, 0.6, {ease: FlxEase.elasticOut});
        FlxG.camera.flash(0x33FFFFFF, 0.4);
        logServer("LEVEL UP: " + currentLevel);
    }
}

function getPipeColor():Int {
    if (currentLevel >= 5) return 0xFFFF0000;
    if (currentLevel >= 3) return 0xFF0099FF;
    if (currentLevel >= 2) return 0xFFFF9900;
    return 0xFF22AA22;
}

// --- NETWORK FIXES ---

function logServer(msg:String) {
    debugLog.text = msg + "\n" + debugLog.text;
    if (debugLog.text.length > 200) debugLog.text = debugLog.text.substring(0, 200);
}

function fetchStatus() {
    try {
        var s = new Socket();
        s.connect(new Host(SERVER_IP), 8080);
        s.write("GET_STATUS\n");
        new FlxTimer().start(0.2, function(tmr) {
            var d = s.read();
            if (d != null && d.indexOf("STATUS") != -1) {
                var p = d.split(":");
                statusText.text = "ONLINE: " + p[1] + " | ROOMS: " + p[2];
                statusText.color = 0xFF00FF00;
            }
            s.socket.close();
        });
    } catch(e:Dynamic) {
        statusText.text = "SERVER: OFFLINE";
        statusText.color = 0xFFFF0000;
    }
}

function fetchLeaderboard() {
    try {
        connection = new Socket();
        connection.connect(new Host(SERVER_IP), 8080);
        connection.write("GET_LEADERBOARD\n");
        new FlxTimer().start(0.2, function(tmr) {
            connection.socket.setBlocking(false);
            connectionEstablished = true;
            logServer("-> FETCHED RANKINGS");
        });
    } catch(e:Dynamic) { lobbyText.text = "OFFLINE!"; }
}

function processNetwork() {
    if (connection == null || !connectionEstablished) return;
    try {
        var data = connection.read();
        if (data == null || data == "") return;
        netBuffer += data;
        if (netBuffer.indexOf("\n") == -1) return;

        var msgs = netBuffer.split("\n");
        netBuffer = msgs.pop(); 

        for (msg in msgs) {
            if (msg == "") continue;
            logServer("<- " + msg);
            var p = msg.split(":");
            switch(p[0]) {
                case "START":
                    FlxG.random.initialSeed = Std.parseInt(p[1]);
                    opponentName = p[2];
                    startMultiplayer();
                case "LEADERBOARD": renderLeaderboard(p[1]);
                case "Y": p2Bird.y = Std.parseFloat(p[1]);
                case "JUMP": 
                    p2Bird.velocity.y = jumpForce;
                    spawnVFX(p2Bird, 0xFFFF3333);
                case "SCORE": p2Score = Std.parseInt(p[1]); updateScoreUI();
                case "BOOSTER": spawnBooster(Std.parseInt(p[1]), FlxG.width + 50, Std.parseFloat(p[2]), false);
                case "EMOTE": showEmote(p2EmoteText, p[1]);
                case "DEAD":
                    p2Dead = true;
                    spawnVFX(p2Bird, 0xFFFF3333);
                case "OPPONENT_DISCONNECTED":
                    if (gameState == "PLAYING") { lobbyText.text = opponentName + " LEFT!"; gameOver(); }
            }
        }
    } catch(e:Dynamic) {}
}

// --- STATE & INPUT ---

function switchState(s:String) {
    gameState = s; typedInput = ""; typingText.text = ""; leaderboardGroup.clear();
    switch(s) {
        case "NICKNAME": lobbyText.text = "ENTER NICKNAME";
        case "MENU": lobbyText.text = "[1] SOLO  [2] MULTI  [3] RANKS";
        case "ROOM_INPUT": lobbyText.text = "ENTER 4-CHAR ROOM CODE";
        case "LEADERBOARD": lobbyText.text = "LOADING..."; fetchLeaderboard();
    }
}

function handleTyping(max:Int) {
    var key = FlxG.keys.firstJustPressed();
    if (FlxG.keys.justPressed.BACKSPACE && typedInput.length > 0) {
        typedInput = typedInput.substring(0, typedInput.length - 1);
    } else if (typedInput.length < max) {
        var abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ";
        if (key >= 65 && key <= 90) typedInput += abc.charAt(key - 65);
        else if (key >= 48 && key <= 57) typedInput += abc.charAt(key - 48 + 26);
        else if (key == 32) typedInput += " ";
    }
    typingText.text = "> " + typedInput + (FlxG.game.ticks % 40 < 20 ? "_" : "");
}

// --- GAMEPLAY ---

function update(elapsed:Float) {
    emoteText.setPosition(bird.x - 80, bird.y - 50);
    p2EmoteText.setPosition(p2Bird.x - 80, p2Bird.y - 50);

    switch(gameState) {
        case "NICKNAME":
            handleTyping(12);
            if (FlxG.keys.justPressed.ENTER && typedInput.length > 1) {
                myNickname = typedInput;
                FlxG.save.data.flappyNickname = myNickname; FlxG.save.flush();
                switchState("MENU");
            }
        case "MENU":
            if (FlxG.keys.justPressed.ONE) startGame(false);
            if (FlxG.keys.justPressed.TWO) switchState("ROOM_INPUT");
            if (FlxG.keys.justPressed.THREE) switchState("LEADERBOARD");
        case "ROOM_INPUT":
            handleTyping(4);
            if (FlxG.keys.justPressed.ENTER && typedInput.length == 4) connectToServer(typedInput);
        case "PLAYING": updatePlaying(elapsed);
        case "DEAD": if (FlxG.keys.justPressed.ENTER) FlxG.resetState();
    }
    if (isMultiplayer) processNetwork();
}

function updatePlaying(elapsed:Float) {
    if (inCountdown) return;

    if (!iAmDead) {
        if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER) {
            bird.velocity.y = jumpForce;
            spawnVFX(bird, 0xFFFFEE00);
            if (isMultiplayer) safeSend("JUMP\n");
        }
        if (FlxG.keys.justPressed.Q) sendEmote(":)");
        if (FlxG.keys.justPressed.W) sendEmote("GG");

        bird.angle = FlxMath.lerp(bird.angle, (bird.velocity.y < 0) ? -15 : 45, elapsed * 10);
        if (bird.y > FlxG.height || bird.y < 0) killMe();

        if (!isGhost && !hasShield) FlxG.overlap(bird, pipes, function(b, p) { killMe(); });
        FlxG.overlap(bird, powerups, function(b, pu) { handlePowerup(pu); });
        
        if (isMultiplayer && FlxG.game.ticks % 3 == 0) safeSend("Y:" + bird.y + "\n");
    }

    pipes.forEachAlive(function(p:FlxSprite) {
        p.velocity.x = pipeSpeed;
        if (p.x < -100) p.kill();
        if (p.ID == 0 && p.x + p.width < bird.x && !iAmDead) {
            p.ID = 99; score++; 
            updateScoreUI();
            checkDifficulty();
            if (isMultiplayer) safeSend("SCORE:" + score + "\n");
        }
    });

    powerups.forEachAlive(function(pu) { pu.velocity.x = pipeSpeed; });
    if (iAmDead && (isMultiplayer ? p2Dead : true)) gameOver();
}

function spawnVFX(obj:FlxSprite, col:Int) {
    var trail = new FlxSprite(obj.x, obj.y).makeGraphic(40, 40, col);
    trail.alpha = 0.6;
    vfxGroup.add(trail);
    FlxTween.tween(trail, {alpha: 0, "scale.x": 0.2, "scale.y": 0.2}, 0.5, {
        onComplete: function(twn) { trail.destroy(); }
    });
}

function spawnPipe() {
    var pipeY = FlxG.random.float(100, FlxG.height - pipeGap - 100);
    var pCol = getPipeColor();
    var bPipe = pipes.recycle(FlxSprite); bPipe.makeGraphic(80, FlxG.height, pCol); bPipe.reset(FlxG.width, pipeY + pipeGap); bPipe.ID = 0; pipes.add(bPipe);
    var tPipe = pipes.recycle(FlxSprite); tPipe.makeGraphic(80, FlxG.height, pCol); tPipe.reset(FlxG.width, pipeY - FlxG.height); tPipe.ID = 1; pipes.add(tPipe);

    if (FlxG.random.bool(20)) {
        var type = FlxG.random.int(1, 4);
        spawnBooster(type, FlxG.width + 100, pipeY + (pipeGap / 2) - 20, true);
    }
}

function spawnBooster(type:Int, x:Float, y:Float, send:Bool) {
    var p = powerups.recycle(FlxSprite);
    var colors = [0xFFFFD700, 0xFF00FFFF, 0xFFFF00FF, 0xFF00FF00];
    p.makeGraphic(35, 35, colors[type-1]);
    p.reset(x, y); p.ID = type; powerups.add(p);
    if (send && isMultiplayer) safeSend("BOOSTER:" + type + ":" + y + "\n");
}

function handlePowerup(pu:FlxSprite) {
    if (pu.ID == 1) { score += 5; logServer("BOOST: POINTS"); }
    else if (pu.ID == 2) { hasShield = true; bird.alpha = 0.5; logServer("BOOST: SHIELD"); new FlxTimer().start(5, function(t) { hasShield = false; bird.alpha = 1; }); }
    else if (pu.ID == 3) { pipeSpeed = -650; logServer("BOOST: SPEED CHAOS"); new FlxTimer().start(5, function(t) { pipeSpeed = -300; }); }
    else if (pu.ID == 4) { isGhost = true; bird.color = 0x888888; logServer("BOOST: GHOST"); new FlxTimer().start(4, function(t) { isGhost = false; bird.color = 0xFFFFFF; }); }
    pu.kill(); updateScoreUI();
    if (isMultiplayer) safeSend("SCORE:" + score + "\n");
}

function sendEmote(emote:String) { showEmote(emoteText, emote); if (isMultiplayer) safeSend("EMOTE:" + emote + "\n"); }
function showEmote(txt:FlxText, emote:String) { txt.text = emote; txt.alpha = 1; FlxTween.tween(txt, {alpha: 0}, 1.5, {startDelay: 1}); }

function killMe() {
    if (iAmDead) return;
    iAmDead = true; bird.velocity.x = pipeSpeed; bird.acceleration.y = gravity;
    if (isMultiplayer) { safeSend("DEAD\n"); safeSend("SUBMIT_SCORE:" + score + "\n"); }
}

function gameOver() {
    if (gameState == "DEAD") return;
    gameState = "DEAD";
    if (pipeTimer != null) pipeTimer.cancel();
    pipes.forEach(function(p) { p.velocity.x = 0; });
    var overText = new FlxText(0, 0, FlxG.width, "GAME OVER\nSCORE: " + score, 64);
    overText.setFormat(Paths.font(currentFont), 64, 0xFFFF0000, "center", 4, 0xFF000000);
    overText.screenCenter(); overText.cameras = [uiCam]; add(overText);
}

function startGame(multi:Bool) {
    isMultiplayer = multi; gameState = "PLAYING";
    titleText.visible = false; lobbyText.visible = false; typingText.visible = false;
    scoreText.visible = true; levelText.visible = true; bird.acceleration.y = gravity;
    currentLevel = 1; pipeSpeed = -300; pipeGap = 230; pipeInterval = 1.6;
    if (!multi) startPipeTimer();
}

function connectToServer(code:String) {
    try {
        connection = new Socket();
        connection.connect(new Host(SERVER_IP), 8080);
        connection.socket.setBlocking(false);
        connectionEstablished = true;
        safeSend("JOIN_ROOM:" + code + ":" + myNickname + "\n");
        gameState = "WAITING_FOR_OPPONENT";
        lobbyText.text = "WAITING FOR P2...";
    } catch(e:Dynamic) { switchState("MENU"); }
}

function startMultiplayer() { p2Bird.visible = true; p2Bird.acceleration.y = gravity; startCountdown(); }

function startCountdown() {
    inCountdown = true;
    var count = 3;
    var t = new FlxText(0, 0, FlxG.width, "3", 120);
    t.setFormat(Paths.font(currentFont), 120, 0xFFFFFFFF, "center", 4, 0xFF000000);
    t.screenCenter(); t.cameras = [uiCam]; add(t);
    new FlxTimer().start(1, function(tmr) {
        count--;
        if (count <= 0) { t.destroy(); inCountdown = false; startGame(true); startPipeTimer(); }
        else t.text = Std.string(count);
    }, 3);
}

function startPipeTimer() { 
    if (pipeTimer != null) pipeTimer.cancel();
    pipeTimer = new FlxTimer().start(pipeInterval, function(tmr) { if (gameState == "PLAYING" && !inCountdown) spawnPipe(); }, 0); 
}

function updateScoreUI() {
    if (isMultiplayer) scoreText.text = myNickname + ": " + score + " | " + opponentName + ": " + p2Score;
    else scoreText.text = "SCORE: " + score;
}

function renderLeaderboard(json:String) {
    var board:Array<Dynamic> = haxe.Json.parse(json);
    var startY = FlxG.height * 0.35;
    for (i in 0...board.length) {
        var entry = new FlxText(0, startY + (i * 35), FlxG.width, (i+1) + ". " + board[i].name + " - " + board[i].score, 24);
        entry.setFormat(Paths.font(currentFont), 24, 0xFFFFFFFF, "center", 2, 0xFF000000);
        entry.cameras = [uiCam]; leaderboardGroup.add(entry);
    }
}

function safeSend(m:String) { if (connectionEstablished) try { connection.write(m); } catch(e:Dynamic) { logServer("SEND FAIL"); } }
function destroy() { if (connection != null) try { connection.socket.close(); } catch(e:Dynamic) {} }