import java.util.*;
import java.io.*;
import processing.sound.*;

// Parâmetros do labirinto
int nCol, nLin;          // nº de linhas e de colunas
int tamanho = 50;        // tamanho (largura e altura) das células do labirinto  
int espacamento = 2;     // espaço livre emtre células
float margemV, margemH;  // margem livre na vertical e na horizontal para assegurar que as células são quadrangulares
color corObstaculos =  color(100, 0 , 128);      // cor de fundo dos obstáculos

// Posicao, tamanho e cor do Pacman
float px, py, pRaio;
color corPacman = color(255, 253, 56);

//velocidade na horizontal e vertical do Pacman
float vx, vy; 
 
// variaveis relacionadas com os fantasmas
int fantasmas = 4; // nº de fantasmas
float[][] posFantasmas = new float[fantasmas][3]; // posicoes dos fantasmas
color[] corFantasmas = {color(66, 197, 244) /* azul */, color(244, 164, 66)/* laranja */, 
                      color(244, 75, 66)/* vermelho */, color(247, 173, 211)/* rosa */};
float[] vFantasmas = {1.7, 1.5, 1.95, 2}; // velocidades dos fantasmas
int[][] mapaFantasmas;
boolean[] obstaculo = {false, false, false, false}; // se um dos fantasmas se encontra a contornar um obstaculo
// se os fantasmas tem ou nao um obstaculo na respetiva direcao
boolean[] fanPodeCima = {true, true, true, true}, fanPodeBaixo = {true, true, true, true}, 
          fanPodeEsq = {true, true, true, true}, fanPodeDir = {true, true, true, true};
int[] dirObstaculoFantasma = new int[4]; // a direcao que o fantasma segui quando encontrou um obstaculo

// matriz e contador da comida
int[][] mapaComida;
int contadorComida = 0;

// variaveis que controlam o ecra mostrado ao utilizador
boolean jogoIniciado = false;
boolean jogoGanho = false;
boolean jogoPerdido = false;
boolean instrucoes = false;

// vairaveis que controlam o nivel de dificuldade e a pontuacao
float dificuldade;
float facil = 3.0, medio = 2.70, dificil = 2.15;
String nivel = "";
int pontuacao = 0;

// variaveis relacionadas com imagens e sons
PImage introPacImg;
SoundFile somMenu, somJogo;

// variaveis para controlar a duracao dos ecra de vitoria e derrota
int duracaoEcra;
int duracaoMaxEcra = 1900;

// variaveis que armazenam velocidade, usados na funcionalidade de pausa
float[] stopVel = new float[2];
boolean pausa = false;
boolean cheatList = false;

//variaveis para controlar o modo de comer fantasmas
boolean modoComer = false;
boolean[] fantasmaComido = new boolean[4];

// variavel que armazena velocidade extra para o cheat
// code de aumentar/repor a velocidade do pacman
float velExtra = 0;

// verifica se foram usados cheat codes
boolean cheatsUsados = false;

void setup() {

  // Definir o tamanho da janela; notar que size() não aceita variáveis.
  size(720, 520);
  background(0);
  
  // icone e titulo da janela                                                                                                                      
  surface.setIcon(loadImage("icon.png"));
  surface.setTitle("Pacman");
  
  nCol = (int)width/tamanho;
  nLin = (int)height/tamanho;

  // Assegurar que nº de linhas e nº de colunas é maior ou igual a 5
  assert nCol >= 5 && nLin >= 5;

  // Determinar margens para limitar a área útil do jogo 
  margemV = (width - nCol * tamanho) / 2.0;
  margemH = (height - nLin * tamanho) / 2.0;
  
  // Inicializar o Pacman e as estruturas internas de comida e fantasmas
  pRaio = tamanho / 2;
  
  mapaComida = new int[nCol][nLin];
  mapaFantasmas = new int[nCol+2][nLin+2];
  
  // Inicializar imagens e sons
  introPacImg = loadImage("pacman.png");
  somMenu = new SoundFile(this, "menu.mp3");
  somJogo = new SoundFile(this, "game.mp3");
  
  somMenu.loop();
  
  frameRate(60);
}

