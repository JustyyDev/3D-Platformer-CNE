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

var gameState:String = "NICKNAME";
var inCountdown:Bool = false;
var flappyCoins:Int = 0;
var coinText:FlxText;
var coinIconText:FlxText;
var coinBounce:Float = 1.0;
var coinEarnedThisRound:Int = 0;
var coinIconSpin:Float = 0;

var allSkins:Array<Dynamic> = [
    {id: "default", name: "DEFAULT", color: 0xFFFFEE00, price: 0, hat: "none"},
    {id: "ice", name: "ICE BIRD", color: 0xFF00CCFF, price: 50, hat: "none"},
    {id: "bubblegum", name: "BUBBLEGUM", color: 0xFFFF6699, price: 50, hat: "none"},
    {id: "neon", name: "NEON", color: 0xFF66FF66, price: 75, hat: "none"},
    {id: "sunset", name: "SUNSET", color: 0xFFFF9933, price: 75, hat: "none"},
    {id: "lavender", name: "LAVENDER", color: 0xFFCC66FF, price: 100, hat: "none"},
    {id: "crimson", name: "CRIMSON", color: 0xFFFF0000, price: 150, hat: "none"},
    {id: "aqua", name: "AQUA", color: 0xFF00FFCC, price: 150, hat: "none"},
    {id: "ghost", name: "GHOST", color: 0xFFFFFFFF, price: 200, hat: "halo"},
    {id: "shadow", name: "SHADOW", color: 0xFF333333, price: 300, hat: "none"},
    {id: "pink", name: "HOT PINK", color: 0xFFFF1493, price: 125, hat: "none"},
    {id: "royal", name: "ROYAL BLUE", color: 0xFF4169E1, price: 175, hat: "crown"},
    {id: "blaze", name: "BLAZE", color: 0xFFFF4500, price: 225, hat: "horns"},
    {id: "ultra", name: "ULTRAVIOLET", color: 0xFF8B00FF, price: 350, hat: "none"},
    {id: "teal", name: "TEAL WAVE", color: 0xFF00CED1, price: 400, hat: "none"},
    {id: "golden", name: "GOLDEN KING", color: 0xFFFFD700, price: 500, hat: "bigcrown"},
    {id: "pirate", name: "PIRATE", color: 0xFF8B4513, price: 250, hat: "pirate"},
    {id: "ninja", name: "NINJA", color: 0xFF111111, price: 280, hat: "headband"},
    {id: "cowboy", name: "COWBOY", color: 0xFFD2B48C, price: 320, hat: "cowboy"},
    {id: "chef", name: "MASTER CHEF", color: 0xFFEEEEEE, price: 180, hat: "chef"},
    {id: "wizard", name: "WIZARD", color: 0xFF4B0082, price: 450, hat: "wizard"},
    {id: "cyborg", name: "CYBORG", color: 0xFFC0C0C0, price: 380, hat: "antenna"},
    {id: "zombie", name: "ZOMBIE", color: 0xFF556B2F, price: 260, hat: "brain"},
    {id: "angel", name: "PURE ANGEL", color: 0xFFFFFACD, price: 600, hat: "halo"},
    {id: "demon", name: "ARCH DEMON", color: 0xFF8B0000, price: 600, hat: "horns"},
    {id: "alien", name: "ALIEN", color: 0xFF32CD32, price: 420, hat: "ufo"},
    {id: "knight", name: "PALADIN", color: 0xFFB0C4DE, price: 550, hat: "helmet"},
    {id: "cap", name: "BALLER", color: 0xFFFF6347, price: 160, hat: "cap"},
    {id: "frog", name: "FROG", color: 0xFF228B22, price: 210, hat: "none"},
    {id: "choco", name: "CHOCOLATE", color: 0xFFD2691E, price: 90, hat: "none"}
];

var allTrails:Array<Dynamic> = [
    {id: "none", name: "NONE", color: 0x00000000, price: 0},
    {id: "sparkle", name: "SPARKLE", color: 0xFFFFDD44, price: 100},
    {id: "fire", name: "FIRE", color: 0xFFFF4400, price: 150},
    {id: "rainbow", name: "RAINBOW", color: 0xFFFF00FF, price: 200},
    {id: "glitch", name: "GLITCH", color: 0xFF00FFCC, price: 350},
    {id: "snow", name: "SNOW", color: 0xFFCCEEFF, price: 125},
    {id: "hearts", name: "HEARTS", color: 0xFFFF4488, price: 175},
    {id: "toxic", name: "TOXIC", color: 0xFF44FF00, price: 275},
    {id: "stars", name: "STARS", color: 0xFFFFFFAA, price: 300},
    {id: "bubbles", name: "BUBBLES", color: 0xFF88CCFF, price: 160},
    {id: "lightning", name: "LIGHTNING", color: 0xFF00FFFF, price: 400},
    {id: "shadows", name: "SHADOWS", color: 0xFF111111, price: 250},
    {id: "money", name: "MONEY", color: 0xFF22AA22, price: 500},
    {id: "pixels", name: "PIXELS", color: 0xFFDDDDDD, price: 220},
    {id: "ash", name: "ASH", color: 0xFF555555, price: 140},
    {id: "slime", name: "SLIME", color: 0xFF99FF33, price: 210},
    {id: "confetti", name: "CONFETTI", color: 0xFFFFFFFF, price: 320}
];

var allBGs:Array<Dynamic> = [
    {id: "day", name: "DAY", price: 0, bg: 0xFF87CEEB, ground: 0xFF4A8C3F, line: 0xFF5BAF50, dirt: 0xFF3A6C2F, grass: 0xFF6BD45E, sky: 0xFFFFFFFF, propType: "cloud"},
    {id: "sunset", name: "SUNSET", price: 75, bg: 0xFFFF6B35, ground: 0xFF8B4513, line: 0xFFCD853F, dirt: 0xFF6B3410, grass: 0xFFDDA040, sky: 0xFFFF8844, propType: "cloud"},
    {id: "night", name: "NIGHT", price: 100, bg: 0xFF0A0A2E, ground: 0xFF1A1A4E, line: 0xFF2A2A6E, dirt: 0xFF12123E, grass: 0xFF3A3A7E, sky: 0xFF444488, propType: "star"},
    {id: "neon", name: "NEON CITY", price: 200, bg: 0xFF1A0033, ground: 0xFF220044, line: 0xFF440088, dirt: 0xFF180033, grass: 0xFF6600AA, sky: 0xFF8800CC, propType: "building"},
    {id: "void", name: "THE VOID", price: 400, bg: 0xFF000000, ground: 0xFF111111, line: 0xFF222222, dirt: 0xFF0A0A0A, grass: 0xFF2A2A2A, sky: 0xFF333333, propType: "crystal"},
    {id: "ocean", name: "OCEAN", price: 150, bg: 0xFF1A6B8A, ground: 0xFF1A5570, line: 0xFF2A7A90, dirt: 0xFF0E3A4A, grass: 0xFF3A9AB0, sky: 0xFF44AACC, propType: "coral"},
    {id: "inferno", name: "INFERNO", price: 250, bg: 0xFF3A0A00, ground: 0xFF5A1A00, line: 0xFF8B3000, dirt: 0xFF2A0800, grass: 0xFFCC5500, sky: 0xFFFF6633, propType: "lava"},
    {id: "forest", name: "FOREST", price: 150, bg: 0xFF224422, ground: 0xFF1A331A, line: 0xFF2A552A, dirt: 0xFF112211, grass: 0xFF2A662A, sky: 0xFF88CC88, propType: "tree"},
    {id: "desert", name: "DESERT", price: 150, bg: 0xFFEEDD88, ground: 0xFFCC9944, line: 0xFFDDAA55, dirt: 0xFFAA7733, grass: 0xFFEEBB55, sky: 0xFFFFDD99, propType: "cactus"},
    {id: "winter", name: "WINTER", price: 200, bg: 0xFFBBDDFF, ground: 0xFFEEEEFF, line: 0xFFFFFFFF, dirt: 0xFFBBCCEE, grass: 0xFFDDFFFF, sky: 0xFFCCDDEE, propType: "snowman"},
    {id: "cyberpunk", name: "CYBERPUNK", price: 350, bg: 0xFF0A0A1A, ground: 0xFF111122, line: 0xFF00FFFF, dirt: 0xFF0A0A11, grass: 0xFFFF00FF, sky: 0xFF442288, propType: "neonbuilding"},
    {id: "alien", name: "ALIEN", price: 300, bg: 0xFF110022, ground: 0xFF2A0033, line: 0xFF440055, dirt: 0xFF1A0022, grass: 0xFF550066, sky: 0xFFAA44AA, propType: "ufo"},
    {id: "candyland", name: "CANDY LAND", price: 220, bg: 0xFFFFD1DC, ground: 0xFFFFB6C1, line: 0xFFFF69B4, dirt: 0xFFDB7093, grass: 0xFFFF1493, sky: 0xFFFFF0F5, propType: "lollipop"},
    {id: "graveyard", name: "GRAVEYARD", price: 180, bg: 0xFF2F4F4F, ground: 0xFF191970, line: 0xFF483D8B, dirt: 0xFF000000, grass: 0xFF696969, sky: 0xFF708090, propType: "tombstone"},
    {id: "space", name: "DEEP SPACE", price: 450, bg: 0xFF000011, ground: 0xFF222233, line: 0xFF444466, dirt: 0xFF111122, grass: 0xFF333344, sky: 0xFF111133, propType: "planet"},
    {id: "volcanic", name: "VOLCANIC", price: 280, bg: 0xFF4A0E00, ground: 0xFF2A0800, line: 0xFFFF4500, dirt: 0xFF1A0500, grass: 0xFF8B0000, sky: 0xFFB22222, propType: "volcano"},
    {id: "retro", name: "RETRO 80S", price: 320, bg: 0xFF2B00FF, ground: 0xFFFF00A0, line: 0xFF00FFFF, dirt: 0xFF8A2BE2, grass: 0xFF9400D3, sky: 0xFFFF1493, propType: "grid"},
    {id: "cloudy", name: "CLOUDY", price: 120, bg: 0xFFD3D3D3, ground: 0xFFA9A9A9, line: 0xFFC0C0C0, dirt: 0xFF808080, grass: 0xFFE0E0E0, sky: 0xFFF5F5F5, propType: "cloud"},
    {id: "matrix", name: "MATRIX", price: 500, bg: 0xFF001100, ground: 0xFF002200, line: 0xFF00FF00, dirt: 0xFF001100, grass: 0xFF008800, sky: 0xFF003300, propType: "code"},
    {id: "steampunk", name: "STEAMPUNK", price: 380, bg: 0xFF8B4513, ground: 0xFFCD853F, line: 0xFFDAA520, dirt: 0xFF5C4033, grass: 0xFFB8860B, sky: 0xFFD2B48C, propType: "gear"},
    {id: "underwater", name: "UNDERWATER CITY", price: 420, bg: 0xFF00008B, ground: 0xFF008080, line: 0xFF20B2AA, dirt: 0xFF006400, grass: 0xFF48D1CC, sky: 0xFF4682B4, propType: "dome"}
];

var shopSkins:Array<Dynamic> = [];
var shopTrails:Array<Dynamic> = [];
var shopBGs:Array<Dynamic> = [];
var equippedSkinId:String = "default";
var equippedTrailId:String = "none";
var equippedBGId:String = "day";

var shopCategory:Int = 0;
var shopScroll:Int = 0;
var shopCursor:Int = 0;
var shopUIGroup:FlxTypedGroup<FlxSprite>;
var shopTextGroup:FlxTypedGroup<FlxText>;

var bird:FlxSprite;
var birdWing:FlxSprite;
var birdEye:FlxSprite;
var birdBeak:FlxSprite;
var birdHat1:FlxSprite;
var birdHat2:FlxSprite;
var birdNickTag:FlxText;
var wingFlapTimer:Float = 0;
var wingUp:Bool = false;
var birdSquash:Float = 1.0;

var pipes:FlxTypedGroup<FlxSprite>;
var pipeCapGroup:FlxTypedGroup<FlxSprite>;
var pipeHighlightGroup:FlxTypedGroup<FlxSprite>;
var pipeShadowGroup:FlxTypedGroup<FlxSprite>;
var powerups:FlxTypedGroup<FlxSprite>;
var powerupGlowGroup:FlxTypedGroup<FlxSprite>;
var powerupLabelGroup:FlxTypedGroup<FlxText>;
var vfxGroup:FlxTypedGroup<FlxSprite>;
var trailGroup:FlxTypedGroup<FlxSprite>;
var playerGroup:FlxTypedGroup<FlxSprite>;
var emoteGroup:FlxTypedGroup<FlxText>;
var nickTagGroup:FlxTypedGroup<FlxText>;
var cloudGroup:FlxTypedGroup<FlxSprite>;
var bgPropGroup:FlxTypedGroup<FlxSprite>;
var grassGroup:FlxTypedGroup<FlxSprite>;
var scorePopGroup:FlxTypedGroup<FlxText>;

var crown:FlxSprite;
var crownGem:FlxSprite;
var sky:FlxBackdrop;
var skyFar:FlxBackdrop;
var ground:FlxSprite;
var groundDirt:FlxSprite;
var groundLine:FlxSprite;
var vignette:FlxSprite;

var uiCam:FlxCamera;
var titleGlow:Float = 0;
var scoreBounce:Float = 1.0;
var trailTimer:Float = 0;
var cloudSpawnTimer:Float = 0;
var bgPropSpawnTimer:Float = 0;
var powerupGlowTimer:Float = 0;
var typingCursorTimer:Float = 0;
var typingCursorBlink:Bool = true;

