import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.group.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import funkin.backend.scripting.ModState;
import sys.net.Host;
import funkin.backend.system.net.Socket;

var uiCam:FlxCamera;
var currentFont:String = "vcr.ttf";
var myNickname:String = "Player";
var flappyCoins:Int = 0;
var coinBounce:Float = 1.0;
var coinIconSpin:Float = 0;

var SERVER_IP:String = "144.21.35.78";
var SERVER_PORT:Int = 8080;

var allSkins:Array<Dynamic> = [
    {id: "default", name: "DEFAULT", color: 0xFFFFEE00, price: 0, hat: "none", power: "none"},
    {id: "ice", name: "ICE BIRD", color: 0xFF00CCFF, price: 50, hat: "none", power: "none"},
    {id: "bubblegum", name: "BUBBLEGUM", color: 0xFFFF6699, price: 50, hat: "none", power: "none"},
    {id: "neon", name: "NEON", color: 0xFF66FF66, price: 75, hat: "none", power: "none"},
    {id: "sunset", name: "SUNSET", color: 0xFFFF9933, price: 75, hat: "none", power: "none"},
    {id: "lavender", name: "LAVENDER", color: 0xFFCC66FF, price: 100, hat: "none", power: "none"},
    {id: "crimson", name: "CRIMSON", color: 0xFFFF0000, price: 150, hat: "none", power: "none"},
    {id: "aqua", name: "AQUA", color: 0xFF00FFCC, price: 150, hat: "none", power: "none"},
    {id: "ghost", name: "GHOST", color: 0xFFFFFFFF, price: 200, hat: "halo", power: "ghost"},
    {id: "shadow", name: "SHADOW", color: 0xFF333333, price: 300, hat: "none", power: "none"},
    {id: "pink", name: "HOT PINK", color: 0xFFFF1493, price: 125, hat: "none", power: "none"},
    {id: "royal", name: "ROYAL BLUE", color: 0xFF4169E1, price: 175, hat: "crown", power: "none"},
    {id: "blaze", name: "BLAZE", color: 0xFFFF4500, price: 225, hat: "horns", power: "speed"},
    {id: "ultra", name: "ULTRAVIOLET", color: 0xFF8B00FF, price: 350, hat: "none", power: "none"},
    {id: "teal", name: "TEAL WAVE", color: 0xFF00CED1, price: 400, hat: "none", power: "none"},
    {id: "golden", name: "GOLDEN KING", color: 0xFFFFD700, price: 500, hat: "bigcrown", power: "heavy"},
    {id: "pirate", name: "PIRATE", color: 0xFF8B4513, price: 250, hat: "pirate", power: "none"},
    {id: "ninja", name: "NINJA", color: 0xFF111111, price: 280, hat: "headband", power: "speed"},
    {id: "cowboy", name: "COWBOY", color: 0xFFD2B48C, price: 320, hat: "cowboy", power: "none"},
    {id: "chef", name: "MASTER CHEF", color: 0xFFEEEEEE, price: 180, hat: "chef", power: "none"},
    {id: "wizard", name: "WIZARD", color: 0xFF4B0082, price: 450, hat: "wizard", power: "explode"},
    {id: "cyborg", name: "CYBORG", color: 0xFFC0C0C0, price: 380, hat: "antenna", power: "heavy"},
    {id: "zombie", name: "ZOMBIE", color: 0xFF556B2F, price: 260, hat: "brain", power: "none"},
    {id: "angel", name: "PURE ANGEL", color: 0xFFFFFACD, price: 600, hat: "halo", power: "ghost"},
    {id: "demon", name: "ARCH DEMON", color: 0xFF8B0000, price: 600, hat: "horns", power: "explode"},
    {id: "alien", name: "ALIEN", color: 0xFF32CD32, price: 420, hat: "ufo", power: "none"},
    {id: "knight", name: "PALADIN", color: 0xFFB0C4DE, price: 550, hat: "helmet", power: "heavy"},
    {id: "mythic", name: "MYTHIC BIRD", color: 0xFF00FA9A, price: 1000, hat: "bigcrown", power: "speed"},
    {id: "galaxy", name: "GALAXY", color: 0xFF191970, price: 2500, hat: "antenna", power: "explode"},
    {id: "divine", name: "DIVINE BIRD", color: 0xFFE0FFFF, price: 5000, hat: "halo", power: "ghost"},
    {id: "omega", name: "OMEGA", color: 0xFFFF00FF, price: 10000, hat: "horns", power: "explode"},
    {id: "creator", name: "THE CREATOR", color: 0xFFFFFFFF, price: 50000, hat: "bigcrown", power: "heavy"}
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
    {id: "galaxy", name: "GALAXY TRAIL", color: 0xFF4B0082, price: 1500},
    {id: "plasma", name: "PLASMA", color: 0xFF00FF00, price: 3000},
    {id: "blackhole", name: "BLACK HOLE", color: 0xFF000000, price: 10000}
];

