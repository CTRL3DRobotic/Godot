
extends Node2D

# =====================================
# CONFIGURAÇÕES
# =====================================

const PORTA: int = 10050

const TEMPO_LIMITE: float = 0.5
const MAX_PONTOS_TRILHA: int = 12

const MOVIMENTO_MINIMO: float = 20.0
const MOVIMENTO_MAXIMO: float = 180.0

const MAX_FRUTAS: int = 12

# =====================================
# CONFIGURAÇÕES NO INSPECTOR
# =====================================

@export_group("Frutas")
@export var cenas_frutas: Array[PackedScene] = []

@export_group("Indicadores das Maos")

@export var textura_mao_1: Texture2D
@export var textura_mao_2: Texture2D

@export var escala_indicador_mao: Vector2 = Vector2(0.2, 0.2)
@export_group("Jogador")
@export var vidas_iniciais: int = 3

@export_group("Comidas Perigosas")
@export var cenas_perigosas: Array[PackedScene] = []
@export_range(0.0, 1.0, 0.05) var chance_perigosa: float = 0.25
@onready var texto_vidas: Label = $Interface/LabelVidas
@export_group("Controle por Webcam")
@export var tempo_ativacao_botao: float = 1.5

@onready var botao_jogar: Button = $Interface/MenuInicial/BotaoJogar
@onready var botao_reiniciar: Button = $Interface/MenuGameOver/BotaoReiniciar

var botao_em_foco: Button = null
var tempo_sobre_botao: float = 0.0
var vidas: int = 3

@export var mostrar_trilhas: bool = true

# =====================================
# NÓS DA CENA
# =====================================

@onready var texto_pontos: Label = $Interface/LabelPontos
@onready var temporizador: Timer = $TimerFrutas
@onready var container_frutas: Node2D = $Frutas

@onready var menu_inicial: Control = $Interface/MenuInicial
@onready var menu_game_over: Control = $Interface/MenuGameOver

@onready var container_indicadores: Node2D = $IndicadoresMaos

# =====================================
# VARIÁVEIS
# =====================================

var udp: PacketPeerUDP = PacketPeerUDP.new()

var maos: Dictionary = {}
var trilhas: Dictionary = {}

var indicadores_maos: Dictionary = {}

var ultimo_pacote: float = -1.0

var pontos: int = 0
var jogo_ativo: bool = false

# Mouse para testes
var mouse_cortando: bool = false
var posicao_mouse_anterior: Vector2 = Vector2.ZERO

# =====================================
# INICIALIZAÇÃO
# =====================================

func _ready() -> void:
 
	randomize()

	var erro: Error = udp.bind(
		PORTA,
		"127.0.0.1"
	)

	if erro == OK:
		print("Godot conectado na porta ", PORTA)
	else:
		push_error("Erro ao iniciar UDP!")

	temporizador.timeout.connect(criar_fruta)
	temporizador.stop()

	menu_inicial.show()
	menu_game_over.hide()

	atualizar_pontos()
	vidas = vidas_iniciais
	atualizar_vidas()

# =====================================
# CONTROLE DO JOGO
# =====================================

func iniciar_jogo() -> void:

	pontos = 0
	vidas = vidas_iniciais
	jogo_ativo = true

	atualizar_pontos()
	atualizar_vidas()

	menu_inicial.hide()
	menu_game_over.hide()

	for fruta in get_tree().get_nodes_in_group("frutas"):
		if is_instance_valid(fruta):
			fruta.queue_free()

	# Limpar trilhas antigas, mas manter
	# as posições das mãos da webcam.
	trilhas.clear()

	temporizador.start()
	
func atualizar_vidas() -> void:
	texto_vidas.text = "VIDAS: " + str(vidas)
	
func finalizar_jogo() -> void:

	jogo_ativo = false

	temporizador.stop()

	menu_game_over.show()

# =====================================
# GERAR FRUTAS
# =====================================


func criar_fruta() -> void:

	if not jogo_ativo:
		return

	if not is_instance_valid(container_frutas):
		return

	if container_frutas.is_queued_for_deletion():
		return

	var quantidade: int = 0

	for item in get_tree().get_nodes_in_group("frutas"):
		if is_instance_valid(item) and not item.is_queued_for_deletion():
			quantidade += 1

	if quantidade >= MAX_FRUTAS:
		return

	var cena_escolhida: PackedScene = null

	# Sortear comida perigosa
	var gerar_perigosa: bool = (
		not cenas_perigosas.is_empty()
		and randf() < chance_perigosa
	)

	if gerar_perigosa:
		cena_escolhida = cenas_perigosas.pick_random()
	elif not cenas_frutas.is_empty():
		cena_escolhida = cenas_frutas.pick_random()
	elif not cenas_perigosas.is_empty():
		cena_escolhida = cenas_perigosas.pick_random()

	if cena_escolhida == null:
		return

	var fruta: Node2D = cena_escolhida.instantiate() as Node2D

	if fruta == null:
		return

	container_frutas.add_child(fruta)

	var tamanho: Vector2 = get_viewport_rect().size
	var margem: float = minf(80.0, tamanho.x * 0.2)

	fruta.global_position = Vector2(
		randf_range(margem, tamanho.x - margem),
		tamanho.y + 50.0
	)

	fruta.set(
		"velocidade",
		Vector2(
			randf_range(-130.0, 130.0),
			randf_range(-1050.0, -850.0)
		)
	)

