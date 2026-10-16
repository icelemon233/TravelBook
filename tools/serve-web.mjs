import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve('build/web'),port=Number(process.env.PORT||18760),base='/cinna-travel-book/';
const types={'.html':'text/html; charset=utf-8','.js':'application/javascript','.mjs':'application/javascript','.json':'application/json; charset=utf-8','.wasm':'application/wasm','.png':'image/png','.jpg':'image/jpeg','.webp':'image/webp','.ttf':'font/ttf','.bin':'application/octet-stream','.css':'text/css'};
http.createServer((request,response)=>{
  try{const pathname=decodeURIComponent(new URL(request.url,'http://127.0.0.1').pathname);
    if(pathname==='/'){response.writeHead(302,{Location:base});response.end();return;}
    if(!pathname.startsWith(base)){response.writeHead(404);response.end();return;}
    let file=path.resolve(root,pathname.slice(base.length)||'index.html');
    if(!file.startsWith(root+path.sep)&&file!==root){response.writeHead(403);response.end();return;}
    if(fs.existsSync(file)&&fs.statSync(file).isDirectory())file=path.join(file,'index.html');
    if(!fs.existsSync(file)){response.writeHead(404);response.end('Not found');return;}
    response.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Cache-Control':'no-cache'});fs.createReadStream(file).pipe(response);
  }catch{response.writeHead(400);response.end();}
}).listen(port,'127.0.0.1',()=>console.log(`Flutter Web preview: http://127.0.0.1:${port}${base}`));
