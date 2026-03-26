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
import sys.net.Host;
import funkin.backend.system.net.Socket;

/**
 * FLAPPY MULTIPLAYER BATTLE ROYALE v4.0
 * Clean rewrite with organized networking.
 */

// ══════════════════════════════════════
//  GAME STATE
// ══════════════════════════════════════

var gameState:String = "NICKNAME";
var inCountdown:Bool = false;

// ══════════════════════════════════════
//  ENTITIES
// ══════════════════════════════════════

var bird:FlxSprite;
var pipes:FlxTypedGroup<FlxSprite>;
var powerups:FlxTypedGroup<FlxSprite>;
var vfxGroup:FlxTypedGroup<FlxSprite>;
var playerGroup:FlxTypedGroup<FlxSprite>;
var emoteGroup:FlxTypedGroup<FlxText>;
var crown:FlxSprite;
var sky:FlxBackdrop;
var skyFar:FlxBackdrop;
var ground:FlxSprite;
var groundLine:FlxSprite;
var uiCam:FlxCamera;
var titleGlow:Float = 0;
var scoreBounce:Float = 1.0;

// ══════════════════════════════════════
//  MULTIPLAYER DATA
// ══════════════════════════════════════

var playerMap:Dynamic = {};
var scoreMap:Dynamic = {};
var deadMap:Dynamic = {};
var emoteMap:Dynamic = {};
var activePlayers:Array<String> = [];
var currentLeader:String = "";

// ══════════════════════════════════════
//  UI
// ══════════════════════════════════════

var titleText:FlxText;
var scoreText:FlxText;
var lobbyText:FlxText;
var typingText:FlxText;
var statusText:FlxText;
var levelText:FlxText;
var debugLog:FlxText;
var myEmoteText:FlxText;
var leaderboardGroup:FlxTypedGroup<FlxText>;
var lobbySlotGroup:FlxTypedGroup<FlxText>;
var playerSidebar:FlxTypedGroup<FlxText>;
var lobbyPlayers:Array<String> = [];
var lobbyRoomText:FlxText;
var playerColors:Array<Int> = [0xFFFFEE00, 0xFF00CCFF, 0xFFFF6699, 0xFF66FF66, 0xFFFF9933, 0xFFCC66FF];

// ══════════════════════════════════════
//  GAMEPLAY TUNING
// ══════════════════════════════════════

var score:Int = 0;
var currentLevel:Int = 1;
var pipeGap:Float = 230;
var pipeInterval:Float = 1.6;
var pipeSpeed:Float = -300;
var gravity:Float = 1500;
var jumpForce:Float = -500;
var currentFont:String = "vcr.ttf";

var hasShield:Bool = false;
var isGhost:Bool = false;
var pipeTimer:FlxTimer;

// ══════════════════════════════════════
//  NETWORK
// ══════════════════════════════════════

var SERVER_IP:String = "144.21.35.78";
var SERVER_PORT:Int = 8080;
var connection:Socket;
var isMultiplayer:Bool = false;
var iAmDead:Bool = false;
var netConnected:Bool = false;
var netBuffer:String = "";
var myNickname:String = "Player";
var typedInput:String = "";
var activeRoomCode:String = "";
var pollTimer:FlxTimer;

// ══════════════════════════════════════
//  CREATE
// ══════════════════════════════════════

function create() {
    if (FlxG.save.data.flappyNickname != null) myNickname = FlxG.save.data.flappyNickname;
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;

    FlxG.camera.bgColor = 0xFF87CEEB;

    uiCam = new FlxCamera();
    uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    // Far sky layer (parallax)
    skyFar = new FlxBackdrop(Paths.image('menus/flappy/sky'), 0x01, 0, 0);
    skyFar.scale.set(2.5, 2.5);
    skyFar.updateHitbox();
    skyFar.y = FlxG.height - skyFar.height - 40;
    skyFar.velocity.x = -15;
    skyFar.alpha = 0.4;
    add(skyFar);

    // Near sky layer
    sky = new FlxBackdrop(Paths.image('menus/flappy/sky'), 0x01, 0, 0);
    sky.scale.set(2, 2);
    sky.updateHitbox();
    sky.y = FlxG.height - sky.height;
    sky.velocity.x = -40;
    add(sky);

    // Ground strip
    ground = new FlxSprite(0, FlxG.height - 4).makeGraphic(FlxG.width, 4, 0xFF4A8C3F);
    add(ground);
    groundLine = new FlxSprite(0, FlxG.height - 6).makeGraphic(FlxG.width, 2, 0xFF5BAF50);
    add(groundLine);

    pipes = new FlxTypedGroup(); add(pipes);
    powerups = new FlxTypedGroup(); add(powerups);
    vfxGroup = new FlxTypedGroup(); add(vfxGroup);
    playerGroup = new FlxTypedGroup(); add(playerGroup);
    emoteGroup = new FlxTypedGroup(); add(emoteGroup);

    bird = new FlxSprite(300, FlxG.height / 2).makeGraphic(40, 40, 0xFFFFEE00);
    bird.antialiasing = true;
    add(bird);

    crown = new FlxSprite(0, 0).makeGraphic(20, 10, 0xFFFFD700);
    crown.visible = false;
    crown.antialiasing = true;
    add(crown);

    leaderboardGroup = new FlxTypedGroup(); add(leaderboardGroup);
    lobbySlotGroup = new FlxTypedGroup(); add(lobbySlotGroup);
    playerSidebar = new FlxTypedGroup(); add(playerSidebar);
    setupUI();

    goToState(myNickname == "Player" ? "NICKNAME" : "MENU");

    fetchServerStatus();
    new FlxTimer().start(15, function(t) { fetchServerStatus(); }, 0);
}

