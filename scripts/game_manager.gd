extends Node
@onready var player: CharacterBody2D = $"../Player1"

func game_over():
	player.motion = Vector2.ZERO
	player.velocity = Vector2.ZERO
	player.is_killed = true
	
