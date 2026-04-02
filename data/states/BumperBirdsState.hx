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
var worldCam:FlxCamera;
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
var playerVX:Float = 0;
var playerVY:Float = 0;
var playerAccel:Float = 800;
var playerFriction:Float = 0.92;
var playerMass:Float = 1.0;
var iAmDead:Bool = false;
var dashCooldown:Float = 0;

var platform:FlxSprite;
var platformBorder:FlxSprite;
var platformGlow:Float = 0;
var platformRadius:Float = 200;
var platformShrinkTimer:Float = 0;
var platformShrinkInterval:Float = 8;
var platformMinRadius:Float = 60;
var platformCX:Float = 0;
var platformCY:Float = 0;

var vfxGroup:FlxTypedGroup<FlxSprite>;
var playerGroup:FlxTypedGroup<FlxSprite>;
var nickTagGroup:FlxTypedGroup<FlxText>;
var playerMap:Dynamic = {};
var playerEyeMap:Dynamic = {};
var playerBeakMap:Dynamic = {};
var playerNickMap:Dynamic = {};
var playerVXMap:Dynamic = {};
var playerVYMap:Dynamic = {};
var targetXMap:Dynamic = {};
var targetYMap:Dynamic = {};
var deadMap:Dynamic = {};
var roundActive:Bool = false;
var countdownActive:Bool = false;
var aliveCount:Int = 0;
var roundText:FlxText;
var statusText:FlxText;
var shrinkWarning:FlxText;
var netSendAccum:Float = 0;
var serverState:Dynamic = null;
var netBuffer:String = "";

function create() {
    if (FlxG.save.data.flappyNickname != null) myNickname = FlxG.save.data.flappyNickname;
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;
    if (FlxG.save.data.flappyCoins != null) flappyCoins = FlxG.save.data.flappyCoins;

    platformCX = FlxG.width / 2;
    platformCY = FlxG.height / 2 + 20;

    FlxG.camera.bgColor = 0xFF080816;

    worldCam = new FlxCamera();
    worldCam.bgColor = 0x00000000;
    FlxG.cameras.add(worldCam, false);

    uiCam = new FlxCamera();
    uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    platform = new FlxSprite(0, 0).makeGraphic(Std.int(platformRadius * 2), Std.int(platformRadius * 2), 0xFF1A1A3A);
    platform.antialiasing = true;
    platform.cameras = [worldCam];
    updatePlatformVisual();
    add(platform);

    platformBorder = new FlxSprite(0, 0).makeGraphic(Std.int(platformRadius * 2 + 8), Std.int(platformRadius * 2 + 8), 0xFFFF6644);
    platformBorder.alpha = 0.4;
    platformBorder.antialiasing = true;
    platformBorder.cameras = [worldCam];
    updatePlatformBorderVisual();
    add(platformBorder);

    vfxGroup = new FlxTypedGroup();
    vfxGroup.cameras = [worldCam];
    add(vfxGroup);
    
    playerGroup = new FlxTypedGroup();
    playerGroup.cameras = [worldCam];
    add(playerGroup);
    
    nickTagGroup = new FlxTypedGroup();
    add(nickTagGroup);

    var skinCol = 0xFFFFEE00;
    if (FlxG.save.data.flappyEquippedSkinId != null) {
        var skins:Array<Dynamic> = [
            {id: "default", color: 0xFFFFEE00}, {id: "ice", color: 0xFF00CCFF}, {id: "bubblegum", color: 0xFFFF6699},
            {id: "neon", color: 0xFF66FF66}, {id: "sunset", color: 0xFFFF9933}, {id: "crimson", color: 0xFFFF0000},
            {id: "golden", color: 0xFFFFD700}, {id: "shadow", color: 0xFF333333}, {id: "royal", color: 0xFF4169E1}
        ];
        for (s in skins) if (s.id == FlxG.save.data.flappyEquippedSkinId) skinCol = s.color;
    }

    player = new FlxSprite(platformCX, platformCY).makeGraphic(32, 26, skinCol);
    player.antialiasing = true;
    player.cameras = [worldCam];
    add(player);

    playerEye = new FlxSprite(0, 0).makeGraphic(8, 8, 0xFFFFFFFF);
    playerEye.cameras = [worldCam];
    add(playerEye);

    playerBeak = new FlxSprite(0, 0).makeGraphic(12, 7, 0xFFFF8800);
    playerBeak.cameras = [worldCam];
    add(playerBeak);

    lobbySlotGroup = new FlxTypedGroup();
    add(lobbySlotGroup);
    lobbyBgGroup = new FlxTypedGroup();
    add(lobbyBgGroup);

    setupUI();
    goToState("MENU");
}

