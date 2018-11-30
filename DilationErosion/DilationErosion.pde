import processing.video.*;

Movie omovie;
int frameNumber = 1;
int nFrames;
int phase = 1;

String inputPath = "binaryframes/";
String outputPath = "binaryenhanced/";

// square 5
//int kernelSize = 5;
//int[][] kernel = {{1,1,1,1,1},
//                  {1,1,1,1,1},
//                  {1,1,1,1,1},
//                  {1,1,1,1,1},
//                  {1,1,1,1,1}};

// cross
int kernelSize = 3;
int[][] kernel = {{0,1,0},
                  {1,1,1},
                  {0,1,0}};

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
  
  PImage img = dilateErode(oimg, 0, 1); // opening (erosion)
  img = dilateErode(img, 255, 1); // closing (dilation)
  
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


PImage dilateErode(PImage oimg, int dilateValue, int n) {
  color[] op;
  color[] np = new int[oimg.pixels.length];
  
  for (int i = 0; i < n; i++) {
    
    op = (i == 0) ? oimg.pixels : np;
    np = new int[oimg.pixels.length];
    
    int radius = (int) kernelSize/2;
    
    for (int y = radius; y < oimg.height-radius; y++) {
      for (int x = radius; x < oimg.width-radius; x++) {
        
        boolean isDia = false;
  
        for (int ix = x - radius, kx = 0; kx < kernelSize; ix++, kx++) {
          for (int iy = y - radius, ky = 0; ky < kernelSize; iy++, ky++) {
  
            // when the there is pixel with dilateValue in bound, make the current pixel dilateValue
            if (red(op[iy * oimg.width + ix]) == dilateValue && kernel[kx][ky] == 1) {
              np[y * oimg.width + x] = color(dilateValue);
              isDia = true;
              break;
            }
            else {
              np[y * oimg.width + x] = op[y * oimg.width + x];
            }
  
          }
          if (isDia == true) break;
        }
        
      }
    }
    
  }
  
  PImage newImg = new PImage(oimg.width, oimg.height);
  newImg.pixels = np;
  return newImg;
}
