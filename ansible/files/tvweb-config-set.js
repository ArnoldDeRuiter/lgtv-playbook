// Sets one top-level key (value as JSON on stdin) in Glasshouse's config.json, leaves the rest alone; prints CHANGED when it wrote.
var fs = require('fs');
var path = '/var/lib/tvweb/config.json';
var key = process.argv[2];
var value = JSON.parse(fs.readFileSync('/dev/stdin', 'utf8'));
var config = JSON.parse(fs.readFileSync(path, 'utf8'));
// Key order ignored so a reordered but equal value is not a change.
function canon(v) {
  if (Array.isArray(v)) return '[' + v.map(canon).join(',') + ']';
  if (v && typeof v === 'object') return '{' + Object.keys(v).sort().map(function (k) { return JSON.stringify(k) + ':' + canon(v[k]); }).join(',') + '}';
  return JSON.stringify(v);
}
if (canon(config[key]) === canon(value)) process.exit(0);
config[key] = value;
fs.writeFileSync(path + '.tmp', JSON.stringify(config, null, 2), { mode: 384 });
fs.renameSync(path + '.tmp', path);
console.log('CHANGED');
