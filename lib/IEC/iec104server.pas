unit IEC104Server;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  IEC104Socket,
  sockets,  blcksock,
  TLoggerUnit, TLevelUnit, cliexecute;

type
  Tcli=class ;

  { TIEC104Server }
//  TIEC104Server = class(TObject)
  TIEC104Server = class(TComponent)
       private
         Fth:TThreadID;
         Fcli:Tcli;
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
  //       function GetTimers: TIEC104Timerset;
  //       procedure SetTimers(timers:TIEC104Timerset);
  //       procedure SetLogEvent(proc:TGetStrProc);
  //       procedure trace(s:string);
       public
         constructor Create(AOwner: Tcomponent);override;
         destructor destroy; override;
         procedure start;
         procedure stop;
         procedure Cliexecute(s:string;Result:TCLIResult);
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

  Tcli=class(Tcliexecute)
  private
  protected
    server:TIEC104Server;
   public
     Procedure execute(ix:integer); override;
end;

implementation

type

  TRunRun = class
      server: TIEC104Server;
      sock:Tsocket;
    end;


Procedure tcli.execute(ix:integer);
var
  i:integer;
  Connection: TIEC104Socket;
  txt:String;
begin
// [,'list','start','stop']
//    execute:='OK'+nl;
  case (ix) of
     0: begin
           CLIResult.cmdmsg:= 'Connections: '+inttostr(server.Connections.Count)+nl;
           for i:=0 to server.Connections.count-1 do
           begin
              connection := server.Connection[i];
              CLIResult.cmdmsg:=CLIResult.cmdmsg+'connection.'+inttostr(i)+' '+connection.Socket.GetRemoteSinIP;
           end;
           Exit;
        end;
     1: begin server.start;
              CLIResult.cmdmsg:= 'Server start';exit  end;

     2: begin server.stop;
                CLIResult.cmdmsg:= 'Server Stop'; exit;  end;
     3: begin if (TLevelUnit.tolevel(Parameter) <> nil) then
               begin
                 server.logger.setLevel(TLevelUnit.tolevel(Parameter));
                 CLIResult.cmdmsg:= 'change Server LogLevel';
               end
            else begin
                CLIResult.cmdmsg:= 'Invalid LogLevel';
                CLIResult.did:=false;
               end;
            Exit; end;
      end;
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
begin
    server := TIEC104Server(p);
    server.socket.Listen;
    server.log(info,'start listen on port '+inttostr(Server.port));
    repeat
       server.log(debug,'wait_accept');
       sock:=server.socket.Accept;
       server.log(Info,'_accept_OK');
       server.log(Error,' sock_ERROR: '+inttostr(clsock.lastError));
      if (server.Frun) then
          begin
          r:= TRunRun.Create;
          r.server:=server;
          r.sock:=sock;
          BeginThread(@runsock,r);
//            Server.AcceptEvent(clsock);
           end;
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
  Fcli:=Tcli.Create(self,
      ['list','start','stop','log']
       );
  Fcli.server:=self;
  Fcli.name:='Server';
end;

Destructor TIEC104Server.destroy;
begin
 stop;
// FConnectionList.Destroy;
 Fcli.destroy;
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

procedure TIEC104Server.ClientClose(index : integer);
//procedure TIEC104Server.ClientClose(Client: TIEC104Socket);
var
x,i:integer;
iecsocket: TIEC104Socket;
begin
iecsocket := Connection[index];
log(Warn,'Client close: '+iecsocket.Name) ;

if assigned(FonclientDisconnect) then
        FonclientDisConnect(self,iecsocket);

x:=iecsocket.ID;  //threadID

iecsocket.Socket.CloseSocket;
WaitForThreadTerminate( x,1000);
//while (iecsocket <>nil) do;    //wait for Thread end
end;

procedure TIEC104Server.cliexecute(s:string;Result:TCLIResult);
begin
  Fcli.ParseCMD(nil,s,result);
end;

(*
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
// iecsock.stop;
// freeandnil(iecsock);
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
   while Connections.Count > 0 do
      begin
      ClientClose(Connections.Count-1);
      end;
    Frun:=false;
//   Disconnect(true);
    Fsocket.CloseSocket;
    WaitForThreadTerminate( Fth,100);
    Freeandnil(Fsocket);
    log(info,'stop server.');
   end;
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

