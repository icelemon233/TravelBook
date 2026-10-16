{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  onEntrypointLoaded: async function(initializer) {
    try {
      const runner = await initializer.initializeEngine();
      await runner.runApp();
      document.getElementById('boot')?.remove();
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register(new URL('service_worker.js', document.baseURI), {scope: new URL('.',document.baseURI).pathname}).then(registration => {
          let requested=false;
          navigator.serviceWorker.addEventListener('controllerchange',()=>{if(requested)location.reload();});
          const offerUpdate=()=>{
            if(!registration.waiting||!navigator.serviceWorker.controller||document.getElementById('travel-update'))return;
            const button=document.createElement('button');button.id='travel-update';button.textContent='新版就绪，确认已保存后刷新';
            button.style.cssText='position:fixed;bottom:100px;right:18px;z-index:100000;padding:12px 18px;border:1px solid #294b3d;border-radius:12px;background:#fffdf8;color:#294b3d;box-shadow:0 4px 18px #0002;cursor:pointer';
            button.onclick=()=>{requested=true;registration.waiting?.postMessage({type:'ACTIVATE'});};document.body.appendChild(button);
          };
          offerUpdate();registration.addEventListener('updatefound',()=>{registration.installing?.addEventListener('statechange',offerUpdate);});
        }).catch(() => {});
      }
    } catch (_) {
      const status=document.getElementById('boot-status');
      if(status) { status.textContent='旅行册暂未载入，请刷新重试。';const retry=document.createElement('a');retry.href=location.href;retry.textContent='重新载入';status.append(document.createElement('br'),retry); }
    }
  }
});
