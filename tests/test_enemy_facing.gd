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
 print('RESULT: ',checks,' enemy facing checks, ',failures,' failures');quit(1 if failures else 0)
