"""Offline existing-source comparison, never alters the candidates."""
from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np
from scipy import ndimage
import hashlib,json
base=Path(__file__).resolve().parent
sources=[('Runtime male',Path('C:/Users/Admin/Documents/Codex/2026-08-31/referenced-chatgpt-conversation-this-is-an-4/game/assets/island/troops/cultist.png'),39),('Original female',base.parent/'extracted/cell_01_02.png',33),('Rejected revision',base.parent/'cthulhu-female-revision-01/extracted/cell_00_00.png',33)]
board=Image.new('RGB',(720,500),'#d3b777');d=ImageDraw.Draw(board)
d.rectangle((0,250,720,500),fill='#263d31')
records=[]
for i,(label,p,h) in enumerate(sources):
    im=Image.open(p).convert('RGBA');small=im.resize((round(im.width*h/im.height),h),Image.Resampling.NEAREST)
    for top in [0,250]:
        d.text((i*240+8,top+6),f'{label}: {h}px, then4x',fill='white',stroke_fill='black',stroke_width=1)
        board.paste(small,(i*240+20,top+70-h),small)
        big=small.resize((small.width*4,small.height*4),Image.Resampling.NEAREST)
        board.paste(big,(i*240+20,top+240-big.height),big)
    alpha=np.asarray(im.getchannel('A'));labels,n=ndimage.label(alpha>0)
    records.append({'label':label,'source':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size':im.size,'scale':h/im.height,'alpha_values':np.unique(alpha).tolist(),'components':sorted(np.bincount(labels.ravel())[1:].tolist(),reverse=True)})
board.save(base/'scale-review.png')
print(json.dumps(records,indent=2))
