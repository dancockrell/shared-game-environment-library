// Source-kit review only. Alignment belongs to the shared room reviewer.
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { alignSpriteEdge } from '../../../../tools/sprite-room-review.mjs';
const root = new URL('./', import.meta.url);
const kit = JSON.parse(readFileSync(new URL('kit.json', root), 'utf8'));
const geometry = kit.geometry;
const door = geometry['stone-arch-doorway'];
const wall = geometry['stone-wall-straight'];
const origin = [250, 45];
const worldEdge = edge => edge.map(([x,y]) => [x + origin[0], y + origin[1]]);
const left = alignSpriteEdge(worldEdge(door.connectors['left-jamb-base'].edge), wall.connectors['right-end'].edge);
const right = alignSpriteEdge(worldEdge(door.connectors['right-jamb-base'].edge), wall.connectors['left-end'].edge);
const placements = [
  {id:'stone-wall-straight', file:'cell_00_00.png', ...left},
  {id:'stone-wall-straight', file:'cell_00_00.png', ...right},
  {id:'stone-arch-doorway', file:'cell_01_00.png', scale:1, offset:origin, error:0},
];
const tangentAngle = g => Math.atan2(g.groundTangent[1], g.groundTangent[0]) * 180 / Math.PI;
const timberDifference = Math.abs(tangentAngle(wall) - tangentAngle(geometry['timber-stone-doorway']));
if (timberDifference < 20) throw new Error('Expected incompatible timber direction was not detected');
const images = placements.map(p => {
  const c=kit.components.find(c=>c.id===p.id);
  return `<img alt="${p.id}" src="extracted-01/${p.file}" style="left:${p.offset[0]}px;top:${p.offset[1]}px;width:${c.bounds[2]*p.scale}px;height:${c.bounds[3]*p.scale}px">`;
}).join('');
const polygons = placements.map(p=>`<polygon points="${geometry[p.id].footprint.map(([x,y])=>`${x*p.scale+p.offset[0]},${y*p.scale+p.offset[1]}`).join(' ')}"/>`).join('');
const endpointMarks = Object.values(door.connectors).map(c => worldEdge(c.edge).map(([x,y])=>`<circle cx="${x}" cy="${y}" r="3"/>`).join('')).join('');
const html = `<!doctype html><meta charset="utf-8"><title>Masonry kit — estimated abutment review</title>
<style>body{background:#24271f;color:#e7dfc4;font:16px system-ui;margin:24px;max-width:900px}h1{font-size:22px}.scene{width:760px;height:455px;position:relative;background:#747851;overflow:hidden}.scene img{position:absolute;image-rendering:pixelated}.scene svg{position:absolute;inset:0;pointer-events:none}polygon{fill:#38bbb025;stroke:#65d4cd;stroke-width:1}circle{fill:#ffe674;stroke:#322e20}code{color:#ffdb82}li{margin:8px 0}</style>
<main><h1>Wall–door–wall: estimated base abutments</h1><p>Exact extracted PNGs. Placement computed by the shared <code>alignSpriteEdge</code> solver; uniform scale and translation only, no rotation or mirroring.</p>
<div class="scene">${images}<svg width="760" height="455">${polygons}${endpointMarks}</svg></div>
<ul><li>Yellow points: matched lower-jamb edge endpoints. Cyan polygons: estimated footprints, <strong>not collision authority</strong>.</li>
<li>Left endpoint error ${left.error.toFixed(3)} px; right ${right.error.toFixed(3)} px. Walls scaled ${left.scale.toFixed(3)} and ${right.scale.toFixed(3)} to abut the authored low jamb bands.</li>
<li><strong>Not seamless:</strong> door full height does not match wall height; projected ground tangent differs ${(Math.abs(tangentAngle(wall)-tangentAngle(door))).toFixed(1)}°. Unequal wall scaling is visible evidence of inconsistent source cap heights, not a shipping solution.</li>
<li>Timber doorway inline continuation rejected: opposite frontage slope (${timberDifference.toFixed(1)}° mismatch). Corner arms require directional seam assets; no automatic join admission.</li>
<li>Door appears closed; this cannot establish MUD door state or graph connectivity. Source review only, no runtime integration.</li></ul></main>`;
writeFileSync(new URL('assembly-preview.html',root),html);
console.log(JSON.stringify({output:fileURLToPath(new URL('assembly-preview.html',root)),left,right,timberDifference}));
