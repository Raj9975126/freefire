// server.js - simple GPS battle royale backend
const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// In‑memory game state
let players = {};
let matchActive = false;
let matchTimer = null;
const MATCH_DURATION_MS = 10 * 60 * 1000; // 10 minutes for demo
const SHOOT_RANGE_METERS = 30; // distance needed to shoot

function distance(lat1, lon1, lat2, lon2) {
  const toRad = Math.PI / 180;
  const R = 6371000; // metres
  const dLat = (lat2 - lat1) * toRad;
  const dLon = (lon2 - lon1) * toRad;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * toRad) * Math.cos(lat2 * toRad) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

io.on('connection', (socket) => {
  console.log('client connected', socket.id);

  // player joins lobby
  socket.on('join', ({ playerId, name }) => {
    players[playerId] = {
      id: playerId,
      name: name || 'Anon',
      socketId: socket.id,
      lat: null,
      lng: null,
      health: 100,
      alive: true
    };
    socket.emit('joined', { success: true });
    io.emit('players_update', Object.values(players));
  });

  // location updates (sent every ~5 s from client)
  socket.on('location', ({ playerId, lat, lng }) => {
    const p = players[playerId];
    if (p) {
      p.lat = lat; p.lng = lng;
      io.emit('players_update', Object.values(players));
    }
  });

  // shooting action
  socket.on('shoot', ({ shooterId, targetId }) => {
    const shooter = players[shooterId];
    const target = players[targetId];
    if (!shooter?.alive || !target?.alive) return;
    if (shooter.lat == null || shooter.lng == null) return;
    if (target.lat == null || target.lng == null) return;
    const d = distance(shooter.lat, shooter.lng, target.lat, target.lng);
    if (d <= SHOOT_RANGE_METERS) {
      target.health -= 34; // simple damage
      if (target.health <= 0) {
        target.alive = false;
        io.to(target.socketId).emit('killed', { by: shooterId });
      }
      io.emit('players_update', Object.values(players));
    } else {
      socket.emit('shoot_failed', { reason: 'out_of_range', distance: d });
    }
  });

  socket.on('start_match', () => {
    if (matchActive) return;
    matchActive = true;
    io.emit('match_started');
    matchTimer = setTimeout(() => {
      matchActive = false;
      io.emit('match_ended');
      // reset state for next match
      players = {};
    }, MATCH_DURATION_MS);
  });

  socket.on('disconnect', () => {
    // remove player by socketId
    const removed = Object.values(players).find(p => p.socketId === socket.id);
    if (removed) {
      delete players[removed.id];
      io.emit('players_update', Object.values(players));
    }
    console.log('client disconnected', socket.id);
  });
});

// health check route
app.get('/status', (req, res) => res.json({ ok: true, players: Object.keys(players).length }));

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Backend listening on http://localhost:${PORT}`));
