
extends Area2D

@export var posicoes: Array[Marker2D] = []

var pode_dar_dano: bool = false
var tempo: float = 0.0
var indice_atual: int = -1

const TEMPO_MUDANCA: float = 10.0
const TEMPO_SEM_DANO: float = 2.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_ao_encostar)
	mudar_posicao()


func _physics_process(delta: float) -> void:
	tempo += delta

	if tempo >= TEMPO_MUDANCA:
		mudar_posicao()
		return

	if not pode_dar_dano and tempo >= TEMPO_SEM_DANO:
		pode_dar_dano = true
		sprite.modulate.a = 1.0

		# Verifica se o jogador ja esta encostando
		for corpo in get_overlapping_bodies():
			causar_dano(corpo)


func mudar_posicao() -> void:
	tempo = 0.0
	pode_dar_dano = false
	sprite.modulate.a = 0.4

	if posicoes.is_empty():
		return

	var novo_indice: int = randi_range(0, posicoes.size() - 1)

	if posicoes.size() > 1:
		while novo_indice == indice_atual:
			novo_indice = randi_range(0, posicoes.size() - 1)

	indice_atual = novo_indice
	global_position = posicoes[novo_indice].global_position


func _ao_encostar(corpo: Node2D) -> void:
	causar_dano(corpo)


func causar_dano(corpo: Node2D) -> void:
	if not pode_dar_dano:
		return

	if corpo.is_in_group("jogador"):
		if corpo.has_method("receber_dano"):
			corpo.receber_dano(1)