function updatePlatformVisual() {
    var size = Std.int(platformRadius * 2);
    platform.makeGraphic(size, size, 0xFF1A1A3A);
    platform.setPosition(platformCX - platformRadius, platformCY - platformRadius);
}

function updatePlatformBorderVisual() {
    var size = Std.int(platformRadius * 2 + 8);
    platformBorder.makeGraphic(size, size, 0xFFFF6644);
    platformBorder.setPosition(platformCX - platformRadius - 4, platformCY - platformRadius - 4);
}

function setupUI() {
    titleText = makeText(0, 40, FlxG.width, "BUMPER BIRDS", 64, 0xFFFF6644);
    subtitleText = makeText(0, 110, FlxG.width, "PUSH THEM OFF!", 20, 0xFFFF9933); subtitleText.alpha = 0.7;
    lobbyText = makeText(0, FlxG.height * 0.78, FlxG.width, "", 22, 0xFFFFEE00);
    typingBg = new FlxSprite(FlxG.width * 0.2, FlxG.height * 0.81).makeGraphic(Std.int(FlxG.width * 0.6), 48, 0xFF1A1A2E); typingBg.alpha = 0.7; typingBg.cameras = [uiCam]; add(typingBg);
    typingBg.visible = false;
    typingText = makeText(0, FlxG.height * 0.82, FlxG.width, "", 34, 0xFFFFFFFF);
    roundText = makeText(0, 10, FlxG.width, "", 28, 0xFFFFFFFF);
    statusText = makeText(0, 44, FlxG.width, "", 18, 0xFFAAAAAA);
    shrinkWarning = makeText(0, FlxG.height - 40, FlxG.width, "", 18, 0xFFFF4444); shrinkWarning.alpha = 0;
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
    if (s == "MENU") { netDisconnect(); isMultiplayer = false; lobbyPlayers = []; activePlayers = []; resetData();
    }

    titleText.visible = (s == "MENU" || s == "ROOM_INPUT");
    subtitleText.visible = (s == "MENU");
    lobbyText.visible = true;
    typingText.visible = (s == "ROOM_INPUT"); typingBg.visible = typingText.visible;
    roundText.visible = (s == "PLAYING" || s == "GAMEOVER");
    statusText.visible = (s == "PLAYING");
    shrinkWarning.visible = false; shrinkWarning.alpha = 0;
    coinText.visible = true; coinIconText.visible = true;
    player.visible = (s == "PLAYING" || s == "GAMEOVER"); playerEye.visible = player.visible; playerBeak.visible = player.visible;
    platform.visible = (s == "PLAYING" || s == "GAMEOVER"); platformBorder.visible = platform.visible;
    switch(s) {
        case "MENU": lobbyText.text = "[1] SOLO (VS BOTS)   [2] MULTI   [ESC] BACK";
        FlxG.sound.playMusic(Paths.music("flappy/mainTheme"), 0.8, true);
        case "ROOM_INPUT": lobbyText.text = "ENTER 4-LETTER ROOM CODE";
        case "PLAYING": startRound();
    }
}

function resetData() {
    playerMap = {}; playerEyeMap = {}; playerBeakMap = {}; playerNickMap = {};
    playerVXMap = {}; playerVYMap = {}; targetXMap = {}; targetYMap = {}; deadMap = {};
}