void draw(){
  background(0);
  
  if (!jogoIniciado) { // ecra do menu e highscores
    // menu
    fill(0, 0);
    stroke(corPacman);
    strokeWeight(espacamento);
    
    image(introPacImg, margemH*2, 0, 0.371875*(height - 2*margemV), height - 2*margemV);
    
    rect(margemH, margemV, width*2/3, height - 2*margemV);
    for (int i = 0; i < 4; i++) {
      rect(margemH*2 + width*2/3, margemV*(i+1) + (height - 5*margemV)*i/4, width*1/3 - 3*margemH,  (height - 5*margemV)/4);
    }
    
    fill(corPacman);
    textSize(120);
    text("P", 200, 125);
    textSize(60);
    text("acman", 250, 125);
    
    fill(color(255, 255, 255));
    text("Fácil", 200, 240); 
    text("Médio", 200, 360); 
    text("Difícil", 200, 480); 

    // highscores
    fill(corPacman);
    textSize(25);
    text("Fácil", margemH*3 + width*2/3, margemV*3.36); 
    text("Médio", margemH*3 + width*2/3, margemV*4.39 + (height - 5*margemV)*1/4); 
    text("Difícil", margemH*3 + width*2/3, margemV*5.43 + (height - 5*margemV)*2/4); 
    text("Cheat Codes", margemH*3 + width*2/3, margemV*6.45 + (height - 5*margemV)*3/4); 
    
    try {
      File fout = new File("highscores.txt");
      if(fout.exists()){
        Scanner input = new Scanner(fout);
        int[][] pontuacoes = {{0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}};
        while(input.hasNextLine()) {
          String line = input.nextLine();
          String[] parts = line.split(":");
          
          int indice = 3;
          switch (parts[0]) {
            case "Facil":
              indice = 0;
              break;
            case "Medio":
              indice = 1;
              break;
            case "Dificil":
              indice = 2;
              break;
            // por omissao = cheat codes
          }
          for(int i = 0; i < 3; i++) {
            int temp = Integer.parseInt(parts[1]);
            if (temp > pontuacoes[indice][i]) {
              if (i != 2) {
                if (i == 0) {
                  pontuacoes[indice][i+2] = pontuacoes[indice][i+1];
                }
                pontuacoes[indice][i+1] = pontuacoes[indice][i];
              }
              pontuacoes[indice][i] = temp;
              break;
            }
          }
        }
        input.close();
        
        fill(color(255, 255, 255));
        // escrever cada highscore
        for (int i = 0; i < 4; i++) {
          for (int j = 0; j < 3; j++) {
            text(pontuacoes[i][j], margemH*13 + width*2/3, margemV*(i+6.25) + (height - 5*margemV)*(i)/4 + 27*j); 
          }
        }
      }
    } catch (IOException e) {
        e.printStackTrace();
    }
    
  } else if (instrucoes) { // ecra de instrucoes
    fill(0);
    stroke(corPacman);
    strokeWeight(espacamento);
    rect(margemH, margemV, width - 2*margemH, height - 2*margemV);
    
    fill(corPacman);
    textSize(40);
    text("Como jogar", 100, 100);  
    fill(255);
    textSize(30);
    text("  Usa as setas ou as teclas WASD para", 50, 150);
    text("movimentares o pacman. ", 50, 190); 
    text("  O objetivo é comeres todas os pontos", 50, 240);
    text("brancos, mas cuidado com os fantasmas!", 50, 280);
    text("Se eles te apanharem, perdes o jogo!", 50, 320);
    text("  Carrega no rato ou em qualquer tecla", 50, 370); 
    text("para continuares.", 50, 410);
    
    textSize(15);
    text("PS. Carrega em 'C'  ;)", 555, 505);
  
  } else if (jogoGanho) { // ecra de vitoria
    fill(0);
    stroke(corPacman);
    strokeWeight(espacamento);
    rect(margemH, margemV, width - 2*margemH, height - 2*margemV);
    
    fill(corPacman);
    textSize(100);
    text("Parabéns!", 100, 200);
    fill(255);
    textSize(40);
    text("Venceste o nível " + nivel + ", com ", 40, 300); 
    text("uma pontuação de " + String.valueOf(pontuacao) + " pontos!", 40, 370);
    
    if (millis() - duracaoEcra > duracaoMaxEcra) {
      // sair do ecra de vitoria
      jogoGanho = false;
      terminarJogo();
    }
    
  } else if (jogoPerdido) { // ecra de derrota
    fill(0);
    stroke(corPacman);
    strokeWeight(espacamento);
    rect(margemH, margemV, width - 2*margemH, height - 2*margemV);
    
    fill(corPacman);
    textSize(85);
    text("Ghostbusted!", 65, 200);
    fill(255);
    textSize(40);
    text("Perdeste no nível " + nivel + ", com ", 40, 300); 
    text("uma pontuação de " + String.valueOf(pontuacao) + " pontos!", 40, 370);
    
    if (millis() - duracaoEcra > duracaoMaxEcra) {
      // sair do ecra de derrota
      jogoPerdido = false;
      terminarJogo();
    }
  } else if (cheatList) {
    fill(0);
    stroke(corPacman);
    strokeWeight(espacamento);
    rect(margemH, margemV, width - 2*margemH, height - 2*margemV);
    
    // titulo
    fill(corPacman);
    textSize(30);
    text("Cheat Codes", width/2 - 90, 60);
    
    // seccao de cores
    fill(corPacman, 200);
    textSize(27);
    text("Mudar o tema", 70, 100);
    
    // teclas G, B, I e Y
    textSize(20);
    fill(corPacman);
    text("G", 50, 130);
    text("B", 50, 160);
    text("I", 50, 190);
    text("Y", 50, 220);
    fill(255);
    text("Tema Verde", 100, 130);
    text("Tema Cinzento", 100, 160);
    text("Inverter o tema original", 100, 190);
    text("Tema original", 100, 220);
    
    // seccao dos fantasmas
    fill(corPacman, 200);
    textSize(27);
    text("Fantasmas", 70, 260);
    
    // teclas F, U e E
    textSize(20);
    fill(corPacman);
    text("F", 50, 290);
    text("U", 50, 320);
    text("E", 50, 360);
    fill(255);
    text("Congelar os fantasmas", 100, 290);
    text("Descongelar os fantasmas", 100, 320);
    text("Ativar/ Desativar modo", 100, 350);
    text("de comer fantasmas", 100, 370);
    
    // seccao de comandos
    fill(corPacman, 200);
    textSize(27);
    text("Sair ou Pausar", 70, 410);
    
    // teclas P e Q
    textSize(20);
    fill(corPacman);
    text("P", 50, 450);
    text("Q", 50, 480);
    fill(255);
    text("Pausa ou continua o jogo", 100, 450); 
    text("Sai do jogo atual", 100, 480); 
    
    // secao da velocidade do pacman
    fill(corPacman, 200);
    textSize(27);
    text("Velocidade", 470, 100);
    
    // teclas V/+ e -
    textSize(20);
    fill(corPacman);
    text("V", 420, 130);
    text("ou +", 405, 150);
    text("-", 420, 190);
    fill(255);
    text("Aumenta a velocidade", 470, 130); 
    text("do pacman", 470, 150);
    text("Repõe a velocidade", 470, 180); 
    text("original do pacman", 470, 200);
    
    
    // seccao de outros comandos
    fill(corPacman, 200);
    textSize(27);
    text("Outros", 470, 240);
    
    // teclas R e C
    textSize(20);
    fill(corPacman);
    text("R", 420, 270);
    text("C", 420, 300);
    fill(255);
    text("Repõe as pontuações", 470, 270);
    text("Abre/Fecha esta lista", 470, 300);
    
  } else {  
    
    desenharLabirinto();
    desenharPontos();
    desenharPacman();
    desenharFantasmas();
    comerPontos();
    orientarPacman(0);
    moverPacman();
    moverFantasmas();
    
    if (pausa) { 
      // desenhar simbolo da pausa em cima do jogo
      fill(corPacman);
      noStroke();
      rect(width/2.3 - 2*margemH, 150, 4*margemH, height/3);
      rect(width/2.3 + 6*margemH, 150, 4*margemH, height/3);
    }
  }  
}

