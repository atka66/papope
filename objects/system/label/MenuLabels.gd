extends CanvasLayer

func _ready():
	$VersionLabel.set_text('V' + Global.VERSION)
