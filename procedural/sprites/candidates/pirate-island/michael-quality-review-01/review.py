"""Deterministic sampling comparison; no authored anatomy or repainting."""
from pathlib import Path
import hashlib,json
from PIL import Image,ImageDraw,ImageFont

HERE=Path(__file__).resolve().parent
GAME=Path('C:/Users/Admin/Documents/Codex/2026-08-31/referenced-chatgpt-conversation-this-is-an-4/game')
src=Image.open(GAME/'assets/sprites/michael/source.png').convert('RGBA')
frames=json.loads((GAME/'assets/sprites/michael/frames.json').read_text())['frames']
terrain=Image.open(GAME/'assets/island/terrain.png').convert('RGBA')
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',15)

def export(im,height=96):
    box=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
    scale=height/(box[3]-box[1])
    # Area sampling integrates the high-resolution pixel clusters before reduction.
    reduced=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.BOX)
    alpha=reduced.getchannel('A').point(lambda a:255 if a>=128 else 0)
    pal=reduced.convert('RGB').quantize(colors=64,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGBA')
    pal.putalpha(alpha)
    return pal,scale,box

meta=[]
for frame in frames:
    x,y,w,h=frame['rect'];im=src.crop((x,y,x+w,y+h))
    reduced,scale,box=export(im)
    name=frame['direction'];reduced.save(HERE/f'michael-{name}-96.png')
    meta.append({'direction':name,'bbox':box,'native_dimensions':reduced.size,'native_pivot':[round(v*scale) for v in frame['footPivot']], 'scale_from_source':scale})

frame=frames[0];x,y,w,h=frame['rect'];im=src.crop((x,y,x+w,y+h));native,ratio,box=export(im)
body=box[3]-box[1]
variants=[('Current direct / 39 body',im,frame['footPivot'],.065),('Direct / 48 body',im,frame['footPivot'],48/body),('Grid96 / 48 body',native,[v*ratio for v in frame['footPivot']],.5),('Direct / 56 body',im,frame['footPivot'],56/body),('Grid96 / 56 body',native,[v*ratio for v in frame['footPivot']],56/96)]
board=Image.new('RGB',(1600,940),'#19242a');draw=ImageDraw.Draw(board)
draw.text((20,12),'Michael: same source, same pose, same terrain. Deterministic sampling only.',font=font,fill='white')
for col,(label,subject,pivot,scale) in enumerate(variants):
    draw.text((col*320+10,45),label,font=font,fill='white')
    for row,zoom in enumerate((1,2)):
        crop=terrain.crop((560,480,720,670)).resize((160*zoom,190*zoom),Image.Resampling.NEAREST)
        sprite=subject.resize((max(1,round(subject.width*scale*zoom)),max(1,round(subject.height*scale*zoom))),Image.Resampling.NEAREST)
        foot=(80*zoom,145*zoom)
        crop.alpha_composite(sprite,(round(foot[0]-pivot[0]*scale*zoom),round(foot[1]-pivot[1]*scale*zoom)))
        if zoom==1: crop=crop.resize((320,380),Image.Resampling.NEAREST)
        board.paste(crop.convert('RGB'),(col*320,82+row*425))
        draw.text((col*320+8,465+row*425),'1x world (shown 2x)' if zoom==1 else '2x camera (actual pixels)',font=small,fill='white')
board.save(HERE/'sampling-comparison.png')
source_plate=Image.new('RGB',(1000,740),'#314048');draw=ImageDraw.Draw(source_plate)
source_plate.paste(im,(0,40),im)
large=native.resize((native.width*4,native.height*4),Image.Resampling.NEAREST)
source_plate.paste(large,(620,100),large)
draw.text((20,10),'Original SE frame / authored identity',font=font,fill='white');draw.text((625,65),'96-body export / shown 4x',font=font,fill='white')
source_plate.save(HERE/'source-and-export.png')
(HERE/'review.json').write_text(json.dumps({'status':'comparison-only-not-runtime-admitted','source_sha256':hashlib.sha256((GAME/'assets/sprites/michael/source.png').read_bytes()).hexdigest(),'method':'BOX area sample to96 alpha-bbox height,64RGBcolors,no dither,binary alpha128; NEAREST presentation','source_body_height':body,'frames':meta,'no_generation':True,'credits':0},indent=2))
print(json.dumps({'body_height':body,'frames':meta}))
