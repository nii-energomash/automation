// источник: nii-energomash/automation/project/npm/scripts/check-lockfile-resolved.mjs
// место: scripts/check-lockfile-resolved.mjs

// Сторож при package-lock.json: падает, если реестровой зависимости вернулся
// ключ resolved — адрес тарбола в конкретном реестре, из-за которого лок
// перестаёт работать на второй площадке.
//
// Только проверяет, ничего не правит: вешается на postinstall, а тот
// выполняется и при npm ci, где лок трогать нельзя.
//
// Признак реестровой зависимости — resolved по http(s) вместе с integrity.
// У git- и tarball-зависимостей resolved законный, и они под проверку
// не попадают.

import { readFile } from 'node:fs/promises';

const LOCKFILE = 'package-lock.json';

const collect = (node, path, found) => {
  if (node === null || typeof node !== 'object') {
    return;
  }

  if (Array.isArray(node)) {
    node.forEach((item, index) => collect(item, `${path}[${index}]`, found));
    return;
  }

  const { resolved, integrity } = node;
  if (
    typeof resolved === 'string' &&
    typeof integrity === 'string' &&
    /^https?:\/\//.test(resolved)
  ) {
    found.push({ path, resolved });
  }

  for (const [key, value] of Object.entries(node)) {
    collect(value, path === '' ? key : `${path} > ${key}`, found);
  }
};

let lockfile;
try {
  lockfile = JSON.parse(await readFile(LOCKFILE, 'utf8'));
} catch (error) {
  if (error.code === 'ENOENT') {
    process.exit(0);
  }
  throw error;
}

const found = [];
collect(lockfile, '', found);

if (found.length === 0) {
  process.exit(0);
}

console.error(`${LOCKFILE}: ключ resolved остался у зависимостей:`);
for (const { path, resolved } of found) {
  console.error(`  ${path}`);
  console.error(`    ${resolved}`);
}
console.error('');
console.error('Лок с адресами реестра не переезжает на вторую площадку.');
console.error('Починить:');
console.error('  1. в .npmrc: omit-lockfile-registry-resolved=true');
console.error('  2. npm install --package-lock-only');
console.error('  3. закоммитить package-lock.json');

process.exitCode = 1;
