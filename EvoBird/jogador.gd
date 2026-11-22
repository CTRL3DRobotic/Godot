
class_name Jogador
extends CharacterBody2D

signal morreu

# =====================================
# CONFIGURACOES
# =====================================

@export_group("Movimento")

@export var gravidade: float = 1500.0
@export var forca_pulo: float = -700.0
@export var forca_nave: float = -900.0

@export_group("Limites da Nave")

@export var limite_superior: float = 60.0
@export var limite_inferior: float = 520.0

@export_group("Animacoes")

@export var animacao_correr: StringName = &"correr"
@export var animacao_pular: StringName = &"pular"
@export var animacao_nave: StringName = &"nave"

# =====================================
# ESTADO DO PERSONAGEM
# =====================================

var modo_nave: bool = false
var vivo: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


# =====================================
# MOVIMENTO
# =====================================

func _physics_process(delta):

	if not vivo:
		return

	if modo_nave:
		controlar_nave(delta)
	else:
		controlar_corrida(delta)

	move_and_slide()

	if modo_nave:
		global_position.y = clampf(
			global_position.y,
			limite_superior,
			limite_inferior
		)

	atualizar_animacao()


# =====================================
# CORRIDA
# =====================================

func controlar_corrida(delta):

	velocity.x = 0
	velocity.y += gravidade * delta

	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = forca_pulo


# =====================================
# NAVE
# =====================================

func controlar_nave(delta):

	velocity.x = 0
	velocity.y += gravidade * delta

	if Input.is_action_pressed("pular"):
		velocity.y += forca_nave * delta

	velocity.y = clampf(velocity.y, -350.0, 350.0)


# =====================================
# ANIMACOES
# =====================================

func atualizar_animacao():

	var animacao: StringName = animacao_correr

	if modo_nave:
		animacao = animacao_nave

	elif not is_on_floor():
		animacao = animacao_pular

	if sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(animacao):
		return

	if sprite.animation != animacao or not sprite.is_playing():
		sprite.play(animacao)


# =====================================
# TRANSFORMAR EM NAVE
# =====================================

func transformar_em_nave():

	modo_nave = true
	velocity = Vector2.ZERO
	global_position.y = 320

	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


# =====================================
# MORTE
# =====================================

func morrer():

	if not vivo:
		return

	vivo = false
	velocity = Vector2.ZERO

	morreu.emit()
