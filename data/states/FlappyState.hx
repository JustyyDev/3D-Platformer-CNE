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

// States: NICKNAME, MENU, ROOM_INPUT, LEADERBOARD, CONNECTING, WAITING_FOR_OPPONENT, PLAYING, DEAD
var gameState:String = "NICKNAME"; 
var isPaused:Bool = false;
var inCountdown:Bool = false;

// Entities
var bird:FlxSprite;
var p2Bird:FlxSprite;
var pipes:FlxTypedGroup<FlxSprite>;
var powerups:FlxTypedGroup<FlxSprite>; 

// UI
var titleText:FlxText;
var scoreText:FlxText;
var lobbyText:FlxText;
var typingText:FlxText;
var leaderboardGroup:FlxTypedGroup<FlxText>;
var uiCam:FlxCamera;

var pipeTimer:FlxTimer;
var shieldTimerObj:FlxTimer; 

var sky:FlxBackdrop;
var score:Int = 0;
var pipeSpeed:Float = -300;
var gravity:Float = 1500;
var hasShield:Bool = false; 
var currentFont:String = "vcr.ttf"; 

// --- MULTIPLAYER VARIABLES ---
var SERVER_IP:String = "144.21.35.78"; 
var isMultiplayer:Bool = false;
var connection:Socket;
var p2Score:Int = 0;
var p2Dead:Bool = false;
var iAmDead:Bool = false;
var netBuffer:String = ""; 
var connectionEstablished:Bool = false; 

// --- LOBBY VARIABLES ---
var myNickname:String = "";
var typedInput:String = "";
var opponentName:String = "P2";

function create() {
    if (FlxG.save.data.flappyFont != null) currentFont = FlxG.save.data.flappyFont;
    
    uiCam = new FlxCamera();
    uiCam.bgColor = 0x00000000;
    FlxG.cameras.add(uiCam, false);

    sky = new FlxBackdrop(Paths.image('menus/flappy/sky'), 0x01, 0, 0);
    sky.antialiasing = true; sky.velocity.x = -40;
    sky.setGraphicSize(FlxG.width, FlxG.height); sky.updateHitbox();
    add(sky);

    pipes = new FlxTypedGroup(); add(pipes);
    powerups = new FlxTypedGroup(); add(powerups);
    leaderboardGroup = new FlxTypedGroup(); add(leaderboardGroup);

    bird = new FlxSprite(300, FlxG.height / 2).makeGraphic(45, 45, 0xFFFFFF00); add(bird);
    p2Bird = new FlxSprite(300, FlxG.height / 2).makeGraphic(45, 45, 0xFFFF0000); 
    p2Bird.alpha = 0.5; p2Bird.visible = false; add(p2Bird);

    titleText = new FlxText(0, FlxG.height * 0.15, FlxG.width, "FLAPPY BIRD", 96);
    titleText.setFormat(Paths.font(currentFont), 96, 0xFFFFFFFF, "center", 2, 0xFF000000);
    titleText.cameras = [uiCam]; add(titleText);

    scoreText = new FlxText(0, 50, FlxG.width, "0", 64);
    scoreText.setFormat(Paths.font(currentFont), 64, 0xFFFFFFFF, "center", 2, 0xFF000000);
    scoreText.cameras = [uiCam]; scoreText.visible = false; add(scoreText);

    lobbyText = new FlxText(0, FlxG.height * 0.6, FlxG.width, "", 32);
    lobbyText.setFormat(Paths.font(currentFont), 32, 0xFFFFEE00, "center", 2, 0xFF000000);
    lobbyText.cameras = [uiCam]; add(lobbyText);

    typingText = new FlxText(0, FlxG.height * 0.75, FlxG.width, "", 48);
    typingText.setFormat(Paths.font(currentFont), 48, 0xFFFFFFFF, "center", 2, 0xFF000000);
    typingText.cameras = [uiCam]; add(typingText);

    // Check if player already has a nickname saved
    if (FlxG.save.data.flappyNickname != null && FlxG.save.data.flappyNickname != "") {
        myNickname = FlxG.save.data.flappyNickname;
        switchState("MENU");
    } else {
        switchState("NICKNAME");
    }
}