var playerMap:Dynamic = {};
var playerWingMap:Dynamic = {};
var playerEyeMap:Dynamic = {};
var playerBeakMap:Dynamic = {};
var playerHat1Map:Dynamic = {};
var playerHat2Map:Dynamic = {};
var playerNickMap:Dynamic = {};
var playerSkinIdMap:Dynamic = {};
var scoreMap:Dynamic = {};
var deadMap:Dynamic = {};
var emoteMap:Dynamic = {};
var activePlayers:Array<String> = [];
var currentLeader:String = "";
var targetYMap:Dynamic = {};

var titleText:FlxText;
var subtitleText:FlxText;
var scoreText:FlxText;
var scoreShadow:FlxText;
var lobbyText:FlxText;
var typingText:FlxText;
var typingBg:FlxSprite;
var statusText:FlxText;
var levelText:FlxText;
var myEmoteText:FlxText;
var leaderboardGroup:FlxTypedGroup<FlxText>;
var lobbySlotGroup:FlxTypedGroup<FlxText>;
var lobbyBgGroup:FlxTypedGroup<FlxSprite>;
var playerSidebar:FlxTypedGroup<FlxText>;
var lobbyPlayers:Array<String> = [];
var lobbyRoomText:FlxText;
var waitDots:Int = 0;
var waitDotTimer:Float = 0;
var playerColors:Array<Int> = [0xFFFFEE00, 0xFF00CCFF, 0xFFFF6699, 0xFF66FF66, 0xFFFF9933, 0xFFCC66FF];

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
var netSendAccum:Float = 0;
var NET_SEND_INTERVAL:Float = 0.05;

var gameMode:Int = 0;
var gameModes:Array<String> = ["DEFAULT", "VERSUS", "HARDMODE", "GHOST TAG", "SPEED", "LOW GRAVITY", "INVERTED", "CHAOS"];
var isHost:Bool = false;
var tagger:String = "";

var lbSolo:Array<Dynamic> = [];
var lbMulti:Array<Dynamic> = [];
var lbCategory:Int = 0;
var lbScroll:Int = 0;

var currentTrack:String = "";
var musicTween:FlxTween;

function playMusicTrack(track:String) {
    if (currentTrack == track) return;
    currentTrack = track;
    if (musicTween != null) musicTween.cancel();
    if (FlxG.sound.music != null && FlxG.sound.music.playing) {
        musicTween = FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.5, {onComplete: function(t) {
            switchTrackReal(track);
        }});
    } else {
        switchTrackReal(track);
    }
}

function switchTrackReal(track:String) {
    if (track == "") {
        if (FlxG.sound.music != null) FlxG.sound.music.stop();
    } else {
        FlxG.sound.playMusic(Paths.music("flappy/" + track), 0, true);
        musicTween = FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.5);
    }
}

function create() {
    if (FlxG.save.data.flappyNickname != null) myNickname = FlxG.save.data.flappyNickname;
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;
    loadCoins();
    loadShopData();
    loadLeaderboards();
    
    var bgData = getBGData(equippedBGId);
    FlxG.camera.bgColor = bgData.bg;
    uiCam = new FlxCamera(); 
    uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);
    
    skyFar = new FlxBackdrop(Paths.image('menus/flappy/sky'), 0x01, 0, 0); 
    skyFar.scale.set(2.5, 2.5); 
    skyFar.updateHitbox(); 
    skyFar.y = FlxG.height - skyFar.height - 40;
    skyFar.velocity.x = -15; 
    skyFar.alpha = 0.4; 
    skyFar.color = bgData.sky; 
    add(skyFar);
    
    sky = new FlxBackdrop(Paths.image('menus/flappy/sky'), 0x01, 0, 0); 
    sky.scale.set(2, 2); 
    sky.updateHitbox();
    sky.y = FlxG.height - sky.height; 
    sky.velocity.x = -40; 
    sky.color = bgData.sky; 
    add(sky);
    
    cloudGroup = new FlxTypedGroup(); add(cloudGroup);
    bgPropGroup = new FlxTypedGroup(); add(bgPropGroup);
    for (ci in 0...6) spawnCloud(true);
    
    pipeShadowGroup = new FlxTypedGroup(); add(pipeShadowGroup);
    pipes = new FlxTypedGroup(); add(pipes);
    pipeCapGroup = new FlxTypedGroup(); add(pipeCapGroup);
    pipeHighlightGroup = new FlxTypedGroup(); add(pipeHighlightGroup);
    
    powerupGlowGroup = new FlxTypedGroup(); add(powerupGlowGroup);
    powerups = new FlxTypedGroup(); add(powerups);
    powerupLabelGroup = new FlxTypedGroup(); add(powerupLabelGroup);
    
    trailGroup = new FlxTypedGroup(); add(trailGroup);
    vfxGroup = new FlxTypedGroup(); add(vfxGroup);
    playerGroup = new FlxTypedGroup(); add(playerGroup);
    nickTagGroup = new FlxTypedGroup(); add(nickTagGroup);
    emoteGroup = new FlxTypedGroup(); add(emoteGroup);
    scorePopGroup = new FlxTypedGroup(); add(scorePopGroup);
    
    groundDirt = new FlxSprite(0, FlxG.height - 30).makeGraphic(FlxG.width, 30, bgData.dirt); add(groundDirt);
    ground = new FlxSprite(0, FlxG.height - 30).makeGraphic(FlxG.width, 6, bgData.ground); add(ground);
    groundLine = new FlxSprite(0, FlxG.height - 32).makeGraphic(FlxG.width, 2, bgData.line); add(groundLine);
    
    grassGroup = new FlxTypedGroup(); add(grassGroup); 
    spawnGrassTufts();
    
    var skinData = getSkinData(equippedSkinId);
    bird = new FlxSprite(300, FlxG.height / 2).makeGraphic(38, 32, skinData.color); 
    bird.antialiasing = true; add(bird);
    birdWing = new FlxSprite(0, 0).makeGraphic(18, 12, darkenColor(skinData.color, 0.7)); 
    birdWing.antialiasing = true; add(birdWing);
    birdEye = new FlxSprite(0, 0).makeGraphic(10, 10, 0xFFFFFFFF); add(birdEye);
    birdBeak = new FlxSprite(0, 0).makeGraphic(14, 8, 0xFFFF8800); add(birdBeak);
    birdHat1 = new FlxSprite(0, 0).makeGraphic(20, 20, 0x00000000); add(birdHat1);
    birdHat2 = new FlxSprite(0, 0).makeGraphic(20, 20, 0x00000000); add(birdHat2);
    
    birdNickTag = new FlxText(0, 0, 200, myNickname, 12);
    birdNickTag.setFormat(Paths.font(currentFont), 12, 0xFFFFFFFF, "center", 1, 0xFF000000); 
    birdNickTag.cameras = [uiCam]; add(birdNickTag);
    
    crown = new FlxSprite(0, 0).makeGraphic(22, 12, 0xFFFFD700); 
    crown.visible = false;
    crown.antialiasing = true; add(crown);
    crownGem = new FlxSprite(0, 0).makeGraphic(6, 6, 0xFFFF0000); 
    crownGem.visible = false; add(crownGem);
    
    vignette = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000); 
    vignette.cameras = [uiCam]; 
    vignette.alpha = 0; add(vignette);
    
    leaderboardGroup = new FlxTypedGroup(); add(leaderboardGroup);
    lobbyBgGroup = new FlxTypedGroup(); add(lobbyBgGroup);
    lobbySlotGroup = new FlxTypedGroup(); add(lobbySlotGroup);
    playerSidebar = new FlxTypedGroup(); add(playerSidebar);
    shopUIGroup = new FlxTypedGroup(); add(shopUIGroup);
    shopTextGroup = new FlxTypedGroup(); add(shopTextGroup);
    
    setupUI(); 
    applyBGTheme();
    goToState(myNickname == "Player" ? "NICKNAME" : "MENU");
    fetchServerStatus();
    new FlxTimer().start(15, function(t) { fetchServerStatus(); }, 0);
}

function getSkinData(id:String):Dynamic {
    for (i in 0...allSkins.length) if (allSkins[i].id == id) return allSkins[i];
    return allSkins[0];
}

function getTrailData(id:String):Dynamic {
    for (i in 0...allTrails.length) if (allTrails[i].id == id) return allTrails[i];
    return allTrails[0];
}

function getBGData(id:String):Dynamic {
    for (i in 0...allBGs.length) if (allBGs[i].id == id) return allBGs[i];
    return allBGs[0];
}

function loadLeaderboards() {
    if (FlxG.save.data.flappyLbSolo != null) lbSolo = FlxG.save.data.flappyLbSolo;
    if (FlxG.save.data.flappyLbMulti != null) lbMulti = FlxG.save.data.flappyLbMulti;
}

function saveToLeaderboard(scoreVal:Int, multi:Bool) {
    var targetArray = multi ? lbMulti : lbSolo;
    var found = false;
    for (i in 0...targetArray.length) {
        if (targetArray[i].name == myNickname) {
            found = true;
            if (scoreVal > targetArray[i].score) targetArray[i].score = scoreVal;
            break;
        }
    }
    if (!found) targetArray.push({name: myNickname, score: scoreVal});
    targetArray.sort(function(a:Dynamic, b:Dynamic):Int { return b.score - a.score; });
    if (targetArray.length > 100) targetArray.pop();
    if (multi) FlxG.save.data.flappyLbMulti = targetArray;
    else FlxG.save.data.flappyLbSolo = targetArray;
    FlxG.save.flush();
}

function darkenColor(col:Int, factor:Float):Int { 
    var r = Std.int(((col >> 16) & 0xFF) * factor);
    var g = Std.int(((col >> 8) & 0xFF) * factor); 
    var b = Std.int((col & 0xFF) * factor);
    return 0xFF000000 | (r << 16) | (g << 8) | b;
}

function lightenColor(col:Int, factor:Float):Int { 
    var r = Std.int(Math.min(255, ((col >> 16) & 0xFF) * factor));
    var g = Std.int(Math.min(255, ((col >> 8) & 0xFF) * factor)); 
    var b = Std.int(Math.min(255, (col & 0xFF) * factor));
    return 0xFF000000 | (r << 16) | (g << 8) | b; 
}

function spawnCloud(initialPlace:Bool) { 
    var w = FlxG.random.int(80, 180);
    var h = FlxG.random.int(25, 50); 
    var c = new FlxSprite(0, 0).makeGraphic(w, h, 0xFFFFFFFF); 
    c.alpha = FlxG.random.float(0.06, 0.2);
    c.y = FlxG.random.float(20, FlxG.height * 0.5); 
    c.x = initialPlace ? FlxG.random.float(-100, FlxG.width + 100) : FlxG.width + FlxG.random.float(20, 200);
    c.velocity.x = FlxG.random.float(-25, -8); 
    c.scale.set(1, FlxG.random.float(0.4, 0.7)); 
    cloudGroup.add(c); 
}

function spawnGrassTufts() { 
    grassGroup.clear(); 
    var bgData = getBGData(equippedBGId);
    var gc = bgData.grass;
    for (gi in 0...40) { 
        var gx = FlxG.random.float(0, FlxG.width); 
        var gw = FlxG.random.int(3, 7); 
        var gh = FlxG.random.int(6, 14);
        var tuft = new FlxSprite(gx, FlxG.height - 30 - gh).makeGraphic(gw, gh, gc); 
        tuft.alpha = FlxG.random.float(0.5, 0.9); 
        grassGroup.add(tuft);
    } 
}

function spawnBGProp(initial:Bool = false) {
    var bgData = getBGData(equippedBGId);
    var pType = bgData.propType;
    var w = 50; var h = 50; var col = 0xFFFFFFFF; var yPos = FlxG.height - 30;
    
    if (pType == "building" || pType == "neonbuilding") {
        w = FlxG.random.int(60, 140); h = FlxG.random.int(100, FlxG.height - 80);
        col = (pType == "neonbuilding") ? (FlxG.random.bool(50) ? 0xFF0A0A1A : 0xFF111122) : (FlxG.random.bool(50) ? 0xFF1A0033 : 0xFF220044);
    } else if (pType == "tree") {
        w = FlxG.random.int(20, 40); h = FlxG.random.int(150, 300); col = darkenColor(bgData.ground, 0.5);
    } else if (pType == "cactus") {
        w = FlxG.random.int(20, 35); h = FlxG.random.int(80, 160); col = 0xFF3A8C2F;
    } else if (pType == "snowman") {
        w = FlxG.random.int(40, 70); h = FlxG.random.int(80, 120); col = 0xFFFFFFFF;
    } else if (pType == "lava") {
        w = FlxG.random.int(40, 90); h = FlxG.random.int(100, 250); col = 0xFFFF4500;
    } else if (pType == "ufo" || pType == "planet") {
        w = FlxG.random.int(40, 100); h = w; col = FlxG.random.bool(50) ? 0xFF555555 : 0xFF333333; yPos = FlxG.random.float(50, FlxG.height - 150);
    } else if (pType == "lollipop") {
        w = FlxG.random.int(10, 20); h = FlxG.random.int(100, 200); col = 0xFFFFFFFF;
    } else if (pType == "tombstone") {
        w = FlxG.random.int(40, 60); h = FlxG.random.int(50, 90); col = 0xFF696969;
    } else if (pType == "crystal") {
        w = FlxG.random.int(20, 50); h = FlxG.random.int(100, 300); col = FlxG.random.bool(50) ? 0xFF8A2BE2 : 0xFF4B0082;
    } else if (pType == "coral") {
        w = FlxG.random.int(30, 80); h = FlxG.random.int(60, 180); col = FlxG.random.bool(50) ? 0xFFFF7F50 : 0xFFFF4500;
    } else {
        w = FlxG.random.int(80, 200); h = FlxG.random.int(40, 100); col = darkenColor(bgData.ground, 0.6);
    }

    var prop = bgPropGroup.recycle(FlxSprite);
    if (prop == null) prop = new FlxSprite();
    prop.makeGraphic(w, h, col);
    var startX = initial ? FlxG.random.float(0, FlxG.width) : FlxG.width + FlxG.random.float(10, 100);
    prop.reset(startX, yPos - h);
    prop.alpha = 0.5 + FlxG.random.float(0, 0.4);
    prop.active = true;
    bgPropGroup.add(prop);
}

