extends SceneTree
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
 checks+=1
 if not value:failures+=1;printerr('FAIL: '+message)
func clean() -> AionCampaignWorld:
 var w:=AionCampaignWorld.new();w.begin('aion');w.state='playing';w.player=Vector2(400,0)
 w.enemies.clear();w.objects.clear();w.hazards.clear();w.zones.clear();w.encounters.clear();w.gates.clear();w.npcs.clear();w.pickups.clear();w.crates.clear();w.platforms.clear();w.pits.clear();w.boss.active=false;w.invulnerable=0.
 return w
func enemy_bullet(w,y: float) -> Dictionary:
 return {'p':Vector2(w.player.x,y),'v':Vector2.ZERO,'owner':'enemy','age':0.,'kind':'seed','damage':1,'pierce':0,'hit':[]}
func encode_encounter(save: Dictionary, encounter: Dictionary) -> void:
 save.encounter=Marshalls.raw_to_base64(var_to_bytes(encounter))
 save.encounter_sha=save.encounter.sha256_text()
func check_weapon_stock() -> void:
 var w:=clean()
 check(w.ammunition==CampaignWeapons.PISTOL_START,'Fresh Mission 1 starts with finite pistol stock')
 w.ammunition=1;w.attack_press()
 check(w.ammunition==0 and w.bullets.size()==1 and w.shots==1,'The last pistol round leaves the actual muzzle and changes the stock to zero')
 var empty:=w.snapshot();var reopened:=AionCampaignWorld.new()
 check(reopened.restore(empty) and reopened.ammunition==0,'A modern checkpoint preserves an empty pistol')
 w.attack_release();w.fire_time=0.;w.attack_press()
 check(w.melee_time>0. and w.shots==1 and w.bullets.size()==1,'Pressing attack on an empty pistol throws a fist even without a target')
 w.attack_release();w.fire_time=0.;w.spawn_enemy('gnome',458.,0.,999);w.attack_press()
 for i in 4:w.step(.05)
 check(w.enemies[0].defeated and w.shots==1 and w.ammunition==0,'Empty-pistol melee damages an actual contact target at the attack frame')
 w.collect({'id':'rocket-slot','kind':'rocket'});var rocket_stock:=w.ammunition
 w.collect({'id':'field-ammo','kind':'pistol_ammo'});w.collect({'id':'field-ammo','kind':'pistol_ammo'})
 check(w.ammunition==rocket_stock and w.pistol_reserve==CampaignWeapons.PISTOL_REFILL,'Collecting one box stores only one sidearm refill under an equipped launcher')
 w.ammunition=1;w.fire_time=0.;w.attack_release();w.attack_press()
 check(w.weapon=='pistol' and w.ammunition==CampaignWeapons.PISTOL_REFILL and w.pistol_reserve==0,'The last rocket re-equips the stored pistol reserve')
 var legacy: Dictionary=bytes_to_var(Marshalls.base64_to_raw(empty.encounter))
 legacy.erase('pistol_reserve');encode_encounter(empty,legacy)
 check(reopened.restore(empty) and reopened.ammunition==CampaignWeapons.PISTOL_START,'A legacy unlimited pistol checkpoint receives the finite starter stock once')
 legacy.weapon='trap';legacy.ammunition=12
 legacy.crates=[{'id':'old-trap-box','x':730.,'y':0.,'hp':1,'kind':'trap'}]
 legacy.bullets=[{'p':Vector2(720.,-10.),'v':Vector2.RIGHT,'kind':'trap','owner':'hero','age':0.}]
 encode_encounter(empty,legacy)
 check(reopened.restore(empty) and reopened.weapon=='rocket' and reopened.ammunition==6 and reopened.pistol_reserve==CampaignWeapons.PISTOL_START,'Legacy equipment converts launcher stock and restores its fallback sidearm')
 check(reopened.bullets.is_empty() and reopened.blasts.is_empty() and reopened.crates[0].kind=='rocket','Legacy mine is removed without damage and the original unopened box ID stays playable')
 var restore_again:=AionCampaignWorld.new()
 check(restore_again.restore(reopened.snapshot()) and restore_again.ammunition==6,'Migrated launcher stock does not shrink again on another load')
 var stock_ids:=reopened.pickups.filter(func(p):return p.kind=='pistol_ammo')
 CampaignWeapons.populate_sidearm(reopened)
 check(not stock_ids.is_empty() and reopened.pickups.filter(func(p):return p.kind=='pistol_ammo').size()==stock_ids.size(),'Older checkpoints gain one copy of each authored field stock box')
 w=clean();w.ammunition=0;w.crates=[{'id':'emergency-stock','x':467.,'y':0.,'hp':1,'kind':'pistol_ammo'}]
 w.attack_press();w.step(.05)
 check(w.crates[0].hp==1 and w.pickups.is_empty(),'Empty-pistol punch cannot break a supply box before its contact cel')
 for i in 3:w.step(.05)
 check(w.crates[0].hp==0 and w.pickups.any(func(p):return p.id=='emergency-stock') and w.shots==0,'The punch contact cel can open an actual supply box without ammunition')
 w.attack_release();w.move_axis=Vector2.RIGHT
 for i in 8:w.step(.05)
 check(w.taken.has('emergency-stock') and w.ammunition==CampaignWeapons.PISTOL_REFILL,'Walking into the newly opened box restocks an empty sidearm through normal overlap')
 w=clean();w.ammunition=0;w.objects=[{'id':'breakable-gate','kind':'gate','x':451.,'y':0.,'hp':1,'active':false,'secret':''}]
 w.attack_press()
 for i in 4:w.step(.05)
 check(w.objects[0].active and w.shots==0,'An empty sidearm can still pass an ordinary breakable gate by punching it')
