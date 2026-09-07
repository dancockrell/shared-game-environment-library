import { readFileSync, writeFileSync } from 'node:fs'
import { resolve, dirname, join } from 'node:path'
import { pathToFileURL } from 'node:url'
import { createHash } from 'node:crypto'

export function validate(m) {
  const require = (v, why) => { if (!v) throw new Error(why) }
  require(m.schemaVersion === 1 && m.runtimeAdmission === false, 'Unadmitted version 1 candidates only')
  require(typeof m.title === 'string', 'Missing title')
  const images = m.images ?? [m.image]
  require(Array.isArray(images) && images.length > 0 && images.length <= 256 && !(m.images && m.image), 'Use one image or an images list')
  for (const image of images) {
    require(/^[\w.-]+\.png$/.test(image?.path), 'Local PNG basename required')
    require(/^[a-f0-9]{64}$/.test(image?.sha256), 'SHA256 required')
    require([image.width,image.height].every(n => Number.isInteger(n) && n > 0), 'Invalid dimensions')
  }
  require(Number.isFinite(m.fps) && m.fps >= 1 && m.fps <= 30, 'Invalid FPS')
  require(Number.isFinite(m.scale) && m.scale > 0 && m.scale <= 2, 'Invalid scale')
  require(Array.isArray(m.frames) && m.frames.length > 1 && m.frames.length <= 256, 'Invalid frames')
  for (const f of m.frames) {
    const imageIndex = f.imageIndex ?? 0
    require(Number.isInteger(imageIndex) && imageIndex >= 0 && imageIndex < images.length, 'Invalid image index')
    const image = images[imageIndex]
    require(f.durationMs === undefined || (Number.isFinite(f.durationMs) && f.durationMs >= 16 && f.durationMs <= 10000), 'Invalid duration')
    require(Array.isArray(f.rect) && f.rect.length === 4 && f.rect.every(Number.isInteger), 'Invalid rectangle')
    const [x,y,w,h] = f.rect
    require(x >= 0 && y >= 0 && w > 0 && h > 0 && x+w <= image.width && y+h <= image.height, 'Rectangle outside image')
    require(Array.isArray(f.anchor) && f.anchor.length === 2 && f.anchor.every(Number.isFinite) && f.anchor[0] >= 0 && f.anchor[0] <= w && f.anchor[1] >= 0 && f.anchor[1] <= h, 'Anchor outside frame')
  }
  return m
}

export function validateImage(bytes, m) {
  if (bytes.subarray(0,8).toString('hex') !== '89504e470d0a1a0a' || bytes.readUInt32BE(16) !== m.image.width || bytes.readUInt32BE(20) !== m.image.height) throw new Error('PNG dimensions mismatch')
  if (createHash('sha256').update(bytes).digest('hex') !== m.image.sha256) throw new Error('Source hash mismatch')
  // This pipeline's source contract is RGBA, not a picture of transparency.
  // Alpha-bearing but fully opaque PNGs are rejected after browser decode.
  if (bytes[24] !== 8 || bytes[25] !== 6) throw new Error('8-bit RGBA PNG required; RGB checkerboards are not transparency')
}

/** Presence gate only: clean matting and anatomy still require visual review. */
export function hasSpriteAlpha(pixels) {
  if (!pixels.length || pixels.length % 4 !== 0) return false
  let transparent = false, visible = false
  for (let i = 3; i < pixels.length; i += 4) {
    transparent ||= pixels[i] === 0
    visible ||= pixels[i] > 0
  }
  return transparent && visible
}

