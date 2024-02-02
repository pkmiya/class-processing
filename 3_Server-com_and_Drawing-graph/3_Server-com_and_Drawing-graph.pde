// Publicized for GitHub
// pkmiya@All rights reserved.

// Development note
/*
  1) □ 温度や湿度のグラフ上に数値をわかりやすく表示，ON/OFFを切り替えられる
    具体的な内容： データ値表示機能を実装
      1.ラベルの位置にあたるデータ値(気温/湿度/気圧)を表示する
      2. データ表示機能は「E」キーで有効/無効が切り替え可能
  4) □ 平均，最低，最高温度などを計算して表示　（例：1日の平均を30日間連続表示）
    具体的な内容：最高/最低/平均値表示機能を実装
      1. 表示されているグラフ範囲におけるデータの最高/最低/平均値を分かりやすく表示(⇒y=定数で表示)
      2. この表示機能は「R」キーで有効/無効が切り替え可能
  6) □ その他ユニークな拡張を施した　（皆さんの工夫に期待）
    具体的な内容： グラフカラー変更機能を実装
      1. タイトルおよびグラフ(メモリではなくプロットエリア)のカラーを変更可能
      2. 「←/→」キーで彩度，「↑/↓」で明度を変更可能
      3. 「Q」キーで自動的にカラーをアニメーションで変更することができる(もう一度押すと停止)通称Gaming Modeを実装
      4. アニメーションスピードを「W/S」キーで調節可能

*/

// VER. 1.3.1

// Developed Application protocol for school private server

import processing.net.*;
Client cl;   // class and variable managing connection as client

import controlP5.*;
ControlP5 reloadButton;  // using button class
// ControlP5 stts;

import java.util.Date;              // date class
import java.text.SimpleDateFormat;  // class handling date format

int [] x;    // array willing to contain data of x-axis and y axis
float [] y1; // temperature
float [] y2; // humidity
float [] y3; // air pressure



int graphN = 144;           // No. of data to get from server
int m = 10;                 // get data per m [min]
int nlx = 8;                // No. of time label

int graph = 0;
int valueDisp = 1;          // Display each value or not
int polarDisp = 1;          

int H = 16; 
int S = 100;
int B = 100;

int autoColor = 0;
int speed = 5;

float N = 10;

boolean drawable = false;   // flag to determine whether drawable
// being used in reloadPressed() and draw()

String acct = "******";     // using each user's occt. and pw.
String pass = "******";

String stts[] = {"OFF", "ON"};

