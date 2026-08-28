'use strict';

const http = require('node:http');
const https = require('node:https');
const net = require('node:net');
const tls = require('node:tls');

const loopbackHosts = new Set(['127.0.0.1', '::1', 'localhost']);
const hopByHopHeaders = new Set([
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
]);

function validatedOrigin(raw, protocols, label) {
  const value = new URL(raw);
  if (!protocols.has(value.protocol)) {
    throw new TypeError(`${label} uses an unsupported protocol`);
  }
  if (value.username || value.password || value.search || value.hash) {
    throw new TypeError(`${label} must not contain credentials or metadata`);
  }
  if (value.pathname !== '/') {
    throw new TypeError(`${label} must be an origin without a path`);
  }
  return value;
}

function stripPrefix(url, prefix) {
  const stripped = url.slice(prefix.length);
  return stripped.startsWith('/') ? stripped : `/${stripped}`;
}

function requestHeaders(source, target, { websocket = false } = {}) {
  const headers = {};
  for (const [name, value] of Object.entries(source)) {
    const lowerName = name.toLowerCase();
    if (
      value == null ||
      lowerName === 'proxy-authorization' ||
      (!websocket && hopByHopHeaders.has(lowerName))
    ) {
      continue;
    }
    headers[name] = value;
  }
  headers.host = target.host;
  return headers;
}

function proxyHttp(request, response, target) {
  const client = target.protocol === 'https:' ? https : http;
  const upstream = client.request({
    protocol: target.protocol,
    hostname: target.hostname,
    port: target.port || undefined,
    method: request.method,
    path: request.url,
    headers: requestHeaders(request.headers, target),
  }, (upstreamResponse) => {
    response.writeHead(
      upstreamResponse.statusCode ?? 502,
      upstreamResponse.statusMessage,
      upstreamResponse.headers,
    );
    upstreamResponse.pipe(response);
  });
  upstream.once('error', () => {
    if (!response.headersSent) {
      response.writeHead(502, { 'content-type': 'text/plain; charset=utf-8' });
    }
    response.end('development proxy unavailable');
  });
  request.pipe(upstream);
}

function websocketHandshake(request, target) {
  const headers = requestHeaders(request.headers, target, { websocket: true });
  const lines = [`${request.method} ${request.url} HTTP/${request.httpVersion}`];
  for (const [name, value] of Object.entries(headers)) {
    if (Array.isArray(value)) {
      value.forEach((item) => lines.push(`${name}: ${item}`));
    } else {
      lines.push(`${name}: ${value}`);
    }
  }
  return `${lines.join('\r\n')}\r\n\r\n`;
}

function proxyWebSocket(request, clientSocket, head, target) {
  const options = {
    host: target.hostname,
    port: Number(target.port || (target.protocol === 'wss:' ? 443 : 80)),
  };
  const upstreamSocket = target.protocol === 'wss:'
    ? tls.connect({ ...options, servername: target.hostname })
    : net.connect(options);
  const fail = () => {
    upstreamSocket.destroy();
    clientSocket.destroy();
  };
  upstreamSocket.once('error', fail);
  clientSocket.once('error', fail);
  upstreamSocket.once('connect', () => {
    upstreamSocket.write(websocketHandshake(request, target));
    if (head.length > 0) upstreamSocket.write(head);
    clientSocket.pipe(upstreamSocket).pipe(clientSocket);
  });
}

function createDevelopmentProxy({
  listenHost,
  listenPort,
  flutterOrigin,
  apiOrigin,
  onlineOrigin,
  websocketOrigin,
}) {
  if (!loopbackHosts.has(listenHost)) {
    throw new TypeError('development proxy must bind to a loopback host');
  }
  if (!Number.isInteger(listenPort) || listenPort < 0 || listenPort > 65535) {
    throw new TypeError('development proxy port is invalid');
  }

  const targets = {
    flutter: validatedOrigin(
      flutterOrigin,
      new Set(['http:', 'https:']),
      'Flutter origin',
    ),
    api: validatedOrigin(
      apiOrigin,
      new Set(['http:', 'https:']),
      'API origin',
    ),
    online: validatedOrigin(
      onlineOrigin,
      new Set(['http:', 'https:']),
      'Online origin',
    ),
    websocket: validatedOrigin(
      websocketOrigin,
      new Set(['ws:', 'wss:']),
      'WebSocket origin',
    ),
  };

  const server = http.createServer((request, response) => {
    if (request.url === '/__health') {
      response.writeHead(200, {
        'cache-control': 'no-store',
        'content-type': 'application/json; charset=utf-8',
      });
      response.end('{"status":"ok"}');
      return;
    }
    if (request.url?.startsWith('/api/')) {
      request.url = stripPrefix(request.url, '/api');
      proxyHttp(request, response, targets.api);
      return;
    }
    if (request.url?.startsWith('/online/')) {
      request.url = stripPrefix(request.url, '/online');
      proxyHttp(request, response, targets.online);
      return;
    }
    proxyHttp(request, response, targets.flutter);
  });
  server.on('upgrade', (request, socket, head) => {
    if (!request.url?.startsWith('/socket/')) {
      socket.destroy();
      return;
    }
    request.url = stripPrefix(request.url, '/socket');
    proxyWebSocket(request, socket, head, targets.websocket);
  });

  return {
    get origin() {
      const address = server.address();
      if (!address || typeof address === 'string') {
        throw new Error('development proxy is not listening');
      }
      return `http://${listenHost}:${address.port}`;
    },
    listen() {
      return new Promise((resolve, reject) => {
        server.once('error', reject);
        server.listen(listenPort, listenHost, () => {
          server.off('error', reject);
          resolve();
        });
      });
    },
    close() {
      return new Promise((resolve, reject) => {
        server.closeAllConnections?.();
        server.close((error) => {
          if (error) reject(error);
          else resolve();
        });
      });
    },
  };
}

module.exports = { createDevelopmentProxy };