function switchState(newState:String) {
    gameState = newState;
    typedInput = "";
    typingText.text = "";
    leaderboardGroup.clear();
    
    switch(newState) {
        case "NICKNAME":
            lobbyText.text = "ENTER YOUR NICKNAME:\n(Press ENTER to confirm)";
        case "MENU":
            lobbyText.text = "WELCOME, " + myNickname + "!\n\n[1] Play Solo\n[2] Join/Create Room\n[3] Global Leaderboard";
        case "ROOM_INPUT":
            lobbyText.text = "ENTER 4-LETTER ROOM CODE:\n(Press ENTER to join)";
        case "LEADERBOARD":
            lobbyText.text = "CONNECTING TO LEADERBOARD...";
            fetchLeaderboard();
    }
}

// --- NETWORK PROCESSING ---
function safeSend(msg:String) {
    if (connection != null && connectionEstablished) try { connection.write(msg); } catch(e:Dynamic) {}
}

function fetchLeaderboard() {
    try {
        connection = new Socket();
        connection.connect(new Host(SERVER_IP), 8080);
        connection.socket.setBlocking(false);
        connectionEstablished = true;
        safeSend("GET_LEADERBOARD\n");
    } catch(e:Dynamic) {
        lobbyText.text = "SERVER OFFLINE! Press [BACKSPACE] to return.";
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
                netBuffer = msgs.pop(); 
                
                for (msg in msgs) {
                    if (msg == "") continue;
                    var parts = msg.split(":");
                    switch(parts[0]) {
                        case "START": // START:SEED:OPPONENT_NAME
                            FlxG.random.initialSeed = Std.parseInt(parts[1]);
                            opponentName = parts[2];
                            startMultiplayer();
                        case "ROOM_FULL":
                            lobbyText.text = "ROOM IS FULL!\nPress [BACKSPACE] to return.";
                            gameState = "MENU";
                        case "LEADERBOARD":
                            lobbyText.text = "GLOBAL TOP 10\n[BACKSPACE] to return";
                            var jsonStr = msg.substring(12); // Remove "LEADERBOARD:"
                            var board:Array<Dynamic> = haxe.Json.parse(jsonStr);
                            var startY = FlxG.height * 0.3;
                            for (i in 0...board.length) {
                                var entry = new FlxText(0, startY + (i * 30), FlxG.width, (i+1) + ". " + board[i].name + " - " + board[i].score, 24);
                                entry.setFormat(Paths.font(currentFont), 24, 0xFFFFFFFF, "center", 2, 0xFF000000);
                                entry.cameras = [uiCam];
                                leaderboardGroup.add(entry);
                            }
                        case "Y": p2Bird.y = Std.parseFloat(parts[1]);
                        case "JUMP": p2Bird.velocity.y = -500;
                        case "SCORE": 
                            p2Score = Std.parseInt(parts[1]);
                            updateScoreUI();
                        case "DEAD":
                            p2Dead = true;
                            p2Bird.velocity.x = pipeSpeed; p2Bird.acceleration.y = gravity;
                            FlxG.sound.play(Paths.sound("death_sfx"), 0.5);
                        case "OPPONENT_DISCONNECTED":
                            if (!iAmDead && !p2Dead && gameState == "PLAYING") {
                                p2Dead = true; p2Bird.visible = false;
                                lobbyText.text = opponentName + " LEFT! YOU WIN!";
                                lobbyText.color = 0xFF00FF00;
                                lobbyText.cameras = [uiCam]; add(lobbyText);
                                gameOver();
                            }
                    }
                }
            }
        }
    } catch(e:Dynamic) {}
}

