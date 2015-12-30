// Serial connections for servos:
// Brown    - +5V
// Red      - +5V
// Orange   - RXD 2
// Yellow   - TXD 3
// Orange 2 - RXD 4
// Yellow 2 - TXD 5

#include <SoftwareSerial.h>

//SoftwareSerial motor(2, 3); // RX, TX
SoftwareSerial motor(4, 5); // RX, TX

void setup()  
{
  Serial.begin(9600);
  motor.begin(9600);
  pinMode(13, OUTPUT);
}

void loop() // run over and over
{
  if (motor.available()) Serial.write(motor.read());
  if (Serial.available()) {
    char c = Serial.read();
    Serial.print(c);
    motor.write(c);
  }
  digitalWrite(13, !digitalRead(13));
  delay(20);
}

