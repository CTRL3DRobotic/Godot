
extends Button

func _pressed():
	EstadoJogo.iniciar_novo_jogo()
	get_tree().change_scene_to_file("res://fase_1.tscn")
