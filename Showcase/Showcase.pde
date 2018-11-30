import processing.video.*;

int frameNumber = 1;
int nFrames;
int phase = 1;

String inputPath = "binaryenhanced/";
String outputPath = "monkeytracked/";

String stage1 = "extractedframes/";
String stage2 = "binaryframes/";
String stage3 = "binaryenhanced/";
String stage4 = "monkeytracked/";
String stage5 = "motiontracked/";
String stage6 = "final/";

int h = 220;
float ratio  = 1.775;

void setup() {
  //size(568, 320);
  // ratio: 1.775
  //size(1136, 640);
  size(1171, 440);
  frameRate(24);
  
  File stage1dir = new File(sketchPath("") + stage1);
  nFrames = stage1dir.list().length-1;
  println(str(nFrames) + " files");

}


void draw() {
  if (frameNumber >= nFrames-2) {
    frameNumber = 1;
    //exit();
  }
  
  // draw text
  textSize(12);
  fill(255, 255, 0); // yellow

  PImage img1 = loadImage(sketchPath("") + stage1 + nf(frameNumber, 4) + ".tif");
  PImage img2 = loadImage(sketchPath("") + stage2 + nf(frameNumber, 4) + ".tif");
  PImage img3 = loadImage(sketchPath("") + stage3 + nf(frameNumber, 4) + ".tif");
  PImage img4 = loadImage(sketchPath("") + stage4 + nf(frameNumber, 4) + ".tif");
  PImage img5 = loadImage(sketchPath("") + stage5 + nf(frameNumber, 4) + ".tif");
  PImage img6 = loadImage(sketchPath("") + stage6 + nf(frameNumber, 4) + ".tif");
  
  
  
  image(img1, h*ratio*0, h*0, h*ratio, h);
  text("Original", h*ratio*0+20, height/2-10);
  
  image(img2, h*ratio*1, h*0, h*ratio, h);
  text("Binary", h*ratio*1+20, height/2-10);
  
  image(img3, h*ratio*2, h*0, h*ratio, h);
  text("Eroded/dilated", h*ratio*2+20, height/2-10);
  
  image(img4, h*ratio*0, h*1, h*ratio, h);
  text("Segmented", h*ratio*0+20, height-10);
  
  image(img5, h*ratio*1, h*1, h*ratio, h);
  text("Motion tracked", h*ratio*1+20, height-10);
  
  image(img6, h*ratio*2, h*1, h*ratio, h);
  text("Final", h*ratio*2+20, height-10);

  fill(0, 255, 0); // green
  text(String.format("Frame: %d/%d", frameNumber, nFrames), 20, 20);
  
  frameNumber++;
}



void movieEvent(Movie m) {
  m.read();
}
