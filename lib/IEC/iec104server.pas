unit IEC104Server;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  IEC104Socket,
  sockets,  blcksock,
  TLoggerUnit, TLevelUnit, cliexecute;

type

  { TIEC104Server }
//  TIEC104Server = class(TObject)
  TIEC104Server = class(TComponent)
       private
         Fth:TThreadID;
         Fsocket: TTCPBlockSocket;
   //       Fname: String;
  //        FIECSettings:TIEC104Settings;  //Server asign settings to all sockets
          FIECTimers:TIEC104TimerSet;
          FConnectionList:TList;
          Fport: integer;
          FOnClientCOnnect: TIECSocketEvent;
          FOnClientDisCOnnect: TIECSocketEvent;
          FOnClientRead: TRTXEvent;
          FOnClientSend: TRTXEvent;
          FLog: TLogger;
          Frun :  boolean;
       protected
          procedure log(ALevel : TLevel; const AMsg : String);
          Procedure SetName(const NewName: TComponentName); override;
          procedure AcceptEvent(iSocket: TIEC104Socket);
          procedure DisconnectEvent(iSocket: TIEC104Socket);
         Function GetClientAddress(Socket:TTCPBlockSocket):string;
         function GetClient(Index: Integer): TIEC104Socket;
         function FindClient(source:TTCPBlockSocket):TIEC104Socket;
         function getClientindex(sender:TIEC104Socket):integer;
         Procedure setOnClientRead(proc: TRTXEvent);
         Procedure setOnClientSend(proc: TRTXEvent);
       public
         constructor Create(AOwner: Tcomponent);override;
         destructor destroy; override;
         procedure start;
         procedure stop;
         Function send(hexstr:String):integer;
         Function send(hexstr:String;con:integer):integer;
         procedure sendBuf(buf: array of byte);
         procedure sendBuf(buf: array of byte;con:integer);
         procedure ClientClose(index :integer);
         property Connections:TList read FConnectionList;
         property Connection[Index: Integer]: TIEC104Socket read GetCLient;
         property Timers:TIEC104Timerset read FIECTimers write FIECTimers;
       published
         Property Socket:TTCPBlockSocket read Fsocket write Fsocket;
         property Port:integer read Fport write Fport;
         property Logger:Tlogger read Flog write Flog;
         property Activ:Boolean read Frun;
  //       property Timers:TIEC104Timerset read getTimers write SetTimers;
         property onClientConnect: TIECSocketEvent read FOnClientCOnnect write FOnClientCOnnect;
         property onClientDisConnect: TIECSocketEvent read FOnClientDisConnect write FOnClientDisConnect;
         property onClientRead: TRTXEvent read FOnClientRead write SetOnClientRead;
         property onClientSend: TRTXEvent read FOnClientSend write SetOnClientSend;
      end;

implementation

type

  TRunRun = class
      server: TIEC104Server;
      sock:Tsocket;
    end;


function runsock(p: Pointer): ptrint;
var
  r: TRunRun;
  ip_rx:array[0..1500]of byte;
  clsock :TTCPBlockSocket;
  iecsock :TIEC104Socket;
  server: TIEC104Server;
  recv:integer;
begin
  r := TRunRun(p);
  server := TIEC104Server(r.server);

  clsock:=TTCPBlockSocket.create;
  clsock.socket:=r.sock;
  clsock.GetSins;
  iecsock:=TIEC104Socket.Create;
  iecsock.ID := GetThreadID;
