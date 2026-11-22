
extends Node2D

# =====================================
# CONFIGURAÇÕES
# =====================================

@export var gravidade: float = 1100.0
@export var raio_corte: float = 35.0
@export var tempo_destruicao: float = 1.0
@export_group("Tipo de Alimento")
@export var perigosa: bool = false
# =====================================
# OBJETOS DA CENA
# =====================================

@onready var sprite_inteiro: Sprite2D = $SpriteInteiro
@onready var metade_esquerda: Sprite2D = $MetadeEsquerda
@onready var metade_direita: Sprite2D = $MetadeDireita

# =====================================
# VARIÁVEIS
# =====================================

var velocidade: Vector2 = Vector2.ZERO
var cortada: bool = false

var velocidade_esquerda: Vector2 = Vector2.ZERO
var velocidade_direita: Vector2 = Vector2.ZERO

var tempo_cortada: float = 0.0

# =====================================
# INICIALIZAÇÃO
# =====================================

func _ready() -> void:

	add_to_group("frutas")

	sprite_inteiro.show()

	metade_esquerda.hide()
	metade_direita.hide()

# =====================================
# MOVIMENTAÇÃO
# =====================================

func _process(delta: float) -> void:

	if not cortada:

		velocidade.y += gravidade * delta

		position += velocidade * delta

	else:

		tempo_cortada += delta

		velocidade_esquerda.y += gravidade * delta
		velocidade_direita.y += gravidade * delta

		metade_esquerda.position += (
			velocidade_esquerda * delta
		)

		metade_direita.position += (
			velocidade_direita * delta
		)

		if tempo_cortada >= tempo_destruicao:
			queue_free()
			return

	# Remover frutas fora da tela
	if not cortada:

		var altura: float = get_viewport_rect().size.y

		if position.y > altura + 120.0:
			queue_free()

# =====================================
# DETECTAR CORTE
# =====================================

func tentar_cortar(
	inicio: Vector2,
	fim: Vector2
) -> bool:

	if cortada:
		return false

	var segmento: Vector2 = fim - inicio

	var tamanho_quadrado: float = (
		segmento.length_squared()
	)

	if tamanho_quadrado < 0.001:
		return false

	var proporcao: float = clampf(
		(global_position - inicio).dot(segmento)
		/ tamanho_quadrado,
		0.0,
		1.0
	)

	var ponto_proximo: Vector2 = (
		inicio + segmento * proporcao
	)

	var distancia: float = (
		ponto_proximo.distance_to(global_position)
	)

	if distancia <= raio_corte:

		cortar()
		return true

	return false

# =====================================
# CORTAR FRUTA
# =====================================

func cortar() -> void:

	if cortada:
		return

	cortada = true
	tempo_cortada = 0.0

	# Esconder fruta inteira
	sprite_inteiro.hide()

	# Mostrar imagens das metades
	metade_esquerda.show()
	metade_direita.show()

	# Lançar metades para lados opostos
	velocidade_esquerda = (
		velocidade + Vector2(-170.0, -180.0)
	)

	velocidade_direita = (
		velocidade + Vector2(170.0, -180.0)
	)