# =====================================
# RECEBER DADOS DO PYTHON
# =====================================

func _process(delta: float) -> void:
	while udp.get_available_packet_count() > 0:

		var pacote: PackedByteArray = udp.get_packet()
		var texto: String = pacote.get_string_from_utf8()

		var dados: Variant = JSON.parse_string(texto)

		if typeof(dados) != TYPE_DICTIONARY:
			continue

		if not dados.has("hands"):
			continue

		if typeof(dados["hands"]) != TYPE_ARRAY:
			continue

		ultimo_pacote = Time.get_ticks_msec() / 1000.0

		var novas_maos: Dictionary = {}

		for mao in dados["hands"]:

			if typeof(mao) != TYPE_DICTIONARY:
				continue

			var id: int = int(mao.get("id", 0))

			var x: float = clampf(
				float(mao.get("x", 0.0)),
				0.0,
				1.0
			)

			var y: float = clampf(
				float(mao.get("y", 0.0)),
				0.0,
				1.0
			)

			var tamanho: Vector2 = get_viewport_rect().size

			var posicao: Vector2 = Vector2(
				x * tamanho.x,
				y * tamanho.y
			)

			novas_maos[id] = posicao

			# Registrar movimento da mão
			if maos.has(id):

				var anterior: Vector2 = maos[id]

				if jogo_ativo:
					registrar_movimento(
						id,
						anterior,
						posicao
					)

			else:
				trilhas[id] = []

		# Remover trilhas de mãos desaparecidas
		for id in maos.keys():

			if not novas_maos.has(id):
				trilhas.erase(id)

		maos = novas_maos

	# =====================================
	# VERIFICAR CONEXÃO COM PYTHON
	# =====================================

	var agora: float = Time.get_ticks_msec() / 1000.0

	if ultimo_pacote < 0.0 or \
		agora - ultimo_pacote > TEMPO_LIMITE:

		maos.clear()
		trilhas.clear()

	# IMPORTANTE:
	# Atualizar indicadores em todos os frames
	atualizar_indicadores()
	verificar_botoes_com_maos(delta)
	queue_redraw()

# =====================================
# REGISTRAR MOVIMENTO
# =====================================

func registrar_movimento(
	id: int,
	anterior: Vector2,
	atual: Vector2
) -> void:

	var distancia: float = anterior.distance_to(atual)

	if not trilhas.has(id):
		trilhas[id] = []

	var lista: Array = trilhas[id]

	if lista.is_empty():
		lista.append(anterior)

	if distancia >= 4.0:

		lista.append(atual)

		while lista.size() > MAX_PONTOS_TRILHA:
			lista.pop_front()

	trilhas[id] = lista

	if distancia < MOVIMENTO_MINIMO:
		return

	if distancia > MOVIMENTO_MAXIMO:
		return

	verificar_cortes(anterior, atual)

# =====================================
# VERIFICAR CORTES
# =====================================


func verificar_cortes(
	inicio: Vector2,
	fim: Vector2
) -> void:

	if not jogo_ativo:
		return

	for fruta in get_tree().get_nodes_in_group("frutas"):

		if not is_instance_valid(fruta):
			continue

		if fruta.is_queued_for_deletion():
			continue

		if not fruta.has_method("tentar_cortar"):
			continue

		var acertou: bool = (
			fruta.call("tentar_cortar", inicio, fim) == true
		)

		if not acertou:
			continue

		if fruta.get("perigosa") == true:

			vidas = maxi(vidas - 1, 0)
			atualizar_vidas()

			print("Comida perigosa! Vidas: ", vidas)

			if vidas <= 0:
				finalizar_jogo()
				return

		else:

			pontos += 10
			atualizar_pontos()

			print("Fruta cortada! Pontos: ", pontos)


# =====================================
# ATUALIZAR PONTOS
# =====================================

func atualizar_pontos() -> void:

	texto_pontos.text = "PONTOS: " + str(pontos)

# =====================================
# CRIAR INDICADORES DAS MÃOS
# =====================================

