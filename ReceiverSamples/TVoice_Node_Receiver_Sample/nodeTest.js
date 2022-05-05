import WebSocket from 'ws';

const ws = new WebSocket('ws://10.0.1.108:8092');

ws.on('open', function open() {
  ws.send('something');
  console.log("open connection");
});

ws.on('message', function message(data) {
  console.log('received: %s', data);
});
