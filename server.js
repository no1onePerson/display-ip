import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { isIP } from 'node:net';

export function addressInfo(address = '') {
  const ip = address.replace(/^::ffff:/, '');
  return { ip, version: isIP(ip) === 6 ? 'IPv6' : 'IPv4', local: ip === '::1' || ip.startsWith('127.') || ip.startsWith('192.168.') || ip.startsWith('10.') || /^172\.(1[6-9]|2\d|3[01])\./.test(ip) };
}

export const server = http.createServer(async (req, res) => {
  const path = new URL(req.url, 'http://localhost').pathname;
  res.setHeader('X-Content-Type-Options', 'nosniff');
  if (path === '/api/connection') {
    res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
    // Use the socket address; untrusted forwarded headers must not override it.
    return res.end(JSON.stringify(addressInfo(req.socket.remoteAddress)));
  }
  const files = { '/': ['index.html', 'text/html'], '/app.js': ['app.js', 'text/javascript'], '/style.css': ['style.css', 'text/css'] };
  if (!files[path]) { res.writeHead(404); return res.end('Not found'); }
  try {
    const [file, type] = files[path];
    const body = await readFile(new URL(`./public/${file}`, import.meta.url));
    res.writeHead(200, { 'Content-Type': `${type}; charset=utf-8` });
    res.end(body);
  } catch { res.writeHead(500); res.end('Unable to load application'); }
});
if (process.argv[1] === fileURLToPath(import.meta.url)) server.listen(Number(process.env.PORT || 3000), '0.0.0.0', () => console.log('Display IP listening on port ' + (process.env.PORT || 3000)));
