const net = require('net');
const http = require('http');
const fs = require('fs');

const PORT = 8080;
const WEBHOOK_PORT = 8081;
const ADMIN_KEY = process.env.ADMIN_KEY || 'changeme';
const KOFI_VERIFICATION_TOKEN = process.env.KOFI_TOKEN || '';
const MAX_NICK_LEN = 12;
const MAX_ROOM_CODE_LEN = 4;
const TICK_RATE = 20;
const TICK_MS = 1000 / TICK_RATE;

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

const CODES = {
    'FLOCKER': { reward: { type: 'coins', amount: 500 }, maxUses: 0, uses: 0, expires: null },
    'PARTY2026': { reward: { type: 'coins', amount: 1000 }, maxUses: 100, uses: 0, expires: null },
    'FOLLOWME': { reward: { type: 'title_coins', title: 'FAN', coins: 250 }, maxUses: 0, uses: 0, expires: null },
    'SECRETBIRD': { reward: { type: 'skin', skinId: 'twitter_bird' }, maxUses: 500, uses: 0, expires: null },
    'XDROP1': { reward: { type: 'coins', amount: 2000 }, maxUses: 50, uses: 0, expires: null },
    'BIGBIRD': { reward: { type: 'coins', amount: 5000 }, maxUses: 25, uses: 0, expires: null },
    'FREEBIE': { reward: { type: 'coins', amount: 100 }, maxUses: 0, uses: 0, expires: null }
};

let redeemedCodes = {};
try { redeemedCodes = JSON.parse(fs.readFileSync('redeemed_codes.json', 'utf8')); } catch(e) {}
try { const cu = JSON.parse(fs.readFileSync('codes_used.json', 'utf8')); for (let k in cu) if (CODES[k]) CODES[k].uses = cu[k]; } catch(e) {}

function saveCodeData() {
    try {
        const cu = {};
        for (let k in CODES) cu[k] = CODES[k].uses;
        fs.writeFileSync('codes_used.json', JSON.stringify(cu));
        fs.writeFileSync('redeemed_codes.json', JSON.stringify(redeemedCodes));
    } catch(e) {}
}

function redeemCode(nickname, code) {
    code = code.toUpperCase().trim();
    if (!CODES[code]) return { ok: false, reason: 'INVALID' };
    const c = CODES[code];
    if (c.expires && Date.now() > c.expires) return { ok: false, reason: 'EXPIRED' };
    if (c.maxUses > 0 && c.uses >= c.maxUses) return { ok: false, reason: 'MAX_USES' };
    if (!redeemedCodes[nickname]) redeemedCodes[nickname] = [];
    if (redeemedCodes[nickname].indexOf(code) !== -1) return { ok: false, reason: 'ALREADY_REDEEMED' };
    c.uses++;
    redeemedCodes[nickname].push(code);
    saveCodeData();
    return { ok: true, reward: c.reward };
}

const GAME_CONFIGS = {
    flockfall: { minPlayers: 1, maxModes: 4 },
    slingshot: { minPlayers: 1, maxModes: 6 },
    treasuregrab: { minPlayers: 1, maxModes: 1 },
    bumperbirds: { minPlayers: 1, maxModes: 1 },
    dodgederby: { minPlayers: 1, maxModes: 1 },
    musicaltiles: { minPlayers: 1, maxModes: 1 },
    skyrun: { minPlayers: 1, maxModes: 1 },
    cubeclash: { minPlayers: 1, maxModes: 1 },
    towerclimb: { minPlayers: 1, maxModes: 1 }
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

function createPlayerState(nick) {
    return { nick, x: 0, y: 0, vx: 0, vy: 0, score: 0, alive: true, inputs: {}, extra: {} };
}

function createGameState(gameId, mode, seed, playerNicks) {
    const rng = seedRng(seed);
    const players = {};
    playerNicks.forEach(n => { players[n] = createPlayerState(n); });

    const base = { gameId, mode, seed, rng, players, tick: 0, phase: 'countdown', countdownLeft: 3.0, started: false, over: false };

    switch (gameId) {
        case 'flockfall':
            return Object.assign(base, initFlockfall(players, mode, rng));
        case 'slingshot':
            return Object.assign(base, initSlingshot(players, mode, rng));
        case 'treasuregrab':
            return Object.assign(base, initTreasureGrab(players, rng));
        case 'bumperbirds':
            return Object.assign(base, initBumperBirds(players, rng));
        case 'dodgederby':
            return Object.assign(base, initDodgeDerby(players, rng));
        case 'musicaltiles':
            return Object.assign(base, initMusicalTiles(players, rng));
        case 'skyrun':
            return Object.assign(base, initSkyRun(players, rng));
        case 'cubeclash':
            return Object.assign(base, initCubeClash(players, rng));
        case 'towerclimb':
            return Object.assign(base, initTowerClimb(players, rng));
    }
    return base;
}

function seedRng(seed) {
    let s = seed;
    return function() {
        s = (s * 1103515245 + 12345) & 0x7fffffff;
        return s / 0x7fffffff;
    };
}

function rngRange(rng, min, max) { return min + rng() * (max - min); }
function rngInt(rng, min, max) { return Math.floor(rngRange(rng, min, max + 1)); }
function rngBool(rng, pct) { return rng() < (pct || 0.5); }

function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
function dist(x1, y1, x2, y2) { return Math.sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1)); }

const ARENA_W = 1280;
const ARENA_H = 720;
const ARENA_L = 40;
const ARENA_R = ARENA_W - 40;
const ARENA_T = 80;
const ARENA_B = ARENA_H - 50;

function initFlockfall(players, mode, rng) {
    const gravity = 680;
    const jumpForce = -320;
    const pipeGap = 170;
    const pipeSpeed = -160;
    Object.values(players).forEach(p => {
        p.x = 120; p.y = ARENA_H / 2; p.vy = 0; p.score = 0;
    });
    return {
        gravity, jumpForce, pipeGap, pipeSpeed,
        pipes: [], pipeTimer: 0, pipeInterval: 1.8,
        scrollSpeed: pipeSpeed, groundY: ARENA_H - 30,
        gameMode: mode
    };
}

