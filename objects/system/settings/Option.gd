extends Node2D

signal focused
signal cycled(delta: int)

func setOption(option: String):
	$OptionLabel.setText(option + ':')

func setSelection(selection: String):
	$SelectionLabel.setText(selection)

func setFocus(focus: bool):
	$LeftArrow.visible = focus
	$RightArrow.visible = focus
	$LeftTarget.visible = focus
	$RightTarget.visible = focus

func animateArrow(isRight: bool):
	$Anim.stop()
	$Anim.play('right' if isRight else 'left')

func _on_row_target_tapped():
	focused.emit()

func _on_left_target_tapped():
	focused.emit()
	cycled.emit(-1)

func _on_right_target_tapped():
	focused.emit()
	cycled.emit(1)