function startRound() {
    iAmDead = false; roundActive = false; countdownActive = true;
    playerVX = 0;
    playerVY = 0; dashCooldown = 0;
    platformRadius = 200; platformShrinkTimer = 0;
    vfxGroup.clear();
    
    player.color = 0xFFFFEE00;
    if (FlxG.save.data.flappyEquippedSkinId != null) {
        var skins:Array<Dynamic> = [
            {id: "default", color: 0xFFFFEE00}, {id: "ice", color: 0xFF00CCFF}, {id: "bubblegum", color: 0xFFFF6699},
            {id: "neon", color: 0xFF66FF66}, {id: "sunset", color: 0xFFFF9933}, {id: "crimson", color: 0xFFFF0000},
            {id: "golden", color: 0xFFFFD700}, {id: "shadow", color: 0xFF333333}, {id: "royal", color: 0xFF4169E1}
        ];
        for (s in skins) if (s.id == FlxG.save.data.flappyEquippedSkinId) player.color = s.color;
    }

    if (isMultiplayer) {
        var myIdx = lobbyPlayers.indexOf(myNickname);
        if (myIdx == -1) myIdx = 0;
        var angle = (myIdx / lobbyPlayers.length) * Math.PI * 2;
        player.x = platformCX + Math.cos(angle) * 60 - 16;
        player.y = platformCY + Math.sin(angle) * 60 - 13;

        for (i in 0...lobbyPlayers.length) {
            if (lobbyPlayers[i] != myNickname) {
                var op = getOpponent(lobbyPlayers[i]);
                var opAngle = (i / lobbyPlayers.length) * Math.PI * 2;
                op.x = platformCX + Math.cos(opAngle) * 60 - 16;
                op.y = platformCY + Math.sin(opAngle) * 60 - 13;
                Reflect.setField(targetXMap, lobbyPlayers[i], op.x);
                Reflect.setField(targetYMap, lobbyPlayers[i], op.y);
            }
        }
    } else {
        player.x = platformCX - 16 + FlxG.random.float(-40, 40);
        player.y = platformCY - 13 + FlxG.random.float(-40, 40);
        spawnBots(3);
    }

    updatePlatformVisual(); updatePlatformBorderVisual();
    titleText.visible = false;
    subtitleText.visible = false; lobbyText.visible = false; typingText.visible = false; typingBg.visible = false;

    FlxG.sound.playMusic(Paths.music("flappy/racingTillDawn"), 0, true);
    FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.5);

    var count = 3;
    var ct = new FlxText(0, 0, FlxG.width, "3", 140);
    ct.setFormat(Paths.font(currentFont), 140, 0xFFFFFFFF, "center", 6, 0xFF000000);
    ct.screenCenter(); ct.cameras = [uiCam]; add(ct);
    new FlxTimer().start(1, function(tmr) {
        count--;
        if (count <= 0) {
            tmr.cancel(); ct.text = "BUMP!"; ct.color = 0xFFFF6644; ct.scale.set(1.5, 1.5);
            FlxTween.tween(ct, {alpha: 0}, 0.5, {ease: FlxEase.quadIn, onComplete: function(_) { ct.destroy(); }});
            FlxG.camera.flash(0x33FFFFFF, 0.3); countdownActive = false; roundActive = true;
        } else {
            ct.text = Std.string(count); ct.scale.set(1.5, 1.5);
            FlxTween.tween(ct.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.elasticOut});
            ct.color = [0xFFFFEE00, 0xFFFF9900, 0xFFFF4444][3 - count];
        }
    }, 0);
}

function spawnBots(count:Int) {
    var botNames = ["BIRDO", "CHONK", "PEEP", "FLUFF", "NUGGET", "SQUAB"];
    for (i in 0...count) {
        var nick = botNames[i % botNames.length];
        activePlayers.push(nick);
        var col = playerColors[(i + 1) % playerColors.length];
        var angle = (i / count) * Math.PI * 2;
        var bx = platformCX + Math.cos(angle) * 60 - 16;
        var by = platformCY + Math.sin(angle) * 60 - 13;
        var bot = new FlxSprite(bx, by).makeGraphic(32, 26, col); bot.alpha = 0.8; bot.cameras = [worldCam]; playerGroup.add(bot);
        var botE = new FlxSprite(0, 0).makeGraphic(8, 8, 0xFFFFFFFF);
        botE.alpha = 0.8; botE.cameras = [worldCam]; playerGroup.add(botE); Reflect.setField(playerEyeMap, nick, botE);
        var botB = new FlxSprite(0, 0).makeGraphic(12, 7, 0xFFFF8800); botB.alpha = 0.8; botB.cameras = [worldCam]; playerGroup.add(botB);
        Reflect.setField(playerBeakMap, nick, botB);
        var tag = new FlxText(0, 0, 150, nick, 11); tag.setFormat(Paths.font(currentFont), 11, col, "center", 1, 0xFF000000);
        tag.cameras = [uiCam]; tag.alpha = 0.6; nickTagGroup.add(tag); Reflect.setField(playerNickMap, nick, tag);
        Reflect.setField(playerMap, nick, bot); Reflect.setField(deadMap, nick, false);
        Reflect.setField(playerVXMap, nick, 0.0);
        Reflect.setField(playerVYMap, nick, 0.0);
        Reflect.setField(targetXMap, nick, bx); Reflect.setField(targetYMap, nick, by);
    }
}

