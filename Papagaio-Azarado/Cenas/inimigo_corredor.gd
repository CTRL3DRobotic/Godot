extends Area2D

# =====================================
# CONFIGURACOES
# =====================================

@export var chao: Marker2D

@export var tempo_piscando: float = 2.0
@export var tempo_corrida: float = 2.0
@export var tempo_reaparecer: float = 7.0

@export var intervalo_pisca: float = 0.125
@export var margem_direita: float = 5.0

@export var dano: int = 1

# =====================================
# VARIAVEIS
# =====================================

@onready var sprite: Sprite2D = $Sprite2D

var material_flash: ShaderMaterial
var pode_dar_dano: bool = false
var destino_x: float = 0.0


# =====================================
# INICIO
# =====================================

func _ready() -> void:

	if chao == null:
		push_error("Configure o Marker2D Chao!")
		return

	body_entered.connect(_ao_encostar)

	criar_shader()

	iniciar_ciclo()


# =====================================
# EFEITO DE PISCAR BRANCO
# =====================================

func criar_shader() -> void:

	var shader = Shader.new()

	shader.code = """
shader_type canvas_item;

uniform float flash = 0.0;

void fragment() {
	vec4 cor = COLOR;
	cor.rgb = mix(cor.rgb, vec3(1.0), flash);
	COLOR = cor;
}
"""

	material_flash = ShaderMaterial.new()
	material_flash.shader = shader

	sprite.material = material_flash


# =====================================
# POSICIONAMENTO
# =====================================

func posicionar_na_direita() -> void:

	var largura_tela = get_viewport_rect().size.x

	# Considera o tamanho real do sprite na tela
	var escala_tela = abs(
		get_canvas_transform().get_scale().x
	)

	var metade_largura = (
		sprite.get_rect().size.x
		* abs(sprite.global_scale.x)
		* escala_tela
	) / 2.0

	var metade_altura = (
		sprite.get_rect().size.y
		* abs(sprite.global_scale.y)
	) / 2.0

	var transformar = (
		get_canvas_transform().affine_inverse()
	)

	# Comeca totalmente visivel na direita
	var inicio = transformar * Vector2(
		largura_tela - metade_largura - margem_direita,
		0
	)

	# Termina completamente fora da esquerda
	var fim = transformar * Vector2(
		-metade_largura - 2.0,
		0
	)

	global_position = Vector2(
		inicio.x,
		chao.global_position.y - metade_altura
	)

	destino_x = fim.x


# =====================================
# CICLO DO INIMIGO
# =====================================

func iniciar_ciclo() -> void:

	while is_inside_tree():

		# 1 - Aparece na direita
		posicionar_na_direita()

		visible = true
		pode_dar_dano = false

		# 2 - Pisca parado
		await piscar()

		# 3 - Comeca a correr
		pode_dar_dano = true


		# Verifica se o jogador ja esta encostando
		for corpo in get_overlapping_bodies():
			_ao_encostar(corpo)

		var tween = create_tween()

		tween.tween_property(
			self,
			"global_position",
			Vector2(
				destino_x,
				global_position.y
			),
			tempo_corrida
		).set_trans(Tween.TRANS_LINEAR)

		await tween.finished

		# 4 - Chegou ao final da tela
		pode_dar_dano = false
		visible = false

		# 5 - Espera para reaparecer
		await get_tree().create_timer(
			tempo_reaparecer
		).timeout


# =====================================
# PISCAR
# =====================================

func piscar() -> void:

	var restante = maxf(tempo_piscando, 0.0)
	var branco = true

	while restante > 0.0:

		if branco:
			material_flash.set_shader_parameter(
				"flash", 1.0
			)
		else:
			material_flash.set_shader_parameter(
				"flash", 0.0
			)

		branco = not branco

		var pausa = minf(
			maxf(intervalo_pisca, 0.02),
			restante
		)

		await get_tree().create_timer(
			pausa
		).timeout

		restante -= pausa

	# Volta para a cor original
	material_flash.set_shader_parameter(
		"flash", 0.0
	)


# =====================================
# DANO NO JOGADOR
# =====================================

func _ao_encostar(corpo: Node2D) -> void:

	if not pode_dar_dano:
		return

	if corpo.is_in_group("jogador"):

		if corpo.has_method("receber_dano"):
			corpo.receber_dano(dano)
