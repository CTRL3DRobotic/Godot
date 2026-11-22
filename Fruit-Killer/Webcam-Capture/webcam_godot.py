
import cv2
import mediapipe as mp
import socket
import json
import time
import threading

# ==========================================
# 1. CONFIGURACOES
# ==========================================

IP_GODOT = "127.0.0.1"
PORTA_GODOT = 10050

# Resolucao menor = menos processamento
LARGURA = 640
ALTURA = 480

FPS_CAMERA = 30

# Modelo mais leve do MediaPipe
COMPLEXIDADE_MODELO = 0

# True = mostrar webcam
# False = economizar processamento
MOSTRAR_WEBCAM = True

# Desenhar esqueleto das maos na webcam
DESENHAR_MAOS = False

# Mostrar informacoes no terminal
MOSTRAR_DESEMPENHO = True

# ==========================================
# 2. COMUNICACAO UDP
# ==========================================

udp = socket.socket(
    socket.AF_INET,
    socket.SOCK_DGRAM
)

DESTINO = (IP_GODOT, PORTA_GODOT)

# ==========================================
# 3. MEDIAPIPE
# ==========================================

mp_maos = mp.solutions.hands
mp_desenho = mp.solutions.drawing_utils

detector = mp_maos.Hands(
    static_image_mode=False,
    max_num_hands=2,
    model_complexity=COMPLEXIDADE_MODELO,
    min_detection_confidence=0.6,
    min_tracking_confidence=0.5
)

# ==========================================
# 4. INICIALIZAR WEBCAM
# ==========================================

camera = cv2.VideoCapture(
    0,
    cv2.CAP_DSHOW
)

if not camera.isOpened():
    print("ERRO: Webcam nao encontrada!")
    detector.close()
    udp.close()
    raise SystemExit(1)

camera.set(
    cv2.CAP_PROP_FRAME_WIDTH,
    LARGURA
)

camera.set(
    cv2.CAP_PROP_FRAME_HEIGHT,
    ALTURA
)

camera.set(
    cv2.CAP_PROP_FPS,
    FPS_CAMERA
)

# Nem todos os drivers suportam essa opcao
camera.set(
    cv2.CAP_PROP_BUFFERSIZE,
    1
)

largura_real = camera.get(
    cv2.CAP_PROP_FRAME_WIDTH
)

altura_real = camera.get(
    cv2.CAP_PROP_FRAME_HEIGHT
)

print("================================")
print("WEBCAM INICIADA")
print("Resolucao:", largura_real, "x", altura_real)
print("Porta UDP:", PORTA_GODOT)
print("Modelo MediaPipe:", COMPLEXIDADE_MODELO)
print("================================")

# ==========================================
# 5. CAPTURA EM THREAD SEPARADA
# ==========================================

frame_atual = None
numero_frame = 0

lock_frame = threading.Lock()
evento_frame = threading.Event()
encerrar = threading.Event()


def capturar_webcam():

    global frame_atual
    global numero_frame

    while not encerrar.is_set():

        sucesso, frame = camera.read()

        if not sucesso:
            time.sleep(0.02)
            continue

        # Espelhar imagem
        frame = cv2.flip(frame, 1)

        # Guardar apenas o quadro mais recente
        with lock_frame:

            frame_atual = frame
            numero_frame += 1

        evento_frame.set()


thread_camera = threading.Thread(
    target=capturar_webcam,
    daemon=True
)

thread_camera.start()

# ==========================================
# 6. CONTROLE DE DESEMPENHO
# ==========================================

ultimo_log = time.monotonic()

frames_processados = 0
tempo_processamento_total = 0.0

ultimo_numero_processado = -1

print("Captura iniciada!")
print("Pressione CTRL+C para encerrar.")

if MOSTRAR_WEBCAM:
    print("Pressione ESC na janela para encerrar.")

# ==========================================
# 7. LOOP PRINCIPAL
# ==========================================

