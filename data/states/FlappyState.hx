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
import sys.net.Host;
import funkin.backend.system.net.Socket;

var gameState:String = "WAITING"; 
var isPaused:Bool = false;
var inCountdown:Bool = false;

// Entities
var bird:FlxSprite;
var p2Bird:FlxSprite;
var pipes:FlxTypedGroup<FlxSprite>;
var powerups:FlxTypedGroup<FlxSprite>; 

// UI
var scoreText:FlxText;
var highscoreText:FlxText;
var newBestPopup:FlxText; 
var lobbyText:FlxText;
var uiCam:FlxCamera;

var pipeTimer:FlxTimer;
var shieldTimerObj:FlxTimer; 

var blurShader:CustomShader;
var cylindricalShader:CustomShader;
var sky:FlxBackdrop;

var score:Int = 0;
var pipeSpeed:Float = -300;
var gravity:Float = 1500;
var hasShield:Bool = false; 
var currentFont:String = "vcr.ttf"; 

// --- MULTIPLAYER VARIABLES ---
var isMultiplayer:Bool = false;
var isHost:Bool = false;
var mainSocket:Socket;
var connection:Socket;
var p2Score:Int = 0;
var p2Dead:Bool = false;
var iAmDead:Bool = false;
var netBuffer:String = ""; 
var connectionEstablished:Bool = false; 

function create() {
    if (FlxG.save.data.flappyHighscore == null) FlxG.save.data.flappyHighscore = 0;
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;
    else FlxG.save.data.flappyFont = "vcr.ttf"; 

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

    p2Bird = new FlxSprite(300, FlxG.height / 2).makeGraphic(45, 45, 0xFFFF0000); 
    p2Bird.antialiasing = true;
    p2Bird.alpha = 0.5; 
    p2Bird.visible = false;
    add(p2Bird);

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

    lobbyText = new FlxText(0, FlxG.height * 0.75, FlxG.width, "[SPACE] Solo   [H] Host   [J] Join", 32);
    lobbyText.setFormat(Paths.font(currentFont), 32, 0xFFFFEE00, "center", 1, 0xFF000000);
    lobbyText.cameras = [uiCam];
    add(lobbyText);
}

// --- NETWORK PROCESSING ---
function safeSend(msg:String) {
    if (connection != null && connectionEstablished) {
        try {
            connection.write(msg);
        } catch(e:Dynamic) {}
    }
}

function processNetwork() {
    if (connection == null || !connectionEstablished) return;
    try {
        var data = connection.read();
        if (data != null && data != "") {
            netBuffer += data;
            if (netBuffer.indexOf("\n") != -1) {
                var msgs = netBuffer.split("\n");
                netBuffer = msgs.pop(); // Keep partial packets in buffer
                
                for (msg in msgs) {
                    if (msg == "") continue;
                    var parts = msg.split(":");
                    switch(parts[0]) {
                        case "SEED":
                            FlxG.random.initialSeed = Std.parseInt(parts[1]);
                            startMultiplayer();
                        case "Y":
                            p2Bird.y = Std.parseFloat(parts[1]);
                        case "JUMP":
                            p2Bird.velocity.y = -500;
                        case "SCORE":
                            p2Score = Std.parseInt(parts[1]);
                            updateScoreUI();
                        case "DEAD":
                            p2Dead = true;
                            p2Bird.velocity.x = pipeSpeed; 
                            p2Bird.acceleration.y = gravity;
                            FlxG.sound.play(Paths.sound("death_sfx"), 0.5);
                    }
                }
            }
        }
    } catch(e:Dynamic) {
        // In non-blocking mode, reading an empty socket throws an error. We just ignore it.
    }
}

