unit IEC104Sockets;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, lNetComponents, LNet, LEvents, ExtCtrls,TLoggerUnit, simplelog;
//
Type

TIEC104Socket = class;

TIECSocketEvent = procedure (Sender: TObject; Socket: TIEC104Socket) of object;

TRTXEvent = procedure(Sender: TObject;const Buffer:array of byte;count :integer) of object;

TIECSocketType= (TIECUnkwon,TIECClient,TIECServer,TIECMonitor);
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

{ TIEC104Server }

TIEC104Server = class(TLTCPComponent)
     private
 //       Fname: String;
//        FIECSettings:TIEC104Settings;  //Server asign settings to all sockets
        FIECTimers:TIEC104TimerSet;
        FClientlist:TList;
//        FOnTraceEvent: TGetStrProc;
        FOnClientCOnnect: TIECSocketEvent;
        FOnClientDisCOnnect: TIECSocketEvent;
        FOnClientRead: TRTXEvent;
        FOnClientSend: TRTXEvent;
        FLogg: TLogger;
//        FLog: TLog ;
        procedure SetActive(val:boolean);
        function getActive:Boolean;
     protected
        Procedure SetName(const NewName: TComponentName); override;

        procedure AcceptEvent(aSocket: TLHandle); override;
        procedure ReceiveEvent(aSocket: TLHandle); override;
        procedure DisconnectEvent(aSocket: TLHandle); override ;
        procedure ErrorEvent(aSocket: TLHandle; const msg: string); override;

       Function GetClientAddress(Socket:TLSocket):string;
       function GetClient(Index: Integer): TIEC104Socket;
       function FindClient(source:TLSocket):TIEC104Socket;
       function getClientindex(sender:TIEC104Socket):integer;
       Procedure setOnClientRead(proc: TRTXEvent);
       Procedure setOnClientSend(proc: TRTXEvent);
//       function GetTimers: TIEC104Timerset;
//       procedure SetTimers(timers:TIEC104Timerset);
//       procedure SetLogEvent(proc:TGetStrProc);
//       procedure trace(s:string);
     public
       constructor Create(AOwner: Tcomponent);override;
       destructor destroy; override;
       procedure ClientClose(Client: TIEC104Socket);
//       procedure clientClose(Name:string);
       property Clients:TList read FClientList;
       property Client[Index: Integer]: TIEC104Socket read GetCLient;
//       function Edit(clientindex:integer):TIEC104Settings;
       property Timers:TIEC104Timerset read FIECTimers write FIECTimers;
     published
       property Port;
 //      property Log:Tlog read Flog write Flog;
       property Logger:Tlogger read Flogg write Flogg;
       property Active:Boolean read getActive write SetActive;
//       property Timers:TIEC104Timerset read getTimers write SetTimers;
       property onClientConnect: TIECSocketEvent read FOnClientCOnnect write FOnClientCOnnect;
       property onClientDisConnect: TIECSocketEvent read FOnClientDisConnect write FOnClientDisConnect;
       property onClientRead: TRTXEvent read FOnClientRead write SetOnClientRead;
       property onClientSend: TRTXEvent read FOnClientSend write SetOnClientSend;
//       property onTrace: TGetStrProc read FonTraceEvent write FonTraceEvent;
//       property onLogEvent: TGetStrProc write SetLogEvent;
    end;


{ TIEC104Socket }

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
    Fip_tx:   array[0..1500]of byte;
    FAPDU_TX_Count:integer;
    FAPDU_Rx:   array[0..255]of byte;
    FAPDU_RX_Count:integer;
    FAPDUlength:      integer;
    FASDUlength:      integer;
    FTIFilter:  byte; // Type Identification filter;
    FVR:        integer;  // Receive variable
    FVS:        integer;  // send variable
    FStatus:    TIECStatusinfo;