function applyBGTheme() {
    var bgData = getBGData(equippedBGId);
    FlxG.camera.bgColor = bgData.bg;
    sky.color = bgData.sky;
    skyFar.color = bgData.sky;
    ground.makeGraphic(FlxG.width, 6, bgData.ground);
    groundDirt.makeGraphic(FlxG.width, 30, bgData.dirt);
    groundLine.makeGraphic(FlxG.width, 2, bgData.line);
    spawnGrassTufts();
    bgPropGroup.clear();
    for (i in 0...12) spawnBGProp(true);
}

function applyHat(hatId:String, target1:FlxSprite, target2:FlxSprite, bx:Float, by:Float, angle:Float, squash:Float) {
    target1.visible = false; target2.visible = false;
    if (hatId == "none") return;
    target1.visible = true; target1.angle = angle;
    target2.visible = true; target2.angle = angle;
    var ox = bx + 19; var oy = by + 16 * squash - 16;
    
    if (hatId == "crown") {
        target1.makeGraphic(20, 10, 0xFFFFD700); target1.setPosition(ox - 10, oy - 10); target2.visible = false;
    } else if (hatId == "bigcrown") {
        target1.makeGraphic(26, 16, 0xFFFFD700); target1.setPosition(ox - 13, oy - 16);
        target2.makeGraphic(8, 8, 0xFFFF0000); target2.setPosition(ox - 4, oy - 10);
    } else if (hatId == "halo") {
        target1.makeGraphic(24, 4, 0xFFFFFF00); target1.setPosition(ox - 12, oy - 20); target2.visible = false;
    } else if (hatId == "headband") {
        target1.makeGraphic(38, 6, 0xFFFF0000); target1.setPosition(bx, by + 4); target2.visible = false;
    } else if (hatId == "cowboy") {
        target1.makeGraphic(36, 6, 0xFF8B4513); target1.setPosition(ox - 18, oy - 6);
        target2.makeGraphic(18, 14, 0xFF8B4513); target2.setPosition(ox - 9, oy - 20);
    } else if (hatId == "chef") {
        target1.makeGraphic(16, 12, 0xFFFFFFFF); target1.setPosition(ox - 8, oy - 12);
        target2.makeGraphic(24, 14, 0xFFFFFFFF); target2.setPosition(ox - 12, oy - 26);
    } else if (hatId == "wizard") {
        target1.makeGraphic(28, 6, 0xFF4B0082); target1.setPosition(ox - 14, oy - 6);
        target2.makeGraphic(14, 20, 0xFF4B0082); target2.setPosition(ox - 7, oy - 26);
    } else if (hatId == "antenna") {
        target1.makeGraphic(4, 16, 0xFF888888); target1.setPosition(ox - 2, oy - 16);
        target2.makeGraphic(8, 8, 0xFFFF0000); target2.setPosition(ox - 4, oy - 24);
    } else if (hatId == "brain") {
        target1.makeGraphic(20, 12, 0xFFFF66AA); target1.setPosition(ox - 10, oy - 12); target2.visible = false;
    } else if (hatId == "horns") {
        target1.makeGraphic(6, 12, 0xFF8B0000); target1.setPosition(ox - 12, oy - 12); target1.angle = angle - 20;
        target2.makeGraphic(6, 12, 0xFF8B0000); target2.setPosition(ox + 6, oy - 12); target2.angle = angle + 20;
    } else if (hatId == "ufo") {
        target1.makeGraphic(30, 8, 0xFF888888); target1.setPosition(ox - 15, oy - 16);
        target2.makeGraphic(14, 10, 0xFF00FFCC); target2.setPosition(ox - 7, oy - 26);
    } else if (hatId == "helmet") {
        target1.makeGraphic(24, 20, 0xFFB0C4DE); target1.setPosition(ox - 12, oy - 16);
        target2.makeGraphic(4, 14, 0xFF000000); target2.setPosition(ox + 4, oy - 12);
    } else if (hatId == "cap") {
        target1.makeGraphic(20, 12, 0xFF1E90FF); target1.setPosition(ox - 10, oy - 12);
        target2.makeGraphic(12, 4, 0xFF1E90FF); target2.setPosition(ox + 10, oy - 4);
    } else if (hatId == "pirate") {
        target1.makeGraphic(30, 12, 0xFF222222); target1.setPosition(ox - 15, oy - 12);
        target2.makeGraphic(6, 6, 0xFF000000); target2.setPosition(ox + 10, oy + 4);
    }
}

function loadCoins() { 
    if (FlxG.save.data.flappyCoins != null) flappyCoins = FlxG.save.data.flappyCoins; 
    else flappyCoins = 0;
}

function saveCoins() { 
    FlxG.save.data.flappyCoins = flappyCoins; 
    FlxG.save.flush(); 
}

function addCoins(amount:Int) { 
    flappyCoins += amount; 
    coinEarnedThisRound += amount; 
    saveCoins(); 
    refreshCoinUI();
}

function spendCoins(amount:Int):Bool { 
    if (flappyCoins < amount) return false; 
    flappyCoins -= amount; 
    saveCoins(); 
    refreshCoinUI(); 
    return true;
}

function refreshCoinUI() { 
    if (coinText != null) { 
        coinText.text = "" + flappyCoins; 
        coinBounce = 1.3;
    } 
}

function loadShopData() {
    var ownedSkins:Array<String> = ["default"];
    var ownedTrails:Array<String> = ["none"];
    var ownedBGs:Array<String> = ["day"];
    if (FlxG.save.data.flappyOwnedSkinsV3 != null) ownedSkins = FlxG.save.data.flappyOwnedSkinsV3;
    if (FlxG.save.data.flappyOwnedTrailsV3 != null) ownedTrails = FlxG.save.data.flappyOwnedTrailsV3;
    if (FlxG.save.data.flappyOwnedBGsV3 != null) ownedBGs = FlxG.save.data.flappyOwnedBGsV3;
    
    if (FlxG.save.data.flappyEquippedSkinId != null) equippedSkinId = FlxG.save.data.flappyEquippedSkinId;
    if (FlxG.save.data.flappyEquippedTrailId != null) equippedTrailId = FlxG.save.data.flappyEquippedTrailId;
    if (FlxG.save.data.flappyEquippedBGId != null) equippedBGId = FlxG.save.data.flappyEquippedBGId;
    
    shopSkins = [];
    for (i in 0...allSkins.length) {
        var item = Reflect.copy(allSkins[i]);
        item.owned = ownedSkins.indexOf(item.id) != -1;
        shopSkins.push(item);
    }
    shopTrails = []; 
    for (i in 0...allTrails.length) {
        var item = Reflect.copy(allTrails[i]);
        item.owned = ownedTrails.indexOf(item.id) != -1;
        shopTrails.push(item);
    }
    shopBGs = []; 
    for (i in 0...allBGs.length) {
        var item = Reflect.copy(allBGs[i]);
        item.owned = ownedBGs.indexOf(item.id) != -1;
        shopBGs.push(item);
    }

    var sorter = function(a:Dynamic, b:Dynamic):Int {
        if (a.price != b.price) return a.price - b.price;
        return (a.name < b.name) ? -1 : 1;
    };
    shopSkins.sort(sorter);
    shopTrails.sort(sorter);
    shopBGs.sort(sorter);
}

function saveShopData() {
    var ownedSkins:Array<String> = [];
    for (i in 0...shopSkins.length) if (shopSkins[i].owned) ownedSkins.push(shopSkins[i].id);
    var ownedTrails:Array<String> = [];
    for (i in 0...shopTrails.length) if (shopTrails[i].owned) ownedTrails.push(shopTrails[i].id);
    var ownedBGs:Array<String> = [];
    for (i in 0...shopBGs.length) if (shopBGs[i].owned) ownedBGs.push(shopBGs[i].id);
    
    FlxG.save.data.flappyOwnedSkinsV3 = ownedSkins;
    FlxG.save.data.flappyOwnedTrailsV3 = ownedTrails;
    FlxG.save.data.flappyOwnedBGsV3 = ownedBGs;
    FlxG.save.data.flappyEquippedSkinId = equippedSkinId;
    FlxG.save.data.flappyEquippedTrailId = equippedTrailId;
    FlxG.save.data.flappyEquippedBGId = equippedBGId;
    FlxG.save.flush();
}

function setupUI() {
    titleText = makeText(0, 55, FlxG.width, "FLAPPY ROYALE", 72, 0xFFFFEE00);
    subtitleText = makeText(0, 135, FlxG.width, "BATTLE ROYALE", 20, 0xFFFF9933); 
    subtitleText.alpha = 0.7;
    scoreShadow = makeText(3, 27, FlxG.width, "0", 36, 0xFF000000);
    scoreShadow.alpha = 0.4; 
    scoreShadow.visible = false;
    scoreText = makeText(0, 24, FlxG.width, "0", 36, 0xFFFFFFFF); 
    scoreText.visible = false;
    levelText = makeText(0, 66, FlxG.width, "LEVEL 1", 20, 0xFF00FFCC); 
    levelText.visible = false;
    statusText = makeText(20, FlxG.height - 28, 350, "", 13, 0xFFAABBCC); 
    statusText.alignment = "left"; 
    statusText.alpha = 0.5;
    lobbyText = makeText(0, FlxG.height * 0.78, FlxG.width, "", 24, 0xFFFFEE00);
    typingBg = new FlxSprite(Std.int(FlxG.width * 0.2), Std.int(FlxG.height * 0.81)).makeGraphic(Std.int(FlxG.width * 0.6), 48, 0xFF1A1A2E); 
    typingBg.alpha = 0.7; 
    typingBg.cameras = [uiCam]; 
    add(typingBg);
    typingBg.visible = false;
    typingText = makeText(0, FlxG.height * 0.82, FlxG.width, "", 34, 0xFFFFFFFF);
    coinIconText = makeText(FlxG.width - 240, 10, 30, "C", 20, 0xFFFFD700);
    coinText = makeText(FlxG.width - 210, 10, 190, "" + flappyCoins, 20, 0xFFFFD700); 
    coinText.alignment = "right";
    myEmoteText = new FlxText(0, 0, 200, "", 32); 
    myEmoteText.setFormat(Paths.font(currentFont), 32, 0xFFFFFFFF, "center", 2, 0xFF000000); 
    myEmoteText.cameras = [uiCam]; add(myEmoteText);
    currentLeader = myNickname;
    lobbyRoomText = makeText(0, FlxG.height * 0.12, FlxG.width, "", 22, 0xFF88CCFF); 
    lobbyRoomText.visible = false;
}

function makeText(x:Float, y:Float, w:Float, text:String, size:Int, color:Int):FlxText { 
    var t = new FlxText(x, y, w, text, size);
    t.setFormat(Paths.font(currentFont), size, color, "center", 2, 0xFF000000); 
    t.cameras = [uiCam]; 
    add(t); 
    return t;
}

function goToState(s:String) {
    gameState = s; 
    typedInput = ""; 
    typingText.text = "";
    leaderboardGroup.clear(); 
    lobbySlotGroup.clear(); 
    lobbyBgGroup.clear();
    playerSidebar.clear(); 
    shopUIGroup.clear(); 
    shopTextGroup.clear();
    lobbyRoomText.visible = false;

    if (s == "NICKNAME" || s == "MENU" || s == "LEADERBOARD" || s == "SHOP") {
        netDisconnect();
        isMultiplayer = false; 
        lobbyPlayers = []; 
        resetMultiplayerData();
    }

    titleText.visible = (s == "NICKNAME" || s == "MENU" || s == "ROOM_INPUT" || s == "LEADERBOARD");
    subtitleText.visible = (s == "MENU");
    lobbyText.visible = true;
    typingText.visible = (s == "NICKNAME" || s == "ROOM_INPUT");
    typingBg.visible = (s == "NICKNAME" || s == "ROOM_INPUT");
    scoreText.visible = false; 
    scoreShadow.visible = false; 
    levelText.visible = false;
    coinText.visible = true; 
    coinIconText.visible = true; 
    vignette.alpha = 0;

    var showBird = (s == "PLAYING" || s == "DEAD");
    bird.visible = showBird; 
    birdWing.visible = showBird; 
    birdEye.visible = showBird; 
    birdBeak.visible = showBird;
    birdHat1.visible = showBird;
    birdHat2.visible = showBird;
    birdNickTag.visible = showBird;

    switch(s) {
        case "NICKNAME": 
            lobbyText.text = "CHOOSE YOUR NAME";
            playMusicTrack("mainTheme");
        case "MENU": 
            lobbyText.text = "[1] SOLO   [2] MULTI   [3] SCORES   [4] SHOP   [ESC] EXIT";
            playMusicTrack("mainTheme");
        case "ROOM_INPUT": 
            lobbyText.text = "ENTER 4-LETTER ROOM CODE";
            playMusicTrack("mainTheme");
        case "LEADERBOARD": 
            lobbyText.text = ""; 
            lbCategory = 0; 
            lbScroll = 0; 
            renderLeaderboardLocal();
            playMusicTrack("mainTheme");
        case "SHOP": 
            lobbyText.text = "";
            shopCategory = 0; 
            shopScroll = 0; 
            shopCursor = 0; 
            renderShop();
            playMusicTrack("shopTheme");
    }
}

