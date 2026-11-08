// Sets one key (dotted path, value as JSON on stdin) in Glasshouse's config.json, leaves the rest alone; prints CHANGED when it wrote.
var fs = require('fs');
var path = '/var/lib/tvweb/config.json';
var keys = process.argv[2].split('.');
var value = JSON.parse(fs.readFileSync('/dev/stdin', 'utf8'));
var config = JSON.parse(fs.readFileSync(path, 'utf8'));
var parent = config;
for (var i = 0; i < keys.length - 1; i++) {
  if (!parent[keys[i]] || typeof parent[keys[i]] !== 'object') parent[keys[i]] = {};
  parent = parent[keys[i]];
}
var last = keys[keys.length - 1];
// Key order ignored so a reordered but equal value is not a change.
function canon(v) {
  if (Array.isArray(v)) return '[' + v.map(canon).join(',') + ']';
  if (v && typeof v === 'object') return '{' + Object.keys(v).sort().map(function (k) { return JSON.stringify(k) + ':' + canon(v[k]); }).join(',') + '}';
  return JSON.stringify(v);
}
if (canon(parent[last]) === canon(value)) process.exit(0);
parent[last] = value;
fs.writeFileSync(path + '.tmp', JSON.stringify(config, null, 2), { mode: 384 });
fs.renameSync(path + '.tmp', path);
console.log('CHANGED');