func obter_ou_criar_indicador(id: int) -> Sprite2D:

	# Verificar se já existe
	if indicadores_maos.has(id):

		var existente: Sprite2D = indicadores_maos[id]

		if is_instance_valid(existente):
			if not existente.is_queued_for_deletion():
				return existente

		indicadores_maos.erase(id)

	# Criar indicador
	var indicador: Sprite2D = Sprite2D.new()

	indicador.centered = true
	indicador.scale = escala_indicador_mao

	# Selecionar imagem conforme o ID da mão
	if id == 1:

		indicador.texture = textura_mao_1

	else:

		indicador.texture = textura_mao_2

	# Adicionar ao container
	container_indicadores.add_child(indicador)

	# Guardar referência
	indicadores_maos[id] = indicador

	return indicador

# =====================================
# ATUALIZAR POSIÇÕES DOS INDICADORES
# =====================================

func atualizar_indicadores() -> void:

	if not is_instance_valid(container_indicadores):
		return

	if container_indicadores.is_queued_for_deletion():
		return

	# Atualizar mãos presentes
	for id in maos.keys():

		var indicador: Sprite2D = obter_ou_criar_indicador(id)

		if is_instance_valid(indicador):

			indicador.global_position = maos[id]

			indicador.visible = true

	# Remover indicadores de mãos ausentes
	for id in indicadores_maos.keys():

		if not maos.has(id):

			var indicador: Sprite2D = indicadores_maos[id]

			if is_instance_valid(indicador):
				if not indicador.is_queued_for_deletion():
					indicador.queue_free()

			indicadores_maos.erase(id)

# =====================================
# LIMPAR INDICADORES
# =====================================

func limpar_indicadores() -> void:

	for id in indicadores_maos.keys():

		var indicador: Sprite2D = indicadores_maos[id]

		if is_instance_valid(indicador):
			if not indicador.is_queued_for_deletion():
				indicador.queue_free()

	indicadores_maos.clear()

# =====================================
# DESENHAR TRILHAS
# =====================================

func _draw() -> void:

	if not mostrar_trilhas:
		return

	if not jogo_ativo:
		return

	for id in maos.keys():

		var cor: Color = Color.GREEN

		if id == 1:
			cor = Color.CYAN

		if trilhas.has(id):

			var lista: Array = trilhas[id]

			for i in range(1, lista.size()):

				var transparencia: float = (
					float(i) / float(lista.size())
				)

				var cor_linha: Color = cor

				cor_linha.a = transparencia

				draw_line(
					lista[i - 1],
					lista[i],
					cor_linha,
					7.0,
					true
				)

# =====================================
# TESTE COM MOUSE
# =====================================

func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:

			mouse_cortando = event.pressed

			posicao_mouse_anterior = event.position

	if event is InputEventMouseMotion:

		if mouse_cortando and jogo_ativo:

			var atual: Vector2 = event.position

			var distancia: float = (
				posicao_mouse_anterior.distance_to(atual)
			)

			if distancia >= MOVIMENTO_MINIMO and \
				distancia <= MOVIMENTO_MAXIMO:

				verificar_cortes(
					posicao_mouse_anterior,
					atual
				)

			posicao_mouse_anterior = atual

# =====================================
# BOTÕES DOS MENUS
# =====================================

func _on_botao_jogar_pressed() -> void:
	iniciar_jogo()

func _on_botao_game_over_pressed() -> void:
	iniciar_jogo()

func _on_botao_quit_game_pressed() -> void:
	get_tree().quit()

# =====================================
# FINALIZAR
# =====================================

func _exit_tree() -> void:

	udp.close()
func verificar_botoes_com_maos(delta: float) -> void:

	var botao_atual: Button = null

	if menu_inicial.visible:
		botao_atual = botao_jogar

	elif menu_game_over.visible:
		botao_atual = botao_reiniciar

	if botao_atual == null:
		botao_em_foco = null
		tempo_sobre_botao = 0.0
		return

	var mao_sobre_botao: bool = false

	for id in maos.keys():

		var posicao_mao: Vector2 = maos[id]

		var area_botao: Rect2 = botao_atual.get_global_rect()

		if area_botao.has_point(posicao_mao):
			mao_sobre_botao = true
			break

	if not mao_sobre_botao:
		botao_em_foco = null
		tempo_sobre_botao = 0.0
		botao_atual.modulate = Color.WHITE
		return

	if botao_em_foco != botao_atual:
		botao_em_foco = botao_atual
		tempo_sobre_botao = 0.0

	tempo_sobre_botao += delta

	# Indicação visual de progresso
	var progresso: float = clampf(
		tempo_sobre_botao / tempo_ativacao_botao,
		0.0,
		1.0
	)

	botao_atual.modulate = Color.WHITE.lerp(
		Color.GREEN,
		progresso
	)

	if tempo_sobre_botao >= tempo_ativacao_botao:

		botao_em_foco = null
		tempo_sobre_botao = 0.0

		botao_atual.modulate = Color.WHITE

		if menu_inicial.visible:
			iniciar_jogo()

		elif menu_game_over.visible:
			iniciar_jogo()
