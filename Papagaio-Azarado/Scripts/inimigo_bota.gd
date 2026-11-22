
extends Area2D

# CONFIGURACOES
@export var chao: Marker2D
@export var tempo_piscando: float = 2.0
@export var tempo_queda: float = 3.0
@export var margem_lateral: float = 30.0
@export var margem_topo: float = 20.0
@export var altura_inimigo: float = 16.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var colisao: CollisionShape2D = $CollisionShape2D

var material_flash: ShaderMaterial


func _ready() -> void:
	# Impede dano durante o aviso
	colisao.set_deferred("disabled", true)

	body_entered.connect(_ao_encostar)

	# Cria o efeito de ficar branco
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

	iniciar()


func iniciar() -> void:
	if chao == null:
		push_error("Configure o Marker2D Chao!")
		return

	# Escolhe um lugar aleatorio no topo da tela
	var tamanho = get_viewport().get_visible_rect().size

	var x_aleatorio = randf_range(
		margem_lateral,
		tamanho.x - margem_lateral
	)

	var posicao_tela = Vector2(
		x_aleatorio,
		margem_topo
	)

	global_position = (
		get_canvas_transform().affine_inverse()
		* posicao_tela
	)

	# Pisca durante os primeiros 2 segundos
	await piscar()

	# Ativa a colisao quando comeca a cair
	colisao.set_deferred("disabled", false)

	# Calcula onde o inimigo vai parar
	var destino = Vector2(
		global_position.x,
		chao.global_position.y - altura_inimigo
	)

	# Faz a queda durar exatamente 3 segundos
	var tween = create_tween()

	tween.tween_property(
		self,
		"global_position",
		destino,
		tempo_queda
	).set_trans(Tween.TRANS_LINEAR)

	await tween.finished

	print("Inimigo chegou ao chao!")


func piscar() -> void:
	var intervalo: float = 0.1
	var repeticoes: int = int(
		tempo_piscando / (intervalo * 2.0)
	)

	for i in range(repeticoes):
		# Fica branco
		material_flash.set_shader_parameter(
			"flash", 1.0
		)

		await get_tree().create_timer(
			intervalo
		).timeout

		# Volta para a cor original
		material_flash.set_shader_parameter(
			"flash", 0.0
		)

		await get_tree().create_timer(
			intervalo
		).timeout

	# Garante a cor original
	material_flash.set_shader_parameter(
		"flash", 0.0
	)


func _ao_encostar(corpo: Node2D) -> void:
	if corpo.is_in_group("jogador"):
		if corpo.has_method("receber_dano"):
			corpo.receber_dano(1)
