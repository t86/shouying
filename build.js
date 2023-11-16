const { version } = require('./package.json')
const fs = require('fs');

fs.writeFileSync('./dist/version.json', JSON.stringify({ version }))