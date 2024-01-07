extends Node2D

func setOption(option: String):
	$OptionLabel.setText(option + ':')

func setSelection(selection: String):
	$SelectionLabel.setText(selection)

func setFocus(focus: bool):
	$LeftArrow.visible = focus
	$RightArrow.visible = focus

func animateArrow(isRight: bool):
	$Anim.stop()
	$Anim.play('right' if isRight else 'left')
