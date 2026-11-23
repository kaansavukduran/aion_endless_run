class_name CampaignAssistArt
extends RefCounted

const DATA := preload("res://assets/MISSION1-ASSIST-ART.json")
const SHEET := preload("res://assets/mission1-assists.png")
static var frames: Dictionary={}

static func pose(assist: Dictionary, animated: bool) -> Dictionary:
	var row:=4
	var frame:=0
	var phase: String=assist.phase
	if assist.kind=="owl":
		row=1 if phase=="drop" else 0
		frame=clampi(int(float(assist.phase_age)/CampaignAssists.DROP_POSE*6.),0,5) if row==1 else posmod(int(float(assist.age)*13.),6)
	elif phase in ["bite","bite_recover"]:
		row=3
		frame=clampi(int(float(assist.phase_age)/CampaignAssists.BITE_DURATION*6.),0,5)
	elif phase in ["run","depart"]:
		row=2
		frame=posmod(int(float(assist.get("stride",0.))/10.5),6)
	else:
		frame=posmod(int(float(assist.age)*4.),6)
	if not animated:frame=2 if row in [1,3] else 0
	var key:=Vector2i(frame,row)
	if not frames.has(key):
		var cell: Array=DATA.data.cell
		var size:=Vector2(float(cell[0]),float(cell[1]))
		var origin: Array=DATA.data.anchors[row][frame]
		var scale: float=DATA.data.scale[row]
		var texture:=AtlasTexture.new()
		texture.atlas=SHEET
		texture.region=Rect2(Vector2(key)*size,size)
		texture.filter_clip=true
		frames[key]={"texture":texture,"offset":-Vector2(float(origin[0]),float(origin[1]))*scale,
			"size":size*scale,"source_row":row,"source_frame":frame}
	return frames[key]
