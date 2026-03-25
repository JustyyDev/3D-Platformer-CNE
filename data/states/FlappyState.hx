import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.group.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxEase;
import flixel.util.FlxColor;
import flixel.addons.display.FlxBackdrop;
import funkin.backend.shaders.CustomShader;
import funkin.backend.scripting.ModState;
import funkin.backend.scripting.ModSubState;

var gameState:String = "WAITING"; 
var isPaused:Bool = false;
var inCountdown:Bool = false;

var bird:FlxSprite;
var pipes:FlxTypedGroup<FlxSprite>;
var powerups:FlxTypedGroup<FlxSprite>; 
var scoreText:FlxText;
var highscoreText:FlxText;
var newBestPopup:FlxText; 
var pipeTimer:FlxTimer;
var shieldTimerObj:FlxTimer; 

var blurShader:CustomShader;
var cylindricalShader:CustomShader;
var uiCam:FlxCamera;
var sky:FlxBackdrop;

var score:Int = 0;
var pipeSpeed:Float = -300;
var gravity:Float = 1500;
var hasShield:Bool = false; 

// --- NEW: Font Variable ---
var currentFont:String = "vcr.ttf"; 

function create() {
    if (FlxG.save.data.flappyHighscore == null) FlxG.save.data.flappyHighscore = 0;

    // --- NEW: Load Custom Font ---
    if (FlxG.save.data.flappyFont != null) {
        currentFont = FlxG.save.data.flappyFont;
    } else {
        FlxG.save.data.flappyFont = "vcr.ttf"; 
    }

    blurShader = new CustomShader("blur");
    blurShader.amount = 0;

    cylindricalShader = new CustomShader("cylindrical");
    cylindricalShader.curve = 0.5;   
    cylindricalShader.zoom = 1.35;   
    FlxG.camera.addShader(cylindricalShader);

    uiCam = new FlxCamera();
    uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    sky = new FlxBackdrop(Paths.image('menus/flappy/sky'), 0x01, 0, 0);
    sky.antialiasing = true;
    sky.velocity.x = -40;
    sky.setGraphicSize(FlxG.width, FlxG.height);
    sky.updateHitbox();
    sky.y = 0; 
    add(sky);

    pipes = new FlxTypedGroup();
    add(pipes);

    powerups = new FlxTypedGroup();
    add(powerups);

    bird = new FlxSprite(300, FlxG.height / 2).makeGraphic(45, 45, 0xFFFFFF00); 
    bird.antialiasing = true;
    add(bird);

    // --- UI ELEMENTS (Updated with currentFont) ---
    scoreText = new FlxText(0, 50, FlxG.width, "0", 64);
    scoreText.setFormat(Paths.font(currentFont), 64, 0xFFFFFFFF, "center", 1, 0xFF000000);
    scoreText.cameras = [uiCam];
    add(scoreText);

    highscoreText = new FlxText(20, 20, FlxG.width, "BEST: " + FlxG.save.data.flappyHighscore, 24);
    highscoreText.setFormat(Paths.font(currentFont), 24, 0xFFFFFFFF, "left", 1, 0xFF000000);
    highscoreText.cameras = [uiCam];
    add(highscoreText);

    newBestPopup = new FlxText(20, 45, FlxG.width, "NEW BEST!", 16);
    newBestPopup.setFormat(Paths.font(currentFont), 16, 0xFFFFEE00, "left", 1, 0xFF000000);
    newBestPopup.cameras = [uiCam];
    newBestPopup.alpha = 0; 
    add(newBestPopup);

    var startHint:FlxText = new FlxText(0, FlxG.height * 0.8, FlxG.width, "PRESS SPACE TO START", 32);
    startHint.setFormat(Paths.font(currentFont), 32, 0xFFFFEE00, "center", 1, 0xFF000000);
    startHint.ID = 100; 
    startHint.cameras = [uiCam];
    add(startHint);
}

function updateScoreUI() {
    var displayScore = Math.floor(score / 2);
    scoreText.text = Std.string(displayScore);
    
    if (displayScore > FlxG.save.data.flappyHighscore) {
        if (newBestPopup.alpha == 0) {
            FlxG.sound.play(Paths.sound("confirmMenu"), 1.0);
            FlxG.camera.flash(0x44FFFFFF, 0.5);
        }
        highscoreText.text = "BEST: " + displayScore;
        newBestPopup.alpha = 1; 
    }
}

