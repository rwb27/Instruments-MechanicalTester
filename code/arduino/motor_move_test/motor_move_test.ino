/*
  Software serial multple serial test
 
 Receives from the hardware serial, sends to software serial.
 Receives from software serial, sends to hardware serial.
 
 The circuit: 
 * RX is digital pin 10 (connect to TX of other device)
 * TX is digital pin 11 (connect to RX of other device)
 
 Note:
 Not all pins on the Mega and Mega 2560 support change interrupts, 
 so only the following can be used for RX: 
 10, 11, 12, 13, 50, 51, 52, 53, 62, 63, 64, 65, 66, 67, 68, 69
 
 Not all pins on the Leonardo support change interrupts, 
 so only the following can be used for RX: 
 8, 9, 10, 11, 14 (MISO), 15 (SCK), 16 (MOSI).
 
 created back in the mists of time
 modified 25 May 2012
 by Tom Igoe
 based on Mikal Hart's example
 
 This example code is in the public domain.
 
 */
#include <SoftwareSerial.h>

SoftwareSerial motor_R(2, 3); // RX, TX
SoftwareSerial motor_L(4, 5); // RX, TX

void setup()  
{
  Serial.begin(9600);
  motor_R.begin(9600);
  motor_L.begin(9600);
  Serial.write(motor_R.write("M255\r\n"));
  Serial.write(motor_L.write("M255\r\n"));
  Serial.write(motor_R.write("P0\r\n"));
  Serial.write(motor_L.write("P0\r\n"));
  Serial.write(motor_R.write("G-8000\r"));
  Serial.write(motor_L.write("G-8000\r"));
  Serial.write(motor_R.write("\n"));
  Serial.write(motor_L.write("\n"));
}

void loop() // run over and over
{
//  if (motor_R.available())
//    Serial.write(motor_R.read());
//  if (motor_L.available())
//    Serial.write(motor_L.read());
//  if (Serial.available()) {
//    motor_R.write(Serial.read());
//    motor_L.write(Serial.read());
//  }
  delay(10);
}