var allBGs:Array<Dynamic> = [
    {id: "day", name: "DAY", price: 0, bg: 0xFF87CEEB, ground: 0xFF4A8C3F},
    {id: "sunset", name: "SUNSET", price: 75, bg: 0xFFFF6B35, ground: 0xFF8B4513},
    {id: "night", name: "NIGHT", price: 100, bg: 0xFF0A0A2E, ground: 0xFF1A1A4E},
    {id: "neon", name: "NEON CITY", price: 200, bg: 0xFF1A0033, ground: 0xFF220044},
    {id: "void", name: "THE VOID", price: 400, bg: 0xFF000000, ground: 0xFF111111},
    {id: "ocean", name: "OCEAN", price: 150, bg: 0xFF1A6B8A, ground: 0xFF1A5570},
    {id: "inferno", name: "INFERNO", price: 250, bg: 0xFF3A0A00, ground: 0xFF5A1A00},
    {id: "forest", name: "FOREST", price: 150, bg: 0xFF224422, ground: 0xFF1A331A},
    {id: "desert", name: "DESERT", price: 150, bg: 0xFFEEDD88, ground: 0xFFCC9944},
    {id: "winter", name: "WINTER", price: 200, bg: 0xFFBBDDFF, ground: 0xFFEEEEFF},
    {id: "cyberpunk", name: "CYBERPUNK", price: 350, bg: 0xFF0A0A1A, ground: 0xFF111122},
    {id: "alien", name: "ALIEN", price: 300, bg: 0xFF110022, ground: 0xFF2A0033},
    {id: "space", name: "DEEP SPACE", price: 450, bg: 0xFF000011, ground: 0xFF222233},
    {id: "matrix", name: "MATRIX", price: 500, bg: 0xFF001100, ground: 0xFF002200},
    {id: "multiverse", name: "MULTIVERSE", price: 2000, bg: 0xFF1A001A, ground: 0xFF330033},
    {id: "heaven", name: "HEAVEN", price: 5000, bg: 0xFFFFFFF0, ground: 0xFFFFFACD},
    {id: "glitchbg", name: "GLITCH DIMENSION", price: 15000, bg: 0xFF000000, ground: 0xFF00FF00}
];

var allPackages:Array<Dynamic> = [
    {id: "pack1", name: "1,000 FLOCKERS", realPrice: "$0.99", coins: 1000},
    {id: "pack2", name: "5,000 FLOCKERS", realPrice: "$3.99", coins: 5000},
    {id: "pack3", name: "15,000 FLOCKERS", realPrice: "$9.99", coins: 15000},
    {id: "pack4", name: "50,000 FLOCKERS", realPrice: "$24.99", coins: 50000},
    {id: "pack5", name: "250,000 FLOCKERS", realPrice: "$99.99", coins: 250000}
];

var shopSkins:Array<Dynamic> = [];
var shopTrails:Array<Dynamic> = [];
var shopBGs:Array<Dynamic> = [];
var shopPackages:Array<Dynamic> = [];

var equippedSkinId:String = "default";
var equippedTrailId:String = "none";
var equippedBGId:String = "day";

var shopCategory:Int = 0;
var shopScroll:Int = 0;
var shopCursor:Int = 0;
var shopUIGroup:FlxTypedGroup<FlxSprite>;
var shopTextGroup:FlxTypedGroup<FlxText>;
var pendingPack:Dynamic = null;
var verifyState:String = "SHOP";
var statusText:FlxText;
var coinText:FlxText;
var coinIconText:FlxText;

