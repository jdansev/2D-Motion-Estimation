import processing.video.*;
import java.util.*;
import Jama.*;
import ddf.minim.*;

Minim minim;
Movie omovie;
int frameNumber = 1;
int nFrames;
int phase = 1;

String inputPath = "binaryenhanced/";
String outputPath = "motiontracked/";

int tailLength = 10;

class KalmanFilter {
  color markerColour;
  
  //  -- Kalman Filter parameters
  float dt           = 1; // Our sampling rate
  double accNoiseMag = 0.1; // Process noise: the variability in how fast the Hexbug is speeding up (stdv of acceleration: meters/sec^2)
  double mNoiseX     = 1;
  double mNoiseY     = 1;
  double u = 0.005; // Define the acceleration magnitude
  Matrix qEstimate = new Matrix(new double [] {0, 0, 0, 0}, 4); // Initized state--it has four components: [positionX; positionY; velocityX; velocityY] of the hexbug
  
  Matrix Ez = new Matrix(new double[][] {{mNoiseX, 0.0}, {0.0, mNoiseY}}); // Noise covariance
  Matrix Ex = new Matrix(new double[][]{{pow(dt, 4.0)/4.0, 0.0, pow(dt, 3.0)/2.0, 0.0},
                    {0.0, pow(dt, 4.0)/4.0, 0.0, pow(dt, 3.0)/2.0},
                    {pow(dt, 3.0)/2.0, 0.0, pow(dt, 2.0), 0.0},
                    {0.0, pow(dt, 3.0)/2.0, 0.0, pow(dt, 2.0)}});
  Matrix P  = Ex.copy();
  
  // Define update equations in 2-D! (Coefficent matrices): A physics based model for where we expect the object to be [state transition (state + velocity)] + [input control (acceleration)]
  Matrix A        = new Matrix( new double [][] {{1, 0, dt, 0}, {0, 1, 0, dt}, {0, 0, 1, 0}, {0, 0, 0, 1}} ); // State update matrice
  Matrix B        = new Matrix(new double [] {pow(dt, 2)/2, pow(dt, 2)/2, dt, dt}, 4);
  Matrix C        = new Matrix(new double [][] {{1, 0, 0, 0}, {0, 1, 0, 0}}); // This is our measurement function C, that we apply to the state estimate Q to get our expect next/new measurement
  Matrix eye4     = new Matrix(new double [][] {{1,0,0,0}, {0,1,0,0}, {0,0,1,0}, {0,0,0,1}}); // 4X4 Identity matrix
  Matrix cMeasure = new Matrix(new double [] {0, 0}, 2); // The object coordinates obtained from brightness segmentation
  
  int foreground  = 250; // Foreground Threshold for Segmentation
  
  List<Double> coordListX = new ArrayList<Double>();
  List<Double> coordListY = new ArrayList<Double>();
  
  // Store the coordinates found by kalman filter
  List<Double> coordListKX = new ArrayList<Double>();
  List<Double> coordListKY = new ArrayList<Double>();
  
  public KalmanFilter(color c) {
    markerColour = c;
  }
  
  void findCoords(PImage oimg, int[] bounds) {
    // Get the initial state (object coordinates) from binary segmentation
    double [] coord = findObj(oimg, 128, bounds); // coord is the centre of mass
  
    cMeasure.set(0, 0, coord[0]);
    cMeasure.set(1, 0, coord[1]);
    qEstimate = A.times(qEstimate).plus(B.times(u));
  
    // Predict next covariance
    P = A.times(P).times(A.transpose()).plus(Ex);
  
    // Predicted measurement covariance
    // Kalman Gain
    Matrix K = P.times(C.transpose()).times(C.times(P).times(C.transpose()).plus(Ez).inverse());
  
    // Update the state estimate only when a valid segmentation tracking is available
    if (cMeasure.get(0, 0) > 0 && cMeasure.get(1, 0) > 0) {
      qEstimate = qEstimate.plus(K.times(cMeasure.minus(C.times(qEstimate))));
    }
  
    // Update covariance estimation
    P = eye4.minus(K.times(C)).times(P);
    
    fill(255,255,0);
    if (cMeasure.get(0, 0) < 0 || cMeasure.get(1, 0) < 0){
      //text("Object missing by intensity thresholding", 10, 20);
    }
    else {
      //text("Object found by intensity thresholding", 10, 20);
      coordListX.add(coord[0]);
      coordListY.add(coord[1]);
    }
    
    coordListKX.add(qEstimate.get(0, 0));
    coordListKY.add(qEstimate.get(1, 0));
    
  }
  
