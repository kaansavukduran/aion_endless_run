extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+message)
func _initialize():call_deferred('run')
func run():
 var w=AionCampaignWorld.new();w.begin('aion');w.player=Vector2(900,0)
 var kinds=['crow','gnome','moth','slime','beetle','wisp','warden','drone','seed']
 kinds.append_array(CampaignContent.NEW_ENEMIES.keys());kinds.append_array(CampaignContent.HEAVIES)
 for kind in kinds:
  for side in [-1,1]:
   w.enemies.clear();w.spawn_enemy(kind,900.+side*320.,-115. if CampaignContent.flying(kind) else 0.,1)
   var e: Dictionary=w.enemies[0];e.age=2.;var x: float=e.x
   w.step_enemies(1./60.)
   var target: int=-side
   check(int(e.facing)==target,kind+' really targets player on either side')
   if kind not in ['seed','mirror','vine','conductor','siphon']:
    check((float(e.x)-x)*target>0.,kind+' approaches in its facing direction')
   var authored: int=1 if kind in ['drone','seed'] else -1
   var mirror: int=AionCampaignView.enemy_draw_direction(kind,int(e.facing))
   check(authored*mirror==target,kind+' source nose points at player, not away')
   e.defeated=true;w.player.x=900.-side*500.;w.step_enemies(1./60.)
   check(int(e.facing)==target,kind+' defeat retains last facing rather than flipping toward a new target')
   w.player.x=900.
 # Actual registered crow/gnome clips are left-facing, including attack frames.
 var bank=RunnerFrameBank.new()
 for row in [0,1,3,4]:
  for frame in bank.count('enemies',row):
   var pose=bank.pose('enemies',row,frame)
   check(pose.source_key=='polish-enemies' and int(pose.source_row)==row,'Uses visually inspected original left-facing clip')
 # The approved rescue NPC walking frames are authored LEFT-facing. Check
 # their actual model movement, not the previous mistaken facing==raw-flip
 # assumption. These are isolated physics fixtures, not browser setters.
 var people:=AionCampaignWorld.new();people.begin('aion');people.state='playing'
 var npc: Dictionary=people.npcs[0]
 people.npcs=[npc];people.enemies.clear();people.objects.clear();people.hazards.clear();people.zones.clear();people.encounters.clear();people.gates.clear();people.crates.clear();people.pickups.clear();people.platforms.clear();people.pits.clear();people.boss.active=false
 people.player=Vector2(200,0);people.move_axis=Vector2.ZERO
 people.rescue(npc)
 var catalogue:=CampaignCatalog.new()
 for variant in 8:
  npc.variant=variant
  for semantic in [-1,1]:
   npc.x=600.;npc.home_x=600.;npc.y=0.;npc.phase='free';npc.free_age=0.;npc.facing=semantic;npc.roam_clock=0.;people.pits.clear()
   var old_x: float=npc.x
   people.step(.05)
   var delta: float=float(npc.x)-old_x
   check(delta*semantic>0.,'Freed NPC actually roams in its semantic direction: '+str(variant)+'/'+str(semantic))
   check(-AionCampaignView.npc_draw_direction(int(npc.facing))==int(signf(delta)),'Left-authored NPC nose follows its real stride: '+str(variant)+'/'+str(semantic))
   var frame: int=6+posmod(int(people.time*6.),2)
   var pose: Dictionary=catalogue.pose('rescue-npcs',variant,frame)
   check(pose.source_key=='rescue-npcs' and int(pose.source_row)==variant and int(pose.source_frame)==frame and pose.texture!=null,'Roaming uses its real registered walk frame, preserving NPC identity')
   check(not people.awarded.has(str(npc.id)+':gift'),'Roaming away from the hero cannot grant a remote gift')
   npc.x=600.;npc.facing=semantic;npc.roam_clock=0.
   people.pits.clear();people.pits.append(Vector2(600.1,680.) if semantic==1 else Vector2(520.,599.9))
   old_x=float(npc.x);people.step(.05)
   check(is_equal_approx(float(npc.x),old_x),'Blocked NPC does not walk across unsupported floor or fake movement')
   check(int(npc.facing)==-semantic,'NPC turns away from its actual unsupported edge')
   old_x=float(npc.x);people.step(.05);delta=float(npc.x)-old_x
   check(delta*(-semantic)>0.,'After turning the next actual stride moves away from the edge')
   check(-AionCampaignView.npc_draw_direction(int(npc.facing))==int(signf(delta)),'The changed walk direction keeps the source face aligned')
 # Enter thanks through actual body contact, then leave before the bag item
 # appears. Departing must walk LEFT while looking LEFT, and keep its drop.
 people.pits.clear();npc.x=600.;npc.home_x=600.;npc.phase='free';npc.free_age=1.;npc.facing=-1;npc.roam_clock=0.;npc.variant=0
 people.player=Vector2(600,0);people.step(.05)
 check(str(npc.phase)=='thanks','Real freed-NPC contact enters thanks before departure')
 check(-AionCampaignView.npc_draw_direction(int(npc.facing))==int(npc.facing),'Thanks faces the contacted hero using the same authored source convention')
 people.player.x=200.
 for i in 42:people.step(.05)
 check(str(npc.phase)=='departed' and people.pickups.any(func(item):return str(item.id)==str(npc.id)+':supply'),'Bag item stays in the world when the thanked NPC starts leaving')
 for i in 3:
  var old_x: float=npc.x;people.step(.05)
  check(float(npc.x)<old_x and int(npc.facing)==-1,'Departing NPC really walks left, not backwards')
  check(-AionCampaignView.npc_draw_direction(int(npc.facing))==-1,'Departing NPC original left face stays aligned to its actual movement')
  var frame: int=6+posmod(int(people.time*6.),2)
  var pose: Dictionary=catalogue.pose('rescue-npcs',int(npc.variant),frame)
  check(pose.source_key=='rescue-npcs' and int(pose.source_frame)==frame,'Departure reuses the same actual two walking frames')
 check(not people.awarded.has(str(npc.id)+':gift'),'Departure cannot silently collect the unclaimed bag item')
 print('RESULT: ',checks,' enemy facing checks, ',failures,' failures');quit(1 if failures else 0)
