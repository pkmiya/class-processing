// Pbulicized for GitHub
// pkmiya@All rights reserved.

// Assignment_05
// World clock

PVector Orig;        // Stores origin coordinates of clock - centre of display -
int h, m, s;         // get hour, minute, second at current time

int oldsec;
int sepFrame;

int delta;

int lag = 0;
int lagmode = 0;
// Sub two clocks never changes, only the main changes corresponding the key pressed
// Time lag of each time line against JST:
//   JST(Japan standard time), UTC(Universal time coordinated): JST-9, EDT(Eastern daylight time): JST-13, 
//   CET(Central European time)[For france etc.]: JST-8, ICT[Indochina time]: JST-2

// lagmode - 0: JST, 1: CET, 2: ICT;

int bgmode = 0;        // background mode - 0: gray, 1: blue, 2: red
int textmode = 1;      // digital display of time - 0: white, 1: black
String timezone[] = {"JST", "CET", "ICT"};

int helpmode = 1;     // left click to toggle help - 1: shows help, 0: not show 

int gamemode = 0;

PFont font, dfont;

int H = 150, S = 30, B = 99; // set color in HSB

void setup() {
  // size(640, 480);
  size(800, 600);
  Orig = new PVector(width/2, height/2);
  
  font = createFont("HGS創英角ﾎﾟｯﾌﾟ体", 30);
  dfont = createFont("Arial", 30);
}

void draw() {
  
  colorMode(HSB, 360, 100, 100);
  background(H, S, B);
  
  colorMode(RGB, 256);
  
  h=hour();
  m=minute();
  s=second();
  
  textFont(font, 20);
  textAlign(RIGHT, TOP);
  textSize(20);
  text("Maybe multifunctional clock", width - 4, 0);
  textFont(dfont, 20);
  text(nf(h, 2) + ":" + nf(m, 2) + ":" + nf(s, 2) + ", " + year() + "/" + nf(month(), 2) + "/" + nf(day(), 2), width, 25);
  
  // Separate frame if different from second 1 frame ago
  if(s != oldsec) sepFrame = frameCount;
  // Record the second one frame ago
  oldsec = s;
  delta = frameCount - sepFrame;
  

  
  // Display clock frames and dial
  drawDial(height*0.38, Orig);
  drawDial(height*0.12, new PVector(width/2.6, height/2.75));
  drawDial(height*0.08, new PVector(width/1.6, height/2.75));
  
  // Draw points for each time
  drawHand(height*0.38, Orig, h+lag, m, s);
  drawHand(height*0.12, new PVector(width/2.6, height/2.75), h-9, m, s);
  drawHand(height*0.08, new PVector(width/1.6, height/2.75), h-13, m, s);

  
  // Display in digital
  if(textmode == 0){}
  else if(textmode == 1) fill(0);
  
  
  dispTime(LEFT, 4, 5, 35,  "Main", lag, timezone[lagmode]);
  dispTime(RIGHT, width - 4, 5, 25, "Sub right", 9, "UTC");
  dispTime(RIGHT, width - 4, 55, 25, "Sub left", 13, "EDT");
  
  
  if(helpmode == 0){}
  else if(helpmode == 1) {
    textAlign(LEFT, TOP);
    textSize(25);
    text("Left-click to toggle help", 4, 0);
    
    textSize(15);
    text("Appearance changes    - ←→ to change hue, ↑↓ to change saturation", 6, 30);
    text("Time lag on main clock - 1: JST, 2: CET, 3: ICT", 6, 50);
  }
  
  // Display time in text
  //print(nf(h, 2)+":"+nf(m, 2)+":"+nf(s, 2)+"   ");
  // Display passed frames from separating frame in console
  //println(delta);
  
  if(gamemode == 1){
    H = (H + 4) % 360;
    colorMode(HSB, 360, 100, 100);
    fill(H+50, S, B);
    text("!!!GAMING MODE!!!", width, 60);
  }
  //if(s%10==5 && delta-sepFrame==20) save("3MI38-04-1.PNG");
}

