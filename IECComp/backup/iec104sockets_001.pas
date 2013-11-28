unit IEC104Sockets;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LNet, ExtCtrls;

Type

TIEC104Socket = class;

TIECSocketEvent = procedure (Sender: TObject; Socket: TIEC104Socket) of object;

TRTXEvent = procedure(Sender: TObject;const Buffer:array of byte;count :integer) of object;

TIECSocketType= (TIECUnkwon,TIECClient,TIECServer);
TIEC104LinkStatus= (IECOFF,IECINIT,IECStartDT,IECStopDT);

TIEC104Timerset = record
    T0:        integer;  //time to restart IP socket
    T1:        integer;  //Time untill my sended information has to be confirned
    T2:        integer;  //time befor sending confirmation
    T3:        integer;  //Pollingtime;
    k:         integer;  //max receive I_frames before confirm
    w:         integer;  //max send I_frames befor i expect a confirmation
 end;

TIECStatusinfo = Record
  asdu:   word;
  obj:    word;
  end;

TIEC104Settings =record
    IECSocketType: TIECSocketType;
    Address : string;
    port: integer;
    Timerset : TIEC104TimerSet;
    active: boolean;
//    StatusInfo: TIECStatusinfo;
    TrcLevel: integer;
  end;

TIEC104Server = class(TComponent)
     private
        Fname: String;
//        FIECSettings:TIEC104Settings;  //Server asign settings to all sockets
        FIECTimers:TIEC104TimerSet;
        FClientlist:TList;
        FServerSocket: TLTCP;
        FOnTraceEvent: TGetStrProc;
        FOnClientCOnnect: TIECSocketEvent;
        FOnClientDisCOnnect: TIECSocketEvent;
//        FonlinkEvent:  TIECLinkEvent;
        FOnClientRead: TRTXEvent;
        FOnClientSend: TRTXEvent;

        procedure SetPort(Port:integer);
        function getPort:integer;
        procedure SetActive(val:boolean);
        function getActive:Boolean;
     protected
//       procedure trace(const s:string);
//       TLSocketEvent = procedure(aSocket: TLSocket) of object;
       procedure ClientConnect(Socket: TLSocket);
       procedure ClientDisConnect(Socket: TLSocket);
       procedure ClientRead(Socket: TLSocket);
       procedure ClientError(const msg: string; Socket: TLSocket);
       Function GetClientAddress(Socket:TLSocket):string;
       function GetClient(Index: Integer): TIEC104Socket;
       function FindClient(source:TLSocket):TIEC104Socket;
       function getClientindex(sender:TIEC104Socket):integer;
       Procedure setOnClientRead(proc: TRTXEvent);
       Procedure setOnClientSend(proc: TRTXEvent);
//       function GetTimers: TIEC104Timerset;
//       procedure SetTimers(timers:TIEC104Timerset);
     public
//       constructor Create(name:string;settings:TIEC104Settings);
       constructor Create(AOwner: Tcomponent);override;
       destructor destroy;
       procedure ClientClose(Client: TIEC104Socket);
//       procedure clientClose(Name:string);
       property ServerSocket:TLTCP read FServerSocket;
       property Clients:TList read FClientList;
       property Client[Index: Integer]: TIEC104Socket read GetCLient;
//       function Edit(clientindex:integer):TIEC104Settings;
       property Timers:TIEC104Timerset read FIECTimers write FIECTimers;
     published
       property Port:integer read getPort write SetPort;
       property Active:Boolean read getActive write SetActive;
//       property Timers:TIEC104Timerset read getTimers write SetTimers;
       property onClientConnect: TIECSocketEvent read FOnClientCOnnect write FOnClientCOnnect;
       property onClientDisConnect: TIECSocketEvent read FOnClientDisConnect write FOnClientDisConnect;
       property onClientRead: TRTXEvent read FOnClientRead write SetOnClientRead;
       property onClientSend: TRTXEvent read FOnClientSend write SetOnClientSend;
//       property onLinkEvent:  TIECLinkEvent read FonLinkEvent write FonLinkEvent;
       property onTrace: TGetStrProc read FonTraceEvent write FonTraceEvent;
    end;

TIEC104Socket = class(TObject)
  private
    FName:    String;
    FIECSocketType: TIECSocketType;
    FID:      integer;
    FPortActive :Boolean;