function updateScoreUI() {
    var displayScore = Math.floor(score / 2);
    var p2Display = Math.floor(p2Score / 2);
    
    if (isMultiplayer) scoreText.text = "YOU: " + displayScore + " | P2: " + p2Display;
    else scoreText.text = Std.string(displayScore);
    
    if (displayScore > FlxG.save.data.flappyHighscore) {
        if (newBestPopup.alpha == 0) {
            FlxG.sound.play(Paths.sound("confirmMenu"), 1.0);
            FlxG.camera.flash(0x44FFFFFF, 0.5);
        }
        highscoreText.text = "BEST: " + displayScore;
        newBestPopup.alpha = 1; 
    }
}

function killMe() {
    if (iAmDead) return;
    iAmDead = true;
    bird.velocity.x = pipeSpeed; 
    bird.acceleration.y = gravity; 
    FlxG.sound.play(Paths.sound("death_sfx")); 
    
    if (isMultiplayer) {
        safeSend("DEAD\n");
        var deadTxt = new FlxText(0, FlxG.height * 0.2, FlxG.width, "YOU DIED! SPECTATING P2...", 32);
        deadTxt.setFormat(Paths.font(currentFont), 32, 0xFFFF0000, "center", 1, 0xFF000000);
        deadTxt.cameras = [uiCam];
        add(deadTxt);
    }
}

function update(elapsed:Float) {
    if (newBestPopup != null && newBestPopup.alpha > 0) {
        var pulse = 1 + (Math.sin(FlxG.game.ticks / 200) * 0.1);
        newBestPopup.scale.set(pulse, pulse);
    }

    switch (gameState) {
        case "WAITING":
            bird.y = (FlxG.height / 2) + (Math.sin(FlxG.game.ticks / 500) * 25);
            if (FlxG.keys.justPressed.SPACE) {
                startGame();
            } else if (FlxG.keys.justPressed.H) {
                lobbyText.text = "HOSTING ON 8080... WAITING FOR P2";
                gameState = "HOSTING";
                
                try {
                    mainSocket = new Socket();
                    mainSocket.socket.bind(new Host("0.0.0.0"), 8080);
                    mainSocket.socket.listen(1);
                    mainSocket.socket.setBlocking(false); // Make it non-blocking immediately
                } catch(e:Dynamic) {}

            } else if (FlxG.keys.justPressed.J) {
                lobbyText.text = "CONNECTING TO HOST...";
                gameState = "JOINING";
                
                try {
                    connection = new Socket();
                    connection.connect(new Host("127.0.0.1"), 8080);
                    connection.socket.setBlocking(false);
                    connectionEstablished = true;
                    
                    lobbyText.text = "CONNECTED! WAITING FOR HOST...";
                    isMultiplayer = true;
                    isHost = false;
                    gameState = "WAITING_FOR_SEED";
                } catch(e:Dynamic) {
                    lobbyText.text = "CONNECTION FAILED! [H] HOST / [J] JOIN";
                    gameState = "WAITING";
                }
            }

        case "HOSTING":
            bird.y = (FlxG.height / 2) + (Math.sin(FlxG.game.ticks / 500) * 25);
            // Poll for a connection every frame. Fails silently if no one is connecting yet.
            try {
                var rawSocket = mainSocket.socket.accept();
                if (rawSocket != null) {
                    connection = new Socket(rawSocket);
                    connection.socket.setBlocking(false);
                    connectionEstablished = true;
                    
                    lobbyText.text = "PLAYER 2 JOINED! STARTING...";
                    isMultiplayer = true;
                    isHost = true;
                    gameState = "WAITING_FOR_SEED";
                    
                    var seed = FlxG.random.int(0, 999999);
                    FlxG.random.initialSeed = seed;
                    safeSend("SEED:" + seed + "\n");
                    startMultiplayer();
                }
            } catch(e:Dynamic) {}

        case "WAITING_FOR_SEED":
            bird.y = (FlxG.height / 2) + (Math.sin(FlxG.game.ticks / 500) * 25);
            processNetwork();

        case "PLAYING":
            if (FlxG.keys.justPressed.P || FlxG.keys.justPressed.ESCAPE) {
                if (!isMultiplayer) pauseGame(); 
            }
            
            if (isMultiplayer) processNetwork();
            
            if (!isPaused && !inCountdown) {
                if (!iAmDead) {
                    if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER) {
                        bird.velocity.y = -500;
                        if (isMultiplayer) safeSend("JUMP\n");
                    }
                    bird.angle = FlxMath.lerp(bird.angle, (bird.velocity.y < 0) ? -20 : 90, elapsed * 8);

                    if (bird.y > FlxG.height || bird.y < 0) killMe();
                    if (!hasShield) FlxG.overlap(bird, pipes, function(b, p) { killMe(); });

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
                        if (isMultiplayer) safeSend("SCORE:" + score + "\n");
                    });

                    // Sync Y less frequently to prevent buffer flooding
                    if (isMultiplayer && FlxG.game.ticks % 3 == 0) safeSend("Y:" + bird.y + "\n");
                }

                if (isMultiplayer && !p2Dead) {
                    p2Bird.angle = FlxMath.lerp(p2Bird.angle, (p2Bird.velocity.y < 0) ? -20 : 90, elapsed * 8);
                }

                pipes.forEachAlive(function(p:FlxSprite) {
                    p.velocity.x = pipeSpeed;
                    if (p.x + p.width < 0) p.kill();
                    
                    if (p.ID == 0 && p.x + p.width < bird.x && !iAmDead) {
                        p.ID = 1;
                        score++;
                        if (isMultiplayer) safeSend("SCORE:" + score + "\n");
                        updateScoreUI();
                        FlxG.sound.play(Paths.sound("confirmMenu"), 0.4);
                    }
                });

                powerups.forEachAlive(function(pu:FlxSprite) {
                    pu.velocity.x = pipeSpeed;
                    if (pu.x + pu.width < 0) pu.kill();
                });
                
                if (isMultiplayer) {
                    if (iAmDead && p2Dead) gameOver();
                } else {
                    if (iAmDead) gameOver();
                }
            } else if (inCountdown && isMultiplayer) {
                processNetwork(); 
            }

        case "DEAD":
            if (FlxG.keys.justPressed.ENTER) FlxG.resetState();
            if (FlxG.keys.justPressed.BACKSPACE) FlxG.switchState(new ModState("CustomMainMenu"));
    }
}

