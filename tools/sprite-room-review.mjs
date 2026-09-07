import { readFileSync, writeFileSync } from 'node:fs'
import { resolve, dirname, join } from 'node:path'
import { pathToFileURL } from 'node:url'
import { createHash } from 'node:crypto'

// This function is also embedded in the offline reviewer: one placement rule.
export function inside(point, polygon) {
  let hit = false
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const a = polygon[i], b = polygon[j]
    if ((a[1] > point[1]) !== (b[1] > point[1]) &&
        point[0] < (b[0] - a[0]) * (point[1] - a[1]) / (b[1] - a[1]) + a[0]) hit = !hit
  }
  return hit
}

export function validate(room) {
  const require = (condition, message) => { if (!condition) throw new Error(message) }
  const point = p => Array.isArray(p) && p.length === 2 && p.every(n => Number.isFinite(n) && n >= 0 && n <= 1)
  require(room.schemaVersion === 1 && room.status === 'candidate' && room.runtimeAdmission === false, 'Review only accepts unadmitted version 1 candidates')
  require(typeof room.title === 'string' && typeof room.source?.description === 'string', 'Missing title or source description')
  require(room.coordinates === 'normalized-image-top-left', 'Unknown coordinate convention')
  require(/^[\w.-]+\.png$/.test(room.image?.path), 'Image must be a local PNG basename')
  require(/^[a-f0-9]{64}$/.test(room.image?.sha256), 'Missing image hash')
  require([room.image.width, room.image.height].every(n => Number.isInteger(n) && n > 0), 'Invalid image dimensions')
  require(Array.isArray(room.floor) && room.floor.length >= 3 && room.floor.every(point), 'Invalid floor polygon')
  require(Array.isArray(room.anchors) && room.anchors.length > 0, 'Missing anchors')
  const ids = new Set()
  for (const anchor of room.anchors) {
    require(typeof anchor.id === 'string' && !ids.has(anchor.id), 'Duplicate or invalid anchor ID')
    ids.add(anchor.id)
    require(typeof anchor.label === 'string' && ['spawn','interaction'].includes(anchor.kind), 'Invalid anchor metadata')
    require(point(anchor.point) && inside(anchor.point, room.floor), 'Anchor outside reviewed floor')
  }
  require(Array.isArray(room.exits), 'Missing explicit exits')
  for (const exit of room.exits) {
    require(typeof exit.direction === 'string' && typeof exit.command === 'string' && typeof exit.to === 'string', 'Invalid graph exit')
    require(exit.presentation === 'off-camera' && exit.anchor === null, 'Spatial exit placement requires separate review')
  }
  return room
}