  void drawTrackPoints() {
    
    stroke(color(markerColour));
    
    int i = (coordListKX.size()-tailLength >= 0) ? coordListKX.size()-tailLength : 0;
    for (; i < coordListKX.size() - 1; i ++) {
      line(coordListKX.get(i).floatValue(), coordListKY.get(i).floatValue(),
           coordListKX.get(i + 1).floatValue(), coordListKY.get(i + 1).floatValue());
    }
    
    // Draw the tracked coordinate boxes on both frames
    drawMarker((int)qEstimate.get(0, 0), (int)qEstimate.get(1, 0), 10);
    
  }
  
  int getX() {
    double d = coordListKX.get(coordListKX.size()-1);
    return (int)d;
  }
  
  int getY() {
    double d = coordListKY.get(coordListKY.size()-1);
    return (int)d;
  }
  
  void drawMarker(int x, int y, int size) {
    noStroke();
    fill(markerColour);
    ellipseMode(CENTER);
    ellipse(x, y, size, size);
  }
  
  // Find the object coordinate by averaging the foreground coordinates
  double [] findObj(PImage frame, int threshold, int[] bounds) {
    int minx = bounds[0];
    int miny = bounds[1];
    int maxx = bounds[2];
    int maxy = bounds[3];
    double xsum = 0;
    double ysum = 0;
    double ctr = 0;
    for (int x = minx; x < maxx; x ++) {
      for (int y = miny; y < maxy; y ++) {
        int loc = x + frame.width * y;
        color c = frame.pixels[loc];
        if (red(c) > threshold) {
                xsum += x;
                ysum += y;
                ctr ++;
        }
      }
    }
    double xmean = 0, ymean = 0;
    if (ctr > 20){
      xmean = xsum / ctr;
      ymean = ysum / ctr;
    }
    else{
      xmean = -1;
      ymean = -1;
    }
    return new double [] { xmean, ymean };
  }
  
}



class Character {
  
  int bodySize = 60;
  int headSize = 50;
  int armWidth = 15;
  int footSize = 15;
  color sleeveColor = #E05850;
  color skinColor = #FFAD60;
  
  int bx, by;
  
  void drawBody() {
    rectMode(CENTER);
    pushMatrix();
    translate(bx, by);
    imageMode(CENTER);
    image(shirt, 0, 0, bodySize, bodySize);
    popMatrix();
    
  }
  
  void setBodyPos(int bx, int by) {
    this.bx = bx;
    this.by = by;
  }
  
  void drawHead() {
    strokeWeight(2);
    stroke(color(0));
    fill(color(255,0,0));
    
    pushMatrix();
    translate(bx, by);
    imageMode(CENTER);
    image(head, 0, -50, head.width/10, head.height/10);
    popMatrix();
    
    //ellipseMode(CENTER);
    //ellipse(bx, by-bodySize/2, headSize,headSize);
  }
  
  void drawArm(int x, int y) {
    strokeCap(ROUND);
    strokeWeight(armWidth);
    stroke(sleeveColor);
    line(bx, by, x, y);
    noStroke();
    fill(skinColor);
    ellipse(x, y, armWidth, armWidth);
  }
  
  void drawLeg(int x, int y) {
    strokeCap(ROUND);
    strokeWeight(footSize);
    stroke(80);
    line(bx, by, x, y);
    noStroke();
    fill(0);
    rectMode(CENTER);
    rect(x, y, footSize, footSize);
  }
  
}

AudioPlayer soundtrack;

KalmanFilter[] kf;
Character c;
PImage bg;
PImage shirt;
PImage head;

void setup() {
  size(568, 320);
  //size(1280, 720);
  frameRate(10);
  
  minim = new Minim(this);
  soundtrack = minim.loadFile("gonna-fly-now-bill-conti.mp3");
  soundtrack.play();
  soundtrack.loop();

  File dir = new File(sketchPath("") + inputPath);
  
  nFrames = dir.list().length-1;
  println(str(nFrames) + " files");
  
  kf = new KalmanFilter[5];
  kf[0] = new KalmanFilter(color(0,255,255)); // cyan
  kf[1] = new KalmanFilter(color(128,128,128)); // gray
  kf[2] = new KalmanFilter(color(0,255,0)); // green
  kf[3] = new KalmanFilter(color(128,0,255)); // purple
  kf[4] = new KalmanFilter(color(255,128,0)); // orange
  
  //kf[0] = new KalmanFilter(color(255,0,0)); // red
  //kf[1] = new KalmanFilter(color(255,0,0)); // red
  //kf[2] = new KalmanFilter(color(255,0,0)); // red
  //kf[3] = new KalmanFilter(color(255,0,0)); // red
  //kf[4] = new KalmanFilter(color(255,0,0)); // red
  
  bg = loadImage("gymnasium.jpg");
  shirt = loadImage("jersey.png");
  head = loadImage("denzel.png");
  
  c = new Character();
}


