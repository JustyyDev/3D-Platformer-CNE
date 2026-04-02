import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.group.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;

var uiCam:FlxCamera;
var currentFont:String = "vcr.ttf";
var flappyCoins:Int = 0;
var coinText:FlxText;
var coinIconText:FlxText;
var coinBounce:Float = 1.0;
var coinIconSpin:Float = 0;

var allAchievements:Array<Dynamic> = [];
var categories:Array<String> = ["ALL", "FLOCKFALL", "TREASURE", "BUMPER", "DODGE", "MUSICAL", "3D EXTRAS", "GENERAL", "SECRET"];
var catIndex:Int = 0;
var curSelected:Int = 0;
var scrollOffset:Int = 0;
var maxVisible:Int = 7;
var filteredList:Array<Dynamic> = [];

var headerText:FlxText;
var countText:FlxText;
var catText:FlxText;
var descTitle:FlxText;
var descBody:FlxText;
var descProgress:FlxText;
var cardGroup:FlxTypedGroup<FlxSprite>;
var cardTextGroup:FlxTypedGroup<FlxText>;
var titleGlow:Float = 0;

function create() {
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;
    if (FlxG.save.data.flappyCoins != null) flappyCoins = FlxG.save.data.flappyCoins;

    FlxG.camera.bgColor = 0xFF0A0A1A;

    uiCam = new FlxCamera();
    uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    buildAchievementList();
    setupUI();
    filterByCategory();
    refreshCards();
    checkCompletionist();
}