void keyPressed() {
  if (instrucoes) {
    instrucoes = false;
  } 
  if (key == CODED) { 
    // orientar pacman
    if (keyCode == UP) {
      orientarPacman(1);
    } else if (keyCode == DOWN) {
      orientarPacman(2);
    } else if (keyCode == LEFT) {
      orientarPacman(3);
    }  else if (keyCode == RIGHT) {
      orientarPacman(4);
    }
  } else {
    if (key == 'W' || key == 'w') {
      orientarPacman(1);
    } else if (key == 'S' || key == 's') {
      orientarPacman(2);
    } else if (key == 'A' || key == 'a') {
      orientarPacman(3);
    } else if (key == 'D' || key == 'd') {
      if (jogoIniciado) {
        orientarPacman(4);
      } else { // selecionar dificuldade dificil
        comecarJogo(dificil);
      }
    }
    else if (key == 'M' || key == 'm'){ 
      if (!jogoIniciado) { // selecionar dificuldade media
        comecarJogo(medio);
      }
    } 
    
    else if (key == 'F' || key == 'f') {       // cheat codes
      if (jogoIniciado) { // Congelar fantasmas
        cheatsUsados = true;
        for (int i = 0; i < fantasmas; i++) {
          vFantasmas[i] = 0;
        } 
      } else { // selecionar dificuldade facil
        comecarJogo(facil);
      }
    } else if (key == 'U' || key == 'u') { // Descongelar fantasmas
      vFantasmas[0] = 1.7; 
      vFantasmas[1] = 1.5; 
      vFantasmas[2] = 1.95; 
      vFantasmas[3] = 2.14;
    }
    else if (key == 'E' || key == 'e') { // Ativa/Desativa no modo de comer fantasmas
      if (!modoComer) {
        cheatsUsados = true;
        modoComer = true;
        for (int i = 0; i < fantasmas; i++) {
          corFantasmas[i] = color(2, 90, 232);
        }
      } else {
        for (int i = 0; i < fantasmas; i++) {
          if (fantasmaComido[i]) {
            switch (i) {
              case 0:
                posFantasmas[0][0] = centroX(1);
                posFantasmas[0][1] = centroY(1);
                posFantasmas[0][2] = 4;
                break;
              case 1:
                posFantasmas[1][0] = centroX(1);
                posFantasmas[1][1] = centroY(nLin);
                posFantasmas[1][2] = 4;
                break;
              case 2:
                posFantasmas[2][0] = centroX(nCol);
                posFantasmas[2][1] = centroY(1);
                posFantasmas[2][2] = 3;
                break;
              case 3:
                posFantasmas[3][0] = centroX(nCol);
                posFantasmas[3][1] = centroY(nLin);
                posFantasmas[3][2] = 3;
                break;
            }
  
           fantasmaComido[i] = false;
          }
        }
        corFantasmas[0] = color(66, 197, 244);
        corFantasmas[1] = color(244, 164, 66);
        corFantasmas[2] = color(244, 75, 66);
        corFantasmas[3] = color(247, 173, 211);
        modoComer = false;
      }
    }
    
    else if (key == '+' || key == 'V'|| key == 'v') { // aumentar velocidade do pacman
      if (velExtra < dificuldade) {
        cheatsUsados = true;
        velExtra += 0.1;
      }
    } else if (key == '-') { // repor a velocidade extra do pacman da 0
      velExtra = 0;
    }
    
    else if (key == 'Y' || key == 'y') { // tema original
      corPacman = color(232, 239, 40);
      corObstaculos = color(100, 0 , 128);
    } else if (key == 'G' || key == 'g') { // tema verde
      corPacman = color(20, 239, 40);
      corObstaculos = color(100, 255, 200);
    } else if (key == 'I' || key == 'i') { // tema invertido
      corPacman = color(100, 0 , 128);
      corObstaculos = color(232, 239, 40);
    } else if (key == 'B' || key == 'b') { // tema cinzento
      corPacman = color(140, 140, 140);
      corObstaculos = color(70, 70 , 70);
    }

    else if (key == 'Q' || key == 'q' || key == 27) { // Sair do jogo, usando Q ou Esc
      if(jogoIniciado) {
        perder();
      }
      key = 0; // se a tecla for Esc, impede que se saia do jogo
    }
    else if (key == ' ' || key == 'P' || key == 'p') { 
      // Pausar e retomar o jogo
      if (!pausa) { // pausar o jogo
        stopVel[0] = vx;
        stopVel[1] = vy;
        vx = 0;
        vy = 0;
        for (int i = 0; i < fantasmas; i++) {
          vFantasmas[i] = 0; 
        }
      } else { // retomar o jogo
        vx = stopVel[0];
        vy = stopVel[1];
        vFantasmas[0] = 1.7; 
        vFantasmas[1] = 1.5; 
        vFantasmas[2] = 1.95; 
        vFantasmas[3] = 2.14;
      }
      // mudar de estado
      pausa = !pausa;
    }
    
    if (key == 'R' || key == 'r') { // Repoe os highscores
      resetScores();
    }
    
    if (key == 'C' || key == 'c') { // Pausa o jogo e mostra a lista dos cheat codes
      if(cheatList) {
        cheatList = false;
        pausa = false;
      } else {
        cheatList = true;
        pausa = true;
      }
    }
  }
}

void mouseClicked() {
  if (instrucoes) {
    instrucoes = false;
  } else if (cheatList) {
    cheatList = false;
    pausa = false;
  } 
  if (!jogoIniciado && (mouseX >= 0) && (mouseX <= width*2/3)) {
     if ((mouseY >= 150) && (mouseY < 300)) { // facil
      nivel = "fácil";
      comecarJogo(facil);
    } else if ((mouseY >= 300) && (mouseY < 420)) { // medio
      nivel = "médio";
      comecarJogo(medio);
    } else if ((mouseY >= 420)) { // dificil
      nivel = "difícil";
      comecarJogo(dificil);
    }
  }
  // se o rato e clickado no ecra de vitoria ou derrota, ignorar o tempo restante da mensagem
  if ((jogoGanho) || (jogoPerdido)) {
  // sair dos ecras
      jogoGanho = false;
      jogoPerdido = false;
      
      terminarJogo();
  }
}