function resetMultiplayerData() { 
    playerMap = {}; 
    playerWingMap = {};
    playerEyeMap = {}; 
    playerBeakMap = {}; 
    playerHat1Map = {};
    playerHat2Map = {};
    playerNickMap = {}; 
    playerSkinIdMap = {};
    scoreMap = {}; 
    deadMap = {}; 
    emoteMap = {};
    targetYMap = {}; 
    activePlayers = []; 
    currentLeader = myNickname;
}

function renderShop() {
    shopUIGroup.clear(); shopTextGroup.clear();
    var catNames = ["BIRD SKINS", "TRAILS", "BACKGROUNDS"];
    var catalog:Array<Dynamic>; 
    var equippedId:String;
    if (shopCategory == 0) { catalog = shopSkins; equippedId = equippedSkinId; }
    else if (shopCategory == 1) { catalog = shopTrails; equippedId = equippedTrailId; }
    else { catalog = shopBGs; equippedId = equippedBGId; }
    
    if (shopCursor >= catalog.length) shopCursor = catalog.length - 1;
    if (shopCursor < 0) shopCursor = 0;
    
    var maxVisible = 7;
    if (shopCursor < shopScroll) shopScroll = shopCursor;
    if (shopCursor >= shopScroll + maxVisible) shopScroll = shopCursor - maxVisible + 1;
    if (shopScroll < 0) shopScroll = 0;

    var headerBg = new FlxSprite(0, 0).makeGraphic(FlxG.width, Std.int(FlxG.height * 0.13), 0xFF0D0D1A); 
    headerBg.alpha = 0.75;
    headerBg.cameras = [uiCam]; 
    shopUIGroup.add(headerBg);
    var shopTitle = new FlxText(0, 12, FlxG.width, "SHOP", 48); 
    shopTitle.setFormat(Paths.font(currentFont), 48, 0xFFFFEE00, "center", 3, 0xFF000000);
    shopTitle.cameras = [uiCam]; 
    shopTextGroup.add(shopTitle);
    var balanceText = new FlxText(0, 62, FlxG.width, "BALANCE: $" + flappyCoins, 18);
    balanceText.setFormat(Paths.font(currentFont), 18, 0xFFFFD700, "center", 1, 0xFF000000); 
    balanceText.cameras = [uiCam]; 
    shopTextGroup.add(balanceText);

    var tabY = Std.int(FlxG.height * 0.14);
    var tabBarBg = new FlxSprite(0, tabY).makeGraphic(FlxG.width, 32, 0xFF111122);
    tabBarBg.alpha = 0.6; 
    tabBarBg.cameras = [uiCam]; 
    shopUIGroup.add(tabBarBg);
    for (ci in 0...3) {
        var isActive = ci == shopCategory;
        var tabCol = isActive ? 0xFFFFEE00 : 0xFF666666; 
        var tabW = FlxG.width / 3;
        var tab = new FlxText(Std.int(ci * tabW), tabY + 4, Std.int(tabW), (isActive ? "> " : "  ") + catNames[ci], 17);
        tab.setFormat(Paths.font(currentFont), 17, tabCol, "center", 2, 0xFF000000); 
        tab.cameras = [uiCam]; 
        shopTextGroup.add(tab);
        if (isActive) { 
            var ul = new FlxSprite(Std.int(ci * tabW + tabW * 0.15), tabY + 28).makeGraphic(Std.int(tabW * 0.7), 3, 0xFFFFEE00);
            ul.cameras = [uiCam]; 
            shopUIGroup.add(ul); 
        }
    }

    var startY = Std.int(FlxG.height * 0.22);
    var slotH = 48; 
    var listW = Std.int(FlxG.width * 0.62); 
    var listX = Std.int(FlxG.width * 0.04);
    for (idx in 0...catalog.length) {
        if (idx < shopScroll || idx >= shopScroll + maxVisible) continue;
        var item = catalog[idx]; 
        var slotY = startY + ((idx - shopScroll) * slotH);
        var isEquipped = item.id == equippedId;
        var isOwned = item.owned; 
        var isCursor = idx == shopCursor;
        var bgCol = isCursor ? 0xFF2A2A4E : (isEquipped ? 0xFF1A3A1A : 0xFF12121E);
        var slotBg = new FlxSprite(listX, Std.int(slotY)).makeGraphic(listW, Std.int(slotH - 4), bgCol);
        slotBg.alpha = isCursor ? 0.85 : 0.5; 
        slotBg.cameras = [uiCam]; 
        shopUIGroup.add(slotBg);
        if (isCursor) { 
            var ca = new FlxText(listX + 4, slotY + 8, 30, ">", 24);
            ca.setFormat(Paths.font(currentFont), 24, 0xFFFFEE00, "left", 2, 0xFF000000); 
            ca.cameras = [uiCam]; 
            shopTextGroup.add(ca); 
            var hlBar = new FlxSprite(listX, Std.int(slotY)).makeGraphic(4, Std.int(slotH - 4), 0xFFFFEE00);
            hlBar.cameras = [uiCam]; 
            shopUIGroup.add(hlBar); 
        }
        var swX = listX + 34;
        var swBorder = new FlxSprite(swX, Std.int(slotY + 6)).makeGraphic(34, 34, isCursor ? 0xFFFFEE00 : 0xFF444444); 
        swBorder.cameras = [uiCam]; 
        shopUIGroup.add(swBorder);
        
        var swatchCol = 0xFFFFFFFF;
        if (shopCategory == 0) swatchCol = item.color;
        else if (shopCategory == 1) swatchCol = item.color;
        else if (shopCategory == 2) swatchCol = item.bg;
        
        var swatch = new FlxSprite(swX + 2, Std.int(slotY + 8)).makeGraphic(30, 30, swatchCol); 
        swatch.cameras = [uiCam]; 
        shopUIGroup.add(swatch);
        var statusStr = "";
        var statusCol:Int = 0xFF888888;
        if (isEquipped) { statusStr = "EQUIPPED"; statusCol = 0xFF00FF88; } 
        else if (isOwned) { statusStr = "OWNED"; statusCol = 0xFF88AAFF; } 
        else { statusStr = "$" + item.price; statusCol = 0xFFFFD700; }
        var nameCol = isCursor ? 0xFFFFFFFF : (isEquipped ? 0xFF00FF88 : (isOwned ? 0xFFCCCCCC : 0xFF999999));
        var nameLabel = new FlxText(swX + 44, slotY + 4, Std.int(listW * 0.5), item.name, 22);
        nameLabel.setFormat(Paths.font(currentFont), 22, nameCol, "left", 2, 0xFF000000); 
        nameLabel.cameras = [uiCam]; 
        shopTextGroup.add(nameLabel);
        var statLabel = new FlxText(swX + 44, slotY + 26, Std.int(listW * 0.5), statusStr, 14);
        statLabel.setFormat(Paths.font(currentFont), 14, statusCol, "left", 1, 0xFF000000); 
        statLabel.cameras = [uiCam]; 
        shopTextGroup.add(statLabel);
    }

    var panelX = Std.int(FlxG.width * 0.70);
    var panelY = Std.int(FlxG.height * 0.22); 
    var panelW = Std.int(FlxG.width * 0.28); 
    var panelH = Std.int(FlxG.height * 0.55);

    var prevPanelBgBase = new FlxSprite(panelX, panelY).makeGraphic(panelW, panelH, 0xFF111122); 
    prevPanelBgBase.alpha = 0.6; 
    prevPanelBgBase.cameras = [uiCam]; 
    shopUIGroup.add(prevPanelBgBase);

    if (shopCategory == 2 && shopCursor < catalog.length) {
        var bgItem = catalog[shopCursor];
        var pBg = new FlxSprite(panelX + 4, panelY + 28).makeGraphic(panelW - 8, 130, bgItem.bg);
        pBg.cameras = [uiCam];
        shopUIGroup.add(pBg);
        var pGd = new FlxSprite(panelX + 4, panelY + 148).makeGraphic(panelW - 8, 10, bgItem.ground);
        pGd.cameras = [uiCam];
        shopUIGroup.add(pGd);
    }

    var prevTitle = new FlxText(panelX, panelY + 8, panelW, "PREVIEW", 16); 
    prevTitle.setFormat(Paths.font(currentFont), 16, 0xFF666666, "center", 1, 0xFF000000); 
    prevTitle.cameras = [uiCam];
    shopTextGroup.add(prevTitle);
    
    var prevBirdX = Std.int(panelX + panelW / 2 - 32); 
    var prevBirdY = Std.int(panelY + 50);

    var previewSkinData = getSkinData(equippedSkinId);
    if (shopCategory == 0 && shopCursor < catalog.length) previewSkinData = catalog[shopCursor];

    var previewTrailIdLocal = equippedTrailId;
    if (shopCategory == 1 && shopCursor < catalog.length) previewTrailIdLocal = catalog[shopCursor].id;
    var previewTrailData = getTrailData(previewTrailIdLocal);

    if (previewTrailIdLocal != "none") {
        var tCol = previewTrailData.color;
        if (previewTrailIdLocal == "rainbow") tCol = 0xFFFF00FF;
        if (previewTrailIdLocal == "glitch") tCol = 0xFF00FFCC;
        if (previewTrailIdLocal == "snow") tCol = 0xFFFFFFFF;
        if (previewTrailIdLocal == "hearts") tCol = 0xFFFF4488;
        if (previewTrailIdLocal == "toxic") tCol = 0xFF44FF00;
        
        for (i in 0...3) {
            var ts = new FlxSprite(prevBirdX - 12 - (i * 18), prevBirdY + 18).makeGraphic(14, 14, tCol);
            ts.alpha = 0.7 - (i * 0.2);
            ts.cameras = [uiCam];
            shopUIGroup.add(ts);
        }
    }
    
    var pb = new FlxSprite(prevBirdX, prevBirdY).makeGraphic(64, 52, previewSkinData.color); 
    pb.cameras = [uiCam]; shopUIGroup.add(pb);
    var pw = new FlxSprite(prevBirdX - 6, prevBirdY + 20).makeGraphic(28, 18, darkenColor(previewSkinData.color, 0.7)); 
    pw.cameras = [uiCam]; shopUIGroup.add(pw);
    var pe = new FlxSprite(prevBirdX + 42, prevBirdY + 10).makeGraphic(16, 16, 0xFFFFFFFF); 
    pe.cameras = [uiCam]; shopUIGroup.add(pe);
    var pep = new FlxSprite(prevBirdX + 48, prevBirdY + 14).makeGraphic(8, 8, 0xFF000000); 
    pep.cameras = [uiCam]; shopUIGroup.add(pep);
    var pbk = new FlxSprite(prevBirdX + 58, prevBirdY + 22).makeGraphic(20, 12, 0xFFFF8800); 
    pbk.cameras = [uiCam]; shopUIGroup.add(pbk);
    
    var hat1 = new FlxSprite(0,0); var hat2 = new FlxSprite(0,0);
    applyHat(previewSkinData.hat, hat1, hat2, prevBirdX, prevBirdY, 0, 1.0);
    hat1.cameras = [uiCam]; hat2.cameras = [uiCam];
    shopUIGroup.add(hat1); shopUIGroup.add(hat2);

    if (shopCursor < catalog.length) {
        var selItem = catalog[shopCursor]; 
        var equId = equippedId;
        var selName = new FlxText(panelX, prevBirdY + 80, panelW, selItem.name, 22); 
        selName.setFormat(Paths.font(currentFont), 22, 0xFFFFFFFF, "center", 2, 0xFF000000); 
        selName.cameras = [uiCam];
        shopTextGroup.add(selName);
        var selStatus = ""; 
        var selStatCol:Int = 0xFFFFD700;
        if (selItem.id == equId) { selStatus = "EQUIPPED"; selStatCol = 0xFF00FF88; } 
        else if (selItem.owned) { selStatus = "PRESS ENTER TO EQUIP"; selStatCol = 0xFF88AAFF; } 
        else { selStatus = "PRESS ENTER TO BUY\n$" + selItem.price; selStatCol = 0xFFFFD700; }
        var selStat = new FlxText(panelX, prevBirdY + 110, panelW, selStatus, 14);
        selStat.setFormat(Paths.font(currentFont), 14, selStatCol, "center", 1, 0xFF000000); 
        selStat.cameras = [uiCam]; 
        shopTextGroup.add(selStat);
    }

    var instrBg = new FlxSprite(0, Std.int(FlxG.height * 0.84)).makeGraphic(FlxG.width, 30, 0xFF0D0D1A);
    instrBg.alpha = 0.6; 
    instrBg.cameras = [uiCam]; 
    shopUIGroup.add(instrBg);
    var instr = new FlxText(0, FlxG.height * 0.845, FlxG.width, "[LEFT/RIGHT] TAB   [UP/DOWN] SELECT   [ENTER] BUY/EQUIP   [ESC] BACK", 14);
    instr.setFormat(Paths.font(currentFont), 14, 0xFF777777, "center", 1, 0xFF000000); 
    instr.cameras = [uiCam]; 
    shopTextGroup.add(instr);
    lobbyText.text = "";
}

