class_name CampaignRowSheets
extends RefCounted

## Tiny registration only. Each source strip remains lazy and uses the same
## bounded decoded-sheet cache; this never preloads another image at startup.
const DATA=preload("res://assets/CAMPAIGN-ROW-SHEETS.json")

static func entry(group: String,row: int) -> Dictionary:
	assert(DATA.data.groups.has(group),"Unregistered row-strip group: "+group)
	var rows: Array=DATA.data.groups[group].rows
	assert(row>=0 and row<rows.size(),"Unregistered row-strip index: "+str(row))
	return rows[row]