/* Inicializa varias variaveis e comeca o jogo */
void comecarJogo(float dif) {
  // repor as condicoes iniciais
  instrucoes = true;
  contadorComida = 0;
  dificuldade = dif;
  pontuacao = 0;
  velExtra = 0;
  
  // mudar para o som do jogo
  somMenu.stop();
  somJogo.loop();
  
  // inicializar o Pacman
  px = centroX(5);
  py = centroY(1);
  
  // inicializar os fantasmas
  posFantasmas[0][0] = centroX(1);
  posFantasmas[0][1] = centroY(1);
  posFantasmas[0][2] = 4;
  
  posFantasmas[1][0] = centroX(1);
  posFantasmas[1][1] = centroY(nLin);
  posFantasmas[1][2] = 4;
  
  posFantasmas[2][0] = centroX(nCol);
  posFantasmas[2][1] = centroY(1);
  posFantasmas[2][2] = 3;
  
  posFantasmas[3][0] = centroX(nCol);
  posFantasmas[3][1] = centroY(nLin);
  posFantasmas[3][2] = 3;
  
  // inicializar velocidades
  vx = 1 * dificuldade;
  vFantasmas[0] = 1.7; 
  vFantasmas[1] = 1.5; 
  vFantasmas[2] = 1.95; 
  vFantasmas[3] = 2.14;
  
  // ajustar velocidade dos fantasmas
  if ((int)(dif*100) == (int)(facil*100)) {
    for (int i = 0; i < fantasmas; i++) {
      vFantasmas[i] -= 1;
    }
  } else if ((int)(dif*100) == (int)(medio*100)) {
    for (int i = 0; i < fantasmas; i++) {
      vFantasmas[i] -= 0.4;
    }
  }
  
  // correr todas as funcoes que compoem o jogo uma vez antes de serem chamadas
  // pela draw, de forma a inicializar os mapas dos fantasmas e da comida
  desenharLabirinto();
  
  // criar mapa de comida e de fantasmas
  for (int i = 0; i < nCol; i++) {
    for (int j = 0; j < nLin; j++) {     
      color c = get((int)centroX(i+1), (int)centroY(j+1));
      if(c != corObstaculos) {
          mapaComida[i][j] = 1;
          mapaFantasmas[i+1][j+1] = 1;
          contadorComida++;
        } else {
          mapaComida[i][j] = 0;
          mapaFantasmas[i+1][j+1] = 0;
        }
     
      mapaFantasmas[0][j+1] = 0;
      mapaFantasmas[nCol+1][j+1] = 1;
    }
  }
  
  // desativar qualquer cheat code
  cheatsUsados = false;
  pausa = false;
  modoComer = false;
  corFantasmas[0] = color(66, 197, 244);
  corFantasmas[1] = color(244, 164, 66);
  corFantasmas[2] = color(244, 75, 66);
  corFantasmas[3] = color(247, 173, 211);
  for (int i = 0; i < fantasmas; i++) {
    fantasmaComido[i] = false;
    dirObstaculoFantasma[i] = 0;
  }
  
  jogoIniciado = true; 
  
  desenharPontos();
  desenharPacman();
  desenharFantasmas();
  comerPontos();
  orientarPacman(0);
  moverPacman();
  moverFantasmas();
  
       
}

/* Guarda a pontuacao e reinicia o jogo */
void terminarJogo() {
  // mudar para o som do menu
  somJogo.stop();
  somMenu.loop();
  
  // guardar pontuacao
  try {
        // abrir ficheiro
        File fout = new File("highscores.txt");
        if(!fout.exists()){
          fout.createNewFile();
        }

        // guardar a pontucao, certificando-nos que so guarda 3 highscores
        // para cada categoria
        String highscores = "";
        
        // ler as top 3 pontuacoes de cada categoria
        Scanner input = new Scanner(fout);
        int[][] pontuacoes = {{0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}};
        while(input.hasNextLine()) {
          String line = input.nextLine();
          String[] parts = line.split(":");
          
          int indice = 3;
          switch (parts[0]) {
            case "Facil":
              indice = 0;
              break;
            case "Medio":
              indice = 1;
              break;
            case "Dificil":
              indice = 2;
              break;
            // por omissao = foram usados cheat codes
          }
          for(int i = 0; i < 3; i++) {
            int temp = Integer.parseInt(parts[1]);
            if (temp > pontuacoes[indice][i]) {
              if (i != 2) {
                if (i == 0) {
                  pontuacoes[indice][i+2] = pontuacoes[indice][i+1];
                }
                pontuacoes[indice][i+1] = pontuacoes[indice][i];
              }
              pontuacoes[indice][i] = temp;
              break;
            }
          }
        }
        input.close();
        
        // verficar se a pontucao deste jogo pertece ao top 3 da sua categoria
        int indiceJogo = 3;
        if (!cheatsUsados) {
          switch ((int)(dificuldade * 100)) {
            case 300:
              indiceJogo = 0;
              break;
            case 270:
              indiceJogo = 1;
              break;
            case 215:
              indiceJogo = 2;
              break;
          }
        }
        for(int i = 0; i < 3; i++) {
            if (pontuacao > pontuacoes[indiceJogo][i]) {
              if (i != 2) {
                if (i == 0) {
                  pontuacoes[indiceJogo][i+2] = pontuacoes[indiceJogo][i+1];
                }
                pontuacoes[indiceJogo][i+1] = pontuacoes[indiceJogo][i];
              }
              pontuacoes[indiceJogo ][i] = pontuacao;
              break;
            }
          }
        
        
        // escrever as top 3 pontuacoes de cada categoria
        for (int i = 0; i < 4; i++) {
          String cabecalho = "Com Cheat Codes:";
          switch (i){
            case 0:
              cabecalho = "Facil:";
              break;
            case 1:
              cabecalho = "Medio:";
              break;
            case 2:
              cabecalho = "Dificil:";
              break;
          }
          for (int j = 0; j < 3; j++) {
            highscores += cabecalho + String.valueOf(pontuacoes[i][j]) + "\n";
          }
        }
        
        
        PrintWriter fileOut = new PrintWriter(fout);
        fileOut.write(highscores);
        fileOut.close();

      } catch (IOException e){
        e.printStackTrace();
      }
      
  // reiniciar o jogo
  jogoIniciado = false;
}

/* Termina o jogo quando este foi ganho, mostrando uma mensagem de vitoria */
void ganhar() {
  // mostar ecra de vitoria
  duracaoEcra = millis();
  jogoGanho = true;
}

/* Termina o jogo quando este foi perdido, mostrando uma mensagem de derrota */
void perder() {
  // mostrar ecra de derrota
  duracaoEcra = millis();
  jogoPerdido = true;
}