// ══════════════════════════════════════
//  UI SETUP
// ══════════════════════════════════════

function setupUI() {
    titleText = makeText(0, 80, FlxG.width, "FLAPPY ROYALE", 84, 0xFFFFEE00);
    scoreText = makeText(0, 30, FlxG.width, "0", 40, 0xFFFFFFFF); scoreText.visible = false;
    levelText = makeText(0, 75, FlxG.width, "LEVEL 1", 28, 0xFF00FFCC); levelText.visible = false;
    statusText = makeText(20, 16, 400, "SERVER: CHECKING...", 16, 0xFFFFFFFF); statusText.alignment = "left";
    debugLog = makeText(FlxG.width - 320, 16, 300, "", 12, 0xFF00FF00); debugLog.alignment = "right";
    lobbyText = makeText(0, FlxG.height * 0.65, FlxG.width, "", 28, 0xFFFFEE00);
    typingText = makeText(0, FlxG.height * 0.8, FlxG.width, "", 42, 0xFFFFFFFF);

    myEmoteText = new FlxText(0, 0, 200, "", 32);
    myEmoteText.setFormat(Paths.font(currentFont), 32, 0xFFFFFFFF, "center", 2, 0xFF000000);
    myEmoteText.cameras = [uiCam];
    add(myEmoteText);

    currentLeader = myNickname;

    lobbyRoomText = makeText(0, FlxG.height * 0.22, FlxG.width, "", 22, 0xFF88CCFF);
    lobbyRoomText.visible = false;
}

function makeText(x:Float, y:Float, w:Float, text:String, size:Int, color:Int):FlxText {
    var t = new FlxText(x, y, w, text, size);
    t.setFormat(Paths.font(currentFont), size, color, "center", 2, 0xFF000000);
    t.cameras = [uiCam];
    add(t);
    return t;
}

// ══════════════════════════════════════
//  STATE MACHINE
// ══════════════════════════════════════

function goToState(s:String) {
    gameState = s;
    typedInput = "";
    typingText.text = "";
    leaderboardGroup.clear();
    lobbySlotGroup.clear();
    playerSidebar.clear();
    lobbyRoomText.visible = false;

    // Disconnect when going back to menu screens - only then clear player list
    if (s == "NICKNAME" || s == "MENU" || s == "LEADERBOARD") {
        netDisconnect();
        isMultiplayer = false;
        lobbyPlayers = [];
        resetMultiplayerData();
    }

    titleText.visible = (s == "NICKNAME" || s == "MENU" || s == "ROOM_INPUT" || s == "LEADERBOARD");
    lobbyText.visible = true;
    typingText.visible = (s == "NICKNAME" || s == "ROOM_INPUT");
    scoreText.visible = false;
    levelText.visible = false;

    switch(s) {
        case "NICKNAME": lobbyText.text = "ENTER NICKNAME";
        case "MENU": lobbyText.text = "[1] SOLO  [2] MULTI (6P)  [3] RANKS";
        case "ROOM_INPUT": lobbyText.text = "ENTER 4-CHAR ROOM CODE";
        case "LEADERBOARD": lobbyText.text = "LOADING..."; fetchLeaderboard();
    }
}

function resetMultiplayerData() {
    playerMap = {};
    scoreMap = {};
    deadMap = {};
    emoteMap = {};
    activePlayers = [];
    currentLeader = myNickname;
}

// ══════════════════════════════════════
//  NETWORK API
// ══════════════════════════════════════

function netConnect(roomCode:String, nickname:String) {
    netDisconnect();
    try {
        connection = new Socket();
        connection.connect(new Host(SERVER_IP), SERVER_PORT);
        netConnected = true;
        netBuffer = "";
        connection.socket.setBlocking(false);
        log("MP CONN OK");
        // Delay send to ensure connection is fully established
        new FlxTimer().start(0.3, function(t) {
            try {
                connection.write("JOIN_ROOM:" + roomCode + ":" + nickname + "\n");
                log("JOIN SENT");
                // Start timer-based polling since read() doesn't work from update loop
                startNetPollTimer();
            } catch(e:Dynamic) { log("JOIN SEND FAIL: " + e); }
        });
    } catch(e:Dynamic) {
        netConnected = false;
        lobbyText.text = "CONNECTION FAILED!";
        log("MP CONN FAIL: " + e);
        new FlxTimer().start(2, function(t) { goToState("MENU"); });
    }
}

function netDisconnect() {
    if (pollTimer != null) { pollTimer.cancel(); pollTimer = null; }
    if (connection != null) {
        try { connection.destroy(); } catch(e:Dynamic) {}
        connection = null;
    }
    netConnected = false;
    netBuffer = "";
}

