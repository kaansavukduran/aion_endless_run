extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+message)
func fresh() -> AionCampaignWorld:
 var w:=AionCampaignWorld.new();w.begin('aion');w.state='playing';w.player=Vector2(400,0);w.enemies.clear();w.npcs.clear();w.objects.clear();w.gates.clear();w.crates.clear();w.platforms.clear();w.pits.clear();return w
func _initialize() -> void:call_deferred('run')
func run() -> void:
 for type in CampaignVehicles.TYPES:
  for facing in [-1,1]:
   var w:=fresh();w.mount={'available':true,'ridden':true,'type':type,'x':400.,'hp':3,'dive':0.};w.player.y=-42.;w.facing=facing;w.aim_direction=Vector2(facing,0)
   w.jump_press();check(w.velocity.y<0.,'Actual Jump launches every vehicle '+type)
   w.step(.05);check(w.player.y < -42.,'Mounted hull really rises '+type)
   var vy: float=w.velocity.y;w.jump_release();w.jump_press();check(w.velocity.y==vy,'Airborne mounted jump cannot borrow Aion double jump')
   for i in 100:w.step(1./60.)
   check(w.grounded() and absf(w.player.y+42.)<.01,'Vehicle returns its actual feet to ground '+type)
   w.enemies.clear();w.spawn_enemy('gnome',400.+facing*210.,0.,0);w.attack_press()
   check(w.bullets.size()==3,'Each vehicle fires three source-muzzle projectiles')
   for i in 35:w.step_bullets(1./120.)
   check(w.enemies[0].defeated,'Actual level volley reaches small ground enemy '+type+'/'+str(facing))
 var w:=fresh();w.npcs=[{'id':'rope-test','x':620.,'y':0.,'freed':false,'secret':'','role':'keeper'}];w.weapon='trap';w.ammunition=4;w.attack_press()
 for i in 600:
  w.step_bullets(1./120.)
  if w.npcs[0].freed:break
 check(w.npcs[0].freed,'Real launched walking spider frees rope through its explosion')
 check(w.greeted.is_empty() and not w.awarded.has('rope-test:gift'),'Explosion rescue does not grant contact reward')
 w=fresh();w.npcs=[{'id':'protected','x':420.,'y':0.,'freed':false,'secret':'hidden','role':'keeper'}];CampaignWeapons.blast(w,Vector2(420,-30),145,3,'ffffff');check(not w.npcs[0].freed,'Blast cannot bypass undiscovered secret')
 w.npcs[0].secret='';w.npcs[0].cage='locked';w.objects=[{'id':'locked','active':false}];CampaignWeapons.blast(w,Vector2(420,-30),145,3,'ffffff');check(not w.npcs[0].freed,'Blast respects closed cage')
 for gun in ['scatter','seeker','spore']:
  w=fresh();w.weapon=gun;w.ammunition=9;w.attack_press();var b: Dictionary=w.bullets[0]
  check(Vector2(b.v).length()>500.,'Special projectile faster '+gun)
  check(float(b.life)*Vector2(b.v).length()>700.,'Special has useful travel range '+gun)
  if gun=='seeker':
   w.spawn_enemy('gnome',1000.,0.,0);b.target=w.enemies[0].id;CampaignWeapons.step(w,b,.5);check(Vector2(b.v).length()>700.,'Homing does not revert to old slow speed')
 w=fresh();w.npcs=[{'id':'late-rope','x':620.,'y':0.,'freed':false,'secret':'','role':'keeper'}]
 w.bullets=[{'p':Vector2(600,-60),'v':Vector2(760,0),'owner':'hero','age':3.1,'kind':'seeker','damage':1,'pierce':0,'hit':[],'life':3.3,'target':''}]
 w.step_bullets(.02);check(w.npcs[0].freed,'Longer-lived projectile still cuts ropes after the former three-second cutoff')
 var bank:=CampaignCatalog.new();var scale: float=-1.
 for frame in range(6,12):
  var pose:=bank.pose('rescue-npcs',7,frame)
  check(pose.texture.get_width()>0 and pose.texture.get_height()>0,'All six pirate walk cels are actually loaded')
  var ratio: float=pose.size.x/pose.texture.get_width()
  if scale<0:scale=ratio
  check(is_equal_approx(ratio,scale),'Pirate has fixed scale through all cels')
  check(absf(pose.offset.y+pose.size.y-2.*ratio)<.01,'Pirate soles stay at actual ground')
 print('RESULT: %d combat patch checks, %d failures'%[checks,failures]);quit(1 if failures else 0)
