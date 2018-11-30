import processing.video.*;

Movie omovie;
int frameNumber = 1;
int nFrames;
int phase = 1;

String inputPath = "extractedframes/";
String outputPath = "binaryframes/";

int THRESHOLD = 240;

// square 5
int kernelSize = 5;
int[][] kernel = {{1,1,1,1,1},
                  {1,1,1,1,1},
                  {1,1,1,1,1},
                  {1,1,1,1,1},
                  {1,1,1,1,1}};

void setup() {
  size(1280, 720);

  File dir = new File(sketchPath("") + inputPath);
  
  nFrames = dir.list().length;
  println(str(nFrames) + " files");
  
  textSize(16);
  fill(0,255,0); // yellow
}


void draw() {
  
  String savePath;
  
  if (frameNumber >= nFrames) {
    exit();
  }
  
  PImage oimg = loadImage(sketchPath("") + inputPath + nf(frameNumber, 4) + ".tif");
  
  PImage img = binaryImage(oimg);
  
  image(oimg, width/2, 0, width/2, height/2);
  image(img, 0, 0, width/2, height/2);
  
  text(String.format("Phase: %d", phase), 20, 40);
  text(String.format("Frame: %d/%d", frameNumber, nFrames), 20, 60);
  
  savePath = outputPath + nf(frameNumber, 4) + ".tif";
  img.save(sketchPath("") + savePath);
  
  frameNumber++;
}

void movieEvent(Movie m) {
  m.read();
}


//int threshold = 130;
int threshold = 60;
int red = 233;
int green = 102;
int blue = 77;

PImage binaryImage(PImage oimg) {
  color[] op = oimg.pixels;
  color[] np = new int[oimg.pixels.length];
  int loc, p;
  
  for (int y = 0; y < oimg.height; y++) {
    for (int x = 0; x < oimg.width; x++) {
      // pixel location
      loc = x + y * oimg.width;
      p = op[loc];
      if ((red(p) < red+threshold && red(p) > red-threshold) && (green(p) < green+threshold && green(p) > green-threshold) && (blue(p) < blue+threshold) && blue(p) > blue-threshold) {
        np[loc] = color(255);
      } else {
        np[loc] = color(0);
      }
    }
  }
  
  PImage newImg = new PImage(oimg.width, oimg.height);
  newImg.pixels = np;
  return newImg;
}
