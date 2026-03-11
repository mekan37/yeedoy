const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');

const port = Number(process.env.PANEL_SMOKE_PORT ?? 43101);
const rootDir = path.resolve(__dirname, '..', 'build', 'web');
const indexPath = path.join(rootDir, 'index.html');

const contentTypes = new Map([
  ['.html', 'text/html; charset=utf-8'],
  ['.js', 'application/javascript; charset=utf-8'],
  ['.mjs', 'application/javascript; charset=utf-8'],
  ['.css', 'text/css; charset=utf-8'],
  ['.json', 'application/json; charset=utf-8'],
  ['.png', 'image/png'],
  ['.jpg', 'image/jpeg'],
  ['.jpeg', 'image/jpeg'],
  ['.svg', 'image/svg+xml'],
  ['.wasm', 'application/wasm'],
  ['.ttf', 'font/ttf'],
  ['.otf', 'font/otf'],
  ['.ico', 'image/x-icon'],
  ['.txt', 'text/plain; charset=utf-8'],
]);

function resolvePath(urlPath) {
  const decodedPath = decodeURIComponent(urlPath.split('?')[0]);
  const relativePath = decodedPath === '/' ? '/index.html' : decodedPath;
  const requestedPath = path.normalize(path.join(rootDir, relativePath));
  if (!requestedPath.startsWith(rootDir)) {
    return null;
  }
  if (fs.existsSync(requestedPath) && fs.statSync(requestedPath).isFile()) {
    return requestedPath;
  }
  return indexPath;
}

const server = http.createServer((req, res) => {
  const filePath = resolvePath(req.url || '/');
  if (!filePath) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.readFile(filePath, (error, data) => {
    if (error) {
      res.writeHead(500);
      res.end('Server error');
      return;
    }

    const extension = path.extname(filePath).toLowerCase();
    const contentType =
      contentTypes.get(extension) || 'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': contentType,
      'Cache-Control': 'no-store',
    });
    res.end(data);
  });
});

server.listen(port, '127.0.0.1', () => {
  console.log(`panel smoke server listening on http://127.0.0.1:${port}`);
});
