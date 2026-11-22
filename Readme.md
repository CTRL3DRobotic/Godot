# Jogos da CTRL 3D

Este repositório reúne três jogos 2D desenvolvidos com Godot 4 e GDScript.

| Jogo | Projeto Godot | Como funciona |
| --- | --- | --- |
| **EvoBird** | [project.godot](EvoBird/project.godot) | Pule com **Espaço** para desviar de obstáculos. O jogo começa há 150 milhões de anos e passa por cinco fases, do Jurássico aos Tempos Modernos. Cada fase troca a ave e os obstáculos. Uma colisão reinicia a partida. |
| **Fruit Killer** | [project.godot](Fruit-Killer/FruitKiller/project.godot) | Corte frutas com o mouse ou com gestos captados pela webcam. Cortar comida perigosa custa uma vida. |
| **Papagaio Azarado** | [project.godot](Papagaio-Azarado/project.godot) | Mova o papagaio pela fase, pule para escapar dos inimigos e colete pinhões para marcar pontos. |

## Executar no Godot

Baixe a edição padrão do Godot 4 para Windows, extraia o ZIP e execute o arquivo `.exe`. [Download oficial do Godot](https://godotengine.org/download/windows/)

No gerenciador de projetos, clique em **Importar**, selecione o arquivo `project.godot` do jogo desejado e abra o projeto. No editor, pressione **F5** para rodar.

### Como rodar o Fruit Killer

Para jogar com o mouse, abra `Fruit-Killer/FruitKiller/project.godot` no **Godot 4.6 ou superior** e pressione **F5**. Para jogar com gestos, você também precisa de uma webcam e do **Python 3.12 de 64 bits** instalado no Windows. [Downloads oficiais do Python para Windows](https://www.python.org/downloads/windows/)

#### Abrir e executar o projeto Python

1. Abra a pasta `Fruit-Killer/Webcam-Capture` no seu editor de código. O arquivo principal é `webcam_godot.py`.
2. No PowerShell, a partir da raiz do repositório, execute os comandos abaixo para entrar na pasta, criar o ambiente virtual, instalar as dependências e iniciar o capturador.

   ```powershell
   cd Fruit-Killer/Webcam-Capture
   py -3.12 -m venv .venv
   .\.venv\Scripts\python.exe -m pip install -r requirements.txt
   .\.venv\Scripts\python.exe webcam_godot.py
   ```

3. Deixe o capturador rodando, abra o Fruit Killer no Godot e pressione **F5**. O capturador usa OpenCV e MediaPipe para rastrear as mãos e envia os dados ao jogo por UDP em `127.0.0.1:10050`.

Depois da primeira configuração, basta abrir o PowerShell na pasta `Fruit-Killer/Webcam-Capture` e rodar `.\.venv\Scripts\python.exe webcam_godot.py` para iniciar o capturador novamente.

## Versões para navegador

A pasta [game-html](game-html/) contém as exportações do [EvoBird](game-html/EvoBird/Evobird.html) e do [Papagaio Azarado](game-html/PapagaioAzarado/JogoPlataforma.html). Sirva a pasta por HTTP para abrir os jogos no navegador.