function update(elapsed:Float) {
    if (newBestPopup != null && newBestPopup.alpha > 0) {
        var pulse:Float = 1 + (Math.sin(FlxG.game.ticks / 200) * 0.1);
        newBestPopup.scale.set(pulse, pulse);
    }

    switch (gameState) {
        case "WAITING":
            bird.y = (FlxG.height / 2) + (Math.sin(FlxG.game.ticks / 500) * 25);
            if (FlxG.keys.justPressed.SPACE) startGame();

        case "PLAYING":
            if (FlxG.keys.justPressed.P || FlxG.keys.justPressed.ESCAPE) pauseGame();
            
            if (!isPaused && !inCountdown) {
                if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER) bird.velocity.y = -500;

                bird.angle = FlxMath.lerp(bird.angle, (bird.velocity.y < 0) ? -20 : 90, elapsed * 8);

                if (bird.y > FlxG.height || bird.y < 0) gameOver();
                
                if (!hasShield) {
                    FlxG.overlap(bird, pipes, function(b, p) { gameOver(); });
                }

                FlxG.overlap(bird, powerups, function(b, pu) {
                    if (pu.ID == 1) {
                        score += 10;
                        FlxG.sound.play(Paths.sound("confirmMenu"), 0.5);
                    } else if (pu.ID == 2) {
                        hasShield = true;
                        bird.alpha = 0.4; 
                        FlxG.sound.play(Paths.sound("confirmMenu"), 0.7);
                        
                        if (shieldTimerObj != null) shieldTimerObj.cancel();
                        shieldTimerObj = new FlxTimer().start(4, function(tmr) {
                            hasShield = false;
                            bird.alpha = 1.0;
                        });
                    }
                    pu.kill();
                    updateScoreUI();
                });

                pipes.forEachAlive(function(p:FlxSprite) {
                    p.velocity.x = pipeSpeed;
                    if (p.x + p.width < 0) p.kill();
                    
                    if (p.ID == 0 && p.x + p.width < bird.x) {
                        p.ID = 1;
                        score++;
                        updateScoreUI();
                        FlxG.sound.play(Paths.sound("confirmMenu"), 0.4);
                    }
                });

                powerups.forEachAlive(function(pu:FlxSprite) {
                    pu.velocity.x = pipeSpeed;
                    if (pu.x + pu.width < 0) pu.kill();
                });

            } else {
                bird.velocity.set(0, 0);
                pipes.forEachAlive(function(p:FlxSprite) { p.velocity.x = 0; });
                powerups.forEachAlive(function(pu:FlxSprite) { pu.velocity.x = 0; });
            }

        case "DEAD":
            if (FlxG.keys.justPressed.ENTER) FlxG.resetState();
            if (FlxG.keys.justPressed.BACKSPACE) FlxG.switchState(new ModState("CustomMainMenu"));
    }
}

function startGame() {
    gameState = "PLAYING";
    bird.acceleration.y = gravity;
    remove(members.filter(function(m) return m.ID == 100)[0]);
    startPipeTimer();
}

function pauseGame() {
    isPaused = true;
    bird.active = false;
    pipes.active = false;
    powerups.active = false;
    pipeTimer.active = false;
    sky.active = false; 
    
    if (shieldTimerObj != null && shieldTimerObj.active) shieldTimerObj.active = false;
    
    blurShader.amount = 3.0;
    FlxG.camera.addShader(blurShader); 

    persistentUpdate = true; 
    persistentDraw = true;

    var pauseSub = new ModSubState("substates/FlappyPause");
    pauseSub.cameras = [uiCam];
    openSubState(pauseSub);
}

function onSubStateClose(sub:ModSubState) {
    FlxTween.num(3.0, 0, 0.4, {ease: FlxEase.quartOut}, function(v:Float) {
        blurShader.amount = v;
        if (v <= 0) {
             FlxG.camera.removeShader(blurShader);
        }
    });
    
    persistentUpdate = true;
    startCountdown();
}

function startCountdown() {
    inCountdown = true;
    bird.velocity.set(0, 0);
    
    var count:Int = 3;
    var cdText:FlxText = new FlxText(0, 0, FlxG.width, "3", 128);
    // Use currentFont here
    cdText.setFormat(Paths.font(currentFont), 128, 0xFFFFFFFF, "center", 1, 0xFF000000);
    cdText.screenCenter();
    cdText.cameras = [uiCam];
    add(cdText);

    new FlxTimer().start(1, function(tmr) {
        count--;
        if (count <= 0) {
            cdText.destroy();
            isPaused = false;
            inCountdown = false;
            
            bird.active = true;
            pipes.active = true;
            powerups.active = true;
            pipeTimer.active = true;
            sky.active = true;
            
            if (shieldTimerObj != null && hasShield) shieldTimerObj.active = true;
        } else {
            cdText.text = Std.string(count);
            FlxG.sound.play(Paths.sound("scrollMenu"), 0.6);
        }
    }, 3);
}

