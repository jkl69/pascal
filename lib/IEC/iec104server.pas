unit IEC104Server;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  IEC104Socket,
  sockets,  blcksock,
  TLoggerUnit, TLevelUnit, cliexecute;

type
  TIEC104Server = class;

  TServerConnection = class
      FthreadID: TThreadID;
      fServer  : TIEC104Server;
      FID       : integer;
      Fsock    : TSocket;
      fsocket  : TTCPBlockSocket;
      iecsock  : TIEC104Socket;
      fTerminated : Boolean;
    procedure execute;
  public
      constructor Create(aServer:TIEC104Server;asock:TSocket);
      destructor destroy; override;
      procedure terminate;
      property Terminated:Boolean read fterminated;
  end;

  { TIEC104Server }
   TIEC104Server = class
//  TIEC104Server = class(TTCPBlockSocket)
       private
         FthreadID:TThreadID;
         socket: TTCPBlockSocket;
   //       Fname: String;
  //        FIECSettings:TIEC104Settings;  //Server asign settings to all sockets
          hasbind:Boolean;
          FIECTimers:TIEC104TimerSet;
          FConnectionList:TList;
          Fport: integer;
          FOnClientCOnnect: TIECSocketEvent;
          FOnClientDisCOnnect: TIECSocketEvent;
          FOnClientRead: TRTXEvent;
          FOnClientSend: TRTXEvent;
          FLog: TLogger;
          fTerminated :  boolean;
       protected
          procedure log(ALevel : TLevel; const AMsg : String);
//          Procedure SetName(const NewName: TComponentName); override;
          procedure DoAcceptEvent(iSocket: TIEC104Socket);
//          procedure DisconnectEvent(aSocket: TIEC104Socket);
          Function GetClientAddress(aSocket:TTCPBlockSocket):string;
          function GetIECSocket(Index: Integer): TIEC104Socket;
          function GetConnection(Index: Integer): TServerConnection;
         function getIECTCPSock(source:TTCPBlockSocket):TIEC104Socket;
         function getClientindex(sender:TIEC104Socket):integer;
         Procedure setOnClientRead(proc: TRTXEvent);
         Procedure setOnClientSend(proc: TRTXEvent);
       public
         Name:string;
         constructor Create;
         destructor destroy; override;
         Function start:Boolean;
         procedure stop;
         procedure Execute;
         Function send(hexstr:String):integer;
         Function send(hexstr:String;con:integer):integer;
         procedure sendBuf(buf: array of byte;count:integer);
         procedure sendBuf(buf: array of byte;count:integer;connection:integer);
         procedure ConnectionClose(index :integer);
         procedure DoConnectionClose(con :TServerConnection);
         property Connections:TList read FConnectionList;
         property iecSocket[Index: Integer]: TIEC104Socket read GetIECSocket;
         property Connection[Index: Integer]: TServerConnection read GetConnection;
         property Timers:TIEC104Timerset read FIECTimers write FIECTimers;
       published
//         Property Socket:TTCPBlockSocket read Fsocket write Fsocket;
         property Port:integer read Fport write Fport;
         property Logger:Tlogger read Flog write Flog;
         property Terminated:Boolean read Fterminated;
  //       property Timers:TIEC104Timerset read getTimers write SetTimers;
         property onClientConnect: TIECSocketEvent read FOnClientCOnnect write FOnClientCOnnect;
         property onClientDisConnect: TIECSocketEvent read FOnClientDisConnect write FOnClientDisConnect;
         property onClientRead: TRTXEvent read FOnClientRead write SetOnClientRead;
         property onClientSend: TRTXEvent read FOnClientSend write SetOnClientSend;
      end;

implementation

var
  ConnectionID:integer=0;

function runConnection(p: Pointer): ptrint;
var
  con: TServerConnection;
begin
  con := TServerConnection(p);
  con.Execute;
//  con.destroy;
end;

function runServer(p: Pointer): ptrint;
var
 server: TIEC104Server;
begin
    server := TIEC104Server(p);
    Server.Execute;
end;

//+++++++++++++++++++++++++++++++++++++
//   TServerConnection    implementation
//+++++++++++++++++++++++++++++++++++++

constructor TServerConnection.Create(aServer:TIEC104Server;asock:TSocket);
begin
inherited create;
fserver:=aserver;
fsock := Asock;
Fsocket:=TTCPBlockSocket.create;
fsocket.socket:=fsock;
fsocket.GetSins;