export function build(file) {
  const path = resolve(file), m = validate(JSON.parse(readFileSync(path,'utf8')))
  const sources = (m.images ?? [m.image]).map(image => {
    const bytes = readFileSync(join(dirname(path),image.path))
    validateImage(bytes, {image})
    return `data:image/png;base64,${bytes.toString('base64')}`
  })
  const data = JSON.stringify(m).replaceAll('<','\\u003c')
  const html = `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Sprite animation review</title>
<style>body{background:#171e20;color:#eee;font:16px system-ui;margin:24px}canvas{background:#39443e;max-width:100%;image-rendering:pixelated;border:1px solid #708078}button,select{font:inherit;margin:8px;padding:8px}#film{display:flex;flex-wrap:wrap;gap:8px}</style>
<h1 id="title"></h1><p>Candidate only. Fixed source scale; per-frame body anchors. No source pixels altered.</p>
<button id="play">Play</button><button id="step">Next frame</button><label>Speed <select id="fps"><option>4</option><option>6</option><option>8</option><option>12</option></select> fps</label>
<label>Background <select id="bg"><option value="#39443e">Moss</option><option value="#eee8d9">Light</option><option value="#101214">Dark</option></select></label><span id="state"></span><br><canvas id="stage" width="600" height="360"></canvas><h2>Aligned frame comparison</h2><div id="film"></div><p id="error" role="alert"></p>
<script>${hasSpriteAlpha.toString()}
const m=${data};document.querySelector('#title').textContent=m.title;const stage=document.querySelector('#stage'),imgs=[];let frame=0,playing=false,last=0,ready=false;const speed=document.querySelector('#fps');speed.value=String(m.fps);
function draw(c,i){const ctx=c.getContext('2d'),f=m.frames[i],s=m.scale;ctx.clearRect(0,0,c.width,c.height);ctx.imageSmoothingEnabled=false;ctx.strokeStyle='#8daba0';ctx.beginPath();ctx.moveTo(c.width/2-8,c.height/2);ctx.lineTo(c.width/2+8,c.height/2);ctx.moveTo(c.width/2,c.height/2-8);ctx.lineTo(c.width/2,c.height/2+8);ctx.stroke();ctx.drawImage(imgs[f.imageIndex??0],...f.rect,c.width/2-f.anchor[0]*s,c.height/2-f.anchor[1]*s,f.rect[2]*s,f.rect[3]*s)}
function paint(){if(!ready)return;draw(stage,frame);document.querySelector('#state').textContent='Frame '+(frame+1)+' / '+m.frames.length}
document.querySelector('#play').onclick=()=>{playing=!playing;last=performance.now();document.querySelector('#play').textContent=playing?'Pause':'Play'};
document.querySelector('#step').onclick=()=>{playing=false;document.querySelector('#play').textContent='Play';frame=(frame+1)%m.frames.length;paint()};
document.querySelector('#bg').onchange=e=>document.querySelectorAll('canvas').forEach(c=>c.style.background=e.target.value);
Promise.all(${JSON.stringify(sources)}.map((src,index)=>new Promise((resolve,reject)=>{const img=new Image();imgs[index]=img;img.onload=()=>{try{const probe=document.createElement('canvas');probe.width=img.naturalWidth;probe.height=img.naturalHeight;const ctx=probe.getContext('2d');ctx.drawImage(img,0,0);if(!hasSpriteAlpha(ctx.getImageData(0,0,probe.width,probe.height).data))throw new Error('Sprite must contain transparent background and visible pixels');resolve()}catch(error){reject(error)}};img.onerror=()=>reject(new Error('Source image could not load'));img.src=src}))).then(()=>{ready=true;for(let i=0;i<m.frames.length;i++){const c=document.createElement('canvas');c.width=240;c.height=220;c.setAttribute('aria-label','Frame '+(i+1));document.querySelector('#film').append(c);draw(c,i)}paint();document.body.dataset.ready='true'}).catch(error=>document.querySelector('#error').textContent=error.message);
function tick(now){const duration=(m.frames[frame].durationMs??1000/m.fps)*m.fps/Number(speed.value);if(playing&&ready&&now-last>=duration){frame=(frame+1)%m.frames.length;last=now;paint()}requestAnimationFrame(tick)}requestAnimationFrame(tick);
// Starts paused, including reduced-motion users. Playback requires explicit action.
</script></html>`
  const out = join(dirname(path),'animation-review.html'); writeFileSync(out,html); return out
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) console.log(build(process.argv[2]))
