"""Fit the licensed MPFB source heads to the existing court rig and wardrobes.

All original binary/accessor data stays intact. Only head/face/hair mesh
references change; skeletons, actions, garments and props remain byte-for-byte.
Run with Python + numpy: --source-ref 895481d8 [--variants male_adult].
"""
import argparse
import copy
import json
from pathlib import Path
import struct
import subprocess
import time
import numpy as np
from validate_court_wardrobe import GLB
from refine_court_anatomy import normals

ROOT = Path(__file__).resolve().parents[2]
VARIANTS = ['male_adult', 'female_adult', 'male_old', 'female_old', 'male_young', 'female_young', 'child']
IDENTITIES = ['face_' + s for s in ('jaw','chin','cheek','nose','bridge','nose_wide','brow','lips','ears','long','round','aged')]
GAZE = {'eyes_left':(20.,0.), 'eyes_right':(-20.,0.), 'eyes_up':(0.,13.), 'eyes_down':(0.,-13.)}


def smooth(lo, hi, values):
    t = np.clip((values-lo)/(hi-lo), 0, 1)
    return t*t*(3-2*t)


def near(points, reference, count=4, power=2):
    ids, weights = [], []
    for start in range(0, len(points), 128):
        d = np.sum((points[start:start+128,None,:]-reference[None,:,:])**2, axis=2)
        ix = np.argpartition(d, count-1, axis=1)[:,:count]
        w = 1/np.maximum(np.take_along_axis(d,ix,axis=1),1e-10)**(power/2)
        w /= w.sum(axis=1,keepdims=True)
        ids.append(ix); weights.append(w)
    return np.concatenate(ids), np.concatenate(weights)


def transfer(values, binding):
    ids, weights = binding
    return np.sum(values[ids] * weights[:,:,None], axis=1)


def boundary(triangles):
    edges = np.concatenate([triangles[:,[0,1]],triangles[:,[1,2]],triangles[:,[2,0]]])
    keys, counts = np.unique(np.sort(edges,axis=1),axis=0,return_counts=True)
    return keys[counts==1]


def torso_component(triangles, points, cut, scale):
    """Discard only isolated old chin remnants after the horizontal cut."""
    neighbours={}
    for face in triangles:
        for v in face:neighbours.setdefault(int(v),set()).update(map(int,face))
    unseen=set(neighbours);components=[]
    while unseen:
        stack=[next(iter(unseen))];part=set()
        while stack:
            v=stack.pop()
            if v in part:continue
            part.add(v);stack.extend(neighbours[v]-part)
        unseen-=part;components.append(part)
    components.sort(key=len,reverse=True)
    for part in components[1:]:
        assert np.min(points[list(part),1])>cut-.020*scale, 'Cut disconnected original body'
    return triangles[np.all(np.isin(triangles,list(components[0])),axis=1)]


