/* Semantic menu counterparts call the same Godot controls as mouse/gamepad.
   No canvas pixel interpretation or writable debug interface is used. */
(() => {
  let root, summary, signature = '', nodes = new Map();
  const act=(kind,id,value)=>window.aionAccessibleAction?.(kind,String(id),String(value??''));
  window.AionAccessibility = {update(raw) {
    const state=JSON.parse(raw);
    const next=JSON.stringify(state);
    if(next===signature)return;
    signature=next;
    if(!root){
      root=document.createElement('nav');root.id='aion-accessibility-controls';root.className='aion-assistive';root.setAttribute('aria-label','Aion Endless Run');
      summary=document.createElement('p');summary.id='aion-accessibility-status';summary.setAttribute('role','status');root.append(summary);document.body.append(root);
      root.addEventListener('keydown',e=>{if(['Enter',' ','ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.key))e.stopPropagation()});
    }
    root.lang=state.language;
    if(summary.textContent!==state.summary)summary.textContent=state.summary;root.dataset.page=state.page;
    const keep=new Set();
    for(const item of state.items){
      const id=String(item.id);keep.add(id);
      let node=nodes.get(id);
      if(!node){
        node=document.createElement(item.range?'input':'button');
        if(item.range){node.type='range';node.addEventListener('input',()=>act('range',id,node.value));}
        else {node.type='button';node.addEventListener('click',()=>act('activate',id));}
        node.dataset.controlId=id;node.addEventListener('focus',()=>act('focus',id));root.append(node);nodes.set(id,node);
      }
      node.setAttribute('aria-label',item.label);node.disabled=!!item.disabled;
      if(item.range){node.min=item.min;node.max=item.max;node.step=item.step||1;node.value=item.value;}
      else {node.textContent=item.label;if(item.toggle)node.setAttribute('aria-pressed',String(!!item.pressed));else node.removeAttribute('aria-pressed');}
    }
    for(const[id,node]of nodes){if(!keep.has(id)){node.remove();nodes.delete(id);}}
  }};
})();