function create() {
    if (FlxG.save.data.flappyNickname != null) myNickname = FlxG.save.data.flappyNickname;
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;
    if (FlxG.save.data.flappyCoins != null) flappyCoins = FlxG.save.data.flappyCoins;

    FlxG.camera.bgColor = 0xFF0A0A18;
    uiCam = new FlxCamera(); uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    shopUIGroup = new FlxTypedGroup(); add(shopUIGroup);
    shopTextGroup = new FlxTypedGroup(); add(shopTextGroup);

    coinIconText = makeText(FlxG.width - 240, 10, 30, "F", 20, 0xFFFFD700);
    coinText = makeText(FlxG.width - 210, 10, 190, "" + flappyCoins, 20, 0xFFFFD700); coinText.alignment = "right";
    statusText = makeText(0, FlxG.height * 0.78, FlxG.width, "", 22, 0xFFFFEE00);

    loadShopData();
    verifyState = "SHOP";
    renderShop();
    FlxG.sound.playMusic(Paths.music("flappy/shopTheme"), 0.8, true);
}

function makeText(x:Float, y:Float, w:Float, text:String, size:Int, color:Int):FlxText {
    var t = new FlxText(x, y, w, text, size);
    t.setFormat(Paths.font(currentFont), size, color, "center", 2, 0xFF000000);
    t.cameras = [uiCam]; add(t); return t;
}

function loadShopData() {
    var ownedSkins:Array<String> = ["default"]; var ownedTrails:Array<String> = ["none"]; var ownedBGs:Array<String> = ["day"];
    if (FlxG.save.data.flappyOwnedSkinsV5 != null) ownedSkins = FlxG.save.data.flappyOwnedSkinsV5;
    if (FlxG.save.data.flappyOwnedTrailsV5 != null) ownedTrails = FlxG.save.data.flappyOwnedTrailsV5;
    if (FlxG.save.data.flappyOwnedBGsV5 != null) ownedBGs = FlxG.save.data.flappyOwnedBGsV5;
    if (FlxG.save.data.flappyEquippedSkinId != null) equippedSkinId = FlxG.save.data.flappyEquippedSkinId;
    if (FlxG.save.data.flappyEquippedTrailId != null) equippedTrailId = FlxG.save.data.flappyEquippedTrailId;
    if (FlxG.save.data.flappyEquippedBGId != null) equippedBGId = FlxG.save.data.flappyEquippedBGId;

    shopSkins = []; for (s in allSkins) { var item = Reflect.copy(s); item.owned = ownedSkins.indexOf(item.id) != -1; shopSkins.push(item); }
    shopTrails = []; for (t in allTrails) { var item = Reflect.copy(t); item.owned = ownedTrails.indexOf(item.id) != -1; shopTrails.push(item); }
    shopBGs = []; for (b in allBGs) { var item = Reflect.copy(b); item.owned = ownedBGs.indexOf(item.id) != -1; shopBGs.push(item); }
    shopPackages = []; for (p in allPackages) shopPackages.push(Reflect.copy(p));

    var sorter = function(a, b) { if (a.price != b.price) return a.price - b.price; return (a.name < b.name) ? -1 : 1; };
    shopSkins.sort(sorter); shopTrails.sort(sorter); shopBGs.sort(sorter);
}

function saveShopData() {
    var os = []; for (s in shopSkins) if (s.owned) os.push(s.id);
    var ot = []; for (t in shopTrails) if (t.owned) ot.push(t.id);
    var ob = []; for (b in shopBGs) if (b.owned) ob.push(b.id);
    FlxG.save.data.flappyOwnedSkinsV5 = os; FlxG.save.data.flappyOwnedTrailsV5 = ot; FlxG.save.data.flappyOwnedBGsV5 = ob;
    FlxG.save.data.flappyEquippedSkinId = equippedSkinId; FlxG.save.data.flappyEquippedTrailId = equippedTrailId; FlxG.save.data.flappyEquippedBGId = equippedBGId;
    FlxG.save.flush();
}

function getSkinData(id:String):Dynamic { for (s in allSkins) if (s.id == id) return s; return allSkins[0]; }
function getTrailData(id:String):Dynamic { for (t in allTrails) if (t.id == id) return t; return allTrails[0]; }

function darkenColor(col:Int, factor:Float):Int {
    var r = Std.int(((col >> 16) & 0xFF) * factor);
    var g = Std.int(((col >> 8) & 0xFF) * factor);
    var b = Std.int((col & 0xFF) * factor);
    return 0xFF000000 | (r << 16) | (g << 8) | b;
}