func check_guarded_beetle() -> void:
 var w:=clean();w.invulnerable=99.;w.spawn_enemy('beetle',650.,0.,911)
 var beetle: Dictionary=w.enemies[0];beetle.wait=40.
 w.attack_press()
 for i in 10:w.step_bullets(.05)
 check(not beetle.defeated and w.blasts.any(func(b):return b.get('kind')=='armour_chip'),'A frontal shot visibly deflects from closed shell plating')
 w.attack_release();w.enemy_shot(beetle)
 for i in 14:w.step_enemies(.05)
 check(CampaignWeapons.shell_open(beetle),'A completed charge opens a real recovery window')
 w.player.x=float(beetle.x)-140.;w.fire_time=0.;w.attack_press()
 for i in 8:w.step_bullets(.05)
 check(beetle.defeated,'The same frontal shot can punish the recovering beetle')
func _initialize() -> void:call_deferred('run')
func run() -> void:
 check_weapon_stock()
 check_guarded_beetle()
 var w:=clean();w.move_axis=Vector2(1,1)
 check(w.crouching(),'Down on solid floor crouches')
 var start:=w.player;w.step(.05)
 check(w.player.x>start.x and is_equal_approx(w.velocity.x,235.*.42),'Crouch retains deliberate crawl movement instead of freezing')
 check(w.player.y==0. and w.player_hit_center().y==-20. and w.player_hit_radius()==17.,'Crouch roots feet and uses its smaller physical body')
 w.aim_direction=Vector2.RIGHT;w.attack_press();w.step(.05)
 check(w.shots>0 and w.player.x>start.x+5.,'Normal attack action can fire while crawling')
 w.attack_release();w.bullets.clear();w.invulnerable=0.;w.bullets.append(enemy_bullet(w,-37.));w.step_bullets(.01)
 check(w.hp==1 and w.attempts_remaining==3,'Chest-height projectiles pass over a crouching player')
 w.bullets.clear();w.invulnerable=0.;w.bullets.append(enemy_bullet(w,-12.));w.step_bullets(.01)
 check(w.hp==0 and w.attempts_remaining==2,'Low projectiles still hit crouch; it is not invulnerability')
 w=clean();w.bullets.append(enemy_bullet(w,-37.));w.step_bullets(.01)
 check(w.hp==0 and w.attempts_remaining==2,'The same chest shot still hits a standing player')
 w=clean();w.platforms.append(Rect2(300,-70,300,20));w.player.y=-70.;w.move_axis=Vector2(0,1);w.jump_press()
 check(w.drop_through_time>0. and w.player.y>-70. and w.velocity.y>0.,'Down+Jump drops through a real one-way platform')
 for i in 15:w.step(.05)
 check(w.player.y==0. and w.grounded(),'Drop-through lands on the real lower floor')
 w=clean();w.load_section('fork_one');w.enemies.clear();w.objects.clear();w.player=Vector2(1000,90);w.velocity=Vector2.ZERO
 check(w.grounded(),'Positive-height lower route is real solid ground')
 w.move_axis=Vector2(1,1);w.step(.05)
 check(w.crouching() and w.player.y==90.,'Crawl stays on the lower physical route')
 for type in CampaignVehicles.TYPES:
  w=clean();w.mount={'available':true,'ridden':true,'x':400.,'hp':1,'type':type};w.player.y=-42.
  check(w.mount.hp==1,'Vehicle starts with one HP: '+type)
  var aim:=Vector2.from_angle(.37);w.aim_direction=aim;CampaignWeapons.fire(w)
  check(w.bullets.size()==1 and Vector2(w.bullets[0].v).normalized().is_equal_approx(aim),'One vehicle projectile preserves continuous surrounding aim: '+type)
  w.invulnerable=0.;w.damage_player()
  w.step(.05)
  check(CampaignVehicles.stunned(w) and int(w.mount.hp)==0,'One hit leaves a readable impact: '+type)
  w.step(.05)
  check(not bool(w.mount.ridden) and not bool(w.mount.available) and w.hp==1 and w.attempts_remaining==3,'A wreck ejects the pilot and leaves all lives: '+type)
  w.collect({'id':'repair:'+type,'kind':'repair'})
  check(w.mount.hp==0 and w.grenades==7,'Repair supplies grenades without reviving a wreck: '+type)
 w=clean();w.mount={'available':true,'ridden':true,'x':400.,'hp':1,'type':'skimmer'};w.player=Vector2(400,-342.)
 check(w.interact(),'Midair exit remains an actual supported interaction')
 w.step(.05)
 check(float(w.mount.floor_y)>-300. and float(w.mount.floor_y)<0.,'Unridden airborne hull falls instead of freezing or instantly snapping toY0')
 for i in 16:w.step(.05)
 check(is_equal_approx(float(w.mount.floor_y),0.) and not bool(w.mount.ridden),'Parked hull continues falling after the exit transition and lands on support')
 w.drop_through_time=.2
 check(CampaignVehicles.can_board(w) and w.interact(),'Landed bailed-out hull can be boarded again normally')
 check(w.drop_through_time==0.,'Boarding clears an on-foot drop-through timer rather than dropping the hull through its deck')
 w=clean();w.load_section('water');check(int(w.mount.hp)==1,'Regional rideable population also uses one HP')
 w.mount.ridden=true;w.player=Vector2(600,-42.);w.state='travel';w.load_section('fork_one')
 check(not w.mount.ridden and w.player.y==0.,'A physical route fork starts with the hero on foot')
 w.mount={'available':true,'ridden':true,'x':1000.,'hp':1,'type':'shell'}
 w.player=Vector2(1000,48.);w.velocity=Vector2.ZERO;CampaignVehicles.step(w,.05)
 check(is_equal_approx(w.player.y,48.) and w.grounded(),'Ridden vehicle lands on fork floor90 using its actual saddle offset')
 var mounted_save:=AionCampaignWorld.new();check(mounted_save.restore(w.snapshot()) and bool(mounted_save.mount.ridden) and int(mounted_save.mount.hp)==1,'A save made while riding still restores the live hull in its current scene')
 w=clean();w.spawn_enemy('gnome',720,0,1);w.spawn_enemy('beetle',790,0,2)
 w.collect({'id':'rocket-stock','kind':'rocket','x':w.player.x,'y':0.});w.attack_press()
 check(w.bullets.size()==1 and w.bullets.front().kind=='rocket' and w.ammunition==5,'One launch spends exactly one round and creates a forward rocket')
 for i in 25:w.step_bullets(.05)
 check(w.enemies.all(func(e):return bool(e.defeated)) and w.bullets.is_empty(),'Rocket contact affects the impact target and a nearby enemy once')
 var explosions: int=w.blasts.filter(func(b):return b.get('kind')=='rocket').size()
 for i in 10:w.step_bullets(.05)
 check(explosions==1 and w.blasts.filter(func(b):return b.get('kind')=='rocket').size()==1,'Rocket blast occurs exactly once')
 w=clean();w.crates=[{'id':'visible-rocket','kind':'rocket','x':620.,'y':0.,'hp':1}];w.step(.05)
 check(w.spider_parade.has('started') and w.weapon=='pistol' and w.blasts.is_empty() and w.bullets.is_empty(),'Approaching the old supply location starts ambient spiders without collecting or firing')
 var earlier:=CampaignWeapons.spider_position(w,0)
 w.time+=.67
 check(earlier.is_finite() and CampaignWeapons.spider_position(w,0).x>CampaignWeapons.spider_position(w,1).x and CampaignWeapons.spider_position(w,1).x>earlier.x,'Staggered spiders walk in order to the right on the authored floor')
 var spider_report:=CampaignWeapons.spider_snapshot(w)
 check(spider_report.size()==3 and spider_report.all(func(s):return bool(s.ambient) and not s.has('target')),'Native and browser observation expose ambient positions without combat target data')
 w.time+=CampaignWeapons.SPIDER_DISPLAY_TIME+2.
 check(not CampaignWeapons.spider_position(w,0).is_finite() and w.bullets.is_empty() and w.blasts.is_empty(),'Decorative procession ends silently and independently of combat')
 w=clean();w.spawn_enemy('crow',800,-115,1);var crow: Dictionary=w.enemies[0];w.enemy_shot(crow);w.step_enemies(.05)
 var old_forward_delta:=400.*(.05/.7)*2.
 check(absf((800.-float(crow.x))-old_forward_delta*.9)<.01,'Crow forward dive movement is exactly ten percent slower')
 w=clean();w.load_section('shore');var npc: Dictionary=w.npcs[0]
 w.enemies.clear();w.objects.clear();w.hazards.clear();w.zones.clear();w.encounters.clear();w.gates.clear();w.pickups.clear();w.crates.clear();w.platforms.clear();w.pits.clear();w.boss.active=false;w.npcs=[npc]
 npc.x=420.;npc.home_x=420.;npc.y=0.;npc.gift='heavy';npc.role='keeper';npc.facing=-1
 w.player=Vector2(400,0);w.hp=1;w.grenades=1;w.invulnerable=99.;w.rescue(npc)
 check(w.hp==1 and w.grenades==1 and w.weapon=='pistol','Freeing a rope does not remotely collect the NPC bag reward')
 for i in 5:w.step(.05)
 check(str(npc.phase)=='thanks','Actual freed-NPC contact begins thanks')
 w.player.x=200.
 for i in 23:w.step(.05)
 var gift_id: String=str(npc.id)+':supply';var gifts: Array=w.pickups.filter(func(p):return str(p.id)==gift_id)
 check(gifts.size()==1 and w.weapon=='pistol' and not w.awarded.has(str(npc.id)+':gift'),'Bag handover creates one visible unclaimed world item')
 check(w.gift_drops.has(str(npc.id)),'An unclaimed gift has a persistent physical record')
 var restored:=AionCampaignWorld.new();check(restored.restore(w.snapshot()),'Pending-gift checkpoint remains compatible with schema4')
 check(restored.pickups.filter(func(p):return str(p.id)==gift_id).size()==1,'Reopening restores exactly one unclaimed physical gift')
 w.move_axis=Vector2(1,0)
 for i in 30:
  w.step(.05)
  if w.taken.has(gift_id):break
 check(w.taken.has(gift_id) and w.awarded.has(str(npc.id)+':gift') and w.weapon=='heavy','Walking into the physical reward actually collects it')
 check(w.hp==1 and w.attempts_remaining==3 and w.grenades==2 and not w.gift_drops.has(str(npc.id)),'Rescue bonuses arrive once at item contact and pending state clears')
 var hp: int=w.hp;var ammo: int=w.ammunition;w.move_axis=Vector2.ZERO
 for i in 25:w.step(.05)
 check(w.hp==hp and w.ammunition==ammo,'Remaining in contact does not award the same gift twice')
 var done:=AionCampaignWorld.new();check(done.restore(w.snapshot()),'Collected-gift checkpoint reopens')
 check(done.pickups.filter(func(p):return str(p.id)==gift_id).is_empty(),'Claimed gift never respawns on reopening')
 var bad: Dictionary=restored.snapshot();bad.gift_drops[str(npc.id)].x='bad'
 check(not AionCampaignWorld.new().restore(bad),'Malformed pending-gift coordinates fail safely')
 print('RESULT: ',checks,' Mission1 mechanics checks, ',failures,' failures');quit(1 if failures else 0)
