"""Register newly authored pixel heroes without modifying source PNG pixels.

Source alpha gutters determine crop rectangles; a reviewed whole-face template
locates the same nose/cheek/eye patch in every upright pose. Physics origins and
one scale per hero are preserved. No bitmap resampling or copied filler frames.
"""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter1d,label,find_objects
from scipy.signal import find_peaks,fftconvolve

ROOT=Path(__file__).resolve().parents[1]
HEROES=['aion','owl','sheep','wolf','rabbit','eren']
ANIMATIONS=['idle','run','jump','gun-run','gun-fire','shoulder-roll','hurt-fall','freeze','burn','ash','special']
SOURCES=['dc96f86c-5dbc-4086-ac2b-4213ff6c9edb','b558fb0b-9c7e-4cec-a607-1a5e524a237f','b14fe9f8-cd83-433a-ac5b-9e11ca8cc092','3a85d0bd-0b88-4616-bd48-4ebfd5a03c30','cc5e6f75-827e-4a6f-b045-1b0d18ff5189','006d49b9-1f9d-468b-b366-17b43d7daa79']
# Reviewed neutral near-eye landmarks. Full patches include cheek/nose/outline,
# so a similarly coloured science badge, coat or muzzle cannot replace a face.
NEUTRAL={'aion':[119,58],'owl':[150,58],'sheep':[145,68],'wolf':[114,63],'rabbit':[110,74],'eren':[151,55]}

def face_fit(q,t,expected=None,radius=None):
    q=q.astype(float)/255;t=t.astype(float)/255
    s=fftconvolve((q*q).sum(2),np.ones(t.shape[:2]),mode='valid')
    cross=sum(fftconvolve(q[:,:,c],t[::-1,::-1,c],mode='valid') for c in range(4))
    ssd=np.maximum(0,s+(t*t).sum()-2*cross)
    if expected is not None:
        yy,xx=np.indices(ssd.shape)
        ssd[(abs(xx+15-expected[0])>radius[0])|(abs(yy+17-expected[1])>radius[1])]=np.inf
    y,x=np.unravel_index(np.argmin(ssd),ssd.shape)
    return int(x),int(y),float(ssd[y,x]/max(.001,(t*t).sum()))

def cuts(v,n):
    step=len(v)/n
    fine=gaussian_filter1d(v.astype(float),1)
    valleys,_=find_peaks(-fine,distance=step*.35,prominence=fine.max()*.1)
    valleys=[int(p) for p in valleys if fine[p]<fine.max()*.1]
    # Ash and low-roll rows are deliberately shorter. A nominal lattice can
    # bisect a character when a peak disappears; actual clear gutters win.
    if len(valleys)==n-1:return [0]+valleys+[len(v)]
    s=gaussian_filter1d(v.astype(float),step*.12)
    peaks,_=find_peaks(s,distance=step*.63,prominence=s.max()*.075)
    if len(peaks)!=n:peaks=np.array([(i+.5)*step for i in range(n)])
    smooth=gaussian_filter1d(v.astype(float),max(1,step*.018));out=[0]
    for lo,hi in zip(peaks,peaks[1:]):
        x0=round(lo+(hi-lo)*.28);x1=round(hi-(hi-lo)*.28)
        xs=np.flatnonzero(smooth[x0:x1+1]<=smooth[x0:x1+1].min()+1e-7)+x0
        out.append(int(min(xs,key=lambda x:abs(x-(lo+hi)/2))))
    return out+[len(v)]

def isolated(a,f):
    x,y,w,h=f['rect'];q=a[y:y+h,x:x+w].copy();mask=np.zeros(q.shape[:2],bool)
    for yy,xx,n in f['runs']:mask[yy,xx:xx+n]=True
    q[~mask]=0
    return q