function updateBotAI(elapsed:Float) {
    for (i in 0...activePlayers.length) {
        var nick = activePlayers[i];
        if (Reflect.field(deadMap, nick)) continue;
        if (isMultiplayer) continue;

        var bot:FlxSprite = Reflect.field(playerMap, nick);
        if (bot == null) continue;
        var bvx:Float = Reflect.field(playerVXMap, nick); if (bvx == null) bvx = 0;
        var bvy:Float = Reflect.field(playerVYMap, nick);
        if (bvy == null) bvy = 0;

        var dx = (platformCX - 16) - bot.x;
        var dy = (platformCY - 13) - bot.y;
        var distCenter = Math.sqrt(dx * dx + dy * dy);
        var ax:Float = 0; var ay:Float = 0;

        if (distCenter > platformRadius * 0.5) {
            ax += dx * 2;
            ay += dy * 2;
        }

        if (!iAmDead) {
            var pdx = (player.x + 16) - (bot.x + 16);
            var pdy = (player.y + 13) - (bot.y + 13);
            var pdist = Math.sqrt(pdx * pdx + pdy * pdy);
            if (pdist < 100 && pdist > 0) {
                ax += (pdx / pdist) * 500;
                ay += (pdy / pdist) * 500;
            }
        }

        ax += FlxG.random.float(-80, 80);
        ay += FlxG.random.float(-80, 80);

        bvx += ax * elapsed; bvy += ay * elapsed;
        bvx *= 0.94; bvy *= 0.94;
        bot.x += bvx * elapsed; bot.y += bvy * elapsed;

        Reflect.setField(playerVXMap, nick, bvx);
        Reflect.setField(playerVYMap, nick, bvy);

        checkFallOff(bot, nick);
    }
}

function checkFallOff(sprite:FlxSprite, nick:String) {
    var sx = sprite.x + 16; var sy = sprite.y + 13;
    var dx = sx - platformCX; var dy = sy - platformCY;
    var dist = Math.sqrt(dx * dx + dy * dy);
    if (dist > platformRadius + 20) {
        Reflect.setField(deadMap, nick, true);
        sprite.color = 0xFF444444;
        spawnFallVFX(sprite.x, sprite.y);
        FlxTween.tween(sprite, {alpha: 0, y: sprite.y + 100}, 0.5, {ease: FlxEase.quadIn});
        checkRoundEnd();
    }
}

function spawnFallVFX(x:Float, y:Float) {
    for (i in 0...8) {
        var size = FlxG.random.int(8, 20);
        var p = new FlxSprite(x + FlxG.random.float(-5, 25), y + FlxG.random.float(-5, 20)).makeGraphic(size, size, FlxG.random.bool(50) ? 0xFFFF4444 : 0xFFFF8800);
        p.alpha = 0.8; p.cameras = [worldCam]; p.velocity.set(FlxG.random.float(-150, 150), FlxG.random.float(-180, 80));
        vfxGroup.add(p);
        FlxTween.tween(p, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.4, {onComplete: function(_) { p.destroy(); }});
    }
    FlxG.camera.shake(0.02, 0.2);
}

function handleCollision(a:FlxSprite, avx:Float, avy:Float, b:FlxSprite, bvx:Float, bvy:Float):Dynamic {
    var ax = a.x + 16;
    var ay = a.y + 13;
    var bx = b.x + 16; var by = b.y + 13;
    var dx = bx - ax; var dy = by - ay;
    var dist = Math.sqrt(dx * dx + dy * dy);
    if (dist < 36 && dist > 0) {
        var nx = dx / dist;
        var ny = dy / dist;
        var relVX = avx - bvx; var relVY = avy - bvy;
        var impact = relVX * nx + relVY * ny;
        if (impact > 0) {
            var bump = impact * 1.5;
            return {avx: avx - nx * bump, avy: avy - ny * bump, bvx: bvx + nx * bump, bvy: bvy + ny * bump, hit: true};
        }
    }
    return {avx: avx, avy: avy, bvx: bvx, bvy: bvy, hit: false};
}

function checkRoundEnd() {
    if (!roundActive) return;

    var alive = 0;
    if (!iAmDead) alive++;
    for (i in 0...activePlayers.length) { 
        if (!Reflect.field(deadMap, activePlayers[i])) alive++; 
    }

    var totalPlayers = isMultiplayer ? lobbyPlayers.length : activePlayers.length + 1;
    if (totalPlayers <= 1) return;

    if (alive <= 1) {
        roundActive = false;
        var won = !iAmDead;
        var reward = won ? 25 : 10;
        flappyCoins += reward; FlxG.save.data.flappyCoins = flappyCoins; FlxG.save.flush();
        coinText.text = "" + flappyCoins; coinBounce = 1.3;
        gameState = "GAMEOVER"; showGameOver(won, reward);
    }

    aliveCount = alive;
    statusText.text = alive + " BIRDS LEFT";
}

