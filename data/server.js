const net = require('net');
const fs = require('fs');

const PORT = 8080;
let rooms = {}; // Format: { "ROOM123": { players: [socket1, socket2] } }
let leaderboard = [];

// Load leaderboard on startup
if (fs.existsSync('leaderboard.json')) {
    leaderboard = JSON.parse(fs.readFileSync('leaderboard.json'));
}

function saveLeaderboard() {
    // Sort descending, keep top 10
    leaderboard.sort((a, b) => b.score - a.score);
    leaderboard = leaderboard.slice(0, 10);
    fs.writeFileSync('leaderboard.json', JSON.stringify(leaderboard));
}

const server = net.createServer((socket) => {
    console.log(`[+] Player connected: ${socket.remoteAddress}`);
    socket.setEncoding('utf8');
    socket.roomCode = null;
    socket.nickname = "Player";

    socket.on('data', (data) => {
        const msgs = data.toString().split('\n');
        for (let msg of msgs) {
            if (!msg) continue;
            const parts = msg.split(':');
            const cmd = parts[0];

            switch(cmd) {
                case "JOIN_ROOM":
                    // JOIN_ROOM:ROOM_CODE:NICKNAME
                    const code = parts[1].toUpperCase();
                    socket.nickname = parts[2] || "Unknown";
                    socket.roomCode = code;

                    if (!rooms[code]) rooms[code] = { players: [] };

                    if (rooms[code].players.length >= 2) {
                        socket.write("ROOM_FULL\n");
                        socket.roomCode = null;
                        return;
                    }

                    rooms[code].players.push(socket);
                    
                    if (rooms[code].players.length === 1) {
                        socket.write("WAITING_FOR_OPPONENT\n");
                    } else if (rooms[code].players.length === 2) {
                        const p1 = rooms[code].players[0];
                        const p2 = rooms[code].players[1];
                        
                        // Link them
                        p1.opponent = p2;
                        p2.opponent = p1;

                        const seed = Math.floor(Math.random() * 999999);
                        console.log(`[!] Room ${code} starting with seed: ${seed}`);
                        
                        p1.write(`START:${seed}:${p2.nickname}\n`);
                        p2.write(`START:${seed}:${p1.nickname}\n`);
                    }
                    break;

                case "SUBMIT_SCORE":
                    // SUBMIT_SCORE:SCORE
                    const finalScore = parseInt(parts[1]);
                    leaderboard.push({ name: socket.nickname, score: finalScore });
                    saveLeaderboard();
                    break;

                case "GET_LEADERBOARD":
                    socket.write("LEADERBOARD:" + JSON.stringify(leaderboard) + "\n");
                    break;

                // Forward gameplay events to opponent
                case "Y":
                case "JUMP":
                case "SCORE":
                case "DEAD":
                    if (socket.opponent) {
                        socket.opponent.write(msg + "\n");
                    }
                    break;
            }
        }
    });

    socket.on('close', () => {
        console.log(`[-] ${socket.nickname} disconnected`);
        if (socket.roomCode && rooms[socket.roomCode]) {
            // Remove from room array
            rooms[socket.roomCode].players = rooms[socket.roomCode].players.filter(p => p !== socket);
            // Alert opponent
            if (socket.opponent) {
                socket.opponent.write("OPPONENT_DISCONNECTED\n");
                socket.opponent.opponent = null;
            }
            // Cleanup empty rooms
            if (rooms[socket.roomCode].players.length === 0) {
                delete rooms[socket.roomCode];
            }
        }
    });

    socket.on('error', (err) => {});
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Global Lobby Server running on port ${PORT}`);
});