//    FOnTraceEvent: TGetStrProc;
    Flog:Tlog;
    FOnRXData: TRTXEvent;
    FOnTXData: TRTXEvent;
    FOn0nTimerEvent:  TNotifyEvent;
    FSocket: TLSocket;
    Fip_rx_count:integer;
    Fip_tx_count:integer;
    Fsend: boolean;
    Fwrite:boolean;
    procedure confirm;
    procedure setName(AValue: String);
  protected
    LogRStr:String;
    LogSStr:String;
    Procedure irq(Sender: TObject);
//    procedure connect(Sender: TObject;Socket: TCustomWinSocket);
    procedure DisConnect;
    procedure readAPDU(ip_rx:array of byte;var IP_Bufpos:integer);
    procedure readAPCI;
    procedure ReadASDU;
    procedure update_VS;
    procedure setActive(val:boolean);
    procedure setLinkStatus(val:TIEC104LinkStatus);
    procedure writeStream;
    procedure sendStream;
    procedure send;
    procedure SendStartAck;
    procedure SendStopAck;
    procedure SendPoll;
    procedure SendPollAck;
    procedure SendQuitt;
    procedure settimeractive(val:boolean);
    procedure setSocketType(s:TIECSocketType);
  public
    constructor Create;
    destructor destroy; override;
    procedure SendStart;
    procedure SendStop;
//    procedure showSetupDialog;
//    Procedure DecodeStream(ip_rx:array of byte);
    Procedure DecodeStream(ip_rx:array of byte);
//    procedure readAPDU(ip_rx:array of byte;var IP_Bufpos:integer);
    procedure sendBuf(buf:array of byte; count:integer;direct:boolean);
    procedure sendHexStr(var s:string);

    property Name:String read FName write setName;
    property SocketType:TIECSocketType read FIECSocketType write setSocketType;
    property Log:Tlog read Flog write Flog;
    property active:boolean read FportActive write setActive;
//    property StreamCount:integer read FAPDU_RX_Count write FAPDU_RX_Count;
    property StreamCount:integer read Fip_rx_count write Fip_rx_count;
    property RXCount: Integer read FVR;
    property TXCount: Integer read FVS;
//    property onTraceEvent: TGetStrProc read FOnTraceEvent write FOnTraceEvent;
    property onRXData: TRTXEvent read FonRXData write FonRXData;
    property onTXData: TRTXEvent read FonTXData write FonTXData;
    property onOnTimerEvent: TNotifyEvent read Fon0nTimerEvent write Fon0nTimerEvent;
    property ASDULength: integer read FASDULength write FASDULength;
//    property Traceon: boolean read Ftraceon write Ftraceon;
    property ID: integer read FID write FID;
    property TIFilter: byte read FTIFilter write FTIFIlter;
    property TimerSet: TIEC104TimerSet read FtimerSet write FTimerSet;
    property Status: TIECStatusInfo read FStatus write FStatus;
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
  S_Frame=$01;U_Frame=$03;I_Frame=$00;//Unknown=-1;
  UStart=$07; UStart_ack=$0B;  // 0000 0111   0000 1011
  UStop=$13;  UStop_ack=$23;   // 0001 0011   0010 0011
  Utest=$43;  Utest_ack=$83;   // 0100 0011   1000 0011

 function BufferToHexStr(const buf:array of byte;count:integer):string;
  var
    x:integer;
 begin
  result:='';
  for x:=0 to count-1 do
     begin
     result:=result+inttohex(buf[x],2)+' ';
//     inc(buf);
     end;
end;

 function DefaultTimerset: TIEC104Timerset;
 begin
   result.T0:=30000;
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
// Fname:=Name;
 Fiectimers:=DefaultTimerset;
 Port:=2404;
 FClientlist:=TList.Create;
 //Log := Tlog.Create;
 Logger :=TLogger.GetInstance('IECServer');
  end;

 Destructor TIEC104Server.destroy;
 begin
   FClientlist.Destroy;
//   FServerSocket.free;
   inherited destroy;
 end;

 procedure TIEC104Server.ClientClose(Client: TIEC104Socket);
var
 x,i:integer;
