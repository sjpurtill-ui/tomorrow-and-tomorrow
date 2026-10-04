"""Additive legacy garments fitted to the delivered court bodies.

Blender --background --factory-startup --python tools/blender/court_legacy_clothing.py
  -- --variants male_adult,female_old --outfits tunic,hide,robe

Never rewrites the original figures or the modern wardrobe. The body copy only
changes coverage for an explicitly replaced outfit; all source morphs and rig
data are copied. Each skirt half follows its own leg, with front/back vents.
"""
import argparse
import copy
import hashlib
import json
import math
import os
import sys
import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree
from mathutils.bvhtree import BVHTree

HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0,HERE)
import cf_body
import cf_dress
from court_era_wardrobe import Bundle, gl

CHANNELS={"hide":1,"tunic":2,"robe":3}
PARTS={"hide":["hide_wrap","hide_cape","hide_cord","hide_footwraps"],
       "tunic":["tunic_body","tunic_trim","tunic_belt","tunic_shoes"],
       "robe":["robe_body","robe_trim","robe_sash","robe_mantle","robe_mantle_edge","robe_shoes"]}


class LegacyBundle(Bundle):
    def __init__(self,path):
        super().__init__(path)
        arms=[i for i,n in enumerate(self.names) if n.split('.')[0] in ('upper_arm','forearm','hand','thumb','index','fingers')]
        self.trunk_mask=np.sum(self.w*np.isin(self.j,arms),axis=1)<.15
        head=[i for i,n in enumerate(self.names) if n.split('.')[0] in ('head','neck','jaw')]
        self.below_neck=np.sum(self.w*np.isin(self.j,head),axis=1)<.20
        torso=np.flatnonzero(self.trunk_mask)
        self.trunk_kd=KDTree(len(torso))
        for i in torso:self.trunk_kd.insert(Vector(self.p[i]),int(i))
        self.trunk_kd.balance()
        # Empty source garment nodes must not steal the replacement's exact name.
        for node in self.doc['nodes']:
            if any(node.get('name','').startswith(k+'_') for k in CHANNELS):
                node['name']='Source_'+node['name']

    def body_copy_masks(self,masks):
        mesh=copy.deepcopy(self.body);mesh['name']='LegacyBody'
        for primitive in mesh['primitives']:
            primitive['indices']=self.copy_accessor(primitive['indices'])
            primitive['attributes']={k:self.copy_accessor(v) for k,v in primitive['attributes'].items()}
            for target in primitive.get('targets',[]):
                for k,v in list(target.items()):target[k]=self.copy_accessor(v)
            colors=self.array(self.attrs['COLOR_0']).copy()
            high=np.iinfo(colors.dtype).max if colors.dtype.kind in 'iu' else 1.0
            for kind,mask in masks.items():colors[:,CHANNELS[kind]]=mask*high
            ca=self.source['accessors'][self.attrs['COLOR_0']]
            primitive['attributes']['COLOR_0']=self.accessor(colors,'VEC4',ca['componentType'],ca.get('normalized',False))
        self.doc['meshes'].append(mesh)
        node=next(n for n in self.doc['nodes'] if n.get('name')=='Body')
        node.update(name='LegacyBody',mesh=len(self.doc['meshes'])-1,skin=self.body_node['skin'])

    def copy_piece(self,name,below=None):
        source_node=next(n for n in self.source['nodes'] if n.get('name')==name)
        mesh=copy.deepcopy(self.source['meshes'][source_node['mesh']])
        for primitive in mesh['primitives']:
            if below is not None:
                points=self.array(primitive['attributes']['POSITION'])
                faces=self.array(primitive['indices']).reshape(-1,3)
                faces=faces[np.max(points[faces,1],axis=1)<=below]
                primitive['indices']=self.accessor(faces,'SCALAR',5125)
            else:primitive['indices']=self.copy_accessor(primitive['indices'])
            primitive['attributes']={k:self.copy_accessor(v) for k,v in primitive['attributes'].items()}
            for target in primitive.get('targets',[]):
                for k,v in list(target.items()):target[k]=self.copy_accessor(v)
        self.doc['meshes'].append(mesh)
        node=next(n for n in self.doc['nodes'] if n.get('name')=='Source_'+name)
        node.update(name=name,mesh=len(self.doc['meshes'])-1,skin=source_node['skin'])

    def finish_group(self,start,name):
        pieces=self.doc['meshes'][start:]
        if not pieces:raise RuntimeError('Empty cloth group '+name)
        prims=[p for mesh in pieces for p in mesh['primitives']]
        self.doc['meshes'][start:]=[{'name':name,'primitives':prims}]
        first=True
        for node in self.doc['nodes']:
            if node.get('mesh',-1)<start:continue
            if first:node.update(mesh=start,name=name);first=False
            else:node.pop('mesh',None);node.pop('skin',None);node['name']='Unused_'+node['name']

    def cape_join(self,name,cut,ease,k):
        """Sew the retained lower cape boundary under the matched shoulder cap."""
        mesh=next(m for m in self.source['meshes'] if m['name']==name)
        body_faces=self.faces[np.all(self.below_neck[self.faces],axis=1)]
        tree=BVHTree.FromPolygons(self.p.tolist(),body_faces.tolist(),all_triangles=True)
        for primitive in mesh['primitives']:
            a=primitive['attributes'];p=self.array(a['POSITION']);norm=self.array(a['NORMAL'])
            sj=self.array(a['JOINTS_0']);sw=self.array(a['WEIGHTS_0'])
            faces=self.array(primitive['indices']).reshape(-1,3)
            faces=faces[np.max(p[faces,1],axis=1)<=cut]
            edges={}
            for face in faces:
                for u,v in zip(face,np.roll(face,-1)):
                    key=tuple(sorted((int(u),int(v))))
                    edges.setdefault(key,[]).append((int(u),int(v)))
            boundary=[items[0] for key,items in edges.items() if len(items)==1 and min(p[key[0],1],p[key[1],1])>cut-.045*k]
            ids=sorted(set(v for edge in boundary for v in edge));lookup={v:i for i,v in enumerate(ids)}
            points=[];joints=[];weights=[];endpoints=[];endweights=[]
            for v in ids:
                probe=p[v].copy();probe[1]=cut+.035*k
                hit,_,face,_=tree.find_nearest(Vector(probe));tri_ids=body_faces[face];tri=self.p[tri_ids];hit=np.asarray(hit)
                uv=np.linalg.lstsq(np.column_stack((tri[1]-tri[0],tri[2]-tri[0])),hit-tri[0],rcond=None)[0]
                bary=np.maximum(np.array((1-uv.sum(),uv[0],uv[1])),0);bary/=bary.sum()
                normal=bary@self.n[tri_ids];normal/=max(np.linalg.norm(normal),1e-8)
                # End below the cap, so the overlap has a definite depth order.
                endpoint=hit+normal*(ease-.003*k if np.dot(norm[v],normal)>0 else ease-.006*k)
                full=np.zeros(len(self.names))
                for c in range(3):np.add.at(full,self.j[tri_ids[c]],self.w[tri_ids[c]]*bary[c])
                endpoints.append(endpoint);endweights.append(full)
            for t in np.linspace(0,1,5):
                for i,v in enumerate(ids):
                    points.append(p[v]*(1-t)+endpoints[i]*t)
                    full=endweights[i]*t;np.add.at(full,sj[v],sw[v]*(1-t))
                    j,w=joint_weights(self,full);joints.append(j);weights.append(w)
            count=len(ids);join_faces=[]
            for row in range(4):
                for u,v in boundary:
                    a=row*count+lookup[u];z=row*count+lookup[v]
                    join_faces.extend(((z,a,a+count),(z,a+count,z+count)))
            slot=self.source['materials'][primitive['material']]['name']
            self.add(name+'_join',slot,points,join_faces,joints,weights)


