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
        if 'hide' in record['outfits']:
            # The cape is optional at runtime. Its shoulder band must retain
            # actual body skin when look.without omits hide_cape. Check an
            # anatomical region by bind weights, independently of the shell
            # builder's coverage formula; always-present wrap coverage stays.
            attrs=new['primitives'][0]['attributes']
            points=bundle.values(attrs['POSITION'])
            joints=bundle.values(attrs['JOINTS_0'])
            weights=bundle.values(attrs['WEIGHTS_0'])
            colours=bundle.values(attrs['COLOR_0'])
            names=[bundle.doc['nodes'][i]['name'] for i in bundle.doc['skins'][0]['joints']]
            arms=[i for i,name in enumerate(names) if name.startswith('upper_arm.')]
            shoulders=(np.sum(weights*np.isin(joints,arms),axis=1)>=.5)&(points[:,1]>record['cape_join_y'])
            assert shoulders.sum()>20,(variant,'no shoulder coverage samples')
            assert np.all(colours[shoulders,CHANNELS['hide']]==0),(variant,'optional cape erases bare shoulders')
            assert np.count_nonzero(colours[:,CHANNELS['hide']])>100,(variant,'hide wrap lost body coverage')
        names=[n['name'] for n in bundle.doc['nodes'] if 'mesh' in n]
        expected=['LegacyBody']+[name for parts in record['parts'].values() for name in parts]
        assert sorted(names)==sorted(expected),(variant,names,expected)
        # Fastenings/footwear are exact. A cape retains all source attributes
        # and its original lower triangles, with one supported shoulder cap.
        preserved={'hide_cape','hide_cord','hide_footwraps','tunic_belt','tunic_shoes',
                   'robe_sash','robe_mantle','robe_mantle_edge','robe_shoes'}
        for name in preserved.intersection(names):
            a,b=source.mesh(name),bundle.mesh(name)
            cape=name in ('hide_cape','robe_mantle','robe_mantle_edge')
            supported=name in ('hide_cape','robe_mantle')
            assert len(b['primitives'])==len(a['primitives'])+int(supported)+int(cape),(variant,name,'surface count')
            height=source.values(old['primitives'][0]['attributes']['POSITION'])[:,1].max()
            if cape:assert .70*height<record['cape_join_y']<.80*height,(variant,'cape join out of shoulder region')
            for ap,bp in zip(a['primitives'],b['primitives']):
                assert ap.get('material')==bp.get('material')
                for key,index in ap['attributes'].items():
                    assert np.array_equal(source.values(index),bundle.values(bp['attributes'][key])),(variant,name,key)
                faces=source.values(ap['indices']).reshape(-1,3)
                if cape:
                    points=source.values(ap['attributes']['POSITION'])
                    faces=faces[np.max(points[faces,1],axis=1)<=record['cape_join_y']]
                assert np.array_equal(faces,bundle.values(bp['indices']).reshape(-1,3)),(variant,name,'lower drape triangles')
            if supported:
                attrs=b['primitives'][-1]['attributes']
                joints=bundle.values(attrs['JOINTS_0']);weights=bundle.values(attrs['WEIGHTS_0'])
                joint_names=[bundle.doc['nodes'][i]['name'].split('.')[0] for i in bundle.doc['skins'][0]['joints']]
                head=[i for i,n in enumerate(joint_names) if n in ('head','neck','jaw')]
                assert (np.sum(weights*np.isin(joints,head),axis=1)<.20001).all(),(variant,name,'cap includes face/neck')
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