function handleTyping(maxLength:Int) {
    if (FlxG.keys.justPressed.BACKSPACE && typedInput.length > 0) {
        typedInput = typedInput.substring(0, typedInput.length - 1);
        FlxG.sound.play(Paths.sound("scrollMenu"), 0.5);
    } else if (FlxG.keys.justPressed.SPACE && typedInput.length < maxLength && gameState == "NICKNAME") {
        typedInput += " ";
        FlxG.sound.play(Paths.sound("scrollMenu"), 0.5);
    } else if (typedInput.length < maxLength) {
        var key = FlxG.keys.firstJustPressed();
        
        // Use basic string slicing to bypass the HScript sandbox!
        var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        var numbers = "0123456789";

        // A-Z is keycodes 65 to 90
        if (key >= 65 && key <= 90) { 
            typedInput += letters.charAt(key - 65);
            FlxG.sound.play(Paths.sound("scrollMenu"), 0.5);
        } 
        // 0-9 is keycodes 48 to 57
        else if (key >= 48 && key <= 57) { 
            typedInput += numbers.charAt(key - 48);
            FlxG.sound.play(Paths.sound("scrollMenu"), 0.5);
        }
    }
    typingText.text = "> " + typedInput + (FlxG.game.ticks % 60 > 30 ? "_" : "");
}

function updateScoreUI() {
    var displayScore = Math.floor(score / 2);
    if (isMultiplayer) scoreText.text = myNickname + ": " + displayScore + " | " + opponentName + ": " + Math.floor(p2Score / 2);
    else scoreText.text = Std.string(displayScore);
}

function killMe() {
    if (iAmDead) return;
    iAmDead = true;
    bird.velocity.x = pipeSpeed; bird.acceleration.y = gravity; 
    FlxG.sound.play(Paths.sound("death_sfx")); 
    
    if (isMultiplayer) {
        safeSend("DEAD\n");
        safeSend("SUBMIT_SCORE:" + Math.floor(score / 2) + "\n");
        var deadTxt = new FlxText(0, FlxG.height * 0.2, FlxG.width, "YOU DIED! SPECTATING...", 32);
        deadTxt.setFormat(Paths.font(currentFont), 32, 0xFFFF0000, "center", 2, 0xFF000000);
        deadTxt.cameras = [uiCam]; add(deadTxt);
    }
}

