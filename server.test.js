import { test } from 'node:test';
import assert from 'node:assert/strict';
import { server } from './server.js';

test('serves the application and reports the socket IP without trusting spoofed headers', async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    const base = `http://127.0.0.1:${server.address().port}`;
    const page = await fetch(base);
    assert.equal(page.status, 200);
    assert.match(await page.text(), /Your place on/);
    const connection = await fetch(`${base}/api/connection`, { headers: { 'X-Forwarded-For': '8.8.8.8' } });
    assert.deepEqual(await connection.json(), { ip: '127.0.0.1', version: 'IPv4', local: true });
    for (const asset of ['app.js', 'style.css']) assert.equal((await fetch(`${base}/${asset}`)).status, 200);
    assert.equal((await fetch(`${base}/missing`)).status, 404);
  } finally { await new Promise(resolve => server.close(resolve)); }
});
