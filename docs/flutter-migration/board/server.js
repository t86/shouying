#!/usr/bin/env node
/**
 * Flutter 移植看板服务：改状态立刻写 tasks.json + BOARD.md。
 *   node docs/flutter-migration/board/server.js
 *   BOARD_PORT=8791 node docs/flutter-migration/board/server.js
 */
'use strict';

const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { URL } = require('node:url');

const {
  JSON_PATH,
  MD_PATH,
  HTML_PATH,
  loadBoard,
  applyStatusChange,
  parseBoardMd,
  payload,
  writeOutputs,
  countByStatus,
} = require('./sync-board.js');

const DEFAULT_PORT = Number(process.env.BOARD_PORT || 8791);
const HOST = process.env.BOARD_HOST || '127.0.0.1';

function json(res, code, body) {
  const text = JSON.stringify(body);
  res.writeHead(code, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'Content-Length': Buffer.byteLength(text),
  });
  res.end(text);
}

function sendFile(res, filePath, type) {
  const buf = fs.readFileSync(filePath);
  res.writeHead(200, {
    'Content-Type': type,
    'Cache-Control': 'no-store',
    'Content-Length': buf.length,
  });
  res.end(buf);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', (c) => {
      size += c.length;
      if (size > 1024 * 1024) {
        reject(new Error('body too large'));
        req.destroy();
        return;
      }
      chunks.push(c);
    });
    req.on('end', () => {
      const raw = Buffer.concat(chunks).toString('utf8');
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch (err) {
        reject(err);
      }
    });
    req.on('error', reject);
  });
}

function createBoardServer() {
  const clients = new Set();
  let lastMarkdown = '';
  let writing = false;

  function broadcast(board) {
    const payloadText = `data: ${JSON.stringify({ type: 'board', board })}\n\n`;
    for (const res of clients) {
      try {
        res.write(payloadText);
      } catch {
        clients.delete(res);
      }
    }
  }

  function applyAndBroadcast(id, status, opts) {
    writing = true;
    try {
      const result = applyStatusChange(id, status, opts);
      if (result.changed) {
        lastMarkdown = fs.readFileSync(MD_PATH, 'utf8');
        broadcast(result.board);
      }
      return result;
    } finally {
      writing = false;
    }
  }

  const server = http.createServer(async (req, res) => {
    const url = new URL(req.url, `http://${HOST}`);
    try {
      if (req.method === 'GET' && url.pathname === '/api/health') {
        const board = loadBoard();
        json(res, 200, {
          ok: true,
          host: HOST,
          port: server.address()?.port || DEFAULT_PORT,
          counts: countByStatus(board.tasks || []),
          updated: board.updated,
        });
        return;
      }
      if (req.method === 'GET' && url.pathname === '/api/board') {
        json(res, 200, loadBoard());
        return;
      }
      if (req.method === 'GET' && url.pathname === '/api/events') {
        res.writeHead(200, {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          Connection: 'keep-alive',
        });
        res.write(`data: ${JSON.stringify({ type: 'board', board: loadBoard() })}\n\n`);
        clients.add(res);
        req.on('close', () => clients.delete(res));
        return;
      }
      if (req.method === 'POST' && url.pathname === '/api/status') {
        const body = await readBody(req);
        const result = applyAndBroadcast(body.id, body.status, {
          allowConfirm: Boolean(body.confirmByUser),
          actor: body.confirmByUser ? 'user' : 'ui',
        });
        json(res, 200, result);
        return;
      }
      if (req.method === 'GET' && (url.pathname === '/' || url.pathname === '/index.html')) {
        sendFile(res, HTML_PATH, 'text/html; charset=utf-8');
        return;
      }
      if (req.method === 'GET' && url.pathname === '/tasks.json') {
        sendFile(res, JSON_PATH, 'application/json; charset=utf-8');
        return;
      }
      json(res, 404, { error: 'not found' });
    } catch (err) {
      const code =
        err.code === 'NOT_FOUND'
          ? 404
          : err.code === 'CONFIRM_FORBIDDEN' || err.code === 'INVALID_STATUS'
            ? 409
            : 400;
      json(res, code, { error: err.message, code: err.code || 'ERROR' });
    }
  });

  function watchMarkdown() {
    lastMarkdown = fs.readFileSync(MD_PATH, 'utf8');
    let timer;
    const watcher = fs.watch(MD_PATH, () => {
      if (writing) return;
      clearTimeout(timer);
      timer = setTimeout(() => {
        try {
          const markdown = fs.readFileSync(MD_PATH, 'utf8');
          if (markdown === lastMarkdown) return;
          const tasks = parseBoardMd(markdown);
          if (!tasks.length) return;
          writing = true;
          const next = payload(tasks);
          writeOutputs(next);
          lastMarkdown = fs.readFileSync(MD_PATH, 'utf8');
          broadcast(next);
        } catch (err) {
          process.stderr.write(`board md watch failed: ${err.message}\n`);
        } finally {
          writing = false;
        }
      }, 250);
    });
    watcher.unref();
    server.on('close', () => {
      clearTimeout(timer);
      watcher.close();
    });
  }

  server.on('listening', () => {
    try {
      watchMarkdown();
    } catch (err) {
      process.stderr.write(`board watch skipped: ${err.message}\n`);
    }
  });

  return { server, clients, applyAndBroadcast };
}

function main() {
  const { server } = createBoardServer();
  server.listen(DEFAULT_PORT, HOST, () => {
    const addr = server.address();
    process.stdout.write(
      `Flutter 移植看板服务 http://${HOST}:${addr.port}/\n` +
        `改状态会写入 ${path.relative(process.cwd(), JSON_PATH)} 与 ${path.relative(process.cwd(), MD_PATH)}\n`,
    );
  });
}

module.exports = { createBoardServer, HOST, DEFAULT_PORT };

if (require.main === module) {
  main();
}