function netSend(msg:String) {
    if (!netConnected || connection == null) return;
    try { connection.write(msg + "\n"); } catch(e:Dynamic) { log("SEND FAIL"); }
}

function netPoll() {
    if (!netConnected || connection == null) return;
    try {
        var sock = connection.socket;
        var maxReads = 20;
        var count = 0;
        while (count < maxReads) {
            count++;
            try {
                var line = sock.input.readLine();
                if (line == null) break;
                line = StringTools.trim(line);
                if (line.length == 0) continue;
                log("RX: " + line.substring(0, 25));
                // Handle server broadcast \\n encoding (literal backslash + n)
                var sublines = line.split("\\n");
                for (si in 0...sublines.length) {
                    var sub = StringTools.trim(sublines[si]);
                    if (sub.length > 0) processNetLine(sub);
                }
            } catch(inner:Dynamic) { break; }
        }
    } catch(e:Dynamic) {}
}

function startNetPollTimer() {
    if (pollTimer != null) pollTimer.cancel();
    pollTimer = new FlxTimer().start(0.2, function(tmr) {
        netPoll();
    }, 0);
}

function processNetLine(line:String) {
    log("< " + line.substring(0, 30));
    var parts = line.split(":");
    var cmd = parts[0];
    parts.splice(0, 1);
    handleServerMessage(cmd, parts);
}

/** One-shot socket for status/leaderboard (doesn't touch game connection) */
function netOneShot(msg:String, delaySeconds:Float, callback:Dynamic) {
    try {
        var s = new Socket();
        log("SOCK OK");
        s.connect(new Host(SERVER_IP), SERVER_PORT);
        log("CONN OK");
        s.socket.setBlocking(false);
        log("NONBLOCK OK");
        // Write after a short delay to ensure connection is established
        new FlxTimer().start(0.5, function(tmr1) {
            try {
                s.write(msg + "\n");
                log("WRITE OK");
            } catch(e:Dynamic) { log("WRITE ERR: " + e); }
            // Read after another delay
            new FlxTimer().start(1.5, function(tmr2) {
                try {
                    var d = s.read();
                    log("READ GOT: " + d);
                    if (d != null && d.length > 0) {
                        // Strip trailing newlines and take first line
                        var lines = d.split("\n");
                        var firstLine = "";
                        for (li in 0...lines.length) {
                            var trimmed = StringTools.trim(lines[li]);
                            if (trimmed.length > 0) { firstLine = trimmed; break; }
                        }
                        if (firstLine.length > 0) callback(firstLine);
                        else callback(null);
                    } else {
                        log("RESP null");
                        callback(null);
                    }
                } catch(e:Dynamic) {
                    log("READ ERR: " + e);
                    callback(null);
                }
                try { s.destroy(); } catch(e2:Dynamic) {}
            }, 1);
        }, 1);
    } catch(e:Dynamic) {
        log("CONN ERR: " + e);
        callback(null);
    }
}

// ══════════════════════════════════════
//  SERVER MESSAGE HANDLER
// ══════════════════════════════════════

function handleServerMessage(cmd:String, args:Array<String>) {
    log("<- " + cmd);

    switch(cmd) {
        case "WAITING_FOR_HOST":
            gameState = "LOBBY";
            addLobbyPlayer(myNickname);
            refreshLobbyUI();

        case "GAME_ALREADY_STARTED":
            lobbyText.text = "GAME IN PROGRESS. SPECTATING...";
            iAmDead = true;
            bird.visible = false;
            beginMultiplayer();

        case "ROOM_FULL":
            lobbyText.text = "ROOM IS FULL (6/6)!";
            new FlxTimer().start(2, function(t) { goToState("MENU"); });

        case "START":
            if (args.length > 0) FlxG.random.initialSeed = Std.parseInt(args[0]);
            beginMultiplayer();

        case "Y":
            if (args.length >= 2) {
                var op = getOpponent(args[1]);
                if (op != null) op.y = Std.parseFloat(args[0]);
            }

        case "JUMP":
            if (args.length >= 1) {
                var op = getOpponent(args[0]);
                if (op != null) { op.velocity.y = jumpForce; spawnVFX(op, op.color); }
            }

        case "SCORE":
            if (args.length >= 2) {
                Reflect.setField(scoreMap, args[1], Std.parseInt(args[0]));
                refreshScoreUI();
                updateCrown();
            }

        case "BOOSTER":
            if (args.length >= 2) spawnBooster(Std.parseInt(args[0]), FlxG.width + 50, Std.parseFloat(args[1]), false);

        case "EMOTE":
            if (args.length >= 2) showRemoteEmote(args[1], args[0]);

        case "DEAD":
            if (args.length >= 1) {
                var nick = args[0];
                Reflect.setField(deadMap, nick, true);
                var op = getOpponent(nick);
                if (op != null) { op.color = 0xFF444444; spawnVFX(op, 0xFF444444); }
                refreshPlayerSidebar();
                checkBattleRoyaleEnd();
            }

        case "PLAYER_LIST":
            // Server could send full list; handle if added later
            if (args.length > 0) {
                for (pi in 0...args.length) addLobbyPlayer(args[pi]);
                refreshLobbyUI();
            }

        case "CHAT":
            var chatMsg = args.join(":");
            log("[CHAT] " + chatMsg);
            // Track joins and leaves in lobby
            if (chatMsg.indexOf("JOINED THE BATTLE") != -1) {
                var joinNick = chatMsg.split(" JOINED")[0];
                joinNick = StringTools.trim(joinNick);
                addLobbyPlayer(joinNick);
                refreshLobbyUI();
            } else if (chatMsg.indexOf("DISCONNECTED") != -1) {
                var leaveNick = chatMsg.split(" DISCONNECTED")[0];
                leaveNick = StringTools.trim(leaveNick);
                lobbyPlayers.remove(leaveNick);
                refreshLobbyUI();
            }
    }
}

