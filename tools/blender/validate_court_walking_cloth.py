"""Check actual hand/skirt intersections in Godot's exported walking poses.

python tools/blender/validate_court_walking_cloth.py reports/court_wardrobe_walk/poses.jsonl
Uses every exported hand/skirt triangle, not the stretch audit's edge sampling.
"""
import argparse
import json
from collections import Counter
import numpy as np


def edges(faces):
    pairs=np.concatenate((faces[:,[0,1]],faces[:,[1,2]],faces[:,[2,0]]))
    return np.unique(np.sort(pairs,axis=1),axis=0)


def intersections(segments,triangles):
    """Segment/triangle crossings; exclude endpoints and mere tangent contact."""
    bounds_min=triangles.min(axis=1);bounds_max=triangles.max(axis=1)
    found=[]
    for start in range(0,len(segments),96):
        segment=segments[start:start+96]
        nearby=np.all(bounds_max>=segment.min(axis=(0,1)),axis=1)&np.all(bounds_min<=segment.max(axis=(0,1)),axis=1)
        if not np.any(nearby):continue
        a,b,c=triangles[nearby,0],triangles[nearby,1],triangles[nearby,2]
        edge1,edge2=b-a,c-a
        origin=segment[:,0,None,:];direction=(segment[:,1]-segment[:,0])[:,None,:]
        cross=np.cross(direction,edge2)
        determinant=np.sum(edge1*cross,axis=2)
        inverse=np.divide(1.,determinant,out=np.zeros_like(determinant),where=np.abs(determinant)>1e-10)
        relative=origin-a
        u=np.sum(relative*cross,axis=2)*inverse
        q=np.cross(relative,edge1)
        v=np.sum(direction*q,axis=2)*inverse
        t=np.sum(edge2*q,axis=2)*inverse
        hit=(np.abs(determinant)>1e-10)&(u>1e-5)&(v>1e-5)&(u+v<1-1e-5)&(t>1e-5)&(t<1-1e-5)
        rows,columns=np.nonzero(hit)
        if len(rows):found.extend((origin[rows,0]+direction[rows,0]*t[rows,columns,None]).tolist())
    return found


def records(path):
    with open(path,encoding="utf-8-sig") as source:
        for line in source:yield json.loads(line)


def check(path):
    failures=[];count=0;groups=Counter()
    for record in records(path):
        count+=1
        hands=np.array(record["hands"]);cloth=np.array(record["cloth"])
        hf=np.array(record["hand_triangles"]).reshape(-1,3)
        cf=np.array(record["triangles"]).reshape(-1,3)
        assert len(hands)>10 and len(hf)>10 and len(cf)>100,"Incomplete walking export"
        hits=intersections(hands[edges(hf)],cloth[cf])
        hits+=intersections(cloth[edges(cf)],hands[hf])
        if hits:
            key="%s %s %s"%(record["variant"],record["outfit"],record["clip"])
            groups[key]+=1
            failures.append({"pose":key,"time":record["time"],"crossings":len(hits),"first":hits[0]})
    print("WARDROBE_WALK_COLLISION",json.dumps({"poses":count,"failed":len(failures),"groups":groups,
          "worst":sorted(failures,key=lambda item:item["crossings"],reverse=True)[:12]}))
    assert count>0,"Empty walking export"
    return len(failures)


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("poses")
    raise SystemExit(1 if check(parser.parse_args().poses) else 0)