function tickFlockfall(gs, dt) {
    if (gs.phase === 'countdown') return;
    gs.pipeTimer += dt;
    if (gs.pipeTimer >= gs.pipeInterval) {
        gs.pipeTimer = 0;
        const gapY = rngRange(gs.rng, 120, ARENA_H - 150 - gs.pipeGap);
        gs.pipes.push({ x: ARENA_W + 10, gapY, scored: {} });
    }
    for (let i = gs.pipes.length - 1; i >= 0; i--) {
        gs.pipes[i].x += gs.scrollSpeed * dt;
        if (gs.pipes[i].x < -80) gs.pipes.splice(i, 1);
    }
    Object.values(gs.players).forEach(p => {
        if (!p.alive) return;
        if (p.inputs.jump) { p.vy = gs.jumpForce; p.inputs.jump = false; }
        p.vy += gs.gravity * dt;
        p.y += p.vy * dt;
        if (p.y < 0) { p.y = 0; p.vy = 0; }
        if (p.y >= gs.groundY - 32) { p.alive = false; return; }
        for (const pipe of gs.pipes) {
            const bx = p.x, by = p.y, bw = 38, bh = 32;
            const px = pipe.x, pw = 60;
            if (bx + bw > px && bx < px + pw) {
                if (by < pipe.gapY || by + bh > pipe.gapY + gs.pipeGap) {
                    p.alive = false; return;
                }
                if (!pipe.scored[p.nick]) { pipe.scored[p.nick] = true; p.score++; }
            }
        }
    });
    checkGameOver(gs);
}

function initSlingshot(players, mode, rng) {
    const nicks = Object.keys(players);
    Object.values(players).forEach(p => {
        p.x = 100; p.y = ARENA_H - 80; p.vx = 0; p.vy = 0;
        p.extra.shotsLeft = mode === 5 ? 999 : 3;
        p.extra.launched = false;
        p.extra.dragging = false;
        p.extra.turnActive = false;
        p.score = 0;
    });
    const gravity = 500;
    const blocks = [];
    const targets = [];
    const turnOrder = nicks.slice();
    generateSlingLevel(blocks, targets, 1, mode, rng, gravity);
    return {
        gravity, blocks, targets, currentLevel: 1, mode,
        turnOrder, currentTurn: 0, turnPhase: 'aim',
        objHealth: {}
    };
}

function generateSlingLevel(blocks, targets, level, mode, rng, gravity) {
    blocks.length = 0;
    targets.length = 0;
    const startX = ARENA_W * 0.55;
    const startY = ARENA_H - 30;
    const rows = Math.min(8, level + 2);
    let idCounter = 0;
    for (let r = 0; r < rows; r++) {
        const cols = rows - r;
        for (let c = 0; c < cols; c++) {
            const bx = startX + c * 40 + r * 20;
            const by = startY - 20 - r * 40;
            const hp = mode === 3 ? 20 : 100;
            const mass = mode === 3 ? 0.5 : 2;
            const elast = mode === 1 ? 0.8 : 0.2;
            const grav = mode === 4 ? gravity * 2 : gravity;
            blocks.push({ id: idCounter++, x: bx, y: by, vx: 0, vy: 0, hp, maxHp: hp, mass, elasticity: elast, gravity: grav, w: 38, h: 38, alive: true });
            if (rngBool(rng, 0.3) || (r === rows - 1 && c === 0)) {
                targets.push({ id: idCounter++, x: bx + 4, y: by - 30, vx: 0, vy: 0, hp: 50, maxHp: 50, mass: 1, elasticity: elast, gravity: grav, w: 30, h: 30, alive: true });
            }
        }
    }
}

function tickSlingshot(gs, dt) {
    if (gs.phase === 'countdown') return;
    const currentNick = gs.turnOrder[gs.currentTurn % gs.turnOrder.length];
    const p = gs.players[currentNick];
    if (!p) return;

    if (p.extra.launched) {
        p.vy += gs.gravity * 0.5 * dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;

        const groundY = ARENA_H - 30;
        if (p.y >= groundY - 32) { p.y = groundY - 32; p.vy = -p.vy * 0.3; if (Math.abs(p.vy) < 20) p.vy = 0; }

        gs.blocks.filter(b => b.alive).forEach(b => {
            b.vy += b.gravity * dt;
            b.y += b.vy * dt;
            if (b.y >= groundY - b.h) { b.y = groundY - b.h; b.vy = 0; }
        });
        gs.targets.filter(t => t.alive).forEach(t => {
            t.vy += t.gravity * dt;
            t.y += t.vy * dt;
            if (t.y >= groundY - t.h) { t.y = groundY - t.h; t.vy = 0; }
        });

        gs.blocks.filter(b => b.alive).forEach(b => {
            if (rectOverlap(p.x, p.y, 38, 32, b.x, b.y, b.w, b.h)) {
                const impact = Math.abs(p.vx) + Math.abs(p.vy);
                const dmg = impact * 0.15;
                b.hp -= dmg;
                p.vx *= -0.3; p.vy *= -0.3;
                b.vx += p.vx * 0.5; b.vy -= 50;
                if (b.hp <= 0) b.alive = false;
            }
        });
        gs.targets.filter(t => t.alive).forEach(t => {
            if (rectOverlap(p.x, p.y, 38, 32, t.x, t.y, t.w, t.h)) {
                const impact = Math.abs(p.vx) + Math.abs(p.vy);
                const dmg = impact * 0.2;
                t.hp -= dmg;
                if (t.hp <= 0) { t.alive = false; p.score += 10; }
            }
        });

        const outOfBounds = p.x > ARENA_W + 100 || p.y > ARENA_H || p.y < -300;
        const stopped = Math.abs(p.vx) < 10 && Math.abs(p.vy) < 10 && p.y > groundY - 50;
        if (outOfBounds || stopped) {
            p.extra.launched = false;
            p.extra.shotsLeft--;
            if (gs.targets.filter(t => t.alive).length === 0) {
                gs.currentLevel++;
                generateSlingLevel(gs.blocks, gs.targets, gs.currentLevel, gs.mode, gs.rng, gs.gravity);
                gs.turnOrder.forEach(n => { if (gs.players[n]) gs.players[n].extra.shotsLeft = gs.mode === 5 ? 999 : 3; });
            } else if (p.extra.shotsLeft <= 0) {
                gs.currentTurn++;
                if (gs.currentTurn >= gs.turnOrder.length) {
                    gs.over = true; gs.phase = 'gameover';
                } else {
                    const next = gs.players[gs.turnOrder[gs.currentTurn % gs.turnOrder.length]];
                    if (next) { next.extra.shotsLeft = gs.mode === 5 ? 999 : 3; }
                }
            }
            p.x = 100; p.y = ARENA_H - 80; p.vx = 0; p.vy = 0;
        }
    }

    if (p.inputs.launch && !p.extra.launched && p.extra.shotsLeft > 0) {
        const dx = p.inputs.launchDx || 0;
        const dy = p.inputs.launchDy || 0;
        p.vx = dx * 8; p.vy = dy * 8;
        p.extra.launched = true;
        p.inputs.launch = false;
    }
}