//  iecsock.ID:=
  recv:=server.Connections.Add(iecsock);
  iecsock.Socket:=clsock;

  Server.AcceptEvent(iecsock);
  server.log(debug,' runsock for: '+clsock.GetRemoteSinIP);

 recv:=1;
 repeat
    server.log(debug,'ThreadID:'+inttoStr(GetThreadID)+' Wait for Data');//+asocket.GetRemoteSinIP);
    recv:=clSock.RecvBufferFrom(@IP_RX,1500);
    server.log(debug,' IP Stream '+inttostr(recv)+'-Bytes recived ');//+getclientAddress(socket));
    IECSock.StreamCount:=recv;
    IECSock.DecodeStream(IP_RX);
 //    sleep(2000);
  until recv<=0;
  if (server.Frun) then
     server.log(Error,'ThreadID:'+inttoStr(GetThreadID)+' sock_ERROR: '+inttostr(clsock.lastError));

  Server.DisconnectEvent(iecsock);

  iecsock.Stop;
  clsock.CloseSocket;
  server.Connections.Delete(server.Connections.IndexOf(iecsock));

  Freeandnil(clsock);
  freeandnil(IecSock);
  server.log(debug,'ThreadID:'+inttoStr(GetThreadID)+' EXIT');
end;

function run(p: Pointer): ptrint;
var
 server: TIEC104Server;
 sock:TSocket;
 clsock:TTCPBlockSocket ;
 terminated:boolean;
 txt:string;
 r: TRunRun;
 i:integer;
begin
    server := TIEC104Server(p);
    server.socket.Listen;
    server.log(info,'start listen on port '+inttostr(Server.port));
    repeat
       server.log(debug,'wait_accept');
       sock:=server.socket.Accept;
       i := clsock.lastError;
//       if (i=0) then begin
         if (server.Frun) then
            begin
            server.log(Info,'_doAccept_');
            r:= TRunRun.Create;
            r.server:=server;
            r.sock:=sock;
            BeginThread(@runsock,r);
  //            Server.AcceptEvent(clsock);
//             end;
         end
       else server.log(Error,'_listen_ERROR: '+inttostr(i)+' '+clsock.GetErrorDesc(i));
      server.log(debug,'EXIT-accept');
   until (not server.Frun);
   server.Socket.CloseSocket;
   server.log(debug,'EXIT-Listen');
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
  FConnectionList:=TList.Create;
end;

Destructor TIEC104Server.destroy;
begin
 stop;
// FConnectionList.Destroy;
 inherited destroy;
end;

procedure TIEC104Server.log(ALevel : TLevel; const AMsg : String);
var
 s:String;
begin
   if (assigned(Flog)) then
     begin
     s:='SERVER_'+AMsg;
     Flog.log(ALevel,s);
     end;
end;


Function TIEC104Server.send(hexstr:String):integer;
var
  i:integer;
begin
 result:=-1;
for  i:=0 to Connections.Count-1 do
    begin
    result:= send(hexstr,i);
    end;
end;

Function TIEC104Server.send(hexstr:String;con:integer):integer;
begin
   result := Connection[con].sendHexStr(hexstr);
end;

procedure TIEC104Server.sendBuf(buf: array of byte);
var
  i:integer;
begin
for  i:=0 to Connections.Count-1 do
    begin
    sendbuf(buf,i);
    end;
end;

Procedure TIEC104Server.sendBuf(buf: array of byte;con:integer);
begin
   log(info,'ServerSend_toCon_'+inttostr(con));
   Connection[con].sendBuf(buf,length(buf),true);
end;

(*
procedure TIEC104Server.DisconnectEvent(aSocket: TLHandle);
end;
  *)

Procedure TIEC104Server.setOnClientRead(proc: TRTXEvent);
var
i:integer;
 cclient:TIEC104Socket;
begin
FOnClientRead:=proc;
for i:=0 to FConnectionList.Count-1 do
   begin
   Cclient:=TIEC104Socket(FConnectionList.Items[i]);
   cclient.OnRXData:=FOnClientRead;
   end;
end;

Procedure TIEC104Server.setOnClientSend(proc: TRTXEvent);
var
i:integer;
 cclient:TIEC104Socket;
begin
FOnClientSend:=proc;
for i:=0 to FConnectionList.Count-1 do
   begin
   Cclient:= TIEC104Socket(FConnectionList.Items[i]);
   cclient.OnTXData:=FOnClientSend;
   end;