begin
 i:=Fclientlist.IndexOf(client);
{
For x:=0 to serverSocket.Count-1 do
    if GetClientAddress(serverSocket.Socks[x]) = client.FName then
        begin
        FserverSocket.Socks[i].Disconnect(true);
        FserverSocket.Socks[i].Destroy;
        end;
}
end;

procedure TIEC104Server.DisconnectEvent(aSocket: TLHandle);
var
   iecsock:TIEC104Socket;
   s:string;
   socket:TLSocket;
begin
 socket:=TLSocket(asocket);
 s:=getclientAddress(socket);
 iecsock:=Findclient(socket);
 logger.info('Connection closed: '+s) ;
 if iecsock <> nil then
 //if i <> 0 then
    begin
    logger.debug('Found client in list  ID:'+inttostr(iecsock.ID)+' DELETE');
    Fclientlist.Delete(getclientindex(iecsock));
    iecsock.FSocket:=nil;
    if assigned(FonclientDisconnect) then
        FonclientDisConnect(self,iecsock);
    iecsock.destroy;
    end;
// log.debug('disconnect- sockets count:'+inttostr(count));
end;

procedure TIEC104Server.ErrorEvent(aSocket: TLHandle; const msg: string);
var
   socket:TLSocket;
begin
  socket:=TLSocket(asocket);
  logger.error('Event: '+msg);
  socket.Disconnect(true);
  inherited ErrorEvent(aSocket,msg);
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


procedure TIEC104Server.AcceptEvent(aSocket: TLHandle);
var
 iecsock:TIEC104Socket;
 socket: TLSocket;
 adr:string;
begin
  socket:=TLSocket(asocket);
  adr:=getclientAddress(socket);

  iecsock:=TIEC104Socket.Create;
//  iecsock.Log.LogAppender:=log.LogAppender;
//      iecsock.Log.LogLevel:=lDEBUG;
  iecsock.SocketType:=TIECServer;
  iecsock.FSocket:=socket;
  iecsock.FID:=fclientlist.Add(iecsock);
  iecsock.Name:=adr;
  iecsock.onRXData:=FOnClientRead;
  iecsock.onTXData:=FOnClientSend;
  iecsock.Ftimer.Enabled:=TRUE;

  logger.info('ClientConect: '+adr+'  ID: '+inttostr(iecsock.Fid));
//log.info('ClientConect: '+adr);
  logger.debug('No. of connected sockets :'+inttostr(count-1));

  if assigned(Fonclientconnect) then
      FonclientConnect(self,iecsock);

  inherited AcceptEvent(aSocket);
end;

procedure TIEC104Server.ReceiveEvent(aSocket: TLHandle);
var
  ip_rx:array[0..1500]of byte;
  c,ip_bufpos:integer;
  iecsock:TIEC104Socket;
  socket: TLSocket;
begin
   socket:=TLSocket(asocket);
   iecsock:=findclient(socket);
   if iecsock= nil then
      begin
      c:=Get(IP_RX,1500,socket);
      if c>0 then
        logger.debug(' IP Stream '+inttostr(c)+'-Bytes recived '+getclientAddress(socket));
      inherited ReceiveEvent(aSocket);
      exit;
      end;
   IECSock.StreamCount:=Get(IP_RX,1500,socket);
   if IECSock.StreamCount>0 then
     begin
     logger.debug(inttostr(iecsock.FIP_RX_count)+' IP Stream-Bytes recived from ID:'+inttostr(iecsock.ID)+' '+getclientAddress(socket));
     IECSock.DecodeStream(IP_RX);
     end;
  inherited ReceiveEvent(aSocket);
end;

procedure TIEC104Server.SetActive(val:boolean);
 begin
