extends Node2D

func setAchievent(achievement):
	$NameLabel.set_text(achievement[0])
	$DescriptionLabel.set_text(achievement[1])
