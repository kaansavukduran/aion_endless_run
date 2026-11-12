/* A synchronous small recovery copy complements Godot's asynchronous IDBFS.
   Existing userfs/IndexedDB data is never cleared or unregistered. */
(() => {
 const key='aion-runner-save-v1';
 window.AionStorage={
  read(){try{const p=JSON.parse(localStorage.getItem(key)||'null');return p&&p.schema===1&&Number.isSafeInteger(p.revision)&&p.revision>0&&typeof p.config==='string'&&p.config.length<=65536?p.config:''}catch(_){return ''}},
  write(config,revision){try{if(typeof config!=='string'||config.length>65536||!Number.isSafeInteger(revision))return false;localStorage.setItem(key,JSON.stringify({schema:1,revision,config}));return true}catch(_){return false}}
 };
})();