function startPipeTimer() {
    if (pipeTimer != null) pipeTimer.destroy();
    pipeTimer = new FlxTimer().start(1.5, function(tmr) {
        if (gameState == "PLAYING" && !isPaused && !inCountdown) spawnPipe();
    }, 0);
}

function spawnPipe() {
    var gap:Float = 210;
    var screenPos:Float = FlxG.random.float(100, FlxG.height - gap - 100);

    var topSide = pipes.recycle(FlxSprite);
    topSide.makeGraphic(80, Math.floor(screenPos), 0xFF006600);
    topSide.reset(FlxG.width + 15, 0); 
    topSide.ID = 2; 
    pipes.add(topSide);

    var topPipe = pipes.recycle(FlxSprite);
    topPipe.makeGraphic(80, Math.floor(screenPos), 0xFF00FF00);
    topPipe.reset(FlxG.width, 0);
    topPipe.ID = 0;
    pipes.add(topPipe);

    var botSide = pipes.recycle(FlxSprite);
    botSide.makeGraphic(80, Math.floor(FlxG.height - screenPos - gap), 0xFF006600); 
    botSide.reset(FlxG.width + 15, screenPos + gap);
    botSide.ID = 2;
    pipes.add(botSide);

    var bottomPipe = pipes.recycle(FlxSprite);
    bottomPipe.makeGraphic(80, Math.floor(FlxG.height - screenPos - gap), 0xFF00FF00); 
    bottomPipe.reset(FlxG.width, screenPos + gap);
    bottomPipe.ID = 0;
    pipes.add(bottomPipe);

    if (FlxG.random.bool(25)) {
        var pu = powerups.recycle(FlxSprite);
        var isShield = FlxG.random.bool(20); 
        
        if (isShield) {
            pu.makeGraphic(30, 30, 0xFF00FFFF); 
            pu.ID = 2;
        } else {
            pu.makeGraphic(30, 30, 0xFFFFD700); 
            pu.ID = 1;
        }
        
        pu.reset(FlxG.width + 25, screenPos + (gap / 2) - 15);
        powerups.add(pu);
    }
}

function gameOver() {
    if (gameState == "DEAD") return;
    gameState = "DEAD";
    
    bird.velocity.set(0, 0);
    bird.acceleration.set(0, 0);
    sky.velocity.x = 0;
    
    pipes.forEach(function(p) { p.velocity.x = 0; });
    powerups.forEach(function(pu) { pu.velocity.x = 0; });
    
    if (pipeTimer != null) pipeTimer.cancel();
    if (shieldTimerObj != null) shieldTimerObj.cancel();

    var finalScore = Math.floor(score / 2);
    
    var medal:String = "NONE";
    var medalColor:Int = 0xFFFFFFFF;
    if (finalScore >= 50) { medal = "GOLD"; medalColor = 0xFFFFD700; }
    else if (finalScore >= 25) { medal = "SILVER"; medalColor = 0xFFC0C0C0; }
    else if (finalScore >= 10) { medal = "BRONZE"; medalColor = 0xFFCD7F32; }

    if (finalScore > FlxG.save.data.flappyHighscore) {
        FlxG.save.data.flappyHighscore = finalScore;
        FlxG.save.flush();
    }

    FlxG.camera.shake(0.01, 0.2);
    FlxG.sound.play(Paths.sound("death_sfx")); 

    var lostText:FlxText = new FlxText(0, 0, FlxG.width, "GAME OVER\nSCORE: " + finalScore, 48);
    // Use currentFont here
    lostText.setFormat(Paths.font(currentFont), 48, 0xFFFF0000, "center", 1, 0xFF000000);
    lostText.screenCenter();
    lostText.y -= 50;
    lostText.cameras = [uiCam];
    add(lostText);

    if (medal != "NONE") {
        var medalText:FlxText = new FlxText(0, lostText.y + 110, FlxG.width, medal + " MEDAL UNLOCKED", 24);
        // Use currentFont here
        medalText.setFormat(Paths.font(currentFont), 24, medalColor, "center", 1, 0xFF000000);
        medalText.cameras = [uiCam];
        add(medalText);
    }

    var restartText:FlxText = new FlxText(0, FlxG.height - 100, FlxG.width, "[ENTER] RETRY   [BACK] MENU", 24);
    // Use currentFont here
    restartText.setFormat(Paths.font(currentFont), 24, 0xFFFFFFFF, "center", 1, 0xFF000000);
    restartText.cameras = [uiCam];
    add(restartText);
}

function destroy() {
    if (uiCam != null && FlxG.cameras.list.contains(uiCam)) {
        FlxG.cameras.remove(uiCam);
    }
}