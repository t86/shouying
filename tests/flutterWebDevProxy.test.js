'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const test = require('node:test');

const {
  createDevelopmentProxy,
} = require('../flutter_workspace/tool/web_dev_proxy');
const {
  buildFlutterArguments,
  developmentTargets,
} = require('../flutter_workspace/tool/web_dev_runner');

function listen(server) {
  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => {
      server.off('error', reject);
      const { port } = server.address();
      resolve(`http://127.0.0.1:${port}`);
    });
  });
}

function close(server) {
  return new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
}

function request(origin, path, headers = {}) {
  return new Promise((resolve, reject) => {
    const request = http.get(`${origin}${path}`, { headers }, (response) => {
      const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => resolve({
        statusCode: response.statusCode,
        body: Buffer.concat(chunks).toString('utf8'),
      }));
    });
    request.once('error', reject);
  });
}

function upgrade(origin, requestPath) {
  return new Promise((resolve, reject) => {
    const target = new URL(origin);
    const request = http.request({
      host: target.hostname,
      port: target.port,
      path: requestPath,
      headers: {
        connection: 'Upgrade',
        upgrade: 'websocket',
        authorization: 'Bearer test-value',
        'proxy-authorization': 'Basic proxy-value',
        'sec-websocket-key': 'dGhlIHNhbXBsZSBub25jZQ==',
        'sec-websocket-version': '13',
      },
    });
    request.once('upgrade', (response, socket) => {
      socket.destroy();
      resolve(response.statusCode);
    });
    request.once('response', (response) => {
      response.resume();
      reject(new Error(`unexpected response ${response.statusCode}`));
    });
    request.once('error', reject);
    request.end();
  });
}

test('loopback development proxy preserves original service paths', async (t) => {
  const received = [];
  const flutterServer = http.createServer((request, response) => {
    received.push(['flutter', request.url]);
    response.end('flutter-shell');
  });
  const apiServer = http.createServer((request, response) => {
    received.push([
      'api',
      request.url,
      request.headers.authorization,
      request.headers['proxy-authorization'],
    ]);
    response.end('api-ok');
  });
  const onlineServer = http.createServer((request, response) => {
    received.push(['online', request.url]);
    response.end('online-ok');
  });
  const websocketHttpServer = http.createServer();
  websocketHttpServer.on('upgrade', (request, socket) => {
    received.push([
      'websocket',
      request.url,
      request.headers.authorization,
      request.headers['proxy-authorization'],
    ]);
    socket.end(
      'HTTP/1.1 101 Switching Protocols\r\n' +
      'Connection: Upgrade\r\n' +
      'Upgrade: websocket\r\n\r\n',
    );
  });

  const flutterOrigin = await listen(flutterServer);
  const apiOrigin = await listen(apiServer);
  const onlineOrigin = await listen(onlineServer);
  const websocketHttpOrigin = await listen(websocketHttpServer);
  const websocketOrigin = websocketHttpOrigin.replace(/^http:/, 'ws:');
  const proxy = createDevelopmentProxy({
    listenHost: '127.0.0.1',
    listenPort: 0,
    flutterOrigin,
    apiOrigin,
    onlineOrigin,
    websocketOrigin,
  });
  await proxy.listen();
  t.after(async () => {
    await proxy.close();
    await Promise.all([
      close(flutterServer),
      close(apiServer),
      close(onlineServer),
      close(websocketHttpServer),
    ]);
  });

  assert.deepEqual(await request(proxy.origin, '/main.dart.js'), {
    statusCode: 200,
    body: 'flutter-shell',
  });
  assert.deepEqual(await request(
    proxy.origin,
    '/api/server/term/auth?pt=1',
    {
      authorization: 'Bearer test-value',
      'proxy-authorization': 'Basic proxy-value',
    },
  ), {
    statusCode: 200,
    body: 'api-ok',
  });
  assert.deepEqual(await request(proxy.origin, '/online/server/sync/all'), {
    statusCode: 200,
    body: 'online-ok',
  });
  assert.deepEqual(await request(proxy.origin, '/__health'), {
    statusCode: 200,
    body: '{"status":"ok"}',
  });

  assert.equal(await upgrade(proxy.origin, '/socket/server/sync'), 101);
  assert.deepEqual(received, [
    ['flutter', '/main.dart.js'],
    ['api', '/server/term/auth?pt=1', 'Bearer test-value', undefined],
    ['online', '/server/sync/all'],
    ['websocket', '/server/sync', 'Bearer test-value', undefined],
  ]);
});

test('development proxy has no npm runtime dependency', () => {
  const source = fs.readFileSync(
    path.join(__dirname, '../flutter_workspace/tool/web_dev_proxy.js'),
    'utf8',
  );
  assert.doesNotMatch(source, /require\(['"](?:http-proxy|ws)['"]\)/);
});

test('development proxy binds only explicit loopback hosts', () => {
  assert.throws(
    () => createDevelopmentProxy({
      listenHost: '0.0.0.0',
      listenPort: 8183,
      flutterOrigin: 'http://127.0.0.1:8184',
      apiOrigin: 'http://api.example.test',
      onlineOrigin: 'https://online.example.test',
      websocketOrigin: 'ws://socket.example.test',
    }),
    /loopback/,
  );
});

test('local runner enables only the loopback debug configuration', () => {
  assert.deepEqual(buildFlutterArguments({ proxyPort: 8183, flutterPort: 8184 }), [
    'run',
    '-d',
    'web-server',
    '--debug',
    '--web-hostname',
    '127.0.0.1',
    '--web-port',
    '8184',
    '--dart-define=SHOUYIN_ALLOW_INSECURE_LOOPBACK=true',
    '--dart-define=SHOUYIN_API_BASE=http://127.0.0.1:8183/api/server',
    '--dart-define=SHOUYIN_ONLINE_BASE=http://127.0.0.1:8183/online/server',
    '--dart-define=SHOUYIN_WS_BASE=ws://127.0.0.1:8183/socket/server',
  ]);
  assert.deepEqual(developmentTargets, {
    apiOrigin: 'http://nls-dev.xmsjznwl.com',
    onlineOrigin: 'https://ncrmyun-dev.xmsjznwl.com',
    websocketOrigin: 'ws://nls-dev.xmsjznwl.com',
  });
  assert.doesNotMatch(JSON.stringify(developmentTargets), /password|credential|token/i);
});