// Display all clock frame - with size mag, centered at Orig
void drawDial(float mag, PVector Orig){  
  pushMatrix();
  translate(Orig.x, Orig.y);
  
  stroke(0);
  fill(255);
  strokeWeight(2);
  circle(0, 0, mag*2);
  
  for(int deg = 0; deg < 360; deg += 6){
    if(deg % 90 == 0){
      strokeWeight(2);
      drawLine(deg, mag * 0.90, mag);
      if(mag == height * 0.38){
        fill(0);
        drawDialText(deg / 30, deg, mag * 0.80);
      }
    }
    else if(deg % 30 == 0){
      strokeWeight(1);
      drawLine(deg, mag * 0.92, mag);
    }
    else{
      strokeWeight(1);
      drawLine(deg, mag * 0.95, mag);
    }
  }
  popMatrix();
}

// Display hand at hh:mm:ss - with size mag, centered at Orig
void drawHand(float mag, PVector Orig, float h, float m, float s){
  pushMatrix();
  translate(Orig.x, Orig.y);
  
  stroke(0);
  strokeWeight(2);
  drawLine(h*30.0, -0.1*mag, mag*0.5);   // display hour hand
  stroke(0);
  strokeWeight(2);
  drawLine(m*6.0, -0.1*mag, mag*0.7);  // display minute hand
  
  stroke(255, 0, 0);
  strokeWeight(1);
  drawLine(s*6.0+delta*0.1, -0.1*mag, mag*0.8);    // display second hand
  
  popMatrix();
}

void drawLine(float deg, float len1, float len2) {
  PVector vec1, vec2;
  vec1=new PVector(0, -len1);  // starting point
  vec1.rotate(radians(deg));
  vec2=new PVector(0, -len2);  // ending point
  vec2.rotate(radians(deg));
  line(vec1.x, vec1.y, vec2.x, vec2.y);
}

void drawDialText(int h, float deg, float len1) {
  PVector vec;
  vec = new PVector(0, -len1);
  vec.rotate(radians(deg));
  textAlign(CENTER, CENTER);
  textSize(35);
  if(h == 0) h = 12;
  text(h, vec.x, vec.y - 5);
  
}

void dispTime(int xAlign, int x, int y, int fSize, String clockType, int hour, String tZone){  // y: relative value, subtraction to height
  
  int h_a;
  
  textAlign(xAlign, BASELINE);
  
  if((h - hour) < 0) h_a = 24 + (h - hour);
  else h_a = h - hour;
  
  textSize(fSize - 10);
  text(clockType + " clock time:", x, height - (y + fSize + 5));
  textSize(fSize);
  text(nf(h_a, 2) + ":" + nf(m, 2) + ":" + nf(s, 2) + ", " + tZone, x, height - y);
  
}

void mousePressed(){
  if(mouseButton == LEFT){
    helpmode = (helpmode + 1) % 2; // toggle help
  }
  else if(mouseButton == CENTER){
    gamemode = (gamemode + 1) % 2;
  }
  else if(mouseButton == RIGHT){
    textmode = (textmode + 1) % 2; // toggle text color
  }
}

void keyPressed(){
  if(key == '1'){
    lag = 0;  // JST
    lagmode = 0;
  }
  else if(key == '2'){
    lag = -8; // CET
    lagmode = 1;
  }
  else if(key == '3'){
    lag = -2; // ICT
    lagmode = 2;
  }
  
  // Adjusting hue (色相) and saturation (彩度)
  if(keyCode == LEFT) H = (H + 10) % 360;
  else if(keyCode == RIGHT)H = (H - 10) % 360;
  if(H < 0) H = 350;
  
  if(keyCode == UP) S = S + 5;
  else if(keyCode == DOWN) S = S - 5;
  if(S < 0) S = 0;
  else if(S > 100) S = 100;
}

// EOF