function updateShop() {
    var catalog:Array<Dynamic>; 
    if (shopCategory == 0) catalog = shopSkins;
    else if (shopCategory == 1) catalog = shopTrails; 
    else catalog = shopBGs;
    
    if (FlxG.keys.justPressed.UP && shopCursor > 0) { shopCursor--; renderShop(); }
    if (FlxG.keys.justPressed.DOWN && shopCursor < catalog.length - 1) { shopCursor++; renderShop(); }
    if (FlxG.keys.justPressed.LEFT) { shopCategory = shopCategory - 1; if (shopCategory < 0) shopCategory = 2; shopCursor = 0; shopScroll = 0; renderShop(); }
    if (FlxG.keys.justPressed.RIGHT) { shopCategory = (shopCategory + 1) % 3; shopCursor = 0; shopScroll = 0; renderShop(); }
    if (FlxG.keys.justPressed.ENTER) shopInteract(shopCursor);
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU");
}

function shopInteract(idx:Int) {
    var catalog:Array<Dynamic>; 
    if (shopCategory == 0) catalog = shopSkins;
    else if (shopCategory == 1) catalog = shopTrails; 
    else catalog = shopBGs;
    if (idx < 0 || idx >= catalog.length) return; 
    var item = catalog[idx];
    if (item.owned) {
        if (shopCategory == 0) {
            equippedSkinId = item.id;
            bird.color = item.color;
        } else if (shopCategory == 1) {
            equippedTrailId = item.id;
        } else {
            equippedBGId = item.id;
            applyBGTheme();
        }
        saveShopData(); 
        FlxG.camera.flash(0x2200FF00, 0.15); 
        renderShop();
    } else {
        if (spendCoins(item.price)) { 
            item.owned = true; 
            saveShopData(); 
            FlxG.camera.flash(0x33FFD700, 0.3); 
            shopInteract(idx);
        } else { 
            FlxG.camera.flash(0x33FF0000, 0.2);
        }
    }
}

function netConnect(roomCode:String, nickname:String) { 
    netDisconnect(); 
    try { 
        connection = new Socket();
        connection.connect(new Host(SERVER_IP), SERVER_PORT); 
        netConnected = true; 
        netBuffer = ""; 
        connection.socket.setBlocking(false);
        new FlxTimer().start(0.3, function(t) { 
            try { 
                connection.write("JOIN_ROOM:" + roomCode + ":" + nickname + "\n"); 
                startNetPollTimer(); 
            } catch(e:Dynamic) {} 
        });
    } catch(e:Dynamic) { 
        netConnected = false; 
        lobbyText.text = "CONNECTION FAILED!"; 
        new FlxTimer().start(2, function(t) { goToState("MENU"); });
    } 
}

function netDisconnect() { 
    if (pollTimer != null) { pollTimer.cancel(); pollTimer = null; } 
    if (connection != null) { try { connection.destroy(); } catch(e:Dynamic) {} connection = null; } 
    netConnected = false;
    netBuffer = ""; 
}

function netSend(msg:String) { 
    if (!netConnected || connection == null) return; 
    try { connection.write(msg + "\n"); } catch(e:Dynamic) {} 
}