void moverFantasmas() { 
  // encontrar a posicao do pacman
  int pacX = (int)(Math.round((px + 0.5 - margemH/2)/tamanho));
  int pacY = (int)(Math.round((py + 0.5 - margemV/2)/tamanho));
  if ((vx < 0) || (vy < 0)) { 
      // ajustar a posicao se o pacman estiver a ir para cima ou para a esquerda
      pacX = (int)(Math.round((px + 0.5 + margemH*3.3)/tamanho)); 
      pacY = (int)(Math.round((py + 0.5 + margemV*3.3)/tamanho));
  }
  
   for (int i = 0; i < fantasmas; i++) {

     float pFx = posFantasmas[i][0];
     float pFy = posFantasmas[i][1];
     
      int x = (int)Math.round((pFx + 0.5 - margemH/2)/tamanho);
      int y = (int)Math.round((pFy + 0.5 - margemV/1.5)/tamanho);
      
       // ajustar a posicao dos fantasmas, para criar um movimento mais fluido
       if (posFantasmas[i][2] - 1 < 0.1) { // para cima
         y = (int)Math.round((pFy + 0.5 - margemV*2)/tamanho) + 1;
       } else if (posFantasmas[i][2] - 2 < 0.1) { // para baixo
         y = (int)Math.round((pFy + 0.5)/tamanho);
       } else if (posFantasmas[i][2] - 3 < 0.1) { // para a esquerda
         x = (int)Math.round((pFx + 0.5 - margemH*2)/tamanho) + 1;
       } else if (posFantasmas[i][2] - 4 < 0.1) { // para a direita
         x = (int)Math.round((pFx + 0.5 - margemH/2.4)/tamanho);
       } 
                                                                                                                                   
     if (!obstaculo[i]) {
       // perseguir pacman
       if ((pacX - x < 0) && (mapaFantasmas[x-1][y] == 1)) { // ir para a esquerda
         pFx -= vFantasmas[i];
         pFy = centroY(y); 
         posFantasmas[i][2] = 3;
       } else if ((pacX - x > 0) && (mapaFantasmas[x+1][y] == 1)) { // ir para a direita
         pFx += vFantasmas[i];
         pFy = centroY(y); 
         posFantasmas[i][2] = 4;
       } else if ((pacY - y < 0) && (mapaFantasmas[x][y-1] == 1)) { // ir para cima
         pFy -= vFantasmas[i];
         pFx = centroX(x); 
         posFantasmas[i][2] = 1;
       } else if ((pacY - y > 0) && (mapaFantasmas[x][y+1] == 1)) { // ir para baixo
         pFy += vFantasmas[i];
         pFx = centroX(x); 
         posFantasmas[i][2] = 2;
       } else {
         if ((pacX - x < 0.5) && (pacX - x > -0.5) && (pacY - y < 0.5) && (pacY - y > -0.5)) {
           // certificar que um fantasma esta a tocar o pacman
           boolean pacComido = false;
           for (int j = 0; j < fantasmas; j++) {
             if ((get((int)px, (int)py) == corFantasmas[i]) || (get((int)(px + pRaio), (int)py) == corFantasmas[i])
                 || (get((int)(px - pRaio), (int)py) == corFantasmas[i]) || (get((int)px, (int)(py + pRaio)) == corFantasmas[i]) 
                 || (get((int)px, (int)(py - pRaio)) == corFantasmas[i])) {
               pacComido = true;
             }
           }
           if (pacComido) { 
             if (!modoComer) {
               perder();
             } else { // comer fantasma
               fantasmaComido[i] = true;
               // verificar se todos os fantasmas foram comidos
               boolean comeuTodosFan = true;
               for (int j = 0; j < fantasmas; j++) {
                 if (!fantasmaComido[j]) {
                   comeuTodosFan = false;
                 }
               }
               if (comeuTodosFan) {
                 ganhar();
               }
             }
           }
         } else {
           obstaculo[i] = true;
         } 
       }
     } else { 
       // ha um obstaculo entre o fantasma e o pacman
       if (dirObstaculoFantasma[i] == 0) { // o obstaculo esta a aparecer pela primeira vez
          if ((pacY != y)) {
            if (((posFantasmas[i][2] - 1 < 0.1) && (posFantasmas[i][2] - 1 > -0.1) && (mapaFantasmas[x][y-1] == 0)) || (pacY - y < 0)) { 
              // obstaculo esta acima do fantasma
              dirObstaculoFantasma[i] = 1; 
              contornarObstaculo(i, pacX, pacY, x, y, pFx, pFy);} // obs cima
            else if (((posFantasmas[i][2] - 2 < 0.1) && (posFantasmas[i][2] - 2 > -0.1) && (mapaFantasmas[x][y+1] == 0)) || (pacY - y > 0)) { 
              // obstaculo esta abaixo do fantasma
              dirObstaculoFantasma[i] = 2; 
              contornarObstaculo(i, pacX, pacY, x, y, pFx, pFy);} // obs baixo
          } else if (pacX != x) {
            if (((posFantasmas[i][2] - 3 < 0.1) && (posFantasmas[i][2] - 3 > -0.1) && (mapaFantasmas[x-1][y] == 0)) || (pacX - x <= 0)) { 
              // obstaculo esta a esquerda do fantasma
              dirObstaculoFantasma[i] = 3; 
              contornarObstaculo(i, pacX, pacY, x, y, pFx, pFy);
            } else if (((posFantasmas[i][2] - 4 < 0.1) && (posFantasmas[i][2] - 4 > -0.1) && (mapaFantasmas[x+1][y] == 0)) || (pacX - x > 0))  { 
              // obstaculo esta a direita do fantasma
              dirObstaculoFantasma[i] = 4; 
              contornarObstaculo(i, pacX, pacY, x, y, pFx, pFy);
            }
          }
       } else { // continuar a contornar o obstaculo
         contornarObstaculo(i, pacX, pacY, x, y, pFx, pFy);
       }
       
     pFx = posFantasmas[i][0];
     pFy = posFantasmas[i][1];
     
     }
     
     // colisao com margens
    if (pFx > centroX(nCol)) { 
      pFx -= vFantasmas[i];
      pFx = centroX(x); 
    } else if (pFx < centroX(1)) {
      pFx += vFantasmas[i];
      pFx = centroX(x); 
    } else if (pFy > centroY(nLin)) {
      pFy -= vFantasmas[i];
      pFy = centroY(y); 
    } else if (pFy < centroY(1)) {
      pFy += vFantasmas[i];
      pFy = centroY(y); 
    }
     
     posFantasmas[i][0] = pFx;
     posFantasmas[i][1] = pFy;
     
  }
}

/* Implementa o movimento do Pacman, adicionando a 
 * sua velocidade a sua posicao
 */
void moverPacman() {
  px += vx;
  py += vy;
}

/* Implenta a inteligencia artificial dos fantasmas para que estes
 * consigam contornar obstaculos
 */