function showGameOver(won:Bool, reward:Int) {
    incrementStat("totalGamesPlayed", 1);
    incrementStat("bumperBirdsGamesPlayed", 1);
    if (won) { incrementStat("totalWins", 1); incrementStat("bumperBirdsWins", 1); }
    else { incrementStat("totalDeaths", 1); }
    if (getStat("bumperBirdsWins") >= 1) unlockAchievement("bb_rookie");
    if (getStat("bumperBirdsWins") >= 100) unlockAchievement("bb_arena");
    unlockAchievement("gen_welcome");
    if (FlxG.sound.music != null) FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.5);
    var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000);
    overlay.cameras = [uiCam]; add(overlay);
    FlxTween.color(overlay, 0.5, 0x00000000, 0xBB000000);

    var result = won ?
    "LAST BIRD STANDING!" : "KNOCKED OUT!";
    var col = won ? 0xFF00FF88 : 0xFFFF4444;
    var rt = new FlxText(0, 0, FlxG.width, result, 56);
    rt.setFormat(Paths.font(currentFont), 56, col, "center", 4, 0xFF000000);
    rt.screenCenter(); rt.y -= 60;
    rt.cameras = [uiCam]; rt.alpha = 0; rt.scale.set(2.5, 2.5); add(rt);
    FlxTween.tween(rt, {alpha: 1}, 0.4, {ease: FlxEase.quadOut});
    FlxTween.tween(rt.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.elasticOut});

    var info = new FlxText(0, 0, FlxG.width, "+" + reward + " FLOCKERS\n\n[ENTER] PLAY AGAIN   [ESC] BACK", 22);
    info.setFormat(Paths.font(currentFont), 22, 0xFFCCCCCC, "center", 2, 0xFF000000);
    info.screenCenter(); info.y += 20; info.cameras = [uiCam]; info.alpha = 0; add(info);
    FlxTween.tween(info, {alpha: 1}, 0.5, {startDelay: 0.3});
}

