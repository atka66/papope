extends Node2D

export(String) var option = ''
export(bool) var show_arrows = true

func _ready():
	$OptionLabel.set_text(option + ':')
	$SelectionLabel.set_text(str(Global.options[option][Global.optionsSelected[option]]))

func _process(delta):
	$SelectionLabel.set_text(str(Global.options[option][Global.optionsSelected[option]]))
	var isArrowsVisible = show_arrows and option.nocasecmp_to(Global.currentOption) == 0
	$LeftArrow.visible = ProjectSettings.get("papope/allow_players_set_options") && isArrowsVisible
	$RightArrow.visible = ProjectSettings.get("papope/allow_players_set_options") && isArrowsVisible