function netPoll() { 
    if (!netConnected || connection == null) return; 
    try { 
        var sock = connection.socket;
        var c = 0; 
        while (c < 20) { 
            c++; 
            try { 
                var line = sock.input.readLine();
                if (line == null) break; 
                line = StringTools.trim(line); 
                if (line.length == 0) continue; 
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
    pollTimer = new FlxTimer().start(0.1, function(tmr) { netPoll(); }, 0); 
}

function processNetLine(line:String) { 
    var parts = line.split(":"); 
    var cmd = parts[0];
    parts.splice(0, 1); 
    handleServerMessage(cmd, parts); 
}

function netOneShot(msg:String, delaySeconds:Float, callback:Dynamic) { 
    try { 
        var s = new Socket(); 
        s.connect(new Host(SERVER_IP), SERVER_PORT); 
        s.socket.setBlocking(false);
        new FlxTimer().start(0.5, function(t1) { 
            try { s.write(msg + "\n"); } catch(e:Dynamic) {} 
            new FlxTimer().start(1.5, function(t2) { 
                try { 
                    var d = s.read(); 
                    if (d != null && d.length > 0) { 
                        var lines = d.split("\n"); 
                        var fl = ""; 
                        for (li in 0...lines.length) { 
                            var tr = StringTools.trim(lines[li]); 
                            if (tr.length > 0) { fl = tr; break; } 
                        } 
                        if (fl.length > 0) callback(fl); 
                        else callback(null); 
                    } else callback(null); 
                } catch(e:Dynamic) { callback(null); } 
                try { s.destroy(); } catch(e2:Dynamic) {} 
            }, 1); 
        }, 1);
    } catch(e:Dynamic) { callback(null); } 
}

function handleServerMessage(cmd:String, args:Array<String>) {
    switch(cmd) {
        case "WAITING_FOR_HOST": 
            gameState = "LOBBY";
            playMusicTrack("mainTheme");
            addLobbyPlayer(myNickname); 
            refreshLobbyUI();
        case "GAME_ALREADY_STARTED": 
            lobbyText.text = "SPECTATING..."; 
            iAmDead = true; 
            bird.visible = false; 
            beginMultiplayer();
        case "ROOM_FULL": 
            lobbyText.text = "ROOM FULL!";
            new FlxTimer().start(2, function(t) { goToState("MENU"); });
        case "MODE_CHANGED":
            if (args.length > 0) {
                gameMode = Std.parseInt(args[0]);
                refreshLobbyUI();
            }
        case "START": 
            if (args.length > 0) FlxG.random.initialSeed = Std.parseInt(args[0]); 
            if (args.length > 1) tagger = args[1];
            beginMultiplayer();
        case "Y": 
            if (args.length >= 2) { 
                Reflect.setField(targetYMap, args[1], Std.parseFloat(args[0])); 
                getOpponent(args[1]);
            }
        case "JUMP": 
            if (args.length >= 1) { 
                var op = getOpponent(args[0]);
                if (op != null) { 
                    op.velocity.y = jumpForce; 
                    op.acceleration.y = gravity; 
                    spawnVFX(op, op.color);
                } 
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
                if (op != null) { 
                    op.color = 0xFF444444; 
                    op.acceleration.y = 0; 
                    spawnDeathBurst(op);
                } 
                refreshPlayerSidebar(); 
                checkBattleRoyaleEnd(); 
            }
        case "PLAYER_LIST": 
            if (args.length > 0) { 
                lobbyPlayers = [];
                for (pi in 0...args.length) { 
                    var pn = StringTools.trim(args[pi]); 
                    if (pn.length > 0) lobbyPlayers.push(pn); 
                } 
                sortLobbyPlayers();
                if (lobbyPlayers[0] == myNickname) isHost = true; else isHost = false;
                if (gameState == "LOBBY" || gameState == "WAITING_FOR_OPPONENT") refreshLobbyUI(); 
                if (gameState == "PLAYING" || gameState == "DEAD") refreshPlayerSidebar();
            }
        case "SKIN":
            if (args.length >= 2) {
                var nick = args[0];
                var skinId = args[1];
                Reflect.setField(playerSkinIdMap, nick, skinId);
            }
    }
}

function addLobbyPlayer(nick:String) { 
    if (nick.length == 0) return;
    for (li in 0...lobbyPlayers.length) { if (lobbyPlayers[li] == nick) return; } 
    lobbyPlayers.push(nick); 
    sortLobbyPlayers();
}

function sortLobbyPlayers() { 
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
    var startY = 110;
    var slotH = 30;
    var panelH = Std.int(40 + lobbyPlayers.length * slotH);
    var panelBg = new FlxSprite(FlxG.width - 235, startY - 32).makeGraphic(230, panelH, 0xFF0A0A1E); 
    panelBg.alpha = 0.6; 
    panelBg.cameras = [uiCam]; 
    playerSidebar.add(panelBg);
    var header = new FlxText(FlxG.width - 230, startY - 26, 220, "PLAYERS", 14); 
    header.setFormat(Paths.font(currentFont), 14, 0xFF666666, "right", 1, 0xFF000000);
    header.cameras = [uiCam]; 
    playerSidebar.add(header);
    
    for (si in 0...lobbyPlayers.length) {
        var nick = lobbyPlayers[si];
        var col = getPlayerColor(nick); 
        var isDead = Reflect.field(deadMap, nick); 
        var isMe = nick == myNickname;
        var scr = isMe ? score : (Reflect.field(scoreMap, nick) != null ? Reflect.field(scoreMap, nick) : 0);
        var dot = new FlxSprite(FlxG.width - 228, Std.int(startY + (si * slotH) + 4)).makeGraphic(8, 8, isDead ? 0xFF444444 : col);
        dot.cameras = [uiCam]; 
        playerSidebar.add(dot);
        var label = (isMe ? "> " : "  ") + nick + "  " + scr + (isDead ? " X" : "");
        var slot = new FlxText(FlxG.width - 218, startY + (si * slotH), 210, label, 16);
        slot.setFormat(Paths.font(currentFont), 16, isDead ? 0xFF555555 : (isMe ? 0xFFFFFFFF : col), "right", 1, 0xFF000000); 
        slot.alpha = isDead ? 0.4 : (isMe ? 1.0 : 0.75); 
        slot.cameras = [uiCam]; 
        playerSidebar.add(slot);
    }
}

function refreshLobbyUI() {
    lobbySlotGroup.clear(); lobbyBgGroup.clear();
    titleText.visible = false; subtitleText.visible = false;
    typingText.visible = false;
    typingBg.visible = false;

    var roomHeaderBg = new FlxSprite(0, 0).makeGraphic(FlxG.width, Std.int(FlxG.height * 0.16), 0xFF0D0D1A);
    roomHeaderBg.alpha = 0.7; roomHeaderBg.cameras = [uiCam]; lobbyBgGroup.add(roomHeaderBg);

    lobbyRoomText.visible = true;
    lobbyRoomText.text = "ROOM: " + activeRoomCode;
    lobbyRoomText.y = 20;
    
    var countText = new FlxText(0, 50, FlxG.width, lobbyPlayers.length + " / 6 PLAYERS", 18);
    countText.setFormat(Paths.font(currentFont), 18, 0xFF88CCFF, "center", 1, 0xFF000000);
    countText.cameras = [uiCam]; lobbySlotGroup.add(countText);

    var startY = FlxG.height * 0.22; var slotH = 56;
    for (si in 0...6) {
        var slotY = startY + (si * slotH);
        var hasPlayer = si < lobbyPlayers.length;
        var nick = hasPlayer ? lobbyPlayers[si] : "WAITING..."; 
        var col = hasPlayer ? playerColors[si % playerColors.length] : 0xFF333333;
        var isMe = hasPlayer && lobbyPlayers[si] == myNickname;
        var cardBg = new FlxSprite(Std.int(FlxG.width * 0.12), Std.int(slotY)).makeGraphic(Std.int(FlxG.width * 0.76), Std.int(slotH - 6), hasPlayer ? 0xFF1A1A2E : 0xFF0D0D18);
        cardBg.alpha = hasPlayer ? 0.65 : 0.3; cardBg.cameras = [uiCam]; lobbyBgGroup.add(cardBg);
        if (hasPlayer) { 
            var stripe = new FlxSprite(Std.int(FlxG.width * 0.12), Std.int(slotY)).makeGraphic(5, Std.int(slotH - 6), col);
            stripe.cameras = [uiCam]; lobbyBgGroup.add(stripe); 
        }
        var numText = new FlxText(Std.int(FlxG.width * 0.15), slotY + 10, 40, "" + (si + 1), 28);
        numText.setFormat(Paths.font(currentFont), 28, hasPlayer ? col : 0xFF333333, "center", 2, 0xFF000000); numText.cameras = [uiCam]; lobbySlotGroup.add(numText);
        var nameStr = hasPlayer ? nick.toUpperCase() : "---";
        if (isMe) nameStr = nameStr + "  (YOU)";
        var nameText = new FlxText(Std.int(FlxG.width * 0.25), slotY + 12, Std.int(FlxG.width * 0.5), nameStr, 24);
        nameText.setFormat(Paths.font(currentFont), 24, isMe ? 0xFFFFFFFF : col, "left", 2, 0xFF000000); nameText.cameras = [uiCam];
        if (hasPlayer) { 
            nameText.alpha = 0;
            FlxTween.tween(nameText, {alpha: 1}, 0.25, {startDelay: si * 0.06, ease: FlxEase.quadOut}); 
        } else nameText.alpha = 0.3;
        lobbySlotGroup.add(nameText);
    }
    
    var modeStr = gameModes[gameMode];
    var ctrlStr = isHost ? "   |   <- " + modeStr + " ->" : "   |   " + modeStr;
    lobbyText.text = "[ENTER] START   |   [ESC] LEAVE" + ctrlStr;
    lobbyText.y = FlxG.height * 0.82;
}

function getOpponent(nick:String):FlxSprite {
    if (activePlayers.indexOf(nick) == -1) {
        activePlayers.push(nick);
        addLobbyPlayer(nick);
        var col = getPlayerColor(nick);
        var op = new FlxSprite(300, FlxG.height / 2).makeGraphic(38, 32, 0xFFFFFFFF); op.color = col;
        op.alpha = 0.5; op.acceleration.y = gravity; playerGroup.add(op);
        var opW = new FlxSprite(0, 0).makeGraphic(18, 12, darkenColor(col, 0.7)); opW.alpha = 0.5; playerGroup.add(opW);
        Reflect.setField(playerWingMap, nick, opW);
        var opE = new FlxSprite(0, 0).makeGraphic(8, 8, 0xFFFFFFFF); opE.alpha = 0.5; playerGroup.add(opE); Reflect.setField(playerEyeMap, nick, opE);
        var opB = new FlxSprite(0, 0).makeGraphic(12, 7, 0xFFFF8800); opB.alpha = 0.5; playerGroup.add(opB); Reflect.setField(playerBeakMap, nick, opB);
        
        var oh1 = new FlxSprite(0,0).makeGraphic(20,20,0x00000000); oh1.alpha=0.5; playerGroup.add(oh1); Reflect.setField(playerHat1Map, nick, oh1);
        var oh2 = new FlxSprite(0,0).makeGraphic(20,20,0x00000000); oh2.alpha=0.5; playerGroup.add(oh2); Reflect.setField(playerHat2Map, nick, oh2);
        
        var opTag = new FlxText(0, 0, 200, nick, 11); opTag.setFormat(Paths.font(currentFont), 11, col, "center", 1, 0xFF000000); opTag.cameras = [uiCam];
        opTag.alpha = 0.6; nickTagGroup.add(opTag); Reflect.setField(playerNickMap, nick, opTag);
        Reflect.setField(playerMap, nick, op); Reflect.setField(scoreMap, nick, 0); Reflect.setField(deadMap, nick, false);
        Reflect.setField(targetYMap, nick, FlxG.height / 2);
        Reflect.setField(playerSkinIdMap, nick, "default");
        var eTxt = new FlxText(0, 0, 200, "", 32); eTxt.setFormat(Paths.font(currentFont), 32, col, "center", 2, 0xFF000000);
        eTxt.cameras = [uiCam]; emoteGroup.add(eTxt); Reflect.setField(emoteMap, nick, eTxt);
        refreshScoreUI();
    }
    return Reflect.field(playerMap, nick);
}

function interpolateOpponents(elapsed:Float) { 
    for (i in 0...activePlayers.length) { 
        var nick = activePlayers[i]; 
        if (Reflect.field(deadMap, nick)) continue;
        var op:FlxSprite = Reflect.field(playerMap, nick); 
        var targetY = Reflect.field(targetYMap, nick); 
        if (op == null || targetY == null) continue;
        var diff = targetY - op.y; 
        if (Math.abs(diff) > 200) op.y = targetY;
        else op.y = FlxMath.lerp(op.y, targetY, elapsed * 12.0); 
        
        if (gameMode == 3 && tagger == nick) {
            if (!iAmDead && FlxG.overlap(bird, op)) killBird();
        }
    } 
}

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
    crownGem.visible = crown.visible;
}

function handleTyping(max:Int, elapsed:Float) { 
    if (FlxG.keys.justPressed.BACKSPACE && typedInput.length > 0) typedInput = typedInput.substring(0, typedInput.length - 1);
    else if (typedInput.length < max) { 
        var key = FlxG.keys.firstJustPressed(); 
        var abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        if (key >= 65 && key <= 90) typedInput += abc.charAt(key - 65);
        else if (key >= 48 && key <= 57) typedInput += abc.charAt(key - 48 + 26);
    } 
    if (gameState == "NICKNAME" || gameState == "ROOM_INPUT") {
        typingCursorTimer += elapsed;
        if (typingCursorTimer >= 0.5) {
            typingCursorBlink = !typingCursorBlink;
            typingCursorTimer = 0;
        }
        typingText.text = "> " + typedInput + (typingCursorBlink ? "_" : "");
    }
}

function update(elapsed:Float) {
    if (titleText.visible) { 
        titleGlow += elapsed * 2.5;
        titleText.scale.set(Math.sin(titleGlow) * 0.08 + 1.0, Math.sin(titleGlow) * 0.08 + 1.0);
        if (subtitleText.visible) subtitleText.alpha = 0.5 + Math.sin(titleGlow * 1.3) * 0.3;
    }
    if (scoreBounce > 1.0) { 
        scoreBounce = FlxMath.lerp(scoreBounce, 1.0, elapsed * 8); 
        scoreText.scale.set(scoreBounce, scoreBounce); 
        scoreShadow.scale.set(scoreBounce, scoreBounce);
    }
    if (coinBounce > 1.0) { 
        coinBounce = FlxMath.lerp(coinBounce, 1.0, elapsed * 8); 
        coinText.scale.set(coinBounce, coinBounce);
    }
    coinIconSpin += elapsed * 6; 
    if (coinIconText != null) coinIconText.scale.set(Math.abs(Math.cos(coinIconSpin)) * 0.6 + 0.4, 1.0);
    
    cloudSpawnTimer += elapsed; 
    if (cloudSpawnTimer > 3.0) { cloudSpawnTimer = 0; spawnCloud(false); }
    cloudGroup.forEachAlive(function(c:FlxSprite) { if (c.x + c.width < -50) c.kill(); });
    
    if (gameState == "PLAYING" && !iAmDead) { 
        wingFlapTimer += elapsed; 
        if (wingFlapTimer > 0.12) { wingFlapTimer = 0; wingUp = !wingUp; } 
    }
    
    if (birdSquash != 1.0) birdSquash = FlxMath.lerp(birdSquash, 1.0, elapsed * 10);
    if (bird.visible) { 
        bird.scale.set(1.0, birdSquash); 
        birdWing.setPosition(bird.x - 4, bird.y + (wingUp ? 4 : 14));
        birdWing.scale.set(1.0, wingUp ? 0.7 : 1.2); 
        birdEye.setPosition(bird.x + 24, bird.y + 6); 
        birdBeak.setPosition(bird.x + 34, bird.y + 12);
        birdNickTag.setPosition(bird.x - 80, bird.y - 22); 
        
        var sDat = getSkinData(equippedSkinId);
        birdWing.color = darkenColor(sDat.color, 0.7);
        applyHat(sDat.hat, birdHat1, birdHat2, bird.x, bird.y, bird.angle, birdSquash);
    }
    
    for (i in 0...activePlayers.length) { 
        var nick = activePlayers[i]; 
        var op:FlxSprite = Reflect.field(playerMap, nick);
        if (op == null) continue; 
        var opW:FlxSprite = Reflect.field(playerWingMap, nick); 
        var opE:FlxSprite = Reflect.field(playerEyeMap, nick); 
        var opB:FlxSprite = Reflect.field(playerBeakMap, nick);
        var opN:FlxText = Reflect.field(playerNickMap, nick); 
        var oh1:FlxSprite = Reflect.field(playerHat1Map, nick);
        var oh2:FlxSprite = Reflect.field(playerHat2Map, nick);
        
        if (opW != null) { opW.setPosition(op.x - 4, op.y + (wingUp ? 4 : 14)); opW.scale.set(1.0, wingUp ? 0.7 : 1.2); } 
        if (opE != null) opE.setPosition(op.x + 24, op.y + 6);
        if (opB != null) opB.setPosition(op.x + 30, op.y + 12); 
        if (opN != null) opN.setPosition(op.x - 80, op.y - 22);
        
        var oSid = Reflect.field(playerSkinIdMap, nick);
        if (oSid != null && oh1 != null && oh2 != null) {
            applyHat(getSkinData(oSid).hat, oh1, oh2, op.x, op.y, op.angle, 1.0);
        }
    }
    
    myEmoteText.setPosition(bird.x - 80, bird.y - 44);
    for (i in 0...activePlayers.length) { 
        var nick = activePlayers[i];
        var op = Reflect.field(playerMap, nick); 
        var eT = Reflect.field(emoteMap, nick);
        if (eT != null && op != null) eT.setPosition(op.x - 80, op.y - 44);
    }
    
    if (crown.visible) { 
        var crT = (currentLeader == myNickname) ? bird : Reflect.field(playerMap, currentLeader);
        if (crT != null) { crown.setPosition(crT.x + 8, crT.y - 16); crownGem.setPosition(crT.x + 16, crT.y - 14); } 
    }
    
    powerupGlowTimer += elapsed; 
    powerupGlowGroup.forEachAlive(function(g:FlxSprite) { g.alpha = 0.15 + Math.sin(powerupGlowTimer * 4) * 0.1; });
    
    bgPropSpawnTimer += elapsed;
    if (bgPropSpawnTimer > 1.5) {
        bgPropSpawnTimer = FlxG.random.float(0, 0.5);
        if (gameState == "PLAYING" && !inCountdown) spawnBGProp();
    }
    bgPropGroup.forEachAlive(function(prop) {
        prop.velocity.x = pipeSpeed * 0.3;
        if (prop.x + prop.width < -50) prop.kill();
    });

    if (isMultiplayer && gameState == "PLAYING") interpolateOpponents(elapsed);
    
    if (gameState == "WAITING_FOR_OPPONENT") { 
        waitDotTimer += elapsed;
        if (waitDotTimer > 0.5) { waitDotTimer = 0; waitDots = (waitDots + 1) % 4; } 
        var dots = "";
        for (di in 0...waitDots) dots += "."; lobbyText.text = "WAITING" + dots;
    }
    if (gameState == "PLAYING") vignette.alpha = FlxMath.lerp(vignette.alpha, 0.15, elapsed * 2);
    if (FlxG.keys.justPressed.ESCAPE && gameState == "PLAYING") { openSubState(new ModSubState("FlappyPause")); return; }
    
    switch(gameState) { 
        case "NICKNAME": updateNickname(elapsed);
        case "MENU": updateMenu(); 
        case "ROOM_INPUT": updateRoomInput(elapsed); 
        case "WAITING_FOR_OPPONENT": updateWaiting(); 
        case "LOBBY": updateLobby(); 
        case "PLAYING": updatePlaying(elapsed); 
        case "DEAD": updateDead();
        case "LEADERBOARD": updateLeaderboard(); 
        case "SHOP": updateShop(); 
    }
}

function updateNickname(elapsed:Float) { 
    handleTyping(12, elapsed); 
    if (FlxG.keys.justPressed.ENTER && typedInput.length > 1) { 
        myNickname = typedInput;
        FlxG.save.data.flappyNickname = myNickname; 
        FlxG.save.flush(); 
        goToState("MENU"); 
    } 
}

function updateMenu() { 
    if (FlxG.keys.justPressed.ONE) { gameMode = 0; startSolo(); }
    if (FlxG.keys.justPressed.TWO) goToState("ROOM_INPUT"); 
    if (FlxG.keys.justPressed.THREE) goToState("LEADERBOARD");
    if (FlxG.keys.justPressed.FOUR) goToState("SHOP"); 
    if (FlxG.keys.justPressed.ESCAPE) {
        playMusicTrack("");
        FlxG.switchState(new MainMenuState());
    }
}

function updateRoomInput(elapsed:Float) { 
    handleTyping(4, elapsed); 
    if (FlxG.keys.justPressed.ENTER && typedInput.length == 4) { 
        activeRoomCode = typedInput; 
        lobbyText.text = "JOINING...";
        netConnect(activeRoomCode, myNickname); 
        isMultiplayer = true; 
        gameState = "WAITING_FOR_OPPONENT"; 
        playMusicTrack("mainTheme");
    } 
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU"); 
}

function updateWaiting() { 
    if (FlxG.keys.justPressed.ENTER) netSend("START_GAME");
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU"); 
}

function updateLobby() { 
    if (isHost) {
        if (FlxG.keys.justPressed.LEFT) {
            gameMode--;
            if (gameMode < 0) gameMode = gameModes.length - 1;
            netSend("CHAT:SET_MODE:" + gameMode);
            refreshLobbyUI();
        }
        if (FlxG.keys.justPressed.RIGHT) {
            gameMode++;
            if (gameMode >= gameModes.length) gameMode = 0;
            netSend("CHAT:SET_MODE:" + gameMode);
            refreshLobbyUI();
        }
    }
    if (FlxG.keys.justPressed.ENTER) netSend("START_GAME"); 
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU"); 
}

function updateDead() { 
    if (FlxG.keys.justPressed.ENTER) FlxG.resetState();
}

function updateLeaderboard() { 
    if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT) {
        lbCategory = (lbCategory == 0) ? 1 : 0;
        lbScroll = 0;
        renderLeaderboardLocal();
    }
    if (FlxG.keys.justPressed.UP && lbScroll > 0) {
        lbScroll -= 5;
        if (lbScroll < 0) lbScroll = 0;
        renderLeaderboardLocal();
    }
    if (FlxG.keys.justPressed.DOWN) {
        lbScroll += 5;
        renderLeaderboardLocal();
    }
    if (FlxG.keys.justPressed.R) {
        lbSolo = [];
        lbMulti = [];
        FlxG.save.data.flappyLbSolo = lbSolo;
        FlxG.save.data.flappyLbMulti = lbMulti;
        FlxG.save.flush();
        renderLeaderboardLocal();
    }
    if (FlxG.keys.justPressed.ESCAPE) goToState("MENU"); 
}

function updatePlaying(elapsed:Float) {
    if (inCountdown) return;
    if (equippedTrailId != "none" && !iAmDead) { 
        trailTimer += elapsed; 
        if (trailTimer >= 0.05) { trailTimer = 0; spawnTrailParticle(bird); } 
    }
    
    if (!iAmDead) {
        if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.UP) { 
            bird.velocity.y = jumpForce;
            birdSquash = 0.7; 
            spawnVFX(bird, getSkinData(equippedSkinId).color); 
            if (isMultiplayer) netSend("JUMP"); 
        }
        if (FlxG.keys.justPressed.Q) sendEmote(":)");
        if (FlxG.keys.justPressed.W) sendEmote("GG"); 
        if (FlxG.keys.justPressed.E) sendEmote("RIP");
        
        var targetAngle = (bird.velocity.y < 0) ? -20 : 50;
        if (gameMode == 6) targetAngle = (bird.velocity.y > 0) ? -20 : 50;
        bird.angle = FlxMath.lerp(bird.angle, targetAngle, elapsed * 10);
        birdWing.angle = bird.angle; 
        birdEye.angle = bird.angle * 0.3; 
        birdBeak.angle = bird.angle * 0.5;
        
        if (bird.y > FlxG.height - 30 || bird.y < 0) killBird();
        
        if (!isGhost && !hasShield) {
            if (gameMode != 3 || tagger != myNickname) {
                FlxG.overlap(bird, pipes, function(b, p) { killBird(); });
            }
        }
        FlxG.overlap(bird, powerups, function(b, pu) { collectPowerup(pu); });
        
        if (isMultiplayer) { 
            netSendAccum += elapsed; 
            if (netSendAccum >= NET_SEND_INTERVAL) { 
                netSendAccum = 0; 
                netSend("Y:" + bird.y);
            } 
        }
    }
    
    for (i in 0...activePlayers.length) { 
        var nick = activePlayers[i];
        if (!Reflect.field(deadMap, nick)) { 
            var op = Reflect.field(playerMap, nick); 
            if (op != null) {
                var tgtAng = (op.velocity.y < 0) ? -20 : 50;
                if (gameMode == 6) tgtAng = (op.velocity.y > 0) ? -20 : 50;
                op.angle = FlxMath.lerp(op.angle, tgtAng, elapsed * 10);
            }
        } 
    }
    
    if (gameMode == 7) {
        pipeSpeed = FlxMath.lerp(pipeSpeed, FlxG.random.float(-200, -800), elapsed * 0.5);
    }
    
    pipes.forEachAlive(function(p:FlxSprite) { 
        p.velocity.x = pipeSpeed; 
        if (p.x < -100) p.kill(); 
        if (p.ID == 0 && p.x + p.width < bird.x && !iAmDead) { 
            p.ID = 99; 
            score++; 
            addCoins(1); 
            scoreBounce = 1.35; 
            spawnScorePopup(); 
            FlxG.camera.flash(0x08FFFFFF, 0.1); 
            refreshScoreUI(); 
            updateCrown(); 
            checkDifficulty(); 
            if (isMultiplayer) netSend("SCORE:" + score); 
        } 
    });
    pipeCapGroup.forEachAlive(function(c:FlxSprite) { c.velocity.x = pipeSpeed; if (c.x < -120) c.kill(); });
    pipeHighlightGroup.forEachAlive(function(h:FlxSprite) { h.velocity.x = pipeSpeed; if (h.x < -120) h.kill(); });
    pipeShadowGroup.forEachAlive(function(s:FlxSprite) { s.velocity.x = pipeSpeed; if (s.x < -120) s.kill(); });
    powerups.forEachAlive(function(pu) { pu.velocity.x = pipeSpeed; });
    powerupGlowGroup.forEachAlive(function(g:FlxSprite) { g.velocity.x = pipeSpeed; if (g.x < -120) g.kill(); });
    powerupLabelGroup.forEachAlive(function(l:FlxText) { l.velocity.x = pipeSpeed; if (l.x < -120) l.kill(); });
}

