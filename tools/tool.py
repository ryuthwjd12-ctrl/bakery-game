import sys
from PIL import Image
import numpy as np
from scipy import ndimage
def cutout(path,tol=22):
    im=Image.open(path).convert('RGB');a=np.asarray(im).astype(int)
    h,w,_=a.shape
    bg=np.median(np.concatenate([a[0],a[-1],a[:,0],a[:,-1]]),axis=0)
    near=(np.abs(a-bg).sum(axis=2)<tol)
    lab,n=ndimage.label(near)
    border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
    bgmask=np.isin(lab,list(border))
    alpha=np.where(bgmask,0,255).astype(np.uint8)
    # soften edge: pixels adjacent to bg that are near-bg get partial
    rgba=np.dstack([a.astype(np.uint8),alpha])
    return Image.fromarray(rgba,'RGBA'),~bgmask
def components(mask,minarea=800):
    lab,n=ndimage.label(mask)
    objs=ndimage.find_objects(lab)
    out=[]
    for i,s in enumerate(objs):
        area=(lab[s]==i+1).sum()
        if area>=minarea:out.append((s[1].start,s[0].start,s[1].stop,s[0].stop,area,i+1))
    return out,lab
if __name__=='__main__':
    img,m=cutout(sys.argv[1]);c,_=components(m,int(sys.argv[2]) if len(sys.argv)>2 else 800)
    for b in sorted(c,key=lambda b:(round(b[1]/100),b[0])):print(b[:5])
