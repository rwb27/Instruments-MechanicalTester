// Serial connections for servos:
// Brown    - +5V
// Red      - +5V
// Orange   - RXD 2
// Yellow   - TXD 3
// Orange 2 - RXD 4
// Yellow 2 - TXD 5

#include <SoftwareSerial.h>

SoftwareSerial motor_R(2, 3); // RX, TX
SoftwareSerial motor_L(4, 5); // RX, TX


void print_binary(int v, int num_places)
{
  int mask = 0, n;
  for (n = 1; n <= num_places; n++) mask = (mask << 1) | 0x0001;
  v = v & mask;  // truncate v to specified number of places
  while(num_places) {
    if (v & (0x0001 << num_places - 1)) Serial.print("1");
    else Serial.print("0");
    --num_places;
  }
}

void setup() {
  Serial.begin(9600);
  motor_R.begin(9600);
  motor_L.begin(9600);
  Serial.println("setup complete");
}

void loop() {
  if (Serial.available()) {
    delay(10);
    char motor = Serial.read();
    char c;
    switch(motor) {
    case 'R':
      Serial.print("\nright motor command: ");
      motor_R.listen();
      while (Serial.available()) {
        c = Serial.read();
        Serial.write(c);
        motor_R.write(c);
      }
      delay(50);
      while (motor_R.available()) {
        delay(50);
        c = motor_R.read();
        Serial.write(c);
        Serial.print("(");
        print_binary(c, 8);
        Serial.print(") ");
        delay(50);
      }
      break;
    case 'L':
      Serial.print("\nleft motor command:  ");
      motor_L.listen();
      while (Serial.available()) {
        c = Serial.read();
        Serial.write(c);
        motor_L.write(c);
      }
      delay(50);
      while (motor_L.available()) {
        delay(50);
        c = motor_R.read();
        Serial.write(c);
        Serial.print("(");
        print_binary(c, 8);
        Serial.print(") ");
        delay(50);
      }
      break;
    default:
      while (Serial.available()) Serial.read();
    }
  }
  motor_R.listen();
  delay(50);
  if (motor_R.available()) {
    Serial.print("Right: ");
    delay(50);
    while (motor_R.available()) {
      Serial.write(motor_R.read());
      delay(50);
    }
  }
  motor_L.listen();
  delay(50);
  if (motor_L.available()) {
    Serial.print("Left:  ");
    delay(50);
    while (motor_L.available()) {
      Serial.write(motor_L.read());
      delay(50);
    }
  }
}