function update(elapsed:Float) {
    titleGlow += elapsed * 2.5;
    if (titleText.visible) titleText.scale.set(Math.sin(titleGlow) * 0.06 + 1.0, Math.sin(titleGlow) * 0.06 + 1.0);
    if (subtitleText.visible) subtitleText.alpha = 0.5 + Math.sin(titleGlow * 1.3) * 0.3;
    if (coinBounce > 1.0) { coinBounce = FlxMath.lerp(coinBounce, 1.0, elapsed * 8); coinText.scale.set(coinBounce, coinBounce);
    }
    coinIconSpin += elapsed * 6; if (coinIconText != null) coinIconText.scale.set(Math.abs(Math.cos(coinIconSpin)) * 0.6 + 0.4, 1.0);
    if (platform.visible) {
        platformGlow += elapsed * 3;
        platformBorder.alpha = 0.3 + Math.sin(platformGlow) * 0.15;
    }

    if (player.visible) {
        playerEye.setPosition(player.x + 20, player.y + 4);
        playerBeak.setPosition(player.x + 26, player.y + 9);
    }

    for (i in 0...activePlayers.length) {
        var nick = activePlayers[i];
        var op:FlxSprite = Reflect.field(playerMap, nick); if (op == null) continue;
        if (isMultiplayer) {
            var tx = Reflect.field(targetXMap, nick);
            var ty = Reflect.field(targetYMap, nick);
            if (tx != null && ty != null) { op.x = FlxMath.lerp(op.x, tx, elapsed * 12);
            op.y = FlxMath.lerp(op.y, ty, elapsed * 12); }
        }
        var opE:FlxSprite = Reflect.field(playerEyeMap, nick);
        var opB:FlxSprite = Reflect.field(playerBeakMap, nick); var opN:FlxText = Reflect.field(playerNickMap, nick);
        if (opE != null) opE.setPosition(op.x + 20, op.y + 4);
        if (opB != null) opB.setPosition(op.x + 26, op.y + 9);
        if (opN != null) opN.setPosition(op.x - 60, op.y - 16);
    }

    vfxGroup.forEachAlive(function(v:FlxSprite) { if (v.alpha <= 0.01) v.kill(); });
    if (FlxG.keys.justPressed.ESCAPE) {
        if (gameState == "PLAYING") { openSubState(new ModSubState("FlappyPause")); return;
        }
        else { netDisconnect(); FlxG.switchState(new ModState("CustomMainMenu")); return;
        }
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
    waitDotTimer += elapsed;
    if (waitDotTimer > 0.5) { waitDotTimer = 0; waitDots = (waitDots + 1) % 4;
    }
    var dots = ""; for (di in 0...waitDots) dots += "."; lobbyText.text = "WAITING" + dots;
}

function updateLobby() {
    if (isHost && FlxG.keys.justPressed.ENTER && lobbyPlayers.length >= 2) netSend("START_GAME:bumperbirds:0");
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU");
}

function doShrink() {
    platformRadius -= 15;
    if (platformRadius < platformMinRadius) platformRadius = platformMinRadius;
    updatePlatformVisual(); updatePlatformBorderVisual();
    FlxG.camera.shake(0.01, 0.3); FlxG.camera.flash(0x22FF0000, 0.2);
    shrinkWarning.visible = true;
    shrinkWarning.text = "PLATFORM SHRINKING!"; shrinkWarning.alpha = 1;
    FlxTween.tween(shrinkWarning, {alpha: 0}, 1.5);
}

function updatePlaying(elapsed:Float) {
    if (countdownActive || !roundActive) return;

    if (!isMultiplayer) {
        platformShrinkTimer += elapsed;
        if (platformShrinkTimer >= platformShrinkInterval && platformRadius > platformMinRadius) {
            platformShrinkTimer = 0;
            doShrink();
        }
    }

    if (!iAmDead) {
        var ax:Float = 0;
        var ay:Float = 0;
        if (FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A) ax -= playerAccel;
        if (FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D) ax += playerAccel;
        if (FlxG.keys.pressed.UP || FlxG.keys.pressed.W) ay -= playerAccel;
        if (FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S) ay += playerAccel;
        if (dashCooldown > 0) dashCooldown -= elapsed;
        if (FlxG.keys.justPressed.SPACE && dashCooldown <= 0) {
            dashCooldown = 1.5;
            if (isMultiplayer) netSend("INPUT:DASH");
            var dashPower = 600;
            if (ax != 0 || ay != 0) {
                var len = Math.sqrt(ax * ax + ay * ay);
                playerVX += (ax / len) * dashPower; playerVY += (ay / len) * dashPower;
            } else {
                playerVX *= 2.5;
                playerVY *= 2.5;
            }
            FlxG.camera.flash(0x11FFFFFF, 0.08);
            spawnDashVFX();
        }

        playerVX += ax * elapsed; playerVY += ay * elapsed;
        playerVX *= playerFriction; playerVY *= playerFriction;
        player.x += playerVX * elapsed; player.y += playerVY * elapsed;
        for (i in 0...activePlayers.length) {
            var nick = activePlayers[i];
            if (Reflect.field(deadMap, nick)) continue;
            var op:FlxSprite = Reflect.field(playerMap, nick); if (op == null) continue;
            var ovx:Float = Reflect.field(playerVXMap, nick);
            if (ovx == null) ovx = 0;
            var ovy:Float = Reflect.field(playerVYMap, nick); if (ovy == null) ovy = 0;
            var result = handleCollision(player, playerVX, playerVY, op, ovx, ovy);
            if (result.hit) {
                playerVX = result.avx;
                playerVY = result.avy;
                Reflect.setField(playerVXMap, nick, result.bvx);
                Reflect.setField(playerVYMap, nick, result.bvy);
                FlxG.camera.shake(0.008, 0.1);
                spawnBumpVFX((player.x + op.x) / 2, (player.y + op.y) / 2);
            }
        }

        checkPlayerFallOff();
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
                }
                if (serverState.pr != null) {
                    platformRadius = FlxMath.lerp(platformRadius, serverState.pr, 0.2);
                    updatePlatformVisual();
                    updatePlatformBorderVisual();
                }
            }
        }
    }

    if (!isMultiplayer) updateBotAI(elapsed);
    roundText.text = "ARENA: " + Std.int(platformRadius);
    checkRoundEnd();
}

function checkPlayerFallOff() {
    var px = player.x + 16;
    var py = player.y + 13;
    var dx = px - platformCX; var dy = py - platformCY;
    var dist = Math.sqrt(dx * dx + dy * dy);
    if (dist > platformRadius + 20) {
        iAmDead = true; player.color = 0xFF444444;
        spawnFallVFX(player.x, player.y);
        FlxTween.tween(player, {alpha: 0.3, y: player.y + 100}, 0.5, {ease: FlxEase.quadIn});
        checkRoundEnd();
    }
}

