"""Normalize candidate to existing atlas contract; create truthful scale review."""
from pathlib import Path
import json,hashlib
from PIL import Image,ImageDraw,ImageFont
H=Path(__file__).resolve().parent
G=Path('C:/Users/Admin/Documents/Codex/2026-08-31/referenced-chatgpt-conversation-this-is-an-4/game')
old=Image.open(G/'assets/sprites/michael/source.png').convert('RGBA')
data=json.loads((G/'assets/sprites/michael/frames.json').read_text())
atlas=Image.new('RGBA',old.size)
details=[]
for i,f in enumerate(data['frames']):
    x,y,w,h=f['rect'];before=old.crop((x,y,x+w,y+h))
    bb=before.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();height=bb[3]-bb[1]
    raw=Image.open(H/f'revision-extracted/cell_{i//2:02d}_{i%2:02d}.png').convert('RGBA')
    scale=height/raw.height;reduced=raw.resize((round(raw.width*scale),height),Image.Resampling.NEAREST)
    pivot=[round(reduced.width/2),height-1]
    paste=[f['footPivot'][0]-pivot[0],f['footPivot'][1]-pivot[1]]
    frame=Image.new('RGBA',(w,h));frame.alpha_composite(reduced,tuple(paste));atlas.alpha_composite(frame,(x,y))
    details.append({'direction':f['direction'],'raw_size':raw.size,'normalized_body_height':height,'chosen_pivot_in_resized_cutout':pivot,'paste_in_existing_frame':paste})
atlas.save(H/'revision-runtime-candidate.png')
data['sourceSha256']=hashlib.sha256((H/'revision-runtime-candidate.png').read_bytes()).hexdigest()
data['status']='rejected-normalized-preparation-use-revision-native-frames'
data['provenance']='shared-game-environment-library/procedural/sprites/candidates/pirate-island/michael-quality-review-01/REVISION_REVIEW.md'
(H/'revision-frames.json').write_text(json.dumps(data,indent=2))
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
board=Image.new('RGB',(1200,920),'#1c2b31');d=ImageDraw.Draw(board)
terrain=Image.open(G/'assets/island/terrain.png').convert('RGBA').crop((560,480,760,680))
for row,height in enumerate((39,56,80)):
    for col,(label,source) in enumerate((('Original',old),('Revision',atlas))):
        f=data['frames'][0];x,y,w,h=f['rect'];im=source.crop((x,y,x+w,y+h));scale=height/592
        im=im.resize((round(w*scale),round(h*scale)),Image.Resampling.NEAREST)
        tile=terrain.copy();tile.alpha_composite(im,(round(100-f['footPivot'][0]*scale),round(160-f['footPivot'][1]*scale)))
        tile=tile.resize((400,400),Image.Resampling.NEAREST)
        # Separate exact rendered sprite size on neutral background from magnified terrain detail.
        px=col*600;py=row*300
        d.text((px+15,py+8),f'{label}: {height}px body (terrain shown 2x)',font=font,fill='white')
        board.paste(tile.crop((0,110,400,370)),(px,py+35))
        board.paste(im,(px+465,py+130),im)
board.save(H/'revision-scale-comparison.png')
turn=Image.new('RGB',(1000,400),'#33434a');d=ImageDraw.Draw(turn)
for i,f in enumerate(data['frames']):
    x,y,w,h=f['rect'];im=atlas.crop((x,y,x+w,y+h));bb=im.getchannel('A').getbbox();im=im.crop(bb)
    im=im.resize((round(im.width*160/im.height),160),Image.Resampling.NEAREST)
    turn.paste(im,(i*250+70,90),im);d.text((i*250+80,30),f['direction'],font=font,fill='white')
turn.save(H/'revision-turnaround-review.png')
(H/'revision-normalization.json').write_text(json.dumps(details,indent=2))
print(data['sourceSha256'])
