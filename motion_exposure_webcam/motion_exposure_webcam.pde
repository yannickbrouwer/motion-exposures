/* Motion Exposures made by Yannick Brouwer
 
 Made with the ipCapture library by Stefano Baldan
 
 Used some code of the official processing Background Subtraction sketch by Golan Levin
 
 Use a MJPEG stream from a static webcam with decent framerate. Espescially older AXIS webcams work well.
 
 The software has 3 modes:
 Recording mode: The mode used when the software is started. It needs to be in this mode to record changes in movement.
 Source mode:  This mode is used to check the webcame image
 Result mode: This is the resulting motion exposure image. You can adjust the brightness using the key modifiers below.
 
 CONTROLS: 
 --------------
 (Make sure that the frame is active by clicking on it)
 
 'Spacebar' to switch between modes. It needs to be in recording mode in order to record from the public webcam.
 
 In Result mode:
 
 'A' key to turn on/off Auto Exposure
 
 'Up' and 'Down' key to increase/decrease the exposure
 
 'S' key to save the current image
 
 EXAMPLE STREAMS:
 --------------
 Place Monthey in Switzerland (800x600)
 http://213.221.150.11/cgi-bin/faststream.jpg
 
 Arjebolden in Sweden (1280x720)
 http://194.103.218.15/mjpg/video.mjpg
 
 */


// Libraries
import ipcapture.*;
import java.io.BufferedWriter;
import java.io.FileWriter;

IPCapture cam;

// Use the dimensions of your webcam stream as input for screenWith and screenHeight 
static final int screenWidth = 800;
static final int screenHeight = 600;

// 2-Dimensional array to save running total of activity
int[][] traces = new int[screenWidth][screenHeight];

// 2-Dimensional array to save final result after exposure correction
int[][] traceOutput = new int[screenWidth][screenHeight];

// What do these do?
int a = 0;
int b = 0;

// Used to save activity data in an external text file
PrintWriter output;

// Autobrightness maps the brightness pixel to 255 (white) and scales the rest accordingly
boolean autoBrightness = true;

// Running total of current brightest pixel used for autobrightness
int maxBrightness = 0;

// The thresshold determines whether a pixel changed enough between current and previous frame to become white and thus contained movement
int tresshold = 50;

// The multiplier is used to make the resulting image brighter or less bright. Higher than 1 is brighter, less than zero is less bright
float multiplier = 1.0;

// Counter to remove titles after a few seconds of switching between modes
long titleCounter = 0;

// numPixels is the amount of pixels in the frame (width * height of the webcamstream)
int numPixels;
int[] previousFrame;

// The following variables are used to create a unique name for each text file with activity data
String title = "monthey"; 
String filename;
int mi = minute();
int h = hour();
int d = day();
int m = month();
int y = year();

// movementSum is a running total of the amount of movement in a frame
int movementSum = 0; // Amount of movement in the frame

// mode is used to select which mode is running, recording, source and result mode
int mode = 0;

void setup() {
  // Make this same size as screenWidth and screenHeight
  size(800, 600);

  //Uncomment the following line for High-Density displays
  //pixelDensity(2);

  // Change the URL in the following line if you want to use a different webcam stream
  cam = new IPCapture(this, "http://213.221.150.11/cgi-bin/faststream.jpg", "", "");
  cam.start();

  // Create an external text file to save the amount of movement
  filename = y + "_" + m + "_" + d + "-" + h + "_" + mi + "-" + title;
  output = createWriter(filename+ ".txt");

  // Calculate the total amount of pixels needed for the creation of an array to store all pixels. 
  numPixels = cam.width * cam.height;

  // Create an array to store the previously captured frame
  previousFrame = new int[numPixels];

  loadPixels();
}

void draw() {

  if (cam.isAvailable()) {
    cam.read();
    cam.loadPixels();


    // This counter is used to draw titles only for a few seconds
    if (titleCounter < 10) {
      titleCounter++;
    }

    // Start the right mode, modes are changed by pressing the spacebar. It should be in Recording (mode 0) to gain new data
    if (mode == 0) {
      recording();
    }

    if (mode == 1) {
      source();
    }

    if (mode == 2) {
      result();
    }
    // After each new frame the running total of movement is reset to zero
    movementSum = 0;
  }
}