function spawnDashVFX() {
    for (i in 0...5) {
        var size = FlxG.random.int(6, 14);
        var p = new FlxSprite(player.x + FlxG.random.float(0, 28), player.y + FlxG.random.float(0, 22)).makeGraphic(size, size, 0xFFFFFFFF);
        p.alpha = 0.5;
        p.cameras = [worldCam];
        p.velocity.set(-playerVX * 0.3 + FlxG.random.float(-40, 40), -playerVY * 0.3 + FlxG.random.float(-40, 40));
        vfxGroup.add(p);
        FlxTween.tween(p, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.25, {onComplete: function(_) { p.destroy(); }});
    }
}

function spawnBumpVFX(x:Float, y:Float) {
    for (i in 0...4) {
        var size = FlxG.random.int(8, 16);
        var p = new FlxSprite(x + FlxG.random.float(-8, 8), y + FlxG.random.float(-8, 8)).makeGraphic(size, size, 0xFFFFCC00);
        p.alpha = 0.6;
        p.cameras = [worldCam];
        p.velocity.set(FlxG.random.float(-120, 120), FlxG.random.float(-120, 120));
        vfxGroup.add(p);
        FlxTween.tween(p, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 0.3, {onComplete: function(_) { p.destroy(); }});
    }
}

function handleTyping(max:Int, elapsed:Float) {
    if (FlxG.keys.justPressed.BACKSPACE && typedInput.length > 0) typedInput = typedInput.substring(0, typedInput.length - 1);
    else if (typedInput.length < max) {
        var key = FlxG.keys.firstJustPressed();
        var abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        if (key >= 65 && key <= 90) typedInput += abc.charAt(key - 65);
        else if (key >= 48 && key <= 57) typedInput += abc.charAt(key - 48 + 26);
    }
    typingCursorTimer += elapsed; if (typingCursorTimer >= 0.5) { typingCursorBlink = !typingCursorBlink; typingCursorTimer = 0;
    }
    typingText.text = "> " + typedInput + (typingCursorBlink ? "_" : "");
}

function netConnect(roomCode:String, nickname:String) {
    netDisconnect();
    try {
        connection = new Socket();
        connection.connect(new Host(SERVER_IP), SERVER_PORT); netConnected = true; connection.socket.setBlocking(false);
        new FlxTimer().start(0.3, function(t) {
            try { connection.write("JOIN_ROOM:" + roomCode + ":" + nickname + "\n"); startNetPollTimer(); } catch(e:Dynamic) {}
        });
    } catch(e:Dynamic) {
        netConnected = false; lobbyText.text = "CONNECTION FAILED!";
        new FlxTimer().start(2, function(t) { goToState("MENU"); });
    }
}

function netDisconnect() {
    if (pollTimer != null) { pollTimer.cancel();
    pollTimer = null; }
    if (connection != null) { try { connection.destroy();
    } catch(e:Dynamic) {} connection = null; }
    netConnected = false;
}

function netSend(msg:String) { if (!netConnected || connection == null) return; try { connection.write(msg + "\n");
    } catch(e:Dynamic) {} }

function netPoll() {
    if (!netConnected || connection == null) return;
    try { var sock = connection.socket; var c = 0;
        while (c < 20) { c++;
            try { var line = sock.input.readLine(); if (line == null) break; line = StringTools.trim(line); if (line.length == 0) continue;
                var sublines = line.split("\\n"); for (si in 0...sublines.length) { var sub = StringTools.trim(sublines[si]); if (sub.length > 0) processNetLine(sub);
                }
            } catch(inner:Dynamic) { break;
            }
        }
    } catch(e:Dynamic) {}
}

function startNetPollTimer() { if (pollTimer != null) pollTimer.cancel();
    pollTimer = new FlxTimer().start(0.1, function(tmr) { netPoll(); }, 0); }
function processNetLine(line:String) { var parts = line.split(":"); var cmd = parts[0];
    parts.splice(0, 1); handleServerMessage(cmd, parts); }

function handleServerMessage(cmd:String, args:Array<String>) {
    switch(cmd) {
        case "WAITING_FOR_HOST": gameState = "LOBBY";
        addLobbyPlayer(myNickname); refreshLobbyUI();
        case "ROOM_FULL": lobbyText.text = "ROOM FULL!"; new FlxTimer().start(2, function(t) { goToState("MENU"); });
        case "START": goToState("PLAYING");
        case "GS":
            if (args.length >= 1) {
                try {
                    var gs = haxe.Json.parse(args.join(":"));
                    serverState = gs;
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
                                if (op != null) { op.color = 0xFF444444; spawnFallVFX(op.x, op.y); }
                                checkRoundEnd();
                            }
                        } else {
                            if (!ps.alive && !iAmDead) checkPlayerFallOff();
                        }
                    }
                    if (gs.ph == "gameover" && gameState == "PLAYING") checkRoundEnd();
                } catch(e:Dynamic) {}
            }
        case "PLAYER_LIST":
            if (args.length > 0) { lobbyPlayers = [];
                for (pi in 0...args.length) { var pn = StringTools.trim(args[pi]); if (pn.length > 0) lobbyPlayers.push(pn);
                }
                if (lobbyPlayers.length > 0 && lobbyPlayers[0] == myNickname) isHost = true;
                else isHost = false;
                if (gameState == "WAITING") { gameState = "LOBBY"; refreshLobbyUI(); } else if (gameState == "LOBBY") refreshLobbyUI();
        }
        case "CHAT": {}
    }
}

