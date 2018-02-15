import processing.video.*;      // Webcam library

Capture camera; //Camera object

int[] downShift; //An int for each pixel that stores how many rows that pixel has "fallen"

int blockSize = 5; //How many camera pixels each screen pixel takes up
                   //Default is 5x5, lower looks better resolution but is slow and the pixel rain is less noticable

void setup()
{
  size(1280,720); //Resolution of webcam
  
  camera = new Capture(this, "name=Logitech HD Webcam C270,size=1280x720,fps=30");  
  camera.start();
  print("Waiting for camera");
  
  //Camera width and height is unknown until a frame is read, so we can't finish setup() until the camera is available
  while(!camera.available())
  {
    print(".");
    delay(100);
  }
  camera.read();
  println("\nCamera initialized, "+camera.width+"x"+camera.height);

  //Use the camera pixel array length to initialize the array
  downShift = new int[camera.pixels.length];
}

void draw()
{
  if(camera.available())
  {
    background(0); //Set background to black
    camera.read();
    camera.loadPixels();
    
    for(int y = camera.height-1; y >= 0; y -= blockSize) //Traverse from bottom up, otherwise lower pixels will overwrite the pixel raindrops
    {
      for(int x = 0; x < camera.width; x += blockSize)
      {
        int index = (camera.width-x-1) + y*camera.width; //Uses width-x-1 to horizontally flip the pixels
        
        //10% chance of the pixel moving down one row and a 1% chance of the pixel's position being reset
        if(random(100) > 90)
        {
          downShift[index] += 1;
          if(random(100) > 90)
          {
            downShift[index] = 0; //Reset so there is a constant pixel stream
          }
        }
        
        fill(blueShift(averageColor(x, y, blockSize, camera), 25)); //Set color to the average of the 5x5 block with a blue hue adjustment
        noStroke(); //Turn off border
        rect(x, y-blockSize, blockSize, blockSize); //Draw a block in the original location (y-blocksize, because we started traversing the rows upside down)
        rect(x, y-blockSize+downShift[index]*blockSize, blockSize, blockSize); //Draw an additional block downshift[index] rows down
      }
    }
  }
}

//Get the average R, G, and B values over a range of pixels in an image buffer
color averageColor(int x, int y, int blockSize, Capture camera)
{
  int totalR = 0;
  int totalG = 0;
  int totalB = 0;
  
  for(int i = y; i < y+blockSize && i < camera.height; i++)  //Need to make sure this doesn't go over the image's bounds
  {                                                          //(which could happen if the height is not divisible by blockSize)
    for(int j = x; j < x+blockSize && i < camera.width; j++) //Same for the width
    {
      int index = (camera.width-j-1) + i*camera.width; //Calculate mirrored index
      totalR += camera.pixels[index] >> 16 & 0xFF;
      totalG += camera.pixels[index] >>  8 & 0xFF;
      totalB += camera.pixels[index] >>  0 & 0xFF;
    }
  }
  
  int avgR = totalR/(blockSize*blockSize); //Divide by number of pixels summed (blocksize^2)
  int avgG = totalG/(blockSize*blockSize);
  int avgB = totalB/(blockSize*blockSize);

  return color(avgR, avgG, avgB); //Return as type color
}

//Shift the hue in a blue direction (add to blue channel, subtract from red channel)
color blueShift(int initialColor, int amount)
{
  int r = initialColor >> 16 & 0xFF;
  int g = initialColor >>  8 & 0xFF;
  int b = initialColor >>  0 & 0xFF;
  
  r -= amount;
  r = constrain(r, 0, 255); //Make sure to stay within 0 to 255
  b += amount;
  b = constrain(b, 0, 255); //Make sure to stay within 0 to 255
  
  return color(r, g, b); //Return as type color
}