function startGame() {
    gameState = "PLAYING";
    bird.acceleration.y = gravity;
    if (lobbyText != null) lobbyText.destroy();
    startPipeTimer();
}

function startMultiplayer() {
    if (lobbyText != null) lobbyText.destroy();
    p2Bird.visible = true;
    startCountdown(); 
}

function startCountdown() {
    inCountdown = true;
    gameState = "PLAYING";
    bird.velocity.set(0, 0);
    bird.acceleration.set(0, 0);
    if (isMultiplayer) {
        p2Bird.velocity.set(0, 0);
        p2Bird.acceleration.set(0, 0);
    }
    
    var count:Int = 3;
    var cdText:FlxText = new FlxText(0, 0, FlxG.width, "3", 128);
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
            bird.acceleration.y = gravity;
            
            if (isMultiplayer && !p2Dead) {
                p2Bird.active = true;
                p2Bird.acceleration.y = gravity;
            }
            
            pipes.active = true;
            powerups.active = true;
            sky.active = true;
            
            startPipeTimer();
            if (shieldTimerObj != null && hasShield) shieldTimerObj.active = true;
        } else {
            cdText.text = Std.string(count);
            FlxG.sound.play(Paths.sound("scrollMenu"), 0.6);
        }
    }, 3);
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
        if (v <= 0) FlxG.camera.removeShader(blurShader);
    });
    
    persistentUpdate = true;
    startCountdown();
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
    topSide.reset(FlxG.width + 15, 0); topSide.ID = 2; pipes.add(topSide);

    var topPipe = pipes.recycle(FlxSprite);
    topPipe.makeGraphic(80, Math.floor(screenPos), 0xFF00FF00);
    topPipe.reset(FlxG.width, 0); topPipe.ID = 0; pipes.add(topPipe);

    var botSide = pipes.recycle(FlxSprite);
    botSide.makeGraphic(80, Math.floor(FlxG.height - screenPos - gap), 0xFF006600); 
    botSide.reset(FlxG.width + 15, screenPos + gap); botSide.ID = 2; pipes.add(botSide);

    var bottomPipe = pipes.recycle(FlxSprite);
    bottomPipe.makeGraphic(80, Math.floor(FlxG.height - screenPos - gap), 0xFF00FF00); 
    bottomPipe.reset(FlxG.width, screenPos + gap); bottomPipe.ID = 0; pipes.add(bottomPipe);

    if (FlxG.random.bool(25)) {
        var pu = powerups.recycle(FlxSprite);
        if (FlxG.random.bool(20)) {
            pu.makeGraphic(30, 30, 0xFF00FFFF); pu.ID = 2;
        } else {
            pu.makeGraphic(30, 30, 0xFFFFD700); pu.ID = 1;
        }
        pu.reset(FlxG.width + 25, screenPos + (gap / 2) - 15);
        powerups.add(pu);
    }
}

