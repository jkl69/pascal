unit IEC104Client;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils,// fptimer,
  blcksock,
  IEC104Socket,
  TLoggerUnit, TLevelUnit, cliexecute;

type

  { TIEC104Client }
//   TIEC104Client = class(TObject)
//  TIEC104Client = class(TComponent)
  TIEC104Client = class
           Name : String;
          private
            Fth:TThreadID;
//            Fcli:TcliExecute;
            Fsocket: TTCPBlockSocket;
            Fhost: String;
            Fport: integer;
            FLog: TLogger;
            FRun: Boolean;
            FTimerSet:   TIEC104Timerset;  // hold the reload values
            FcounterSet: TIEC104Timerset;  // hold the current values
            Fiecsock : TIEC104Socket;
            FOnRXData: TRTXEvent;
            FOnConnect: TIECSocketEvent;
            FOnDisCOnnect: TIECSocketEvent;
            procedure setTimerset(tset:TIEC104Timerset);
            procedure setlogger(l:Tlogger);
          protected
            procedure irq(sender:TObject);
            procedure ConnectEvent;
            procedure DisconnectEvent;
            procedure connect;
            function doRecieve: integer;
          public
//            constructor Create(AOwner: Tcomponent); override;
//            constructor Create;
            constructor Create(aName:String);
            destructor destroy; override;
//            procedure CLIexecute(s:string;result:TCLIResult);
            procedure Start;
            procedure Stop;
            Function send(hexstr:String):integer;
            procedure log(ALevel : TLevel; const AMsg : String);
            Property Socket:TTCPBlockSocket read Fsocket write Fsocket;
            Property iecSocket:TIEC104Socket read Fiecsock write Fiecsock;
            property onRXData: TRTXEvent read FonRXData write FonRXData;
            property onConnect: TIECSocketEvent read FOnConnect write FOnConnect;
            property onDisConnect: TIECSocketEvent read FOnDisConnect write FOnDisConnect;
            Property host:String read Fhost write Fhost;
            Property Port:Integer read FPort write FPort;
            property TimerSet:TIEC104Timerset read FTimerSet write setTimerSet;
            property Logger : Tlogger read Flog write setlogger;
            property Activ : Boolean read Frun;
         end;


implementation

function run(p: Pointer): ptrint;
var loop:word;
    idleTime:word;
    client: TIEC104Client;
begin
  client := TIEC104Client(p);
//  idletime:=client.TimerSet.T0;
  while (Client.Activ) do
    begin
    if loop mod 10=0 then
       begin
       client.connect; //stay in connect till disconnect
       idletime:=client.TimerSet.T0
       end;
    if Client.Activ then
       begin
       client.log(debug,'['+client.Name+'] next Try msec:'+inttoStr(IdleTime));
       dec(idleTime,client.TimerSet.T0 div 10);
       sleep(client.TimerSet.T0 div 10 );
       end;
    inc(loop);
    end;
  client.log(debug,'['+client.Name+'] THREAD END');
end;

    { TIEC104Client }

//constructor TIEC104Client.Create(AOwner: Tcomponent);
//constructor TIEC104Client.Create;
constructor TIEC104Client.Create(aname:string);
    begin
//    inherited create(Aowner);
    inherited create;
    name := aname;
    FtimerSet:=IEC104Socket.DefaultTimerset;
    Port:=2404;
    host:= '127.0.0.1';
{*
Fcli:=TClientCLI.Create(self,
      ['start','stop','close','host','port','send',
        'startDt','stopdt','list','timer']);
    Fcli.name:='Client';*}
  Fiecsock := TIEC104Socket.Create;
  Fiecsock.Name:=Name;
  Fiecsock.SocketType:=TIECClient;
  Fiecsock.Logger:=Flog;
  Fiecsock.TimerSet:=Ftimerset;
  end;

destructor TIEC104Client.Destroy;
    begin
    log(debug,'destroy');
    stop;
    Freeandnil(Fiecsock);
