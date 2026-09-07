"""Author metre-scale early settlement GLBs and an offline asset contact sheet.
Blender --background --python tools/build_early_settlement_kit.py
No live game, save, or simulation input is changed.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/buildings/early_settlement'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
mat=bpy.data.materials.new('Early settlement vertex colours');mat.use_nodes=True
bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=.92
vc=mat.node_tree.nodes.new('ShaderNodeVertexColor');vc.layer_name='Color'
mat.node_tree.links.new(vc.outputs['Color'],bsdf.inputs['Base Color'])
WOOD=(.22,.105,.045,1); FIBRE=(.51,.39,.20,1); CLOTH=(.48,.40,.28,1)
EARTH=(.47,.30,.17,1); STONE=(.32,.33,.27,1); DARK=(.055,.044,.028,1)
parts=[]
def finish(o,color):
    bpy.context.view_layer.objects.active=o
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.clear();o.data.materials.append(mat)
    attr=o.data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
    for c in attr.data:c.color=color
    parts.append(o);return o

def box(at,size,color):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.dimensions=size
    return finish(o,color)

def pole(a,b,r=.045,color=WOOD):
    a,b=Vector(a),Vector(b);d=b-a
    bpy.ops.mesh.primitive_cylinder_add(vertices=7,radius=r,depth=d.length,location=(a+b)/2)
    o=bpy.context.object;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();return finish(o,color)

def panel(verts,color):
    mesh=bpy.data.meshes.new('woven panel');mesh.from_pydata(verts,[],[tuple(range(len(verts)))])
    o=bpy.data.objects.new('panel',mesh);bpy.context.collection.objects.link(o)
    return finish(o,color)

def gable(width=3.5,depth=3.8,eave=2.0,ridge=3.25):
    # Overlapping courses have real thickness and bounded silhouette detail.
    for side in [-1,1]:
      for row in range(9):
        t=row/9;u=min(1,(row+1.25)/9)
        x0=side*width*.5*t;x1=side*width*.5*u
        z0=ridge+(eave-ridge)*t;z1=ridge+(eave-ridge)*u
        color=tuple(v*(1+.035*((row%3)-1)) for v in FIBRE[:3])+(1,)
        for j in range(6):
          y0=-depth/2+j*depth/6;y1=y0+depth/6+.035
          panel([(x0,y0,z0+.025),(x1,y0,z1),(x1,y1,z1),(x0,y1,z0+.025)],color)
    pole((0,-depth*.53,ridge+.025),(0,depth*.53,ridge+.025),.07)

def walls(color=EARTH,height=1.95):
    box((0,.0,.06),(3.15,3.3,.12),color)
    for x in [-1.5,1.5]:box((x,0,height/2),(.17,3.3,height),color)
    box((0,1.55,height/2),(3.1,.18,height),color)
    # Actual open door, not a dark rectangle on an unbroken wall.
    for x in [-1.02,1.02]:box((x,-1.55,height/2),(1.03,.18,height),color)
    box((0,-1.55,height-.12),(.98,.2,.24),WOOD)

def ridge_camp():
    for side in [-1,1]:
      for j in range(7):
        a=-1.6+j*3.2/7;b=a+3.2/7+.015
        panel([(0,a,1.65),(side*1.35,a,.08),(side*1.35,b,.08),(0,b,1.65)],tuple(v*(1+.02*(j%3)) for v in CLOTH[:3])+(1,))
    for y in [-1.65,1.65]:
      pole((0,y,0),(0,y,1.7),.04)
      for x in [-1.35,1.35]:pole((x,y,0),(x,y,.18),.025)
    pole((0,-1.76,1.67),(0,1.76,1.67),.045)
    # One end tied shut, entrance opposite left open.
    panel([(-1.3,1.6,.1),(1.3,1.6,.1),(0,1.6,1.62)],CLOTH)

def round_camp():
    for i in range(16):
      a=i*math.tau/16;b=(i+1)*math.tau/16
      if i in [11,12]:continue
      v=lambda r,t,z:(r*math.cos(t),r*math.sin(t),z)
      panel([v(1.65,a,.06),v(1.65,b,.06),v(.85,b,1.32),v(.85,a,1.32)],CLOTH)
      panel([v(.85,a,1.32),v(.85,b,1.32),(0,0,1.95)],FIBRE)
      if i%2==0:pole(v(1.63,a,0),v(.35,a,1.78),.028)

def lean_to(work=False):
    for x in [-1.35,1.35]:
      pole((x,-1.4,0),(x,-1.4,1.9));pole((x,1.35,0),(x,1.35,.7))
      pole((x,-1.5,1.9),(x,1.5,.7),.065)
    for j in range(10):
      y=-1.6+j*.33;z=1.95-(y+1.6)*.375
      box((0,y,z),(3.1,.38,.075),FIBRE)
    for i in range(8):pole((-1.3,1.25,.12+i*.075),(1.3,1.25,.12+i*.075),.025)
    if work:
      box((0,.0,.85),(1.9,.65,.10),WOOD)
      for x in [-.75,.75]:pole((x,0,0),(x,0,.85),.06)
      box((.4,-.1,.96),(.6,.14,.10),FIBRE)
    else:
      for x in [-.65,.65]:box((x,.25,.06),(.85,1.45,.12),CLOTH)

def round_house():
    for i in range(24):
      a=i*math.tau/24;b=(i+1)*math.tau/24
      if i not in [17,18]:
        panel([(1.7*math.cos(a),1.7*math.sin(a),.04),(1.7*math.cos(b),1.7*math.sin(b),.04),(1.7*math.cos(b),1.7*math.sin(b),1.7),(1.7*math.cos(a),1.7*math.sin(a),1.7)],EARTH)
      if i%3==0:pole((1.72*math.cos(a),1.72*math.sin(a),0),(1.72*math.cos(a),1.72*math.sin(a),1.78),.045)
      for row in range(6):
        r0=.1+1.85*row/6;r1=.1+1.85*(row+1)/6
        z0=3.05-1.3*row/6;z1=3.05-1.3*(row+1)/6
        panel([(r0*math.cos(a),r0*math.sin(a),z0+.025),(r1*math.cos(a),r1*math.sin(a),z1),(r1*math.cos(b),r1*math.sin(b),z1),(r0*math.cos(b),r0*math.sin(b),z0+.025)],FIBRE)

def earth_house():
    walls()
    for x in [-1.35,-.65,0,.65,1.35]:pole((x,-1.8,2.03),(x,1.8,2.03),.09)
    box((0,0,2.17),(3.3,3.6,.18),EARTH)
    for x in [-1.55,1.55]:box((x,0,2.34),(.17,3.5,.18),EARTH)
    box((0,1.65,2.34),(3.2,.18,.18),EARTH)

def stone_house():
    # Dry rubble, uneven coursing and small openings; no invented dressed masonry.
    rng=random.Random(41)
    for row in range(7):
      for side in [-1,1]:
        for j in range(8):
          y=-1.6+j*.43
          box((side*1.48+rng.uniform(-.025,.025),y+rng.uniform(-.045,.045),row*.245+.13),(.24,rng.uniform(.36,.45),rng.uniform(.21,.26)),tuple(v*rng.uniform(.88,1.13) for v in STONE[:3])+(1,))
      for j in range(8):
        x=-1.43+j*.41
        for y in [-1.62,1.62]:
          if y<0 and abs(x)<.55:continue
          box((x,y,row*.245+.13),(rng.uniform(.36,.44),.24,rng.uniform(.22,.26)),STONE)
    for x in [-1.2,-.6,0,.6,1.2]:pole((x,-1.8,1.83),(x,1.8,1.83),.075)
    for i in range(7):
      for j in range(8):box((-1.48+i*.49,-1.68+j*.48,1.96+rng.uniform(-.018,.018)),(.50,.49,.18),STONE)

def raised_store():
    for x in [-1.15,1.15]:
      for y in [-1.35,1.35]:pole((x,y,0),(x,y,2.1),.11)
    for i in range(12):box((-1.25+i*.23,0,.65),(.22,2.9,.12),WOOD)
    for y in [-1.35,1.35]:
      for row in range(8):pole((-1.3,y,.8+row*.14),(1.3,y,.8+row*.14),.05,FIBRE)
    for x in [-1.25,1.25]:
      for row in range(8):pole((x,-1.35,.8+row*.14),(x,1.35,.8+row*.14),.05,FIBRE)
    gable(3.4,3.6,2.02,3.05)

def patterned_beam(y,z,width):
    box((0,y,z),(width,.16,.23),WOOD)
    red=(.42,.12,.055,1);cream=(.68,.57,.34,1)
    for i in range(int(width/.28)):
      x=-width/2+.14+i*.28
      panel([(x-.09,y-.086,z-.07),(x+.09,y-.086,z-.07),(x,y-.086,z+.08)],red if i%2 else cream)

def communal_hall(enclosed=False):
    # Matched material and craft standard; politics changes access and enclosure.
    for x in [-3.4,3.4]:
      for y in [-4.2,-1.4,1.4,4.2]:
        pole((x,y,0),(x,y,3.1),.16)
        pole((x,y,2.2),(x*.73,y,3.1),.09)
    gable(7.9,10,3.05,5.1)
    for y in [-4.35,4.35]:patterned_beam(y,3.05,7.2)
    if enclosed:
      for x in [-3.45,3.45]:box((x,0,1.25),(.18,8.8,2.5),EARTH)
      box((0,4.35,1.25),(7,.18,2.5),EARTH)
      for x in [-2.4,2.4]:box((x,-4.35,1.25),(2.15,.18,2.5),EARTH)
      # Deliberate approach and small forecourt; no free defensive wall.
      for x in [-4.8,4.8]:
        for y in [-7,-5.8,-4.6]:pole((x,y,0),(x,y,1.1),.09)
        for z in [.4,.85]:pole((x,-7,z),(x,-4.4,z),.06)
      box((0,-5,.12),(3,1.2,.24),WOOD)
    else:
      # Open-sided common house: seating and an accessible shared interior.
      for x in [-2.8,2.8]:
        box((x,0,.6),(.55,7.6,.12),WOOD)
        for y in [-3,0,3]:pole((x,y,0),(x,y,.6),.08)
      box((0,1,.8),(1.4,2.8,.12),WOOD)
    for x in [-3.4,3.4]:
      for z in [.9,1.08,2.2]:box((x,-4.37,z),(.37,.07,.075),(.46,.15,.065,1))

def decorated_household():
    round_house()
    for x in [-.48,.48]:
      pole((x,-1.72,0),(x,-1.72,1.72),.08)
      for z in [.4,.6,1.15,1.35]:box((x,-1.79,z),(.15,.04,.065),(.58,.23,.095,1))
    patterned_beam(-1.76,1.75,1.25)

builders={'carried_ridge':ridge_camp,'carried_round':round_camp,'rooted_lean_to':lean_to,'round_household':round_house,'earthen_household':earth_house,'rubble_household':stone_house,'raised_store':raised_store,'covered_workshop':lambda:lean_to(True)}
manifest={}
for name,build in builders.items():
    parts=[];build()
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:p.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
    obj=bpy.context.object;obj.name=name
    bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    # One mesh, one vertex-colour material, export in metres with identity transform.
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True)
    manifest[name]={'dimensions_m':[round(v,3) for v in obj.dimensions],'vertices':len(obj.data.vertices),'polygons':len(obj.data.polygons)}
    obj.hide_render=True;obj.hide_viewport=True
cultural={'crafted_household':decorated_household,'open_common_hall':communal_hall,'enclosed_authority_hall':lambda:communal_hall(True)}
for name,build in cultural.items():
    parts=[];build();bpy.ops.object.select_all(action='DESELECT')
    for part in parts:part.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
    obj=bpy.context.object;obj.name=name;bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True)
    manifest[name]={'dimensions_m':[round(v,3) for v in obj.dimensions],'vertices':len(obj.data.vertices),'polygons':len(obj.data.polygons),'status':'authored study; not selected by runtime; requires recorded construction-era culture and patronage'}
    obj.hide_render=True;obj.hide_viewport=True
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
# Offline review sheet uses the exported author's actual geometry, not concept art.
for index,name in enumerate(builders):
    obj=bpy.data.objects[name];obj.hide_render=False;obj.hide_viewport=False
    obj.location=((index%4)*6.1,(index//4)*7.4,0)
    bpy.ops.object.text_add(location=(obj.location.x-2.1,obj.location.y-2.65,.05))
    label=bpy.context.object;label.data.body=name.replace('_',' ');label.data.size=.29
    label.data.materials.append(mat)
box((9.0,3.3,-.18),(26,16,.3),(.20,.24,.16,1))
bpy.ops.object.light_add(type='AREA',location=(4,-5,18));bpy.context.object.data.energy=3600;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=12
bpy.ops.object.camera_add(location=(18,-22,25));cam=bpy.context.object;target=Vector((9,3.4,.4));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=28;bpy.context.scene.camera=cam
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.world.color=(.4,.4,.4)
scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'asset-review.png')
bpy.ops.render.render(write_still=True)

# A second plate compares political expression at equal craft/material quality.
for obj in list(bpy.context.scene.objects):
    if obj.type in {'MESH','FONT'}:obj.hide_render=True
for index,name in enumerate(cultural):
    obj=bpy.data.objects[name];obj.hide_render=False;obj.location=(index*12,0,0)
    bpy.ops.object.text_add(location=(obj.location.x-3,-8,.05));label=bpy.context.object
    label.data.body=name.replace('_',' ');label.data.size=.43;label.data.materials.append(mat)
box((12,-1,-.19),(39,22,.3),(.20,.24,.16,1))
cam.location=(27,-30,30);cam.rotation_euler=(Vector((12,-1,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=39
scene.render.resolution_x=1800;scene.render.resolution_y=950;scene.render.filepath=str(OUT/'cultural-studies.png');bpy.ops.render.render(write_still=True)
