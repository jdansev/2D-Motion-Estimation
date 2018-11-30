import processing.video.*; 
import java.util.*;
import Jama.*;

Movie omovie;
int frameNumber = 1;
int nFrames;
int phase = 1;

String inputPath = "binaryenhanced/";
String outputPath = "motiontracked/";


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
// Store the coordinates found by intensity thresholding
List<Double> coordListX = new ArrayList<Double>();
List<Double> coordListY = new ArrayList<Double>();

// Store the coordinates found by kalman filter
List<Double> coordListKX = new ArrayList<Double>();
List<Double> coordListKY = new ArrayList<Double>();



void setup() {
  size(568, 320);
  //size(1280, 720);
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
  println(oimg.width);
  println(oimg.height);
  
  /* KALMAN FILTER */
  
  // Get the initial state (object coordinates) from binary segmentation
  double [] coord = findObj(oimg, 128); // coord is the centre of mass

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
  
  image(oimg, 0, 0);
  
  fill(255,255,0);
  if (cMeasure.get(0, 0) < 0 || cMeasure.get(1, 0) < 0){
    text("Object missing by intensity thresholding", 10, 70); 
  }
  else {
    text("Object found by intensity thresholding", 10, 20);
    coordListX.add(coord[0]);
    coordListY.add(coord[1]);
  }
  
  coordListKX.add(qEstimate.get(0, 0));
  coordListKY.add(qEstimate.get(1, 0));
  
  
  // Draw segments to show the tracks
  
  // kalman filter
  stroke(color(0, 255, 0));
  for (int i = 0; i < coordListKX.size() - 2; i ++) {
    line(coordListKX.get(i).floatValue(), coordListKY.get(i).floatValue(),
         coordListKX.get(i + 1).floatValue(), coordListKY.get(i + 1).floatValue());
  }
  
  // Draw the tracked coordinate boxes on both frames
  drawMarker((int)qEstimate.get(0, 0), (int)qEstimate.get(1, 0), 10);
  
  savePath = sketchPath("") + outputPath + nf(frameNumber, 4) + ".tif";
  saveFrame(savePath);
  
  frameNumber++;
}

void drawMarker(int x, int y, int size) {
  
  noStroke();
  fill(255,0,0);
  ellipseMode(CENTER);
  ellipse(x, y, size, size);
  
}


// Find the object coordinate by averaging the foreground coordinates
double [] findObj(PImage frame, int threshold) {
  double xsum = 0;
  double ysum = 0;
  double ctr = 0;

    for (int x = 0; x < frame.width; x ++) {
      for (int y = 0; y < frame.height; y ++) {
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


void movieEvent(Movie m) {
  m.read();
}
