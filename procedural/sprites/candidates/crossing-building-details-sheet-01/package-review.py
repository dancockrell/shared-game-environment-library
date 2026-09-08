"""Package existing extractor records and one diagnostic contact sheet; no source edits."""
from pathlib import Path
import json
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parent
m=json.loads((root/'extracted-01/metadata.json').read_text())
specs=[
 ('closed-plank-door','wall',[90,282],['door','wood','closed'],'Threshold mount; no wall supplied and no lock/passability state implied.'),
 ('arched-wood-door','wall',[89,291],['door','wood','arch','closed'],'Threshold mount; curved frame requires compatible opening, not existing masonry seam.'),
 ('shuttered-window','wall',[104,231],['window','wood','shutters'],'Lower sill mount, not ground pivot; static closed appearance.'),
 ('empty-window-frame','wall',[104,239],['window','frame','wood'],'Open center is alpha; consumer must provide wall opening/background, not paint frame over intact wall and claim opening.'),
 ('stone-chimney','roof',[102,271],['chimney','stone'],'Roof penetration/base mount; roof slope/occlusion must be matched, no chimney smoke or interior passage.'),
 ('brick-chimney','roof',[91,254],['chimney','brick'],'Roof penetration/base mount; stone base is part of art, roof occlusion requires deliberate overlap.'),
 ('wood-three-step-flight','ground',[139,232],['stairs','wood'],'Landing must be matched to actual doorway height and axis; no seamless stair-door claim.'),
 ('stone-two-step-flight','ground',[146,180],['steps','stone'],'Low broad two-tier alternative to existing taller masonry stairs; no path/navigation authority.'),
 ('small-porch-platform','ground',[153,205],['porch','platform','wood'],'Short visible legs, no stairs; surface mounting depth differs from floor contact.'),
 ('blue-cloth-awning','wall',[155,39],['awning','cloth','blue'],'Upper back support mount; requires matching wall direction and draw-order, not a ground object.'),
 ('iron-hanging-bracket','wall',[18,76],['bracket','iron'],'Wall-plate center mount; no hanging item supplied, bracket projects right in image.'),
 ('wood-railing-segment','ground',[135,199],['railing','wood'],'Two-post ground contact estimate; bounded segment not certified seamless.'),
]
components=[]
sheet=Image.new('RGB',(1000,690),(43,46,37));draw=ImageDraw.Draw(sheet)
for c,(name,mount,anchor,tags,limit) in zip(m['cells'],specs):
 p=root/'extracted-01'/c['file'];im=Image.open(p)
 assert im.mode=='RGBA' and list(im.size)==c['size']
 components.append({'id':name,'file':'extracted-01/'+c['file'],'size':c['size'],'anchor':anchor,'status':'reviewed-candidate','semanticTags':tags,'mount':mount,'sha256':c['png_sha256'],'mountingLimits':limit,'anchorAuthority':'visually-estimated-source-pixels-not-collision'})
 # Diagnostic nearest-neighbor50% view preserves sheet relative authored sizes.
 thumb=im.resize((round(im.width*.5),round(im.height*.5)),Image.Resampling.NEAREST)
 x=(c['index']%4)*250;y=(c['index']//4)*230
 draw.rectangle((x+5,y+5,x+244,y+218),fill=(70,75,57) if c['index']%2==0 else (203,189,155))
 sheet.paste(thumb,(x+(250-thumb.width)//2,y+175-thumb.height),thumb)
 draw.text((x+10,y+190),name,fill=(255,245,215));draw.text((x+10,y+205),mount+' mount / source candidate',fill=(245,240,220))
sheet.save(root/'review.png')
kit={'schemaVersion':1,'id':'crossing-building-details-sheet-01','status':'source-candidate','runtimeAdmitted':False,'source':'source-01-magenta.png','sourceSha256':m['source_sha256'],'extraction':'extracted-01/metadata.json','usableCandidateCount':12,'rejectedCount':0,'components':components,'restrictions':['Generic architecture; no named room assignment without prose evidence','Fixed high three-quarter and upper-left lighting; no automatic rotation/mirroring','Candidate individual parts, not certified mutually seamless kit','Generated relative sizes vary: windows larger than half-door requested; consumers must author relative scales and wall mounting deliberately','Wall and roof anchors do not mean ground pivots; no underlay cutout/occlusion implementation provided']}
(root/'kit.json').write_text(json.dumps(kit,indent=2)+'\n')
print('Packaged12 extracted candidates; contact sheet at50%source scale; no runtime admission')