void contornarObstaculo(int fantasma, int pacX, int pacY, int x, int y, float pFx, float pFy) {

  if (dirObstaculoFantasma[fantasma] == 1) {
   // enquanto houver um obstaculo em cima do fantasma
     if(mapaFantasmas[x][y-1] != 1) {
     // ir para a esquerda ou para a direita ate deixar de existir um obstaculo em cima
       if((mapaFantasmas[x-1][y] == 1) && (fanPodeEsq[fantasma])) {  // ir para a esquerda
         pFx -= vFantasmas[fantasma];
         pFy = centroY(y); 
       } else if ((mapaFantasmas[x+1][y] == 1) && (fanPodeDir[fantasma])) { // ir para direita
         fanPodeEsq[fantasma] = false;
         pFx += vFantasmas[fantasma];
         pFy = centroY(y); 
       } else {
       // ir para baixo ate ser possivel ir a esquerda ou para a direita
         if (mapaFantasmas[x][y+1] == 1) {
           pFy += vFantasmas[fantasma];
           pFx = centroX(x); 
           
           fanPodeEsq[fantasma] = (mapaFantasmas[x-1][y] == 1);
           fanPodeDir[fantasma] = (mapaFantasmas[x+1][y] == 1);
         }
       }
     }
     if (pacY - y <= 0){ // ir para cima
       if (mapaFantasmas[x][y-1] == 1) {
         pFy -= vFantasmas[fantasma];
         pFx = centroX(x); 
         posFantasmas[fantasma][2] = 1;
       }
     } else {
       obstaculo[fantasma] = false;
       dirObstaculoFantasma[fantasma] = 0;
     }
   } 
   
   else if (dirObstaculoFantasma[fantasma] == 2) {
   // enquanto houver um obstaculo em baixo do fantasma
     if(mapaFantasmas[x][y+1] != 1) { 
     // ir para a esquerda ou para a direita ate deixar de existir um obstaculo em baixo
       if((mapaFantasmas[x-1][y] == 1) && (fanPodeEsq[fantasma])) {  // ir para a esquerda
         pFx -= vFantasmas[fantasma];
         pFy = centroY(y); 
       } else if ((mapaFantasmas[x+1][y] == 1) && (fanPodeDir[fantasma])) { // ir para direita
         fanPodeEsq[fantasma] = false;
         pFx += vFantasmas[fantasma];
         pFy = centroY(y); 
       } else {
       // ir para cima ate ser possivel ir a esquerda ou para a direita
         if (mapaFantasmas[x][y-1] == 1) {
           pFy -= vFantasmas[fantasma];
           pFx = centroX(x); 
           
           fanPodeEsq[fantasma] = (mapaFantasmas[x-1][y] == 1);
           fanPodeDir[fantasma] = (mapaFantasmas[x+1][y] == 1);
         }
       }
     }
     if (pacY - y > 0) {  // ir para baixo
       if (mapaFantasmas[x][y+1] == 1) {
         pFy += vFantasmas[fantasma];
         pFx = centroX(x); 
         posFantasmas[fantasma][2] = 2;
       }
     } else {
       obstaculo[fantasma] = false;
       dirObstaculoFantasma[fantasma] = 0;
     }
   }
   
   else if (dirObstaculoFantasma[fantasma] == 3) {
     // enquanto houver um obstaculo a esquerda do fantasma
     if(mapaFantasmas[x-1][y] != 1) {
       // ir para cima ou para baixo ate deixar de existir um obstaculo a direita do fantasma
       if((mapaFantasmas[x][y-1] == 1) && (fanPodeCima[fantasma])) {   // ir para cima
         pFx = centroX(x); 
         pFy -= vFantasmas[fantasma];
       } else if ((mapaFantasmas[x][y+1] == 1) && (fanPodeBaixo[fantasma])) {  // ir para baixo
         fanPodeCima[fantasma] = false;
         pFx = centroX(x); 
         pFy += vFantasmas[fantasma];
       } else {
         // ir para a direita ate ser possivel ir para cima ou para baixo
         if (mapaFantasmas[x][y+1] == 1) {
           pFx += vFantasmas[fantasma];
           pFy = centroY(y);
           
           fanPodeCima[fantasma] = mapaFantasmas[x][y-1] == 1;
           fanPodeBaixo[fantasma] = mapaFantasmas[x][y+1] == 1;
         }
       }
     }
     if (pacX - x <= 0){ // ir para a esquerda
       if (mapaFantasmas[x-1][y] == 1) {
         pFx -= vFantasmas[fantasma];
         pFy = centroY(y); 
         posFantasmas[fantasma][2] = 3;
       }
     } else {
       obstaculo[fantasma] = false;
       dirObstaculoFantasma[fantasma] = 0;
     }  
   } else { // dirObstaculoFantasma[fantasma] = 4  
     // enquanto houver um obstaculo a direita do fantasma
     if(mapaFantasmas[x+1][y] != 1) {
       // ir para cima ou para baixo ate deixar de existir um obstaculo a direita do fantasma
       if((mapaFantasmas[x][y-1] == 1) && (fanPodeCima[fantasma])) {  // ir para cima
         pFx = centroX(x); 
         pFy -= vFantasmas[fantasma];
       } else if ((mapaFantasmas[x][y+1] == 1) && (fanPodeBaixo[fantasma])) { // ir para baixo
         fanPodeCima[fantasma] = false;
         pFx = centroX(x); 
         pFy += vFantasmas[fantasma];
       } else {
         // ir para a esquerda ate ser possivel ir para cima ou para baixo
         if (mapaFantasmas[x][y-1] == 1) {
           pFx -= vFantasmas[fantasma];
           pFy = centroY(y);
           
           fanPodeCima[fantasma] = (mapaFantasmas[x][y-1] == 1);
           fanPodeBaixo[fantasma] = (mapaFantasmas[x][y+1] == 1);
         }
       }
     }
     if (pacX - x > 0){ // ir para a direita
       if (mapaFantasmas[x+1][y] == 1) {
         pFx += vFantasmas[fantasma];
         pFy = centroY(y); 
         posFantasmas[fantasma][2] = 4;
       }
     } else {
       obstaculo[fantasma] = false;
       dirObstaculoFantasma[fantasma] = 0;
     } 
   } 
     
 
   posFantasmas[fantasma][0] = pFx;
   posFantasmas[fantasma][1] = pFy;
}


/* Orienta o pacman de acordo com a direcao passada como argumento (0 = nao ha mudanca,
 * 1 = ir para cima, 2 = ir para baixo, 3 = ir para a esquerda, 4 = ir para a direita),
 * alterando as suas velocidades nos eixos x e y, bem como o alinhando 
 * quando ha mudancas de direcao
 */