function update(elapsed:Float) {
    if (gameState != "PLAYING" && gameState != "DEAD") {
        bird.y = (FlxG.height / 2) + (Math.sin(FlxG.game.ticks / 500) * 25);
    }

    switch (gameState) {
                case "NICKNAME":
                    handleTyping(12);
                    // Removed .trim() here!
                    if (FlxG.keys.justPressed.ENTER && typedInput.length > 0) {
                        myNickname = typedInput; // Removed .trim() here too!
                        FlxG.save.data.flappyNickname = myNickname;
                        FlxG.save.flush();
                        FlxG.sound.play(Paths.sound("confirmMenu"));
                        switchState("MENU");
                    }

                case "MENU":
                    if (FlxG.keys.justPressed.ONE) {
                        startGame();
                    } else if (FlxG.keys.justPressed.TWO) {
                        switchState("ROOM_INPUT");
                    } else if (FlxG.keys.justPressed.THREE) {
                        switchState("LEADERBOARD");
                    } else if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE) {
                        FlxG.switchState(new ModState("CustomMainMenu"));
                    }

                case "ROOM_INPUT":
                    handleTyping(6); 
                    // Removed .trim() here!
                    if (FlxG.keys.justPressed.ENTER && typedInput.length > 0) {
                        lobbyText.text = "CONNECTING TO SERVER...";
                        typingText.text = "";
                        gameState = "CONNECTING";
                        
                        try {
                            connection = new Socket();
                            connection.connect(new Host(SERVER_IP), 8080);
                            connection.socket.setBlocking(false);
                            connectionEstablished = true;
                            isMultiplayer = true;
                            
                            // Removed .trim() here too!
                            safeSend("JOIN_ROOM:" + typedInput + ":" + myNickname + "\n");
                            gameState = "WAITING_FOR_OPPONENT";
                        } catch(e:Dynamic) {
                            lobbyText.text = "SERVER OFFLINE! [BACKSPACE] TO RETURN";
                            gameState = "ROOM_INPUT";
                        }
                    }
                    if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE) switchState("MENU");
        case "WAITING_FOR_OPPONENT":
            processNetwork();
            lobbyText.alpha = 0.5 + (Math.sin(FlxG.game.ticks / 300) * 0.5);
            if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE) {
                if (connection != null) connection.destroy();
                switchState("MENU");
            }

        case "LEADERBOARD":
            processNetwork();
            if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE) {
                if (connection != null) connection.destroy();
                switchState("MENU");
            }

        case "PLAYING":
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
                        if (pu.ID == 1) score += 10;
                        else if (pu.ID == 2) {
                            hasShield = true; bird.alpha = 0.4; 
                            if (shieldTimerObj != null) shieldTimerObj.cancel();
                            shieldTimerObj = new FlxTimer().start(4, function(tmr) { hasShield = false; bird.alpha = 1.0; });
                        }
                        pu.kill(); FlxG.sound.play(Paths.sound("confirmMenu"), 0.6);
                        updateScoreUI();
                        if (isMultiplayer) safeSend("SCORE:" + score + "\n");
                    });

                    if (isMultiplayer && FlxG.game.ticks % 3 == 0) safeSend("Y:" + bird.y + "\n");
                }

                if (isMultiplayer && !p2Dead) p2Bird.angle = FlxMath.lerp(p2Bird.angle, (p2Bird.velocity.y < 0) ? -20 : 90, elapsed * 8);

                pipes.forEachAlive(function(p:FlxSprite) {
                    p.velocity.x = pipeSpeed;
                    if (p.x + p.width < 0) p.kill();
                    if (p.ID == 0 && p.x + p.width < bird.x && !iAmDead) {
                        p.ID = 1; score++; updateScoreUI(); FlxG.sound.play(Paths.sound("confirmMenu"), 0.4);
                        if (isMultiplayer) safeSend("SCORE:" + score + "\n");
                    }
                });

                powerups.forEachAlive(function(pu:FlxSprite) { pu.velocity.x = pipeSpeed; if (pu.x + pu.width < 0) pu.kill(); });
                
                if (isMultiplayer && iAmDead && p2Dead) gameOver();
                else if (!isMultiplayer && iAmDead) gameOver();
                
            } else if (inCountdown && isMultiplayer) {
                processNetwork(); 
            }

        case "DEAD":
            if (FlxG.keys.justPressed.ENTER) FlxG.resetState();
            if (FlxG.keys.justPressed.BACKSPACE) FlxG.switchState(new ModState("CustomMainMenu"));
    }
}

function startGame() {
    gameState = "PLAYING"; bird.acceleration.y = gravity;
    if (lobbyText != null) lobbyText.destroy();
    if (typingText != null) typingText.destroy();
    if (titleText != null) FlxTween.tween(titleText, {y: -200, alpha: 0}, 0.5, {ease: FlxEase.quartIn});
    scoreText.visible = true; startPipeTimer();
}

function startMultiplayer() {
    if (lobbyText != null) lobbyText.destroy();
    if (typingText != null) typingText.destroy();
    if (titleText != null) FlxTween.tween(titleText, {y: -200, alpha: 0}, 0.5, {ease: FlxEase.quartIn});
    scoreText.visible = true; p2Bird.visible = true;
    startCountdown(); 
}

