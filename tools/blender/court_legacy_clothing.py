"""Additive legacy garments fitted to the delivered court bodies.

Blender --background --factory-startup --python tools/blender/court_legacy_clothing.py
  -- --variants male_adult,female_old --outfits tunic

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

HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0,HERE)
import cf_body
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

    def copy_piece(self,name):
        source_node=next(n for n in self.source['nodes'] if n.get('name')==name)
        mesh=copy.deepcopy(self.source['meshes'][source_node['mesh']])
        for primitive in mesh['primitives']:
            primitive['indices']=self.copy_accessor(primitive['indices'])
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


def smooth(t):
    t=np.clip(t,0.,1.)
    return t*t*(3.-2.*t)


def joint_weights(b,values):
    ids=np.argsort(values)[-4:][::-1]
    kept=values[ids];kept/=kept.sum()
    return ids,kept


def cloth_surface(b,name,slot,points,faces,joints,weights,thickness):
    """One shared deformation field on both sides; no separately weighted liner."""
    points=np.asarray(points);faces=np.asarray(faces);n=np.zeros_like(points)
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
        rows,steps=22,33
        if trim:rows=3
        for row in range(rows):
            t=row/(rows-1)
            height=(hem+.032*k-t*.032*k) if trim else start-t*(start-hem)
            h=max(height,f.z_hip)
            rx,fr,bk,cy=[float(np.interp(h,zvals,[s[j] for s in sections])) for j in range(1,5)]
            nearby=b.p[(np.abs(b.p[:,1]-h)<.014*k)&b.trunk_mask]
            if len(nearby):rx=max(rx,float(np.max(np.abs(nearby[:,0]))))
            fall=float(np.clip((start-height)/(start-hem),0.,1.))
            for col in range(steps):
                a=a0+(a1-a0)*col/(steps-1)
                # Retain the long female tunic / ankle robe silhouettes and
                # subdued vertical pleats, without a jagged triangulated hem.
                flare=(.035 if kind=='tunic' else .055)*k*fall
                pleat=.004*k*fall*math.sin(a*(12 if kind=='tunic' else 14))
                x=math.sin(a)*(rx+ease+flare+pleat)
                depth=(fr if math.cos(a)>=0 else bk)+ease+.010*k*fall+pleat
                z=-cy+math.cos(a)*depth
                points.append((x,height,z))
                anchor=(math.sin(a)*(rx+ease),start,-cy+math.cos(a)*((fr if math.cos(a)>=0 else bk)+ease))
                nearest=b.trunk_kd.find(Vector(anchor))[1]
                weight=np.zeros(len(b.names))
                for index,value in zip(b.j[nearest],b.w[nearest]):weight[index]+=value
                own='L' if half==1 else 'R'
                follow=float(smooth((start-height)/(.15*k)))
                shin=float(smooth((f.z_knee+.025*k-height)/(.16*k)))
                weight*=1-follow
                weight[b.names.index('thigh.'+own)]+=follow*(1-shin)
                weight[b.names.index('shin.'+own)]+=follow*shin
                ids,w=joint_weights(b,weight);joints.append(ids);values.append(w)
        faces=[]
        for row in range(rows-1):
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
    p=b.p+b.n*ease
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
    b.shell(kind+'_upper','CLOTH_A',mask,np.full(len(y),ease),limits=[lower,neck,-trim]+ends)
    skirt(b,f,kind,hem,ease,start)
    b.finish_group(group,kind+'_body')
    group=len(b.doc['meshes'])
    b.shell(kind+'_neckband','CLOTH_C',mask,np.full(len(y),ease+.0008*k),limits=[lower,neck,trim]+ends)
    for side,(on_arm,field) in zip(('L','R'),cuffs):
        b.shell(kind+'_cuff_'+side,'CLOTH_C',mask&on_arm,np.full(len(y),ease+.0008*k),limits=[field,.027*k-field])
    skirt(b,f,kind,hem,ease+.001*k,start,True)
    b.finish_group(group,kind+'_trim')
    for name in PARTS[kind][2:]:b.copy_piece(name)
    # The open skirt must never erase the legs behind its vents. Only the
    # matched upper shell and original shoes provide fixed body coverage.
    cover=mask&(lower>.018*k)&(neck>.012*k)
    for end in ends:cover &= end>.016*k
    faces=b.faces[np.any(~cover[b.faces],axis=1)]
    cover[np.unique(faces)]=False
    original=b.array(b.attrs['COLOR_0'])
    cover |= (y<f.z_ankle+.045*k)&(original[:,CHANNELS[kind]]>0)
    return cover


def build(variant,kinds,out):
    source=os.path.join(ROOT,'assets','court_figures','court_figure_'+variant+'.glb')
    b=LegacyBundle(source);f=cf_body.Frame(cf_body.params(variant))
    masks={}
    for kind in kinds:
        if kind not in ('tunic','robe'):raise ValueError('Hide requires its own silhouette review before replacement')
        masks[kind]=garment(b,f,kind)
    b.body_copy_masks(masks)
    path=os.path.join(out,'court_legacy_'+variant+'.glb');b.write(path)
    record={'file':os.path.basename(path),'outfits':kinds,'parts':{kind:PARTS[kind] for kind in kinds},
            'source_sha256':hashlib.sha256(open(source,'rb').read()).hexdigest(),
            'sha256':hashlib.sha256(open(path,'rb').read()).hexdigest()}
    print('LEGACY_CLOTH',variant,kinds,len(b.doc['meshes']),'meshes',len(b.data),'bytes',flush=True)
    return record


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--variants',default='male_adult,female_old')
    parser.add_argument('--outfits',default='tunic')
    parser.add_argument('--out',default=os.path.join(ROOT,'assets','court_figures','legacy'))
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    os.makedirs(args.out,exist_ok=True)
    path=os.path.join(args.out,'court_legacy.json')
    manifest=json.load(open(path)) if os.path.exists(path) else {'version':1,'revision':'legacy-cloth-v1','variants':{}}
    for variant in args.variants.split(','):manifest['variants'][variant]=build(variant,args.outfits.split(','),args.out)
    with open(path,'w') as out:json.dump(manifest,out,indent=2)
