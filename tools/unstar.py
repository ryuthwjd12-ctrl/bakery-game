import numpy as np
from PIL import Image
def amap(cx,cy,r,p,A,feather=0.8,size=(768,1408)):
    yy,xx=np.mgrid[0:size[0],0:size[1]].astype(float)
    d=(np.abs(xx-cx)/r)**p+(np.abs(yy-cy)/r)**p
    # distance-ish feather in units of d
    s=np.clip((1-d)/ (feather*p/r*3) +0.5,0,1)
    return A*s
def restore(im,a):
    a3=a[...,None]
    return np.clip((im-a3*255)/(1-a3),0,255)
def tv(img,box):
    x0,y0,x1,y1=box
    r=img[y0:y1,x0:x1]
    return np.abs(np.diff(r,axis=0)).sum()+np.abs(np.diff(r,axis=1)).sum()
def fit(im,cx0=1288,cy0=648):
    box=(cx0-34,cy0-34,cx0+34,cy0+34)
    best=None
    for A in np.arange(0.2,0.55,0.03):
     for r in [22,24,26,28]:
      for p in [0.55,0.65,0.75]:
       for dx in [-2,-1,0,1,2]:
        for dy in [-2,-1,0,1,2]:
          a=amap(cx0+dx,cy0+dy,r,p,A)
          v=tv(restore(im,a),box)
          if best is None or v<best[0]: best=(v,A,r,p,cx0+dx,cy0+dy)
    return best

from scipy import ndimage
def ringmask(cx,cy,r,p,band=0.22,size=(768,1408)):
    yy,xx=np.mgrid[0:size[0],0:size[1]].astype(float)
    d=(np.abs(xx-cx)/r)**p+(np.abs(yy-cy)/r)**p
    return np.abs(d-1)<band
def diffuse(img,mask,it=150):
    w=img.copy()
    ys,xs=np.where(mask); y0,y1,x0,x1=ys.min()-4,ys.max()+5,xs.min()-4,xs.max()+5
    sub=w[y0:y1,x0:x1]; m=mask[y0:y1,x0:x1]
    for i in range(it):
        avg=np.stack([ndimage.uniform_filter(sub[...,c],3) for c in range(3)],-1)
        sub[m]=avg[m]
    w[y0:y1,x0:x1]=sub
    return w
def unstar(im,cx=1287,cy=648,r=26,p=0.65,A=0.3):
    out=restore(im,amap(cx,cy,r,p,A))
    return diffuse(out,ringmask(cx,cy,r,p))
