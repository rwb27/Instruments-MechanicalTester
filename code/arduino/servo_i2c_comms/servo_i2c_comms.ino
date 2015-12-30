// I2C connections for servos:
// Brown    - SCL, A5
// Red      - SDA, A4
// Orange   - +5V
// Yellow   - +5V
// Orange 2 - +5V
// Yellow 2 - +5V

#include <Wire.h>

int motor_R = 10;
int motor_L = 11;

byte turn[] = {0x8, 0xFF, 0x00, 0x00, 0x0};
byte fwd[]  = {0x1, 0x7F, 0x0};
byte back[] = {0x1, 0x1, 0xFF};
byte zero[] = {0x3, 0x0, 0x0, 0x0, 0x0};

void send(int addr, byte *msg, int siz) {
  Wire.beginTransmission(addr);
  for (int i=0; i < siz; i++) {
    Wire.write(msg[i]);
  }
  digitalWrite(13, HIGH);
  Wire.endTransmission();
  digitalWrite(13, LOW);
  delay(100);
}

void test(int addr) {
  Serial.write("Testing ");
  Serial.print(addr);
  Serial.write(" \r\n");
  send(addr, zero, sizeof(zero));
  send(addr, back,  sizeof(fwd));
  send(addr, turn, sizeof(turn));
}

void setup() {
  Serial.begin(115200);
  Wire.begin(); // join i2c bus (address optional for master)
  pinMode(13, OUTPUT);
  delay(100);
}

void loop() {
  delay(2000);
  test(10);
//  for (int i=0; i <= 128; i++){
//    test(i);
//  }
}
