from PIL import Image
import numpy as np
from scipy import ndimage as ndi
im=Image.open('/mnt/user-data/uploads/dimas_sprite_sheet.png').convert('RGB')
a=np.array(im).astype(int)
mx=a.max(2); mn=a.min(2); sat=mx-mn
bg=(sat<28)&(mx>150)&(mx<232)&(a[:,:,2]>=a[:,:,0])
fg=~bg; fg[:80,:]=False
lab,n=ndi.label(fg, structure=np.ones((3,3)))
sizes=ndi.sum(fg,lab,range(1,n+1)); objs=ndi.find_objects(lab)
comps=[(i+1,objs[i]) for i in range(n) if sizes[i]>800]
comps.sort(key=lambda c:(0 if c[1][0].start<380 else (1 if c[1][0].start<700 else 2), c[1][1].start))
gray=a.mean(2)
def best_grid(edge, lo=4.9, hi=5.4):
    best=(-1,0,0); L=len(edge)
    for p in np.arange(lo,hi,0.01):
        for off in np.arange(0,p,0.2):
            idx=np.round(np.arange(off,L,p)).astype(int); idx=idx[idx<L]
            s=edge[idx].sum()/len(idx)
            if s>best[0]: best=(s,p,off)
    return best
native=[]
for lid,o in comps:
    sub=gray[o]; m=ndi.binary_fill_holes(lab[o]==lid)
    ex=np.abs(np.diff(sub,axis=1)); ex=(ex*(m[:,1:]|m[:,:-1])).sum(0)
    ey=np.abs(np.diff(sub,axis=0)); ey=(ey*(m[1:,:]|m[:-1,:])).sum(1)
    _,px,ox=best_grid(ex); _,py,oy=best_grid(ey)
    h,w=m.shape
    nx=int((w-ox)//px)+1; ny=int((h-oy)//py)+1
    rgb=a[o]
    out=np.zeros((ny,nx,4),np.uint8)
    for j in range(ny):
        y0=oy+j*py; y1=y0+py
        for i in range(nx):
            x0=ox+i*px; x1=x0+px
            ya=int(round(y0+py*0.25)); yb=max(ya+1,int(round(y1-py*0.25)))
            xa=int(round(x0+px*0.25)); xb=max(xa+1,int(round(x1-px*0.25)))
            ya=max(ya,0); xa=max(xa,0)
            blk=m[ya:yb,xa:xb]
            if blk.size==0 or blk.mean()<0.5: continue
            pix=rgb[ya:yb,xa:xb][blk]
            out[j,i,:3]=np.median(pix,axis=0).astype(np.uint8); out[j,i,3]=255
    # potong bbox
    ys,xs=np.nonzero(out[:,:,3])
    out=out[ys.min():ys.max()+1, xs.min():xs.max()+1]
    native.append(out)
    print(out.shape, round(px,2), round(py,2))
np.save('/tmp/native.npy', np.array(native,dtype=object), allow_pickle=True)
# pratinjau
W=sum(f.shape[1]+2 for f in native); H=max(f.shape[0] for f in native)
sheet=Image.new('RGBA',(W,H),(110,150,110,255)); x=0
for f in native:
    sheet.alpha_composite(Image.fromarray(f),(x,H-f.shape[0])); x+=f.shape[1]+2
sheet.resize((W*3,H*3),Image.NEAREST).save('/tmp/native_preview.png')