function gameOver() {
    if (gameState == "DEAD") return;
    gameState = "DEAD";
    
    bird.velocity.set(0, 0); bird.acceleration.set(0, 0);
    if (isMultiplayer) { p2Bird.velocity.set(0, 0); p2Bird.acceleration.set(0, 0); }
    sky.velocity.x = 0;
    pipes.forEach(function(p) { p.velocity.x = 0; });
    powerups.forEach(function(pu) { pu.velocity.x = 0; });
    
    if (pipeTimer != null) pipeTimer.cancel();
    if (shieldTimerObj != null) shieldTimerObj.cancel();

    var finalScore = Math.floor(score / 2);
    if (finalScore > FlxG.save.data.flappyHighscore) {
        FlxG.save.data.flappyHighscore = finalScore;
        FlxG.save.flush();
    }

    FlxG.camera.shake(0.01, 0.2);
    FlxG.sound.play(Paths.sound("death_sfx")); 

    var resultStr = "GAME OVER\nSCORE: " + finalScore;
    if (isMultiplayer) {
        var p2Final = Math.floor(p2Score / 2);
        if (finalScore > p2Final) resultStr = "YOU WON!\n" + finalScore + " VS " + p2Final;
        else if (finalScore < p2Final) resultStr = "YOU LOST...\n" + finalScore + " VS " + p2Final;
        else resultStr = "TIE GAME!\n" + finalScore + " VS " + p2Final;
    }

    var lostText:FlxText = new FlxText(0, 0, FlxG.width, resultStr, 48);
    lostText.setFormat(Paths.font(currentFont), 48, 0xFFFF0000, "center", 1, 0xFF000000);
    lostText.screenCenter();
    lostText.y -= 50;
    lostText.cameras = [uiCam];
    add(lostText);

    var restartText:FlxText = new FlxText(0, FlxG.height - 100, FlxG.width, "[ENTER] RETRY   [BACK] MENU", 24);
    restartText.setFormat(Paths.font(currentFont), 24, 0xFFFFFFFF, "center", 1, 0xFF000000);
    restartText.cameras = [uiCam];
    add(restartText);
}

function destroy() {
    if (uiCam != null && FlxG.cameras.list.contains(uiCam)) FlxG.cameras.remove(uiCam);
    if (connection != null) {
        try { connection.socket.close(); } catch(e:Dynamic) {}
        connection.destroy();
    }
    if (mainSocket != null) {
        try { mainSocket.socket.close(); } catch(e:Dynamic) {}
        mainSocket.destroy();
    }
}