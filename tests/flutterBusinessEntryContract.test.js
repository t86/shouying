'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '..');

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

test('Vue defines the booking, ordering, and cashier entry contract', () => {
  const register = read('src/views/Register/register.vue');
  const login = read('src/views/Thelogin/Thelogin.vue');
  const datasetConfig = read('src/utils/config/card.js');

  for (const [client, accessMode, route] of [
    ['book', 2, '/cardMachine'],
    ['order', 4, '/orderCard'],
    ['money', 8, '/moneyCard'],
  ]) {
    assert.match(
      register,
      new RegExp(`client:\\s*["']${client}["'][\\s\\S]{0,160}?code:\\s*["'][A-Za-z0-9_-]{3,128}["']`),
      `${client} must retain a development terminal code without exposing it in migration output`,
    );
    assert.match(login, new RegExp(`${accessMode}:\\s*["']${client}["']`));
    assert.match(
      login,
      new RegExp(`name:\\s*["']${client}["'][\\s\\S]{0,180}?url:\\s*["']${route}["']`),
    );
  }
  assert.match(login, /client_name:\s*this\.clientName/);

  for (const [index, name] of [
    [0, 'areaInfo'],
    [1, 'cardInfo'],
    [14, 'businessData'],
    [18, 'storeStatusInfo'],
  ]) {
    assert.match(
      datasetConfig,
      new RegExp(`['"]${name}['"][^\\n]*//\\s*${index}-`),
    );
  }
});

test('Flutter exposes the same business-system mapping as executable code', () => {
  const contractPath = path.join(
    root,
    'flutter_workspace/packages/session/lib/src/business_system.dart',
  );
  assert.equal(fs.existsSync(contractPath), true, 'business_system.dart must exist');
  const source = fs.readFileSync(contractPath, 'utf8');
  for (const [name, clientKind, route] of [
    ['booking', 'ClientKind.booking', '/cardMachine'],
    ['order', 'ClientKind.order', '/orderCard'],
    ['cashier', 'ClientKind.cashier', '/moneyCard'],
  ]) {
    assert.match(
      source,
      new RegExp(`${name}\\([\\s\\S]{0,180}?client:\\s*${clientKind}[\\s\\S]{0,180}?landingPath:\\s*'${route}'`),
    );
  }
});
