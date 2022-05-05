import websockets.*;

WebsocketClient wsc;

void setup()
{
    wsc= new WebsocketClient(this, "ws://10.0.1.108:8092/");
}

void draw()
{
  background(255,255,255);
}

void webSocketEvent(String msg){
 println(msg);
 
}