// ══════════════════════════════════════
//  LOBBY UI
// ══════════════════════════════════════

function addLobbyPlayer(nick:String) {
    if (nick.length == 0) return;
    for (li in 0...lobbyPlayers.length) {
        if (lobbyPlayers[li] == nick) return;
    }
    lobbyPlayers.push(nick);
    sortLobbyPlayers();
}

function sortLobbyPlayers() {
    // Sort alphabetically so all clients see the same order; host (self) always first
    lobbyPlayers.sort(function(a:String, b:String):Int {
        if (a == myNickname) return -1;
        if (b == myNickname) return 1;
        if (a < b) return -1;
        if (a > b) return 1;
        return 0;
    });
}

function getPlayerColor(nick:String):Int {
    for (i in 0...lobbyPlayers.length) {
        if (lobbyPlayers[i] == nick) return playerColors[i % playerColors.length];
    }
    return 0xFFFFFFFF;
}

function refreshPlayerSidebar() {
    playerSidebar.clear();
    if (!isMultiplayer || lobbyPlayers.length <= 1) return;

    var startY = 120;
    var slotH = 28;

    // Header
    var header = new FlxText(FlxG.width - 220, startY - 30, 210, "PLAYERS", 16);
    header.setFormat(Paths.font(currentFont), 16, 0xFF888888, "right", 1, 0xFF000000);
    header.cameras = [uiCam];
    playerSidebar.add(header);

    for (si in 0...lobbyPlayers.length) {
        var nick = lobbyPlayers[si];
        var col = getPlayerColor(nick);
        var isDead = Reflect.field(deadMap, nick);
        var isMe = nick == myNickname;
        var scr = isMe ? score : (Reflect.field(scoreMap, nick) != null ? Reflect.field(scoreMap, nick) : 0);
        var prefix = isMe ? "> " : "  ";
        var suffix = isDead ? "  [X]" : "";
        var label = prefix + nick + "  " + scr + suffix;

        var slot = new FlxText(FlxG.width - 220, startY + (si * slotH), 210, label, 18);
        slot.setFormat(Paths.font(currentFont), 18, isDead ? 0xFF666666 : col, "right", 1, 0xFF000000);
        slot.alpha = isDead ? 0.5 : (isMe ? 1.0 : 0.8);
        slot.cameras = [uiCam];
        playerSidebar.add(slot);
    }
}

function refreshLobbyUI() {
    lobbySlotGroup.clear();
    titleText.visible = false;
    lobbyRoomText.visible = true;
    lobbyRoomText.text = "ROOM: " + activeRoomCode + "  (" + lobbyPlayers.length + "/6)";

    var startY = FlxG.height * 0.28;
    var slotH = 55;

    for (si in 0...6) {
        var slotY = startY + (si * slotH);
        var hasPlayer = si < lobbyPlayers.length;
        var nick = hasPlayer ? lobbyPlayers[si] : "- EMPTY -";
        var col = hasPlayer ? playerColors[si % playerColors.length] : 0xFF555555;
        var isMe = hasPlayer && lobbyPlayers[si] == myNickname;
        var label = (isMe ? "> " : "  ") + (si + 1) + ".  " + nick.toUpperCase() + (isMe ? "  (YOU)" : "");

        var slot = new FlxText(0, slotY, FlxG.width, label, 30);
        slot.setFormat(Paths.font(currentFont), 30, col, "center", 2, 0xFF000000);
        slot.cameras = [uiCam];
        if (hasPlayer) {
            slot.alpha = 0;
            FlxTween.tween(slot, {alpha: 1}, 0.3, {startDelay: si * 0.08, ease: FlxEase.quadOut});
        } else {
            slot.alpha = 0.4;
        }
        lobbySlotGroup.add(slot);
    }

    lobbyText.text = "[ENTER] START GAME  |  [ESC] LEAVE";
}

// ══════════════════════════════════════
//  OPPONENT MANAGEMENT
// ══════════════════════════════════════

function getOpponent(nick:String):FlxSprite {
    if (activePlayers.indexOf(nick) == -1) {
        activePlayers.push(nick);
        addLobbyPlayer(nick);
        log("NEW PLAYER: " + nick);

        var op = new FlxSprite(300, FlxG.height / 2).makeGraphic(40, 40, 0xFFFFFFFF);
        op.color = getPlayerColor(nick);
        op.alpha = 0.5;
        playerGroup.add(op);

        Reflect.setField(playerMap, nick, op);
        Reflect.setField(scoreMap, nick, 0);
        Reflect.setField(deadMap, nick, false);

        var eTxt = new FlxText(0, 0, 200, "", 32);
        eTxt.setFormat(Paths.font(currentFont), 32, op.color, "center", 2, 0xFF000000);
        eTxt.cameras = [uiCam];
        emoteGroup.add(eTxt);
        Reflect.setField(emoteMap, nick, eTxt);

        refreshScoreUI();
    }
    return Reflect.field(playerMap, nick);
}

