from pathlib import Path
import numpy as np
from PIL import Image,ImageFilter,ImageDraw
import json
SOURCE_ROOT=Path(__file__).resolve().parents[1]
out=SOURCE_ROOT/'assets/style';out.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(104)
n=256;y,x=np.mgrid[0:n,0:n];u=x/n;v=y/n
fine=rng.normal(0,.018,(n,n));large=np.sin(u*np.pi*8)*np.sin(v*np.pi*6)*.025
surfaces={}
row=y//32;bx=(x+(row%2)*32)%64;by=y%32
edge=np.minimum.reduce([bx,63-bx,by,31-by]);cells=rng.uniform(.72,.92,(8,5))
stone=cells[row,(x+(row%2)*32)//64]*(.96+fine)+.04*np.clip(edge/4,0,1)
stone*=.64+.36*np.clip(edge/2,0,1)
surfaces['stone']=stone
surfaces['plaster']=np.clip(.88+fine*.6+large,.72,1)
grain=np.sin(v*2*np.pi*22+np.sin(u*2*np.pi*3)*1.5)*.045+np.sin(v*2*np.pi*57)*.018
surfaces['wood']=np.clip(.80+grain+fine,.55,1)
rows=y//32;rx=(x+(rows%2)*16)%32;ry=y%32
seam=np.minimum.reduce([rx,31-rx,ry,31-ry]);slate=.68+.13*(ry/32)+fine+rng.uniform(-.04,.04,(8,9))[rows,(x+(rows%2)*16)//32]
slate*=.60+.40*np.clip(seam/2,0,1);surfaces['slate']=slate
for name,h in surfaces.items():
 h=np.clip(h,0,1);Image.fromarray(np.uint8(h[:,:,None]*np.ones((1,1,3))*255)).save(out/(name+'_color.png'))
 dx=(np.roll(h,-1,1)-np.roll(h,1,1))*.7;dy=(np.roll(h,-1,0)-np.roll(h,1,0))*.7
 normal=np.stack([-dx,-dy,np.ones_like(h)],axis=-1);normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
 Image.fromarray(np.uint8((normal*.5+.5)*255)).save(out/(name+'_normal.png'))
# Contact occlusion baked once from original shop footprints; no runtime shadow pass.
ao=Image.new('L',(512,512),255);draw=ImageDraw.Draw(ao)
t=json.loads((SOURCE_ROOT/'data/town.json').read_text())
for shop in t['shops']:
 b=shop.get('b')
 if not b:continue
 sx,sy,w,h=b
 draw.rectangle(((sx+.05)/44*512,(sy+.1)/34*512,(sx+w-.05)/44*512,(sy+h+.3)/34*512),fill=75)
# temple footprint retained from the map
# blur creates soft ground contact around existing buildings, not hard sun shadows.
ao=ao.filter(ImageFilter.GaussianBlur(6));ao.save(out/'town_ao.png')
print('Created',len(list(out.glob('*.png'))),'small reusable material textures')