void setup() {
  size(800, 600);
  //size(640, 480);

  // connecting to server in port 8080
  x = new int[graphN];  // setting array to store data of graphN
  y1 = new float[graphN];
  y2 = new float[graphN];
  y3 = new float[graphN];

  // creating RELOAD button
  reloadButton = new ControlP5(this);
  reloadButton
    .addButton("reloadPressed")  // Name of function to be executed when button pressed
    .setLabel("RELOAD")          // label to display
    .setSize(80, 25)             // button size
    .setPosition(width-85, 5)    // button location
    .setColorForeground(color(#c0c0c0)) // button color when pointed out
    .setColorBackground(color(#808080)) // button color when not
    ;

  /*
  stts = new ControlP5(this);
  stts
    .addButton("sttsChange")
    .setLabel(sttsStr[sttsFlag])
    .setSize(80, 25)
    .setPosition(5, 5)
    .setColorForeground(color(#c0c0c0))
    .setColorBackground(color(#808080))
    ;
  */
}


// being false until receiving message from server
// use a gimmick by using the following flag to manage process
boolean recvOK;            // used in waitAndRecv() and clientEvent()

// flag being true when received 600 data from server
boolean drawOK=false;      // used in draw() and reloadPressed()

// flag being true when authorized successfully
boolean authOK;            // used in reloadPressed() and  clientEvent()

// used in clientEvent() and reloadPressed()
int dbN;              // No. of records of database received using info command info
int rcvEpoch;              // epoch time received using get()
float rcvTemperature;      // temperature received using get()
float rcvHumid;            // humidity received using get()
float rcvPress;            // pressure received using get()

// when the reload button is pressed
void reloadPressed() {
  authOK = false;            // Keeping flag false because of being unauthorized yet
  
  // connect to server
  cl = new Client(this, "XX.XX.XX.XX", 8080);
  if (!cl.active()) return;// exit if connection failed
  // send authentication info
  sendAndRecv("user "+acct+" "+pass);  // wait for resonse with sending auth. info
  if (!authOK || !recvOK) { // exit if authentication failed or no response
    cl.stop();
    return;
  }
  // ask for No. of record
  sendAndRecv("info"); // send info command and wait for response

  //graph = 72 * (int)N;

  for (int i = 0; i < graphN; i++) {
    // issue command to get 600 data
    //int recNo = ( dbN- 1 + (i + 1 - graph) * m);
    int recNo = ( dbN- 1 + (i + 1 - graphN) * (int)N);

    sendAndRecv("get " + recNo);  // send get command
    x[i] = rcvEpoch;         // store data in array x[], y[] as getting one record
    y1[i] = rcvTemperature;
    y2[i] = rcvHumid;
    y3[i] = rcvPress;
  }
  sendAndRecv("quit");     // send quit command and wait for response (1[ms]×1000 at max)
  cl.stop();
  drawOK = true;             // draw graph
}

// send message to server and wait for response
// used in reloadPressed()
void sendAndRecv(String mes) {
  // wait n [times] as chenking response per d[ms]
  // process as error if packet not returned untill waiting n times
  int d = 1, n = 1000;
  recvOK = false;            // flag being false - unreceived yet
  cl.write(mes + char(10));  // send command to serer
  for (int i = 0; i < n; i++) {
    delay(d);              // wait for a while
    if (recvOK) return;    // check whether received packet from server
    //print(i);            // can check and visualize waiting time by removing "//"
  }
  println("Timeout("+d*n+"[ms])"); // assume as an error when could not receive until waiting n times
}

// receive message from server
// developing application protocol which sepatates process by checking header of message
void clientEvent(Client cl) {
  // read reply from server
  String rmes=cl.readStringUntil(char(10)).trim();
  println(rmes);
  String [] str=rmes.split(" ");    // separate into strings at spaces
  if (str[0].equals("hello")) {
    // authorized successfully if header says hello
    authOK=true;
  } else if (str[0].equals("L")) {
    // contains numerical data of 24*2 if header says L
    for (int i=0; i<24; i++) {
      x[i]=int(str[i*2+1]);     // store into x[], y[] with converting float type
      y1[i]=float(str[i*2+2]);
    }
  } else if (str[0].equals("I")) {
    // contains No. of data, date, time, epoch time, date, time, epoch time...
    dbN=int(str[1]);
    println(rmes);
  } else if (str[0].equals("G")) {
    // contains date, time, epoch time temperature 1, humidity 1, pressure 1, tempereture 2, ...
    rcvEpoch=int(str[3]);     // returning epoch time, temperature, and so on for reloadPressed() function
    rcvTemperature=float(str[4]);
    rcvHumid = float(str[5]);
    rcvPress = float(str[8]);
    print(".");
  } else if (str[0].equals("bye")) {
    // quit successfully if header says bye
    println(char(10)+rmes);
  } else {
    println(rmes);   // show exeception message and errors
  }
  // notify waitTimer() that message processing has been done
  recvOK=true;
}


void draw() {
  background(0);
  

  textAlign(LEFT, CENTER);
  textSize(18);
  text("Last " + (int)N/10 + " days", 10, 50);
  textSize(16);
  textAlign(RIGHT, CENTER);
  text("H: " + H + ", S: " + S + ", B: " + B + ", latency: " + speed, 750, 50);
  
  colorMode(HSB, 100, 100, 100);
  fill(H, S, B);
  text("Gaming mode: " + stts[autoColor], 750, 550);
  textAlign(CENTER, TOP);
  textSize(32);
  text("Client", width/2, 0);
  
  colorMode(RGB, 256);
  fill(#ffffff);
  // text("N = " + N, 10, 20);
  // draw data using arrays x[], y[]
  if (drawOK) {
    textSize(18);
    textAlign(LEFT, TOP);
    text("Temperature", 40, 80);
    text("Humidity", 40, 280);
    text("Air pressure", 400, 80);

    // Calc max/min/avg graph here;
    if(autoColor == 1){
      H = (millis()/(10*speed)) % 100;
    }
    MyDrawGraph(x, y1, x[0], 0, x[graphN-1], 40, 80, 240, 340, 120, graphN/nlx, 0, 40, 10);
    MyDrawGraph(x, y2, x[0], 0, x[graphN-1], 100, 80, 480, 340, 320, graphN/nlx, 0, 100, 20);
    MyDrawGraph(x, y3, x[0], 900, x[graphN-1], 1050, 460, 480, 720, 120, graphN/nlx, 920, 1050, 20);

  }
}


// display graph with x-interval [rx1,rx2], and y-interval [ry1,ry2] onto screen with coordinate (sx1,sy1)-(sx2, sy2)
void MyDrawGraph(int [] xdata, float [] ydata,
  float rx1, float ry1, float rx2, float ry2, // original coordinate
  float sx1, float sy1, float sx2, float sy2, // screen coordinate
  int lx, // duration of x-axis label
  int ly1, int ly2, int ldy  // starting, ending, increment of y-axis label
  ) {
  float x0, y0, x1, y1;
  // tepmerature - y-axis scale

  float max, min;
  float max_1, min_1;
  float sum = 0.0;

  float avg = 0.0;
  float avg_1;

  strokeWeight(1);  // determines weight, color, edges of line
  stroke(#008000);  // mosgreen
  strokeCap(SQUARE);
  textSize(16);
  textAlign(RIGHT, CENTER);
  for (int ly=ly1; ly<=ly2; ly+=ldy) {
    y1=map(ly, ry1, ry2, sy1, sy2);
    line(sx1, y1, sx2, y1);
    text(ly, sx1, y1);
  }

  // time - x-axis scale
  textAlign(CENTER, TOP);
  for (int i=0; i<graphN; i++) {
    x0 = map(xdata[i], rx1, rx2, sx1, sx2);  // calculating starting point of line
    y0 = sy1; // map(0, ry1, ry2, sy1, sy2);
    if (i % lx == lx - 1) {
      text(getDateString(xdata[i], "HH"), x0, y0);
      line(x0, sy1, x0, sy2);
    }
  }

  // draws line graph
  colorMode(HSB, 100, 100, 100);
  float width = 2; // Fix line width as 2 abs(sx2 - sx1) / graphN * 0.7; calculating line width
  strokeWeight(width);
  stroke(H, S, B); // stroke(#FFFF00); // yellow  stroke(#0000ff);  blue
  strokeCap(SQUARE);
  float ox = 0, oy = 0;

  int dispPosition = 0;

  for (int i = 0; i < graphN; i++) {
    textSize(12);
    x1 = map(xdata[i], rx1, rx2, sx1, sx2);  // calculating ending point of line
    y1 = map(ydata[i], ry1, ry2, sy1, sy2);
    if(i != 0) line(ox, oy, x1, y1);
    ox = x1;
    oy = y1;

    if(valueDisp == 1){
      if(i % lx == lx -1) {
        if(dispPosition == 0){
          text((int)ydata[i], x1, y1 - 30);
          dispPosition = 1 - dispPosition;
        }
        else{
          text((int)ydata[i], x1, y1 + 10);
          dispPosition = 1 - dispPosition;
        }
      }
    }
  }


  colorMode(RGB, 256);
  if(polarDisp == 1){
    strokeWeight(2);
    textAlign(LEFT, CENTER);
    max = max(ydata);
    max_1 = max;
    max = map(max, ry1, ry2, sy1, sy2);
    stroke(#ff0000); // red
    line(sx1, max, sx2, max);
    text((int)max_1, sx2 + 5, max);

    min = min(ydata);
    min_1 = min;
    min = map(min, ry1, ry2, sy1, sy2);
    stroke(#0000ff);
    line(sx1, min, sx2, min);
    text((int)min_1, sx2 + 10, min);

    for(int cnt = 0; cnt < ydata.length; cnt++) sum += ydata[cnt];
    avg = sum / ydata.length;
    avg_1 = avg;
    avg = map(avg, ry1, ry2, sy1, sy2);
    stroke(#ffffff);
    line((float)sx1, avg, (float)sx2, avg);
    text((int)avg_1, sx2 + 8, avg);
  }

  // drawing x and y axis
  strokeWeight(3);
  stroke(#00ff00);  // green
  strokeCap(ROUND);
  line(sx1, sy1, sx2, sy1); // drawing x-axis
  line(sx1, sy1, sx1, sy2); // drawing y-axis
}


String getDateString(long epoch, String fmt) {
  SimpleDateFormat sdf = new SimpleDateFormat(fmt);
  return sdf.format(new Date(epoch*1000));
}

/*
void sttsChange(){
  sttsFlag = (sttsFlag + 1) % 5;

}
*/

void keyPressed() {
  if(key == '1') m += 10;
  else if(key == '2') m -= 10;

  if(m < 10) m = 10;
  else if(m > 300) m = 300;

  if(key == 'e') valueDisp = 1 - valueDisp;
  else if(key == 'r') polarDisp = 1 - polarDisp;

  // Adjusting hue and saturation
  if(keyCode == LEFT) H = (H - 2) % 100;
  else if(keyCode == RIGHT)H = (H + 2) % 100;
  if(H < 0) H = 100;
  
  if(keyCode == UP) S = S + 2;
  else if(keyCode == DOWN) S = S - 2;
  if(S < 0) S = 0;
  else if(S > 100) S = 100;

  if (key == 'q') autoColor = 1 - autoColor;

  if(key == 'w') speed += 1;
  else if(key == 's') speed -= 1;
  if(speed < 1) speed = 1;
}

void mouseWheel(MouseEvent event){
  float e = event.getCount();
  N = constrain(N + 10*e, 10, 300);
}