function addCoins(amount:Int) { flappyCoins += amount; FlxG.save.data.flappyCoins = flappyCoins; FlxG.save.flush(); coinText.text = "" + flappyCoins; coinBounce = 1.3; }
function spendCoins(amount:Int):Bool { if (flappyCoins < amount) return false; flappyCoins -= amount; FlxG.save.data.flappyCoins = flappyCoins; FlxG.save.flush(); coinText.text = "" + flappyCoins; coinBounce = 1.3; return true; }

function applyHat(hatId:String, target1:FlxSprite, target2:FlxSprite, bx:Float, by:Float) {
    target1.visible = false; target2.visible = false;
    if (hatId == "none") return;
    target1.visible = true; target2.visible = true;
    var ox = bx + 19; var oy = by - 4;

    if (hatId == "crown") { target1.makeGraphic(20, 10, 0xFFFFD700); target1.setPosition(ox - 10, oy - 10); target2.visible = false; }
    else if (hatId == "bigcrown") { target1.makeGraphic(26, 16, 0xFFFFD700); target1.setPosition(ox - 13, oy - 16); target2.makeGraphic(8, 8, 0xFFFF0000); target2.setPosition(ox - 4, oy - 10); }
    else if (hatId == "halo") { target1.makeGraphic(24, 4, 0xFFFFFF00); target1.setPosition(ox - 12, oy - 20); target2.visible = false; }
    else if (hatId == "headband") { target1.makeGraphic(38, 6, 0xFFFF0000); target1.setPosition(bx, by + 4); target2.visible = false; }
    else if (hatId == "cowboy") { target1.makeGraphic(36, 6, 0xFF8B4513); target1.setPosition(ox - 18, oy - 6); target2.makeGraphic(18, 14, 0xFF8B4513); target2.setPosition(ox - 9, oy - 20); }
    else if (hatId == "chef") { target1.makeGraphic(16, 12, 0xFFFFFFFF); target1.setPosition(ox - 8, oy - 12); target2.makeGraphic(24, 14, 0xFFFFFFFF); target2.setPosition(ox - 12, oy - 26); }
    else if (hatId == "wizard") { target1.makeGraphic(28, 6, 0xFF4B0082); target1.setPosition(ox - 14, oy - 6); target2.makeGraphic(14, 20, 0xFF4B0082); target2.setPosition(ox - 7, oy - 26); }
    else if (hatId == "antenna") { target1.makeGraphic(4, 16, 0xFF888888); target1.setPosition(ox - 2, oy - 16); target2.makeGraphic(8, 8, 0xFFFF0000); target2.setPosition(ox - 4, oy - 24); }
    else if (hatId == "brain") { target1.makeGraphic(20, 12, 0xFFFF66AA); target1.setPosition(ox - 10, oy - 12); target2.visible = false; }
    else if (hatId == "horns") { target1.makeGraphic(6, 12, 0xFF8B0000); target1.setPosition(ox - 12, oy - 12); target2.makeGraphic(6, 12, 0xFF8B0000); target2.setPosition(ox + 6, oy - 12); }
    else if (hatId == "ufo") { target1.makeGraphic(30, 8, 0xFF888888); target1.setPosition(ox - 15, oy - 16); target2.makeGraphic(14, 10, 0xFF00FFCC); target2.setPosition(ox - 7, oy - 26); }
    else if (hatId == "helmet") { target1.makeGraphic(24, 20, 0xFFB0C4DE); target1.setPosition(ox - 12, oy - 16); target2.makeGraphic(4, 14, 0xFF000000); target2.setPosition(ox + 4, oy - 12); }
    else if (hatId == "pirate") { target1.makeGraphic(30, 12, 0xFF222222); target1.setPosition(ox - 15, oy - 12); target2.makeGraphic(6, 6, 0xFF000000); target2.setPosition(ox + 10, oy + 4); }
}

