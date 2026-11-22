# Jogos da CTRL 3D

Este repositório reúne três jogos 2D desenvolvidos com Godot 4 e GDScript.

| Jogo | Projeto Godot | Como funciona |
| --- | --- | --- |
| **EvoBird** | [project.godot](EvoBird/project.godot) | Pule com **Espaço** para desviar de obstáculos. O jogo começa há 150 milhões de anos e passa por cinco fases, do Jurássico aos Tempos Modernos. Cada fase troca a ave e os obstáculos. Uma colisão reinicia a partida. |
| **Fruit Killer** | [project.godot](Fruit-Killer/FruitKiller/project.godot) | Corte frutas com o mouse ou com gestos captados pela webcam. Cortar comida perigosa custa uma vida. |
| **Papagaio Azarado** | [project.godot](Papagaio-Azarado/project.godot) | Mova o papagaio pela fase, pule para escapar dos inimigos e colete pinhões para marcar pontos. |

## Executar no Godot

Abra o gerenciador de projetos do Godot 4, importe o arquivo `project.godot` do jogo desejado e pressione **F5** no editor.

### Webcam no Fruit Killer

Em um terminal PowerShell, a partir da raiz do repositório, instale as dependências e inicie o capturador.

```powershell
cd Fruit-Killer/Webcam-Capture
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe webcam_godot.py
```

Com a webcam disponível e o capturador em execução, abra o Fruit Killer no Godot. O capturador usa OpenCV e MediaPipe para rastrear as mãos e envia os dados ao jogo por UDP em `127.0.0.1:10050`.

## Versões para navegador

A pasta [game-html](game-html/) contém as exportações do [EvoBird](game-html/EvoBird/Evobird.html) e do [Papagaio Azarado](game-html/PapagaioAzarado/JogoPlataforma.html). Sirva a pasta por HTTP para abrir os jogos no navegador.