function rectOverlap(ax, ay, aw, ah, bx, by, bw, bh) {
    return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
}

function initTreasureGrab(players, rng) {
    Object.values(players).forEach(p => {
        p.x = ARENA_W / 2; p.y = ARENA_H / 2; p.score = 0; p.extra.hasDouble = false; p.extra.hasMagnet = false;
        p.extra.doubleTimer = 0; p.extra.magnetTimer = 0;
    });
    return { timer: 60, coins: [], coinSpawnTimer: 0, spawnRate: 0.4, speed: 320 };
}

function tickTreasureGrab(gs, dt) {
    if (gs.phase === 'countdown') return;
    gs.timer -= dt;
    if (gs.timer <= 0) { gs.over = true; gs.phase = 'gameover'; return; }

    gs.coinSpawnTimer += dt;
    let interval = gs.spawnRate;
    if (gs.timer < 20) interval = 0.2;
    if (gs.timer < 10) interval = 0.12;
    if (gs.coinSpawnTimer >= interval) {
        gs.coinSpawnTimer = 0;
        const roll = gs.rng();
        let type = 'small', value = 1;
        if (roll < 0.03) type = 'double';
        else if (roll < 0.06) type = 'magnet';
        else if (roll < 0.2) { type = 'big'; value = 5; }
        gs.coins.push({
            x: rngRange(gs.rng, ARENA_L + 20, ARENA_R - 20),
            y: rngRange(gs.rng, ARENA_T + 20, ARENA_B - 20),
            type, value, alive: true
        });
    }
    if (gs.coins.length > 80) gs.coins = gs.coins.filter(c => c.alive).slice(-60);

    Object.values(gs.players).forEach(p => {
        if (!p.alive) return;
        const spd = gs.speed * dt;
        if (p.inputs.left) p.x -= spd;
        if (p.inputs.right) p.x += spd;
        if (p.inputs.up) p.y -= spd;
        if (p.inputs.down) p.y += spd;
        p.x = clamp(p.x, ARENA_L, ARENA_R - 34);
        p.y = clamp(p.y, ARENA_T, ARENA_B - 28);

        if (p.extra.hasMagnet) {
            p.extra.magnetTimer -= dt;
            if (p.extra.magnetTimer <= 0) p.extra.hasMagnet = false;
            gs.coins.filter(c => c.alive && c.type !== 'double' && c.type !== 'magnet').forEach(c => {
                const dx = (p.x + 17) - c.x;
                const dy = (p.y + 14) - c.y;
                const d = Math.sqrt(dx * dx + dy * dy);
                if (d < 120 && d > 0) {
                    const pull = 400 / d;
                    c.x += dx * pull * dt * 3;
                    c.y += dy * pull * dt * 3;
                }
            });
        }
        if (p.extra.hasDouble) {
            p.extra.doubleTimer -= dt;
            if (p.extra.doubleTimer <= 0) p.extra.hasDouble = false;
        }

        gs.coins.filter(c => c.alive).forEach(c => {
            const dx = Math.abs((p.x + 17) - c.x);
            const dy = Math.abs((p.y + 14) - c.y);
            if (dx < 24 && dy < 22) {
                c.alive = false;
                if (c.type === 'double') { p.extra.hasDouble = true; p.extra.doubleTimer = 8; }
                else if (c.type === 'magnet') { p.extra.hasMagnet = true; p.extra.magnetTimer = 6; }
                else {
                    const earned = p.extra.hasDouble ? c.value * 2 : c.value;
                    p.score += earned;
                }
            }
        });
    });
    gs.coins = gs.coins.filter(c => c.alive);
}

function initBumperBirds(players, rng) {
    const cx = ARENA_W / 2, cy = ARENA_H / 2 + 20;
    let i = 0;
    Object.values(players).forEach(p => {
        const angle = (i / Object.keys(players).length) * Math.PI * 2;
        p.x = cx + Math.cos(angle) * 80;
        p.y = cy + Math.sin(angle) * 80;
        p.vx = 0; p.vy = 0;
        p.extra.dashCooldown = 0;
        i++;
    });
    return { platformRadius: 180, shrinkTimer: 0, shrinkInterval: 8, minRadius: 60, cx, cy, accel: 800, friction: 0.92 };
}

function tickBumperBirds(gs, dt) {
    if (gs.phase === 'countdown') return;
    gs.shrinkTimer += dt;
    if (gs.shrinkTimer >= gs.shrinkInterval) {
        gs.shrinkTimer = 0;
        gs.platformRadius = Math.max(gs.minRadius, gs.platformRadius - 15);
    }
    const aliveArr = Object.values(gs.players).filter(p => p.alive);
    aliveArr.forEach(p => {
        if (p.extra.dashCooldown > 0) p.extra.dashCooldown -= dt;
        const accel = gs.accel * dt;
        if (p.inputs.left) p.vx -= accel;
        if (p.inputs.right) p.vx += accel;
        if (p.inputs.up) p.vy -= accel;
        if (p.inputs.down) p.vy += accel;
        if (p.inputs.dash && p.extra.dashCooldown <= 0) {
            const len = Math.sqrt(p.vx * p.vx + p.vy * p.vy);
            if (len > 10) { p.vx *= 2.5; p.vy *= 2.5; }
            else { p.vx += 400; }
            p.extra.dashCooldown = 1.5;
            p.inputs.dash = false;
        }
        p.vx *= gs.friction; p.vy *= gs.friction;
        p.x += p.vx * dt; p.y += p.vy * dt;

        const d = dist(p.x + 14, p.y + 12, gs.cx, gs.cy);
        if (d > gs.platformRadius + 20) p.alive = false;
    });

    for (let i = 0; i < aliveArr.length; i++) {
        for (let j = i + 1; j < aliveArr.length; j++) {
            const a = aliveArr[i], b = aliveArr[j];
            const dx = (b.x + 14) - (a.x + 14);
            const dy = (b.y + 12) - (a.y + 12);
            const d = Math.sqrt(dx * dx + dy * dy);
            if (d < 32 && d > 0) {
                const nx = dx / d, ny = dy / d;
                const relVx = a.vx - b.vx, relVy = a.vy - b.vy;
                const impact = (relVx * nx + relVy * ny) * 1.5;
                if (impact > 0) {
                    a.vx -= nx * impact; a.vy -= ny * impact;
                    b.vx += nx * impact; b.vy += ny * impact;
                }
                const overlap = 32 - d;
                a.x -= nx * overlap * 0.5; a.y -= ny * overlap * 0.5;
                b.x += nx * overlap * 0.5; b.y += ny * overlap * 0.5;
            }
        }
    }
    checkGameOver(gs);
}

