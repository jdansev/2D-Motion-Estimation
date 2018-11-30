import processing.video.*;

Movie omovie;
int frameNumber = 1;
int nFrames;
int phase = 1;

String inputPath = "binaryenhanced/";
String outputPath = "monkeytracked/";

void setup() {
  size(568, 320);
  //frameRate(10);

  File dir = new File(sketchPath("") + inputPath);
  
  nFrames = dir.list().length-1;
  println(str(nFrames) + " files");
}


void draw() {
  String savePath;

  if (frameNumber >= nFrames) {
    exit();
  }

  PImage oimg = loadImage(sketchPath("") + inputPath + nf(frameNumber, 4) + ".tif");
  
  background(color(128));
  image(oimg, 0, 0);
  
  drawSegments(oimg);

  savePath = outputPath + nf(frameNumber, 4) + ".tif";
  //img.save(sketchPath("") + savePath);
  
  saveFrame(sketchPath("") + savePath);
  
  // draw text
  textSize(16);
  fill(0,255,0); // yellow
  text(String.format("Phase: %d", phase), 20, 40);
  text(String.format("Frame: %d/%d", frameNumber, nFrames), 20, 60);
  
  frameNumber++;
}



void drawSegments(PImage oimg) {
  
  int paddingOffset = 8;
  
  int[] constraints = segmentFrame(oimg);
  int minx = constraints[0];
  int miny = constraints[1];
  int maxx = constraints[2];
  int maxy = constraints[3];
  
  int rangex = maxx - minx;
  int rangey = maxy - miny;
  
  noFill();
  
  // bounding box
  stroke(255,0,0);
  rectMode(CORNER);
  rect(minx, miny, rangex, rangey);
  
  // left arm
  stroke(0,255,0);
  rectMode(CORNER);
  rect(minx, miny, rangex/2-paddingOffset, rangey/2-paddingOffset);
  
  // right arm
  stroke(0,0,255);
  rectMode(CORNER);
  rect(minx+rangex/2+paddingOffset, miny, rangex/2-paddingOffset, rangey/2-paddingOffset);
  
  // left foot
  stroke(0,255,255);
  rectMode(CORNER);
  rect(minx, miny+rangey/2+paddingOffset, rangex/2-paddingOffset, rangey/2-paddingOffset);
  
  // right foot
  stroke(255,0,255);
  rectMode(CORNER);
  rect(minx+rangex/2+paddingOffset, miny+rangey/2+paddingOffset, rangex/2-paddingOffset, rangey/2-paddingOffset);
  
  // body
  stroke(255,255,0);
  rectMode(CORNER);
  rect(minx+rangex/4, miny+rangey/4, rangex/2, rangey/2);
  
  
  
}

int[] segmentFrame(PImage oimg) {
  int minx = oimg.width;
  int miny = oimg.height;
  int maxx = 0;
  int maxy = 0;
  
  for (int y = 0; y < oimg.height; y++) {
    for (int x = 0; x < oimg.width; x++) {
      
      int loc = x + y * oimg.width;
      int p = oimg.pixels[loc];
      float gs = 0.212671 * red(p) + 0.715160 * green(p) + 0.072169 * blue(p);
      
      if (gs == 255) {
        if (x < minx) minx = x;
        if (x > maxx) maxx = x;
        if (y < miny) miny = y;
        if (y > maxy) maxy = y;
      }
      
    }
  }

  return new int[] { minx, miny, maxx, maxy };
}



void movieEvent(Movie m) {
  m.read();
}
