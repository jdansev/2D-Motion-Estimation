import processing.video.*;

Movie omovie;
int frameNumber = 1;
int phase = 1;
String outputPath = "extractedframes/";

void setup() {
  size(1280, 720);
  omovie = new Movie(this, sketchPath("monkey.mov"));
  omovie.play();
  
  textSize(16);
  fill(0,255,0); // yellow
  
  frameRate(30);
}


void draw() {
  
  float time = omovie.time();
  float duration = omovie.duration();
  float progress = 100 * time / duration;
  
  String savePath;
  
  if (phase == 1) {
    
    if (time >= duration) {
      exit();
    }
    
    image(omovie, 0, 0, width, height);
    
    savePath = outputPath + nf(frameNumber, 4) + ".tif";
    
    text(String.format("Phase: %d", phase), 20, 40);
    text(String.format("Frame: %d", frameNumber), 20, 60);
    text(String.format("Progress: %.2f%%", progress), 20, 80);
    text(String.format("Saving to " + savePath), 20, 100);
    
    
    omovie.save(sketchPath("") + savePath);
    
  }
  
  frameNumber++;
}

void movieEvent(Movie m) {
  m.read();
}