function buildAchievementList() {
    allAchievements = [
        {id: "ff_first", name: "FIRST FLIGHT", desc: "Play Flockfall for the first time", cat: "FLOCKFALL", secret: false, statKey: "flockfallGamesPlayed", target: 1},
        {id: "ff_pipe50", name: "PIPE DREAM", desc: "Score 50 in Flockfall", cat: "FLOCKFALL", secret: false, statKey: "flockfallHighScore", target: 50},
        {id: "ff_sky200", name: "SKY LEGEND", desc: "Score 200 in Flockfall", cat: "FLOCKFALL", secret: false, statKey: "flockfallHighScore", target: 200},
        {id: "ff_marathon", name: "MARATHON FLAPPER", desc: "Play 100 games of Flockfall", cat: "FLOCKFALL", secret: false, statKey: "flockfallGamesPlayed", target: 100},
        {id: "ff_untouchable", name: "UNTOUCHABLE", desc: "Score 100 in one Flockfall run", cat: "FLOCKFALL", secret: false, statKey: "flockfallHighScore", target: 100},
        {id: "ff_slingmaster", name: "SLINGSHOT MASTER", desc: "Win 10 slingshot matches", cat: "FLOCKFALL", secret: false, statKey: "slingshotWins", target: 10},
        {id: "ff_demolition", name: "DEMOLITION EXPERT", desc: "Destroy 500 blocks total", cat: "FLOCKFALL", secret: false, statKey: "blocksDestroyed", target: 500},
        {id: "ff_perfectshot", name: "PERFECT SHOT", desc: "Destroy all targets in one shot", cat: "FLOCKFALL", secret: false, statKey: "perfectShots", target: 1},
        {id: "ff_barrage", name: "BIRD BARRAGE", desc: "Play 500 games of Flockfall", cat: "FLOCKFALL", secret: false, statKey: "flockfallGamesPlayed", target: 500},
        {id: "ff_god", name: "FLOCKFALL GOD", desc: "Score 500 in Flockfall (legendary!)", cat: "FLOCKFALL", secret: false, statKey: "flockfallHighScore", target: 500},

        {id: "tg_hunter", name: "TREASURE HUNTER", desc: "Collect 100 coins in one Treasure Grab game", cat: "TREASURE", secret: false, statKey: "treasureGrabHighScore", target: 100},
        {id: "tg_rush", name: "GOLD RUSH", desc: "Collect 500 coins in one game", cat: "TREASURE", secret: false, statKey: "treasureGrabHighScore", target: 500},
        {id: "tg_hoarder", name: "HOARDER", desc: "Earn 10,000 total from Treasure Grab", cat: "TREASURE", secret: false, statKey: "treasureGrabTotalCoins", target: 10000},
        {id: "tg_speed", name: "SPEED COLLECTOR", desc: "Collect 50 coins in 15 seconds", cat: "TREASURE", secret: false, statKey: "treasureGrabSpeedRecord", target: 1},
        {id: "tg_king", name: "TREASURE KING", desc: "Win 50 multiplayer Treasure Grab games", cat: "TREASURE", secret: false, statKey: "treasureGrabMPWins", target: 50},
        {id: "tg_million", name: "MILLIONAIRE", desc: "Earn 100,000 total from Treasure Grab", cat: "TREASURE", secret: false, statKey: "treasureGrabTotalCoins", target: 100000},

        {id: "bb_rookie", name: "BUMPER ROOKIE", desc: "Win your first Bumper Birds match", cat: "BUMPER", secret: false, statKey: "bumperBirdsWins", target: 1},
        {id: "bb_bully", name: "BULLY", desc: "Push 50 opponents off the platform", cat: "BUMPER", secret: false, statKey: "bumperBirdsKills", target: 50},
        {id: "bb_clean", name: "UNTOUCHABLE BUMPER", desc: "Win without being pushed once", cat: "BUMPER", secret: false, statKey: "bumperBirdsCleanWins", target: 1},
        {id: "bb_master", name: "ARENA MASTER", desc: "Win 100 Bumper Birds matches", cat: "BUMPER", secret: false, statKey: "bumperBirdsWins", target: 100},
        {id: "bb_sumo", name: "SUMO CHAMPION", desc: "Win with max size power-up active", cat: "BUMPER", secret: false, statKey: "bumperBirdsSumoWins", target: 1},
        {id: "bb_100", name: "LAST STANDING 100", desc: "Be last alive 100 times in Bumper Birds", cat: "BUMPER", secret: false, statKey: "bumperBirdsWins", target: 100},

        {id: "dd_10", name: "DODGE THIS", desc: "Survive to wave 10 in Dodge Derby", cat: "DODGE", secret: false, statKey: "dodgeDerbyHighWave", target: 10},
        {id: "dd_25", name: "MATRIX MODE", desc: "Survive to wave 25", cat: "DODGE", secret: false, statKey: "dodgeDerbyHighWave", target: 25},
        {id: "dd_50", name: "INVINCIBLE", desc: "Survive to wave 50", cat: "DODGE", secret: false, statKey: "dodgeDerbyHighWave", target: 50},
        {id: "dd_reflex", name: "QUICK REFLEXES", desc: "Dodge 1000 total projectiles", cat: "DODGE", secret: false, statKey: "dodgeDerbyDodges", target: 1000},
        {id: "dd_100", name: "DODGE LEGEND", desc: "Survive to wave 100 (near impossible)", cat: "DODGE", secret: false, statKey: "dodgeDerbyHighWave", target: 100},
        {id: "dd_champ", name: "DERBY CHAMPION", desc: "Win 50 multiplayer Dodge Derby games", cat: "DODGE", secret: false, statKey: "dodgeDerbyMPWins", target: 50},

        {id: "mt_5", name: "MUSICAL FEET", desc: "Survive 5 rounds in Musical Tiles", cat: "MUSICAL", secret: false, statKey: "musicalTilesHighRound", target: 5},
        {id: "mt_15", name: "DANCE MACHINE", desc: "Survive 15 rounds", cat: "MUSICAL", secret: false, statKey: "musicalTilesHighRound", target: 15},
        {id: "mt_streak", name: "PERFECT RHYTHM", desc: "Win 3 Musical Tiles games in a row", cat: "MUSICAL", secret: false, statKey: "musicalTilesWinStreak", target: 3},
        {id: "mt_50", name: "TILE MASTER", desc: "Win 50 Musical Tiles games", cat: "MUSICAL", secret: false, statKey: "musicalTilesWins", target: 50},
        {id: "mt_30", name: "ETERNAL DANCER", desc: "Survive 30 rounds (very hard!)", cat: "MUSICAL", secret: false, statKey: "musicalTilesHighRound", target: 30},

        {id: "sr_1000", name: "SKY RUNNER", desc: "Run 1000m in Sky Run", cat: "3D EXTRAS", secret: false, statKey: "skyRunHighDistance", target: 1000},
        {id: "sr_5000", name: "SKY LEGEND", desc: "Run 5000m in Sky Run", cat: "3D EXTRAS", secret: false, statKey: "skyRunHighDistance", target: 5000},
        {id: "sr_10000", name: "INFINITE RUNNER", desc: "Run 10000m (near impossible!)", cat: "3D EXTRAS", secret: false, statKey: "skyRunHighDistance", target: 10000},
        {id: "cc_10", name: "CUBE FIGHTER", desc: "Win 10 Cube Clash matches", cat: "3D EXTRAS", secret: false, statKey: "cubeClashWins", target: 10},
        {id: "cc_100", name: "ARENA LEGEND", desc: "Win 100 Cube Clash matches", cat: "3D EXTRAS", secret: false, statKey: "cubeClashWins", target: 100},
        {id: "tc_500", name: "TOWER ROOKIE", desc: "Reach 500m in Tower Climb", cat: "3D EXTRAS", secret: false, statKey: "towerClimbHighHeight", target: 500},
        {id: "tc_summit", name: "SUMMIT SEEKER", desc: "Reach the summit in Tower Climb", cat: "3D EXTRAS", secret: false, statKey: "towerClimbSummits", target: 1},
        {id: "tc_speed", name: "SPEED CLIMBER", desc: "Reach summit in under 60 seconds", cat: "3D EXTRAS", secret: false, statKey: "towerClimbSpeedRun", target: 1},
        {id: "tc_50", name: "MOUNTAIN GOD", desc: "Reach the summit 50 times", cat: "3D EXTRAS", secret: false, statKey: "towerClimbSummits", target: 50},

        {id: "gen_welcome", name: "WELCOME!", desc: "Play any game for the first time", cat: "GENERAL", secret: false, statKey: "totalGamesPlayed", target: 1},
        {id: "gen_collector", name: "COLLECTOR", desc: "Own 10 shop items", cat: "GENERAL", secret: false, statKey: "totalItemsOwned", target: 10},
        {id: "gen_fashion", name: "FASHIONISTA", desc: "Own 30 shop items", cat: "GENERAL", secret: false, statKey: "totalItemsOwned", target: 30},
        {id: "gen_shopaholic", name: "SHOPAHOLIC", desc: "Own ALL shop items (good luck!)", cat: "GENERAL", secret: false, statKey: "totalItemsOwned", target: 80},
        {id: "gen_social", name: "SOCIAL BUTTERFLY", desc: "Play 10 multiplayer games", cat: "GENERAL", secret: false, statKey: "multiplayerGamesPlayed", target: 10},
        {id: "gen_party", name: "PARTY ANIMAL", desc: "Play 100 multiplayer games", cat: "GENERAL", secret: false, statKey: "multiplayerGamesPlayed", target: 100},
        {id: "gen_code1", name: "CODE HUNTER", desc: "Redeem your first code", cat: "GENERAL", secret: false, statKey: "codesRedeemed", target: 1},
        {id: "gen_code10", name: "CODE COLLECTOR", desc: "Redeem 10 different codes", cat: "GENERAL", secret: false, statKey: "codesRedeemed", target: 10},
        {id: "gen_spender", name: "BIG SPENDER", desc: "Spend 100,000 flockers total", cat: "GENERAL", secret: false, statKey: "totalFlockerSpent", target: 100000},
        {id: "gen_completionist", name: "THE COMPLETIONIST", desc: "Unlock ALL other achievements", cat: "GENERAL", secret: false, statKey: null, target: 0},

        {id: "sec_deaths", name: "???", desc: "Die 100 times across all games", cat: "SECRET", secret: true, statKey: "totalDeaths", target: 100, revealName: "PERSISTENT FAILURE", revealDesc: "Die 100 times across all games"},
        {id: "sec_broke", name: "???", desc: "Try to buy something you can't afford 50 times", cat: "SECRET", secret: true, statKey: "cantAffordAttempts", target: 50, revealName: "WINDOW SHOPPER", revealDesc: "Try to buy something you can't afford 50 times"},
        {id: "sec_afk", name: "???", desc: "Stay in a menu for 10 minutes", cat: "SECRET", secret: true, statKey: "afkTime", target: 1, revealName: "AFK CHAMPION", revealDesc: "Stay in a menu for 10 minutes without doing anything"},
        {id: "sec_allgames", name: "???", desc: "Play every single game mode", cat: "SECRET", secret: true, statKey: "allGamesPlayed", target: 1, revealName: "VARIETY GAMER", revealDesc: "Play every single game mode at least once"},
        {id: "sec_1337", name: "???", desc: "???", cat: "SECRET", secret: true, statKey: "earned1337", target: 1, revealName: "LEET", revealDesc: "Earn exactly 1337 lifetime flockers"}
    ];
}