def bridge(lower_edges, upper_edges, points):
    """Walk real boundary edges and find the shortest connecting strip.

    The old decimated neck is not angularly monotone: sorting its vertices
    by angle can swap neighbours and leave holes. Never reorder its edges.
    """
    centre=points[np.unique(np.r_[lower_edges.ravel(),upper_edges.ravel()])].mean(axis=0)
    def ordered_loop(edges):
        neighbours={}
        for a,b in edges:
            neighbours.setdefault(int(a),[]).append(int(b));neighbours.setdefault(int(b),[]).append(int(a))
        assert all(len(n)==2 for n in neighbours.values()), 'Neck boundary is not a loop'
        ids=np.asarray(list(neighbours),np.uint32)
        angle=np.mod(np.arctan2(points[ids,2]-centre[2],points[ids,0]-centre[0]),2*np.pi)
        start=int(ids[np.argmin(angle)]);walk=[start];previous=-1;current=start
        while True:
            nxt=next(v for v in neighbours[current] if v!=previous)
            if nxt==start:break
            assert nxt not in walk,'Repeated neck boundary vertex'
            walk.append(nxt);previous,current=current,nxt
        assert len(walk)==len(neighbours),'Multiple neck boundary loops'
        walk=np.asarray(walk,np.uint32);p=points[walk]
        area=np.sum(p[:,0]*np.roll(p[:,2],-1)-p[:,2]*np.roll(p[:,0],-1))
        if area<0:walk=np.r_[walk[0],walk[:0:-1]]
        return walk
    lower=ordered_loop(lower_edges);upper=ordered_loop(upper_edges)
    m,n=len(lower),len(upper)
    a,b=np.r_[lower,lower[0]],np.r_[upper,upper[0]]
    cross_cost=np.sum((points[a,None]-points[b][None])**2,axis=2)
    cost=np.full((m+1,n+1),np.inf);parent=np.zeros((m+1,n+1),np.int8)
    cost[0,0]=0
    # A perimeter zipper can connect distant points on a hunched neck.
    # Dynamic programming minimizes cross-edge length while consuming every
    # directed boundary edge once. Exclude a complete wrap before advancing
    # the other loop, which would duplicate the starting cross edge.
    for i in range(m+1):
        for j in range(n+1):
            if i==j==0 or (i==m and j==0) or (i==0 and j==n):continue
            left=cost[i-1,j] if i else np.inf
            down=cost[i,j-1] if j else np.inf
            if left<down:cost[i,j],parent[i,j]=left+cross_cost[i,j],1
            else:cost[i,j],parent[i,j]=down+cross_cost[i,j],2
    result=[];i,j=m,n
    while i or j:
        if parent[i,j]==1:result.append([a[i-1],b[j],a[i]]);i-=1
        else:result.append([a[i],b[j-1],b[j]]);j-=1
    result=np.asarray(result[::-1],np.uint32)
    edges=np.concatenate([result[:,[0,1]],result[:,[1,2]],result[:,[2,0]]])
    unique,counts=np.unique(np.sort(edges,axis=1),axis=0,return_counts=True)
    assert counts.max()<=2, 'Neck strip repeated a wrapped cross edge'
    expected={tuple(e) for e in np.sort(np.concatenate([lower_edges,upper_edges]),axis=1)}
    assert {tuple(e) for e in unique[counts==1]}==expected, 'Neck strip changed its boundary'
    return result


def neck_relaxation(points, triangles, start, scale, origin):
    """A fixed linear fairing operator for the new neck, anchored to the body.

    A valid annulus alone still leaves the native cut's sawtooth silhouette.
    Relax its lower contour into the old neck without moving retained vertices
    or facial features. Reuse the same operator for shapes and skin weights.
    """
    gain=.5*(1-smooth(-.015,.040,(points[:,1]-origin[1])/scale))
    gain[:start]=0
    active=np.flatnonzero(gain>0)
    edges=np.unique(np.sort(np.concatenate([triangles[:,[0,1]],triangles[:,[1,2]],triangles[:,[2,0]]]),axis=1),axis=0)
    neighbours=[np.unique(edges[np.any(edges==i,axis=1)]) for i in active]
    neighbours=[n[n!=i] for i,n in zip(active,neighbours)]
    def relax(values):
        result=values.astype(np.float64).copy()
        for _ in range(6):
            means=np.asarray([result[n].mean(axis=0) for n in neighbours])
            result[active]+=(means-result[active])*gain[active,None]
        return result.astype(values.dtype)
    return relax


