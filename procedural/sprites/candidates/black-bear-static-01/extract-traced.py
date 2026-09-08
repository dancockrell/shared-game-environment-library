"""Invoke the existing Cattle Trail polygon cutter without its unrelated atlas jobs.
No new matting algorithm: authored contour is source-specific data.
"""
import ast, hashlib, json
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np

root=Path(__file__).resolve().parent
upstream=Path('C:/Users/Admin/Documents/Codex/2026-09-07/referenced-chatgpt-conversation-this-is-an-2/outputs/cattle-trail/tools/extract_assets.py')
tree=ast.parse(upstream.read_text())
cut_node=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='cut')
scope={'Image':Image,'ImageDraw':ImageDraw,'np':np,'sources':{0:Image.open(root/'source-02-alpha.png').convert('RGBA')}}
exec(compile(ast.Module(body=[cut_node],type_ignores=[]),str(upstream),'exec'),scope)
polygon=[(200,680),(192,627),(194,529),(217,473),(197,446),(198,402),(211,386),(238,384),(267,407),(278,426),(341,381),(401,340),(475,303),(528,301),(569,280),(616,243),(674,211),(718,202),(756,194),(806,194),(840,203),(889,219),(935,254),(975,295),(1005,341),(1030,399),(1046,465),(1040,535),(1049,588),(1065,677),(1074,751),(1060,811),(1037,851),(1001,871),(968,875),(935,858),(910,850),(914,824),(944,793),(936,759),(904,719),(874,673),(843,648),(819,669),(813,747),(791,787),(733,812),(718,847),(714,902),(694,977),(660,1007),(619,1027),(585,1037),(557,1025),(522,1011),(515,982),(535,951),(558,924),(557,851),(544,781),(525,753),(477,721),(455,712),(442,743),(428,842),(414,909),(392,941),(350,966),(298,976),(260,966),(215,944),(210,914),(245,880),(264,858),(272,788),(277,743),(246,739),(217,723)]
box=(185,190,1080,1045)
im=scope['cut'](0,box,polygon)
im.save(root/'standing-traced.png')
record={'status':'traced-source-candidate-pending-review','source':'source-02-alpha.png','sourceSha256':hashlib.sha256((root/'source-02-alpha.png').read_bytes()).hexdigest(),'existingCutter':str(upstream),'cutterSha256':hashlib.sha256(upstream.read_bytes()).hexdigest(),'box':box,'polygon':polygon,'file':'standing-traced.png','size':im.size,'sha256':hashlib.sha256((root/'standing-traced.png').read_bytes()).hexdigest(),'transformation':'Existing Cattle cut function with authored polygon; crop, binary alpha, source RGB unchanged. No resizing or global color removal.'}
(root/'traced-extraction.json').write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps({'size':im.size,'sha256':record['sha256']}))
