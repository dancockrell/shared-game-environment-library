"""Offline composition and conservative mask audit, not an engine capture."""
from pathlib import Path
from PIL import Image, ImageDraw
from collections import deque
import json, hashlib
base=Path(__file__).resolve().parent
game=Path('C:/Users/Admin/Documents/Codex/2026-08-31/referenced-chatgpt-conversation-this-is-an-4/game/assets/island')
nav=json.loads((game/'navigation.json').read_text())
manifest=json.loads((game/'buildings.json').read_text())
entrance=(15,24); pivot=(350,1100); width=140
offsets=[(0,-1),(1,-1),(2,-1),(1,0),(2,0)]
def inside(x,y):
    result=False
    points=nav['landPolygon']
    for (a,b),(c,d) in zip(points,points[1:]+points[:1]):
        if (b>y)!=(d>y) and x<(c-a)*(y-b)/(d-b)+a: result=not result
    return result
land=set()
for y in range(32):
    for x in range(48):
        px,py=(x+.5)*32,(y+.5)*32
        if [x,y] in nav['landCorrections'] or (inside(px,py) and not any(a-10<=px<a+w+10 and b-10<=py<b+h+10 for a,b,w,h in nav['blockedRects'])): land.add((x,y))
existing={'site_archetype.colonial.watch_fort':(12,11),'site_archetype.pirates.tide_quay':(34,22),'site_archetype.cthulhu.drowned_shrine':(27,16),'site_archetype.eastern_fox_people.river_market':(33,9),'site_archetype.michael.field_workshop':(19,17)}
blocked={(p[0]+dx,p[1]+dy) for key,p in existing.items() for dx,dy in manifest[key]['blocked_offsets']}
foot={(entrance[0]+dx,entrance[1]+dy) for dx,dy in offsets}
walk=land-blocked-foot
distance={tuple(nav['start']):0}; q=deque(distance)
while q:
    x,y=q.popleft()
    for nxt in [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]:
        if nxt in walk and nxt not in distance: distance[nxt]=distance[(x,y)]+1; q.append(nxt)
terrain=Image.open(game/'terrain.png').convert('RGBA')
layers=[]
for key,pt in existing.items():
    art=manifest[key]; src=Image.open(game/Path(art['texture']).name).convert('RGBA'); sc=art['display_width']/src.width
    layers.append((pt[1],src,sc,((pt[0]+.5)*32-art['pivot'][0]*sc,(pt[1]+.5)*32-art['pivot'][1]*sc)))
source=base/'extracted/cell_00_00.png'; sprite=Image.open(source).convert('RGBA'); scale=width/sprite.width
origin=((entrance[0]+.5)*32-pivot[0]*scale,(entrance[1]+.5)*32-pivot[1]*scale)
layers.append((entrance[1],sprite,scale,origin))
for _,img,sc,pos in sorted(layers,key=lambda layer:layer[0]): terrain.alpha_composite(img.resize((round(img.width*sc),round(img.height*sc)),Image.Resampling.NEAREST),(round(pos[0]),round(pos[1])))
terrain.save(base/'placement-review.png')
detail=terrain.crop((384,576,672,864)).resize((864,864),Image.Resampling.NEAREST); draw=ImageDraw.Draw(detail)
for x,y in foot:
    draw.rectangle(((x*32-384)*3,(y*32-576)*3,((x+1)*32-384)*3-1,((y+1)*32-576)*3-1),outline='#ed9380',width=3)
cx,cy=((entrance[0]+.5)*32-384)*3,((entrance[1]+.5)*32-576)*3
draw.ellipse((cx-6,cy-6,cx+6,cy+6),outline='#ffff88',width=3)
draw.text((10,10),'STATIC PLACEMENT / 3x nearest / coral: proposed obstruction',fill='white',stroke_fill='black',stroke_width=1)
detail.save(base/'placement-detail.png')
record={'entrance':entrance,'pivot':pivot,'width':width,'scale':scale,'source_size':sprite.size,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'terrain_sha256':hashlib.sha256((game/'terrain.png').read_bytes()).hexdigest(),'navigation_sha256':hashlib.sha256((game/'navigation.json').read_bytes()).hexdigest(),'blocked_offsets':offsets,'footprint_on_existing_land':foot<=land,'no_existing_overlap':not bool(foot&blocked),'entrance_walkable':entrance in walk,'path_steps_from_start':distance.get(entrance),'runtime_admission':False,'method':'Offline point-in-polygon/grown-rect mask plus cardinal BFS; mirrors inspected scene contract, not executed Godot navigation'}
(base/'placement.json').write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps(record))