class Writer:
    def __init__(self, glb):
        self.g=glb; self.binary=bytearray(glb.bin)

    def add(self, values, original=None, normalized=False):
        values=np.ascontiguousarray(values)
        if values.ndim==1:values=values[:,None]
        component={np.dtype('float32'):5126,np.dtype('uint32'):5125,np.dtype('uint16'):5123,np.dtype('uint8'):5121}[values.dtype]
        while len(self.binary)%4:self.binary.append(0)
        view=len(self.g.doc['bufferViews'])
        self.g.doc['bufferViews'].append({'buffer':0,'byteOffset':len(self.binary),'byteLength':values.nbytes})
        self.binary.extend(values.tobytes())
        acc={'componentType':component,'type':{1:'SCALAR',2:'VEC2',3:'VEC3',4:'VEC4'}[values.shape[1]],'count':len(values),'bufferView':view}
        if original is not None:
            old=self.g.doc['accessors'][original]
            if old.get('normalized'):acc['normalized']=True
        if normalized:acc['normalized']=True
        if component==5126 or values.shape[1]==1:
            acc.update(min=values.min(axis=0).tolist(),max=values.max(axis=0).tolist())
        index=len(self.g.doc['accessors']);self.g.doc['accessors'].append(acc)
        return index

    def primitive(self,attrs,triangles,deltas,names,material,normal_deltas=None):
        normal=attrs['NORMAL']
        targets=[]
        for name in names:
            delta=deltas.get(name,np.zeros_like(attrs['POSITION'])).astype(np.float32)
            dn=normal_deltas[name] if normal_deltas is not None else normals(attrs['POSITION']+delta,triangles)-normal
            targets.append({'POSITION':self.add(delta),'NORMAL':self.add(dn.astype(np.float32))})
        return {'attributes':{k:self.add(v,normalized=(k=='COLOR_0' and v.dtype==np.uint16)) for k,v in attrs.items()},
                'indices':self.add(triangles.astype(np.uint32).reshape(-1)), 'material':material,'targets':targets,'mode':4}

    def save(self,path):
        self.g.doc['buffers'][0]['byteLength']=len(self.binary)
        doc=json.dumps(self.g.doc,separators=(',',':')).encode();doc+=b' '*(-len(doc)%4)
        self.binary+=b'\0'*(-len(self.binary)%4)
        raw=struct.pack('<III',0x46546c67,2,28+len(doc)+len(self.binary))+struct.pack('<II',len(doc),0x4e4f534a)+doc+struct.pack('<II',len(self.binary),0x004e4942)+self.binary
        path=Path(path);temporary=path.with_suffix('.mpfb-tmp');temporary.write_bytes(raw)
        for attempt in range(5):
            try:
                temporary.replace(path)
                break
            except PermissionError:
                if attempt==4:raise
                # Windows indexers can briefly hold a read handle. Keep the
                # old asset intact and retry the same atomic replacement.
                time.sleep(.15*2**attempt)


def mesh_arrays(g,mesh):
    p=mesh['primitives'][0]
    attrs={k:g.values(v) for k,v in p['attributes'].items()}
    targets={name:{k:g.values(v) for k,v in t.items()} for name,t in zip(mesh['extras']['targetNames'],p['targets'])}
    triangles=g.values(p['indices']).reshape(-1,3).astype(np.uint32)
    return attrs,targets,triangles


def source_data(path):
    data=np.load(path,allow_pickle=False)
    source={k:data[k] for k in data.files}
    # Full native blink overtravels the lower lid. This still closes the
    # spherical eyes on all seven heads, without pinching the closed lid.
    blink=list(source['names']).index('blink')
    for key in ('deltas','brow_deltas','teeth_deltas','eye_center_deltas'):
        source[key][blink]*=.78
    return source


def fit_info(g,body,variant):
    attrs,_,_=mesh_arrays(g,body)
    p=attrs['POSITION'];uv=attrs['TEXCOORD_0'];valid=abs(uv[:,0])>.01
    scale=float(np.median(p[valid,0]/uv[valid,0]))
    chin=float(np.median(p[:,1]-(1-uv[:,1])*scale))
    origin=np.array([0,chin,.020 if variant.endswith('_old') else 0.])
    return scale,origin


def new_attrs(p,triangles,scale,origin,head_joint,neck_joint=None,landmarks=None):
    count=len(p);n=normals(p,triangles).astype(np.float32);q=(p-origin)/scale
    uv=q[:,:2].copy()
    # Shader landmarks follow native anatomical height, while actual geometry
    # retains the source's human proportions.
    anchors=(landmarks or {}).get('paint_y_anchors')
    measured=(landmarks or {}).get('landmarks',{})
    if measured:
        mouth=measured['mouth_seam'][1];nose=measured['nose_base'][1]
        eye=float(np.mean(np.asarray(measured['eyes'])[:,1]));brow=float(np.mean(np.asarray(measured['brows'])[:,1]))
        anchors=[[-.05,-.05],[0,0],[mouth,.054],[nose,.089],[eye,.133],[brow,.160],[.282,.282]]
        eye_x=abs(measured['eyes'][0][0]);brow_x=abs(measured['brows'][0][0])
        uv[:,0]*=np.interp(q[:,1],[0,mouth,nose,eye,brow,.282],[.9,.043/measured['lip_width'],.8,.034/eye_x,.036/brow_x,.95])
    if anchors:
        anchors=np.asarray(anchors)
        uv[:,1]=np.interp(q[:,1],anchors[:,0],anchors[:,1])
    uv[:,1]=1-uv[:,1]
    uv2=np.c_[np.maximum(0,n[:,2]),np.full(count,-1.)].astype(np.float32)
    colour=np.zeros((count,4),np.uint16);colour[:,0]=65535
    joints=np.zeros((count,4),np.uint8);joints[:,0]=head_joint
    weights=np.zeros((count,4),np.float32);weights[:,0]=1
    if neck_joint is not None:
        h=smooth(-.020,.035,q[:,1]);weights[:,0]=h;weights[:,1]=1-h;joints[:,1]=neck_joint
    return {'POSITION':p.astype(np.float32),'NORMAL':n,'TEXCOORD_0':uv.astype(np.float32),'TEXCOORD_1':uv2,'COLOR_0':colour,'JOINTS_0':joints,'WEIGHTS_0':weights}