function spawnScorePopup() { 
    var pop = new FlxText(Std.int(bird.x + 20), Std.int(bird.y - 30), 100, "+1", 22);
    pop.setFormat(Paths.font(currentFont), 22, 0xFFFFEE00, "center", 2, 0xFF000000); 
    pop.cameras = [uiCam]; 
    scorePopGroup.add(pop);
    FlxTween.tween(pop, {y: pop.y - 60, alpha: 0}, 0.7, {ease: FlxEase.quadOut, onComplete: function(_) { pop.destroy(); }});
}

function spawnTrailParticle(obj:FlxSprite) {
    var size = FlxG.random.int(6, 16); 
    var p = trailGroup.recycle(FlxSprite);
    if (p == null) p = new FlxSprite();
    var trailData = getTrailData(equippedTrailId);
    var col:Int = trailData.color;
    var dur = 0.25 + FlxG.random.float(0, 0.15);
    var vx = FlxG.random.float(-30, -70);
    var vy = FlxG.random.float(-15, 15);
    var shrinks = true;
    
    if (equippedTrailId == "rainbow") col = FlxColor.fromHSB((FlxG.game.ticks * 8) % 360, 1.0, 1.0);
    if (equippedTrailId == "glitch") { col = FlxG.random.bool(50) ? 0xFF00FFCC : (FlxG.random.bool(50) ? 0xFFFF00FF : 0xFF00FF00); size = FlxG.random.int(3, 22); }
    if (equippedTrailId == "snow") { col = FlxG.random.bool(50) ? 0xFFCCEEFF : 0xFFFFFFFF; size = FlxG.random.int(4, 12); vy = FlxG.random.float(-10, -30); }
    if (equippedTrailId == "hearts") { col = FlxG.random.bool(50) ? 0xFFFF4488 : 0xFFFF88AA; size = FlxG.random.int(6, 14); vy = FlxG.random.float(-20, -50); }
    if (equippedTrailId == "toxic") { col = FlxG.random.bool(50) ? 0xFF44FF00 : 0xFF88FF44; size = FlxG.random.int(5, 16); vy = FlxG.random.float(-10, -40); }
    if (equippedTrailId == "stars") { col = FlxG.random.bool(50) ? 0xFFFFFFAA : 0xFFFFFFFF; size = FlxG.random.int(4, 10); }
    if (equippedTrailId == "bubbles") { col = FlxG.random.bool(50) ? 0xFF88CCFF : 0xFFFFFFFF; size = FlxG.random.int(6, 16); vy = FlxG.random.float(-20, -60); shrinks = false; }
    if (equippedTrailId == "lightning") { col = 0xFF00FFFF; size = FlxG.random.int(2, 20); vx = FlxG.random.float(-80, -120); vy = FlxG.random.float(-40, 40); }
    if (equippedTrailId == "shadows") { col = 0xFF111111; size = FlxG.random.int(8, 20); dur = 0.5; }
    if (equippedTrailId == "money") { col = 0xFF22AA22; size = FlxG.random.int(6, 12); vy = FlxG.random.float(-10, 10); shrinks = false; }
    if (equippedTrailId == "pixels") { col = 0xFFDDDDDD; size = FlxG.random.int(8, 14); vx = -50; vy = 0; }
    if (equippedTrailId == "ash") { col = 0xFF555555; size = FlxG.random.int(4, 12); vy = FlxG.random.float(-10, -40); dur = 0.4; }
    if (equippedTrailId == "slime") { col = 0xFF99FF33; size = FlxG.random.int(8, 16); vy = FlxG.random.float(10, 40); }
    if (equippedTrailId == "confetti") { col = FlxG.random.color(0xFF000000, 0xFFFFFFFF); size = FlxG.random.int(4, 10); vy = FlxG.random.float(-20, 20); dur = 0.6; }

    p.makeGraphic(size, size, col); 
    p.reset(obj.x + 19 - size / 2 + FlxG.random.float(-5, 5), obj.y + 16 - size / 2 + FlxG.random.float(-5, 5));
    p.alpha = 0.5; 
    p.velocity.set(vx, vy); 
    trailGroup.add(p);
    if (shrinks) FlxTween.tween(p, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, dur, { onComplete: function(twn) { p.kill(); } });
    else FlxTween.tween(p, {alpha: 0}, dur, { onComplete: function(twn) { p.kill(); } });
}

function spawnPipe() {
    var pGap = pipeGap;
    if (gameMode == 7) pGap = FlxG.random.float(120, 300);
    var pipeY = FlxG.random.float(100, FlxG.height - pGap - 140);
    var col = getPipeColor(); 
    var darkCol = darkenColor(col, 0.6); 
    var lightCol = lightenColor(col, 1.4); 
    var pipeW = 76;
    var capW = 88; 
    var capH = 22;
    
    var bot = pipes.recycle(FlxSprite); 
    bot.makeGraphic(pipeW, FlxG.height, col); 
    bot.reset(FlxG.width, pipeY + pGap);
    bot.ID = 0; pipes.add(bot);
    
    var botCap = pipeCapGroup.recycle(FlxSprite); 
    if (botCap == null) botCap = new FlxSprite(); 
    botCap.makeGraphic(capW, capH, darkCol);
    botCap.reset(FlxG.width - (capW - pipeW) / 2, pipeY + pGap); 
    pipeCapGroup.add(botCap);
    
    var botHL = pipeHighlightGroup.recycle(FlxSprite);
    if (botHL == null) botHL = new FlxSprite(); 
    botHL.makeGraphic(8, FlxG.height, lightCol); 
    botHL.reset(FlxG.width + 6, pipeY + pGap); 
    botHL.alpha = 0.3;
    pipeHighlightGroup.add(botHL);
    
    var botSH = pipeShadowGroup.recycle(FlxSprite); 
    if (botSH == null) botSH = new FlxSprite(); 
    botSH.makeGraphic(10, FlxG.height, darkCol);
    botSH.reset(FlxG.width + pipeW - 10, pipeY + pGap); 
    botSH.alpha = 0.35; 
    pipeShadowGroup.add(botSH);
    
    var top = pipes.recycle(FlxSprite); 
    top.makeGraphic(pipeW, FlxG.height, col);
    top.reset(FlxG.width, pipeY - FlxG.height); 
    top.ID = 1; pipes.add(top);
    
    var topCap = pipeCapGroup.recycle(FlxSprite); 
    if (topCap == null) topCap = new FlxSprite();
    topCap.makeGraphic(capW, capH, darkCol); 
    topCap.reset(FlxG.width - (capW - pipeW) / 2, pipeY - capH); 
    pipeCapGroup.add(topCap);
    
    var topHL = pipeHighlightGroup.recycle(FlxSprite);
    if (topHL == null) topHL = new FlxSprite(); 
    topHL.makeGraphic(8, FlxG.height, lightCol); 
    topHL.reset(FlxG.width + 6, pipeY - FlxG.height); 
    topHL.alpha = 0.3;
    pipeHighlightGroup.add(topHL);
    
    if (FlxG.random.bool(22)) spawnBooster(FlxG.random.int(1, 4), FlxG.width + 100, pipeY + (pGap / 2) - 18, true);
}

function getPipeColor():Int { 
    if (currentLevel >= 5) return 0xFFCC2222; 
    if (currentLevel >= 3) return 0xFF2277BB;
    if (currentLevel >= 2) return 0xFFCC8822; 
    return 0xFF228822; 
}

function spawnBooster(type:Int, x:Float, y:Float, broadcast:Bool) {
    var colors = [0xFFFFD700, 0xFF00FFFF, 0xFFFF00FF, 0xFF00FF00];
    var labels = ["+5", "SH", "SPD", "GHO"];
    var p = powerups.recycle(FlxSprite); 
    p.makeGraphic(30, 30, colors[type - 1]); 
    p.reset(x, y);
    p.ID = type; powerups.add(p);
    var glow = powerupGlowGroup.recycle(FlxSprite); 
    if (glow == null) glow = new FlxSprite();
    glow.makeGraphic(50, 50, colors[type - 1]); 
    glow.reset(x - 10, y - 10); 
    glow.alpha = 0.15; powerupGlowGroup.add(glow);
    var lbl = new FlxText(Std.int(x - 10), Std.int(y - 18), 50, labels[type - 1], 12);
    lbl.setFormat(Paths.font(currentFont), 12, colors[type - 1], "center", 1, 0xFF000000); 
    lbl.cameras = [uiCam]; 
    powerupLabelGroup.add(lbl);
    if (broadcast && isMultiplayer) netSend("BOOSTER:" + type + ":" + y);
}

function collectPowerup(pu:FlxSprite) {
    switch(pu.ID) { 
        case 1: score += 5; addCoins(5); 
        case 2: 
            hasShield = true;
            bird.alpha = 0.5; addCoins(5); 
            new FlxTimer().start(5, function(t) { hasShield = false; bird.alpha = 1; }); 
        case 3: 
            pipeSpeed = -650;
            addCoins(5); 
            new FlxTimer().start(5, function(t) { pipeSpeed = -300 - ((currentLevel - 1) * 35); }); 
        case 4: 
            isGhost = true;
            bird.color = 0xFF888888; addCoins(5); 
            new FlxTimer().start(4, function(t) { isGhost = false; bird.color = getSkinData(equippedSkinId).color; }); 
    }
    pu.kill();
    FlxG.camera.flash(0x11FFFFFF, 0.08); 
    refreshScoreUI(); 
    updateCrown(); 
    if (isMultiplayer) netSend("SCORE:" + score);
}