void draw() {
  String savePath;

  if (frameNumber >= nFrames) {
    frameNumber = 1;
    //exit();
  }

  PImage oimg = loadImage(sketchPath("") + inputPath + nf(frameNumber, 4) + ".tif");
  println(oimg.width);
  println(oimg.height);
  
  
  //image(oimg, 0, 0);
  
  background(0);
  
  imageMode(CORNER);
  image(bg, 0, 0,  width, height);
  
  drawSegments(oimg);

  savePath = sketchPath("") + outputPath + nf(frameNumber, 4) + ".tif";
  saveFrame(savePath);
  
  frameNumber++;
}






void drawSegments(PImage oimg) {
  
  int paddingOffset = 0;
  int xPoint, yPoint, xSize, ySize;
  
  int[] constraints = segmentFrame(oimg);
  
  // bounding box
  int minx = constraints[0];
  int miny = constraints[1];
  int maxx = constraints[2];
  int maxy = constraints[3];
  int rangex = maxx - minx;
  int rangey = maxy - miny;

  
  // left arm
  
  xPoint = minx;
  yPoint = miny;
  xSize = rangex/2-paddingOffset;
  ySize = rangey/2-paddingOffset;

  noFill();
  stroke(0,255,0);
  rectMode(CORNER);
  //rect(xPoint, yPoint, xSize, ySize);
  kf[0].findCoords(oimg, new int[] { xPoint, yPoint, xPoint+xSize, yPoint+ySize });
  
  
  // right arm
  
  xPoint = minx+rangex/2+paddingOffset;
  yPoint = miny;
  xSize = rangex/2-paddingOffset;
  ySize = rangey/2-paddingOffset;
  
  noFill();
  stroke(0,0,255);
  rectMode(CORNER);
  //rect(xPoint, yPoint, xSize, ySize);
  kf[1].findCoords(oimg, new int[] { xPoint, yPoint, xPoint+xSize, yPoint+ySize });
  
  
  
  // left foot
  
  xPoint = minx;
  yPoint = miny+rangey/2+paddingOffset;
  xSize = rangex/2-paddingOffset;
  ySize = rangey/2-paddingOffset;
  
  noFill();
  stroke(0,255,255);
  rectMode(CORNER);
  //rect(xPoint, yPoint, xSize, ySize);
  kf[2].findCoords(oimg, new int[] { xPoint, yPoint, xPoint+xSize, yPoint+ySize });
  
  
  
  // right foot
  
  xPoint = minx+rangex/2+paddingOffset;
  yPoint = miny+rangey/2+paddingOffset;
  xSize = rangex/2-paddingOffset;
  ySize = rangey/2-paddingOffset;
  
  noFill();
  stroke(255,0,255);
  rectMode(CORNER);
  //rect(xPoint, yPoint, xSize, ySize);
  kf[3].findCoords(oimg, new int[] { xPoint, yPoint, xPoint+xSize, yPoint+ySize });
  
  
  
  // body
  
  xPoint = minx+rangex/4;
  yPoint = miny+rangey/4;
  xSize = rangex/2;
  ySize = rangex/2;
  
  noFill();
  stroke(255,255,0);
  rectMode(CORNER);
  //rect(xPoint, yPoint, xSize, ySize);
  kf[4].findCoords(oimg, new int[] { xPoint, yPoint, xPoint+xSize, yPoint+ySize });
  
  
  // bounding box
  
  xPoint = minx;
  yPoint = miny;
  xSize = rangex;
  ySize = rangey;
  
  noFill();
  stroke(255,0,0);
  rectMode(CORNER);
  //rect(xPoint, yPoint, xSize, ySize);
  
  
  //render character to screen
  c.setBodyPos(kf[4].getX(), kf[4].getY());
  c.drawArm(kf[0].getX(), kf[0].getY()); // left arm
  c.drawArm(kf[1].getX(), kf[1].getY()); // right arm
  c.drawLeg(kf[2].getX(), kf[2].getY()); // left leg
  c.drawLeg(kf[3].getX(), kf[3].getY()); // right leg
  c.drawBody();
  c.drawHead();
  
  
  //kf[0].drawTrackPoints();
  //kf[1].drawTrackPoints();
  //kf[2].drawTrackPoints();
  //kf[3].drawTrackPoints();
  //kf[4].drawTrackPoints();

  
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