function initDodgeDerby(players, rng) {
    Object.values(players).forEach(p => {
        p.x = ARENA_W / 2; p.y = ARENA_H / 2;
        p.extra.hasShield = false; p.extra.isShrunk = false; p.extra.isPhased = false;
        p.extra.shieldTimer = 0; p.extra.shrinkTimer = 0; p.extra.phaseTimer = 0;
    });
    return {
        wave: 0, waveTimer: 0, waveInterval: 6,
        projectiles: [], powerups: [], powerupSpawnTimer: 0,
        speed: 280
    };
}

function tickDodgeDerby(gs, dt) {
    if (gs.phase === 'countdown') return;
    gs.waveTimer += dt;
    gs.powerupSpawnTimer += dt;
    const interval = Math.max(3, gs.waveInterval - gs.wave * 0.3);
    if (gs.waveTimer >= interval) {
        gs.waveTimer = 0;
        gs.wave++;
        const count = 3 + gs.wave * 2;
        const speed = 100 + gs.wave * 20;
        for (let i = 0; i < count; i++) {
            const side = rngInt(gs.rng, 0, 3);
            let px, py, pvx, pvy;
            if (side === 0) { px = rngRange(gs.rng, ARENA_L, ARENA_R); py = ARENA_T - 10; pvx = rngRange(gs.rng, -50, 50); pvy = speed; }
            else if (side === 1) { px = rngRange(gs.rng, ARENA_L, ARENA_R); py = ARENA_B + 10; pvx = rngRange(gs.rng, -50, 50); pvy = -speed; }
            else if (side === 2) { px = ARENA_L - 10; py = rngRange(gs.rng, ARENA_T, ARENA_B); pvx = speed; pvy = rngRange(gs.rng, -50, 50); }
            else { px = ARENA_R + 10; py = rngRange(gs.rng, ARENA_T, ARENA_B); pvx = -speed; pvy = rngRange(gs.rng, -50, 50); }
            const homing = gs.wave >= 3 && rngBool(gs.rng, 0.2);
            gs.projectiles.push({ x: px, y: py, vx: pvx, vy: pvy, homing, alive: true });
        }
    }

    if (gs.powerupSpawnTimer >= 8) {
        gs.powerupSpawnTimer = 0;
        const type = rngInt(gs.rng, 0, 2);
        gs.powerups.push({
            x: rngRange(gs.rng, ARENA_L + 30, ARENA_R - 30),
            y: rngRange(gs.rng, ARENA_T + 30, ARENA_B - 30),
            type, alive: true
        });
    }

    const alivePlayers = Object.values(gs.players).filter(p => p.alive);
    gs.projectiles.forEach(proj => {
        if (!proj.alive) return;
        if (proj.homing && alivePlayers.length > 0) {
            const target = alivePlayers[0];
            const dx = target.x - proj.x, dy = target.y - proj.y;
            const d = Math.sqrt(dx * dx + dy * dy);
            if (d > 0) { proj.vx += (dx / d) * 80 * dt; proj.vy += (dy / d) * 80 * dt; }
        }
        proj.x += proj.vx * dt; proj.y += proj.vy * dt;
        if (!proj.homing) {
            if (proj.x < ARENA_L || proj.x > ARENA_R) proj.vx *= -1;
            if (proj.y < ARENA_T || proj.y > ARENA_B) proj.vy *= -1;
        }
        if (proj.x < ARENA_L - 100 || proj.x > ARENA_R + 100 || proj.y < ARENA_T - 100 || proj.y > ARENA_B + 100) {
            proj.alive = false;
        }
    });

    alivePlayers.forEach(p => {
        const spd = gs.speed * dt;
        if (p.inputs.left) p.x -= spd;
        if (p.inputs.right) p.x += spd;
        if (p.inputs.up) p.y -= spd;
        if (p.inputs.down) p.y += spd;
        p.x = clamp(p.x, ARENA_L, ARENA_R - 28);
        p.y = clamp(p.y, ARENA_T, ARENA_B - 24);

        if (p.extra.shieldTimer > 0) p.extra.shieldTimer -= dt;
        if (p.extra.shrinkTimer > 0) p.extra.shrinkTimer -= dt;
        if (p.extra.phaseTimer > 0) p.extra.phaseTimer -= dt;
        if (p.extra.shieldTimer <= 0) p.extra.hasShield = false;
        if (p.extra.shrinkTimer <= 0) p.extra.isShrunk = false;
        if (p.extra.phaseTimer <= 0) p.extra.isPhased = false;

        gs.powerups.filter(pw => pw.alive).forEach(pw => {
            if (Math.abs(p.x - pw.x) < 24 && Math.abs(p.y - pw.y) < 24) {
                pw.alive = false;
                if (pw.type === 0) { p.extra.hasShield = true; p.extra.shieldTimer = 5; }
                else if (pw.type === 1) { p.extra.isShrunk = true; p.extra.shrinkTimer = 6; }
                else { p.extra.isPhased = true; p.extra.phaseTimer = 3; }
            }
        });

        if (p.extra.isPhased) return;
        const hitSize = p.extra.isShrunk ? 10 : 20;
        gs.projectiles.filter(proj => proj.alive).forEach(proj => {
            if (Math.abs((p.x + 14) - proj.x) < hitSize && Math.abs((p.y + 12) - proj.y) < hitSize) {
                if (p.extra.hasShield) { p.extra.hasShield = false; p.extra.shieldTimer = 0; proj.alive = false; }
                else { p.alive = false; p.score = 5 + gs.wave * 2; }
            }
        });
    });
    gs.projectiles = gs.projectiles.filter(p => p.alive);
    gs.powerups = gs.powerups.filter(p => p.alive);
    checkGameOver(gs);
}

