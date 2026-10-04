"""Validate wardrobe GLBs independently of Blender/Godot's import cache.
Run with Python + numpy from the explicit project root. Checks every byte-valued
skin attribute/morph, named bind pose and complete outfit coverage at rest.
"""
import argparse
import hashlib
import json
import os
import struct
from collections import Counter
import numpy as np

DT = {5120:"i1",5121:"u1",5122:"<i2",5123:"<u2",5125:"<u4",5126:"<f4"}
SZ = {"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4,"MAT4":16}


class GLB:
    def __init__(self,path):
        self.raw=open(path,"rb").read()
        n=struct.unpack_from("<I",self.raw,12)[0]
        self.doc=json.loads(self.raw[20:20+n]);self.bin=self.raw[28+n:]
    def values(self,i):
        a=self.doc["accessors"][i];dtype=np.dtype(DT[a["componentType"]]);width=SZ[a["type"]]
        if "bufferView" in a:
            v=self.doc["bufferViews"][a["bufferView"]]
            result=np.ndarray((a["count"],width),dtype=dtype,buffer=self.bin,offset=v.get("byteOffset",0)+a.get("byteOffset",0),strides=(v.get("byteStride",dtype.itemsize*width),dtype.itemsize)).copy()
        else:result=np.zeros((a["count"],width),dtype=dtype)
        if "sparse" in a:
            s=a["sparse"];vi=self.doc["bufferViews"][s["indices"]["bufferView"]];vv=self.doc["bufferViews"][s["values"]["bufferView"]]
            ids=np.frombuffer(self.bin,DT[s["indices"]["componentType"]],s["count"],vi.get("byteOffset",0)+s["indices"].get("byteOffset",0))
            data=np.frombuffer(self.bin,dtype,s["count"]*width,vv.get("byteOffset",0)+s["values"].get("byteOffset",0)).reshape(-1,width)
            result[ids]=data
        return result
    def mesh(self,name):
        node=next(n for n in self.doc["nodes"] if n.get("name")==name)
        return self.doc["meshes"][node["mesh"]]


def boundary_edges(glb, name):
    """Weld clip-generated duplicates before finding the visible cut edges."""
    mesh=glb.mesh(name)["primitives"][0]
    pos=glb.values(mesh["attributes"]["POSITION"])
    faces=glb.values(mesh["indices"]).reshape(-1,3)
    _,ids=np.unique(np.round(pos,6),axis=0,return_inverse=True)
    edges=Counter()
    samples={}
    for face in faces:
        for i in range(3):
            a,c=int(face[i]),int(face[(i+1)%3])
            key=tuple(sorted((int(ids[a]),int(ids[c]))))
            if key[0]==key[1]:continue
            edges[key]+=1;samples[key]=(pos[a],pos[c])
    return np.asarray([samples[key] for key,n in edges.items() if n==1])


def surface_distance(points, triangles):
    """True triangle distance, including edges; nearest vertices miss thin bands."""
    a,b,c=triangles[:,0],triangles[:,1],triangles[:,2]
    ab,ac=b-a,c-a
    normal=np.cross(ab,ac);nn=np.sum(normal*normal,axis=1)
    aa=np.sum(ab*ab,axis=1);cc=np.sum(ac*ac,axis=1);cross=np.sum(ab*ac,axis=1)
    denominator=np.maximum(aa*cc-cross*cross,1e-20)
    result=[]
    for chunk in range(0,len(points),64):
        point=points[chunk:chunk+64,None,:];delta=point-a
        av=np.sum(delta*ab,axis=2);cv=np.sum(delta*ac,axis=2)
        u=(av*cc-cv*cross)/denominator;v=(cv*aa-av*cross)/denominator
        inside=(u>=0)&(v>=0)&(u+v<=1)&(nn>1e-20)
        distance=np.where(inside,np.sum(delta*normal,axis=2)**2/np.maximum(nn,1e-20),np.inf)
        for start,end in ((a,b),(b,c),(c,a)):
            edge=end-start
            along=np.clip(np.sum((point-start)*edge,axis=2)/np.maximum(np.sum(edge*edge,axis=1),1e-20),0,1)
            offset=point-(start+along[:,:,None]*edge)
            distance=np.minimum(distance,np.sum(offset*offset,axis=2))
        result.extend(np.sqrt(distance.min(axis=1)))
    return np.array(result)


def check_seams(bundle, rec, body):
    height=float(body[:,1].max()-body[:,1].min())
    for outfit in rec["outfits"]:
        shell=outfit+("_doublet" if outfit=="medieval" else "_jacket")
        edges=boundary_edges(bundle,shell)
        upper=edges[np.all(edges[:,:,1]>height*.78,axis=1)]
        assert len(upper)>12,(rec["variant"],shell,"missing neckline")
        span=float(np.ptp(upper[:,:,1]))
        # A fitted neck can rise gently at the side; the old rectangular mask
        # left 5-6 cm tabs. Bound that excursion to 1% of the body's height.
        assert span<height*.010,(rec["variant"],shell,"ragged neckline",span)
        sleeve_edges=np.unique(edges.reshape(-1,3),axis=0)
        for side in ("L","R"):
            cuff=np.unique(boundary_edges(bundle,outfit+"_cuff_"+side).reshape(-1,3),axis=0)
            distances=((cuff[:,None,:]-sleeve_edges[None,:,:])**2).sum(axis=2).min(axis=1)
            sewn=int(np.sum(distances<(.0003*height)**2))
            assert sewn>=8 and sewn>=len(cuff)*.30,(rec["variant"],outfit,side,"unjoined cuff",sewn,len(cuff))
        if outfit not in ("medieval","formal"):continue
        # Front/back vents can articulate between the legs. A longitudinal
        # opening at the outer hip is a missing side seam, not such a vent.
        for name in rec["outfits"][outfit]:
            if "_skirt_" not in name:continue
            edges=boundary_edges(bundle,name)
            vertical=edges[np.abs(edges[:,0,1]-edges[:,1,1])>.003]
            assert len(vertical)>0,(rec["variant"],name,"no vent")
            assert np.abs(vertical[:,:,0]).max()<height*.025,(rec["variant"],name,"open side seam")
    belt=bundle.mesh("medieval_belt")["primitives"][0]
    belt_pos=bundle.values(belt["attributes"]["POSITION"])
    doublet=bundle.mesh("medieval_doublet")["primitives"][0]
    cloth=bundle.values(doublet["attributes"]["POSITION"])
    triangles=cloth[bundle.values(doublet["indices"]).reshape(-1,3)]
    near=np.any((triangles[:,:,1]>belt_pos[:,1].min()-.03)&(triangles[:,:,1]<belt_pos[:,1].max()+.03),axis=1)
    gap=float(surface_distance(belt_pos,triangles[near]).max())
    assert gap<height*.004,(rec["variant"],"belt floats away from doublet",gap)


def check(root):
    folder=os.path.join(root,"assets","court_figures","wardrobe")
    manifest=json.load(open(os.path.join(folder,"court_wardrobe.json")))
    for rec in manifest["variants"]:
        original=GLB(os.path.join(root,"assets","court_figures","court_figure_"+rec["variant"]+".glb"))
        bundle=GLB(os.path.join(folder,rec["file"]))
        assert hashlib.sha256(original.raw).hexdigest()==rec["source_sha256"]
        assert hashlib.sha256(bundle.raw).hexdigest()==rec["sha256"]
        assert "animations" not in bundle.doc
        a=original.mesh("Body");b=bundle.mesh("WardrobeBody")
        assert a.get("extras")==b.get("extras") and a.get("weights")==b.get("weights")
        for old,new in zip(a["primitives"],b["primitives"]):
            for name,idx in old["attributes"].items():
                ov=original.values(idx);nv=bundle.values(new["attributes"][name])
                assert np.array_equal(ov[:,[0,2,3]],nv[:,[0,2,3]]) if name=="COLOR_0" else np.array_equal(ov,nv),name
            assert np.array_equal(original.values(old["indices"]),bundle.values(new["indices"]))
            for ot,nt in zip(old.get("targets",[]),new.get("targets",[])):
                for name in ot:assert np.array_equal(original.values(ot[name]),bundle.values(nt[name])),name
        for old,new in zip(original.doc["skins"],bundle.doc["skins"]):
            assert old["joints"]==new["joints"]
            assert np.array_equal(original.values(old["inverseBindMatrices"]),bundle.values(new["inverseBindMatrices"]))
            for index in old["joints"]:assert original.doc["nodes"][index]==bundle.doc["nodes"][index]
        attrs=b["primitives"][0]["attributes"]
        body=bundle.values(attrs["POSITION"]);colors=bundle.values(attrs["COLOR_0"])
        hidden=body[colors[:,1]>.5]
        check_seams(bundle,rec,body)
        worst=0.
        for outfit in manifest["outfits"]:
            cloth=[];triangles=0
            for name in rec["outfits"][outfit]:
                for p in bundle.mesh(name)["primitives"]:
                    pos=bundle.values(p["attributes"]["POSITION"]);cloth.append(pos)
                    assert np.isfinite(pos).all()
                    weights=bundle.values(p["attributes"]["WEIGHTS_0"])
                    assert np.allclose(weights.sum(axis=1),1,atol=1e-5)
                    assert bundle.values(p["attributes"]["JOINTS_0"]).max()<len(bundle.doc["skins"][0]["joints"])
                    triangles+=bundle.doc["accessors"][p["indices"]]["count"]//3
            cloth=np.concatenate(cloth)
            gap=0.
            for offset in range(0,len(hidden),96):
                distances=((hidden[offset:offset+96,None,:]-cloth[None,:,:])**2).sum(axis=2)
                gap=max(gap,float(np.sqrt(distances.min(axis=1)).max()))
            assert gap<.065,(rec["variant"],outfit,gap)
            worst=max(worst,gap)
        print("WARDROBE_BUFFER_CHECK PASS",rec["variant"],"face/rig exact; max covered-skin gap %.3fm"%worst,flush=True)


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("--root",default=".")
    check(os.path.abspath(parser.parse_args().root))
