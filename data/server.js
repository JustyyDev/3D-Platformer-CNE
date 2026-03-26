const net = require('net');
const fs = require('fs');

const PORT = 8080;
const ADMIN_KEY = process.env.ADMIN_KEY || 'changeme';
const MAX_NICK_LEN = 12;
const MAX_ROOM_CODE_LEN = 4;
let rooms = {}; 
let leaderboard = [];

function sanitize(str, maxLen) {
    return str.replace(/[^A-Za-z0-9 _-]/g, '').substring(0, maxLen);
}

if (fs.existsSync('leaderboard.json')) {
    try { leaderboard = JSON.parse(fs.readFileSync('leaderboard.json')); } catch (e) { leaderboard = []; }
}

function saveLeaderboard() {
    leaderboard.sort((a, b) => b.score - a.score);
    leaderboard = leaderboard.slice(0, 10);
    fs.writeFileSync('leaderboard.json', JSON.stringify(leaderboard));
}

const server = net.createServer((socket) => {
    console.log(`[CONN] New connection from ${socket.remoteAddress}:${socket.remotePort}`);
    socket.setEncoding('utf8');
    socket.nickname = "Guest";
    socket.roomCode = null;

    socket.on('data', (data) => {
        const msgs = data.toString().split('\n');
        for (let msg of msgs) {
            msg = msg.replace(/\\n/g, '\n').trim();
            if (!msg) continue;
            const parts = msg.split(':');
            const cmd = parts[0];

            switch(cmd) {
                case "JOIN_ROOM":
                    const code = sanitize(parts[1] || "0000", MAX_ROOM_CODE_LEN).toUpperCase();
                    socket.nickname = sanitize(parts[2] || "Player", MAX_NICK_LEN);
                    if (!code || !socket.nickname) break;
                    socket.roomCode = code;

                    if (!rooms[code]) {
                        rooms[code] = { players: [], gameStarted: false, seed: Math.floor(Math.random() * 999999) };
                    }
                    
                    if (rooms[code].players.length >= 6) {
                        socket.write("ROOM_FULL\n");
                        break;
                    }

                    rooms[code].players.push(socket);
                    console.log(`[LOBBY] ${socket.nickname} joined room ${code} (${rooms[code].players.length}/6)`);

                    broadcastToRoom(code, `CHAT:${socket.nickname} JOINED THE BATTLE!`);

                    if (rooms[code].gameStarted) socket.write("GAME_ALREADY_STARTED\n");
                    else socket.write("WAITING_FOR_HOST\n");
                    break;

                case "START_GAME":
                    if (socket.roomCode && rooms[socket.roomCode]) {
                        rooms[socket.roomCode].gameStarted = true;
                        broadcastToRoom(socket.roomCode, `START:${rooms[socket.roomCode].seed}:${socket.nickname}`);
                        console.log(`[GAME] Room ${socket.roomCode} has started.`);
                    }
                    break;

                case "NUKE_SERVER":
                    if (parts[1] !== ADMIN_KEY) {
                        console.log(`[!] UNAUTHORIZED NUKE ATTEMPT BY ${socket.nickname}`);
                        break;
                    }
                    console.log(`[!] NUCLEAR RESET BY ${socket.nickname}`);
                    broadcastToRoom(socket.roomCode, "CHAT:SERVER REBOOTING BY ADMIN...");
                    setTimeout(() => { process.exit(0); }, 500);
                    break;

                case "GET_STATUS":
                    let total = 0;
                    for (let r in rooms) total += rooms[r].players.length;
                    socket.write(`STATUS:${total}:${Object.keys(rooms).length}\n`);
                    break;

                case "SUBMIT_SCORE":
                    var submitted = parseInt(parts[1]) || 0;
                    if (submitted < 0 || submitted > 99999) break;
                    leaderboard.push({ name: socket.nickname, score: submitted });
                    saveLeaderboard();
                    break;

                case "GET_LEADERBOARD":
                    socket.write("LEADERBOARD:" + JSON.stringify(leaderboard) + "\n");
                    break;

                default: 
                    if (socket.roomCode && rooms[socket.roomCode]) {
                        broadcastToRoom(socket.roomCode, `${msg}:${socket.nickname}`, socket);
                    }
                    break;
            }
        }
    });

    socket.on('error', (err) => { /* Ignore dropped connections to prevent crashes */ });

    socket.on('close', () => {
        if (socket.roomCode && rooms[socket.roomCode]) {
            console.log(`[LEAVE] ${socket.nickname} left room ${socket.roomCode}`);
            rooms[socket.roomCode].players = rooms[socket.roomCode].players.filter(p => p !== socket);
            broadcastToRoom(socket.roomCode, `CHAT:${socket.nickname} DISCONNECTED`);
            broadcastToRoom(socket.roomCode, `DEAD:${socket.nickname}`);
            if (rooms[socket.roomCode].players.length === 0) delete rooms[socket.roomCode];
        }
    });
});

function broadcastToRoom(roomCode, message, excludeSocket = null) {
    if (!rooms[roomCode]) return;
    rooms[roomCode].players.forEach((client) => {
        if (client !== excludeSocket && !client.destroyed && client.writable) {
            client.write(message.replace(/\n/g, '\\n') + "\n");
        }
    });
}

server.listen(PORT, '0.0.0.0', () => {
    console.log("-----------------------------------------");
    console.log(`BATTLE ROYALE SERVER LIVE ON PORT ${PORT}`);
    console.log("-----------------------------------------");
});