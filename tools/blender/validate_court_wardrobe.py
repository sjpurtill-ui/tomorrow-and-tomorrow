"""Validate wardrobe GLBs independently of Blender/Godot's import cache.
Run with Python + numpy from the explicit project root. Checks every byte-valued
skin attribute/morph, named bind pose and complete outfit coverage at rest.
"""
import argparse
import hashlib
import json
import os
import struct
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
