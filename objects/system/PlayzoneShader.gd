tool
extends Node2D

export(Shader) var shader

func _ready():
	$ShaderRect.material.shader = shader
