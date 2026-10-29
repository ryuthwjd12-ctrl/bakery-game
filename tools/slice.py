"""제미나이 원본 그림(art/raw)을 잘라 게임 그림(assets)으로 만들어요. 실행: python3 tools/slice.py"""
import sys, os, json
HERE=os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0,HERE)
from tool import cutout
from PIL import Image
import numpy as np
from scipy import ndimage
R=os.path.join(HERE,'..','art','raw')+'/'
OUT=os.path.join(HERE,'..','assets')+'/'
for d in ['characters','customers','items','furniture','backgrounds','ui']: os.makedirs(OUT+d,exist_ok=True)

cache={}
def cut(f,tol=22):
    if (f,tol) not in cache: cache[(f,tol)]=cutout(R+f,tol)
    return cache[(f,tol)]

def grab(f,box,tol=22,keep_largest=False,clear_shadow=None):
    """crop box from cutout sheet, return RGBA trimmed"""
    im,m=cut(f,tol)
    x0,y0,x1,y1=box
    a=np.array(im.crop(box))
    mask=a[...,3]>0
    if clear_shadow is not None:
        rgb=a[...,:3].astype(int)
        sh=(np.abs(rgb-np.array(clear_shadow)).sum(axis=2)<40)
        # only near bottom
        rows=np.arange(a.shape[0])[:,None]
        sh&=rows>a.shape[0]-60
        mask&=~sh
    lab,n=ndimage.label(mask)
    if n:
        sizes=ndimage.sum(mask,lab,range(1,n+1))
        if keep_largest:
            mask=lab==(np.argmax(sizes)+1)
        else:
            big=[i+1 for i,s in enumerate(sizes) if s>=max(60,0.02*sizes.max())]
            mask=np.isin(lab,big)
    a[...,3]=np.where(mask,255,0)
    return Image.fromarray(a,'RGBA')

def trim(im):
    bb=im.getbbox(); return im.crop(bb)

def split_seeds(f,box,seed_ymax,tol=22):
    """split merged frames: seeds from components above seed_ymax (sheet coords), geodesic grow"""
    im,m=cut(f,tol)
    x0,y0,x1,y1=box
    sub=m[y0:y1,x0:x1]
    seedmask=sub.copy(); seedmask[seed_ymax-y0:,:]=False
    lab,n=ndimage.label(seedmask)
    sizes=ndimage.sum(seedmask,lab,range(1,n+1))
    keep=[i+1 for i,s in enumerate(sizes) if s>2000]
    L=np.zeros(sub.shape,int)
    for k,i in enumerate(keep): L[lab==i]=k+1
    # grow
    st=ndimage.generate_binary_structure(2,1)
    for _ in range(2000):
        un=(L==0)&sub
        if not un.any(): break
        grown=ndimage.grey_dilation(L,footprint=st)
        upd=un&(grown>0)
        if not upd.any(): break
        L[upd]=grown[upd]
    arr=np.array(im)[y0:y1,x0:x1]
    frames=[]
    order=sorted(range(1,len(keep)+1),key=lambda k:np.where(L==k)[1].mean())
    for k in order:
        a=arr.copy(); a[...,3]=np.where(L==k,255,0)
        frames.append(trim(Image.fromarray(a,'RGBA')))
    return frames