def graft_body(writer, name, source, variant, scale, origin, joints):
    g=writer.g;mesh=g.mesh(name);attrs,targets,triangles=mesh_arrays(g,mesh)
    # The chin plane clears the higher shoulders of the old/child bodies.
    # Decimation leaves the actual neck boundary below this plane.
    original_p=attrs['POSITION'];cut=origin[1]
    kept_tri=triangles[np.all(original_p[triangles,1]<=cut,axis=1)]
    kept_tri=torso_component(kept_tri,original_p,cut,scale)
    keep=np.unique(kept_tri);remap=np.zeros(len(original_p),np.uint32);remap[keep]=np.arange(len(keep))
    lowertri=remap[kept_tri]
    hp=source['positions'];ht=source['triangles'].astype(np.uint32)
    ht=ht[np.all(hp[ht,1]>-.010,axis=1)]
    use=np.unique(ht);hmap=np.zeros(len(hp),np.uint32);hmap[use]=np.arange(len(use))
    hp=hp[use];ht=hmap[ht]
    sd={str(k):v[use] for k,v in zip(source['names'],source['deltas'])}
    # Match the original neck's motion over four native topological rings.
    # Outside this narrow transition the native facial targets stay exact.
    rim=np.unique(boundary(ht));gain=np.ones(len(hp),np.float32);gain[rim]=0
    visited=rim.copy();frontier=rim.copy()
    for ring in range(1,4):
        adjacent=np.unique(ht[np.any(np.isin(ht,frontier),axis=1)])
        frontier=np.setdiff1d(adjacent,visited);gain[frontier]=ring/4
        visited=np.union1d(visited,frontier)
    names=list(targets)+[n for n in sd if n not in targets]
    hp=(hp*scale+origin).astype(np.float32)
    total=np.concatenate([original_p[keep],hp]);N=len(keep)
    headtri=ht+N
    original_open={tuple(edge) for edge in boundary(triangles)}
    lowedges=boundary(lowertri)
    lowedges=np.asarray([edge for edge in lowedges if tuple(sorted(keep[edge])) not in original_open],dtype=np.uint32)
    highedges=boundary(ht);highedges=highedges[np.all((hp[highedges,1]-origin[1])/scale<.035,axis=1)]
    lowloop=np.unique(lowedges);highloop=np.unique(highedges)+N
    assert len(lowloop)>8 and len(highloop)>8,(len(lowloop),len(highloop))
    # Interpolate original cut-ring movement instead of pinning the new rim
    # while the legacy neck moves under speech and identity shapes.
    binding=near(hp,original_p[keep[lowloop]],3,power=1)
    blended={}
    for n in names:
        original_delta=targets.get(n,{}).get('POSITION',np.zeros_like(original_p))
        native_delta=sd.get(n,np.zeros_like(hp))*scale
        inherited=transfer(original_delta[keep[lowloop]],binding)
        fitted=native_delta*gain[:,None]+inherited*(1-gain[:,None])
        blended[n]=np.concatenate([original_delta[keep],fitted]).astype(np.float32)
    necktri=bridge(lowedges,highedges+N,total)
    alltri=np.concatenate([lowertri,headtri,necktri])
    relax=neck_relaxation(total,alltri,N,scale,origin)
    total=relax(total);hp=total[N:]
    blended={n:relax(d) for n,d in blended.items()}
    metadata=json.loads(str(source.get('metadata','{}')))
    headattrs=new_attrs(hp,ht,scale,origin,joints['head'],joints['neck'],metadata)
    out={k:np.concatenate([v[keep],headattrs[k].astype(v.dtype)]) for k,v in attrs.items()}
    # Blend in joint space before reducing to the four glTF influences.
    # This keeps an animated neck as smooth as its resting contour.
    joint_weights=np.zeros((len(total),max(joints.values())+1),np.float32)
    for slot in range(4):
        np.add.at(joint_weights,(np.arange(len(total)),out['JOINTS_0'][:,slot]),out['WEIGHTS_0'][:,slot])
    joint_weights=relax(joint_weights)
    selected=np.argsort(-joint_weights[N:],axis=1)[:,:4]
    weights=np.take_along_axis(joint_weights[N:],selected,axis=1)
    out['JOINTS_0'][N:]=selected
    out['WEIGHTS_0'][N:]=weights/weights.sum(axis=1,keepdims=True)
    calculated=normals(total,alltri).astype(np.float32)
    out['NORMAL'][N:]=calculated[N:];out['NORMAL'][lowloop]=calculated[lowloop]
    prim=mesh['primitives'][0]
    prim['attributes']={k:writer.add(v,prim['attributes'][k]) for k,v in out.items()}
    prim['indices']=writer.add(alltri.reshape(-1))
    newtargets=[]
    for n in names:
        old=targets.get(n,{})
        delta=blended[n]
        normaldelta=np.concatenate([old.get('NORMAL',np.zeros_like(original_p))[keep],np.zeros_like(hp)]).astype(np.float32)
        calc=normals(total+delta,alltri)-out['NORMAL']
        normaldelta[N:]=calc[N:];normaldelta[lowloop]=calc[lowloop]
        newtargets.append({'POSITION':writer.add(delta),'NORMAL':writer.add(normaldelta)})
    prim['targets']=newtargets;mesh['weights']=[0.]*len(names)
    mesh.setdefault('extras',{}).update(targetNames=names,mpfb_head_revision=1,mpfb_cut_y=cut,
        mpfb_original_indices=writer.add(keep.astype(np.uint32)),mpfb_original_vertex_count=N,mpfb_head_start=N,mpfb_source_variant=variant)
    return {'body':name,'kept_vertices':N,'head_vertices':len(hp),'triangles':len(alltri),'neck_triangles':len(necktri)}