//    if (FCLI<>nil) then   Fcli.destroy;
    log(debug,'destroy_');
    inherited destroy;
    end;

procedure TIEC104Client.setTimerset(tset:TIEC104Timerset);
begin
  Ftimerset:=tset;
  if Fsocket<>nil then
     iecsocket.TimerSet:=Ftimerset;
end;

procedure TIEC104Client.setlogger(l:Tlogger);
begin
  Flog:=l;
  Fiecsock.Logger:=Flog;
end;
{*
Procedure TIEC104Client.cliexecute(s:string;result:TCLIResult);
begin
//   if (FCLI<>nil) then  Fcli.ParseCMD(nil,s,result)
//  else
     log(error,'CLI Not Assigned');
  end;
  *}
procedure TIEC104Client.log(ALevel : TLevel; const AMsg : String);
var
 s:String;
begin
   if (assigned(Flog)) then
     begin
     s:='CLIENT_'+AMsg;
     Flog.log(ALevel,s);
     end;
end;

function TIEC104Client.send(hexstr:String):integer;
//procedure TIEC104Socket.sendHexStr(var s:string);
begin
   result:=Fiecsock.sendHexStr(hexstr);
end;

function TIEC104Client.doRecieve: integer;
var
   buffer:   array[0..2000]of byte;
begin
  log(info,'['+Name+'] Connected to server OK.');
  Fiecsock.Socket := Fsocket;
  Fiecsock.start;
  repeat
//        buffer := sock.RecvPacket(2000);
    doRecieve:=fsocket.RecvBuffer(@buffer,2000);
  if (doRecieve>0) then
    begin
    Fiecsock.StreamCount:=doRecieve;
    Fiecsock.DecodeStream(buffer);
    end;
// ...until there's no more data.
//      until i=-1;
  until doRecieve <= 0;
  log(debug,'Stop read socket sockresult:'+inttoStr(doRecieve));
  Fiecsock.stop;
//  Fiecsock.destroy;
end;

procedure TIEC104Client.connect;
var
  sockresult:integer;
begin
    log(info,'['+Name+'] Try connect to Server '+host+':'+IntToStr(Port));
    Fsocket := TTCPBlockSocket.Create;
    Fsocket.Connect(host,IntToStr(Port));
// Was there an error?
    if Fsocket.LastError <> 0 then
      log(warn,'['+Name+'] Could not connect to server.')
    else
      begin
      ConnectEvent;
      sockresult:=doRecieve;
      DisconnectEvent;
      end;
   Freeandnil(Fsocket);
//   fsocket.Destroy; fsocket:=nil;
   end;

procedure TIEC104Client.ConnectEvent;
    begin
    log(info,'ConnectEvent');
     if assigned(FOnConnect) then
        FOnConnect(self,Fiecsock);
    end;

procedure TIEC104Client.DisconnectEvent;
    begin
    log(info,'DisconnectEvent');
     if assigned(FOnDisConnect) then
        FOnDisConnect(self,Fiecsock);
    end;


procedure TIEC104Client.start;
 begin
 if (not Frun) then
   begin
   Fcounterset.T0:=IEC104Socket.off;  // disable reconnect check
   Fth:=BeginThread(@run,Pointer(self));
   Frun:=true;
   end;
 end;

procedure TIEC104Client.stop;
 begin
 if (Frun) then
   begin
   Frun:=false;
   if (Fsocket<>nil) then Fsocket.CloseSocket;  // should stop thread;
   WaitForThreadTerminate( Fth,1000);
   end;
 end;


 procedure TIEC104Client.irq(sender:TObject);
    var
    t0:integer;
    begin
    log(debug,'IRQ');
 //   if (Connected) then log(info,'connected');
    t0:=datetimetotimestamp(now).time;

    if (t0>FcounterSet.T0) then  //reconnect time is expierd
      begin
    //  log.Warn('Reconnect time (t0) expiered try reconnect to '+host+' on port '+inttostr(port));
      Fcounterset.T0:=IEC104Socket.off;
//      connect();
      end;
    end;


end.

