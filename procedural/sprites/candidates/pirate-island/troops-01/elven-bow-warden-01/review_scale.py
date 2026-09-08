"""Offline actual-size figure comparison; no source edits."""
from pathlib import Path
from PIL import Image,ImageDraw
import argparse
base=Path(__file__).resolve().parent
parser=argparse.ArgumentParser();parser.add_argument('--comparison',choices=['initial','bow','height'],default='height');args=parser.parse_args()
marine=base.parent/'colonial-female-revision-02/extracted/cell_00_00.png'
original=base/'extracted/cell_00_00.png';corrected=base/'extracted-bow-correction/cell_00_00.png'
sources,filename={
 'initial':([('Marine33px',marine,33),('Elf33px',original,33),('Elf35px bow included',original,35)],'scale-review.png'),
 'bow':([('Marine33px',marine,33),('Original elf33px',original,33),('Corrected bow33px',corrected,33)],'bow-correction-review.png'),
 'height':([('Corrected33px',corrected,33),('Corrected35px',corrected,35),('Corrected36px',corrected,36)],'bow-height-review.png')
}[args.comparison]
board=Image.new('RGB',(720,500),'#d3b777');d=ImageDraw.Draw(board)
d.rectangle((0,250,720,500),fill='#263d31')
for i,(label,p,h) in enumerate(sources):
    im=Image.open(p).convert('RGBA');small=im.resize((round(im.width*h/im.height),h),Image.Resampling.NEAREST)
    for top in [0,250]:
        d.text((i*240+8,top+6),label+' then4x',fill='white',stroke_fill='black',stroke_width=1)
        board.paste(small,(i*240+20,top+70-h),small)
        big=small.resize((small.width*4,small.height*4),Image.Resampling.NEAREST)
        board.paste(big,(i*240+20,top+240-big.height),big)
board.save(base/filename)
