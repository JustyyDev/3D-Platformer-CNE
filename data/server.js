const net = require('net');
const http = require('http');
const fs = require('fs');

const PORT = 8080;
const WEBHOOK_PORT = 8081;
const ADMIN_KEY = process.env.ADMIN_KEY || 'changeme';
const KOFI_VERIFICATION_TOKEN = process.env.KOFI_TOKEN || '';
const MAX_NICK_LEN = 12;
const MAX_ROOM_CODE_LEN = 4;
let rooms = {};
let leaderboard = [];
let pendingDonations = [];

const PACK_PRICES = {
    'pack1': {min: 0.99, coins: 1000},
    'pack2': {min: 3.99, coins: 5000},
    'pack3': {min: 9.99, coins: 15000},
    'pack4': {min: 24.99, coins: 50000},
    'pack5': {min: 99.99, coins: 250000}
};

function sanitize(str, maxLen) {
    return str.replace(/[^A-Za-z0-9 _-]/g, '').substring(0, maxLen);
}

if (fs.existsSync('leaderboard.json')) {
    try { leaderboard = JSON.parse(fs.readFileSync('leaderboard.json')); } catch (e) { leaderboard = []; }
}

function saveLeaderboard() {
    leaderboard.sort((a, b) => b.score - a.score);
    leaderboard = leaderboard.slice(0, 100);
    fs.writeFileSync('leaderboard.json', JSON.stringify(leaderboard));
}

function claimDonation(nickname, packId) {
    const pack = PACK_PRICES[packId];
    if (!pack) return null;

    for (let i = 0; i < pendingDonations.length; i++) {
        const d = pendingDonations[i];
        if (d.amount >= pack.min && !d.claimed) {
            d.claimed = true;
            pendingDonations.splice(i, 1);
            console.log(`[PAYMENT] ${nickname} claimed ${packId} from donation of $${d.amount}`);
            return pack.coins;
        }
    }
    return null;
}

setInterval(() => {
    const cutoff = Date.now() - 30 * 60 * 1000;
    pendingDonations = pendingDonations.filter(d => d.timestamp > cutoff);
}, 60 * 1000);

const webhook = http.createServer((req, res) => {
    if (req.method === 'POST' && req.url === '/kofi') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const params = new URLSearchParams(body);
                const raw = params.get('data');
                if (!raw) { res.writeHead(400); res.end(); return; }

                const data = JSON.parse(raw);

                if (KOFI_VERIFICATION_TOKEN && data.verification_token !== KOFI_VERIFICATION_TOKEN) {
                    console.log('[PAYMENT] Invalid verification token, rejecting webhook');
                    res.writeHead(403); res.end(); return;
                }

                if (data.type === 'Donation' || data.type === 'Shop Order') {
                    const amount = parseFloat(data.amount) || 0;
                    const from = data.from_name || 'anonymous';
                    console.log(`[PAYMENT] Ko-fi webhook: $${amount} from ${from}`);

                    if (amount > 0) {
                        pendingDonations.push({
                            amount: amount,
                            from: from,
                            message: data.message || '',
                            timestamp: Date.now(),
                            claimed: false
                        });
                    }
                }

                res.writeHead(200);
                res.end();
            } catch (e) {
                console.log('[PAYMENT] Webhook parse error:', e.message);
                res.writeHead(400);
                res.end();
            }
        });
    } else if (req.method === 'GET' && req.url === '/health') {
        res.writeHead(200, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({status: 'ok', pending: pendingDonations.length}));
    } else {
        res.writeHead(404);
        res.end();
    }
});

webhook.listen(WEBHOOK_PORT, '0.0.0.0', () => {
    console.log(`[WEBHOOK] Ko-fi webhook listener on port ${WEBHOOK_PORT}`);
});

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
                        rooms[code] = { players: [], gameStarted: false, seed: Math.floor(Math.random() * 999999), gameId: 'flockfall' };
                    }

                    if (rooms[code].players.length >= 6) {
                        socket.write("ROOM_FULL\n");
                        break;
                    }

                    rooms[code].players.push(socket);
                    console.log(`[LOBBY] ${socket.nickname} joined room ${code} (${rooms[code].players.length}/6)`);

                    broadcastToRoom(code, `CHAT:${socket.nickname} JOINED THE BATTLE!`);
                    sendPlayerList(code);

                    if (rooms[code].gameStarted) socket.write("GAME_ALREADY_STARTED\n");
                    else socket.write("WAITING_FOR_HOST\n");
                    break;

                case "START_GAME":
                    if (socket.roomCode && rooms[socket.roomCode]) {
                        rooms[socket.roomCode].gameStarted = true;
                        const gameId = rooms[socket.roomCode].gameId || 'flockfall';
                        broadcastToRoom(socket.roomCode, `START:${rooms[socket.roomCode].seed}:${socket.nickname}:${gameId}`);
                        console.log(`[GAME] Room ${socket.roomCode} started ${gameId}`);
                    }
                    break;

                case "GAME_SELECT":
                    if (socket.roomCode && rooms[socket.roomCode]) {
                        const selectedGame = sanitize(parts[1] || "flockfall", 20);
                        rooms[socket.roomCode].gameId = selectedGame;
                        broadcastToRoom(socket.roomCode, `GAME_SELECTED:${selectedGame}:${socket.nickname}`);
                        console.log(`[LOBBY] ${socket.nickname} selected ${selectedGame} in ${socket.roomCode}`);
                    }
                    break;

                case "VERIFY_DONATION":
                    const nick = sanitize(parts[1] || "", MAX_NICK_LEN);
                    const packId = sanitize(parts[2] || "", 10);
                    console.log(`[PAYMENT] Verify request: ${nick} wants ${packId}`);
                    const coins = claimDonation(nick, packId);
                    if (coins) {
                        socket.write("VERIFY_SUCCESS\n");
                    } else {
                        socket.write("VERIFY_FAIL\n");
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

    socket.on('error', (err) => {});

    socket.on('close', () => {
        if (socket.roomCode && rooms[socket.roomCode]) {
            console.log(`[LEAVE] ${socket.nickname} left room ${socket.roomCode}`);
            rooms[socket.roomCode].players = rooms[socket.roomCode].players.filter(p => p !== socket);
            broadcastToRoom(socket.roomCode, `CHAT:${socket.nickname} DISCONNECTED`);
            broadcastToRoom(socket.roomCode, `DEAD:${socket.nickname}`);
            sendPlayerList(socket.roomCode);
            if (rooms[socket.roomCode].players.length === 0) delete rooms[socket.roomCode];
        }
    });
});

function sendPlayerList(roomCode) {
    if (!rooms[roomCode]) return;
    const nicks = rooms[roomCode].players.map(p => p.nickname).sort();
    broadcastToRoom(roomCode, `PLAYER_LIST:${nicks.join(':')}`);
}

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
    console.log(`FLOCKFALL SERVER LIVE ON PORT ${PORT}`);
    console.log("-----------------------------------------");
});