function checkDifficulty() { 
    var newLevel = Math.floor(score / 10) + 1;
    if (newLevel > currentLevel) { 
        currentLevel = newLevel; 
        if (gameMode != 4 && gameMode != 7) pipeSpeed -= 35; 
        if (gameMode != 2 && gameMode != 7) pipeGap = Math.max(160, pipeGap - 10);
        pipeInterval = Math.max(0.7, pipeInterval - 0.12); 
        restartPipeTimer(); 
        levelText.text = "LEVEL " + currentLevel; 
        levelText.scale.set(2, 2); 
        levelText.alpha = 1;
        FlxTween.tween(levelText.scale, {x: 1, y: 1}, 0.6, {ease: FlxEase.elasticOut}); 
        FlxTween.tween(levelText, {alpha: 0.6}, 1.5, {startDelay: 1}); 
        FlxG.camera.flash(0x18FFFFFF, 0.3); 
        FlxG.camera.shake(0.006, 0.12);
    } 
}

function spawnVFX(obj:FlxSprite, col:Int) { 
    for (vi in 0...4) { 
        var size = FlxG.random.int(10, 28);
        var trail = new FlxSprite(obj.x + FlxG.random.float(-8, 30), obj.y + FlxG.random.float(-8, 24)).makeGraphic(size, size, col); 
        trail.alpha = 0.6;
        trail.velocity.set(FlxG.random.float(-70, 70), FlxG.random.float(-90, 30)); 
        vfxGroup.add(trail); 
        FlxTween.tween(trail, {alpha: 0, "scale.x": 0.05, "scale.y": 0.05}, 0.35 + FlxG.random.float(0, 0.25), { onComplete: function(twn) { trail.destroy(); } });
    } 
}

function spawnDeathBurst(obj:FlxSprite) { 
    for (di in 0...12) { 
        var size = FlxG.random.int(8, 30);
        var shard = new FlxSprite(obj.x + FlxG.random.float(-5, 35), obj.y + FlxG.random.float(-5, 28)).makeGraphic(size, size, FlxG.random.bool(50) ? 0xFFFF4444 : 0xFFFFAA00);
        shard.alpha = 0.9; 
        shard.velocity.set(FlxG.random.float(-200, 200), FlxG.random.float(-250, 100)); 
        vfxGroup.add(shard); 
        FlxTween.tween(shard, {alpha: 0, "scale.x": 0.05, "scale.y": 0.05}, 0.5 + FlxG.random.float(0, 0.4), { onComplete: function(twn) { shard.destroy(); } });
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
    txt.scale.set(1.3, 1.3);
    FlxTween.tween(txt.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.quadOut}); 
    FlxTween.tween(txt, {alpha: 0}, 1.5, {startDelay: 1});
}

function killBird() { 
    if (iAmDead) return; 
    iAmDead = true; 
    bird.velocity.x = pipeSpeed;
    bird.acceleration.y = gameMode == 6 ? -gravity : gravity; 
    bird.color = 0xFF444444; 
    birdWing.color = 0xFF333333; 
    birdHat1.color = 0xFF555555;
    birdHat2.color = 0xFF555555;
    spawnDeathBurst(bird); 
    FlxG.camera.shake(0.025, 0.35); 
    FlxG.camera.flash(0x66FF0000, 0.35); 
    addCoins(10); 
    if (isMultiplayer) { 
        netSend("DEAD");
        netSend("SUBMIT_SCORE:" + score); 
        checkBattleRoyaleEnd(); 
    } else {
        saveToLeaderboard(score, false);
        showGameOver();
    }
}

function checkBattleRoyaleEnd() { 
    var aliveCount = 0;
    for (i in 0...activePlayers.length) { if (!Reflect.field(deadMap, activePlayers[i])) aliveCount++; } 
    if (!iAmDead) aliveCount++;
    if (aliveCount <= 1 && (activePlayers.length > 0 || iAmDead)) { 
        if (!iAmDead) { 
            currentLeader = myNickname; 
            addCoins(25);
            netSend("SUBMIT_SCORE:" + score); 
            saveToLeaderboard(score, true);
        } 
        showGameOver(); 
    } else if (iAmDead) { 
        lobbyText.text = "SPECTATING... " + aliveCount + " LEFT";
        lobbyText.visible = true; 
    } 
}

function showGameOver() {
    if (gameState == "DEAD") return; gameState = "DEAD";
    playMusicTrack("");
    if (pipeTimer != null) pipeTimer.cancel();
    pipes.forEach(function(p) { p.velocity.x = 0; }); 
    pipeCapGroup.forEach(function(c) { c.velocity.x = 0; });
    pipeHighlightGroup.forEach(function(h) { h.velocity.x = 0; }); 
    pipeShadowGroup.forEach(function(s) { s.velocity.x = 0; });
    
    var won = currentLeader == myNickname;
    var result = isMultiplayer ? (won ? "VICTORY ROYALE!" : "ELIMINATED") : "GAME OVER"; 
    var col = won ? 0xFF00FF88 : 0xFFFF4444;
    
    var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000); 
    overlay.cameras = [uiCam]; add(overlay); 
    FlxTween.color(overlay, 0.6, 0x00000000, 0xBB000000);
    
    var overText = new FlxText(0, 0, FlxG.width, result, 64); 
    overText.setFormat(Paths.font(currentFont), 64, col, "center", 4, 0xFF000000); 
    overText.screenCenter(); 
    overText.y -= 70;
    overText.cameras = [uiCam]; 
    overText.alpha = 0; 
    overText.scale.set(2.5, 2.5); add(overText);
    
    FlxTween.tween(overText, {alpha: 1}, 0.4, {ease: FlxEase.quadOut});
    FlxTween.tween(overText.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.elasticOut});
    
    var coinSummary = "  |  +" + coinEarnedThisRound + " COINS";
    var finalScore = isMultiplayer ? "SCORE: " + score + "  |  " + (won ? "#1 WINNER" : "ELIMINATED") + coinSummary : "SCORE: " + score + coinSummary;
    var scoreInfo = new FlxText(0, 0, FlxG.width, finalScore + "\n\n[ENTER] RETRY", 22);
    scoreInfo.setFormat(Paths.font(currentFont), 22, 0xFFCCCCCC, "center", 2, 0xFF000000); 
    scoreInfo.screenCenter();
    scoreInfo.y += 20; 
    scoreInfo.cameras = [uiCam]; 
    scoreInfo.alpha = 0; add(scoreInfo);
    
    FlxTween.tween(scoreInfo, {alpha: 1}, 0.5, {startDelay: 0.4, ease: FlxEase.quadOut});
}

function resetGameplay() { 
    score = 0; 
    currentLevel = 1; 
    coinEarnedThisRound = 0; 
    netSendAccum = 0; 
    trailTimer = 0;
    hasShield = false; 
    isGhost = false; 

    pipeSpeed = -300; 
    pipeGap = 230;
    pipeInterval = 1.6; 
    gravity = 1500;
    jumpForce = -500;

    if (gameMode == 2) {
        pipeSpeed = -450;
        pipeGap = 160;
    } else if (gameMode == 4) {
        pipeSpeed = -700;
        pipeInterval = 0.8;
    } else if (gameMode == 5) {
        gravity = 700;
        jumpForce = -350;
    } else if (gameMode == 6) {
        gravity = -1500;
        jumpForce = 500;
    }

    bgPropGroup.clear();
    for (i in 0...10) spawnBGProp(true);
}

function startSolo() { 
    iAmDead = false; 
    isMultiplayer = false; 
    resetGameplay(); 
    playMusicTrack("racingTillDawn");
    enterPlayState(); 
    restartPipeTimer(); 
}

function beginMultiplayer() {
    lobbySlotGroup.clear(); lobbyBgGroup.clear();
    lobbyRoomText.visible = false; refreshPlayerSidebar();
    inCountdown = true; var count = 3;
    var t = new FlxText(0, 0, FlxG.width, "3", 140);
    t.setFormat(Paths.font(currentFont), 140, 0xFFFFFFFF, "center", 6, 0xFF000000); 
    t.screenCenter(); 
    t.cameras = [uiCam]; add(t);
    playMusicTrack("racingTillDawn");
    new FlxTimer().start(1, function(tmr) { 
        count--; 
        if (count <= 0) { 
            tmr.cancel(); 
            t.text = "GO!"; 
            t.color = 0xFF00FF88; 
            t.scale.set(1.5, 1.5); 
            FlxTween.tween(t, {alpha: 0}, 0.5, {ease: FlxEase.quadIn, onComplete: function(_) { t.destroy(); }}); 
            FlxG.camera.flash(0x33FFFFFF, 0.3); 
            inCountdown = false; 
            iAmDead = false; 
            resetGameplay(); 
            enterPlayState(); 
            restartPipeTimer(); 
            if (isMultiplayer) netSend("CHAT:SKIN:" + equippedSkinId);
        } else { 
            t.text = Std.string(count); 
            t.scale.set(1.5, 1.5); 
            FlxTween.tween(t.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.elasticOut}); 
            t.color = [0xFFFFEE00, 0xFFFF9900, 0xFFFF4444][3 - count]; 
            FlxG.camera.shake(0.004, 0.1); 
        } 
    }, 0);
}

function enterPlayState() {
    gameState = "PLAYING"; 
    titleText.visible = false; 
    subtitleText.visible = false; 
    lobbyText.visible = false;
    typingText.visible = false; 
    typingBg.visible = false;
    scoreText.visible = true; 
    scoreShadow.visible = true; 
    levelText.visible = true;
    bird.visible = true;
    birdWing.visible = true; 
    birdEye.visible = true; 
    birdBeak.visible = true;
    birdHat1.visible = true;
    birdHat2.visible = true;
    birdNickTag.visible = true;
    bird.acceleration.y = gameMode == 6 ? -gravity : gravity; 
    
    var sDat = getSkinData(equippedSkinId);
    if (gameMode == 3 && tagger == myNickname) bird.color = 0xAAFF0000;
    else bird.color = sDat.color;
    birdHat1.color = 0xFFFFFFFF; birdHat2.color = 0xFFFFFFFF;
    
    birdWing.color = darkenColor(sDat.color, 0.7);
    bird.y = FlxG.height / 2; 
    bird.velocity.y = 0; 
    birdNickTag.text = myNickname;
}

function restartPipeTimer() { 
    if (pipeTimer != null) pipeTimer.cancel(); 
    pipeTimer = new FlxTimer().start(pipeInterval, function(tmr) { 
        if (gameState == "PLAYING" && !inCountdown) spawnPipe(); 
    }, 0);
}

function refreshScoreUI() { 
    scoreText.text = "SCORE: " + score; 
    scoreShadow.text = "SCORE: " + score; 
    scoreText.size = 32;
    scoreShadow.size = 32; 
    if (isMultiplayer) refreshPlayerSidebar(); 
}

function fetchServerStatus() { 
    netOneShot("GET_STATUS", 0.3, function(d) { 
        if (d != null && d.indexOf("STATUS") != -1) { 
            var p = d.split(":"); 
            statusText.text = p[1] + " online | " + p[2] + " rooms"; 
            statusText.color = 0xFF88CC88; 
        } else { 
            statusText.text = "server offline"; 
            statusText.color = 0xFFCC6666; 
        } 
    });
}

function renderLeaderboardLocal() {
    leaderboardGroup.clear();
    var entries = (lbCategory == 0) ? lbSolo : lbMulti;
    var startY = FlxG.height * 0.28;
    var maxDisplay = 6;
    var catStr = (lbCategory == 0) ? "SOLO" : "MULTIPLAYER";
    
    lobbyText.text = catStr + " LEADERBOARD  [<-/->] SWITCH  [UP/DOWN] SCROLL  [R] RESET  [ESC] BACK";

    if (entries == null || entries.length == 0) { 
        var empty = new FlxText(0, startY + 50, FlxG.width, "NO SCORES YET", 32);
        empty.setFormat(Paths.font(currentFont), 32, 0xFF666666, "center", 2, 0xFF000000);
        empty.cameras = [uiCam];
        leaderboardGroup.add(empty);
    } else { 
        var medalColors = [0xFFFFD700, 0xFFC0C0C0, 0xFFCD7F32]; 
        var medalIcons = ["1st", "2nd", "3rd"]; 
        
        var iterLimit = Std.int(Math.min(maxDisplay, entries.length - lbScroll));
        
        for (i in 0...iterLimit) { 
            var realIdx = lbScroll + i;
            var col = realIdx < 3 ? medalColors[realIdx] : 0xFFAAAAAA; 
            var prefix = realIdx < 3 ? medalIcons[realIdx] + "  " : (realIdx + 1) + ". "; 
            var rowBg = new FlxSprite(Std.int(FlxG.width * 0.15), Std.int(startY + (i * 42) - 4)).makeGraphic(Std.int(FlxG.width * 0.7), 36, realIdx < 3 ? 0xFF1A1A2E : 0xFF101018); 
            rowBg.alpha = 0.5; 
            rowBg.cameras = [uiCam]; 
            leaderboardGroup.add(rowBg); 
            var entry = new FlxText(0, startY + (i * 42), FlxG.width, prefix + entries[realIdx].name + "    " + entries[realIdx].score, 24); 
            entry.setFormat(Paths.font(currentFont), 24, col, "center", 2, 0xFF000000); 
            entry.cameras = [uiCam]; 
            entry.alpha = 0; 
            FlxTween.tween(entry, {alpha: 1}, 0.3, {startDelay: i * 0.06, ease: FlxEase.quadOut}); 
            leaderboardGroup.add(entry); 
        } 
    }
}

function log(msg:String) {}
function destroy() { netDisconnect(); }