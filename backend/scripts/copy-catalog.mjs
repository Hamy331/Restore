import { mkdir, copyFile } from 'node:fs/promises';
await mkdir('dist/modules/catalog', { recursive: true });
await copyFile('src/modules/catalog/catalog.json', 'dist/modules/catalog/catalog.json');