//    FLinkActive: Boolean;
    FLinkStatus: TIEC104LinkStatus;
    Ftimer:     TTimer;
//    Ftimeractive:boolean;
    FTimerSet:   TIEC104Timerset;
    FcounterSet: TIEC104Timerset;
    FAPDU_tx:   array[0..255]of byte;
    FAPDU_TX_Count:integer;
    FAPDU_Rx:   array[0..255]of byte;
    FAPDU_RX_Count:integer;
    FAPDUlength:      integer;
    FASDUlength:      integer;
    FTIFilter:  byte; // Type Identification filter;
    FVR:        integer;  // Receive variable
    FVS:        integer;  // send variable
//    FProfile:   TIECProfile;
    FStatus:    TIECStatusinfo;
    FOnTraceEvent: TGetStrProc;
    FTrl       :integer;  //Tracelevel
    FOnRXData: TRTXEvent;
    FOnTXData: TRTXEvent;
    FOn0nTimerEvent:  TNotifyEvent;
//    FOnLinkEvent: TIECLinkEvent;
    FSocket: TLSocket;
    Fip_rx_count:integer;
    procedure confirm;
  protected
    Procedure irq(Sender: TObject);
//    procedure connect(Sender: TObject;Socket: TCustomWinSocket);
    procedure DisConnect;
//    procedure readAPDU(ip_rx:array of byte;var IP_Bufpos:integer);
    procedure readAPCI;
    procedure ReadASDU;
    procedure update_VS;
    procedure setActive(val:boolean);
    procedure setLinkStatus(val:TIEC104LinkStatus);
    procedure send;
    procedure SendStartAck;
    procedure SendStopAck;
    procedure SendPoll;
    procedure SendPollAck;
    procedure SendQuitt;
    procedure settimeractive(val:boolean);
//    procedure trace(const s:string);
  public
    constructor Create;
    destructor destroy;
    procedure SendStart;
    procedure SendStop;
//    procedure StatusToDataOut;
//    procedure StatusToDataOut(val:boolean);
//    procedure showSetupDialog;
    procedure readAPDU(ip_rx:array of byte;var IP_Bufpos:integer);
    procedure sendBuf(buf:array of byte; count:integer);
//    procedure sendBuf(var buf:array of byte; count:integer);
    procedure sendHexStr(var s:string);
    property active:boolean read FportActive write setActive;
    property RXCount: Integer read FVR;
    property TXCount: Integer read FVS;
    property onTraceEvent: TGetStrProc read FOnTraceEvent write FOnTraceEvent;
    property onRXData: TRTXEvent read FonRXData write FonRXData;
    property onTXData: TRTXEvent read FonTXData write FonTXData;
//    property onLinkEvent: TIECLinkEvent read FonLinkEvent write FonLinkEvent;
    property onOnTimerEvent: TNotifyEvent read Fon0nTimerEvent write Fon0nTimerEvent;
    property ASDULength: integer read FASDULength write FASDULength;
//    property Traceon: boolean read Ftraceon write Ftraceon;
    property ID: integer read FID write FID;
    property TIFilter: byte read FTIFilter write FTIFIlter;
    property Name: string read FName;
    property TimerSet: TIEC104TimerSet read FtimerSet write FTimerSet;
//    property Profile: TIECProfile read FProfile write FProfile;
    property Status: TIECStatusInfo read FStatus write FStatus;
    property Tracelevel: integer read FTrl write FTrl;
//    property linkEstablisched: Boolean read FLinkactive;// write FLactive;
    property linkStatus: TIEC104LinkStatus read FLinkStatus write setLinkstatus;
//    property LinkActive: Boolean read Ftimeractive write settimeractive;
  published
  end;

implementation

var
  shutdown:Boolean=false;

const
  ID_104=$68;
  off=90000000;
  S_Frame=$01;U_Frame=$03;I_Frame=$00;Unknown=-1;
  UStart=$07; UStart_ack=$0B;  // 0000 0111   0000 1011
  UStop=$13;  UStop_ack=$23;   // 0001 0011   0010 0011
  Utest=$43;  Utest_ack=$83;   // 0100 0011   1000 0011

 function BufferToHexStr(buf:pbyte;count:integer):string;
  var
    x:integer;
 begin
  for x:=0 to count-1 do
     begin
     result:=result+inttohex(buf^,2)+' ';
     inc(buf);
     end;
