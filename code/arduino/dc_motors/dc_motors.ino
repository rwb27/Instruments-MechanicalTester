#include <SerialCommand.h>
SerialCommand NanoCmd;   // The Nano Subsystem SerialCommand object

// connect encoder and motor controller pins to Arduino digital pins
  int GantryTarget = 0;
  // Motor 0
  int M0_pwm = 5;
  int M0_dir_1 = 3;
  int M0_dir_2 = 4;
  int M0_encoder_A = 9;
  int M0_encoder_B = 10;
  int M0_pos = 0;
  int M0_encoder_A_last = HIGH;
  int M0_delta = 0;
  // Motor 1
  int M1_pwm = 6;
  int M1_dir_1 = 7;
  int M1_dir_2 = 8;
  int M1_encoder_A = 11;
  int M1_encoder_B = 12;
  int M1_pos = 0;
  int M1_encoder_A_last = HIGH;
  int M1_delta = 0;


// set up encoder variables
  int n = LOW;
  int m = LOW;
  int dir_0;
  int dir_1;
  int power_0;
  int power_1;

void setup() {
  Serial.begin (115200);
  // Setup callbacks for SerialCommand commands
  NanoCmd.addCommand("G",  GantryMove);   // moves test gantry +ve up -ve down
  //   NanoCmd.setDefaultHandler(unrecognized_params);

  // set all the motor control pins to outputs
  pinMode(M0_pwm, OUTPUT);
  pinMode(M1_pwm, OUTPUT);
  pinMode(M0_dir_1, OUTPUT);
  pinMode(M0_dir_2, OUTPUT);
  pinMode(M1_dir_1, OUTPUT);
  pinMode(M1_dir_2, OUTPUT);

  //initialise encoder pins
  pinMode (M0_encoder_A, INPUT);
  pinMode (M0_encoder_B, INPUT);
  pinMode (M1_encoder_A, INPUT);
  pinMode (M1_encoder_B, INPUT);


}
void set_motors() {
  M0_delta =  (GantryTarget - M0_pos);
  M1_delta =  (GantryTarget - M1_pos);

  if (M0_delta >= 0) dir_0 = HIGH;
  else               dir_0 = LOW;
  if (M1_delta >= 0) dir_1 = HIGH;
  else               dir_1 = LOW;

  if (abs(M0_delta) > 105) power_0 = 255;
  else                     power_0 = abs(M0_delta) + 150;
  if (abs(M1_delta) > 105) power_1 = 255;
  else                     power_1 = abs(M1_delta) + 150;
  
  if (M0_delta == 0) power_0 = 0;
  if (M1_delta == 0) power_1 = 0;
  digitalWrite(M0_dir_1, !dir_0);
  digitalWrite(M0_dir_2,  dir_0);
  digitalWrite(M1_dir_1, !dir_1);
  digitalWrite(M1_dir_2,  dir_1);
  analogWrite( M0_pwm,  power_0);
  analogWrite( M1_pwm,  power_1);
}

void loop() {
  NanoCmd.readSerial();
  GetEncoders();
  set_motors();
}

void GetEncoders() {
  n = digitalRead(M0_encoder_A);
  m = digitalRead(M1_encoder_A);
  if ((M0_encoder_A_last == LOW) && (n == HIGH)) {
    if (digitalRead(M0_encoder_B) == LOW) M0_pos--;
    else M0_pos++;
  }
  if ((M1_encoder_A_last == LOW) && (m == HIGH)) {
    if (digitalRead(M1_encoder_B) == LOW) M1_pos--;
    else M1_pos++;
  }
  if (((M0_encoder_A_last == LOW) && (n == HIGH)) || ((M1_encoder_A_last == LOW) && (m == HIGH))) {
    Serial.print (M0_delta);
    Serial.print ("/");
    Serial.println (M1_delta);
  }
  M0_encoder_A_last = n;
  M1_encoder_A_last = m;
  // TODO Get time stamp
}

void GantryMove() {
  int aNumber;
  char *arg;

  Serial.println("Adjusting Gantry");
  arg = NanoCmd.next();
  if (arg != NULL) {
    GantryTarget = atoi(arg);    // Converts a char string to an integer
    Serial.print("Gantry Steps: ");
    Serial.println(GantryTarget);
  }
  else {
    Serial.println("No arguments");
  }
}

void unrecognized_params() {
  // This gets set as the default handler, and gets called when no other command matches.
  Serial.println("What?");
}




