#include <Servo.h> 
Servo servo1;

//// pin numbers //////////////////////
#define switchPin 10
#define xPin 0
#define yPin 1
#define zPin 2
#define rndPin 3
#define servoPin1 9
#define dummySwitch 7
#define ledPin 13

long lastDebounceTime = 0;
long debounceDelay = 500;//first definition
long now;//present time for judgment length of writing time

//angles of servo for onoff
int pushOff = 0;
int pushOn = 90;
int pushOnMid = 50;

int rules[8];//for defining ptterns

long x_sum, y_sum, z_sum;
int smoothCount = 0;
int smoothNum = 30;
int thresholdX = 0;
int thresholdY = 0;
int thresholdZ = 0;
int hysY = 30;
int hysX = 30;
int lastX, lastY = 512;
int r, arg;

boolean mesureFin = false;


void setup(){
  Serial.begin(57600);
  servo1.attach(servoPin1);
  servo1.write(0);

  //define pinmode
  pinMode(switchPin, INPUT);
  pinMode(xPin, INPUT);  
  pinMode(yPin, INPUT);
  pinMode(zPin, INPUT);
  pinMode(ledPin, OUTPUT);  
  pinMode(dummySwitch, OUTPUT);  
  pinMode(servoPin1, OUTPUT);

  measureBaseline();//calcu baseline
  randomSeed(analogRead(rndPin));
}

void loop(){

  digitalWrite(dummySwitch, HIGH);
  int val = digitalRead(switchPin);

  //when finished calcu & switch = on
  if(mesureFin && val == 1){
    now++;

    //add nums for smoothing
    int x=analogRead(xPin);
    int y=analogRead(yPin);
    int z=analogRead(zPin);
    x_sum+=x;
    y_sum+=y;
    z_sum+=z;
    smoothCount++;

    //when smoothed
    if(smoothCount > smoothNum - 1){

      //calcu averages
      int smoothedX = x_sum/smoothNum;
      int smoothedY = y_sum/smoothNum;
      int smoothedZ = z_sum/smoothNum;
      
      //send Serial
      Serial.print(smoothedX);
      Serial.print(',');
      Serial.println(smoothedY);


      //push the spray
      if((now - lastDebounceTime) > debounceDelay){
        if(smoothedY < lastY - hysY || lastY + hysY < smoothedY ||
          smoothedX < lastX - hysX || lastX + hysX < smoothedX){

          int rndPush = random(7);
          r = random(10);

          if(1 < rndPush){
            servo1.write(pushOn);
            digitalWrite(ledPin, HIGH);
          }
          else if(rndPush < 2){
            servo1.write(pushOff);
            digitalWrite(ledPin, LOW);
          }
        }
        else if(lastY - hysY < smoothedY || smoothedY < lastY + hysY ||
          lastX - hysX < smoothedX || smoothedX < lastX + hysX ){
          servo1.write(pushOff);
          digitalWrite(ledPin, LOW);
        }

        lastX = smoothedX;
        lastY = smoothedY;
        lastDebounceTime = now;

        //debounceDelay = random(5000) + 1000;

      }

      //reset smoothed
      smoothCount = 0;
      x_sum = 0;
      y_sum = 0;
      z_sum = 0;
    }
  }

  //reset
  else if(mesureFin && val == 0){
    digitalWrite(ledPin, LOW);
    servo1.write(0);
    now = 0;
    lastDebounceTime = 0;
  }
}

//mesuring baseline function
void measureBaseline(){
  digitalWrite(ledPin, HIGH);

  long totalX = 0;
  long totalY = 0;
  long totalZ = 0;
  int count = 0;

  while(millis() < 3000){//3sec for mesure
    int calibX = analogRead(xPin);
    int calibY = analogRead(yPin);
    int calibZ = analogRead(zPin);
    totalX += calibX;
    totalY += calibY;
    totalZ += calibZ;
    count++;
    delay(1);
  }

  //alarm finished mesuring
  thresholdX = totalX / count;
  thresholdY = totalY / count;
  thresholdZ = totalZ / count;
  mesureFin = true;
  digitalWrite(ledPin, LOW);
}