end;

 function DefaultTimerset: TIEC104Timerset;
 begin
   result.T0:=10000;
   result.T1:=15000;
   result.T2:=10000;
   result.T3:=20000;
   result.k:=12;
   result.w:=8;
 end;

  //+++++++++++++++++++++++++++++++++++++
 //   TIECServer    implementation
 //+++++++++++++++++++++++++++++++++++++

 constructor TIEC104Server.Create(Aowner: TComponent);
 begin
 inherited create(AOwner);
 Fname:=Name;

 Fiectimers:=DefaultTimerset;
 FServerSocket:=TLTCP.Create(self);

 FServerSocket.Port:=2404;

 //FServerSocket.Active:=true;
// FServerSocket.OnClientConnect:=@ClientConnect;
 FServerSocket.OnAccept:=@ClientConnect;
 FServerSocket.OnDisconnect:=@ClientDisconnect;
 FServerSocket.OnReceive:=@ClientRead;
 FServerSocket.OnError:=@Clienterror;

 FClientlist:=TList.Create;
 end;

 Destructor TIEC104Server.destroy;
 begin
   FClientlist.Destroy;
   FServerSocket.free;
   inherited destroy;
 end;

 procedure TIEC104Server.ClientClose(Client: TIEC104Socket);
var
 x,i:integer;
begin
 i:=Fclientlist.IndexOf(client);
 For x:=0 to serverSocket.Count-1 do
    if GetClientAddress(serverSocket.Socks[x]) = client.FName then
        begin
        FserverSocket.Socks[i].Disconnect(true);
        FserverSocket.Socks[i].Destroy;
        end;
end;

procedure TIEC104Server.ClientConnect(Socket: TLSocket);
var
 cclient:TIEC104Socket;
begin
cclient:=TIEC104Socket.Create;
cclient.FIECSocketType:=TIECServer;
cclient.FSocket:=socket;
cclient.FID:=fclientlist.Add(cclient);
cclient.FName:=getclientAddress(socket);
//trace('ClientConect: '+getclientAddress(socket)+'ID: '+inttostr(client.Fid));

if assigned(Fonclientconnect) then
    FonclientConnect(self,cclient);

cclient.Tracelevel:=6;
cclient.onTraceEvent:=Fontraceevent;
cclient.onRXData:=FOnClientRead;
cclient.onTXData:=FOnClientSend;
//cclient.onLinkEvent:=FonlinkEvent;
cclient.Ftimer.Enabled:=TRUE;
end;

procedure TIEC104Server.ClientDisconnect(Socket: TLSocket);
var
   s:string;
   cclient:TIEC104Socket;
   i:integer;
begin
s:=getclientAddress(socket);
//trace('Connection closed: '+s) ;
cclient:=Findclient(socket);
if cclient <> nil then
//if i <> 0 then
   begin
//   trace('found client in list: DELETE');
   Fclientlist.Delete(getclientindex(cclient));
   cclient.FSocket:=nil;
   if assigned(FonclientDisconnect) then
       FonclientDisConnect(self,cclient);
   cclient.destroy;
   end;
end;

//       TLSocketErrorEvent = procedure(const msg: string; aSocket: TLSocket) of object;
procedure TIEC104Server.ClientError(const msg: string; Socket: TLSocket) ;
var
  s:string;
begin
case errorcode of
  10053: s:='ERROR_Connection closed: '+getclientAddress(socket);
else
  s:='SocketError_?: '+ msg;
end;
errorcode:=0;
//trace(s);
socket.Disconnect(true);
end;

Procedure TIEC104Server.setOnClientRead(proc: TRTXEvent);
var
  i:integer;
   cclient:TIEC104Socket;
begin
 FOnClientRead:=proc;
 for i:=0 to Fclientlist.Count-1 do
     begin
     Cclient:=TIEC104Socket(Fclientlist.Items[i]);
     cclient.FOnRXData:=FOnClientRead;
     end;
end;

Procedure TIEC104Server.setOnClientSend(proc: TRTXEvent);
var
  i:integer;
   cclient:TIEC104Socket;
begin
 FOnClientSend:=proc;
 for i:=0 to Fclientlist.Count-1 do
     begin
     Cclient:= TIEC104Socket(Fclientlist.Items[i]);
     cclient.FOnTXData:=FOnClientSend;
     end;