export function build(manifestPath) {
  const filename = resolve(manifestPath)
  const room = validate(JSON.parse(readFileSync(filename, 'utf8')))
  const bytes = readFileSync(join(dirname(filename), room.image.path))
  if (createHash('sha256').update(bytes).digest('hex') !== room.image.sha256) throw new Error('Image hash mismatch')
  if (bytes.subarray(0,8).toString('hex') !== '89504e470d0a1a0a' || bytes.readUInt32BE(16) !== room.image.width || bytes.readUInt32BE(20) !== room.image.height) throw new Error('PNG dimensions mismatch')
  const data = JSON.stringify(room).replaceAll('<', '\\u003c')
  const html = `<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Sprite room placement review</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#101817;color:#eee7d8;font:16px system-ui}header{padding:20px 28px;border-bottom:1px solid #40514b}h1{font-size:24px;margin:5px 0}small{color:#e7bd72}main{display:grid;grid-template-columns:minmax(0,1fr) 300px;gap:20px;padding:20px}aside{line-height:1.6}button,select{font:inherit;padding:8px;color:#eee7d8;background:#263a34;border:1px solid #8aa596;border-radius:5px;max-width:100%}button{cursor:pointer}button:focus-visible,select:focus-visible{outline:3px solid #ffdb83}label{display:block;margin:14px 0}svg{display:block;width:100%;height:auto;background:#070b09;touch-action:manipulation}#floor{fill:#66cbb3;fill-opacity:.12;stroke:#89d9c2;stroke-width:3;stroke-dasharray:8 6}#markers text{fill:#fff4d8;paint-order:stroke;stroke:#111;stroke-width:4;font-size:18px;font-weight:700}#markers circle{fill:#deb75e;stroke:#fff3ce;stroke-width:2}#status{min-height:3em;color:#e7bd72}li{margin-bottom:10px}p{overflow-wrap:anywhere}@media(max-width:850px){main{grid-template-columns:1fr}aside{max-width:none}}
</style>
<header><small>DR COMPANION · SPRITE WORKSHOP · NOT LIVE GAMEPLAY</small><h1 id="title"></h1><span>Candidate layout — no runtime admission</span></header>
<main><section><svg id="board" role="img" aria-label="Room art with placement probes"><image id="art" width="100%" height="100%"/><polygon id="floor"/><g id="markers"></g></svg><p id="status" role="status">Choose a marker, then click clear floor to place it. Use the arrow buttons for precise adjustments.</p></section>
<aside><h2>Placement review</h2><label>Selected marker <select id="selected"></select></label>
<div aria-label="Move selected marker"><button data-dx="0" data-dy="-0.01" aria-label="Move up">↑</button> <button data-dx="-0.01" data-dy="0" aria-label="Move left">←</button> <button data-dx="0.01" data-dy="0" aria-label="Move right">→</button> <button data-dx="0" data-dy="0.01" aria-label="Move down">↓</button></div>
<label><input id="overlays" type="checkbox" checked> Show floor and probes</label><button id="reset">Reset positions</button> <button id="save">Export layout JSON</button>
<h3>Confirmed map data</h3><p id="exits"></p><h3>Authored room description</h3><p id="description"></p><details><summary>Limits of this preview</summary><ul id="limits"></ul></details></aside></main>
<script>
const original=${data}; const room=structuredClone(original);
const inside=${inside.toString()};
const $=id=>document.getElementById(id), ns='http://www.w3.org/2000/svg';
$('title').textContent=room.title; $('description').textContent=room.source.description;
$('board').setAttribute('viewBox','0 0 '+room.image.width+' '+room.image.height);
$('art').setAttribute('href',room.image.path);
$('exits').textContent=room.exits.map(e=>e.direction+' → '+e.to+' ('+e.presentation+')').join('; ') || 'No exits in source record.';
for(const limit of [room.placementAuthority,...room.limitations]){const li=document.createElement('li');li.textContent=limit;$('limits').append(li)}
for(const a of room.anchors){const o=document.createElement('option');o.value=a.id;o.textContent=a.label;$('selected').append(o)}
$('floor').setAttribute('points',room.floor.map(p=>p[0]*room.image.width+','+p[1]*room.image.height).join(' '));
function draw(){ $('markers').replaceChildren(); for(const a of room.anchors){const g=document.createElementNS(ns,'g');g.setAttribute('transform','translate('+a.point[0]*room.image.width+' '+a.point[1]*room.image.height+')');const c=document.createElementNS(ns,'circle');c.setAttribute('r',a.id===$('selected').value?13:9);const t=document.createElementNS(ns,'text');t.setAttribute('y',-22);t.setAttribute('text-anchor','middle');t.textContent=a.label;g.append(c,t);$('markers').append(g)}}
function move(p){p=p.map(n=>Math.round(n*10000)/10000);if(!inside(p,room.floor)){$('status').textContent='Placement rejected: outside the reviewed clear floor.';return}const a=room.anchors.find(a=>a.id===$('selected').value);a.point=p;draw();$('status').textContent=a.label+': '+a.point.join(', ')+'. Local review only; export to keep changes.'}
$('board').addEventListener('click',e=>{const p=new DOMPoint(e.clientX,e.clientY).matrixTransform($('board').getScreenCTM().inverse());move([p.x/room.image.width,p.y/room.image.height])});
document.querySelectorAll('[data-dx]').forEach(b=>b.onclick=()=>{const p=room.anchors.find(a=>a.id===$('selected').value).point;move([p[0]+Number(b.dataset.dx),p[1]+Number(b.dataset.dy)])});
$('selected').onchange=draw;
$('overlays').onchange=()=>{for(const id of ['floor','markers'])$(id).style.display=$('overlays').checked?'':'none'};
$('reset').onclick=()=>{room.anchors=structuredClone(original.anchors);draw();$('status').textContent='Original positions restored.'};
$('save').onclick=()=>{const url=URL.createObjectURL(new Blob([JSON.stringify(room,null,2)+'\\n'],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download=room.id+'-review.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);$('status').textContent='Layout export requested. Candidate status unchanged.'};
draw();
</script></html>`
  const output = join(dirname(filename), 'review.html')
  writeFileSync(output, html)
  return output
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  if (!process.argv[2]) throw new Error('Usage: node tools/sprite-room-review.mjs path/to/room.json')
  console.log(build(process.argv[2]))
}
