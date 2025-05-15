const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);

  socket.on('join', (roomId) => {
    socket.join(roomId);
    socket.to(roomId).emit('peer-joined', socket.id);
    console.log(`User ${socket.id} joined room ${roomId}`);
  });

  socket.on('offer', (data) => {
    socket.to(data.roomId).emit('offer', { sdp: data.sdp, from: socket.id });
  });

  socket.on('answer', (data) => {
    socket.to(data.roomId).emit('answer', { sdp: data.sdp, from: socket.id });
  });

  socket.on('candidate', (data) => {
    socket.to(data.roomId).emit('candidate', { candidate: data.candidate, from: socket.id });
  });

  socket.on('leave', (roomId) => {
    socket.leave(roomId);
    socket.to(roomId).emit('peer-left', socket.id);
    console.log(`User ${socket.id} left room ${roomId}`);
  });

  socket.on('disconnect', () => {
    console.log('A user disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Signaling server listening on port ${PORT}`);
}); 