end;

procedure TIEC104Server.ClientRead(Socket: TLSocket);
var
   ip_rx:array[0..1500]of byte;
   ip_bufpos:integer;
   cclient:TIEC104Socket;

begin
ip_bufpos:=0;
//IP_RX_count:=socket.ReceiveBuf(IP_RX,1500);
cclient:=findclient(socket);
if cclient= nil then
   exit;
//Client.FIP_RX_count:=socket.ReceiveBuf(IP_RX,1500);
Cclient.FIP_RX_count:=socket.Get(IP_RX,1500);
//  Client.trace('_'+inttostr(FIECSocket.FIP_RX_Count)+' IP Stream-Bytes recived');
IP_bufpos:=0;
while ip_bufpos < cclient.Fip_rx_count do     // there could be moe than 1 APDU in a IP-Stream
   begin
   cclient.readAPDU(IP_RX,IP_Bufpos);          //Read 1 IEC_APDU message out of the IP-stream
   end;

end;



function TIEC104Server.getClientindex(sender:TIEC104Socket):integer;
var
   x:integer;
   cclient:TIEC104Socket;
begin
result:=-1;
x:=0;
while x< fclientlist.Count do
   begin
   cclient:=TIEC104Socket(fclientlist[x]);
   if cclient = sender then
      begin
      result:=x;
      x:=1000;
      end;
   inc(x);
   end;
end;

function TIEC104Server.findClient(source:TLSocket):TIEC104Socket;
var
   x:integer;
   cclient:TIEC104Socket;
begin
result:=nil;
x:=0;
while x< fclientlist.Count do
    begin
    cclient:=TIEC104Socket(fclientlist[x]);
//    if clientstr = getclientAddress(client.FSocket) then
    if cclient.FSocket = source then
       begin
//       trace('found client in list:');
       result:=cclient;
       x:=1000;
       end;
    inc(x);
    end;
end;

 function TIEC104Server.GetPort:integer;
 begin
  result:=FserverSocket.Port;
 end;
 Procedure TIEC104Server.SetPort(Port:integer);
 begin
  FServerSocket.Port:=port;
 end;

 procedure TIEC104Server.SetActive(val:boolean);
 begin
 if  (not val)and (FServerSocket.Active) then
     begin
     while Fserversocket.Count > 0 do
        begin
        Fserversocket.Socks[0].Disconnect(True);
        Fserversocket.Socks[0].destroy;
        end;
     FServerSocket.Disconnect(true);
     end
 else
    begin
    FServerSocket.Listen(FServerSocket.port);
    if assigned(ontrace) then
       ontrace('start server sockets: '+inttostr(Fserversocket.Count));
    end;
  end;

 function TIEC104Server.GetClient(Index: Integer): TIEC104Socket;
 begin
   Result := TIEC104Socket(FClientlist[Index]);
 end;

 function TIEC104Server.getActive:Boolean;
 begin
   result:=FServerSocket.Active;
 end;

 Function TIEC104Server.GetClientAddress(Socket:TLSocket):string;
 begin
   result:=socket.peerAddress+':'+inttostr(socket.peerPort);
 end;

 //+++++++++++++++++++++++++++++++++++++
 //   TIECSocket    implementation
 //+++++++++++++++++++++++++++++++++++++

 constructor TIEC104Socket.Create;
 //constructor TIEC104Socket.Create(settings:TIEC104Settings);
 begin
   inherited Create;
   Ftimer:=TTimer.create(nil);
   Ftimer.OnTimer:=@irq;
   Ftimer.Enabled:=False;
   FIECSocketType:= TIECUnkwon;
   FAPDU_RX_count:=-1;
 //  Ftrl:=6;
   Fvr:=0;
   FVS:=0;
   Ftrl:=-1;
   FTIFilter:=0;
   FLinkStatus:=IECOFF;
   FtimerSet:=DefaultTimerset;
   FcounterSet.T1:=OFF;
 //  FProfile:=DefaultIECsettings.Profile;
 //  FStatus:=DefaultIECsettings.StatusInfo;
 end;

 Destructor TIEC104Socket.destroy;
 begin
   FTimer.Free;
   inherited destroy;
 end;

procedure TIEC104Socket.confirm;
begin
   case FAPDU_RX[2] of
       UStart: begin
               Fcounterset.k:=0;
               Fcounterset.w:=0;