// ══════════════════════════════════════
//  CROWN
// ══════════════════════════════════════

function updateCrown() {
    var highest = score;
    var leader = myNickname;

    for (i in 0...activePlayers.length) {
        var nick = activePlayers[i];
        var s = Reflect.field(scoreMap, nick);
        if (!Reflect.field(deadMap, nick) && s > highest) { highest = s; leader = nick; }
    }

    currentLeader = leader;
    crown.visible = !(iAmDead && leader == myNickname);
}

// ══════════════════════════════════════
//  INPUT: TYPING
// ══════════════════════════════════════

function handleTyping(max:Int) {
    if (FlxG.keys.justPressed.BACKSPACE && typedInput.length > 0) {
        typedInput = typedInput.substring(0, typedInput.length - 1);
    } else if (typedInput.length < max) {
        var key = FlxG.keys.firstJustPressed();
        var abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        if (key >= 65 && key <= 90) typedInput += abc.charAt(key - 65);
        else if (key >= 48 && key <= 57) typedInput += abc.charAt(key - 48 + 26);
    }
    typingText.text = "> " + typedInput + (FlxG.game.ticks % 40 < 20 ? "_" : "");
}

// ══════════════════════════════════════
//  UPDATE (MAIN LOOP)
// ══════════════════════════════════════

function update(elapsed:Float) {
    // netPoll is now timer-driven, no need to call from update

    // Title glow animation
    if (titleText.visible) {
        titleGlow += elapsed * 2.5;
        var pulse = Math.sin(titleGlow) * 0.15 + 1.0;
        titleText.scale.set(pulse, pulse);
    }

    // Score bounce decay
    if (scoreBounce > 1.0) {
        scoreBounce = FlxMath.lerp(scoreBounce, 1.0, elapsed * 8);
        scoreText.scale.set(scoreBounce, scoreBounce);
    }

    // Emote positions
    myEmoteText.setPosition(bird.x - 80, bird.y - 50);
    for (i in 0...activePlayers.length) {
        var nick = activePlayers[i];
        var op = Reflect.field(playerMap, nick);
        var eT = Reflect.field(emoteMap, nick);
        if (eT != null && op != null) eT.setPosition(op.x - 80, op.y - 50);
    }

    // Crown tracking
    if (crown.visible) {
        if (currentLeader == myNickname) {
            crown.setPosition(bird.x + 10, bird.y - 15);
        } else {
            var op = Reflect.field(playerMap, currentLeader);
            if (op != null) crown.setPosition(op.x + 10, op.y - 15);
        }
    }

    // Admin nuke
    if (FlxG.keys.justPressed.F12 && isMultiplayer) { log("ADMIN NUKE"); netSend("NUKE_SERVER:flappyAdmin2026"); }

    // Pause
    if (FlxG.keys.justPressed.ESCAPE && gameState == "PLAYING") {
        openSubState(new ModSubState("FlappyPause"));
        return;
    }

    switch(gameState) {
        case "NICKNAME": updateNickname();
        case "MENU": updateMenu();
        case "ROOM_INPUT": updateRoomInput();
        case "WAITING_FOR_OPPONENT": updateWaiting();
        case "LOBBY": updateLobby();
        case "PLAYING": updatePlaying(elapsed);
        case "DEAD": updateDead();
        case "LEADERBOARD": updateLeaderboard();
    }
}

function updateNickname() {
    handleTyping(12);
    if (FlxG.keys.justPressed.ENTER && typedInput.length > 1) {
        myNickname = typedInput;
        FlxG.save.data.flappyNickname = myNickname;
        FlxG.save.flush();
        goToState("MENU");
    }
}

function updateMenu() {
    if (FlxG.keys.justPressed.ONE) startSolo();
    if (FlxG.keys.justPressed.TWO) goToState("ROOM_INPUT");
    if (FlxG.keys.justPressed.THREE) goToState("LEADERBOARD");
}

function updateRoomInput() {
    handleTyping(4);
    if (FlxG.keys.justPressed.ENTER && typedInput.length == 4) {
        activeRoomCode = typedInput;
        lobbyText.text = "JOINING...";
        netConnect(activeRoomCode, myNickname);
        isMultiplayer = true;
        gameState = "WAITING_FOR_OPPONENT";
    }
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU");
}

function updateWaiting() {
    if (FlxG.keys.justPressed.ENTER) netSend("START_GAME");
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU");
}

function updateLobby() {
    if (FlxG.keys.justPressed.ENTER) netSend("START_GAME");
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU");
}

function updateDead() {
    if (FlxG.keys.justPressed.ENTER) FlxG.resetState();
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU");
}

function updateLeaderboard() {
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU");
}

// ══════════════════════════════════════
//  GAMEPLAY
// ══════════════════════════════════════