def smooth(t):
    t=np.clip(t,0.,1.)
    return t*t*(3.-2.*t)


def joint_weights(b,values):
    ids=np.argsort(values)[-4:][::-1]
    kept=values[ids];kept/=kept.sum()
    return ids,kept


def cloth_surface(b,name,slot,points,faces,joints,weights,thickness):
    """One shared deformation field on both sides; no separately weighted liner."""
    points=np.asarray(points);faces=np.asarray(faces)
    used,inverse=np.unique(faces,return_inverse=True)
    points=points[used];faces=inverse.reshape(-1,3)
    joints=np.asarray(joints)[used];weights=np.asarray(weights)[used]
    n=np.zeros_like(points)
    fn=np.cross(points[faces[:,1]]-points[faces[:,0]],points[faces[:,2]]-points[faces[:,0]])
    for c in range(3):np.add.at(n,faces[:,c],fn)
    n/=np.maximum(np.linalg.norm(n,axis=1,keepdims=True),1e-8)
    count=len(points)
    b.add(name,slot,np.concatenate((points,points-n*thickness)),
          np.concatenate((faces,faces[:,::-1]+count)),
          np.concatenate((joints,joints)),np.concatenate((weights,weights)),
          np.concatenate((n,-n)))


def skirt(b,f,kind,hem,ease,start,trim=False):
    k=f.H/1.72
    sections=cf_body.torso_profile(f)
    zvals=[s[0] for s in sections]
    # Two continuous half-panels: no single triangle is pulled by opposite legs.
    # Vents are only a few millimetres at rest and open with the actual stride.
    for half,(a0,a1) in enumerate(((-math.pi+.008,-.008),(.008,math.pi-.008))):
        points=[];joints=[];values=[]
        steps=33
        band_top=hem+(0. if kind=='hide' else .032*k)
        heights=sorted(set(np.linspace(start,hem,22).tolist()+[band_top]),reverse=True)
        rows=len(heights)
        for height in heights:
            h=max(height,f.z_hip)
            rx,fr,bk,cy=[float(np.interp(h,zvals,[s[j] for s in sections])) for j in range(1,5)]
            nearby=b.p[(np.abs(b.p[:,1]-h)<.014*k)&b.trunk_mask]
            if len(nearby):rx=max(rx,float(np.max(np.abs(nearby[:,0]))))
            fall=float(np.clip((start-height)/(start-hem),0.,1.))
            for col in range(steps):
                a=a0+(a1-a0)*col/(steps-1)
                # Retain the long female tunic / ankle robe silhouettes and
                # subdued vertical pleats, without a jagged triangulated hem.
                flare=(.010 if kind=='tunic' else .032)*k*fall
                pleat=.004*k*fall*math.sin(a*(12 if kind=='tunic' else 14))
                x=math.sin(a)*(rx+ease+flare+pleat)
                depth=(fr if math.cos(a)>=0 else bk)+ease-.008*k*fall+pleat
                z=-cy+math.cos(a)*depth
                # Turn the lower vent corners back toward their own facing.
                # A hip-wide rim rigidly attached to the shin protrudes as a
                # pointed ribbon when the knee bends. Only the front/back
                # corners below the knee change; the upper contact envelope
                # and lateral fullness stay exactly as authored.
                tuck=float(smooth((f.z_knee+.025*k-height)/(.17*k)))*abs(math.cos(a))**8
                if tuck>1e-6:
                    sign=1 if half==1 else -1
                    candidates=np.flatnonzero(b.trunk_mask&(b.p[:,0]*sign>0)&(np.abs(b.p[:,1]-height)<.023*k))
                    if len(candidates):
                        delta=b.p[candidates]-np.array((x,height,z))
                        nearest=candidates[int(np.argmin(np.sum(delta*delta,axis=1)))]
                        target=b.p[nearest]+b.n[nearest]*.011*k
                        x=x*(1-tuck)+target[0]*tuck
                        z=z*(1-tuck)+target[2]*tuck
                cloth_height=height
                if kind=='hide':
                    edge=float(hide_hem(f,hem)(np.array([[x,-z,hem]]))[0])
                    cloth_height+=(edge-hem)*fall**3
                points.append((x,cloth_height,z))
                weight=np.zeros(len(b.names))
                # A single continuous waist anchor avoids nearest-vertex
                # jumps between hips and opposite thighs around the belt.
                weight[b.names.index('hips')]=1.
                own='L' if half==1 else 'R'
                follow=float(smooth((start-cloth_height)/(.15*k)))
                shin=float(smooth((f.z_knee+.025*k-cloth_height)/(.16*k)))
                weight*=1-follow
                weight[b.names.index('thigh.'+own)]+=follow*(1-shin)
                weight[b.names.index('shin.'+own)]+=follow*shin
                ids,w=joint_weights(b,weight);joints.append(ids);values.append(w)
        faces=[]
        for row in range(rows-1):
            in_band=(heights[row]+heights[row+1])*.5<band_top
            if in_band!=trim:continue
            for col in range(steps-1):
                i=row*steps+col;faces.extend(((i,i+steps,i+steps+1),(i,i+steps+1,i+1)))
        cloth_surface(b,kind+('_hem_' if trim else '_panel_')+str(half),
                      'CLOTH_C' if trim else 'CLOTH_A',points,faces,joints,values,.0025*k)