iecsock:=TIEC104Socket.Create;
iecsock.SocketType:=TIECServer;
iecsock.Socket:=fsocket;
fID:=ConnectionID;
inc(ConnectionID);
iecsock.ID:=Fserver.Connections.Count;

fserver.Connections.Add(self);
fTerminated:=false;
end;

destructor TServerConnection.destroy;
begin
if not terminated then begin
   terminate;
   end;
inherited;
Fserver.log(debug,'CON:Destroyed');
end;

procedure TServerConnection.terminate;
begin
fServer.log(Debug,'CON:'+inttoStr(fID)+' go terminate') ;
fterminated:=true;
fServer.DoConnectionClose(self);
iecsock.destroy;
//fServer.log(debug,'iecsocket destroyed') ;
fsocket.CloseSocket;
//fServer.log(debug,'CON:_WAIT THREAD END') ;
WaitForThreadTerminate( FthreadID,10000);
end;

procedure TServerConnection.Execute;
var ip_rx:array[0..1500]of byte;
    rxcount:integer;
begin
// fserver.log(Debug,'CON:_EXECUTE');
 repeat
//   fserver.log(debug,'CON:'+inttoStr(IecSock.ID)+' Wait for Data');
    rxcount:=fSocket.RecvBufferFrom(@IP_RX,1500);
    if (rxCount=0) or (fsocket.LastError<>0) then
       fserver.log(debug,'CON:'+inttoStr(fID)+
           '_Stream '+inttostr(rxcount)+'-Bytes recived _ERROR:'+inttostr(fsocket.LastError));
    if (RXcount=0) and (not terminated) then Terminate;
    if not terminated then
       begin
       IECSock.StreamCount:=rxcount;
       IECSock.DecodeStream(IP_RX);
       sleep(1000);
       end;
  until Terminated; //rxcount<=0;
  fserver.log(Debug,'CON:_THREAD END');// close IP-Socket');
//  fServer.DoConnectionClose(self);
 if rxCount=0 then
    destroy;
end;

//+++++++++++++++++++++++++++++++++++++
//   TIEC104Server    implementation
//+++++++++++++++++++++++++++++++++++++

//constructor TIEC104Server.Create(Aowner: TComponent);
constructor TIEC104Server.Create;
begin
inherited;
// Fname:=Name;
  Fiectimers:=DefaultTimerset;
  Port:=2404;
  FConnectionList:=TList.Create;
  Fterminated:=true;
  hasbind:=False;
end;

Destructor TIEC104Server.destroy;
begin
 stop;
 FConnectionList.Destroy;
 inherited destroy;
 log(debug,'Destroyed');
end;

procedure TIEC104Server.Execute;
var sock:TSocket;
    loop:word;
    con:TServerconnection;
begin
log(info,'start listen on port '+inttostr(port));
repeat
   with socket do begin
   if loop mod 13=0 then
     log(debug,'wait_accept');
//   if canread(1000) then
   if canread(1000) then
     if lastError = 0 then
        begin
        sock:=Accept;
        if lastError=0 then
           begin
//           log(debug,'_doAccept_');
           con := TServerconnection.Create(self,sock);
           DoAcceptEvent(con.iecsock);
           con.FthreadID:= BeginThread(@runConnection,con);
           end
        else
           log(Error,'_Listen_ERROR: '+inttostr(lastError)+' '+GetErrorDesc(lastError));
        end
   else
      log(Error,'_listen_ERROR: '+inttostr(lastError)+' '+GetErrorDesc(lastError));
//   log(debug,'EXIT-accept');
   inc(loop);
   end;
until (terminated);
log(debug,'EXIT-Listen');
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
log(info,'SendToall Connections:'+inttostr(Connections.Count));
for  i:=0 to Connections.Count-1 do
    begin
    result := send(hexstr,i);
    end;
end;

Function TIEC104Server.send(hexstr:String;con:integer):integer;
begin
   log(debug,'Send_$Con_'+inttostr(con));
   IecSocket[con].sendHexStr(hexstr);
   result := 1;//IecSocket[con].sendHexStr(hexstr);
end;

procedure TIEC104Server.sendBuf(buf: array of byte;count:integer);
var
  i:integer;
begin
log(info,'Send_all_Connections:'+inttostr(Connections.Count));
for  i:=0 to Connections.Count-1 do
    begin
    sendbuf(buf,count,i);
    end;
end;

Procedure TIEC104Server.sendBuf(buf: array of byte;count:integer;connection:integer);
begin
   log(debug,'Send_toCon_'+inttostr(connection));
   IECSocket[connection].sendBuf(buf,length(buf),true);
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

