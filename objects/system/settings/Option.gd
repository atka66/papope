extends Node2D

func setOption(option: String):
	$OptionLabel.setText(option + ':')

func setSelection(selection: String):
	$SelectionLabel.setText(selection)

func setFocus(focus: bool):
	$LeftArrow.visible = focus && !ProjectSettings.get("papope/hosted_mode")
	$RightArrow.visible = focus && !ProjectSettings.get("papope/hosted_mode")

func animateArrow(isRight: bool):
	$Anim.stop()
	$Anim.play('right' if isRight else 'left')
