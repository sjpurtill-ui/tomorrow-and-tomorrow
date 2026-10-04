"""Raw invariants for additive legacy clothes; independent of import caches."""
import argparse
import hashlib
import json
import os
import numpy as np
from validate_court_wardrobe import GLB

CHANNELS={'hide':1,'tunic':2,'robe':3}
BODIES={'male_adult','female_adult','male_old','female_old','male_young','female_young','child'}


def check(root,complete=False):
    folder=os.path.join(root,'assets','court_figures','legacy')
    manifest=json.load(open(os.path.join(folder,'court_legacy.json')))
    assert manifest['version']==1
    if complete:assert set(manifest['variants'])==BODIES
    for variant,record in manifest['variants'].items():
        if complete:assert set(record['outfits'])==set(CHANNELS)
        source=GLB(os.path.join(root,'assets','court_figures','court_figure_'+variant+'.glb'))
        bundle=GLB(os.path.join(folder,record['file']))
        assert hashlib.sha256(source.raw).hexdigest()==record['source_sha256']
        assert hashlib.sha256(bundle.raw).hexdigest()==record['sha256']
        assert 'animations' not in bundle.doc
        old,new=source.mesh('Body'),bundle.mesh('LegacyBody')
        assert old.get('weights')==new.get('weights') and old.get('extras')==new.get('extras')
        channels=[0]+[CHANNELS[k] for k in CHANNELS if k not in record['outfits']]
        for a,b in zip(old['primitives'],new['primitives']):
            for name,index in a['attributes'].items():
                av,bv=source.values(index),bundle.values(b['attributes'][name])
                if name=='COLOR_0':assert np.array_equal(av[:,channels],bv[:,channels]),(variant,name)
                else:assert np.array_equal(av,bv),(variant,name)
            assert np.array_equal(source.values(a['indices']),bundle.values(b['indices']))
            assert len(a.get('targets',[]))==len(b.get('targets',[]))
            for at,bt in zip(a.get('targets',[]),b.get('targets',[])):
                for name,index in at.items():assert np.array_equal(source.values(index),bundle.values(bt[name])),(variant,name)
        for a,b in zip(source.doc['skins'],bundle.doc['skins']):
            assert a['joints']==b['joints']
            assert np.array_equal(source.values(a['inverseBindMatrices']),bundle.values(b['inverseBindMatrices']))
            for index in a['joints']:assert source.doc['nodes'][index]==bundle.doc['nodes'][index]
        names=[n['name'] for n in bundle.doc['nodes'] if 'mesh' in n]
        expected=['LegacyBody']+[name for parts in record['parts'].values() for name in parts]
        assert sorted(names)==sorted(expected),(variant,names,expected)
        triangles=0
        for kind in record['outfits']:
            for name in record['parts'][kind]:
                for primitive in bundle.mesh(name)['primitives']:
                    attributes=primitive['attributes']
                    points=bundle.values(attributes['POSITION'])
                    faces=bundle.values(primitive['indices']).reshape(-1,3)
                    weights=bundle.values(attributes['WEIGHTS_0'])
                    assert np.isfinite(points).all() and np.isfinite(weights).all()
                    assert faces.max()<len(points)
                    assert np.allclose(weights.sum(axis=1),1,atol=1e-5)
                    assert (weights>=0).all()
                    assert bundle.values(attributes['JOINTS_0']).max()<len(bundle.doc['skins'][0]['joints'])
                    triangles+=len(faces)
        print('LEGACY_CLOTH_RAW PASS',variant,record['outfits'],triangles,'triangles; originalbody/face/rig exact',flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--root',default='.')
    parser.add_argument('--complete',action='store_true')
    args=parser.parse_args();check(os.path.abspath(args.root),args.complete)