function initMusicalTiles(players, rng) {
    const cols = 5, rows = 4;
    Object.values(players).forEach(p => {
        p.x = ARENA_W / 2; p.y = ARENA_T + (rows * 100) / 2;
    });
    return {
        cols, rows, round: 0, maxRounds: 8,
        tilePhase: 'idle', musicTimer: 0, revealTimer: 0,
        musicDuration: 5.5, revealDuration: 2.5,
        safeTiles: [], speed: 300
    };
}

function tickMusicalTiles(gs, dt) {
    if (gs.phase === 'countdown') return;

    if (gs.tilePhase === 'idle') {
        gs.round++;
        if (gs.round > gs.maxRounds) { gs.over = true; gs.phase = 'gameover'; return; }
        gs.tilePhase = 'music';
        gs.musicTimer = 0;
        gs.musicDuration = Math.max(2.5, 5.5 - gs.round * 0.35);
        gs.safeTiles = [];
    }

    if (gs.tilePhase === 'music') {
        gs.musicTimer += dt;
        updateTileMovement(gs, dt);
        if (gs.musicTimer >= gs.musicDuration) {
            gs.tilePhase = 'reveal';
            gs.revealTimer = 0;
            gs.revealDuration = Math.max(1.5, 2.5 - gs.round * 0.1);
            const total = gs.cols * gs.rows;
            const safeCount = Math.max(2, Math.floor(total * (0.6 - gs.round * 0.05)));
            const indices = [];
            for (let i = 0; i < total; i++) indices.push(i);
            for (let i = total - 1; i > 0; i--) {
                const j = rngInt(gs.rng, 0, i);
                [indices[i], indices[j]] = [indices[j], indices[i]];
            }
            gs.safeTiles = indices.slice(0, safeCount);
        }
    }

    if (gs.tilePhase === 'reveal') {
        gs.revealTimer += dt;
        updateTileMovement(gs, dt);
        if (gs.revealTimer >= gs.revealDuration) {
            gs.tilePhase = 'check';
            const tileW = (ARENA_W - 120) / gs.cols;
            const tileH = (ARENA_H - 150) / gs.rows;
            const offX = 60, offY = 90;
            Object.values(gs.players).forEach(p => {
                if (!p.alive) return;
                const col = Math.floor((p.x - offX) / tileW);
                const row = Math.floor((p.y - offY) / tileH);
                if (col < 0 || col >= gs.cols || row < 0 || row >= gs.rows) { p.alive = false; return; }
                const tileIdx = row * gs.cols + col;
                if (!gs.safeTiles.includes(tileIdx)) p.alive = false;
            });
            checkGameOver(gs);
            if (!gs.over) {
                setTimeout(() => { gs.tilePhase = 'idle'; }, 2000);
            }
        }
    }
}

function updateTileMovement(gs, dt) {
    Object.values(gs.players).forEach(p => {
        if (!p.alive) return;
        const spd = gs.speed * dt;
        if (p.inputs.left) p.x -= spd;
        if (p.inputs.right) p.x += spd;
        if (p.inputs.up) p.y -= spd;
        if (p.inputs.down) p.y += spd;
        p.x = clamp(p.x, 60, ARENA_W - 88);
        p.y = clamp(p.y, 90, ARENA_H - 84);
    });
}

function initSkyRun(players, rng) {
    let i = 0;
    Object.values(players).forEach(p => {
        p.x = i * 2; p.y = 0; p.extra.z = 0; p.vy = 0;
        p.extra.lane = 1; p.extra.grounded = true;
        i++;
    });
    return {
        runSpeed: 300, gravity: 800, jumpForce: -400,
        platforms: [], platformSpawnZ: 0, spawnInterval: 200,
        flockerPickups: [], pickupSpawnZ: 0
    };
}

function tickSkyRun(gs, dt) {
    if (gs.phase === 'countdown') return;
    gs.runSpeed += dt * 5;

    while (gs.platformSpawnZ < gs.runSpeed * 10) {
        gs.platformSpawnZ += gs.spawnInterval;
        const lane = rngInt(gs.rng, 0, 2);
        const width = rngRange(gs.rng, 60, 150);
        gs.platforms.push({ z: gs.platformSpawnZ, lane, width, y: 0 });
        if (rngBool(gs.rng, 0.3)) {
            gs.flockerPickups.push({ z: gs.platformSpawnZ, lane: rngInt(gs.rng, 0, 2), collected: {} });
        }
    }

    Object.values(gs.players).forEach(p => {
        if (!p.alive) return;
        p.extra.z += gs.runSpeed * dt;

        if (p.inputs.left && p.extra.lane > 0) { p.extra.lane--; p.inputs.left = false; }
        if (p.inputs.right && p.extra.lane < 2) { p.extra.lane++; p.inputs.right = false; }
        if (p.inputs.jump && p.extra.grounded) { p.vy = gs.jumpForce; p.extra.grounded = false; p.inputs.jump = false; }

        p.vy += gs.gravity * dt;
        p.y += p.vy * dt;

        let onPlatform = false;
        gs.platforms.forEach(plat => {
            if (Math.abs(plat.z - p.extra.z) < plat.width / 2 && plat.lane === p.extra.lane) {
                if (p.y >= 0 && p.vy >= 0) { p.y = 0; p.vy = 0; p.extra.grounded = true; onPlatform = true; }
            }
        });

        if (!onPlatform && p.y > 500) p.alive = false;

        gs.flockerPickups.forEach(fp => {
            if (!fp.collected[p.nick] && fp.lane === p.extra.lane && Math.abs(fp.z - p.extra.z) < 40) {
                fp.collected[p.nick] = true; p.score += 5;
            }
        });
    });

    const minZ = Math.min(...Object.values(gs.players).filter(p => p.alive).map(p => p.extra.z)) - 500;
    gs.platforms = gs.platforms.filter(p => p.z > minZ);
    gs.flockerPickups = gs.flockerPickups.filter(p => p.z > minZ);
    checkGameOver(gs);
}

function initCubeClash(players, rng) {
    const cx = 0, cy = 0;
    let i = 0;
    Object.values(players).forEach(p => {
        const angle = (i / Object.keys(players).length) * Math.PI * 2;
        p.x = cx + Math.cos(angle) * 120;
        p.y = cy + Math.sin(angle) * 120;
        p.extra.z = 0;
        p.vx = 0; p.vy = 0;
        p.extra.size = 1;
        p.extra.boostTimer = 0;
        i++;
    });
    return {
        arenaRadius: 250, shrinkTimer: 0, shrinkInterval: 10,
        powerCubes: [], cubeSpawnTimer: 0,
        accel: 600, friction: 0.9
    };
}