//               FVR:=0;
//               FVS:=0;
               Fcounterset.T1:=off;
               Fcounterset.T2:=off;
               Fcounterset.T3:=datetimetotimestamp(now).time+FTimerset.T3; //polltime;
               sendStartAck;
               LinkStatus:=iecStartDT;
//               FLinkactive:=true;
//               StatusToDataOut;
               end;
       UStart_ack: begin
               Fcounterset.k:=0;
               Fcounterset.k:=0;
//               FVR:=0;
//               FVS:=0;
               Fcounterset.T1:=off;
               Fcounterset.T2:=off;
               Fcounterset.T3:=datetimetotimestamp(now).time+FTimerset.T3; //polltime;
//               FLinkactive:=true;
               LinkStatus:=iecStartDT;
//               StatusToDataOut;
               end;
       Utest: begin
               if FLinkStatus=IECInit then
                  LinkStatus:=iecStopDT;
               sendPollAck;
               end;
       Utest_ack: begin
               if FLinkStatus=IECInit then
                  LinkStatus:=iecStopDT;
               Fcounterset.T1:=off;
               end;
       Ustop: begin
               sendStopAck;
//               Flinkactive:=False;
               LinkStatus:=iecStopDT;
               end;
      UStop_ack:begin
                LinkStatus:=iecStopDT;
                end;
    end;
end;

procedure TIEC104Socket.irq(Sender: TObject);
var
 t0:integer;

begin
//trace('IRQ');
t0:=datetimetotimestamp(now).time;

// Try reconnect after t0
if (t0 > FcounterSet.T0) and (FPortactive = true) then
   begin
   if assigned(Fon0nTimerEvent) then
       Fon0nTimerEvent(self);
   end;

//Trace('now'+inttostr(t0)+'_T1_'+inttostr(Fcounterset.T1));
//Trace('_(T1)_'+inttostr(Fcounterset.T1-t0));
if (t0>Fcounterset.T1) then //Time untill my sendings has to be confirned is expired
   if (FLinkStatus<>IECINIT) then
       begin
//       Trace('_Missing confirmation (T1)_should close IP connection');
       Fcounterset.T1:=off;
       end;

//if (t0>Fcounterset.T2)and FLinkactive then
if (t0>Fcounterset.T2)and (FLinkStatus=iecStartDT) then
//Time i should send confirnetions is expired
   begin
   sendQuitt;
   end;

if (t0>Fcounterset.T3) and (Flinkstatus<>IECINIT) then
   begin
   if (FIECSocketType=TIECClient) then
      begin
      Sendpoll;
      Fcounterset.T1:=datetimetotimestamp(now).time+Ftimerset.T1; //wait for poll_ack;
      end;
   Fcounterset.T3:=datetimetotimestamp(now).time+Ftimerset.T3; //polltime;
   end;

if Fcounterset.k>FTimerset.k then  //too much sendings without ackwolegement
   begin
//   Trace('_missing confirmation (w)__should close IP connection');
   Fcounterset.k:=0;
   end;
end;

procedure TIEC104Socket.DisConnect;

begin
if not shutdown then
   if FlinkStatus<>IECOFF then
      begin
      if FlinkStatus<>IECINIT then
//          trace('Lost Connection to '+FSocket.peerAddress+':'+inttostr(Fsocket.peerPort));
      FlinkStatus:=IECINIT;
      FCounterset.T0:=datetimetotimestamp(now).time+Ftimerset.T0; //reconnecttime;
//      StatusToDataOut(False);
      end;
end;

procedure TIEC104Socket.readAPDU(ip_rx:array of byte;var IP_Bufpos:integer);  //copy 1 IEC message out of the IP-stream
var
   i:integer;
   s:string;
begin

 if ip_rx[IP_bufpos]=ID_104 then
    begin
    if FAPDU_RX_Count<= -1 then // a new APDU should start
      begin
      FAPDUlength:=ip_rx[ip_bufpos+1]+2;   //get length of new APDU message in IP stream
      FAPDU_RX_Count:=Fapdulength;         // count how many Bytes are missed for the complet APDU
      end;

