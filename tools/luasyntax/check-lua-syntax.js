// Syntax-check every .lua file in the mod with a real Lua parser (luaparse).
// Usage: node check-lua-syntax.js [rootDir]
// Exit code 0 = all files parse, 1 = at least one syntax error.
const fs = require('fs');
const path = require('path');
const luaparse = require('luaparse');

const root = process.argv[2] || path.resolve(__dirname, '..', '..');
const skipDirs = new Set(['node_modules', '.npm-cache', 'artifacts']);
const files = [];

(function walk(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        if (entry.isDirectory()) {
            if (skipDirs.has(entry.name)) continue;
            walk(path.join(dir, entry.name));
        } else if (entry.name.toLowerCase().endsWith('.lua')) {
            files.push(path.join(dir, entry.name));
        }
    }
})(root);

let bad = 0;
for (const file of files) {
    const src = fs.readFileSync(file, 'utf8');
    try {
        luaparse.parse(src, { luaVersion: '5.3' });
    } catch (err) {
        bad++;
        const rel = path.relative(root, file);
        console.log(`SYNTAX ERROR: ${rel}:${err.line}:${err.column}: ${err.message}`);
    }
}
console.log(`checked ${files.length} lua files, ${bad} with syntax errors`);
process.exit(bad > 0 ? 1 : 0);