def atlas(hero):
    path=ROOT/'assets'/('pixel-'+hero+'.png');a=np.array(Image.open(path).convert('RGBA'));h,w=a.shape[:2]
    global_labels,_=label(a[:,:,3]>=192,np.ones((3,3)));objects=find_objects(global_labels)
    ys=cuts((a[:,:,3]>=192).sum(1),11);rows=[]
    for row in range(11):
        strip=a[ys[row]:ys[row+1]];xs=cuts((strip[:,:,3]>=192).sum(0),6);line=[]
        for col in range(6):
            q=strip[:,xs[col]:xs[col+1]];labs,n=label(q[:,:,3]>=192,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0
            body=labs==sizes.argmax();yy,xx=np.where(body);bb=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
            # Retain the detached halo and the small, forward-only muzzle glint.
            keep=body.copy()
            for k in range(1,n+1):
                if sizes[k]<max(4,sizes.max()*.002):continue
                yy,xx=np.where(labs==k)
                if (hero=='sheep' and yy.max()<bb[1]+(bb[3]-bb[1])*.3) or row in [7,8,9] or (row==4 and xx.min()>bb[0]+(bb[2]-bb[0])*.7):keep|=labs==k
            # A high ear / airborne foot can cross the row's nominal gutter.
            # Recover the COMPLETE connected silhouette from source coordinates,
            # without copying neighbouring sprites or changing source pixels.
            yy,xx=np.where(body);global_id=int(global_labels[ys[row]+yy[0],xs[col]+xx[0]])
            sy,sx=objects[global_id-1]
            if sx.stop-sx.start>w/6*1.55 or sy.stop-sy.start>h/11*1.65:raise ValueError(('Source poses touch each other',hero,row,col))
            rx=min(xs[col],sx.start-2);ry=min(ys[row],sy.start-2);rx=max(0,rx);ry=max(0,ry)
            ex=min(w,max(xs[col+1],sx.stop+2));ey=min(h,max(ys[row+1],sy.stop+2))
            expanded=global_labels[ry:ey,rx:ex]==global_id
            expanded[ys[row]-ry:ys[row+1]-ry,xs[col]-rx:xs[col+1]-rx]|=keep
            keep=expanded;yy,xx=np.where(global_labels[ry:ey,rx:ex]==global_id);bb=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
            yy,xx=np.where(keep);b=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)];runs=[]
            for y in range(b[1],b[3]):
                z=np.diff(np.pad(keep[y].astype(np.int8),(1,1)))
                runs.extend([[y,int(x),int(e-x)] for x,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
            line.append({'rect':[rx,ry,ex-rx,ey-ry],'bounds':b,'body_bounds':bb,'runs':runs,'eye':None,'source_column':col,'origin':[float((bb[0]+bb[2])/2),float(bb[3])],'registration':'body-axis-and-ground'})
        rows.append(line)
    height=np.median([f['body_bounds'][3]-f['body_bounds'][1] for f in rows[0]])
    factor=(92 if hero in ['rabbit','eren'] else 82)/height
    return a,{'path':str(path.relative_to(ROOT)),'width':w,'height':h,'rows':11,'columns':6,'row_counts':[6]*11,'frames':rows,'scale':[float(factor)]*11,'anchor_x':[0]*11,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

def main():
    atlases={};arrays={}
    for hero in HEROES:arrays[hero],atlases['pixel-'+hero]=atlas(hero)
    data={'version':'0.20.0','status':'New game rendering; owner art approval is separate from technical validation. Original source/model sheets retained.','method':'New drawn poses, unchanged original generated PNGs; registered isolated alpha spans, a single scale per hero and independently reviewed full-face probes.','animations':ANIMATIONS,'generation_sources':dict(zip(HEROES,SOURCES)),'atlases':atlases,'aliases':{},'muzzles':{}}
    data['reference_policy']='Owner model references and existing original sheets determine identity. The inline black-cat image informs pixel clusters/material lighting only; no cat pixels, outfit or species are incorporated. Private references are not republished.'
    data['identities']={'aion':'Pink axolotl; cyan-tipped pink gills, blue eyes, white scientist coat/badges and DNA tail.','owl':'Orange/brown owl; cream facial disk/chest, amber eyes, feathered wings and yellow beak/talons.','sheep':'Cream wool sheep; amber eyes, drooping ears, brown hooves and gold halo.','wolf':'Purple/gray wolf; cyan eyes, cream muzzle/chest/tailtip, purple forearm rune; no shirt or lab coat.','rabbit':'Emre: tan rabbit, green eyes, blue shirt/plain red tie, dark trousers, bare rabbit feet.','eren':'Eren: orange-brown rabbit, dark plum eyes/black eyelashes, freckles, spiky cheek tufts, dark teal jacket/striped tie, brown shoes.'}
    report=[]
    for hero in HEROES:
        a=atlases['pixel-'+hero];source=arrays[hero];factor=a['scale'][0]
        ref=a['frames'][0][0];eye=NEUTRAL[hero];x,y=eye[0]-15,eye[1]-17
        t=isolated(source,ref)[y:y+38,x:x+43]
        target=[14.,float((eye[1]-ref['body_bounds'][3])*factor)]
        a['target_eye']=target;a['head_spans']=[float({'aion':95,'owl':83,'sheep':100,'wolf':84,'rabbit':60,'eren':70}[hero])]*11
        for row in [0,1,2,3,4,7,8,10]:
            target_row=target.copy()
            if row==10 and hero=='wolf':target_row[1]=-39.
            if row==10 and hero=='owl':target_row[1]=target[1]
            for col,f in enumerate(a['frames'][row]):
                expected=None;radius=None
                if row in [7,8]:
                    b=f['body_bounds'];rb=ref['body_bounds']
                    ratios=[(eye[i]-rb[i])/(rb[i+2]-rb[i]) for i in [0,1]]
                    expected=[b[i]+ratios[i]*(b[i+2]-b[i]) for i in [0,1]]
                    radius=[(b[2]-b[0])*.24,(b[3]-b[1])*.10]
                xx,yy,error=face_fit(isolated(source,f),t,expected,radius)
                if error>.48:raise ValueError(('Anatomical face review required',hero,row,col,error))
                marker=[xx+15,yy+17]
                f['eye']=marker;f['head_probe']=[xx,yy,43,38]
                f['origin']=[marker[0]-target_row[0]/factor,marker[1]-target_row[1]/factor]
                # Emre's charge visibly lowers knees/body instead of fixing Y.
                if row==10 and hero=='rabbit':f['origin'][1]=float(f['body_bounds'][3])
                if row in [7,8]:f['origin'][1]=float(f['body_bounds'][3])
                f['registration']='whole-face'
                report.append({'hero':hero,'row':row,'frame':col,'residual':round(error,5),'probe':f['head_probe'],'eye':marker})
        # Projectiles and airborne weapon overlays share this measured barrel.
        f=a['frames'][3][0];q=isolated(source,f)
        muzzle_mask=(q[:,:,3]>=192);muzzle_mask[:round(f['eye'][1]+6)]=False;muzzle_mask[round(f['eye'][1]+45):]=False
        yy,xx=np.where(muzzle_mask);front=xx>=xx.max()-2
        data['muzzles'][hero]=[float((xx.max()+1-f['origin'][0])*factor),float((np.median(yy[front])-f['origin'][1])*factor)]
        data['aliases']['runner-'+hero]=[{'atlas':'pixel-'+hero,'row':r} for r in [0,1,2,7,8,9,10,2]]
    for key,row in [('gun-run',3),('gun-fire',4),('heroes',3),('rolls',5)]:data['aliases'][key]=[{'atlas':'pixel-'+hero,'row':row} for hero in HEROES]
    data['aliases']['deaths']=[{'atlas':'pixel-'+hero,'row':6} for hero in HEROES for _ in range(2)]
    data['aliases']['actions']=[{'atlas':'pixel-'+hero,'row':r} for hero,r in [('wolf',10),('owl',10),('sheep',2)]]
    # Enemy impact starts already falling; obstacle impact first stumbles.
    # Four reused authored poses form a separate playback clip, not new art.
    for hero in HEROES:
        a=atlases['pixel-'+hero];a['physical_rows']=11;a['rows']=12
        a['frames'].append(a['frames'][6][2:]);a['row_counts'].append(4)
        a['scale'].append(a['scale'][0]);a['anchor_x'].append(0);a['head_spans'].append(a['head_spans'][0])
    data['aliases']['deaths']=[{'atlas':'pixel-'+hero,'row':r} for hero in HEROES for r in [6,11]]
    data['new_drawn_poses']=396
    data['playback_note']='Rows0..10 are the 396 unique authored source drawings. Virtual row11 reuses four forward-fall drawings per hero for enemy faceplants; it is not counted as new artwork.'
    data['face_registration']=report
    # A first-pass contact sheet is for manual anatomical registration review.
    preview=Image.new('RGBA',(1200,260),(30,27,37,255))
    for i,hero in enumerate(HEROES):
        f=atlases['pixel-'+hero]['frames'][0][0];q=Image.fromarray(isolated(arrays[hero],f));preview.alpha_composite(q,(200*i,0))
        print(hero,'first neutral crop',f['rect'],'body',f['body_bounds'],'scale',atlases['pixel-'+hero]['scale'][0])
    out=ROOT/'build/pixel-review';out.mkdir(parents=True,exist_ok=True);preview.save(out/'neutral-contact-sheet.png')
    (ROOT/'assets/PIXEL-HEROES-PROVENANCE.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
    print('Largest face residuals',sorted(report,key=lambda x:-x['residual'])[:12]);print('Measured muzzles',data['muzzles'])

if __name__=='__main__':main()