//    trace('read '+inttostr(FAPDU_RX_Count)+' bytes from offset: '+inttostr(IP_bufpos));
      repeat
         FAPDU_RX[FAPDUlength-FAPDU_RX_count]:=ip_RX[IP_bufpos];
         inc(IP_bufpos);
         dec(FAPDU_RX_count);
      until (FAPDU_RX_count=0)  // End fo IEC message reached
            or (IP_bufpos = Fip_rx_count);  //end of IP stream reached (Fip_rx_count= length of IP stream)

     if FAPDU_RX_count=0 then  //End fo IEC message reached --> APDU Complet ??
        begin
        if (Ftrl > -1)and (FAPDUlength >Ftrl) then
           begin
           i:=Ftrl;  s:='';    //   Ftrl Byte-pos for Trace
           s:=BufferToHexStr(PByte(FAPDU_RX[Ftrl]),FAPDUlength-Ftrl);
//           trace('RX['+inttostr(FAPDUlength-FTrl)+'] '+s);
           end;
        readAPCI;
        FAPDU_RX_count:=-1;   // APDU complet reset APDU length counter
        end      //END APDU complet
     else
        begin       // APDU NOt Yet Complet
//        trace('_!_IP_Stream to short_!_');
//        trace('_'+inttostr(FIP_RX_Count)+' IP Stream-Bytes recived');
//        trace('_need '+inttostr(FAPDU_RX_Count)+' more bytes from next IP Stream: ');
        end;
     end       // END first byte OK
 else
//     trace('_APDU NOT starts with Byte $68 --> exit');
end;

procedure TIEC104Socket.ReadASDU;
   var
    tvr:integer;
    x:integer;
    asdu:array[0..249] of byte;
//    res:T104_Res;
   begin
   update_VS;
   tvr:=(FAPDU_RX[2]+FAPDU_RX[3]*256)shr 1;  //read sendsequenc
   if tvr<>fvr then
      begin
//      trace('_Sequenzerror recived '+inttostr(tvr)+' expect '+inttostr(Fvr));
      fvr:= tvr;  //fix Sequenz value
      end;
   inc(fvr);         //inc incomming since my last confirmation
   inc(Fcounterset.w);
   if Fcounterset.w>FTimerSet.w-1 then
      begin
      Fcounterset.T2:=0;
      Fcounterset.w:=0;
      end;
   if Fcounterset.T2=off then
      Fcounterset.T2:=datetimetotimestamp(now).time+FTimerSet.T2; //quiettimer;
   FASDUlength:=FAPDU_RX[1]-4;

   for x:=0 to FASDUlength-1 do
      asdu[x]:=FAPDU_Rx[x+6];
  //   trace('data recived');
   Fcounterset.T3:=datetimetotimestamp(now).time+FTimerSet.T3; //polltime; //update pollingtime

//TRXEvent = procedure(Sender: TObject;const Buffer,count :integer)
   if assigned(FonRXData) then
        FonRXData(self,ASDU,FASDULength);
end;

procedure TIEC104Socket.update_VS;
var
  tvs:integer;
begin
 tvs:=(FAPDU_RX[4]+FAPDU_RX[5]*256)shr 1; //read confirmation from partner
 if tvs=Fvs then
    begin
    Fcounterset.T1:=off;
    Fcounterset.k:=0;
    end;
end;

procedure TIEC104Socket.readAPCI;
var APCI:byte;
begin
  APCI:=FAPDU_RX[2] and $03;
  if APCI=U_Frame then
    begin
    confirm;
    end;
  if APCI=S_Frame then
    begin
    update_Vs;
    end;
  if (APCI and $01)=I_Frame then
    begin
    readASDU;
    end;
end;

procedure TIEC104Socket.setActive(val:boolean);
begin
//if val<>FPortActive then
//   begin
   if val then
      begin
      Fvr:=0;
      FVS:=0;
      FcounterSet.T0:=off;
      FcounterSet.T1:=off;
      LinkStatus:=IECINIT;
      Ftimer.Enabled:=True;
      end
   else
      begin
      LinkStatus:=IECOFF;
      Ftimer.Enabled:=False;
      end;
   FPortActive:=val;
//   end;
end;

procedure TIEC104Socket.sendHexStr(var s:string);
var
  count:integer;
  cbuf:array[0..100]of char;
  buf:array[0..100]of byte absolute Cbuf;
begin
  while pos(' ',s)<>0 do
     delete(s,pos(' ',s),1);
  if s<>'' then
     begin
     s:=lowercase(s);
     count:=  hextobin(pchar(s),cbuf,100);