function tickCubeClash(gs, dt) {
    if (gs.phase === 'countdown') return;
    gs.shrinkTimer += dt;
    gs.cubeSpawnTimer += dt;
    if (gs.shrinkTimer >= gs.shrinkInterval) {
        gs.shrinkTimer = 0;
        gs.arenaRadius = Math.max(60, gs.arenaRadius - 20);
    }
    if (gs.cubeSpawnTimer >= 5) {
        gs.cubeSpawnTimer = 0;
        const type = rngInt(gs.rng, 0, 1);
        gs.powerCubes.push({
            x: rngRange(gs.rng, -gs.arenaRadius + 30, gs.arenaRadius - 30),
            y: rngRange(gs.rng, -gs.arenaRadius + 30, gs.arenaRadius - 30),
            type, alive: true
        });
    }

    const aliveArr = Object.values(gs.players).filter(p => p.alive);
    aliveArr.forEach(p => {
        if (p.extra.boostTimer > 0) p.extra.boostTimer -= dt;
        const spd = gs.accel * (p.extra.boostTimer > 0 ? 1.5 : 1) * dt;
        if (p.inputs.left) p.vx -= spd;
        if (p.inputs.right) p.vx += spd;
        if (p.inputs.up) p.vy -= spd;
        if (p.inputs.down) p.vy += spd;
        p.vx *= gs.friction; p.vy *= gs.friction;
        p.x += p.vx * dt; p.y += p.vy * dt;

        const d = Math.sqrt(p.x * p.x + p.y * p.y);
        if (d > gs.arenaRadius + 30) p.alive = false;

        gs.powerCubes.filter(c => c.alive).forEach(c => {
            if (Math.abs(p.x - c.x) < 25 && Math.abs(p.y - c.y) < 25) {
                c.alive = false;
                if (c.type === 0) p.extra.boostTimer = 5;
                else p.extra.size = Math.min(2, p.extra.size + 0.3);
            }
        });
    });

    for (let i = 0; i < aliveArr.length; i++) {
        for (let j = i + 1; j < aliveArr.length; j++) {
            const a = aliveArr[i], b = aliveArr[j];
            const dx = b.x - a.x, dy = b.y - a.y;
            const d = Math.sqrt(dx * dx + dy * dy);
            const minD = (a.extra.size + b.extra.size) * 18;
            if (d < minD && d > 0) {
                const nx = dx / d, ny = dy / d;
                const relV = (a.vx - b.vx) * nx + (a.vy - b.vy) * ny;
                if (relV > 0) {
                    const massA = a.extra.size, massB = b.extra.size;
                    const impulse = relV * 1.8;
                    a.vx -= nx * impulse * (massB / (massA + massB));
                    a.vy -= ny * impulse * (massB / (massA + massB));
                    b.vx += nx * impulse * (massA / (massA + massB));
                    b.vy += ny * impulse * (massA / (massA + massB));
                }
            }
        }
    }
    gs.powerCubes = gs.powerCubes.filter(c => c.alive);
    checkGameOver(gs);
}

function initTowerClimb(players, rng) {
    let i = 0;
    Object.values(players).forEach(p => {
        p.x = ARENA_W / 2 + (i - 1) * 50; p.y = ARENA_H - 60;
        p.vx = 0; p.vy = 0;
        p.extra.grounded = true;
        p.extra.height = 0;
        i++;
    });
    const platforms = [];
    for (let j = 0; j < 50; j++) {
        platforms.push({
            x: rngRange(rng, 80, ARENA_W - 180),
            y: ARENA_H - 100 - j * 80,
            w: rngRange(rng, 80, 160),
            moving: j > 5 && rngBool(rng, 0.3),
            moveSpeed: rngRange(rng, 40, 100),
            moveDir: rngBool(rng, 0.5) ? 1 : -1,
            disappearing: j > 10 && rngBool(rng, 0.15),
            timer: 0, visible: true
        });
    }
    return {
        platforms, gravity: 700, jumpForce: -380,
        speed: 250, topY: ARENA_H - 100 - 49 * 80,
        cameraY: 0
    };
}

function tickTowerClimb(gs, dt) {
    if (gs.phase === 'countdown') return;

    gs.platforms.forEach(plat => {
        if (plat.moving) {
            plat.x += plat.moveSpeed * plat.moveDir * dt;
            if (plat.x < 40 || plat.x + plat.w > ARENA_W - 40) plat.moveDir *= -1;
        }
        if (plat.disappearing) {
            plat.timer += dt;
            plat.visible = Math.sin(plat.timer * 2) > -0.3;
        }
    });

    Object.values(gs.players).forEach(p => {
        if (!p.alive) return;
        const spd = gs.speed * dt;
        if (p.inputs.left) p.x -= spd;
        if (p.inputs.right) p.x += spd;
        if (p.inputs.jump && p.extra.grounded) { p.vy = gs.jumpForce; p.extra.grounded = false; p.inputs.jump = false; }

        p.vy += gs.gravity * dt;
        p.y += p.vy * dt;
        p.x = clamp(p.x, 40, ARENA_W - 70);

        p.extra.grounded = false;
        if (p.vy >= 0) {
            gs.platforms.forEach(plat => {
                if (!plat.visible) return;
                if (p.x + 28 > plat.x && p.x < plat.x + plat.w && p.y + 24 >= plat.y && p.y + 24 <= plat.y + 12) {
                    p.y = plat.y - 24; p.vy = 0; p.extra.grounded = true;
                }
            });
        }

        p.extra.height = Math.max(p.extra.height, ARENA_H - p.y);
        p.score = Math.floor(p.extra.height / 10);

        if (p.y > gs.cameraY + ARENA_H + 200) p.alive = false;
        if (p.y <= gs.topY) { p.score += 100; gs.over = true; gs.phase = 'gameover'; }
    });

    const highestY = Math.min(...Object.values(gs.players).filter(p => p.alive).map(p => p.y));
    gs.cameraY = highestY - ARENA_H * 0.4;
    checkGameOver(gs);
}

function checkGameOver(gs) {
    if (gs.over) return;
    const alive = Object.values(gs.players).filter(p => p.alive);
    const total = Object.values(gs.players).length;
    if (total <= 1) return;
    if (alive.length <= 1) { gs.over = true; gs.phase = 'gameover'; }
}

