const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const www = path.join(root, 'www');
const files = ['index.html', 'ziwei-mingpan.html', 'manifest.json', 'sw.js'];

fs.mkdirSync(www, { recursive: true });
files.forEach(file => {
  fs.copyFileSync(path.join(root, file), path.join(www, file));
});

const assetsSrc = path.join(root, 'assets');
const assetsDst = path.join(www, 'assets');
fs.rmSync(assetsDst, { recursive: true, force: true });
fs.cpSync(assetsSrc, assetsDst, { recursive: true });

console.log('Synced web assets to www/');