function TIEC104Server.getIECTCPSock(source:TTCPBlockSocket):TIEC104Socket;
var
 x:integer;
 con:TServerConnection;
// isock:TIEC104Socket;
begin
result:=nil;
x:=0;
while x< FConnectionList.Count do
  begin
  con:=TServerConnection(FConnectionList[x]);
  if con.iecsock.Socket = source then
     begin
     result:=con.iecsock;
     x:=1000;
     end;
  inc(x);
  end;
end;

procedure TIEC104Server.DoAcceptEvent(isocket: TIEC104Socket);
var  i:integer; adr:String;
     alist:TStrings;
begin
adr:=getclientAddress(isocket.Socket);
isocket.Name:='Server['+inttoStr(isocket.id)+']';
isocket.Logger:=TLogger.getInstance(isocket.Name);
isocket.Logger.setLevel(TLevelUnit.info);
alist:=isocket.logger.GetAllAppenders;
if alist.Count=0 then  //if logger already exist do NOT ad appenders
  begin
  alist:=logger.GetAllAppenders;
  for i:= 0 to alist.Count-1 do
      isocket.Logger.AddAppender(logger.GetAppender(alist[i]));
  end;
isocket.onRXData:=FOnClientRead;
isocket.onTXData:=FOnClientSend;
isocket.TimerSet:=timers;
isocket.start;
log(info,'ClientConect: '+adr+'  ID:'+inttostr(isocket.id));
log(debug,'No. of connections:'+inttostr(Connections.Count));

if assigned(Fonclientconnect) then
   onclientConnect(self,isocket);
end;


Function TIEC104Server.Start:Boolean;
begin
if Terminated then
   begin
   socket:=TTCPBlockSocket.Create;
   log(debug,'Bind');
   socket.Bind('0.0.0.0',inttoStr(port));
   if socket.lastError<>0 then
       begin
       log(error,socket.GetErrorDesc(socket.lastError));
       result:=False;
       socket.closesocket;
       socket.Destroy;
       exit;
       end;
   socket.Listen;
   Fterminated:=false;
   log(info,'start server on port '+inttostr(port));
   FthreadID:=BeginThread(@runServer,self);
   result:=True;
   end;
end;

procedure TIEC104Server.Stop;
begin
log(debug,'Enter_Stop');
if (not Terminated) then
   begin
   fTerminated:=True;  //server should accept new connects
   if Connections.Count >0 then
      log(debug,'Still '+inttoStr(Connections.Count)+' connections activ->go closeing');
   while Connections.Count > 0 do
      begin
      ConnectionClose(Connections.Count-1);
      end;
    log(debug,'Wait Terminate Listen');
    WaitForThreadTerminate(FthreadID,100);
    socket.CloseSocket;
    socket.destroy;
   end;
log(info,'server stoped.');
end;

procedure TIEC104Server.ConnectionClose(index : integer);
//procedure TIEC104Server.ConnectionClose(Client: TIEC104Socket);
var
x,i:integer;
con    :TServerConnection;
isocket: TIEC104Socket;
begin
if index < FConnectionList.Count then
  begin
  con     := Connection[index];
//  con.destroy;
  con.terminate; //will also destroy connection;
  end;
end;

procedure TIEC104Server.DoConnectionClose(con:TServerConnection);
var index:integer;
begin
index:= FConnectionList.IndexOf(con);
FConnectionList.Delete(index);
log(debug,'connection '+inttostr(index)+' deleted:') ;
if assigned(FonclientDisconnect) then
   onclientDisConnect(self,con.iecsock);
end;

function TIEC104Server.GetIECSocket(Index: Integer): TIEC104Socket;
var con:TServerConnection;
begin
  Result := TServerConnection(FConnectionList[Index]).iecsock;
//  Result := TIEC104Socket(FConnectionList[Index]);
end;

function TIEC104Server.GetConnection(Index: Integer): TServerConnection;
begin
  Result := TServerConnection(FConnectionList[Index]);
end;


//procedure TIEC104Server.SetName(const NewName: TComponentName);
//begin inherited SetName(NewName);end;

Function TIEC104Server.GetClientAddress(aSocket:TTCPBlockSocket):string;
//Function TIEC104Server.GetClientAddress:string;
begin
// result:=socket.PeerAddress+':'+inttostr(socket.peerPort);
result:=asocket.GetRemoteSinIP+':';//+inttostr(socket.GetRemoteSinPort);
end;

end.