void orientarPacman(int direction) { 
  int x = (int)(Math.round((px + 0.5 - margemH/2)/tamanho));
  int y = (int)(Math.round((py + 0.5 - margemV/2)/tamanho));
  
  // se o jogo estivar pausado, e uma tecla diretional 
  // tiver sido carregada, sair da pausa
  if ((direction != 0 ) && (pausa)) {
    vx = stopVel[0];
    vy = stopVel[1];
    vFantasmas[0] = 1.7; 
    vFantasmas[1] = 1.5; 
    vFantasmas[2] = 1.95; 
    vFantasmas[3] = 2.14;
    pausa = false;
  }
         
  // mudar a direcao do pacman, se for o caso       
  switch (direction) {
      
    case 1: // cima
      // ajustar as coordenadas se o pacman for para cima
      x = (int)(Math.round((px + 0.5 + margemH*3.3)/tamanho)); 
      y = (int)(Math.round((py + 0.5 + margemV*3.3)/tamanho));
      
      // check for collisons
      if ((y > 1) && (get((int)centroX(x), (int)centroY(y-1)) != corObstaculos)) {
        vx = 0;
        vy = -1 * (dificuldade + velExtra);
        px = centroX(x);
      } else {
        vx = 0;
        vy = 0;
      }
      break;
    case 2: // baixo
      if ((y < nLin) && (get((int)centroX(x), (int)centroY(y+1)) != corObstaculos)) {
        vx = 0;
        vy = 1 * (dificuldade + velExtra);
        px = centroX(x);
      } else {
        vx = 0;
        vy = 0;
      }
      break;
    case 3: // esquerda  
      // ajustar as coordenadas se o pacman estiver a ir para a esquerda
      x = (int)(Math.round((px + 0.5 + margemH*3.3)/tamanho)); 
      y = (int)(Math.round((py + 0.5 + margemV*3.3)/tamanho));
      
      if ((x > 1) && (get((int)centroX(x-1), (int)centroY(y)) != corObstaculos)) {
        vy = 0;
        vx = -1 * (dificuldade + velExtra);
        py = centroY(y); 
      } else {
        vx = 0;
        vy = 0;
      }
      break;
    case 4: // direita    
      if ((x < nCol) && (get((int)centroX(x+1), (int)centroY(y)) != corObstaculos)) { //
        vy = 0;
        vx = 1 * (dificuldade + velExtra);
        py = centroY(y); 
      } else {
        vx = 0;
        vy = 0;
      }
      break;
  }
 

  // ajustar posicao se o pacman for para cima ou para a esquerda
  if (vx < 0 || vy < 0) { 
    x = (int)(Math.round((px + 0.5 + margemH*3.3)/tamanho)); 
    y = (int)(Math.round((py + 0.5 + margemV*3.3)/tamanho));
  }

  // colisao com obstaculos sem haver mudanca de direcao
  if ((vy < 0) && (get((int)centroX(x), (int)centroY(y-1)) == corObstaculos) || 
      (vy > 0) && (get((int)centroX(x), (int)centroY(y+1)) == corObstaculos) ||
      (vx < 0) && (get((int)centroX(x-1), (int)centroY(y)) == corObstaculos) ||
      (vx > 0) && (get((int)centroX(x+1), (int)centroY(y)) == corObstaculos)) {
        vx = 0;
        vy = 0;
        px = centroX(x); 
        py = centroY(y); 
  }

  // colisao com margens
  if((px > centroX(nCol)) || (px < centroX(1))) {
    vx = 0;
    px = centroX(x); 
  } else if((py > centroY(nLin)) || (py < centroY(1))) {
    vy = 0;
    py = centroY(y); 
  }
}

/* Desenha os quatro fantasmas, tendo em atencao
 * a direcao para onde os olhos estam virados
 */
void desenharFantasmas() {
  
  for (int i = 0; i < fantasmas; i++) {
    if (!fantasmaComido[i]) {
      fill(corFantasmas[i]);
      float raioFant = pRaio/3.0;
      posFantasmas[i][1] -= 3.5; // fazer o fantasma mais "alto" que o pacman
      
      // desenhar corpo do fantasma
      ellipse(posFantasmas[i][0], posFantasmas[i][1], pRaio, pRaio);
      rect(posFantasmas[i][0] - pRaio/2.0, posFantasmas[i][1], pRaio, pRaio/1.5);
      
      // desenhar cauda do fantasma, composta por 3 circulos
      ellipse(posFantasmas[i][0] - raioFant, posFantasmas[i][1] + pRaio/1.5, pRaio/3.0, pRaio/3.0);
      ellipse(posFantasmas[i][0], posFantasmas[i][1] + pRaio/1.5, pRaio/3.0, pRaio/3.0);
      ellipse(posFantasmas[i][0] + raioFant, posFantasmas[i][1] + pRaio/1.5, pRaio/3.0, pRaio/3.0);
      
      
      // adicionar olhos ao fantasma
      fill (255);
      ellipse(posFantasmas[i][0] - pRaio/4.2, posFantasmas[i][1], pRaio/3, pRaio/2.5);
      ellipse(posFantasmas[i][0] + pRaio/4.2, posFantasmas[i][1], pRaio/3, pRaio/2.5);
      
      // adicionar iris
      fill(88, 135, 211);
      float tamanhoIris = pRaio/5;
      switch ((int)Math.round(posFantasmas[i][2])) {
        case 1: // fantasma a andar para cima
          ellipse(posFantasmas[i][0] - pRaio/4.2, posFantasmas[i][1] - pRaio/8, tamanhoIris, tamanhoIris);
          ellipse(posFantasmas[i][0] + pRaio/4.2, posFantasmas[i][1] - pRaio/8, tamanhoIris, tamanhoIris);
          break;
        case 2: // fantasma a andar para baixo
          ellipse(posFantasmas[i][0] - pRaio/4.2, posFantasmas[i][1] + pRaio/8, tamanhoIris, tamanhoIris);
          ellipse(posFantasmas[i][0] + pRaio/4.2, posFantasmas[i][1] + pRaio/8, tamanhoIris, tamanhoIris);
          break;
        case 3: // fantasma a andar para a esquerda
          ellipse(posFantasmas[i][0] - pRaio/4.2 - pRaio/10, posFantasmas[i][1], tamanhoIris, tamanhoIris);
          ellipse(posFantasmas[i][0] + pRaio/4.2 - pRaio/10, posFantasmas[i][1], tamanhoIris, tamanhoIris);
          break;
        case 4: // fantasma a andar para a direita
          ellipse(posFantasmas[i][0] - pRaio/4.2 + pRaio/10, posFantasmas[i][1], tamanhoIris, tamanhoIris);
          ellipse(posFantasmas[i][0] + pRaio/4.2 + pRaio/10, posFantasmas[i][1], tamanhoIris, tamanhoIris);
          break;
      }
      posFantasmas[i][1] += 3.5; // compensar o ajuste da altura do fantasma
    }
  }
}

/* Remove os pontos brancos (comida) do mapa se o pacman lhes tocar */
void comerPontos() {
  int x = (int)(Math.round((px + 0.5 - margemH)/tamanho));
  int y = (int)(Math.round((py + 0.5 - margemV/2)/tamanho));

  // ajustar as coordenadas se o pacaman estiver a ir para cima ou para a esquerda
  if (vx < 0 || vy < 0) { 
    x = (int)(Math.round((px + 0.5 + margemH*3.3)/tamanho)); 
    y = (int)(Math.round((py + 0.5 + margemV*3.3)/tamanho));
  } else if (vx > 0) {
    x = (int)(Math.round((px + 0.5 - margemH/2)/tamanho + 0.23));
  }

  color c = get((int)centroX(x), (int)centroY(y));
  
  // se for comida (ponto branco), comer
  if (c == color(255, 255 , 255)) {  
    if (mapaComida[x-1][y-1] == 1) {
      mapaComida[x-1][y-1] = 0;
      contadorComida--;
      
        // subir pontuacao
        pontuacao += 100 * (5/dificuldade);
        
        // verificar se o jogo foi ganho
        if (contadorComida == 0) {
          ganhar();
        }
    }
  }     
        


}