def garment(b,f,kind):
    k=f.H/1.72;y=b.p[:,1]
    family={}
    for key in ('upper_arm','forearm','hand','thumb','index','fingers'):
        family[key]=np.sum(b.w*np.isin(b.j,[i for i,n in enumerate(b.names) if n.split('.')[0]==key]),axis=1)
    arm=family['upper_arm']+family['forearm']
    hands=family['hand']+family['thumb']+family['index']+family['fingers']
    start=f.z_hip+.045*k
    hem=(f.z_knee+(.05 if not f.p['female'] else -.17)*k) if kind=='tunic' else f.z_ankle+.030*k
    ease=(.019 if kind=='tunic' else .023)*k
    # Retain the original belt's fitted waist. Inflating this narrow band as
    # much as the sleeves puts the preserved leather belt inside the cloth.
    waist_fit=1.-smooth(np.abs(y-f.z_waist)/(.075*k))
    upper_ease=ease-(ease-.010*k)*waist_fit
    p=b.p+b.n*upper_ease[:,None]
    mask=(y<f.z_chin+.05*k)&(hands<.995)
    lower=p[:,1]-start+.045*k
    neck=np.maximum(f.z_shoulder+.050*k-p[:,1],np.abs(p[:,0])-.092*k)
    trim=np.minimum(p[:,1]-f.z_shoulder-k*(.015+.020*(p[:,0]/(.091*k))**2),.091*k-np.abs(p[:,0]))
    ends=[];cuffs=[]
    for side,sign in (('L',1),('R',-1)):
        shoulder=gl(f.shoulder[side]);elbow=gl(f.elbow[side]);wrist=gl(f.wrist[side])
        endpoint=shoulder+(elbow-shoulder)*.52 if kind=='tunic' else wrist+(elbow-wrist)*.10
        axis=(elbow-shoulder) if kind=='tunic' else (wrist-elbow);axis/=np.linalg.norm(axis)
        on_arm=(arm+hands>.15)&(b.p[:,0]*sign>f.p['shoulder']*.55)
        field=-(p-endpoint)@axis
        ends.append(np.where(on_arm,field,1.))
        cuffs.append((on_arm,field))
    group=len(b.doc['meshes'])
    b.shell(kind+'_upper','CLOTH_A',mask,upper_ease,limits=[lower,neck,-trim]+ends)
    # Overlapping inner facings stay within the original hem and follow the
    # body's actual hip/knee blend. They support the outer folds when a vent
    # opens in a deep bend, without erasing the visible legs below the hem.
    facing=(b.trunk_mask)&(y<start+.040*k)&(y>hem-.04*k)
    b.shell(kind+'_facings','CLOTH_A',facing,np.full(len(y),.011*k),
            limits=[start+.022*k-(y+b.n[:,1]*.011*k),y+b.n[:,1]*.011*k-hem])
    skirt(b,f,kind,hem,ease,start)
    b.finish_group(group,kind+'_body')
    group=len(b.doc['meshes'])
    b.shell(kind+'_neckband','CLOTH_C',mask,upper_ease+.0008*k,limits=[lower,neck,trim]+ends)
    for side,(on_arm,field) in zip(('L','R'),cuffs):
        b.shell(kind+'_cuff_'+side,'CLOTH_C',mask&on_arm,np.full(len(y),ease+.0008*k),limits=[field,.027*k-field])
    # The hem is a material region of the exact same panel grid, not an
    # independently weighted strip hovering over the deformed body.
    skirt(b,f,kind,hem,ease,start,True)
    b.finish_group(group,kind+'_trim')
    for name in PARTS[kind][2:]:
        if name=='robe_mantle':supported_mantle(b,f)
        elif name=='robe_mantle_edge':supported_mantle(b,f,True)
        else:b.copy_piece(name)
    # The open skirt must never erase the legs behind its vents. Only the
    # matched upper shell and original shoes provide fixed body coverage.
    cover=mask&(lower>.018*k)&(neck>.012*k)
    for end in ends:cover &= end>.016*k
    cover |= b.trunk_mask&(y<start+.008*k)&(y>hem+.020*k)
    faces=b.faces[np.any(~cover[b.faces],axis=1)]
    cover[np.unique(faces)]=False
    original=b.array(b.attrs['COLOR_0'])
    cover |= (y<f.z_ankle+.045*k)&(original[:,CHANNELS[kind]]>0)
    return cover


