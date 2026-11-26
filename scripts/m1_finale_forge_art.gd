class_name M1FinaleForgeArt
extends RefCounted

const VOID := Color("282026")
const OXIDE := Color("64413b")
const COPPER := Color("ae754f")
const EDGE := Color("e3a76b")
const LIGHT := Color("fff0af")
const EMBER := Color("d36951")
const ASH := Color("625151")
const LANTERNS := [1780., 2055., 2340., 2640., 2850.]
const LANTERN_ORDER := [0, 1, 2, 1, 2]

static var plate_outline := PackedVector2Array([
	Vector2(-27,-15),Vector2(-22,-23),Vector2(-9,-25),Vector2(-3,-19),Vector2(-3,20),
	Vector2(-9,26),Vector2(-22,22),Vector2(-28,14)
])
static var plate_inset := PackedVector2Array([
	Vector2(-24,-13),Vector2(-19,-20),Vector2(-10,-21),Vector2(-6,-17),Vector2(-6,17),
	Vector2(-10,22),Vector2(-20,19),Vector2(-25,12)
])
static var root_rind := PackedVector2Array([
	Vector2(-11,0),Vector2(-9,-.32),Vector2(-4,-.49),Vector2(-5,-.66),Vector2(2,-.81),
	Vector2(6,-1),Vector2(10,-.84),Vector2(8,-.56),Vector2(12,-.34),Vector2(10,0)
])
static var root_fibre := PackedVector2Array([
	Vector2(-7,0),Vector2(-5,-.45),Vector2(0,-.55),Vector2(-1,-.65),Vector2(6,-.94),
	Vector2(5,-.56),Vector2(8,-.37),Vector2(6,0)
])

static func motion_enabled(view) -> bool:
	return view.host.motion_enabled and not view.host.options.reduced_motion

static func draw_engine(view) -> void:
	var w=view.world
	if w.completed or not bool(w.boss.engaged):return
	var x:=float(w.boss.x)
	if x<view.camera_x-120. or x>view.camera_x+view.scene_w+120.:return
	var center: Vector2=view.at(CampaignBossPressure.core_point(w)).round()
	var moving:=motion_enabled(view)
	var phase:=int(w.boss.phase)
	var shifting:=float(w.boss.get("shift_pause",0.))
	var ports: Array=w.boss.get("ports",[3,3])
	if phase<3:
		for i in 2:
			var point: Vector2=view.at(CampaignBossPressure.port_point(w,i)).round()
			draw_socket(view,point,int(ports[i]) if phase==1 else 0)
			if shifting>0. and phase==2:
				var burst:=Vector2((-1. if i==0 else 1.)*(1.-shifting/.75)*17.,-4.)
				if not moving:burst=Vector2(0.,-4.)
				draw_sparks(view,point+burst)
	if CampaignBossPressure.core_exposed(w):
		draw_core(view,center,phase)
		return
	var protected_now:=not CampaignBossPressure.vulnerable(w)
	for side in [-1.,1.]:
		view.draw_set_transform(center,0.,Vector2(side,1.))
		view.draw_colored_polygon(plate_outline,VOID)
		view.draw_colored_polygon(plate_inset,COPPER if protected_now else OXIDE)
		view.draw_rect(Rect2(-21.,-11.,15.,3.),EDGE if protected_now else COPPER)
		view.draw_rect(Rect2(-19.,6.,13.,4.),OXIDE if protected_now else VOID)
		view.draw_rect(Rect2(-13.,-18.,4.,4.),EDGE)
		view.draw_rect(Rect2(-15.,15.,4.,4.),EDGE)
	view.draw_set_transform(Vector2.ZERO)
	view.draw_rect(Rect2(center+Vector2(-2.,-11.),Vector2(4.,23.)),EMBER if protected_now else OXIDE)
	var impact:=float(w.boss.clock)-float(w.boss.get("shield_contact",-5.))
	if protected_now and impact<.18:
		var side: float=w.boss.get("shield_side",-1.)
		var scatter:=8.+(floorf(impact*35.)*3. if moving else 0.)
		draw_sparks(view,center+Vector2(side*(24.+scatter),-4.))

