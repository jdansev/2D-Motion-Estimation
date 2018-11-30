import processing.video.*;

import ddf.minim.*;

Minim minim;
AudioPlayer song;

Character c;
 
void setup()
{
  size(1280, 720);
 
  minim = new Minim(this);
 
  // this loads mysong.wav from the data folder
  song = minim.loadFile("drum.wav");
  song.play();
  song.loop();
  
  c = new Character();
}
 
void draw()
{
  
  background(255);
  
  int bx = width/2;
  int by = height/2;
  
  c.drawArm(bx+100, by-100);
  c.drawArm(bx-100, by-100);
  c.drawLeg(bx-100, by+100);
  c.drawLeg(bx+100, by+100);
  c.drawBody(bx, by);
  c.drawHead();
  
}



class Character {
  
  int bodySize = 50;
  int headSize = 50;
  int armWidth = 15;
  int footSize = 15;
  color bodyColor = color(255,0,0);
  
  int bx, by;
  
  void drawBody(int bx, int by) {
    this.bx = bx;
    this.by = by;
    
    strokeWeight(2);
    stroke(color(0));
    fill(bodyColor);
    rectMode(CENTER);
    pushMatrix();
    translate(bx, by);
    rect(0, 0, bodySize, bodySize);
    popMatrix();
  }
  
  void drawHead() {
    strokeWeight(2);
    stroke(color(0));
    fill(color(255,0,0));
    ellipseMode(CENTER);
    ellipse(bx, by-bodySize, headSize,headSize);
  }
  
  void drawArm(int x, int y) {
    strokeCap(ROUND);
    strokeWeight(armWidth);
    stroke(color(0,0,255));
    line(bx, by, x, y);
    noStroke();
    fill(bodyColor);
    ellipse(x, y, armWidth, armWidth);
  }
  
  void drawLeg(int x, int y) {
    strokeCap(ROUND);
    strokeWeight(footSize);
    stroke(color(128));
    line(bx, by, x, y);
    noStroke();
    fill(0);
    rect(x, y, footSize, footSize);
  }
  
}




boolean toggle = true;

void mouseClicked() {
  if (mouseButton == LEFT) {
    
    if (toggle) {
      song.pause();
      toggle = false;
    }
    else {
      song.play();
      toggle = true;
      
    }
    
  } else if (mouseButton == RIGHT) {
    song.rewind();
  }
}
