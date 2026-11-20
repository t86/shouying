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

function proxyHttp(request, response, target, { body } = {}) {
  const client = target.protocol === 'https:' ? https : http;
  const headers = requestHeaders(request.headers, target);
  if (body != null) {
    headers['content-length'] = String(body.length);
    headers['content-type'] = 'application/json';
    delete headers['transfer-encoding'];
  }
  const upstream = client.request({
    protocol: target.protocol,
    hostname: target.hostname,
    port: target.port || undefined,
    method: request.method,
    path: request.url,
    headers,
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
  if (body == null) {
    request.pipe(upstream);
  } else {
    request.resume();
    upstream.end(body);
  }
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

async function proxyDevelopmentAuthorization(
  request,
  response,
  target,
  developmentMachineCodes,
) {
  const chunks = [];
  let bytes = 0;
  try {
    for await (const chunk of request) {
      bytes += chunk.length;
      if (bytes > 8192) throw constProxyInputError;
      chunks.push(chunk);
    }
    const payload = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    const placeholder = payload?.code;
    const match = typeof placeholder === 'string'
      ? placeholder.match(/^loopback-development-([A-Za-z_]+)$/)
      : null;
    if (match == null || !developmentClients.includes(match[1])) {
      throw constProxyInputError;
    }
    const machineCode = developmentMachineCodes[match[1]];
    proxyHttp(request, response, target, {
      body: Buffer.from(JSON.stringify({ code: machineCode })),
    });
  } catch {
    if (!response.headersSent) {
      response.writeHead(400, {
        'content-type': 'text/plain; charset=utf-8',
      });
    }
    response.end('development authorization request is invalid');
  }
}

const constProxyInputError = Object.freeze({});

function createDevelopmentProxy({
  listenHost,
  listenPort,
  flutterOrigin,
  apiOrigin,
  onlineOrigin,
  websocketOrigin,
  developmentMachineCodes,
}) {
  if (!loopbackHosts.has(listenHost)) {
    throw new TypeError('development proxy must bind to a loopback host');
  }
  if (!Number.isInteger(listenPort) || listenPort < 0 || listenPort > 65535) {
    throw new TypeError('development proxy port is invalid');
  }
  const requiredClients = developmentClients;
  if (
    developmentMachineCodes == null ||
    typeof developmentMachineCodes !== 'object' ||
    Object.keys(developmentMachineCodes).sort().join(',') !==
        [...requiredClients].sort().join(',') ||
    requiredClients.some(
      (client) =>
        !/^[A-Za-z0-9_-]{3,128}$/.test(developmentMachineCodes[client]),
    ) ||
    new Set(requiredClients.map((client) => developmentMachineCodes[client]))
          .size !== requiredClients.length
  ) {
    throw new TypeError('development machine codes are invalid');
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

  const trustedServiceRequest = (request) => {
    const source = request.headers.origin ?? request.headers.referer;
    if (source == null) return true;
    let sourceOrigin;
    try {
      sourceOrigin = new URL(source).origin;
    } catch {
      return false;
    }
    const address = server.address();
    if (!address || typeof address === 'string') return false;
    return sourceOrigin === `http://${listenHost}:${address.port}`;
  };

  const rejectServiceRequest = (request, response) => {
    request.resume();
    response.writeHead(403, {
      'content-type': 'text/plain; charset=utf-8',
    });
    response.end('development proxy origin rejected');
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
      if (!trustedServiceRequest(request)) {
        rejectServiceRequest(request, response);
        return;
      }
      request.url = stripPrefix(request.url, '/api');
      proxyHttp(request, response, targets.api);
      return;
    }
    if (request.url?.startsWith('/dev-api/')) {
      if (!trustedServiceRequest(request)) {
        rejectServiceRequest(request, response);
        return;
      }
      request.url = stripPrefix(request.url, '/dev-api');
      if (
        request.method === 'POST' &&
        request.url === '/server/term/auth'
      ) {
        void proxyDevelopmentAuthorization(
          request,
          response,
          targets.api,
          developmentMachineCodes,
        );
        return;
      }
      proxyHttp(request, response, targets.api);
      return;
    }
    if (request.url?.startsWith('/online/')) {
      if (!trustedServiceRequest(request)) {
        rejectServiceRequest(request, response);
        return;
      }
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
    if (!trustedServiceRequest(request)) {
      socket.end(
        'HTTP/1.1 403 Forbidden\r\n' +
        'Connection: close\r\n' +
        'Content-Length: 0\r\n\r\n',
      );
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

const developmentClients = Object.freeze([
  'org_mgr', 'book', 'order', 'money', 'vip', 'erp', 'erpAdmin', 'wine', 'queuedsp',
]);

module.exports = { createDevelopmentProxy, developmentClients };