def hide_hem(f,hem):
    k=f.H/1.72
    return cf_dress._hem(hem,amp=.012,jag=.038*k,count=6,tilt=.030*k,seed=.4)


def supported_mantle(b,f,trim=False):
    """Retain the lower mantle, sew one matched shoulder cap over its opening."""
    k=f.H/1.72;start=len(b.doc['meshes'])
    name='robe_mantle_edge' if trim else 'robe_mantle'
    b.copy_piece(name,below=f.z_chest+.030*k)
    b.cape_join(name,f.z_chest+.030*k,.034*k,k)
    if trim:b.finish_group(start,name);return
    offset=.034*k
    p=b.p+b.n*offset;y=p[:,1]
    back=np.degrees(np.abs(np.arctan2(p[:,0],-p[:,2]-.020)))
    reach=np.interp(y,[f.z_chest-.02,f.z_shoulder-.10*k,f.z_shoulder-.02*k,f.z_shoulder+.030*k],
                    [79.,92.,150.,172.])
    mask=(b.p[:,1]>f.z_chest-.10*k)&(b.p[:,1]<f.z_shoulder+.13*k)&b.below_neck
    neck=np.maximum(f.z_shoulder+.055*k-y,np.abs(p[:,0])-.075*k)
    limits=[y-f.z_chest+.045*k,neck,reach-back]
    b.shell(name+'_shoulders','CLOTH_B',mask,np.full(len(y),offset),limits=limits)
    b.finish_group(start,name)


