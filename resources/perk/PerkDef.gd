class_name PerkDef
extends Resource
## One perk's display data. Replaces the old [name, description, frame] arrays
## that were indexed with magic numbers ([0], [1], [2]) across the UI.

@export var id: int = 0
@export var display_name: String = ""
@export var description: String = ""
## Frame index in sprites/perk/perks.png (0 is the blank/empty pip).
@export var frame: int = 0

static func make(new_id: int, new_name: String, new_desc: String, new_frame: int) -> PerkDef:
	var perk := PerkDef.new()
	perk.id = new_id
	perk.display_name = new_name
	perk.description = new_desc
	perk.frame = new_frame
	return perk