function updatePlaying(elapsed:Float) {
    if (inCountdown) return;

    if (!iAmDead) {
        if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.UP) {
            bird.velocity.y = jumpForce;
            spawnVFX(bird, 0xFFFFEE00);
            if (isMultiplayer) netSend("JUMP");
        }

        if (FlxG.keys.justPressed.Q) sendEmote(":)");
        if (FlxG.keys.justPressed.W) sendEmote("GG");
        if (FlxG.keys.justPressed.E) sendEmote("RIP");

        bird.angle = FlxMath.lerp(bird.angle, (bird.velocity.y < 0) ? -15 : 45, elapsed * 10);
        if (bird.y > FlxG.height || bird.y < 0) killBird();

        if (!isGhost && !hasShield) FlxG.overlap(bird, pipes, function(b, p) { killBird(); });
        FlxG.overlap(bird, powerups, function(b, pu) { collectPowerup(pu); });

        if (isMultiplayer && FlxG.game.ticks % 2 == 0) netSend("Y:" + bird.y);
    }

    for (i in 0...activePlayers.length) {
        var nick = activePlayers[i];
        if (!Reflect.field(deadMap, nick)) {
            var op = Reflect.field(playerMap, nick);
            if (op != null) op.angle = FlxMath.lerp(op.angle, (op.velocity.y < 0) ? -15 : 45, elapsed * 10);
        }
    }

    pipes.forEachAlive(function(p:FlxSprite) {
        p.velocity.x = pipeSpeed;
        if (p.x < -100) p.kill();
        if (p.ID == 0 && p.x + p.width < bird.x && !iAmDead) {
            p.ID = 99;
            score++;
            scoreBounce = 1.4;
            refreshScoreUI();
            updateCrown();
            checkDifficulty();
            if (isMultiplayer) netSend("SCORE:" + score);
        }
    });

    powerups.forEachAlive(function(pu) { pu.velocity.x = pipeSpeed; });
}

// ══════════════════════════════════════
//  PIPES & POWERUPS
// ══════════════════════════════════════

function spawnPipe() {
    var pipeY = FlxG.random.float(100, FlxG.height - pipeGap - 100);
    var col = getPipeColor();

    var bot = pipes.recycle(FlxSprite);
    bot.makeGraphic(80, FlxG.height, col);
    bot.reset(FlxG.width, pipeY + pipeGap);
    bot.ID = 0;
    pipes.add(bot);

    var top = pipes.recycle(FlxSprite);
    top.makeGraphic(80, FlxG.height, col);
    top.reset(FlxG.width, pipeY - FlxG.height);
    top.ID = 1;
    pipes.add(top);

    if (FlxG.random.bool(20)) {
        spawnBooster(FlxG.random.int(1, 4), FlxG.width + 100, pipeY + (pipeGap / 2) - 20, true);
    }
}

function getPipeColor():Int {
    if (currentLevel >= 5) return 0xFFFF0000;
    if (currentLevel >= 3) return 0xFF0099FF;
    if (currentLevel >= 2) return 0xFFFF9900;
    return 0xFF22AA22;
}

function spawnBooster(type:Int, x:Float, y:Float, broadcast:Bool) {
    var colors = [0xFFFFD700, 0xFF00FFFF, 0xFFFF00FF, 0xFF00FF00];
    var p = powerups.recycle(FlxSprite);
    p.makeGraphic(35, 35, colors[type - 1]);
    p.reset(x, y);
    p.ID = type;
    powerups.add(p);
    if (broadcast && isMultiplayer) netSend("BOOSTER:" + type + ":" + y);
}

function collectPowerup(pu:FlxSprite) {
    switch(pu.ID) {
        case 1: score += 5;
        case 2: hasShield = true; bird.alpha = 0.5; new FlxTimer().start(5, function(t) { hasShield = false; bird.alpha = 1; });
        case 3: pipeSpeed = -650; new FlxTimer().start(5, function(t) { pipeSpeed = -300 - ((currentLevel - 1) * 35); });
        case 4: isGhost = true; bird.color = 0xFF888888; new FlxTimer().start(4, function(t) { isGhost = false; bird.color = 0xFFFFEE00; });
    }
    pu.kill();
    refreshScoreUI();
    updateCrown();
    if (isMultiplayer) netSend("SCORE:" + score);
}

// ══════════════════════════════════════
//  DIFFICULTY
// ══════════════════════════════════════

function checkDifficulty() {
    var newLevel = Math.floor(score / 10) + 1;
    if (newLevel > currentLevel) {
        currentLevel = newLevel;
        pipeSpeed -= 35;
        pipeGap = Math.max(160, pipeGap - 10);
        pipeInterval = Math.max(0.7, pipeInterval - 0.12);
        restartPipeTimer();

        levelText.text = "LEVEL " + currentLevel;
        levelText.scale.set(2, 2);
        levelText.alpha = 1;
        FlxTween.tween(levelText.scale, {x: 1, y: 1}, 0.6, {ease: FlxEase.elasticOut});
        FlxTween.tween(levelText, {alpha: 0.7}, 1.5, {startDelay: 1});
        FlxG.camera.flash(0x22FFFFFF, 0.3);
        FlxG.camera.shake(0.008, 0.15);
    }
}

// ══════════════════════════════════════
//  VFX & EMOTES
// ══════════════════════════════════════