//     trace(inttostr(Count));
     if count >0 then
         begin
         sendbuf(buf,count);
         s:=BufferToHexStr(@buf,count);
         end;
     end;
end;

//procedure TIEC104Socket.sendBuf(var buf: array of byte; count:integer);
procedure TIEC104Socket.sendBuf(buf: array of byte; count:integer);
//procedure TIEC104Socket.sendasdu(Sender: TObject;Socket: TCustomWinSocket;count:integer;const asdu_tx:array of byte);
var
   tvs,tvr:word;
   i:integer;
   str:string;
begin
  str:='TX: ';
  tvs:=Fvs shl 1;
  tvr:=Fvr shl 1;
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=count+4;
  FAPDU_TX[2]:=tvs mod 256;
  FAPDU_TX[3]:=tvs div 256;
  FAPDU_TX[4]:=tvr mod 256;
  FAPDU_TX[5]:=tvr div 256;
  FAPDU_TX_count:=count+6;
  for i:=0 to count-1 do
//    FAPDU_tx[6+i]:=asdu_TX[i];
    FAPDU_tx[6+i]:=buf[i];
  FAPDU_TX_count:=count+6;
  inc(Fvs);      //variable send
  inc(Fcounterset.k); //counter sended messages
  Fcounterset.T1:=datetimetotimestamp(now).time+Ftimerset.T1;
//  Trace('now'+inttostr(datetimetotimestamp(now).time)+'_(T1)_'+inttostr(Fcounterset.T1));
  send;
end;

procedure TIEC104Socket.send;
var
  count,x:integer;
  str:string;
  asdu:array[0..249] of byte;
begin
if Fsocket<>nil then
    Fsocket.Send(FAPDU_TX,FAPDU_TX_Count);

//Fcounterset.T1:=datetimetotimestamp(now).time+Ftimerset.T1;
if (Ftrl > -1) then
   begin
   count:=0;
   for x:=0 to FAPDU_TX_count-1 do
      begin
      if x >= Ftrl then
         str:=str+inttohex(FAPDU_TX[x],2)+' ';
      if x>5 then
          begin
          asdu[count]:=FAPDU_TX[x];
          inc(count);
          end;
      end;
   if (str<>'') then
//      trace('TX['+inttostr(FAPDU_TX_Count-Ftrl)+'] '+str);
   end;

 if (count > 0) and assigned(FonTXData) then
        FonTXData(self,ASDU,count);
end;

procedure TIEC104Socket.SetLinkstatus(val:TIEC104LinkStatus);
begin
if (val<>Flinkstatus) then
   begin
   FLinkStatus:=val;
//   if assigned(FOnLinkEvent) then
//       FOnlinkEvent(self,FLinkStatus);
   end;
end;

procedure TIEC104Socket.SendQuitt;
var
   tvr:integer;
begin
 tvr:=Fvr shl 1;
FAPDU_TX[0]:=ID_104;
FAPDU_TX[1]:=$04;
FAPDU_TX[2]:=s_frame;
FAPDU_TX[3]:=$00;
FAPDU_TX[4]:=tvr mod 256;
FAPDU_TX[5]:=tvr div 256;
FAPDU_TX_count:=6;
Fcounterset.w:=0;
Fcounterset.T2:=off;
send;
end;

Procedure TIEC104Socket.SendStart;
  begin
  Fvr:=0;
  FVS:=0;
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Ustart;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  Fcounterset.T1:=datetimetotimestamp(now).time+Ftimerset.T1; //wait for Start_ack;
  send;
end;

Procedure TIEC104Socket.SendStartAck;
  begin
  Fvr:=0;
  FVS:=0;
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Ustart_ack;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  send;
  end;

Procedure TIEC104Socket.SendStopAck;
  begin
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Ustop_ack;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  send;
  end;

Procedure TIEC104Socket.SendStop;
  begin
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Ustop;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  send;
  end;

Procedure TIEC104Socket.Sendpoll;
  begin
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Utest;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  send;
  end;

Procedure TIEC104Socket.SendpollAck;
  begin
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Utest_ack;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  send;
  end;

procedure TIEC104Socket.SettimerActive(val:Boolean);
begin
Ftimer.Enabled:=val;
if val=false then
  begin
  sendStop;
  end;
end;

end.