function setupUI() {
    var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF0A0A1A);
    bg.cameras = [uiCam]; add(bg);

    var sidePanel = new FlxSprite().makeGraphic(460, FlxG.height, 0xFF000000);
    sidePanel.alpha = 0.5; sidePanel.cameras = [uiCam]; add(sidePanel);

    var accent = new FlxSprite(458, 0).makeGraphic(3, FlxG.height, 0xFFFFD700);
    accent.alpha = 0.6; accent.cameras = [uiCam]; add(accent);

    headerText = new FlxText(20, 12, 420, "ACHIEVEMENTS", 36);
    headerText.setFormat(Paths.font(currentFont), 36, 0xFFFFD700, "left"); headerText.cameras = [uiCam]; add(headerText);

    var unlocked = getUnlockedCount();
    var total = allAchievements.length;
    var pct = Std.int((unlocked / total) * 100);
    countText = new FlxText(20, 52, 420, unlocked + "/" + total + " UNLOCKED (" + pct + "%)", 16);
    countText.setFormat(Paths.font(currentFont), 16, 0xFFAAAAAA, "left"); countText.cameras = [uiCam]; add(countText);

    catText = new FlxText(20, 76, 420, "[<] " + categories[catIndex] + " [>]", 18);
    catText.setFormat(Paths.font(currentFont), 18, 0xFF88CCFF, "left"); catText.cameras = [uiCam]; add(catText);

    cardGroup = new FlxTypedGroup(); add(cardGroup);
    cardTextGroup = new FlxTypedGroup(); add(cardTextGroup);

    descTitle = new FlxText(480, 120, FlxG.width - 500, "", 28);
    descTitle.setFormat(Paths.font(currentFont), 28, 0xFFFFD700, "left", 2, 0xFF000000); descTitle.cameras = [uiCam]; add(descTitle);

    descBody = new FlxText(480, 160, FlxG.width - 500, "", 18);
    descBody.setFormat(Paths.font(currentFont), 18, 0xFFCCCCCC, "left"); descBody.cameras = [uiCam]; add(descBody);

    descProgress = new FlxText(480, 220, FlxG.width - 500, "", 20);
    descProgress.setFormat(Paths.font(currentFont), 20, 0xFF88FF44, "left"); descProgress.cameras = [uiCam]; add(descProgress);

    coinIconText = new FlxText(FlxG.width - 240, 14, 30, "F", 20);
    coinIconText.setFormat(Paths.font(currentFont), 20, 0xFFFFD700, "center"); coinIconText.cameras = [uiCam]; add(coinIconText);
    coinText = new FlxText(FlxG.width - 210, 14, 190, "" + flappyCoins, 20);
    coinText.setFormat(Paths.font(currentFont), 20, 0xFFFFD700, "right"); coinText.cameras = [uiCam]; add(coinText);

    var helpText = new FlxText(480, FlxG.height - 50, FlxG.width - 500, "[UP/DOWN] SELECT   [LEFT/RIGHT] CATEGORY   [ESC] BACK", 14);
    helpText.setFormat(Paths.font(currentFont), 14, 0xFF666666, "left"); helpText.cameras = [uiCam]; add(helpText);
}

