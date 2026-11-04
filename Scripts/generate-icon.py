#!/usr/bin/env python3
"""Original geometric prism artwork, generated at Retina resolutions."""
from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path
import json, math
root=Path(__file__).resolve().parents[1]/'macOS/Resources/Assets.xcassets'
icons=root/'AppIcon.appiconset'; icons.mkdir(parents=True,exist_ok=True)
size=1024
image=Image.new('RGBA',(size,size),(0,0,0,0))
canvas=Image.new('RGBA',(size,size)); draw=ImageDraw.Draw(canvas)
for y in range(size):
    t=y/size
    draw.line((0,y,size,y),fill=(int(15+22*t),int(24+8*t),int(53+28*t),255))
mask=Image.new('L',(size,size)); ImageDraw.Draw(mask).rounded_rectangle((50,50,974,974),radius=210,fill=255)
image.paste(canvas,(0,0),mask)
glow=Image.new('RGBA',image.size); d=ImageDraw.Draw(glow)
d.ellipse((190,100,850,900),fill=(32,173,245,100)); glow=glow.filter(ImageFilter.GaussianBlur(95)); image=Image.alpha_composite(image,glow)
d=ImageDraw.Draw(image)
# Refracting planes, a globe arc, and a connectivity point.
d.polygon([(512,190),(790,738),(512,650)],fill=(107,223,245,220))
d.polygon([(512,190),(234,738),(512,650)],fill=(83,115,226,240))
d.polygon([(234,738),(512,650),(790,738),(512,832)],fill=(163,117,242,235))
d.line([(234,738),(512,190),(790,738),(512,832),(234,738)],fill=(203,244,255,230),width=7)
d.line([(512,190),(512,650),(790,738)],fill=(222,250,255,180),width=4)
d.arc((260,280,764,784),start=205,end=350,fill=(228,250,255,220),width=8)
d.ellipse((746,507,770,531),fill=(240,255,255,255))
entries=[]
for points in [16,32,128,256,512]:
    for scale in [1,2]:
        px=points*scale; filename=f'icon_{points}x{points}@{scale}x.png'
        image.resize((px,px),Image.Resampling.LANCZOS).save(icons/filename)
        entries.append({'idiom':'mac','size':f'{points}x{points}','scale':f'{scale}x','filename':filename})
(icons/'Contents.json').write_text(json.dumps({'images':entries,'info':{'author':'IP Prism','version':1}},indent=2))
(root/'Contents.json').write_text(json.dumps({'info':{'author':'IP Prism','version':1}}))