function spawnVFX(obj:FlxSprite, col:Int) {
    for (vi in 0...3) {
        var size = FlxG.random.int(15, 35);
        var trail = new FlxSprite(obj.x + FlxG.random.float(-10, 10), obj.y + FlxG.random.float(-10, 10)).makeGraphic(size, size, col);
        trail.alpha = 0.7;
        trail.velocity.set(FlxG.random.float(-60, 60), FlxG.random.float(-80, 20));
        vfxGroup.add(trail);
        FlxTween.tween(trail, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.4 + FlxG.random.float(0, 0.3), {
            onComplete: function(twn) { trail.destroy(); }
        });
    }
}

function sendEmote(emote:String) {
    showEmote(myEmoteText, emote);
    if (isMultiplayer) netSend("EMOTE:" + emote);
}

function showRemoteEmote(nick:String, emote:String) {
    if (activePlayers.indexOf(nick) != -1) {
        var txt = Reflect.field(emoteMap, nick);
        if (txt != null) showEmote(txt, emote);
    }
}

function showEmote(txt:FlxText, emote:String) {
    txt.text = emote;
    txt.alpha = 1;
    FlxTween.tween(txt, {alpha: 0}, 1.5, {startDelay: 1});
}

// ══════════════════════════════════════
//  DEATH & GAME OVER
// ══════════════════════════════════════

function killBird() {
    if (iAmDead) return;
    iAmDead = true;
    bird.velocity.x = pipeSpeed;
    bird.acceleration.y = gravity;
    bird.color = 0xFF444444;

    FlxG.camera.shake(0.02, 0.3);
    FlxG.camera.flash(0x55FF0000, 0.3);

    if (isMultiplayer) {
        netSend("DEAD");
        netSend("SUBMIT_SCORE:" + score);
        checkBattleRoyaleEnd();
    } else {
        showGameOver();
    }
}

function checkBattleRoyaleEnd() {
    if (!iAmDead) return;
    for (i in 0...activePlayers.length) {
        if (!Reflect.field(deadMap, activePlayers[i])) {
            lobbyText.text = "SPECTATING REMAINING PLAYERS...";
            lobbyText.visible = true;
            return;
        }
    }
    showGameOver();
}

function showGameOver() {
    if (gameState == "DEAD") return;
    gameState = "DEAD";
    if (pipeTimer != null) pipeTimer.cancel();
    pipes.forEach(function(p) { p.velocity.x = 0; });

    var won = currentLeader == myNickname;
    var result = isMultiplayer ? (won ? "VICTORY ROYALE!" : "ELIMINATED") : "GAME OVER";
    var col = won ? 0xFF00FF00 : 0xFFFF4444;

    // Dark overlay
    var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000);
    overlay.cameras = [uiCam];
    add(overlay);
    FlxTween.color(overlay, 0.5, 0x00000000, 0xAA000000);

    var overText = new FlxText(0, 0, FlxG.width, result, 64);
    overText.setFormat(Paths.font(currentFont), 64, col, "center", 4, 0xFF000000);
    overText.screenCenter();
    overText.y -= 60;
    overText.cameras = [uiCam];
    overText.alpha = 0;
    overText.scale.set(2, 2);
    add(overText);
    FlxTween.tween(overText, {alpha: 1}, 0.4, {ease: FlxEase.quadOut});
    FlxTween.tween(overText.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.elasticOut});

    var scoreInfo = new FlxText(0, 0, FlxG.width, "SCORE: " + score + "\n\n[ENTER] RETRY  [ESC] MENU", 28);
    scoreInfo.setFormat(Paths.font(currentFont), 28, 0xFFFFFFFF, "center", 2, 0xFF000000);
    scoreInfo.screenCenter();
    scoreInfo.y += 30;
    scoreInfo.cameras = [uiCam];
    scoreInfo.alpha = 0;
    add(scoreInfo);
    FlxTween.tween(scoreInfo, {alpha: 1}, 0.5, {startDelay: 0.3, ease: FlxEase.quadOut});
}

// ══════════════════════════════════════
//  GAME START
// ══════════════════════════════════════

function resetGameplay() {
    score = 0;
    currentLevel = 1;
    pipeSpeed = -300;
    pipeGap = 230;
    pipeInterval = 1.6;
    hasShield = false;
    isGhost = false;
}

function startSolo() {
    iAmDead = false;
    isMultiplayer = false;
    resetGameplay();
    enterPlayState();
    restartPipeTimer();
}

function beginMultiplayer() {
    lobbySlotGroup.clear();
    lobbyRoomText.visible = false;
    refreshPlayerSidebar();
    inCountdown = true;
    var count = 3;
    var t = new FlxText(0, 0, FlxG.width, "3", 140);
    t.setFormat(Paths.font(currentFont), 140, 0xFFFFFFFF, "center", 6, 0xFF000000);
    t.screenCenter();
    t.cameras = [uiCam];
    add(t);

    new FlxTimer().start(1, function(tmr) {
        count--;
        if (count <= 0) {
            t.text = "GO!";
            t.color = 0xFF00FF00;
            t.scale.set(1.5, 1.5);
            FlxTween.tween(t, {alpha: 0}, 0.5, {ease: FlxEase.quadIn, onComplete: function(_) { t.destroy(); }});
            FlxG.camera.flash(0x33FFFFFF, 0.3);
            inCountdown = false;
            resetGameplay();
            enterPlayState();
            restartPipeTimer();
        } else {
            t.text = Std.string(count);
            t.scale.set(1.5, 1.5);
            FlxTween.tween(t.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.elasticOut});
            var cols = [0xFFFFEE00, 0xFFFF9900, 0xFFFF4444];
            t.color = cols[3 - count];
        }
    }, 4);
}

