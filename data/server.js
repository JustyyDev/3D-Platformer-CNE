const net = require('net');
const fs = require('fs');

const PORT = 8080;
let rooms = {}; 
let leaderboard = [];

if (fs.existsSync('leaderboard.json')) {
    leaderboard = JSON.parse(fs.readFileSync('leaderboard.json'));
}

function saveLeaderboard() {
    leaderboard.sort((a, b) => b.score - a.score);
    leaderboard = leaderboard.slice(0, 10);
    fs.writeFileSync('leaderboard.json', JSON.stringify(leaderboard));
}

const server = net.createServer((socket) => {
    socket.setEncoding('utf8');
    socket.nickname = "Guest";

    socket.on('data', (data) => {
        const msgs = data.toString().split('\n');
        for (let msg of msgs) {
            if (!msg) continue;
            const parts = msg.split(':');
            const cmd = parts[0];

            switch(cmd) {
                case "JOIN_ROOM":
                    const code = parts[1].toUpperCase();
                    socket.nickname = parts[2] || "Player";
                    socket.roomCode = code;
                    if (!rooms[code]) rooms[code] = { players: [] };
                    if (rooms[code].players.length >= 2) {
                        socket.write("ROOM_FULL\n");
                        return;
                    }
                    rooms[code].players.push(socket);
                    if (rooms[code].players.length === 2) {
                        const p1 = rooms[code].players[0];
                        const p2 = rooms[code].players[1];
                        p1.opponent = p2; p2.opponent = p1;
                        const seed = Math.floor(Math.random() * 999999);
                        p1.write(`START:${seed}:${p2.nickname}\n`);
                        p2.write(`START:${seed}:${p1.nickname}\n`);
                    } else {
                        socket.write("WAITING_FOR_OPPONENT\n");
                    }
                    break;

                case "GET_STATUS":
                    let total = 0;
                    for (let r in rooms) total += rooms[r].players.length;
                    socket.write(`STATUS:${total}:${Object.keys(rooms).length}\n`);
                    break;

                case "BOOSTER": 
                    // Format: BOOSTER:TYPE:X:Y
                    if (socket.opponent) socket.opponent.write(msg + "\n");
                    break;

                case "SUBMIT_SCORE":
                    leaderboard.push({ name: socket.nickname, score: parseInt(parts[1]) });
                    saveLeaderboard();
                    break;

                case "GET_LEADERBOARD":
                    socket.write("LEADERBOARD:" + JSON.stringify(leaderboard) + "\n");
                    break;

                default: // Forward Y, JUMP, SCORE, DEAD
                    if (socket.opponent) socket.opponent.write(msg + "\n");
                    break;
            }
        }
    });

    socket.on('close', () => {
        if (socket.roomCode && rooms[socket.roomCode]) {
            rooms[socket.roomCode].players = rooms[socket.roomCode].players.filter(p => p !== socket);
            if (socket.opponent) socket.opponent.write("OPPONENT_DISCONNECTED\n");
            if (rooms[socket.roomCode].players.length === 0) delete rooms[socket.roomCode];
        }
    });
});

server.listen(PORT, '0.0.0.0', () => console.log(`Super Flappy Server on ${PORT}`));