function renderShop() {
    shopUIGroup.clear(); shopTextGroup.clear();
    var catNames = ["BIRD SKINS", "TRAILS", "BACKGROUNDS", "FLOCKER PACKS"];
    var catalog:Array<Dynamic>; var equippedId:String = "";

    if (shopCategory == 0) { catalog = shopSkins; equippedId = equippedSkinId; }
    else if (shopCategory == 1) { catalog = shopTrails; equippedId = equippedTrailId; }
    else if (shopCategory == 2) { catalog = shopBGs; equippedId = equippedBGId; }
    else { catalog = shopPackages; equippedId = ""; }

    if (shopCursor >= catalog.length) shopCursor = catalog.length - 1;
    if (shopCursor < 0) shopCursor = 0;

    var maxVisible = 7;
    if (shopCursor < shopScroll) shopScroll = shopCursor;
    if (shopCursor >= shopScroll + maxVisible) shopScroll = shopCursor - maxVisible + 1;
    if (shopScroll < 0) shopScroll = 0;

    var headerBg = new FlxSprite(0, 0).makeGraphic(FlxG.width, Std.int(FlxG.height * 0.13), 0xFF0D0D1A); headerBg.alpha = 0.75; headerBg.cameras = [uiCam]; shopUIGroup.add(headerBg);
    var shopTitle = new FlxText(0, 12, FlxG.width, "SHOP", 48); shopTitle.setFormat(Paths.font(currentFont), 48, 0xFFFFEE00, "center", 3, 0xFF000000); shopTitle.cameras = [uiCam]; shopTextGroup.add(shopTitle);
    var balanceText = new FlxText(0, 62, FlxG.width, "BALANCE: " + flappyCoins + " FLOCKERS", 18); balanceText.setFormat(Paths.font(currentFont), 18, 0xFFFFD700, "center", 1, 0xFF000000); balanceText.cameras = [uiCam]; shopTextGroup.add(balanceText);

    var tabY = Std.int(FlxG.height * 0.14);
    var tabBarBg = new FlxSprite(0, tabY).makeGraphic(FlxG.width, 32, 0xFF111122); tabBarBg.alpha = 0.6; tabBarBg.cameras = [uiCam]; shopUIGroup.add(tabBarBg);
    for (ci in 0...4) {
        var isActive = ci == shopCategory; var tabCol = isActive ? 0xFFFFEE00 : 0xFF666666; var tabW = FlxG.width / 4;
        var tab = new FlxText(Std.int(ci * tabW), tabY + 4, Std.int(tabW), (isActive ? "> " : "  ") + catNames[ci], 17);
        tab.setFormat(Paths.font(currentFont), 17, tabCol, "center", 2, 0xFF000000); tab.cameras = [uiCam]; shopTextGroup.add(tab);
        if (isActive) { var ul = new FlxSprite(Std.int(ci * tabW + tabW * 0.15), tabY + 28).makeGraphic(Std.int(tabW * 0.7), 3, 0xFFFFEE00); ul.cameras = [uiCam]; shopUIGroup.add(ul); }
    }

    var startY = Std.int(FlxG.height * 0.22); var slotH = 48; var listW = Std.int(FlxG.width * 0.62); var listX = Std.int(FlxG.width * 0.04);
    for (idx in 0...catalog.length) {
        if (idx < shopScroll || idx >= shopScroll + maxVisible) continue;
        var item = catalog[idx]; var slotY = startY + ((idx - shopScroll) * slotH);
        var isEquipped = item.id == equippedId; var isOwned = shopCategory != 3 && item.owned; var isCursor = idx == shopCursor;
        var bgCol = isCursor ? 0xFF2A2A4E : (isEquipped ? 0xFF1A3A1A : 0xFF12121E);
        var slotBg = new FlxSprite(listX, Std.int(slotY)).makeGraphic(listW, Std.int(slotH - 4), bgCol); slotBg.alpha = isCursor ? 0.85 : 0.5; slotBg.cameras = [uiCam]; shopUIGroup.add(slotBg);
        if (isCursor) {
            var ca = new FlxText(listX + 4, slotY + 8, 30, ">", 24); ca.setFormat(Paths.font(currentFont), 24, 0xFFFFEE00, "left", 2, 0xFF000000); ca.cameras = [uiCam]; shopTextGroup.add(ca);
            var hlBar = new FlxSprite(listX, Std.int(slotY)).makeGraphic(4, Std.int(slotH - 4), 0xFFFFEE00); hlBar.cameras = [uiCam]; shopUIGroup.add(hlBar);
        }
        var swX = listX + 34;
        var swBorder = new FlxSprite(swX, Std.int(slotY + 6)).makeGraphic(34, 34, isCursor ? 0xFFFFEE00 : 0xFF444444); swBorder.cameras = [uiCam]; shopUIGroup.add(swBorder);

        var swatchCol = 0xFFFFFFFF;
        if (shopCategory == 0) swatchCol = item.color; else if (shopCategory == 1) swatchCol = item.color; else if (shopCategory == 2) swatchCol = item.bg; else if (shopCategory == 3) swatchCol = 0xFFFFD700;

        var swatch = new FlxSprite(swX + 2, Std.int(slotY + 8)).makeGraphic(30, 30, swatchCol); swatch.cameras = [uiCam]; shopUIGroup.add(swatch);
        var statusStr = ""; var statusCol:Int = 0xFF888888;
        if (shopCategory == 3) { statusStr = item.realPrice; statusCol = 0xFF00FF88; }
        else {
            if (isEquipped) { statusStr = "EQUIPPED"; statusCol = 0xFF00FF88; } else if (isOwned) { statusStr = "OWNED"; statusCol = 0xFF88AAFF; } else { statusStr = item.price + "F"; statusCol = 0xFFFFD700; }
        }
        var nameCol = isCursor ? 0xFFFFFFFF : (isEquipped ? 0xFF00FF88 : (isOwned || shopCategory == 3 ? 0xFFCCCCCC : 0xFF999999));
        var nameLabel = new FlxText(swX + 44, slotY + 4, Std.int(listW * 0.5), item.name, 22); nameLabel.setFormat(Paths.font(currentFont), 22, nameCol, "left", 2, 0xFF000000); nameLabel.cameras = [uiCam]; shopTextGroup.add(nameLabel);
        var statLabel = new FlxText(swX + 44, slotY + 26, Std.int(listW * 0.5), statusStr, 14); statLabel.setFormat(Paths.font(currentFont), 14, statusCol, "left", 1, 0xFF000000); statLabel.cameras = [uiCam]; shopTextGroup.add(statLabel);
    }

    var panelX = Std.int(FlxG.width * 0.70); var panelY = Std.int(FlxG.height * 0.22); var panelW = Std.int(FlxG.width * 0.28); var panelH = Std.int(FlxG.height * 0.55);
    var prevPanelBgBase = new FlxSprite(panelX, panelY).makeGraphic(panelW, panelH, 0xFF111122); prevPanelBgBase.alpha = 0.6; prevPanelBgBase.cameras = [uiCam]; shopUIGroup.add(prevPanelBgBase);

    if (shopCategory == 2 && shopCursor < catalog.length) {
        var bgItem = catalog[shopCursor];
        var pBg = new FlxSprite(panelX + 4, panelY + 28).makeGraphic(panelW - 8, 130, bgItem.bg); pBg.cameras = [uiCam]; shopUIGroup.add(pBg);
        var pGd = new FlxSprite(panelX + 4, panelY + 148).makeGraphic(panelW - 8, 10, bgItem.ground); pGd.cameras = [uiCam]; shopUIGroup.add(pGd);
    }

    var prevTitle = new FlxText(panelX, panelY + 8, panelW, "PREVIEW", 16); prevTitle.setFormat(Paths.font(currentFont), 16, 0xFF666666, "center", 1, 0xFF000000); prevTitle.cameras = [uiCam]; shopTextGroup.add(prevTitle);

    var prevBirdX = Std.int(panelX + panelW / 2 - 32); var prevBirdY = Std.int(panelY + 50);

    var previewSkinData = getSkinData(equippedSkinId); if (shopCategory == 0 && shopCursor < catalog.length) previewSkinData = catalog[shopCursor];
    var previewTrailIdLocal = equippedTrailId; if (shopCategory == 1 && shopCursor < catalog.length) previewTrailIdLocal = catalog[shopCursor].id;
    var previewTrailData = getTrailData(previewTrailIdLocal);

    if (previewTrailIdLocal != "none") {
        var tCol = previewTrailData.color;
        for (i in 0...3) { var ts = new FlxSprite(prevBirdX - 12 - (i * 18), prevBirdY + 18).makeGraphic(14, 14, tCol); ts.alpha = 0.7 - (i * 0.2); ts.cameras = [uiCam]; shopUIGroup.add(ts); }
    }

    var pb = new FlxSprite(prevBirdX, prevBirdY).makeGraphic(64, 52, previewSkinData.color); pb.cameras = [uiCam]; shopUIGroup.add(pb);
    var pw = new FlxSprite(prevBirdX - 6, prevBirdY + 20).makeGraphic(28, 18, darkenColor(previewSkinData.color, 0.7)); pw.cameras = [uiCam]; shopUIGroup.add(pw);
    var pe = new FlxSprite(prevBirdX + 42, prevBirdY + 10).makeGraphic(16, 16, 0xFFFFFFFF); pe.cameras = [uiCam]; shopUIGroup.add(pe);
    var pep = new FlxSprite(prevBirdX + 48, prevBirdY + 14).makeGraphic(8, 8, 0xFF000000); pep.cameras = [uiCam]; shopUIGroup.add(pep);
    var pbk = new FlxSprite(prevBirdX + 58, prevBirdY + 22).makeGraphic(20, 12, 0xFFFF8800); pbk.cameras = [uiCam]; shopUIGroup.add(pbk);

    var hat1 = new FlxSprite(0,0); var hat2 = new FlxSprite(0,0);
    applyHat(previewSkinData.hat, hat1, hat2, prevBirdX, prevBirdY); hat1.cameras = [uiCam]; hat2.cameras = [uiCam]; shopUIGroup.add(hat1); shopUIGroup.add(hat2);

    if (shopCursor < catalog.length) {
        var selItem = catalog[shopCursor];
        var selName = new FlxText(panelX, prevBirdY + 80, panelW, selItem.name, 22); selName.setFormat(Paths.font(currentFont), 22, 0xFFFFFFFF, "center", 2, 0xFF000000); selName.cameras = [uiCam]; shopTextGroup.add(selName);
        var selStatus = ""; var selStatCol:Int = 0xFFFFD700;

        if (shopCategory == 3) {
            selStatus = "SUPPORT VIA KO-FI\n" + selItem.realPrice + "\nPRESS ENTER TO DONATE"; selStatCol = 0xFF00FF88;
        } else {
            var pwr = ""; if (shopCategory == 0 && previewSkinData.power != "none") pwr = "\nPOWER: " + previewSkinData.power.toUpperCase();
            if (selItem.id == equippedId) { selStatus = "EQUIPPED" + pwr; selStatCol = 0xFF00FF88; }
            else if (selItem.owned) { selStatus = "PRESS ENTER TO EQUIP" + pwr; selStatCol = 0xFF88AAFF; }
            else { selStatus = "PRESS ENTER TO BUY\n" + selItem.price + " FLOCKERS" + pwr; selStatCol = 0xFFFFD700; }
        }
        var selStat = new FlxText(panelX, prevBirdY + 110, panelW, selStatus, 14); selStat.setFormat(Paths.font(currentFont), 14, selStatCol, "center", 1, 0xFF000000); selStat.cameras = [uiCam]; shopTextGroup.add(selStat);
    }

    var instrBg = new FlxSprite(0, Std.int(FlxG.height * 0.84)).makeGraphic(FlxG.width, 30, 0xFF0D0D1A); instrBg.alpha = 0.6; instrBg.cameras = [uiCam]; shopUIGroup.add(instrBg);
    var instr = new FlxText(0, FlxG.height * 0.845, FlxG.width, "[LEFT/RIGHT] TAB   [UP/DOWN] SELECT   [ENTER] BUY/EQUIP   [ESC] BACK", 14); instr.setFormat(Paths.font(currentFont), 14, 0xFF777777, "center", 1, 0xFF000000); instr.cameras = [uiCam]; shopTextGroup.add(instr);
    statusText.text = "";
}