function getOpponent(nick:String):FlxSprite {
    if (nick == myNickname) return null;
    if (activePlayers.indexOf(nick) == -1) {
        activePlayers.push(nick);
        var col = playerColors[activePlayers.length % playerColors.length];
        var op = new FlxSprite(platformCX, platformCY).makeGraphic(32, 26, col); op.alpha = 0.6; op.cameras = [worldCam]; playerGroup.add(op);
        var opE = new FlxSprite(0, 0).makeGraphic(8, 8, 0xFFFFFFFF);
        opE.alpha = 0.6; opE.cameras = [worldCam]; playerGroup.add(opE); Reflect.setField(playerEyeMap, nick, opE);
        var opB = new FlxSprite(0, 0).makeGraphic(12, 7, 0xFFFF8800); opB.alpha = 0.6; opB.cameras = [worldCam]; playerGroup.add(opB);
        Reflect.setField(playerBeakMap, nick, opB);
        var tag = new FlxText(0, 0, 150, nick, 11); tag.setFormat(Paths.font(currentFont), 11, col, "center", 1, 0xFF000000);
        tag.cameras = [uiCam]; tag.alpha = 0.6; nickTagGroup.add(tag); Reflect.setField(playerNickMap, nick, tag);
        Reflect.setField(playerMap, nick, op); Reflect.setField(deadMap, nick, false); Reflect.setField(playerVXMap, nick, 0.0);
        Reflect.setField(playerVYMap, nick, 0.0);
        Reflect.setField(targetXMap, nick, platformCX); Reflect.setField(targetYMap, nick, platformCY);
    }
    return Reflect.field(playerMap, nick);
}

function addLobbyPlayer(nick:String) { if (nick.length == 0) return; for (li in 0...lobbyPlayers.length) if (lobbyPlayers[li] == nick) return; lobbyPlayers.push(nick);
}

function refreshLobbyUI() {
    lobbySlotGroup.clear(); lobbyBgGroup.clear(); titleText.visible = false; subtitleText.visible = false; typingText.visible = false; typingBg.visible = false;
    lobbyRoomText.visible = true; lobbyRoomText.text = "ROOM: " + activeRoomCode + "   |   BUMPER BIRDS";
    lobbyRoomText.y = 20;
    var countText = new FlxText(0, 50, FlxG.width, lobbyPlayers.length + " / 6 PLAYERS", 18);
    countText.setFormat(Paths.font(currentFont), 18, 0xFF88CCFF, "center", 1, 0xFF000000); countText.cameras = [uiCam]; lobbySlotGroup.add(countText);
    var startY = FlxG.height * 0.22; var slotH = 56;
    for (si in 0...6) {
        var slotY = startY + (si * slotH);
        var hasPlayer = si < lobbyPlayers.length;
        var nick = hasPlayer ? lobbyPlayers[si] : "WAITING..."; var col = hasPlayer ?
        playerColors[si % playerColors.length] : 0xFF333333; var isMe = hasPlayer && lobbyPlayers[si] == myNickname;
        var cardBg = new FlxSprite(Std.int(FlxG.width * 0.12), Std.int(slotY)).makeGraphic(Std.int(FlxG.width * 0.76), Std.int(slotH - 6), hasPlayer ? 0xFF1A1A2E : 0xFF0D0D18);
        cardBg.alpha = hasPlayer ? 0.65 : 0.3; cardBg.cameras = [uiCam]; lobbyBgGroup.add(cardBg);
        if (hasPlayer) { var stripe = new FlxSprite(Std.int(FlxG.width * 0.12), Std.int(slotY)).makeGraphic(5, Std.int(slotH - 6), col); stripe.cameras = [uiCam]; lobbyBgGroup.add(stripe);
        }
        var nameStr = hasPlayer ? nick.toUpperCase() : "---";
        if (isMe) nameStr = nameStr + "  (YOU)";
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