def feature(writer,name,p,triangles,deltas,names,material,scale,origin,joints,triangle_uv=None):
    mesh=writer.g.mesh(name)
    attrs=new_attrs(p,triangles,scale,origin,joints['head'])
    # Facial accessories aren't skin and do not receive projected face paint.
    attrs['TEXCOORD_1'][:]=[0,1]
    normal_deltas=None
    if triangle_uv is not None:
        # Preserve native UV seams while sharing each original vertex's
        # smooth normal, skin weights and expression displacement.
        corners=np.c_[triangles.ravel(),triangle_uv.reshape(-1,2)]
        unique,inverse=np.unique(corners,axis=0,return_inverse=True)
        ids=unique[:,0].astype(np.int64)
        normal_deltas={n:(normals(p+deltas[n],triangles)-attrs['NORMAL'])[ids] for n in names}
        attrs={k:v[ids] for k,v in attrs.items()}
        deltas={n:d[ids] for n,d in deltas.items()}
        uv=unique[:,1:].astype(np.float32);uv[:,1]=1-uv[:,1]
        attrs['TEXCOORD_0']=uv
        triangles=inverse.reshape(-1,3).astype(np.uint32)
    mesh['primitives']=[writer.primitive(attrs,triangles,deltas,names,material,normal_deltas)]
    mesh['weights']=[0.]*len(names)
    mesh.setdefault('extras',{}).update(targetNames=names,mpfb_head_revision=1)


def sphere_patch(center,radii,limit=np.pi,segments=32,rings=16):
    points=[center+np.array([0,0,radii[2]])]
    # Polar axis is +Z (face forward). One vertex per pole avoids degenerates.
    stop=rings if limit<np.pi else rings-1
    for row in range(1,stop+1):
        theta=limit*row/rings
        for col in range(segments):
            phi=2*np.pi*col/segments
            points.append(center+radii*np.array([np.sin(theta)*np.cos(phi),np.sin(theta)*np.sin(phi),np.cos(theta)]))
    faces=[]
    for i in range(segments):faces.append([0,1+i,1+(i+1)%segments])
    for row in range(stop-1):
        a=1+row*segments;b=a+segments
        for i in range(segments):
            j=(i+1)%segments;faces.extend([[a+i,b+i,b+j],[a+i,b+j,a+j]])
    if limit==np.pi:
        tip=len(points);points.append(center-np.array([0,0,radii[2]]));a=1+(stop-1)*segments
        for i in range(segments):faces.append([a+i,tip,a+(i+1)%segments])
    p=np.asarray(points,np.float32);t=np.asarray(faces,np.uint32)
    # The cap ring winding above is inward in this +Z parameterization.
    n=np.cross(p[t[:,1]]-p[t[:,0]],p[t[:,2]]-p[t[:,0]])
    if np.mean(np.sum(n*(p[t].mean(axis=1)-center),axis=1))<0:t=t[:,[0,2,1]]
    return p,t