function serializeGameState(gs) {
    const players = {};
    Object.entries(gs.players).forEach(([nick, p]) => {
        players[nick] = {
            x: Math.round(p.x), y: Math.round(p.y),
            vx: Math.round(p.vx || 0), vy: Math.round(p.vy || 0),
            score: p.score, alive: p.alive
        };
        if (p.extra.z !== undefined) players[nick].z = Math.round(p.extra.z);
        if (p.extra.lane !== undefined) players[nick].lane = p.extra.lane;
        if (p.extra.size !== undefined) players[nick].size = Math.round(p.extra.size * 100) / 100;
        if (p.extra.height !== undefined) players[nick].height = Math.round(p.extra.height);
        if (p.extra.hasShield) players[nick].shield = 1;
        if (p.extra.isShrunk) players[nick].shrunk = 1;
        if (p.extra.isPhased) players[nick].phased = 1;
        if (p.extra.hasDouble) players[nick].dbl = 1;
        if (p.extra.hasMagnet) players[nick].mag = 1;
        if (p.extra.shotsLeft !== undefined) players[nick].shots = p.extra.shotsLeft;
        if (p.extra.launched) players[nick].launched = 1;
    });

    const state = { g: gs.gameId, t: gs.tick, ph: gs.phase, p: players };

    if (gs.phase === 'countdown') state.cd = Math.ceil(gs.countdownLeft);

    switch (gs.gameId) {
        case 'flockfall':
            state.pipes = gs.pipes.map(p => ({ x: Math.round(p.x), gy: Math.round(p.gapY) }));
            break;
        case 'slingshot':
            state.blocks = gs.blocks.filter(b => b.alive).map(b => ({ id: b.id, x: Math.round(b.x), y: Math.round(b.y), hp: Math.round(b.hp) }));
            state.targets = gs.targets.filter(t => t.alive).map(t => ({ id: t.id, x: Math.round(t.x), y: Math.round(t.y), hp: Math.round(t.hp) }));
            state.turn = gs.turnOrder[gs.currentTurn % gs.turnOrder.length];
            state.lvl = gs.currentLevel;
            break;
        case 'treasuregrab':
            state.timer = Math.round(gs.timer * 10) / 10;
            state.coins = gs.coins.slice(-40).map(c => ({ x: Math.round(c.x), y: Math.round(c.y), tp: c.type[0] }));
            break;
        case 'bumperbirds':
            state.pr = Math.round(gs.platformRadius);
            break;
        case 'dodgederby':
            state.wave = gs.wave;
            state.projs = gs.projectiles.slice(-50).map(p => ({ x: Math.round(p.x), y: Math.round(p.y) }));
            state.pws = gs.powerups.map(p => ({ x: Math.round(p.x), y: Math.round(p.y), tp: p.type }));
            break;
        case 'musicaltiles':
            state.round = gs.round; state.tp = gs.tilePhase;
            state.safe = gs.safeTiles;
            break;
        case 'skyrun':
            state.spd = Math.round(gs.runSpeed);
            break;
        case 'cubeclash':
            state.ar = Math.round(gs.arenaRadius);
            state.cubes = gs.powerCubes.map(c => ({ x: Math.round(c.x), y: Math.round(c.y), tp: c.type }));
            break;
        case 'towerclimb':
            state.camY = Math.round(gs.cameraY);
            state.plats = gs.platforms.filter(p => p.visible).map(p => ({ x: Math.round(p.x), y: Math.round(p.y), w: Math.round(p.w) }));
            break;
    }

    return JSON.stringify(state);
}

function tickRoom(room, dt) {
    if (!room.gameState || room.gameState.over) return;
    const gs = room.gameState;

    if (gs.phase === 'countdown') {
        gs.countdownLeft -= dt;
        if (gs.countdownLeft <= 0) {
            gs.phase = 'playing';
            gs.started = true;
            if (gs.gameId === 'musicaltiles') gs.tilePhase = 'idle';
        }
        return;
    }

    gs.tick++;
    switch (gs.gameId) {
        case 'flockfall': tickFlockfall(gs, dt); break;
        case 'slingshot': tickSlingshot(gs, dt); break;
        case 'treasuregrab': tickTreasureGrab(gs, dt); break;
        case 'bumperbirds': tickBumperBirds(gs, dt); break;
        case 'dodgederby': tickDodgeDerby(gs, dt); break;
        case 'musicaltiles': tickMusicalTiles(gs, dt); break;
        case 'skyrun': tickSkyRun(gs, dt); break;
        case 'cubeclash': tickCubeClash(gs, dt); break;
        case 'towerclimb': tickTowerClimb(gs, dt); break;
    }
}

function startGameLoop() {
    setInterval(() => {
        const dt = TICK_MS / 1000;
        for (const code in rooms) {
            const room = rooms[code];
            if (room.gameStarted && room.gameState) {
                tickRoom(room, dt);
                const stateStr = serializeGameState(room.gameState);
                broadcastToRoom(code, `GS:${stateStr}`);
            }
        }
    }, TICK_MS);
}

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
                    res.writeHead(403); res.end(); return;
                }
                if (data.type === 'Donation' || data.type === 'Shop Order') {
                    const amount = parseFloat(data.amount) || 0;
                    const from = data.from_name || 'anonymous';
                    if (amount > 0) {
                        pendingDonations.push({ amount, from, message: data.message || '', timestamp: Date.now(), claimed: false });
                    }
                }
                res.writeHead(200); res.end();
            } catch (e) { res.writeHead(400); res.end(); }
        });
    } else if (req.method === 'GET' && req.url === '/health') {
        let total = 0;
        for (let r in rooms) total += rooms[r].players.length;
        res.writeHead(200, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({status: 'ok', rooms: Object.keys(rooms).length, players: total, pending: pendingDonations.length}));
    } else { res.writeHead(404); res.end(); }
});

webhook.listen(WEBHOOK_PORT, '0.0.0.0', () => {
    console.log(`[WEBHOOK] Ko-fi listener on port ${WEBHOOK_PORT}`);
});