void recording() {
  // For loop runs through each individual pixel in the frame
  for (int i = 0; i < numPixels; i++) {
    color currColor = cam.pixels[i];
    color prevColor = previousFrame[i];

    // This is the brightness value of the current  
    int currR = (currColor >> 16) & 0xFF; // Like red(), but faster

    // This is that same pixel in the previous frame
    int prevR = (prevColor >> 16) & 0xFF;

    // By subtracting the brightness of current and previous frame we get the difference in brightness. 
    int diffR = abs(currR - prevR);

    // If the difference in brightness is larger than the thresshold, there is movement detected in the frame, therefore result is added to the running total and the pixel in the resulting array becomes 1 value brighter
    if (diffR > tresshold) {
      movementSum += diffR;

      // Brightness difference larger than the thresshold are colored white on-screen
      pixels[i]=color(255);
      a = i % screenWidth;
      b = (i - a)/screenWidth;

      // That same pixel is also added to a 2D array
      traces[a][b] = traces[a][b]+1;

      // This calculates whether the current pixel is the brightest of them all, used for autobrightness 
      if (traces[a][b] > maxBrightness) {
        maxBrightness = traces[a][b];
      }
    } else
      // If difference is not larger than the thresshold the resulting pixel will become black
    { 
      pixels[i] = color(0);
    }

    // Save the current pixel into the 'previous' buffer
    previousFrame[i] = currColor;
  }
  // To prevent flicker from frames that are all black (no movement),
  // only update the screen if the image has changed.
  if (movementSum > 0) {
    updatePixels();

    String ms = Long.toString(System.currentTimeMillis());

    // Print the current amount of movement with a timestamp to the external text file.
    output.println(ms + "," + movementSum);
  }
  if (titleCounter <6) {
    fill(255);
    textSize(18);
    text("Recording", 10, 25);
  }
}

// Shows the original webcam stream
void source() {
  image(cam, 0, 0);
  if (titleCounter <6) {
    fill(255);
    textSize(18);
    text("Source", 10, 25);
  }
}

// Shows the result of the 2D array (traces[][]) filled with pixels that showed movement. These pixels are scaled with the multiplier and saved in a new 2D array (traceOutput)
void result() {
  background(0); 

  for (int i = 0; i < screenWidth; i++) {
    for (int j = 0; j < screenHeight; j++) {
      traceOutput[i][j] = int((traces[i][j])*multiplier);
      if (traceOutput[i][j] < 256) {
        stroke(traceOutput[i][j]);
      } else {
        stroke(255);
      }
      point(i, j);
    }
  }
  if (titleCounter <3) {
    fill(255);
    textSize(18);
    text("Result", 10, 25);
  }
}



void keyPressed() {

  // Spacebar is used to iterate through the differet modes
  if (key == ' ') {
    titleCounter = 0;
    mode = mode + 1;
    if (mode >2) {
      mode = 0;
    }
  }


  // Auto Exposure (Brightness is scaled, making the brightest pixel fully white (255)
  if (key == 'a') {
    titleCounter = 0;
    fill(255);
    textSize(18);

    if (autoBrightness) {
      multiplier = 255/maxBrightness;
      autoBrightness = false;

      if (titleCounter <3) {
        text("Auto Exposure", 10, 40);
      }
    } else {
      multiplier = 1;
      autoBrightness = true; 

      if (titleCounter <3) {
        text("Original Exposure", 10, 40);
      }
    }
  }

  // Pressing s saves a PNG of the current frame
  if (key == 's') {
    saveFrame("motion_exp_######.png");
  }

  // Pressing the up key increases the multiplier making the resulting image brighter, down does the opposite
  if (key == CODED) {

    if (keyCode == UP) {
      titleCounter = 0;
      if (multiplier < 1) {
        multiplier = multiplier + 0.1;
      } else {
        multiplier = multiplier + 1;
      }

      if (titleCounter <3) {
        text("Exposure = " + multiplier, 10, 40);
      }
    } 

    if (keyCode == DOWN) {
      titleCounter = 0;
      if (multiplier < 2) {
        multiplier = multiplier - 0.1;
      } else {
        multiplier = multiplier - 1;
      }
      if (titleCounter <3) {
        text("Exposure = " + multiplier, 10, 40);
      }
    }
  }
}

// function used to save information to the external text file with movement data
void appendTextToFile(String filename, String text) {
  File f = new File(dataPath(filename));
  if (!f.exists()) {
    createFile(f);
  }
  try {
    PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(f, true)));
    out.println(text);
    out.close();
  }
  catch (IOException e) {
    e.printStackTrace();
  }
}

/**
 * Creates a new file including all subfolders
 */
void createFile(File f) {
  File parentDir = f.getParentFile();
  try {
    parentDir.mkdirs(); 
    f.createNewFile();
  }
  catch(Exception e) {
    e.printStackTrace();
  }
}    