function filterByCategory() {
    filteredList = [];
    var cat = categories[catIndex];
    for (a in allAchievements) {
        if (cat == "ALL" || a.cat == cat) filteredList.push(a);
    }
    curSelected = 0;
    scrollOffset = 0;
}

function refreshCards() {
    cardGroup.clear();
    cardTextGroup.clear();

    var startY = 100;
    var cardH = 58;

    for (vi in 0...maxVisible) {
        var idx = scrollOffset + vi;
        if (idx >= filteredList.length) break;
        var ach = filteredList[idx];
        var unlocked = hasAchievement(ach.id);
        var isSel = idx == curSelected;

        var cy = startY + vi * cardH;
        var bgCol = unlocked ? 0xFF1A1A0A : 0xFF0D0D18;
        var card = new FlxSprite(10, cy).makeGraphic(440, Std.int(cardH - 4), bgCol);
        card.alpha = isSel ? 0.8 : 0.4;
        card.cameras = [uiCam];
        cardGroup.add(card);

        if (unlocked) {
            var goldStripe = new FlxSprite(10, cy).makeGraphic(4, Std.int(cardH - 4), 0xFFFFD700);
            goldStripe.cameras = [uiCam]; cardGroup.add(goldStripe);
        }

        var icon = unlocked ? "+" : (ach.secret ? "?" : "-");
        var iconText = new FlxText(18, cy + 8, 30, icon, 28);
        var iconCol = unlocked ? 0xFFFFD700 : (ach.secret ? 0xFF666666 : 0xFF444444);
        iconText.setFormat(Paths.font(currentFont), 28, iconCol, "center"); iconText.cameras = [uiCam]; cardTextGroup.add(iconText);

        var displayName = ach.name;
        if (ach.secret && !unlocked) displayName = "???";
        else if (unlocked && ach.revealName != null) displayName = ach.revealName;
        var nameCol = unlocked ? 0xFFFFD700 : (isSel ? 0xFFFFFFFF : 0xFF888888);
        var nameText = new FlxText(52, cy + 6, 390, displayName, 22);
        nameText.setFormat(Paths.font(currentFont), 22, nameCol, "left", 1, 0xFF000000); nameText.cameras = [uiCam]; cardTextGroup.add(nameText);

        if (ach.statKey != null && ach.target > 1) {
            var current = getStat(ach.statKey);
            if (current > ach.target) current = ach.target;
            var progText = new FlxText(52, cy + 30, 390, current + "/" + ach.target, 14);
            var progCol = unlocked ? 0xFF88FF44 : 0xFF555555;
            progText.setFormat(Paths.font(currentFont), 14, progCol, "left"); progText.cameras = [uiCam]; cardTextGroup.add(progText);

            var barW = 200;
            var barBg = new FlxSprite(230, cy + 34).makeGraphic(barW, 8, 0xFF222222);
            barBg.cameras = [uiCam]; cardGroup.add(barBg);
            var fillW = Std.int((current / ach.target) * barW);
            if (fillW < 1) fillW = 1;
            if (fillW > barW) fillW = barW;
            var barFill = new FlxSprite(230, cy + 34).makeGraphic(fillW, 8, unlocked ? 0xFFFFD700 : 0xFF446688);
            barFill.cameras = [uiCam]; cardGroup.add(barFill);
        }
    }

    updateDescription();
}

