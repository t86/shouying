'use strict';

const path = require('node:path');
const { spawn } = require('node:child_process');
const fs = require('node:fs');

const { createDevelopmentProxy } = require('./web_dev_proxy');

const developmentTargets = Object.freeze({
  apiOrigin: 'http://nls-dev.xmsjznwl.com',
  onlineOrigin: 'https://ncrmyun-dev.xmsjznwl.com',
  websocketOrigin: 'ws://nls-dev.xmsjznwl.com',
});

function buildFlutterArguments({ proxyPort, flutterPort }) {
  const localOrigin = `127.0.0.1:${proxyPort}`;
  return [
    'run',
    '-d',
    'web-server',
    '--debug',
    '--web-hostname',
    '127.0.0.1',
    '--web-port',
    String(flutterPort),
    '--dart-define=SHOUYIN_ALLOW_INSECURE_LOOPBACK=true',
    '--dart-define=SHOUYIN_DEV_SYSTEM_SELECTION=true',
    `--dart-define=SHOUYIN_API_BASE=http://${localOrigin}/dev-api/server`,
    `--dart-define=SHOUYIN_ONLINE_BASE=http://${localOrigin}/online/server`,
    `--dart-define=SHOUYIN_WS_BASE=ws://${localOrigin}/socket/server`,
  ];
}

function extractDevelopmentMachineCodes(source) {
  const result = {};
  for (const client of ['book', 'order', 'money']) {
    const match = source.match(
      new RegExp(
        `client\\s*:\\s*['"]${client}['"][\\s\\S]{0,256}?` +
        `code\\s*:\\s*['"]([A-Za-z0-9_-]{3,128})['"]`,
      ),
    );
    if (match == null) {
      throw new Error('development terminal codes are unavailable');
    }
    result[client] = match[1];
  }
  return Object.freeze(result);
}

async function startLocalWeb({
  proxyPort = 8183,
  flutterPort = 8184,
  spawnProcess = spawn,
} = {}) {
  const workspaceRoot = path.resolve(__dirname, '..');
  const repositoryRoot = path.resolve(workspaceRoot, '..');
  const developmentMachineCodes = extractDevelopmentMachineCodes(
    fs.readFileSync(
      path.join(repositoryRoot, 'src/views/Register/register.vue'),
      'utf8',
    ),
  );
  const flutterExecutable = path.join(
    workspaceRoot,
    '.fvm/flutter_sdk/bin/flutter',
  );
  const proxy = createDevelopmentProxy({
    listenHost: '127.0.0.1',
    listenPort: proxyPort,
    flutterOrigin: `http://127.0.0.1:${flutterPort}`,
    ...developmentTargets,
    developmentMachineCodes,
  });
  await proxy.listen();
  const child = spawnProcess(
    flutterExecutable,
    buildFlutterArguments({ proxyPort, flutterPort }),
    {
      cwd: path.join(workspaceRoot, 'apps/web_app'),
      stdio: 'inherit',
    },
  );
  return { child, proxy };
}

async function runCli() {
  const { child, proxy } = await startLocalWeb();
  let closing = false;
  const close = async (signal) => {
    if (closing) return;
    closing = true;
    if (signal && child.exitCode == null) child.kill(signal);
    await proxy.close();
  };
  process.once('SIGINT', () => void close('SIGINT'));
  process.once('SIGTERM', () => void close('SIGTERM'));
  child.once('error', () => void close());
  child.once('exit', (code, signal) => {
    void close().then(() => {
      if (signal) process.kill(process.pid, signal);
      else process.exitCode = code ?? 1;
    });
  });
  process.stdout.write('Local Flutter Web: http://127.0.0.1:8183/\n');
}

if (require.main === module) {
  runCli().catch((error) => {
    const code = typeof error?.code === 'string' ? error.code : 'startup_failed';
    process.stderr.write(`Local Flutter Web failed: ${code}\n`);
    process.exitCode = 1;
  });
}

module.exports = {
  buildFlutterArguments,
  developmentTargets,
  extractDevelopmentMachineCodes,
  startLocalWeb,
};