def eyes(writer,source,scale,origin,joints,materials):
    # Native eyelids close over spherical eyes. Squashing the eyeballs here
    # would collapse their visible shape during partial blinks and squints.
    names=IDENTITIES+list(GAZE)
    skinbinding={}
    for side,centre in enumerate(source['eye_centers']):
        skinbinding[side]=near(centre[None,:],source['positions'])
    deltas={str(k):v for k,v in zip(source['names'],source['deltas'])}
    mesh=writer.g.mesh('Eyes');primitives=[]
    for slot,angle,inflate in [('EYE_WHITE',np.pi,0.),('IRIS',.49,.00025),('PUPIL',.23,.00040),('EYE_SHINE',.050,.00058)]:
        allp=[];allt=[];alld={n:[] for n in names};base=0
        for side,c in enumerate(source['eye_centers']):
            radii=np.asarray(source['eye_radii'][side])*.985
            radii+=inflate
            centre=c.copy()
            if slot=='EYE_SHINE':centre+=np.array([-.0022,.0030,0])
            p,t=sphere_patch(centre,radii,angle,32,16 if slot=='EYE_WHITE' else 5)
            t=t+base;base+=len(p);allp.append(p);allt.append(t)
            for n in names:
                move=np.zeros_like(p)
                if n in IDENTITIES and n in deltas:
                    source_index=list(source['names']).index(n)
                    move[:]=source['eye_center_deltas'][source_index,side] if 'eye_center_deltas' in source else transfer(deltas[n],skinbinding[side])[0]
                elif n in GAZE:
                    yaw,pitch=np.radians(GAZE[n]);x,y,z=(p-c).T
                    x2=x*np.cos(yaw)+z*np.sin(yaw);z2=z*np.cos(yaw)-x*np.sin(yaw)
                    y2=y*np.cos(pitch)+z2*np.sin(pitch);z3=z2*np.cos(pitch)-y*np.sin(pitch)
                    move=np.c_[x2,y2,z3]+c-p
                alld[n].append(move*scale)
        p=np.concatenate(allp)*scale+origin;t=np.concatenate(allt)
        attrs=new_attrs(p,t,scale,origin,joints['head']);attrs['TEXCOORD_1'][:]=[0,1]
        primitives.append(writer.primitive(attrs,t,{n:np.concatenate(v) for n,v in alld.items()},names,materials[slot]))
    mesh['primitives']=primitives;mesh['weights']=[0.]*len(names)
    mesh.setdefault('extras',{}).update(targetNames=names,mpfb_head_revision=1)