def hide(b,f):
    """The original asymmetric wrap, fur cape, cord and foot-wrap vocabulary."""
    k=f.H/1.72;y=b.p[:,1];start=f.z_hip+.045*k
    hem=f.z_knee+(.07 if not f.p['female'] else -.06)*k
    ease=.017*k
    waist=1-smooth(np.abs(y-(f.z_waist-.012*k))/(.075*k))
    offsets=ease-(ease-.009*k)*waist
    p=b.p+b.n*offsets[:,None]
    top=f.z_chest+.050*k+.30*np.clip(p[:,0],-.20,.25)+.25*np.maximum(p[:,0]-.04,0)
    fields=[p[:,1]-f.z_hip,top-p[:,1]]
    group=len(b.doc['meshes'])
    mask=b.trunk_mask&(y>f.z_hip-.06*k)&(y<f.z_shoulder+.03*k)
    # Skinning blends the armpit into the upper arm before the visible trunk
    # ends. Include that small torso-side seam instead of deleting whole
    # triangles merely because their arm influence exceeds the trunk mask.
    underarm=(y>f.z_chest-.080*k)&(y<f.z_shoulder)&(np.abs(b.p[:,0])<f.p['chest_w']+.018*k)
    b.shell('hide_upper','CLOTH_A',mask|underarm,offsets,limits=fields)
    lining_p=b.p+b.n*(.011*k)
    edge=hide_hem(f,hem)(np.column_stack((lining_p[:,0],-lining_p[:,2],lining_p[:,1])))
    facing=b.trunk_mask&(y<start+.04*k)&(y>hem-.10*k)
    b.shell('hide_facing','CLOTH_A',facing,np.full(len(y),.011*k),
            limits=[start+.022*k-lining_p[:,1],lining_p[:,1]-edge])
    skirt(b,f,'hide',hem,ease,start)
    b.finish_group(group,'hide_wrap')
    group=len(b.doc['meshes'])
    b.copy_piece('hide_cape',below=f.z_chest+.030*k)
    b.cape_join('hide_cape',f.z_chest+.030*k,.032*k,k)
    cape_p=b.p+b.n*(.032*k);cy=cape_p[:,1]
    slit=np.maximum(np.abs(cape_p[:,0])-(.030+.50*(f.z_shoulder+.05-cy)),.010-cape_p[:,2])
    neck=np.maximum(f.z_shoulder+.046*k-cy,np.abs(cape_p[:,0])-.075*k)
    cape_mask=(y>f.z_chest-.10*k)&(y<f.z_shoulder+.13*k)&b.below_neck
    limits=[cy-f.z_chest+.027*k,slit,neck]
    b.shell('hide_cape_lining','CLOTH_B',cape_mask,np.full(len(y),.032*k),limits=limits)
    b.finish_group(group,'hide_cape')
    b.copy_piece('hide_cord');b.copy_piece('hide_footwraps')
    cover=mask&(fields[0]>.02*k)&(fields[1]>.02*k)
    cover|=facing&(lining_p[:,1]>edge+.02*k)&(y<start+.006*k)
    cape_cover=cape_mask.copy()
    for field in limits:cape_cover&=field>.018*k
    cover|=cape_cover
    boundary=b.faces[np.any(~cover[b.faces],axis=1)];cover[np.unique(boundary)]=False
    original=b.array(b.attrs['COLOR_0'])
    cover|=(y<f.z_ankle+.06*k)&(original[:,CHANNELS['hide']]>0)
    return cover