//    if  (not val)and (connected) then
  if  (val=false) then
     begin
     while clients.Count > 0 do
        begin
        client[clients.Count-1].FSocket:=nil;
        client[clients.Count-1].destroy;
        Fclientlist.Delete(clients.Count-1);
        end;
     Disconnect(true);
     logger.info('stop server.');
     end
 else
    begin
    Listen(port);
    logger.info('start server on port '+inttostr(port));
    end;
  end;

 function TIEC104Server.GetClient(Index: Integer): TIEC104Socket;
 begin
   Result := TIEC104Socket(FClientlist[Index]);
 end;

 function TIEC104Server.getActive:Boolean;
 begin
   result:=Connected;
 end;

 procedure TIEC104Server.SetName(const NewName: TComponentName);
begin
  inherited SetName(NewName);
//  logger.name:= name;
end;

 Function TIEC104Server.GetClientAddress(Socket:TLSocket):string;
 begin
// result:=socket.PeerAddress+':'+inttostr(socket.peerPort);
 result:=socket.LocalAddress+':'+inttostr(socket.LocalPort);
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
   FIP_TX_count:=0;
   Fvr:=0;
   FVS:=0;
   FTIFilter:=0;
   FLinkStatus:=IECOFF;
   FtimerSet:=DefaultTimerset;
   FcounterSet.T1:=OFF;
   Flog:= Tlog.Create;
 end;

 Destructor TIEC104Socket.destroy;
 begin
   FTimer.Free;
   log.debug('Destroy Socket');
   flog.Destroy;
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
               LogRStr:='uStaA';
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
               LogRStr:='uStaC';
              end;
       Utest: begin
               if FLinkStatus=IECInit then
                  LinkStatus:=iecStopDT;
               sendPollAck;
               Fcounterset.T3:=datetimetotimestamp(now).time+FTimerset.T3;
               LogRStr:='uTstA';
               end;
       Utest_ack: begin
               if FLinkStatus=IECInit then
                  LinkStatus:=iecStopDT;
               Fcounterset.T1:=off;
               LogRStr:='uTstC';
               end;
       Ustop: begin
               sendStopAck;
//               Flinkactive:=False;
               LinkStatus:=iecStopDT;
               LogRStr:='uStoA';
               end;
      UStop_ack:begin
                LinkStatus:=iecStopDT;
                LogRStr:='uTstC';
                end;
    end;
end;

procedure TIEC104Socket.setName(AValue: String);
begin
  if FName=AValue then Exit;
  FName:=AValue;
  log.Name:=FName;
end;

procedure TIEC104Socket.irq(Sender: TObject);
var
 t0:integer;

begin
//log.debug('IRQ');
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
       log.warn('_Missing confirmation (T1)_should close IP connection');
       Fcounterset.T1:=off;
       end;

//if (t0>Fcounterset.T2)and FLinkactive then
if (t0>Fcounterset.T2)and (FLinkStatus=iecStartDT) then
//Time i should send confirnetions is expired
   begin
   log.debug('(T2) expired send Quitt');
   sendQuitt;
   end;

if (t0>Fcounterset.T3) and (Flinkstatus<>IECINIT) then
   begin
   if (FIECSocketType=TIECClient) then
      begin
      log.debug('(T3) expired send poll');
      Sendpoll;
      Fcounterset.T1:=datetimetotimestamp(now).time+Ftimerset.T1; //wait for poll_ack;
      Fcounterset.T3:=datetimetotimestamp(now).time+Ftimerset.T3; //reload next polltime;
      end;
   if (FIECSocketType=TIECServer) then
      begin
      log.warn(' Missing Polling fron client(T3)');
      Fcounterset.T3:=datetimetotimestamp(now).time+Ftimerset.T3; //polltime;
      end;
   end;

if Fsend= true then
     send;
if (Fip_tx_count >0) and (Fwrite=False) then
   sendStream;

if Fcounterset.k>FTimerset.k then  //too much sendings without ackwolegement
   begin
   log.warn(' missing confirmation (w)__should close IP connection');
   Fcounterset.k:=0;
   end;
end;

procedure TIEC104Socket.DisConnect;

begin
if not shutdown then
   if FlinkStatus<>IECOFF then
      begin
      if FlinkStatus<>IECINIT then
          log.debug('Lost Connection to '+FSocket.peerAddress+':'+inttostr(Fsocket.peerPort));
      FlinkStatus:=IECINIT;
      FCounterset.T0:=datetimetotimestamp(now).time+Ftimerset.T0; //reconnecttime;
