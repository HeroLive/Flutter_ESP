#include <Arduino.h>
#include <WebSocketsServer.h> //import for websocket
#include <ArduinoJson.h> //data Json

const char *ssid =  "esp8266";   //Wifi SSID (Name)
const char *pass =  "123456789"; //wifi password

WebSocketsServer webSocket = WebSocketsServer(81); //websocket init with port 81

StaticJsonDocument<500> StepperDoc;

#define pul 0 //D3
#define dir 2 //D4

float disPerRound = 1 ;//0.025; //round/mm
int microStep = 1; //16;
float angleStep = 1.8;
float stepsPerUnit = disPerRound * 360.0 * microStep / angleStep;
long position = 0;
long target = 0;
long speed = 2;
bool dir_status = HIGH;
unsigned long last_step_time;
unsigned long step_delay;

void setup() {
  Serial.begin(9600); //serial start

  pinMode(pul, OUTPUT);
  pinMode(dir, OUTPUT);
  digitalWrite(dir, dir_status);

  // set First value
  StepperDoc["speed"] = 2;
  StepperDoc["position"] = 0;

  Serial.println("Connecting to wifi");

  IPAddress apIP(192, 168, 99, 100);   //Static IP for wifi gateway
  WiFi.softAPConfig(apIP, apIP, IPAddress(255, 255, 255, 0)); //set Static IP gateway on NodeMCU
  WiFi.softAP(ssid, pass); //turn on WIFI

  webSocket.begin(); //websocket Begin
  webSocket.onEvent(webSocketEvent); //set Event for websocket
  Serial.println("Websocket is started");
}

void loop() {
  webSocket.loop(); //keep this line on loop method
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  //webscket event method
  String cmd = "";
  switch (type) {
    case WStype_DISCONNECTED:
      Serial.println("Websocket is disconnected");
      break;
    case WStype_CONNECTED: {
        Serial.println("Websocket is connected");
        Serial.println(webSocket.remoteIP(num).toString());
        webSocket.sendTXT(num, "connected");
      }
      break;
    case WStype_TEXT:
      cmd = "";
      for (int i = 0; i < length; i++) {
        cmd = cmd + (char) payload[i];
      } //merging payload to single string
      Serial.print("Data from flutter:");
      Serial.println(cmd);
      StepperEvent(cmd);
      break;
    case WStype_FRAGMENT_TEXT_START:
      break;
    case WStype_FRAGMENT_BIN_START:
      break;
    case WStype_BIN:
      hexdump(payload, length);
      break;
    default:
      break;
  }
}

void StepperEvent(String json) {
  // Deserialize the JSON document
  DeserializationError error = deserializeJson(StepperDoc, json);
  if (error) {
    Serial.print(F("deserializeJson() failed: "));
    Serial.println(error.f_str());
    return;
  }
  long target = StepperDoc["position"];
  long newPositon = target * stepsPerUnit;
  speed = StepperDoc["speed"];
  Serial.print("Move from ");
  Serial.print(position/stepsPerUnit);
  Serial.print(" to ");
  Serial.println(target);

  step_delay = 1000L * 1000L / stepsPerUnit / speed;
  if (newPositon > position) {
    digitalWrite(dir, dir_status);
  } else if (newPositon < position) {
    digitalWrite(dir, !dir_status);
  } else {
    return;
  }
  //  for (long i = 0; i < abs(target - position) * stepsPerUnit; i++) {
  //    digitalWrite(pul, HIGH);
  //    digitalWrite(pul, LOW);
  //    delayMicroSeconds
  //    Serial.println(i);
  //  }
  long counter = 0;
  while (position != newPositon)
  {
    unsigned long now = micros();
    if (now - last_step_time >= step_delay)
    {
      last_step_time = now;
      digitalWrite(pul, HIGH);
      digitalWrite(pul, LOW);
      position = (position < newPositon) ? position + 1 : position - 1;
//      counter++;
//      Serial.println(counter);
    }
  }
  Serial.println("on target");
}
