
extends Node2D

# Cena do inimigo que cai
@export var cena_inimigo: PackedScene

# Marcador indicando a altura do chao
@export var chao: Marker2D

# Intervalo aleatorio entre surgimentos
@export var tempo_minimo: float = 1.5
@export var tempo_maximo: float = 3.0

# Quantidade maxima de inimigos na fase
@export var max_inimigos: int = 10

var inimigos: Array[Node2D] = []


func _ready() -> void:
	gerar_inimigo()
	iniciar_geracao()


func iniciar_geracao() -> void:
	while is_inside_tree():
		var intervalo = randf_range(
			tempo_minimo,
			tempo_maximo
		)

		await get_tree().create_timer(
			intervalo
		).timeout

		if not is_inside_tree():
			return

		gerar_inimigo()


func gerar_inimigo() -> void:
	if cena_inimigo == null or chao == null:
		return

	# Limpa referencias de inimigos removidos
	for i in range(inimigos.size() - 1, -1, -1):
		if not is_instance_valid(inimigos[i]):
			inimigos.remove_at(i)

	# Remove o inimigo mais antigo se atingir o limite
	if inimigos.size() >= max_inimigos:
		var antigo = inimigos.pop_front()

		if is_instance_valid(antigo):
			antigo.queue_free()

	# Cria um novo inimigo
	var inimigo = cena_inimigo.instantiate() as Node2D

	if inimigo == null:
		return

	# Define o chao antes de iniciar o inimigo
	inimigo.set("chao", chao)

	# Adiciona na fase
	add_child(inimigo)

	# Guarda o inimigo criado
	inimigos.append(inimigo)