//      StatusToDataOut(False);
      end;
end;

Procedure TIEC104Socket.DecodeStream(ip_rx:array of byte);
var
   IP_bufpos: integer;
begin
 IP_bufpos:=0;
 while ip_bufpos < Fip_rx_count do     // there could be moe than 1 APDU in a IP-Stream
    begin
    readAPDU(IP_RX,IP_Bufpos);          //Read 1 IEC_APDU message out of the IP-stream
    end;

end;


procedure TIEC104Socket.readAPDU(ip_rx:array of byte;var IP_Bufpos:integer);  //copy 1 IEC message out of the IP-stream
var
   offsetstr,s:string;
begin

 if ip_rx[IP_bufpos]=ID_104 then
    begin
    if FAPDU_RX_Count<= -1 then // a new APDU should start
      begin
      FAPDUlength:=ip_rx[ip_bufpos+1]+2;   //get length of new APDU message in IP stream
      FAPDU_RX_Count:=Fapdulength;         // count how many Bytes are missed for the complet APDU
      end;

      offsetstr:=inttostr(IP_bufpos);
      repeat
         FAPDU_RX[FAPDUlength-FAPDU_RX_count]:=ip_RX[IP_bufpos];
         inc(IP_bufpos);
         dec(FAPDU_RX_count);
      until (FAPDU_RX_count=0)  // End fo IEC message reached
            or (IP_bufpos = Fip_rx_count);  //end of IP stream reached (Fip_rx_count= length of IP stream)

     if FAPDU_RX_count=0 then  //End fo IEC message reached --> APDU Complet ??
        begin
        logRstr:='';

        readAPCI;
        FAPDU_RX_count:=-1;   // APDU complet reset APDU length counter

        if (log.LogLevel=linfo)and (FAPDUlength >6) then
            begin
            s:=BufferToHexStr(FAPDU_RX[6],FAPDUlength-6);
            log.info('R['+inttostr(FAPDUlength-6)+'] '+s);
            end;
         if (log.LogLevel=ldebug) then
            begin
            s:=BufferToHexStr(FAPDU_RX,FAPDUlength);
            log.debug('R'+logRstr+'['+inttostr(FAPDUlength)+'/'+offsetstr+'] '+s);
            end;

        if Fsend then send;
        end      //END APDU complet
     else
        begin       // APDU NOt Yet Complet
        log.warn('_!_IP_Stream to short_!_');
        log.debug('_'+inttostr(FIP_RX_Count)+' IP Stream-Bytes recived');
        log.debug('_need '+inttostr(FAPDU_RX_Count)+' more bytes from next IP Stream: ');
        end;
     end       // END first byte OK
 else
     begin
     log.fatal('APDU NOT starts with Byte $68 idx:'+inttostr(IP_bufpos)+' '+BuffertoHexStr(ip_rx[IP_bufpos],6)+' ...--> exit');
     ip_bufpos:=Fip_rx_count;
     end;
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
   if (tvr<>fvr) and (FIECSocketType<>TIECMonitor) then
      begin
      log.error(' Sequenc recived '+inttostr(tvr)+' expect '+inttostr(Fvr));
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
var
   APCI:byte;
begin
  Fsend := false;
  APCI:=FAPDU_RX[2] and $03;
  if APCI=U_Frame then
    begin
    if FIECSocketType<>TIECMonitor then
      confirm;
    end;
  if APCI=S_Frame then
    begin
    update_Vs;
    LogRStr:='s'+inttostr(Fvr);
    end;
  if (APCI and $01)=I_Frame then
    begin
    readASDU;
    LogRStr:='i'+inttostr(Fvr);
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
         sendbuf(buf,count,true);
         s:=BufferToHexStr(buf,count);
         end;
     end;
end;