function shopInteract(idx:Int) {
    var catalog:Array<Dynamic>;
    if (shopCategory == 0) catalog = shopSkins; else if (shopCategory == 1) catalog = shopTrails; else if (shopCategory == 2) catalog = shopBGs; else catalog = shopPackages;

    if (idx < 0 || idx >= catalog.length) return;
    var item = catalog[idx];

    if (shopCategory == 3) {
        FlxG.openURL("https://ko-fi.com/justytccd");
        pendingPack = item;
        verifyState = "VERIFY";
        shopUIGroup.clear(); shopTextGroup.clear();
        var txt = new FlxText(0, FlxG.height * 0.4, FlxG.width, "WAITING FOR DONATION...\n\nDONATE ON KO-FI, THEN PRESS [ENTER] TO CLAIM YOUR FLOCKERS\n\nPRESS [ESC] TO CANCEL", 24);
        txt.setFormat(Paths.font(currentFont), 24, 0xFFFFFFFF, "center", 2, 0xFF000000); txt.cameras = [uiCam]; shopTextGroup.add(txt);
        return;
    }

    if (item.owned) {
        if (shopCategory == 0) equippedSkinId = item.id;
        else if (shopCategory == 1) equippedTrailId = item.id;
        else equippedBGId = item.id;
        saveShopData(); FlxG.camera.flash(0x2200FF00, 0.15); renderShop();
    } else {
        if (spendCoins(item.price)) { item.owned = true; saveShopData(); FlxG.camera.flash(0x33FFD700, 0.3); shopInteract(idx); }
        else { FlxG.camera.flash(0x33FF0000, 0.2); }
    }
}

