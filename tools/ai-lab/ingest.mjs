// Nạp mọi file Markdown trong content/ lên kệ: data/shelf.json.
import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';

import { chunkMarkdown, embed } from './shelf.mjs';

const files = (await readdir('content')).filter((f) => f.endsWith('.md'));
const shelf = [];
for (const file of files) {
  const markdown = await readFile(`content/${file}`, 'utf8');
  for (const chunk of chunkMarkdown(markdown, file.replace(/\.md$/, ''))) {
    shelf.push({ ...chunk, embedding: await embed(chunk.text) });
    console.log(`${chunk.id}  (${chunk.text.split(/\s+/).length} words)`);
  }
}
await mkdir('data', { recursive: true });
await writeFile('data/shelf.json', JSON.stringify(shelf));
console.log(`\n${shelf.length} passages on the shelf from ${files.length} file(s).`);