function enterPlayState() {
    gameState = "PLAYING";
    titleText.visible = false;
    lobbyText.visible = false;
    typingText.visible = false;
    scoreText.visible = true;
    levelText.visible = true;
    bird.acceleration.y = gravity;
}

function restartPipeTimer() {
    if (pipeTimer != null) pipeTimer.cancel();
    pipeTimer = new FlxTimer().start(pipeInterval, function(tmr) {
        if (gameState == "PLAYING" && !inCountdown) spawnPipe();
    }, 0);
}

// ══════════════════════════════════════
//  SCORE UI
// ══════════════════════════════════════

function refreshScoreUI() {
    if (isMultiplayer) {
        scoreText.text = "SCORE: " + score;
        scoreText.size = 32;
        refreshPlayerSidebar();
    } else {
        scoreText.text = "SCORE: " + score;
        scoreText.size = 32;
    }
}

// ══════════════════════════════════════
//  ONE-SHOT REQUESTS
// ══════════════════════════════════════

function fetchServerStatus() {
    log("PING " + SERVER_IP);
    netOneShot("GET_STATUS", 0.3, function(d) {
        log("RESP: " + d);
        if (d != null && d.indexOf("STATUS") != -1) {
            var p = d.split(":");
            statusText.text = "ONLINE: " + p[1] + " | ROOMS: " + p[2];
            statusText.color = 0xFF00FF00;
        } else {
            statusText.text = "SERVER: OFFLINE";
            statusText.color = 0xFFFF0000;
        }
    });
}

function fetchLeaderboard() {
    netOneShot("GET_LEADERBOARD", 0.3, function(d) {
        if (d != null && d.indexOf("LEADERBOARD") != -1) {
            var idx = d.indexOf(":");
            if (idx != -1) renderLeaderboard(d.substring(idx + 1).split("\n")[0]);
        } else {
            lobbyText.text = "OFFLINE!";
        }
    });
}

function renderLeaderboard(json:String) {
    try {
        log("LB JSON: " + json);
        // Manual JSON array parse since haxe.Json may not be available in scripting
        var entries:Array<Dynamic> = [];
        var s = StringTools.trim(json);
        if (s.charAt(0) == "[" && s.charAt(s.length - 1) == "]") {
            s = s.substring(1, s.length - 1); // strip []
            if (StringTools.trim(s).length > 0) {
                // Split by },{ pattern
                var raw = s.split("},{" );
                for (ri in 0...raw.length) {
                    var obj = raw[ri];
                    obj = StringTools.replace(obj, "{", "");
                    obj = StringTools.replace(obj, "}", "");
                    obj = StringTools.replace(obj, "\"", "");
                    // Now have: name:Foo,score:123
                    var nameVal = "";
                    var scoreVal = 0;
                    var fields = obj.split(",");
                    for (fi in 0...fields.length) {
                        var kv = fields[fi].split(":");
                        if (kv.length >= 2) {
                            var k = StringTools.trim(kv[0]);
                            var v = StringTools.trim(kv[1]);
                            if (k == "name") nameVal = v;
                            else if (k == "score") scoreVal = Std.parseInt(v);
                        }
                    }
                    if (nameVal.length > 0) entries.push({name: nameVal, score: scoreVal});
                }
            }
        }
        var startY = FlxG.height * 0.30;
        if (entries.length == 0) {
            lobbyText.text = "NO SCORES YET  [ESC] BACK";
        } else {
            var medalColors = [0xFFFFD700, 0xFFC0C0C0, 0xFFCD7F32];
            for (i in 0...entries.length) {
                var col = i < 3 ? medalColors[i] : 0xFFCCCCCC;
                var prefix = i == 0 ? ">> " : "   ";
                var entry = new FlxText(0, startY + (i * 38), FlxG.width, prefix + (i + 1) + ". " + entries[i].name + "  -  " + entries[i].score, 26);
                entry.setFormat(Paths.font(currentFont), 26, col, "center", 2, 0xFF000000);
                entry.cameras = [uiCam];
                entry.alpha = 0;
                FlxTween.tween(entry, {alpha: 1}, 0.3, {startDelay: i * 0.06, ease: FlxEase.quadOut});
                leaderboardGroup.add(entry);
            }
            lobbyText.text = "LEADERBOARD  [ESC] BACK";
        }
    } catch(e:Dynamic) {
        lobbyText.text = "PARSE ERROR: " + e;
    }
}

// ══════════════════════════════════════
//  LOGGING & CLEANUP
// ══════════════════════════════════════

function log(msg:String) {
    debugLog.text = msg + "\n" + debugLog.text;
    if (debugLog.text.length > 200) debugLog.text = debugLog.text.substring(0, 200);
}

function destroy() {
    netDisconnect();
}
