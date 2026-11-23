class_name MissionFrogTongueArt
extends RefCounted

## Presentation only: the existing World owns skill clocks, reach and physics.
## Locomotion remains driven by actual travel/flight while the jaw is open.
static func motion_spec(w,phase: String,face: int) -> Dictionary:
	if w.character!="frog":return {}
	var open: bool=phase in ["extend","retract"]
	if not w.grounded():
		return {"action":"tongue_air" if open else "air_fire","frame":RunnerWorld.flight_frame_for(w.velocity.y,w.air_time,6)}
	if absf(w.velocity.x)<=1.:return {}
	var low: bool=w.crouching()
	var backward: bool=w.velocity.x*float(face)<-1.
	var gait: String=("crouch_walk_back" if backward else "crouch_walk") if low else ("walk_back" if backward else "walk")
	return {"action":"tongue_"+gait if open else gait,"frame":posmod(int(w.walk_distance/(110. if low else 174.)*6.),6)}