function updateDescription() {
    if (curSelected >= filteredList.length) { descTitle.text = ""; descBody.text = ""; descProgress.text = ""; return; }
    var ach = filteredList[curSelected];
    var unlocked = hasAchievement(ach.id);

    if (ach.secret && !unlocked) {
        descTitle.text = "???";
        descBody.text = "This is a secret achievement.\nKeep playing to discover it!";
        descProgress.text = "";
    } else {
        descTitle.text = unlocked && ach.revealName != null ? ach.revealName : ach.name;
        descBody.text = unlocked && ach.revealDesc != null ? ach.revealDesc : ach.desc;
        descTitle.color = unlocked ? 0xFFFFD700 : 0xFFFFFFFF;

        if (ach.statKey != null && ach.target > 0) {
            var current = getStat(ach.statKey);
            if (current > ach.target) current = ach.target;
            descProgress.text = unlocked ? "COMPLETED!" : (current + " / " + ach.target);
            descProgress.color = unlocked ? 0xFFFFD700 : 0xFF88CCFF;
        } else if (ach.id == "gen_completionist") {
            var total = allAchievements.length - 1;
            var have = getUnlockedCount();
            if (hasAchievement("gen_completionist")) have = have - 1;
            descProgress.text = unlocked ? "COMPLETED!" : (have + " / " + total + " achievements");
            descProgress.color = unlocked ? 0xFFFFD700 : 0xFF88CCFF;
        } else {
            descProgress.text = unlocked ? "COMPLETED!" : "";
            descProgress.color = unlocked ? 0xFFFFD700 : 0xFF88CCFF;
        }
    }
}