def normalize(frames,target_h,name,scale=None):
    """scale so median height=target_h, put on common canvas, bottom aligned, head-centered; save strip"""
    hs=sorted(f.height for f in frames); med=hs[len(hs)//2]
    s=scale if scale else target_h/med
    fr=[f.resize((max(1,round(f.width*s)),max(1,round(f.height*s))),Image.LANCZOS) for f in frames]
    # head centroid x
    cx=[]
    for f in fr:
        a=np.array(f)[...,3]>0; top=a[:max(1,int(a.shape[0]*0.3))]
        xs=np.where(top)[1]; cx.append(xs.mean() if len(xs) else f.width/2)
    left=max(c for c in cx); right=max(f.width-c for f,c in zip(fr,cx))
    W=int(np.ceil(left+right))+4; H=max(f.height for f in fr)+2
    W+=W%2
    strip=Image.new('RGBA',(W*len(fr),H),(0,0,0,0))
    for i,(f,c) in enumerate(zip(fr,cx)):
        strip.paste(f,(int(i*W+W/2-c),H-f.height-1),f)
    strip.save(OUT+name)
    return {'file':name,'frame_w':W,'frame_h':H,'count':len(fr),'scale':s}

meta={}
H=220
# ---- female walk 3x8 (front, back, right)
FW='01-03-female-walk-8frames.png'
im,m=cut(FW)
lab,n=ndimage.label(m)
def comps_in(mask,yr,minarea=3000):
    lab,n=ndimage.label(mask)
    out=[]
    for i,s in enumerate(ndimage.find_objects(lab)):
        if s is None: continue
        if s[0].start>=yr[0]-5 and s[0].stop<=yr[1]+5:
            area=(lab[s]==i+1).sum()
            if area>=minarea: out.append((s[1].start,s[0].start,s[1].stop,s[0].stop))
    return sorted(out)
for name,yr in [('front',(45,254)),('back',(288,494)),('right',(526,734))]:
    boxes=comps_in(m,yr)
    frs=[trim(grab(FW,b,keep_largest=True)) for b in boxes]
    print('female',name,len(frs))
    meta['female_'+name]=normalize(frs,H,f'characters/female_walk_{name}.png')
# ---- male
mr=[trim(grab('34-male-walk-right.png',b,keep_largest=True)) for b in [(80,71,365,723),(365,81,558,729)]]
mid=split_seeds('34-male-walk-right.png',(551,59,1104,726),450)
mr+=mid+[trim(grab('34-male-walk-right.png',(1095,75,1342,720),keep_largest=True))]
print('male right',len(mr))
meta['male_right']=normalize(mr,H,'characters/male_walk_right.png')
SH=(239,224,193)
mb=[trim(grab('35-male-walk-back.png',(x0,134,x1,682),clear_shadow=SH,keep_largest=True)) for x0,x1 in [(53,234),(279,455),(502,682),(728,910),(954,1133),(1176,1356)]]
meta['male_back']=normalize(mb,H,'characters/male_walk_back.png')
mf=[trim(grab('36-male-mixed-walk-front.png',b,keep_largest=True)) for b in [(111,34,230,376),(365,34,476,376),(568,33,696,376),(797,33,909,373)]]
meta['male_front']=normalize(mf,H,'characters/male_walk_front.png')
# ---- puppy
P='12-waiter-puppy-and-walkers.png'
def pboxes(bs): return [trim(grab(P,b,keep_largest=True)) for b in bs]
PH=120
meta['puppy_front']=normalize(pboxes([(57,34,145,163),(158,34,246,163),(260,34,348,162),(362,34,450,162)]),PH,'characters/puppy_front.png')
meta['puppy_back']=normalize(pboxes([(563,35,644,163),(658,35,739,162),(753,35,834,163),(847,35,928,163)]),PH,'characters/puppy_back.png')
meta['puppy_right']=normalize(pboxes([(564,175,637,301),(659,175,732,301),(756,175,829,302),(850,175,924,301)]),PH,'characters/puppy_right.png')
meta['puppy_tray']=normalize(pboxes([(1008,173,1124,294),(1135,172,1251,293),(1262,172,1378,293)]),PH,'characters/puppy_tray.png')
meta['puppy_sweep']=normalize(pboxes([(1007,309,1109,430),(1135,309,1237,430),(1260,309,1363,430)]),PH,'characters/puppy_sweep.png')
# ---- customers standing (from sheet 12) and seated (sheet 13)
stand={'rabbit':(49,427,116,573),'cat':(363,444,441,572),'deer':(713,422,808,571),'chick':(366,624,439,742)}
for k,b in stand.items():
    f=trim(grab(P,b,keep_largest=True)); s=110/f.height if k!='chick' else 85/f.height
    f=f.resize((round(f.width*s),round(f.height*s)),Image.LANCZOS); f.save(OUT+f'customers/{k}_stand.png')
C='13-customers-a.png'
seated={'rabbit':[(119,46,359,347),(401,45,645,347)],'cat':[(794,87,1045,346),(1073,87,1334,347)],
        'deer':[(98,424,357,723),(404,418,665,723)],'chick':[(793,507,1040,722),(1078,504,1330,723)]}
for k,(w,e) in seated.items():
    for tag,b in [('wait',w),('eat',e)]:
        f=trim(grab(C,b))
        s=0.62; f=f.resize((round(f.width*s),round(f.height*s)),Image.LANCZOS)
        f.save(OUT+f'customers/{k}_{tag}.png')
# ---- icons
I='27-32-items-and-keyart.png'
def icon(box,name,size=72,folder='items/'):
    x0,y0,x1,y1=box
    crop=Image.open(R+I).convert('RGB').crop((x0+3,y0+3,x1-3,y1-3))
    a=np.asarray(crop).astype(int)
    bg=np.median(np.concatenate([a[0],a[-1],a[:,0],a[:,-1]]),axis=0)
    near=np.abs(a-bg).sum(axis=2)<34
    lab,n=ndimage.label(near)
    border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
    bgm=np.isin(lab,list(border))
    fg=~bgm
    l2,n2=ndimage.label(fg)
    if n2:
        sz=ndimage.sum(fg,l2,range(1,n2+1)); fg=np.isin(l2,[i+1 for i,s in enumerate(sz) if s>=0.05*sz.max()])
    rgba=np.dstack([a.astype(np.uint8),np.where(fg,255,0).astype(np.uint8)])
    im=trim(Image.fromarray(rgba,'RGBA'))
    s=(size-6)/max(im.size); im=im.resize((max(1,round(im.width*s)),max(1,round(im.height*s))),Image.LANCZOS)
    c=Image.new('RGBA',(size,size)); c.paste(im,((size-im.width)//2,(size-im.height)//2),im); c.save(OUT+folder+name+'.png')
IX=[28,103,180,258,335,411,488,565,643]; IY=[51,126,201]
def ib(c,r,xs=IX,ys=IY,w=73): return (xs[c],ys[r],xs[c]+w,ys[r]+w)
for nm,(c,r) in {'flour':(0,0),'sugar':(1,0),'butter':(2,0),'egg':(3,0),'milk':(4,0),'chocolate':(5,0),'cream':(6,0),'raspberry':(0,1),'acorn':(3,1),'honey':(5,1)}.items():
    icon(ib(c,r),nm)
CX=[765,842,919,997,1075,1154,1232,1309]
for nm,(c,y) in {'butter_cookie':(0,50),'choco_cookie':(1,50),'star_cookie':(2,50),'jam_cookie':(3,50),'milk_bread':(0,126)}.items():
    icon((CX[c],y,CX[c]+74,y+72),nm)
for nm,c in {'raspberry_cake':0,'warm_milk':6}.items():
    icon((IX[c],317,IX[c]+73,389),nm)
TX=[27,103,179,257,335,410,488,565,642,716]
for nm,(c,y) in {'bowl':(0,469),'rolling_pin':(1,469),'star_cutter':(2,469),'cake_tin':(4,469),'piping_bag':(7,469),'cake_plate':(1,545),'mug':(5,545)}.items():
    icon((TX[c],y,TX[c]+74,y+72),nm)
# furniture
for nm,b in {'round_table':(30,674,110,742),'pink_chair':(210,662,266,745),'display_case':(344,662,426,744),'plant':(505,661,562,744),'picture':(623,667,709,738),'lamp':(574,659,613,744)}.items():
    f=trim(grab(I,b,keep_largest=True)); f.save(OUT+'furniture/'+nm+'.png')
icon((1075,314,1151,387),'rug_icon',size=96,folder='furniture/')
# ---- animal sheets: 4 rows x 8 (front, back, right walk; sit row)
os.makedirs(OUT+'animals',exist_ok=True)
ANIMAL_SHEETS={'rabbit':'42-rabbit.png'}
def row_frames(f,yr):
    im,m=cut(f)
    lab,n=ndimage.label(m)
    out=[]
    for i,sl in enumerate(ndimage.find_objects(lab)):
        if sl is None: continue
        cy=(sl[0].start+sl[0].stop)/2
        if yr[0]<=cy<yr[1] and (lab[sl]==i+1).sum()>1500:
            out.append((sl[1].start,sl[0].start,sl[1].stop,sl[0].stop))
    return [trim(grab(f,b,keep_largest=True)) for b in sorted(out)]
for name,f in ANIMAL_SHEETS.items():
    hgt=Image.open(R+f).height; band=hgt/4
    rows=[row_frames(f,(band*i,band*(i+1))) for i in range(4)]
    hs=sorted(x.height for x in rows[0]); sc=118/hs[len(hs)//2]
    for anim,frs in zip(['front','back','right','sit'],rows):
        meta[name+'_'+anim]=normalize(frs,118,f'animals/{name}_{anim}.png',scale=sc)
# rabbit sit row: 0,1 wait / 3,4 eat / 5 happy / 7 sad -> split into named strips
import shutil
def split_strip(name,src,groups):
    info=meta.pop(name+'_'+src); im=Image.open(OUT+info['file'])
    W=info['frame_w']
    for g,idx in groups.items():
        st=Image.new('RGBA',(W*len(idx),im.height))
        for k,i in enumerate(idx): st.paste(im.crop((i*W,0,(i+1)*W,im.height)),(k*W,0))
        fn=f'animals/{name}_{g}.png'; st.save(OUT+fn)
        meta[name+'_'+g]=dict(info,file=fn,count=len(idx))
    os.remove(OUT+info['file'])
split_strip('rabbit','sit',{'wait':[0,1],'eat':[3,4],'happy':[5],'sad':[7]})
# mixed sheet (43): boxes by animal
M='43-animals-mixed.png'
MIX={
 'cat':{'front':[(732,25,803,134),(838,25,910,135),(944,25,1016,134),(1050,25,1124,134),(1158,25,1229,135)],
        'back':[(726,147,802,255),(835,147,910,255),(941,147,1016,254)],
        'right':[(1047,148,1121,254),(1153,148,1227,255),(1259,148,1332,255)],
        'wait':[(726,268,801,372),(835,267,908,372)],'eat':[(954,268,1016,372),(1059,267,1121,372)],
        'happy':[(1163,268,1225,372)],'sad':[(1269,273,1334,373)]},
 'deer':{'front':[(39,408,113,536),(322,409,393,535)],'back':[(138,408,212,536)],'right':[(230,408,298,536)]},
 'bear':{'front':[(46,553,111,655),(325,554,389,653)],'back':[(142,553,206,655)],'right':[(234,553,300,654)],
         'wait':[(50,664,110,750),(144,665,204,750)],'eat':[(238,665,296,750)],'happy':[(328,665,388,750)]},
 'chick':{'front':[(470,419,520,486),(548,421,598,486),(626,419,676,486),(701,421,750,486),(777,421,825,485),(851,421,900,486)],
          'back':[(626,497,678,567),(702,499,753,567)],'right':[(778,499,828,566),(852,499,903,567)],
          'wait':[(470,667,522,744),(702,673,753,742)],'eat':[(549,668,601,744),(778,674,826,742)],'happy':[(627,668,678,744)]},
 'squirrel':{'front':[(945,578,1015,658),(1030,578,1098,658),(1113,578,1178,657),(1192,577,1259,657),(1274,578,1342,657)],
             'right':[(947,498,1010,570),(1033,499,1094,570),(1116,499,1175,569),(1196,499,1255,570),(1275,499,1338,569)],
             'wait':[(945,668,1017,748),(1031,668,1102,749)],'eat':[(1112,668,1179,750),(1190,668,1261,748)],'happy':[(1273,668,1343,748)]},
}
for name,anims in MIX.items():
    fr={a:[trim(grab(M,b,keep_largest=True)) for b in bs] for a,bs in anims.items()}
    hs=sorted(x.height for x in fr['front']); sc=(96 if name=='chick' else 116)/hs[len(hs)//2]
    for a,frs in fr.items():
        meta[name+'_'+a]=normalize(frs,116,f'animals/{name}_{a}.png',scale=sc)
# sprite data for the game
with open(os.path.join(HERE,'..','scripts','sprite_data.gd'),'w') as fh:
    fh.write('class_name SpriteData\nextends RefCounted\n## tools/slice.py가 만든 파일이에요. 직접 고치지 말아요.\n## 값: [그림 경로, 한 칸 너비, 높이, 칸 수]\n\nconst STRIPS := {\n')
    for k,v in meta.items():
        fh.write(f'\t"{k}": ["{v["file"][:-4]}", {v["frame_w"]}, {v["frame_h"]}, {v["count"]}],\n')
    fh.write('}\n')
# backgrounds
for src,dst in [('33-bakery-empty-room.png','hall_empty.png'),('17-kitchen.png','kitchen.png'),('18-acorn-village.png','acorn_village.png')]:
    Image.open(R+src).convert('RGB').save(OUT+'backgrounds/'+dst)
Image.open(R+I).convert('RGB').crop((828,436,1382,748)).save(OUT+'backgrounds/title.png')
print(json.dumps(meta,indent=0))
