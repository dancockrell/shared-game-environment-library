"""Offline placement diagnostic with actual workshop; not an engine capture."""
from pathlib import Path
from PIL import Image, ImageDraw
import hashlib

base = Path(__file__).resolve().parent
game = Path('C:/Users/Admin/Documents/Codex/2026-08-31/referenced-chatgpt-conversation-this-is-an-4/game/assets/island')
source = base.parents[1] / 'mercantile-cart-props-01/extracted-01/cell_00_02.png'
terrain = Image.open(game / 'terrain.png').convert('RGBA')
sprite = Image.open(source).convert('RGBA')
scale = 30 / sprite.width
size = (30, round(sprite.height * scale))
origin = (round(656-252*scale), round(624-304*scale))
terrain.alpha_composite(sprite.resize(size,Image.Resampling.NEAREST),origin)
workshop_source=base/'extracted/cell_00_00.png'
workshop=Image.open(workshop_source).convert('RGBA')
ws=120/workshop.width
wo=(round(624-405*ws),round(560-910*ws))
terrain.alpha_composite(workshop.resize((120,round(workshop.height*ws)),Image.Resampling.NEAREST),wo)
terrain.save(base/'placement-review.png')
detail = terrain.crop((480,432,816,704)).resize((1008,816),Image.Resampling.NEAREST)
d=ImageDraw.Draw(detail)
def xy(x,y): return ((x-480)*3,(y-432)*3)
for x in range(15,26): d.line((*xy(x*32,432),*xy(x*32,704)), fill='#777777')
for y in range(14,23): d.line((*xy(480,y*32),*xy(816,y*32)), fill='#777777')
for x,y in [(19,16),(20,16),(21,16),(20,17)]:
    d.rectangle((*xy(x*32+2,y*32+2),*xy((x+1)*32-2,(y+1)*32-2)),outline='#ff8877',width=3)
for x,y,label,color in [(624,560,'WORKSHOP ENTRANCE 19,17','#ffff88'),(656,592,'MICHAEL START 20,18','#44ffff'),(656,624,'CACHE 20,19','#ffffff')]:
    a,b=xy(x,y); d.ellipse((a-6,b-6,a+6,b+6),outline=color,width=2)
    d.text((a+10,b),label,fill=color,stroke_fill='#111111',stroke_width=1)
d.text((8,8),'STATIC REVIEW: actual workshop at120px / 3x nearest / coral = foundation',fill='white',stroke_fill='black',stroke_width=1)
detail.save(base/'placement-detail.png')
print({'source_size':sprite.size,'scale':scale,'size':size,'origin':origin,'alpha_extrema':sprite.getchannel('A').getextrema(),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest()})
print({'workshop_size':workshop.size,'scale':ws,'origin':wo,'sha256':hashlib.sha256(workshop_source.read_bytes()).hexdigest()})