end;


function TIEC104Server.getClientindex(sender:TIEC104Socket):integer;
var
 x:integer;
 cclient:TIEC104Socket;
begin
result:=-1;
x:=0;
while x< FConnectionList.Count do
 begin
 cclient:=TIEC104Socket(FConnectionList[x]);
 if cclient = sender then
    begin
    result:=x;
    x:=1000;
    end;
 inc(x);
 end;
end;

function TIEC104Server.findClient(source:TTCPBlockSocket):TIEC104Socket;
var
 x:integer;
 cclient:TIEC104Socket;
begin
result:=nil;
x:=0;
while x< FConnectionList.Count do
  begin
  cclient:=TIEC104Socket(FConnectionList[x]);
//    if clientstr = getclientAddress(Connection.FSocket) then
  if cclient.Socket = source then
     begin
//       trace('found client in list:');
     result:=cclient;
     x:=1000;
     end;
  inc(x);
  end;
end;

procedure TIEC104Server.AcceptEvent(isocket: TIEC104Socket);
var
  adr:string;
begin
adr:=getclientAddress(isocket.Socket);
isocket.Logger:=logger;
isocket.SocketType:=TIECServer;
isocket.Name:=adr;
isocket.onRXData:=FOnClientRead;
isocket.onTXData:=FOnClientSend;
isocket.start;
isocket.TimerSet:=timers;

log(info,'ClientConect: '+adr+'  ID: '+inttostr(isocket.id));
log(debug,'No. of connected sockets :'+inttostr(Connections.Count));

if assigned(Fonclientconnect) then
    FonclientConnect(self,isocket);
end;

procedure TIEC104Server.DisconnectEvent(iSocket: TIEC104Socket);
begin
 log(info,'ClientDisConect:');
// iSocket.stop;
// freeandnil(iSocket);
end;


procedure TIEC104Server.Start;
begin
if  (not Frun) then
   begin
   Frun:=true;
   Fsocket := TTCPBlockSocket.Create;
   Fsocket.Bind('0.0.0.0',inttoStr(port));
//   log(info,'start server on port '+inttostr(port));
   Fth:=BeginThread(@run,self);
   end;
end;

procedure TIEC104Server.Stop;
begin
if  (Frun) then
   begin
   Frun:=false;
   while Connections.Count > 0 do
      begin
      ClientClose(Connections.Count-1);
      end;
//   Disconnect(true);
    Fsocket.CloseSocket;
    WaitForThreadTerminate( Fth,100);
    Freeandnil(Fsocket);
    log(info,'stop server.');
   end;
end;

procedure TIEC104Server.ClientClose(index : integer);
//procedure TIEC104Server.ClientClose(Client: TIEC104Socket);
var
x,i:integer;
iecsocket: TIEC104Socket;
begin
iecsocket := Connection[index];
log(Warn,'close connection: '+iecsocket.Name) ;

if assigned(FonclientDisconnect) then
        FonclientDisConnect(self,iecsocket);

x:=iecsocket.ID;  //threadID
//iecsocket.Socket.CloseSocket;
iecsocket.stop;
//WaitForThreadTerminate( Fth,10);
WaitForThreadTerminate( x,10);
//while (iecsocket <>nil) do;    //wait for Thread end
end;

function TIEC104Server.GetClient(Index: Integer): TIEC104Socket;
begin
 Result := TIEC104Socket(FConnectionList[Index]);
end;


procedure TIEC104Server.SetName(const NewName: TComponentName);
begin
inherited SetName(NewName);
//  logger.name:= name;
end;

Function TIEC104Server.GetClientAddress(Socket:TTCPBlockSocket):string;
begin
// result:=socket.PeerAddress+':'+inttostr(socket.peerPort);
result:=socket.GetRemoteSinIP+':';//+inttostr(socket.GetRemoteSinPort);
end;

end.

