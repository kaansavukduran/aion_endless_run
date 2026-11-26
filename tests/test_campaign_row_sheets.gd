## Exact source and lazy-load contracts, not ordinary-input/browser evidence.
extends SceneTree
const Rows=preload("res://scripts/campaign_row_sheets.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func expected_pixels(sheet: Image,f: Dictionary) -> Image:
	var b: Array=f.bounds
	var result:=Image.create_empty(int(b[2]-b[0])+4,int(b[3]-b[1])+4,false,Image.FORMAT_RGBA8)
	for run in RunnerSourcePixels.runs(f):result.blit_rect(sheet,Rect2i(int(f.rect[0])+int(run[1]),int(f.rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])-int(b[0])+2,int(run[0])-int(b[1])+2))
	return result
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var catalogue:=CampaignCatalog.new();var effects:=CampaignEffectsArt.new()
	var banks: Dictionary={"keepers-walk":CampaignCatalog.KEEPERS_WALK.data,"legacy-deaths":CampaignEffectsArt.DATA.data.banks["legacy-deaths"]}
	check(Rows.DATA.data.groups.keys().size()==2,"Only the two measured decode hotspots use row strips")
	for key in banks:
		var atlas: Dictionary=banks[key];var source: Image=RunnerSourcePixels.image("res://"+str(atlas.path));source.convert(Image.FORMAT_RGBA8)
		var group: Dictionary=Rows.DATA.data.groups[key]
		check(FileAccess.get_sha256("res://"+str(atlas.path))==str(group.source_sha256),"Original approved source is preserved byte for byte: "+key)
		check(group.rows.size()==atlas.frames.size(),"Every original source row has exactly one strip: "+key)
		for row in atlas.frames.size():
			var strip: Dictionary=Rows.entry(key,row)
			check(FileAccess.get_sha256("res://"+str(strip.path))==str(strip.sha256),"The actual lazy strip matches its recorded source hash")
			var pixels: Image=RunnerSourcePixels.image("res://"+str(strip.path));pixels.convert(Image.FORMAT_RGBA8)
			var c: Array=strip.source_crop
			check(pixels.get_data()==source.get_region(Rect2i(int(c[0]),int(c[1]),int(c[2]),int(c[3]))).get_data(),"Every unscaled RGBA byte in this source row is unchanged")
			check(pixels.get_width()==int(c[2]) and pixels.get_height()==int(c[3]) and pixels.get_data_size()<=source.get_data_size()/7.,"A requested row decodes a small strip instead of the full 8/9-row source")
			for frame in atlas.frames[row].size():
				var f: Dictionary=atlas.frames[row][frame]
				var actual: Dictionary=catalogue.pose("rescue-npcs",row,frame+6) if key=="keepers-walk" else effects.death(CampaignEffectsArt.LEGACY[row],frame)
				check(actual.texture.get_image().get_data()==expected_pixels(source,f).get_data(),"Actual bank output preserves every registered masked RGBA pixel, including gutters")
				var b: Array=f.bounds;var scale: float=atlas.scales[row]
				check(Vector2(actual.offset).is_equal_approx(Vector2(float(b[0])-float(f.origin[0])-2.,float(b[1])-float(f.origin[1])-2.)*scale),"Runtime actor offset and original anatomical scale are unchanged")
	# A first NPC requests one lazy row only. Clear test-process caches, not any
	# persisted game state, to observe actual resource selection independently.
	CampaignCatalog.cache.clear();CampaignEffectsArt.cache.clear();RunnerSourcePixels.sheets.clear();RunnerSourcePixels.recent.clear()
	RunnerSourcePixels.section_paths.clear();RunnerSourcePixels.current_section=""
	var before:=RunnerSourcePixels.decodes;catalogue.pose("rescue-npcs",3,6)
	check(RunnerSourcePixels.decodes==before+1 and RunnerSourcePixels.sheets.size()==1 and RunnerSourcePixels.sheets.has("res://"+str(Rows.entry("keepers-walk",3).path)),"First NPC walk loads exactly its requested row and no other slabs")
	before=RunnerSourcePixels.decodes;catalogue.pose("rescue-npcs",3,7)
	check(RunnerSourcePixels.decodes==before,"Another cel in that walk reuses its resident source row")
	before=RunnerSourcePixels.decodes;effects.death("gnome",0)
	check(RunnerSourcePixels.decodes==before+1 and RunnerSourcePixels.sheets.has("res://"+str(Rows.entry("legacy-deaths",1).path)),"First enemy defeat loads exactly its own original death row")
	check(not RunnerSourcePixels.sheets.has("res://assets/keepers-walk.png") and not RunnerSourcePixels.sheets.has("res://assets/legacy-deaths.png"),"The targeted runtime banks never decode the retired full sheets")
	print("RESULT: %d exact campaign row-strip checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
