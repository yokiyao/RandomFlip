import processing.video.Capture;
import gab.opencv.OpenCV;
import java.awt.Rectangle;
 
import oscP5.*;
import netP5.*;

Capture cam;
OpenCV opencv;

// input resolution
int w = 320, h = 240;

// output zoom
int zoom = 1;


OscP5 oscP5;
NetAddress myRemoteLocation;


void setup() {

  // actual size, is a result of input resolution and zoom factor
  size(320 , 240 );

  // capture camera with input resolution
  cam = new Capture(this, w, h);
  cam.start();

  // init OpenCV with input resolution
  opencv = new OpenCV(this, w, h);

  // setup for facial recognition
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  

  // limit frameRate
  //frameRate(30);
  
   /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this,12000);
  
  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
  myRemoteLocation = new NetAddress("127.0.0.1",13500);
}

int noise_reduce_v = 6;
float smoothedfaceX = 0;
float smoothedfaceY = 0;
float smoothedfaceW = 0;
float smoothedfaceH = 0;
int timer = 0;
void draw() {

  // get the camera image
  opencv.loadImage(cam);

  // detect faces
  Rectangle[] faces = opencv.detect();

  // zoom to input resolution
  scale(zoom );

  // draw input image
  image(opencv.getInput(), 0, 0);

  // draw rectangles around detected faces
  fill(255, 64);
  strokeWeight(3);
  //for (int i = 0; i < faces.length; i++) {
     
  if (faces.length != 0){ 
    timer = 0;
    //if (faces.length > 1){
      for (int faceid = 0; faceid < faces.length; faceid++){
        if (faces[0].width < faces[faceid].width){
          Rectangle face = faces[faceid];
          faces[faceid] = faces[0];
          faces[0] = face;
        }
      }
      smoothedfaceX = lerp(smoothedfaceX, faces[0].x, 0.05);
      smoothedfaceY = lerp(smoothedfaceY, faces[0].y, 0.05);
      smoothedfaceW = lerp(smoothedfaceW, faces[0].width, 0.05);
      smoothedfaceH = lerp(smoothedfaceH, faces[0].height, 0.05);
      rect(smoothedfaceX, smoothedfaceY, smoothedfaceW, smoothedfaceH);
      //float x = map(faces[0].x,0,320, -2,2);
      //float y = map(faces[0].y, 0, 240,-2,2);
      println(smoothedfaceX, smoothedfaceY, 
              smoothedfaceW, faces.length);
      sendOSC(smoothedfaceX, smoothedfaceY, 
              smoothedfaceW, 1);
      
   // }
    
  }  
  else if (faces.length == 0){
     timer++;
   println(  timer + "     " + faces.length);
     //smoothedfaceH = lerp(smoothedfaceH, faces[0].height, 0.05);
     if (timer > 200){
       smoothedfaceX = lerp(smoothedfaceX, 120, 0.005);
       smoothedfaceY = lerp(smoothedfaceY, 105, 0.005);
       smoothedfaceW = lerp(smoothedfaceW, 39, 0.005);
       sendOSC(smoothedfaceX, smoothedfaceY, smoothedfaceW, 0);
       if (timer > 1000){
         timer = 0;
       }
     }
  }
//}
  
 
  // show performance and number of detected faces on the console
  if (frameCount % 50 == 0) {
    println("Frame rate:", round(frameRate), "fps");
    println("Number of faces:", faces.length);
  }
  
}

// read a new frame when it's available
void captureEvent(Capture c) {
  c.read();
}


void sendOSC(float x, float y, float w, float l){
  OscMessage myMessage = new OscMessage("/cam");
  myMessage.add(x);
  myMessage.add(y);
  myMessage.add(w);
  myMessage.add(l);
  oscP5.send(myMessage, myRemoteLocation);
}
