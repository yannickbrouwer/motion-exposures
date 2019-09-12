Animation animation1;
int tresshold = 100;
int numPixels;
int[] previousFrame;

int mode = 1;

int a = 0;
int b = 0;
int screenWidth = 625;
int screenHeight = 350;
int[][] traces = new int[screenWidth][screenHeight];
int[][] traceOutput = new int[screenWidth][screenHeight];

void setup() {
  size(625, 350);
  background(0);
  frameRate(5);
  animation1 = new Animation("swindon_", 90);
  

  numPixels = width * height;
  // Create an array to store the previously captured frame
  previousFrame = new int[numPixels];
  loadPixels();
}

void draw() { 
  // Display the sprite at the position xpos, ypos
   
    if (mode == 1){
    animation1.display();

 
    loadPixels(); // Make its pixels[] array available
    
    int movementSum = 0; // Amount of movement in the frame
  
     for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
      color currColor = pixels[i];
      color prevColor = previousFrame[i];
      int currR = (currColor >> 16) & 0xFF; // Like red(), but faster
      int prevR = (prevColor >> 16) & 0xFF;
      int diffR = abs(currR - prevR);
     
      if (diffR > tresshold){
        movementSum += diffR;
     
        pixels[i]=color(255);
        a = i % width;
        b = (i - a)/width;
      
        traces[a][b] = traces[a][b]+1;
      }
    else
    {
      pixels[i] = color(0);
    }
      // The following line is much faster, but more confusing to read
      //pixels[i] = 0xff000000 | (diffR << 16) | (diffG << 8) | diffB;
      // Save the current color into the 'previous' buffer
      previousFrame[i] = currColor;
     }
      if (movementSum > 0) {
      updatePixels();
      }
    }
      if (mode == 2){
    background(0); 

for (int i = 0; i < screenWidth; i++) {
  for (int j = 0; j < screenHeight; j++) {
    traceOutput[i][j] = int((traces[i][j])*2);
    if(traceOutput[i][j] < 256){
    stroke(traceOutput[i][j]);
    }
    else{
       stroke(255);
    }
    point(i,j);
  }
}
}
  }

// Class for animating a sequence of GIFs

void keyPressed() {
  if (key == ' ') {
    if (mode == 1){
      mode = 2;
  }
  else{
    mode =1;
  }
  
}
}
  
class Animation {
  PImage[] images;
  int imageCount;
  int frame;
  
  Animation(String imagePrefix, int count) {
    imageCount = count;
    images = new PImage[imageCount];

    for (int i = 1; i < imageCount; i++) {
      // Use nf() to number format 'i' into four digits
      String filename = imagePrefix + nf(i, 5) + ".png";
      images[i] = loadImage(filename);
    }
  }

  void display() {
    frame = (frame+1) % imageCount;
    if (frame == 0){
      frame = 1;
    }
    image(images[frame], 0, 0);
  }
  
  int getWidth() {
    return images[0].width;
  }
}