function netOneShot(msg:String, callback:Dynamic) {
    try {
        var s = new Socket(); s.connect(new Host(SERVER_IP), SERVER_PORT); s.socket.setBlocking(false);
        new FlxTimer().start(0.5, function(t1) {
            try { s.write(msg + "\n"); } catch(e:Dynamic) {}
            new FlxTimer().start(1.5, function(t2) {
                try {
                    var d = s.read();
                    if (d != null && d.length > 0) {
                        var lines = d.split("\n"); var fl = "";
                        for (li in 0...lines.length) { var tr = StringTools.trim(lines[li]); if (tr.length > 0) { fl = tr; break; } }
                        if (fl.length > 0) callback(fl); else callback(null);
                    } else callback(null);
                } catch(e:Dynamic) { callback(null); }
                try { s.destroy(); } catch(e2:Dynamic) {}
            }, 1);
        }, 1);
    } catch(e:Dynamic) { callback(null); }
}

function update(elapsed:Float) {
    if (coinBounce > 1.0) { coinBounce = FlxMath.lerp(coinBounce, 1.0, elapsed * 8); coinText.scale.set(coinBounce, coinBounce); }
    coinIconSpin += elapsed * 6; if (coinIconText != null) coinIconText.scale.set(Math.abs(Math.cos(coinIconSpin)) * 0.6 + 0.4, 1.0);

    if (verifyState == "VERIFY") {
        if (FlxG.keys.justPressed.ENTER && pendingPack != null) {
            statusText.text = "CHECKING DONATION...";
            netOneShot("VERIFY_DONATION:" + myNickname + ":" + pendingPack.id, function(res) {
                if (res != null && res.indexOf("SUCCESS") != -1) {
                    addCoins(pendingPack.coins); FlxG.camera.flash(0x3300FF00, 0.4); pendingPack = null; verifyState = "SHOP"; renderShop();
                } else {
                    FlxG.camera.flash(0x33FF0000, 0.4); statusText.text = "VERIFICATION FAILED!";
                    new FlxTimer().start(2, function(t) { verifyState = "SHOP"; pendingPack = null; renderShop(); });
                }
            });
        }
        if (FlxG.keys.justPressed.ESCAPE) { pendingPack = null; verifyState = "SHOP"; renderShop(); }
        return;
    }

    var catalog:Array<Dynamic>;
    if (shopCategory == 0) catalog = shopSkins; else if (shopCategory == 1) catalog = shopTrails; else if (shopCategory == 2) catalog = shopBGs; else catalog = shopPackages;

    if (FlxG.keys.justPressed.UP && shopCursor > 0) { shopCursor--; renderShop(); }
    if (FlxG.keys.justPressed.DOWN && shopCursor < catalog.length - 1) { shopCursor++; renderShop(); }
    if (FlxG.keys.justPressed.LEFT) { shopCategory = (shopCategory - 1 + 4) % 4; shopCursor = 0; shopScroll = 0; renderShop(); }
    if (FlxG.keys.justPressed.RIGHT) { shopCategory = (shopCategory + 1) % 4; shopCursor = 0; shopScroll = 0; renderShop(); }
    if (FlxG.keys.justPressed.ENTER) shopInteract(shopCursor);
    if (FlxG.keys.justPressed.ESCAPE) FlxG.switchState(new ModState("CustomMainMenu"));
}