def refit_hair(writer,source,scale,origin,old_body):
    """Retain authored hairstyles; fit their underlying scalp and skin riders."""
    oldattrs,_,_=mesh_arrays(writer.g,old_body)
    old=(oldattrs['POSITION']-origin)/scale
    old=old[old[:,1]>-.025]
    head=source['positions'];hd={str(k):v for k,v in zip(source['names'],source['deltas'])}
    centre=np.array([0,.155,-.008])
    def directions(p):
        vector=p-centre
        return vector/np.maximum(np.linalg.norm(vector,axis=1,keepdims=True),1e-9)
    olddir=directions(old);newdir=directions(head)
    for mesh in writer.g.doc['meshes']:
        name=mesh.get('name','')
        if not name.startswith(('hair_','beard_')):continue
        names=list(mesh.get('extras',{}).get('targetNames',[]))
        newnames=names+[n for n in hd if n not in names and (name.startswith('beard_') or n in IDENTITIES)]
        for primitive in mesh['primitives']:
            attrs={k:writer.g.values(v) for k,v in primitive['attributes'].items()}
            q=(attrs['POSITION']-origin)/scale
            oldbind=near(directions(q),olddir);newbind=near(directions(q),newdir)
            oldsurface=transfer(old,oldbind);newsurface=transfer(head,newbind)
            distance=np.linalg.norm(q-oldsurface,axis=1)
            follow=1-smooth(.025,.15,distance)
            follow*=smooth(-.12,-.015,q[:,1])
            shift=(newsurface-oldsurface)*follow[:,None]
            p=(q+shift)*scale+origin
            tri=writer.g.values(primitive['indices']).reshape(-1,3).astype(np.uint32)
            attrs['POSITION']=p.astype(np.float32);attrs['NORMAL']=normals(p,tri).astype(np.float32)
            oldtargets={n:t for n,t in zip(names,primitive.get('targets',[]))}
            ts=[]
            for n in newnames:
                if n in hd:
                    d=transfer(hd[n],newbind)*follow[:,None]*scale
                else:d=writer.g.values(oldtargets[n]['POSITION'])
                dn=normals(p+d,tri)-attrs['NORMAL']
                ts.append({'POSITION':writer.add(d.astype(np.float32)),'NORMAL':writer.add(dn.astype(np.float32))})
            primitive['attributes']={k:writer.add(v,primitive['attributes'][k]) for k,v in attrs.items()}
            primitive['targets']=ts
        mesh['weights']=[0.]*len(newnames)
        mesh.setdefault('extras',{}).update(targetNames=newnames,mpfb_head_revision=1)


def process(source_path,output,source,variant):
    g=GLB(str(source_path));writer=Writer(g)
    name=next(n['name'] for n in g.doc['nodes'] if n.get('name') in ('Body','LegacyBody','WardrobeBody'))
    body=g.mesh(name);original_body=copy.deepcopy(body)
    if body.get('extras',{}).get('mpfb_head_revision'):
        raise ValueError('Input already contains an MPFB head; use an ungrafted source ref')
    scale,origin=fit_info(g,body,variant)
    joints={g.doc['nodes'][n]['name']:i for i,n in enumerate(g.doc['skins'][0]['joints'])}
    mats={m.get('name'):i for i,m in enumerate(g.doc['materials'])}
    if name=='Body':
        # Hair fitting reads the original head before its primitive is replaced.
        refit_hair(writer,source,scale,origin,original_body)
    result=graft_body(writer,name,source,variant,scale,origin,joints)
    if name=='Body':
        if 'TEETH' not in mats:
            mats['TEETH']=len(g.doc['materials']);g.doc['materials'].append({'name':'TEETH','pbrMetallicRoughness':{'baseColorFactor':[.78,.74,.64,1.],'metallicFactor':0.,'roughnessFactor':.8}})
        names=[str(n) for n in source['names']]
        feature(writer,'Brows',source['brow_positions']*scale+origin,source['brow_triangles'].astype(np.uint32),
                {n:d*scale for n,d in zip(names,source['brow_deltas'])},names,mats['HAIR'],scale,origin,joints,source['brow_triangle_uv'])
        feature(writer,'Mouth',source['teeth_positions']*scale+origin,source['teeth_triangles'].astype(np.uint32),
                {n:d*scale for n,d in zip(names,source['teeth_deltas'])},names,mats['TEETH'],scale,origin,joints,source['teeth_triangle_uv'])
        eyes(writer,source,scale,origin,joints,mats)
    writer.save(output)
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-ref',default='895481d8')
    parser.add_argument('--source-dir',type=Path,default=ROOT/'assets/court_figures/mpfb_source')
    parser.add_argument('--variants',default=','.join(VARIANTS))
    parser.add_argument('--base-only',action='store_true')
    args=parser.parse_args()
    cache=ROOT/'artifacts/mpfb-baseline';cache.mkdir(parents=True,exist_ok=True)
    for variant in args.variants.split(','):
        src=source_data(args.source_dir/(variant+'.npz'))
        paths=[f'assets/court_figures/court_figure_{variant}.glb']
        if not args.base_only:paths.extend([f'assets/court_figures/legacy/court_legacy_{variant}.glb',f'assets/court_figures/wardrobe/court_wardrobe_{variant}.glb'])
        for path in paths:
            baseline=cache/(args.source_ref+'-'+Path(path).name)
            if not baseline.exists():baseline.write_bytes(subprocess.check_output(['git','show',args.source_ref+':'+path],cwd=ROOT))
            result=process(baseline,ROOT/path,src,variant)
            print(json.dumps({'path':path,**result}),flush=True)


if __name__=='__main__':main()
