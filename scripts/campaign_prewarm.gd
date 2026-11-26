class_name CampaignPrewarm
extends RefCounted
## Runs inside load_section, behind the travel fade. Cuts the frames a section
## is about to need for the first time (first kill of each enemy kind, the
## hero's knife and rescue cut, captives and their walk-away, the fork tunnel
## crawl) so those moments do not decode a whole source sheet mid-play.
## Cut frames live in each bank's process-wide cache, so this is paid once per
## session; frames already cut cost a dictionary lookup.
static var effects: CampaignEffectsArt
static var catalogue: CampaignCatalog

static func section(w) -> void:
	if effects==null:effects=CampaignEffectsArt.new();catalogue=CampaignCatalog.new()
	var kinds:={}
	for e in w.enemies:
		if not bool(e.mini) and str(e.kind) in CampaignEffectsArt.LEGACY:kinds[str(e.kind)]=true
	for kind in kinds:
		for frame in 6:effects.death(kind,frame)
	var variants:={}
	for npc in w.npcs:variants[int(npc.get("variant",0))]=true
	for variant in variants:
		for frame in 12:catalogue.pose("rescue-npcs",variant,frame)
	var actions: Array=M1HeroActionArt.CONTACT_ACTIONS.duplicate()
	if str(w.section)=="fork_one":actions.append_array(M1HeroActionArt.TUNNEL_ACTIONS)
	for action in actions:
		if not M1HeroActionArt.supports(str(w.character),action):continue
		for frame in int(M1HeroActionArt.clip_spec(str(w.character),action).frames):M1HeroActionArt.pose(str(w.character),action,frame)