/* Desenha o pacman - recebe um boolean - verdadeiro 
 * se o pacman anda da esquerda para a direita, falso
 * se o pacman anda da direita para esquerda
 */
void desenharPacman() {
  fill(corPacman);
  ellipseMode(CENTER);
  noStroke();
  if (vy == 0) {
    if (vx > 0) {
      // arco entre PI/4.0 and PI*7/4.0
      arc(px, py, pRaio, pRaio, map(abs(sin(px * PI/50)), 0, 1, PI/4.0, 0), map(abs(sin(px * PI/50)), 0, 1, PI*7/4.0, PI*2), PIE);
    } else {
      // arco entre -PI*3/4.0 and PI*3/4.0
      arc(px, py, pRaio, pRaio, map(abs(sin(px * PI/50)), 0, 1, -PI, -PI*3/4.0), map(abs(sin(px * PI/50)), 0, 1, PI, PI*3/4.0), PIE);
    }
  } else if (vy > 0) {
    // arco entre -PI*5/4.0 and PI/4.0
    arc(px, py, pRaio, pRaio, map(abs(sin(py * PI/50)), 0, 1, -PI*3/2.0, -PI*5/4.0), map(abs(sin(py * PI/50)), 0, 1, PI/2.0, PI/4.0), PIE);
  } else { // vy < 0
    // arco entre -PI/4.0 and PI*5/4.0
    arc(px, py, pRaio, pRaio, map(abs(sin(py * PI/50)), 0, 1, -PI/2.0, -PI/4.0), map(abs(sin(py * PI/50)), 0, 1, PI*3/2.0, PI*5/4.0), PIE);
  }
}

/* Desenha o ecra do jogo (o fundo e os obstaculos) */
void desenharLabirinto () {

  // desenha a fronteira da área de jogo
  fill(0);
  stroke(80, 60, 200);
  strokeWeight(espacamento);
  rect(margemH, margemV, width - 2*margemH, height - 2*margemV);

  // Desenha obstáculos
  if (dificuldade == facil) { // mapa facil
    desenharObstaculo(2, 2, 3, 1);
    desenharObstaculo(6, 2, 3, 1);
    desenharObstaculo(10, 2, 3, 1);
    desenharObstaculo(2, 4, 5, 1);
    desenharObstaculo(8, 4, 6, 1);
    desenharObstaculo(7,6, 1, 1);
    desenharObstaculo(2,6, 3, 2);
    desenharObstaculo(2,9, 6, 1);
    desenharObstaculo(9,6, 1, 4);
    desenharObstaculo(11, 6, 1, 1);
    desenharObstaculo(11, 9, 1, 1);
    desenharObstaculo(13, 6, 1, 4);
  }  else if (dificuldade == medio) {
    // mapa medio
    desenharObstaculo(5, 4, 6, 1);
    desenharObstaculo(3, 2, 4, 1);
    desenharObstaculo(3, 2, 1, 2);
    desenharObstaculo(9, 2, 4, 1);
    desenharObstaculo(12, 2, 1, 2);
    desenharObstaculo(2, 6, 5, 1);
    desenharObstaculo(2, 5, 1, 2);
    desenharObstaculo(9, 6, 5, 1);
    desenharObstaculo(13, 5, 1, 2);
    desenharObstaculo(7, 8, 2, 1);
    desenharObstaculo(2, 8, 2, 1);
    desenharObstaculo(2, 8, 1, 2);
    desenharObstaculo(12, 8, 2, 1);
    desenharObstaculo(13, 8, 1, 2);
    desenharObstaculo(5, 10, 6, 1);
    desenharObstaculo(5, 9, 1, 2);
    desenharObstaculo(10, 9, 1, 2);
  }  else {
    // mapa dificil
    desenharObstaculo(2, 2, 5, 1);
    desenharObstaculo(13, 2, 1, 1);
    desenharObstaculo(8, 2, 4, 1); 
    desenharObstaculo(3, 4, 1, 3);
    desenharObstaculo(5, 4, 1, 5);
    desenharObstaculo(8, 4, 1, 3);
    desenharObstaculo(2, 8, 2, 1);
    desenharObstaculo(1, 4, 1, 3);
    desenharObstaculo(7, 8, 5, 1);
    desenharObstaculo(2, 10, 12, 1);
    desenharObstaculo(13, 6, 1, 3);
    desenharObstaculo(11, 6, 3, 1);
    desenharObstaculo(10, 4, 4, 1); 
  }
  
}

/* Desenha um obstáculo interno de um labirinto:
 * x: índice da célula inicial segundo eixo dos X - gama (1..nCol) 
 * y: índice da célula inicial segundo eixo dos Y - gama (1..nLin)
 * numC: nº de colunas (células) segundo eixo dos X (largura do obstáculo)
 * numL: nº de linhas (células) segundo eixo dos Y (altura do obstáculo) 
 */
void desenharObstaculo(int x, int y, int numC, int numL) {
  float x0, y0, larg, comp;
  
  x0 = margemH + (x-1) * tamanho;
  y0 = margemV + (y-1) * tamanho;
  larg = numC * tamanho;
  comp = numL * tamanho;

  fill(corObstaculos);
  noStroke();
  strokeWeight(espacamento/2);
  rect(x0, y0, larg, comp);
}

/* Desenhar pontos nas células vazias (que não fazem parte de um obstáculo). 
 * Esta função usa a cor de fundo no ecrã para determinar se uma célula está 
 * vazia ou se faz parte de um obstáculo.
 */
void desenharPontos() {
  ellipseMode(CENTER);
  fill(255);
  noStroke();

 
  // se o ponto esta no array, desenhar
  for (int i = 0; i < nCol; i++) {
    for (int j = 0; j < nLin; j++) {
      if (mapaComida[i][j] == 1) {
        ellipse(centroX(i+1), centroY(j+1), pRaio/2, pRaio/2);
      }
    }
  }
}

// transformar o índice de uma célula em coordenada no ecrã
float centroX(int col) {
  return margemH + (col - 0.5) * tamanho;
}

// transformar o índice de uma célula em coordenada no ecrã
float centroY(int lin) {
  return margemV + (lin - 0.5) * tamanho;
}

/* Faz o reset de todas as pontuacoes guardadas, ficando todas a 0 */
void resetScores() {
  try {
        // abrir ficheiro
        File fout = new File("highscores.txt");
        if(fout.exists()){          
          PrintWriter fileOut = new PrintWriter(fout);
          // fazer um overwrite com uma string vazia, que o jogo depois
          // interpretara como todos os scores serem 0
          fileOut.write(""); 
          fileOut.close();
        }
      } catch (IOException e){
        e.printStackTrace();
      }
}