static func draw_socket(view,point: Vector2,hp: int) -> void:
	view.draw_rect(Rect2(point-Vector2(10.,13.),Vector2(20.,26.)),VOID)
	view.draw_rect(Rect2(point-Vector2(13.,8.),Vector2(26.,16.)),VOID)
	view.draw_rect(Rect2(point-Vector2(9.,10.),Vector2(18.,20.)),COPPER)
	view.draw_rect(Rect2(point-Vector2(7.,8.),Vector2(14.,16.)),VOID)
	if hp>0:
		for row in 3:
			var vent:=point+Vector2(-5.,-6.+5.*row)
			view.draw_rect(Rect2(vent,Vector2(10.,3.)),EDGE if row<hp else OXIDE)
		view.draw_rect(Rect2(point-Vector2(9.,10.),Vector2(18.,2.)),EDGE)
	else:
		view.draw_rect(Rect2(point+Vector2(-7.,-10.),Vector2(6.,3.)),ASH)
		view.draw_rect(Rect2(point+Vector2(-2.,-7.),Vector2(5.,3.)),OXIDE)
		view.draw_rect(Rect2(point+Vector2(2.,-4.),Vector2(3.,6.)),OXIDE)
		view.draw_rect(Rect2(point+Vector2(1.,8.),Vector2(8.,2.)),ASH)

static func draw_core(view,point: Vector2,phase: int) -> void:
	var rim:=Color("8dd6bf") if phase==3 else EDGE
	var hot:=Color("ddf6c6") if phase==3 else LIGHT
	# The original painted lens remains visible between the open copper leaves.
	view.draw_rect(Rect2(point-Vector2(10.,16.),Vector2(20.,3.)),rim)
	view.draw_rect(Rect2(point+Vector2(-8.,14.),Vector2(16.,3.)),rim)
	for side in [-1.,1.]:
		view.draw_rect(Rect2(point+Vector2(side*19.-3.,-11.),Vector2(6.,22.)),VOID)
		view.draw_rect(Rect2(point+Vector2(side*16.-2.,-12.),Vector2(4.,23.)),COPPER)
		view.draw_rect(Rect2(point+Vector2(side*13.-1.,-13.),Vector2(2.,7.)),hot)
		view.draw_rect(Rect2(point+Vector2(side*12.-1.,9.),Vector2(2.,4.)),rim)
	if phase==3:view.draw_rect(Rect2(point+Vector2(-4.,-7.),Vector2(8.,14.)),Color("ddf6c660"))

static func draw_sparks(view,point: Vector2) -> void:
	view.draw_rect(Rect2(point+Vector2(-3.,-3.),Vector2(6.,6.)),LIGHT)
	view.draw_rect(Rect2(point+Vector2(6.,-9.),Vector2(4.,3.)),EDGE)
	view.draw_rect(Rect2(point+Vector2(-10.,-7.),Vector2(3.,3.)),EMBER)
	view.draw_rect(Rect2(point+Vector2(-6.,8.),Vector2(3.,4.)),EDGE)
	view.draw_rect(Rect2(point+Vector2(8.,4.),Vector2(4.,3.)),EMBER)

static func draw_floor(view) -> void:
	var w=view.world
	if w.section!="arena" or not bool(w.boss.active) or not bool(w.boss.engaged):return
	var warning:=float(w.boss.get("beam_warning",0.))
	var eruption:=float(w.boss.get("eruption",0.))
	if warning>0. or eruption>0.:draw_eruption(view,warning,eruption)
	var echo:=float(w.boss.get("echo_wait",0.))>0.
	var charge:=CampaignBossPressure.dash_warning(w)
	if not echo and not charge and not (float(w.boss.windup)>0. and int(w.boss.attack)%3==1):return
	var direction:=float(w.boss.get("echo_direction",-1.)) if echo else CampaignBossPressure.lane_direction(w)
	var start:=float(w.boss.x)+direction*CampaignBossPressure.WAVE_OFFSET
	var finish:=start+direction*CampaignBossPressure.WAVE_SPEED*CampaignBossPressure.WAVE_LIFE
	if charge:
		start=float(w.boss.x)-direction*CampaignBossPressure.DASH_RADIUS
		finish=CampaignBossPressure.dash_destination(w,direction)+direction*CampaignBossPressure.DASH_RADIUS
	draw_lane(view,start,finish,direction,charge,echo)

