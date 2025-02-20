#include <BluetoothSerial.h>

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <Keypad.h>

// Sensor Kecepatan
#define SENSOR_D0 14
volatile int pulseCount = 0;  // Variabel untuk menghitung jumlah pulsa

void IRAM_ATTR countPulse() {
  pulseCount++;  // Tambah hitungan setiap ada pulsa dari sensor
}

unsigned long lastTime = 0;
const int diskHoles = 20;  // Ubah sesuai jumlah lubang pada disk



// L289N atau dinamo
int IN3 = 27;
int IN4 = 26;
int ENB = 32;

// LCD
LiquidCrystal_I2C lcd(0x27, 21, 22);
int wire_begin = 21;
int wire_end = 22;


// Key Pad
const byte ROWS = 4;
const byte COLS = 4;
byte rowPins[ROWS] = { 19, 18, 5, 17 };
byte colPins[COLS] = { 16, 4, 2, 15 };
String status = "WAIT";

BluetoothSerial SerialBT;



char keys[ROWS][COLS] = {
  { '1', '2', '3', 'A' },
  { '4', '5', '6', 'B' },
  { '7', '8', '9', 'C' },
  { '*', '0', '#', 'D' }
};

Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);
bool isFirstMsg = false;
bool isBT = false;
bool isClient = false;
bool isDinamo = false;
bool isSend = false;

void setup() {
  Serial.begin(115200);
  // calculateRPM();
  setupLCD();
  setupRPM();
  setupDinamo();
}

void loop() {
  char key = keypad.getKey();

  if (!isFirstMsg) {
    firstMessage();
    isFirstMsg = true;
    return;
  }

  if (status == "WAIT") {
    if (key) {
      if (key == '2') {
        SerialBT.begin("ESP32_Bluetooth");
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Mencari Device");
        lcd.setCursor(0, 1);
        lcd.print("Batal Tekan 2");
        status = "BLUETOOTH";
        return;
      } else {
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Masukkan Tombol");
        delay(1000);
        isFirstMsg = false;
        return;
      }
    }
  }

  if (status == "BLUETOOTH") {
    if (!isBT) {
      SerialBT.begin("ESP32_Device");
      isBT = true;
      return;
    }

    if (key) {
      if (key == '2') {
        isBT = false;
        status = "WAIT";
        isClient = false;
        isSend = false;
        isDinamo = false;
        SerialBT.end();
        return;
      }
    }

    if (!isClient) {
      if (SerialBT.hasClient()) {
        lcd.setCursor(0, 0);
        lcd.print("Berhasil Terhubung....");
        lcd.setCursor(0, 1);
        lcd.print("Tekan 2 Putuskan");
        isClient = true;
        SerialBT.println("");
        hidupDinamo(0);
        return;
      }
    }

    if (SerialBT.hasClient() && isSend) {
      unsigned long currentTime = millis();
      if (currentTime - lastTime >= 1000) {  // Setiap 1 detik
        if (pulseCount > 0) {
          int rpm = (pulseCount * 60000) / (diskHoles * (currentTime - lastTime));
          Serial.print("Kecepatan: ");
          Serial.print(rpm);
          Serial.println(" RPM");
          SerialBT.println(rpm);  // Kirim data RPM ke Bluetooth
          pulseCount = 0;
        } else {
          SerialBT.println(0);  // Kirim 0 jika tidak ada pulsa
        }
        lastTime = currentTime;
      }
    }

    if (SerialBT.available()) {
      String input = SerialBT.readString();
      Serial.println(input);
      input.trim();
      int receivedValue = input.toInt();
      hidupDinamo(receivedValue);
      return;
    }
  }
}

void firstMessage() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Tekan 2 Bluetooth");
}

int getRPM() {
  unsigned long currentTime = millis();
  if (currentTime - lastTime >= 1000) {
    int rpm = (pulseCount * 60000) / (diskHoles * (currentTime - lastTime));
    Serial.print("Kecepatan: ");
    Serial.print(rpm);
    Serial.println(" RPM");

    pulseCount = 0;
    lastTime = currentTime;
    return rpm;
  }
}

void setupLCD() {
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Menunggu.....");
  Wire.begin(wire_begin, wire_end);
}

void setupRPM() {
  pinMode(SENSOR_D0, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(SENSOR_D0), countPulse, RISING);
}

void setupDinamo() {
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  pinMode(ENB, OUTPUT);
}

void hidupDinamo(int num) {
  if (num == 0) {
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, LOW);
    analogWrite(ENB, num);
    isSend = false;
  } else {
    digitalWrite(IN3, HIGH);
    digitalWrite(IN4, LOW);
    analogWrite(ENB, num);
    isSend = true;

  }
}
