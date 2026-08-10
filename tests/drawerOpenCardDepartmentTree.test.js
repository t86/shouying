const assert = require('assert');
const fs = require('fs');
const path = require('path');
const test = require('node:test');

function loadListToTreeMethod() {
  const componentPath = path.join(
    __dirname,
    '../src/components/book/machine/drawerOpenCard.vue'
  );
  const source = fs.readFileSync(componentPath, 'utf8');
  const methodStart = source.indexOf('listToTree (newList)');

  assert.notStrictEqual(methodStart, -1, 'drawerOpenCard should define listToTree');

  const bodyStart = source.indexOf('{', methodStart);
  let depth = 0;
  let bodyEnd = -1;

  for (let index = bodyStart; index < source.length; index += 1) {
    if (source[index] === '{') depth += 1;
    if (source[index] === '}') depth -= 1;
    if (depth === 0) {
      bodyEnd = index;
      break;
    }
  }

  assert.notStrictEqual(bodyEnd, -1, 'listToTree method should have a complete body');

  const body = source.slice(bodyStart, bodyEnd + 1);
  return Function(`return function listToTree(newList) ${body}`)();
}

test('shows second- and third-level departments regardless of websocket list order', () => {
  const listToTree = loadListToTreeMethod();
  const departments = [
    { id: '0', name: '不限', parentId: 0 },
    { id: '231591502411073', name: '营销部', parentId: '0' },
    { id: '232871404508425', name: '猛虎团', parentId: '231591502411073' },
    { id: '242332115427070', name: '猛虎A', parentId: '232871404508425' },
  ];

  const tree = listToTree(departments);
  const marketingDepartment = tree.find(item => item.name === '营销部');

  assert.deepStrictEqual(
    marketingDepartment.children[0].children.map(item => item.name),
    ['猛虎A']
  );
});