static func draw_lane(view,start: float,finish: float,direction: float,charge: bool,echo: bool) -> void:
	var left:=maxf(0.,maxf(minf(start,finish),view.camera_x))
	var right:=minf(view.world.length(),minf(maxf(start,finish),view.camera_x+view.scene_w))
	var step:=24 if charge else 28
	for i in range(ceili(left/step),floori(right/step)+1):
		var x:=float(i*step)
		var point: Vector2=view.at(Vector2(x,view.world.floor_at(x)-5.)).round()
		if charge:
			view.draw_rect(Rect2(point+Vector2(-8.,0.),Vector2(16.,5.)),Color("5d3435"))
			view.draw_rect(Rect2(point+Vector2(-5.*direction,-3.),Vector2(10.,3.)),EMBER)
			view.draw_rect(Rect2(point+Vector2(4.*direction,-1.),Vector2(4.,5.)),EDGE)
		else:
			var ink:=Color("a9d6e6") if echo else EDGE
			view.draw_rect(Rect2(point-Vector2(5.,3.),Vector2(10.,3.)),ink)
			if echo:view.draw_rect(Rect2(point+Vector2(-3.,2.),Vector2(6.,2.)),ink)

static func draw_eruption(view,warning: float,eruption: float) -> void:
	var x:=float(view.world.boss.beam_x)
	var radius:=CampaignBossPressure.ERUPTION_RADIUS
	if x+radius<view.camera_x or x-radius>view.camera_x+view.scene_w:return
	var progress:=1.-warning/CampaignBossPressure.ERUPTION_WARNING
	var moving:=motion_enabled(view)
	for i in range(-8,9):
		var root_x:=x+i*radius/8.
		var point: Vector2=view.at(Vector2(root_x,view.world.floor_at(root_x))).round()
		var edge:=absi(i)==8
		view.draw_rect(Rect2(point+Vector2(-5.,-5.),Vector2(11.,10.)),VOID)
		view.draw_rect(Rect2(point+Vector2(-5.,-7.),Vector2(11.,4.)),EDGE if edge or progress>=float(absi(i))/8. else EMBER)
		if edge:
			view.draw_rect(Rect2(point+Vector2(-3.,-22.),Vector2(6.,17.)),VOID)
			view.draw_rect(Rect2(point+Vector2(-1.,-19.),Vector2(3.,14.)),LIGHT)
		if eruption<=0. or edge or posmod(i,2)==1:continue
		var height:=CampaignBossPressure.ERUPTION_HEIGHT*(.87+float(posmod(i,3))*.065)
		if moving and eruption<.09:height*=.9
		var lean:=-1. if posmod(i,4)==0 else 1.
		view.draw_set_transform(point+Vector2(0.,1.),0.,Vector2(lean,roundf(height)))
		view.draw_colored_polygon(root_rind,VOID)
		view.draw_colored_polygon(root_fibre,EMBER)
		view.draw_rect(Rect2(1.,-.64,3.,.34),EDGE)
		view.draw_set_transform(Vector2.ZERO)
		if eruption>.12:draw_sparks(view,point+Vector2(lean*13.,-height*.83).round())

static func draw_lanterns(view) -> void:
	var w=view.world
	if w.section!="arena":return
	for i in LANTERNS.size():
		var x: float=LANTERNS[i]
		if x<view.camera_x-24. or x>view.camera_x+view.scene_w+24.:continue
		var base: Vector2=view.at(Vector2(x,w.floor_at(x))).round()
		var lit: bool=w.completed and (w.state=="complete" or w.victory_time>=CampaignBossPressure.LANTERN_BEATS[LANTERN_ORDER[i]])
		view.draw_rect(Rect2(base+Vector2(-10.,-5.),Vector2(20.,5.)),VOID)
		view.draw_rect(Rect2(base+Vector2(-4.,-50.),Vector2(8.,46.)),VOID)
		view.draw_rect(Rect2(base+Vector2(-2.,-48.),Vector2(3.,43.)),COPPER)
		var head:=base-Vector2(0.,53.)
		if lit:
			view.draw_rect(Rect2(head-Vector2(18.,17.),Vector2(36.,33.)),Color("e5a96322"))
			view.draw_rect(Rect2(head-Vector2(14.,20.),Vector2(28.,39.)),Color("e5a96322"))
		view.draw_rect(Rect2(head-Vector2(8.,12.),Vector2(16.,24.)),VOID)
		view.draw_rect(Rect2(head-Vector2(11.,10.),Vector2(22.,4.)),COPPER)
		view.draw_rect(Rect2(head+Vector2(-9.,8.),Vector2(18.,4.)),COPPER)
		view.draw_rect(Rect2(head-Vector2(6.,6.),Vector2(12.,14.)),LIGHT if lit else ASH)
		view.draw_rect(Rect2(head-Vector2(1.,6.),Vector2(2.,14.)),COPPER)
		if lit:view.draw_rect(Rect2(base+Vector2(-13.,-3.),Vector2(26.,3.)),Color("e5a96370"))