def build(variant,kinds,out):
    source=os.path.join(ROOT,'assets','court_figures','court_figure_'+variant+'.glb')
    b=LegacyBundle(source);f=cf_body.Frame(cf_body.params(variant))
    masks={}
    for kind in kinds:
        if kind not in CHANNELS:raise ValueError('Unknown legacy outfit '+kind)
        masks[kind]=hide(b,f) if kind=='hide' else garment(b,f,kind)
    b.body_copy_masks(masks)
    path=os.path.join(out,'court_legacy_'+variant+'.glb');b.write(path)
    record={'file':os.path.basename(path),'outfits':kinds,'parts':{kind:PARTS[kind] for kind in kinds},
            'cape_join_y':f.z_chest+.030*f.H/1.72,
            'source_sha256':hashlib.sha256(open(source,'rb').read()).hexdigest(),
            'sha256':hashlib.sha256(open(path,'rb').read()).hexdigest()}
    print('LEGACY_CLOTH',variant,kinds,len(b.doc['meshes']),'meshes',len(b.data),'bytes',flush=True)
    return record


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--variants',default='male_adult,female_adult,male_old,female_old,male_young,female_young,child')
    parser.add_argument('--outfits',default='tunic,hide,robe')
    parser.add_argument('--out',default=os.path.join(ROOT,'assets','court_figures','legacy'))
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    os.makedirs(args.out,exist_ok=True)
    path=os.path.join(args.out,'court_legacy.json')
    manifest=json.load(open(path)) if os.path.exists(path) else {'version':1,'revision':'legacy-cloth-v1','variants':{}}
    for variant in args.variants.split(','):manifest['variants'][variant]=build(variant,args.outfits.split(','),args.out)
    with open(path,'w') as out:json.dump(manifest,out,indent=2)