const server = net.createServer((socket) => {
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
                case "JOIN_ROOM": {
                    const code = sanitize(parts[1] || "0000", MAX_ROOM_CODE_LEN).toUpperCase();
                    socket.nickname = sanitize(parts[2] || "Player", MAX_NICK_LEN);
                    if (!code || !socket.nickname) break;
                    socket.roomCode = code;
                    if (!rooms[code]) {
                        rooms[code] = { players: [], gameStarted: false, seed: Math.floor(Math.random() * 999999), gameId: 'flockfall', gameMode: 0, gameState: null };
                    }
                    if (rooms[code].players.length >= 6) { socket.write("ROOM_FULL\n"); break; }
                    rooms[code].players.push(socket);
                    broadcastToRoom(code, `CHAT:${socket.nickname} JOINED!`);
                    sendPlayerList(code);
                    if (rooms[code].gameStarted) socket.write("GAME_ALREADY_STARTED\n");
                    else socket.write("WAITING_FOR_HOST\n");
                    break;
                }
                case "START_GAME": {
                    if (!socket.roomCode || !rooms[socket.roomCode]) break;
                    const room = rooms[socket.roomCode];
                    room.gameStarted = true;
                    room.seed = Math.floor(Math.random() * 999999);
                    const nicks = room.players.map(p => p.nickname);
                    const gameId = sanitize(parts[1] || room.gameId || 'flockfall', 20);
                    const mode = parseInt(parts[2]) || room.gameMode || 0;
                    room.gameId = gameId;
                    room.gameMode = mode;
                    room.gameState = createGameState(gameId, mode, room.seed, nicks);
                    broadcastToRoom(socket.roomCode, `START:${room.seed}:${socket.nickname}:${gameId}:${mode}`);
                    break;
                }
                case "GAME_SELECT": {
                    if (!socket.roomCode || !rooms[socket.roomCode]) break;
                    const selectedGame = sanitize(parts[1] || "flockfall", 20);
                    const selectedMode = parseInt(parts[2]) || 0;
                    rooms[socket.roomCode].gameId = selectedGame;
                    rooms[socket.roomCode].gameMode = selectedMode;
                    broadcastToRoom(socket.roomCode, `GAME_AND_MODE_CHANGED:${selectedGame}:${selectedMode}`);
                    break;
                }
                case "INPUT": {
                    if (!socket.roomCode || !rooms[socket.roomCode]) break;
                    const room = rooms[socket.roomCode];
                    if (!room.gameState || !room.gameState.players[socket.nickname]) break;
                    const player = room.gameState.players[socket.nickname];
                    const inputType = parts[1];
                    switch (inputType) {
                        case 'JUMP': player.inputs.jump = true; break;
                        case 'LEFT': player.inputs.left = parts[2] === '1'; break;
                        case 'RIGHT': player.inputs.right = parts[2] === '1'; break;
                        case 'UP': player.inputs.up = parts[2] === '1'; break;
                        case 'DOWN': player.inputs.down = parts[2] === '1'; break;
                        case 'DASH': player.inputs.dash = true; break;
                        case 'LAUNCH':
                            player.inputs.launch = true;
                            player.inputs.launchDx = parseFloat(parts[2]) || 0;
                            player.inputs.launchDy = parseFloat(parts[3]) || 0;
                            break;
                    }
                    break;
                }
                case "VERIFY_DONATION": {
                    const nick = sanitize(parts[1] || "", MAX_NICK_LEN);
                    const packId = sanitize(parts[2] || "", 10);
                    const coins = claimDonation(nick, packId);
                    socket.write(coins ? "VERIFY_SUCCESS\n" : "VERIFY_FAIL\n");
                    break;
                }
                case "SUBMIT_SCORE": {
                    const submitted = parseInt(parts[1]) || 0;
                    if (submitted < 0 || submitted > 99999) break;
                    leaderboard.push({ name: socket.nickname, score: submitted });
                    saveLeaderboard();
                    break;
                }
                case "GET_LEADERBOARD":
                    socket.write("LEADERBOARD:" + JSON.stringify(leaderboard) + "\n");
                    break;
                case "GET_STATUS": {
                    let total = 0;
                    for (let r in rooms) total += rooms[r].players.length;
                    socket.write(`STATUS:${total}:${Object.keys(rooms).length}\n`);
                    break;
                }
                case "REDEEM_CODE": {
                    const codeStr = (parts[1] || "").toUpperCase().trim();
                    const result = redeemCode(socket.nickname, codeStr);
                    if (result.ok) {
                        socket.write("CODE_SUCCESS:" + JSON.stringify(result.reward) + "\n");
                    } else {
                        socket.write("CODE_FAIL:" + result.reason + "\n");
                    }
                    break;
                }
                case "NUKE_SERVER":
                    if (parts[1] !== ADMIN_KEY) break;
                    broadcastToRoom(socket.roomCode, "CHAT:SERVER REBOOTING...");
                    setTimeout(() => { process.exit(0); }, 500);
                    break;
                case "CHAT":
                    if (socket.roomCode) broadcastToRoom(socket.roomCode, `CHAT:${sanitize(parts.slice(1).join(':'), 100)}:${socket.nickname}`, socket);
                    break;
                case "SKIN":
                    if (socket.roomCode) broadcastToRoom(socket.roomCode, `SKIN:${sanitize(parts[1] || '', 20)}:${socket.nickname}`, socket);
                    break;
                case "EMOTE":
                    if (socket.roomCode) broadcastToRoom(socket.roomCode, `EMOTE:${sanitize(parts[1] || '', 20)}:${socket.nickname}`, socket);
                    break;
                default:
                    if (socket.roomCode && rooms[socket.roomCode]) {
                        broadcastToRoom(socket.roomCode, `${msg}:${socket.nickname}`, socket);
                    }
                    break;
            }
        }
    });

    socket.on('error', () => {});

    socket.on('close', () => {
        if (socket.roomCode && rooms[socket.roomCode]) {
            rooms[socket.roomCode].players = rooms[socket.roomCode].players.filter(p => p !== socket);
            broadcastToRoom(socket.roomCode, `CHAT:${socket.nickname} DISCONNECTED`);
            if (rooms[socket.roomCode].gameState && rooms[socket.roomCode].gameState.players[socket.nickname]) {
                rooms[socket.roomCode].gameState.players[socket.nickname].alive = false;
            }
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

startGameLoop();

server.listen(PORT, '0.0.0.0', () => {
    console.log("-----------------------------------------");
    console.log(`JUSTY'S PARTY PACK SERVER - PORT ${PORT}`);
    console.log(`TICK RATE: ${TICK_RATE}Hz (${TICK_MS}ms)`);
    console.log(`SERVER-AUTHORITATIVE MODE`);
    console.log("-----------------------------------------");
});