function startCountdown() {
    inCountdown = true; gameState = "PLAYING";
    bird.velocity.set(0, 0); bird.acceleration.set(0, 0);
    if (isMultiplayer) { p2Bird.velocity.set(0, 0); p2Bird.acceleration.set(0, 0); }
    
    var count:Int = 3;
    var cdText:FlxText = new FlxText(0, 0, FlxG.width, "3", 128);
    cdText.setFormat(Paths.font(currentFont), 128, 0xFFFFFFFF, "center", 2, 0xFF000000);
    cdText.screenCenter(); cdText.cameras = [uiCam]; add(cdText);

    new FlxTimer().start(1, function(tmr) {
        count--;
        if (count <= 0) {
            cdText.destroy(); inCountdown = false;
            bird.active = true; bird.acceleration.y = gravity;
            if (isMultiplayer && !p2Dead) { p2Bird.active = true; p2Bird.acceleration.y = gravity; }
            startPipeTimer();
        } else {
            cdText.text = Std.string(count); FlxG.sound.play(Paths.sound("scrollMenu"), 0.6);
        }
    }, 3);
}

function startPipeTimer() {
    pipeTimer = new FlxTimer().start(1.5, function(tmr) { if (gameState == "PLAYING" && !inCountdown) spawnPipe(); }, 0);
}

function spawnPipe() {
    var gap:Float = 210; var screenPos:Float = FlxG.random.float(100, FlxG.height - gap - 100);

    var tS = pipes.recycle(FlxSprite); tS.makeGraphic(80, Math.floor(screenPos), 0xFF006600); tS.reset(FlxG.width+15, 0); tS.ID=2; pipes.add(tS);
    var tP = pipes.recycle(FlxSprite); tP.makeGraphic(80, Math.floor(screenPos), 0xFF00FF00); tP.reset(FlxG.width, 0); tP.ID=0; pipes.add(tP);
    var bS = pipes.recycle(FlxSprite); bS.makeGraphic(80, Math.floor(FlxG.height-screenPos-gap), 0xFF006600); bS.reset(FlxG.width+15, screenPos+gap); bS.ID=2; pipes.add(bS);
    var bP = pipes.recycle(FlxSprite); bP.makeGraphic(80, Math.floor(FlxG.height-screenPos-gap), 0xFF00FF00); bP.reset(FlxG.width, screenPos+gap); bP.ID=0; pipes.add(bP);
}

function gameOver() {
    if (gameState == "DEAD") return;
    gameState = "DEAD";
    bird.velocity.set(0, 0); bird.acceleration.set(0, 0);
    if (isMultiplayer) { p2Bird.velocity.set(0, 0); p2Bird.acceleration.set(0, 0); }
    sky.velocity.x = 0; pipes.forEach(function(p) { p.velocity.x = 0; });
    if (pipeTimer != null) pipeTimer.cancel();
    
    var finalScore = Math.floor(score / 2);
    if (!isMultiplayer) safeSend("SUBMIT_SCORE:" + finalScore + "\n"); // Submit solo scores too!

    var resultStr = "GAME OVER\nSCORE: " + finalScore;
    if (isMultiplayer) {
        var p2Final = Math.floor(p2Score / 2);
        if (finalScore > p2Final) resultStr = "YOU WON!\n" + finalScore + " VS " + p2Final;
        else if (finalScore < p2Final) resultStr = "YOU LOST...\n" + finalScore + " VS " + p2Final;
        else resultStr = "TIE GAME!\n" + finalScore + " VS " + p2Final;
    }

    var lostText = new FlxText(0, 0, FlxG.width, resultStr, 48);
    lostText.setFormat(Paths.font(currentFont), 48, 0xFFFFFFFF, "center", 2, 0xFF000000);
    lostText.screenCenter(); lostText.y -= 50; lostText.cameras = [uiCam]; add(lostText);
}

function destroy() {
    if (uiCam != null && FlxG.cameras.list.contains(uiCam)) FlxG.cameras.remove(uiCam);
    if (connection != null) { try { connection.socket.close(); } catch(e:Dynamic) {} connection.destroy(); }
}