function update(elapsed:Float) {
    titleGlow += elapsed * 2.5;
    headerText.alpha = 0.8 + Math.sin(titleGlow) * 0.2;
    if (coinBounce > 1.0) { coinBounce = FlxMath.lerp(coinBounce, 1.0, elapsed * 8); coinText.scale.set(coinBounce, coinBounce); }
    coinIconSpin += elapsed * 6; if (coinIconText != null) coinIconText.scale.set(Math.abs(Math.cos(coinIconSpin)) * 0.6 + 0.4, 1.0);

    if (FlxG.keys.justPressed.ESCAPE) { FlxG.switchState(new ModState("CustomMainMenu")); return; }

    if (FlxG.keys.justPressed.LEFT) {
        catIndex--; if (catIndex < 0) catIndex = categories.length - 1;
        catText.text = "[<] " + categories[catIndex] + " [>]";
        filterByCategory(); refreshCards();
    }
    if (FlxG.keys.justPressed.RIGHT) {
        catIndex++; if (catIndex >= categories.length) catIndex = 0;
        catText.text = "[<] " + categories[catIndex] + " [>]";
        filterByCategory(); refreshCards();
    }
    if (FlxG.keys.justPressed.UP && filteredList.length > 0) {
        curSelected--; if (curSelected < 0) curSelected = filteredList.length - 1;
        if (curSelected < scrollOffset) scrollOffset = curSelected;
        if (curSelected >= scrollOffset + maxVisible) scrollOffset = curSelected - maxVisible + 1;
        refreshCards();
    }
    if (FlxG.keys.justPressed.DOWN && filteredList.length > 0) {
        curSelected++; if (curSelected >= filteredList.length) curSelected = 0;
        if (curSelected >= scrollOffset + maxVisible) scrollOffset = curSelected - maxVisible + 1;
        if (curSelected < scrollOffset) scrollOffset = curSelected;
        refreshCards();
    }
}

function getUnlockedCount():Int {
    var achs:Array<String> = FlxG.save.data.flappyAchievements;
    if (achs == null) return 0;
    return achs.length;
}

function hasAchievement(id:String):Bool {
    var achs:Array<String> = FlxG.save.data.flappyAchievements;
    if (achs == null) return false;
    for (a in achs) if (a == id) return true;
    return false;
}

function unlockAchievement(id:String) {
    if (hasAchievement(id)) return;
    var achs:Array<String> = FlxG.save.data.flappyAchievements;
    if (achs == null) achs = [];
    achs.push(id);
    FlxG.save.data.flappyAchievements = achs;
    FlxG.save.flush();
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

function incrementStat(key:String, amount:Int) {
    saveStat(key, getStat(key) + amount);
}

function checkCompletionist() {
    var total = allAchievements.length - 1;
    var have = getUnlockedCount();
    if (hasAchievement("gen_completionist")) return;
    var countWithout = have;
    if (countWithout >= total) unlockAchievement("gen_completionist");
}

function checkAllGamesPlayed() {
    if (getStat("flockfallGamesPlayed") > 0 &&
        getStat("treasureGrabTotalCoins") > 0 &&
        getStat("bumperBirdsWins") + getStat("bumperBirdsKills") > 0 &&
        getStat("dodgeDerbyGamesPlayed") > 0 &&
        getStat("musicalTilesHighRound") > 0 &&
        getStat("skyRunGamesPlayed") > 0 &&
        getStat("cubeClashWins") > 0 &&
        getStat("towerClimbHighHeight") > 0) {
        saveStat("allGamesPlayed", 1);
        unlockAchievement("sec_allgames");
    }
}
