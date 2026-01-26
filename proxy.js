const http = require('http');

const TARGET_HOST = '192.168.1.25';
const TARGET_PORT = 80;
const PROXY_PORT = 3000;

const server = http.createServer((clientReq, clientRes) => {
  console.log(`[${new Date().toISOString()}] ${clientReq.method} ${clientReq.url}`);

  const options = {
    hostname: TARGET_HOST,
    port: TARGET_PORT,
    path: clientReq.url,
    method: clientReq.method,
    headers: {
      ...clientReq.headers,
      host: TARGET_HOST,
    },
  };

  const proxyReq = http.request(options, (proxyRes) => {
    clientRes.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(clientRes);
  });

  proxyReq.on('error', (err) => {
    console.error('Erro no proxy:', err.message);
    clientRes.writeHead(502);
    clientRes.end('Erro de conexão com o servidor');
  });

  clientReq.pipe(proxyReq);
});

server.listen(PROXY_PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Proxy rodando na porta ${PROXY_PORT}`);
  console.log(`📡 Redirecionando para http://${TARGET_HOST}:${TARGET_PORT}`);
  console.log(`\n📱 No app, use: http://192.168.137.1:${PROXY_PORT}/api`);
  console.log(`\nPressione Ctrl+C para parar\n`);
});
