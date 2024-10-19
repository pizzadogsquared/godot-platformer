extends Area2D

@onready var game_manager: Node = $/root/Game/GameManager
@onready var timer: Timer = $Timer

func _on_body_entered(body: CharacterBody2D) -> void:
	print("You died!")
	Engine.time_scale = 0.5
	get_node("CollisionShape2D").queue_free()
	game_manager.game_over()
	timer.start()


func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