try:

    while not encerrar.is_set():

        # Aguardar a chegada de um quadro
        if not evento_frame.wait(timeout=0.1):
            continue

        # Recuperar o quadro mais recente
        with lock_frame:

            frame = frame_atual
            numero_atual = numero_frame

            evento_frame.clear()

        if frame is None:
            continue

        # Nao processar duas vezes o mesmo quadro
        if numero_atual == ultimo_numero_processado:
            continue

        ultimo_numero_processado = numero_atual

        inicio_processamento = time.perf_counter()

        altura, largura = frame.shape[:2]

        # ==================================
        # 8. PREPARAR IMAGEM
        # ==================================

        imagem_rgb = cv2.cvtColor(
            frame,
            cv2.COLOR_BGR2RGB
        )

        imagem_rgb.flags.writeable = False

        resultado = detector.process(
            imagem_rgb
        )

        # ==================================
        # 9. DETECTAR AS DUAS MAOS
        # ==================================

        dados = {
            "hands": []
        }

        if resultado.multi_hand_landmarks:

            for i, mao in enumerate(
                resultado.multi_hand_landmarks
            ):

                # Landmark 9: centro superior da palma
                centro = mao.landmark[9]

                x = max(
                    0.0,
                    min(1.0, centro.x)
                )

                y = max(
                    0.0,
                    min(1.0, centro.y)
                )

                # Identificacao das maos
                mao_id = i

                if resultado.multi_handedness:

                    classificacao = (
                        resultado.multi_handedness[i]
                        .classification[0].label
                    )

                    if classificacao == "Left":
                        mao_id = 0
                    else:
                        mao_id = 1

                # Manter compatibilidade com Godot
                dados["hands"].append({
                    "id": mao_id,
                    "x": round(x, 4),
                    "y": round(y, 4)
                })

                # Desenhar apenas se solicitado
                if MOSTRAR_WEBCAM and DESENHAR_MAOS:

                    mp_desenho.draw_landmarks(
                        frame,
                        mao,
                        mp_maos.HAND_CONNECTIONS
                    )

                    px = int(x * largura)
                    py = int(y * altura)

                    cv2.circle(
                        frame,
                        (px, py),
                        12,
                        (0, 255, 0),
                        -1
                    )

                    cv2.putText(
                        frame,
                        f"Mao {mao_id}",
                        (px + 15, py - 15),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.6,
                        (0, 255, 0),
                        2
                    )

        # ==================================
        # 10. ENVIAR DADOS AO GODOT
        # ==================================

        mensagem = json.dumps(
            dados,
            separators=(",", ":")
        ).encode("utf-8")

        udp.sendto(
            mensagem,
            DESTINO
        )

        fim_processamento = time.perf_counter()

        tempo_ms = (
            fim_processamento - inicio_processamento
        ) * 1000.0

        frames_processados += 1

        tempo_processamento_total += tempo_ms

        # ==================================
        # 11. EXIBIR PREVIEW
        # ==================================

        if MOSTRAR_WEBCAM:

            cv2.putText(
                frame,
                f"Maos: {len(dados['hands'])}",
                (15, 30),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.7,
                (0, 255, 0),
                2
            )

            cv2.putText(
                frame,
                f"Processamento: {tempo_ms:.1f} ms",
                (15, 60),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                (0, 255, 255),
                2
            )

            cv2.imshow(
                "Webcam - Controle Godot",
                frame
            )

            if cv2.waitKey(1) & 0xFF == 27:
                break

        # ==================================
        # 12. MEDIR FPS
        # ==================================

        agora = time.monotonic()

        intervalo = agora - ultimo_log

        if intervalo >= 1.0:

            fps = (
                frames_processados / intervalo
            )

            media_ms = (
                tempo_processamento_total
                / max(frames_processados, 1)
            )

            if MOSTRAR_DESEMPENHO:

                print(
                    f"FPS: {fps:.1f} | "
                    f"Media processamento: {media_ms:.1f} ms | "
                    f"Maos: {len(dados['hands'])}"
                )

            frames_processados = 0

            tempo_processamento_total = 0.0

            ultimo_log = agora

except KeyboardInterrupt:

    print("\nEncerrando programa...")

finally:

    # ==================================
    # 13. FINALIZAR RECURSOS
    # ==================================

    encerrar.set()
    evento_frame.set()

    thread_camera.join(timeout=2.0)

    camera.release()
    detector.close()
    udp.close()

    if MOSTRAR_WEBCAM:
        cv2.destroyAllWindows()

    print("Programa finalizado!")
