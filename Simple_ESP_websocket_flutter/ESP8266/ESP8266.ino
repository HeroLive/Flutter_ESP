#include <Arduino.h>
#include <WebSocketsServer.h> //import for websocket

const char *ssid =  "esp8266";   //Wifi SSID (Name)
const char *pass =  "123456789"; //wifi password

WebSocketsServer webSocket = WebSocketsServer(81); //websocket init with port 81

float counter = 0;
unsigned long t = 0;
String json;

void setup() {
  Serial.begin(9600); //serial start

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
      if (cmd == "add") {
        counter++;
        json = String(counter, 0);
        webSocket.broadcastTXT(json);
      }
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
