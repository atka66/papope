extends HBoxContainer

export (String) var ip = "unknown"
export (String) var servername = "unknown"
export (String) var version = "unknown"

# Called when the node enters the scene tree for the first time.
func _ready():
	$IpLabel.text = ip
	$NameLabel.text = servername
	$VersionLabel.text = version


func _on_JoinButton_pressed():
	get_tree().change_scene(Res.LobbyPath)
