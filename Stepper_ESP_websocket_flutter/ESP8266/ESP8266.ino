#include <Arduino.h>
#include <WebSocketsServer.h> //import for websocket
#include <ArduinoJson.h> //data Json
#include "DHT.h" //dht11

const char *ssid =  "esp8266";   //Wifi SSID (Name)
const char *pass =  "123456789"; //wifi password

WebSocketsServer webSocket = WebSocketsServer(81); //websocket init with port 81

unsigned long t_tick = 0;

StaticJsonDocument<500> TempDoc;

//properties DHT11 & init library dht11
#define DHTPIN 5    //D4,D3,D5    
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);
double humi;
double tempC;

void setup() {
  Serial.begin(9600); //serial start
  dht.begin();

  // set First value
  TempDoc["tempC"] = 0;
  TempDoc["humi"] = 0;

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

  if (millis() - t_tick > 2000) {
    //Read humi & tempC
    humi = dht.readHumidity();
    tempC = dht.readTemperature();
    if (isnan(tempC) || isnan(humi)) {
      Serial.println("Failed to read from DHT sensor!");
      return;
    }
    Serial.print("Temperature: ");
    Serial.print(tempC);
    Serial.print("°C Humidity: ");
    Serial.print(humi);
    Serial.println("%");
    dhtEvent();
    t_tick = millis();
  }
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

void dhtEvent() {
  TempDoc["humi"] = humi;
  TempDoc["tempC"] = tempC;
  char msg[256];
  serializeJson(TempDoc, msg);
  webSocket.broadcastTXT(msg);
}