//procedure TIEC104Socket.sendBuf(var buf: array of byte; count:integer);
procedure TIEC104Socket.sendBuf(buf: array of byte; count:integer;direct:boolean);
var
   tvs,tvr:word;
   i:integer;
begin
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
     FAPDU_tx[6+i]:=buf[i];

  FAPDU_TX_count:=count+6;
  inc(Fvs);      //variable send
  inc(Fcounterset.k); //counter sended messages
  Fcounterset.T1:=datetimetotimestamp(now).time+Ftimerset.T1;

//  Trace('now'+inttostr(datetimetotimestamp(now).time)+'_(T1)_'+inttostr(Fcounterset.T1));
  if direct then
    send
  else
    writestream;
end;

procedure TIEC104Socket.writestream;
var
  s:String;
begin
 Fwrite:=True;  // Block timmer straemsend  action while update stream

 LogSStr:='i'+inttostr(Fvs);
 if (log.LogLevel=linfo)and (FAPDU_TX_Count >6) then
      begin
      s:=BufferToHexStr(FAPDU_TX[6],FAPDU_TX_Count-6);
      log.info('S['+inttostr(FAPDU_TX_Count-6)+'] '+s);
      end;
   if (log.LogLevel=ldebug) then
      begin
      s:=BufferToHexStr(FAPDU_TX,FAPDU_TX_Count);
      log.debug('S'+logSstr+'['+inttostr(FAPDU_TX_Count)+'/'+inttostr(Fip_TX_Count)+'] '+s);
      end;
 move(FAPDU_TX,FIP_TX[Fip_TX_Count],FAPDU_TX_Count);
 Fip_TX_Count:=Fip_TX_Count+FAPDU_TX_Count;
 if  Fip_TX_Count>1000 then
    sendstream;

 Fwrite:=False;
end;

procedure TIEC104Socket.sendStream;
var
  s:String;
begin
if Fsocket<>nil then
   Fsocket.Send(Fip_TX,Fip_TX_Count);

// Logging
log.debug('Send IP_TX_Length: '+inttostr(Fip_tx_Count));
Fip_TX_Count:=0;

 if (FAPDU_TX_Count > 6) and assigned(FonTXData) then
        FonTXData(self,FAPDU_TX[6],FAPDU_TX_Count-6);
end;


procedure TIEC104Socket.send;
var
  s:String;
begin
if Fsocket<>nil then
   Fsocket.Send(FAPDU_TX,FAPDU_TX_Count);

// Logging
if (log.LogLevel=linfo)and (FAPDU_TX_Count >6) then
    begin
    s:=BufferToHexStr(FAPDU_TX[6],FAPDU_TX_Count-6);
    log.info('S['+inttostr(FAPDU_TX_Count-6)+'] '+s);
    end;
 if (log.LogLevel=ldebug) then
    begin
    s:=BufferToHexStr(FAPDU_TX,FAPDU_TX_Count);
    log.debug('S'+logSstr+'['+inttostr(FAPDU_TX_Count)+'] '+s);
    end;

 Fsend:= false;

 if (FAPDU_TX_Count > 6) and assigned(FonTXData) then
        FonTXData(self,FAPDU_TX[6],FAPDU_TX_Count-6);
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
logSstr:='s'+inttostr(Fvr);
Fsend:=true;
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
  logSstr:='uStarA';
  Fsend:=true;
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
  logSstr:='uStarC';
  Fsend:=true;
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
  logSstr:='uStopC';
  Fsend:=true;
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
  logSstr:='uStopA';
  Fsend:=true;
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
  logSstr:='uTstA';
  Fsend:=true;
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
  logSstr:='uTstC';
  Fsend:=true;
  end;

procedure TIEC104Socket.SettimerActive(val:Boolean);
begin
Ftimer.Enabled:=val;
if val=false then
  begin
  sendStop;
  end;
end;

procedure TIEC104Socket.setSocketType(s: TIECSocketType);
begin
 if s= TIECServer then
    Ftimerset.T3:=Ftimerset.T0;
 FIECsockettype:=s;
end;

end.

