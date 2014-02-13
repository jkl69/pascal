program IECGW;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp, sockets, blcksock, IEC104Client, IEC104ClientList,
  IEC104Socket, IEC104Server, TConfiguratorUnit, TLoggerUnit, TLevelUnit,
  TFileAppenderUnit, cliexecute, GWAppender, jsonparser;

type

  tcli=class(Tcliexecute)
    private
//      netsession : Tsession;
    public
       procedure execute(ix:integer); override;
       procedure executeX; override;
  end;



  { TMyApplication }
  //TRTXEvent = procedure(Sender: TObject;const Buffer:array of byte;count :integer) of object;

  TMyApplication = class(TCustomApplication)
  protected
    Fth:TThreadID;
    session: Tsession;
    Fexit: boolean;
    Clients: TIEC104Clientlist ;
    Server : TIEC104Server;
    cmdIN: String;
    procedure DoRun; override;
  private
    procedure clientRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
    procedure clientCreateEvent(Sender: TObject;Socket: TIEC104Socket);
    procedure serverRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
    procedure serverCreateEvent(Sender: TObject;Socket: TIEC104Socket);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure Dofile(f:String);
    procedure termStart;
    procedure termStop;
//    Procedure DoLog(EventType : TEventType; const Msg : String); override;
    procedure WriteHelp; virtual;
//    procedure Dofile(f:String);
  end;

var
  Application: TMyApplication;
  cli :Tcli;
  CLIResult:TCLIResult;
  Logger,Slogger,clogger : TLogger;
  netRun:  boolean;
  GWapp:TGWAppender;

//procedure net_session(sock:Tsocket);
function net_session(p: Pointer): ptrint;
var
  session:Tsession;
  ssock:TTCPBlockSocket ;
  res,txt:string;
const
  CR = #13;  LF = #10;  CRLF = CR + LF;

begin
txt:='';
session:= Tsession(p);
try
//  Bsock:=TTCPBlockSocket.create;
   ssock := session.sock;
//  Bsock.socket:=sock;
  ssock.GetSins;
  with ssock do
   begin
//    sessionexit :=false;
    res := RecvPacket(1800);
    if lastError<>0 then
       begin
       logger.debug('ASCII Session');
       sendString('Welkome to IECGW'+crlf);
       session.Json:=false;
       end
    else
      begin
      logger.debug('JSON Session');
      session.Json:=true;
      end;
    session.exit:=false;
    repeat
      if (session.Json) then
         res := RecvPacket(1000)
      else
         begin
         res := RecvPacket(300000);
         SendString(res) ;
         end;
      txt:=txt+res;
      if (session.Json) then
          begin
          Logger.debug('JASON receiv:'+txt);
          end
      else
         begin
          if pos(lf,txt)<>0 then   ///ASCI CMD received
              begin
              while pos(cr,txt)<>0 do delete(txt,pos(cr,txt),1);
              while pos(lf,txt)<>0 do delete(txt,pos(lf,txt),1);
//              Logger.debug('receive:'+txt+crlf);
              cli.ParseCMD(session,txt,CLIResult);
              txt:='';
              end;
         end;

      if lastError <>0 then
            begin
            if (session.Json) then
               begin
               Logger.debug('sock_Event:'+inttostr(lastError)+'JASON_RECV:'+txt);
               if (lastError=10054) then session.exit:=true;
               if (txt<>'') then
                   begin
                   cli.ParseCMD(session,txt,CliResult);
                   Logger.debug(CliResult.awnser.AsJSON);
                   txt:='';
                   end;
               end
            else
               begin
               logger.error('socket_ERROR:'+inttostr(lastError));
               sendString('ERROR');
               break;
               end;
            end;
    until session.exit;
    end;
  finally
   ssock.CloseSocket;
  end;
logger.info('EXIT-NET-SESSION');
freeandnil(ssock);
freeandnil(session);
end;

function frun(p: Pointer): ptrint;
var
 s:TSocket;
 netses:Tsession;
 bsock,sock: TTCPBlockSocket;
begin
  sock := TTCPBlockSocket.Create;
  sock.Bind('0.0.0.0','5001');
  logger.Info(' listen on port '+inttostr(sock.GetLocalSinPort));
  sock.Listen;
    repeat
    s:=sock.Accept;
    logger.Info('accept');
    netses:=Tsession.Create;
    Bsock:=TTCPBlockSocket.create;
    Bsock.socket:=s;
 //    netses.sock:=s;
    netses.sock:=Bsock;
//    net_session(netses);
    BeginThread(@net_session,netses);
   until netrun;
   logger.Debug('EXIT-Listen');
   sock.CloseSocket;
   freeandnil(sock);
 end;

procedure tcli.executeX;
begin
  CliResult.did:=true;
  CliResult.cmdmsg := 'logout';
  Fsession.exit:=true;
end;

procedure tcli.execute(ix:integer);
  begin
//  (['exit','client','log',load]);
//  execute:= inherited execute(ix);
  case (ix) of
   0: begin Application.Fexit:=true;exit; end;
   1: begin Application.clients.cliexecute(cmdChild,CLIResult); exit;  end;
   2: begin if (TLevelUnit.tolevel(Parameter) <> nil) then
          logger.setLevel(TLevelUnit.tolevel(Parameter)); Exit; end;
   3: begin Application.dofile(Parameter); Exit; end;
   4: begin Application.server.cliexecute(cmdChild,CLIResult); exit;  end;
  end;
end;

{ TMyApplication }

//TIECSocketEvent = procedure (Sender: TObject; Socket: TIEC104Socket) of object;
procedure TMyApplication.clientCreateEvent(Sender: TObject;Socket: TIEC104Socket);
begin
 logger.Error('CLient Create Event');
 Socket.onRXData:=@clientRXEvent;
end;

procedure TMyApplication.clientRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
var
  CL:TIEC104Socket;
  i:integer;
begin
 logger.Error('CLient Data Recieve');
 for  i:=0 to server.Connections.Count-1 do
     begin
     cl := server.Connection[i];
     cl.sendBuf(buffer,count,false);
     end;
end;

procedure TMyApplication.ServerCreateEvent(Sender: TObject ;Socket: TIEC104Socket);
begin
 logger.Error('Server Create Event');
 socket.onRXData:=@serverRXEvent;
end;

procedure TMyApplication.serverRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
var
  CL:TIEC104Client;
  asdu,i:integer;
begin
 asdu := buffer[4]+buffer[5]*256;
 logger.Error('Connection Recieve Event from ASDU:'+inttostr(asdu));
  for  i:=0 to server.Connections.Count-1 do
     begin
     cl := clients.Client[i];
     cl.iecSocket.sendBuf(buffer,count,false);
     end;
end;

procedure TMyApplication.Dofile(f:String);
var
 File1: TextFile;
 Str: String;
begin
  logger.Debug('File Reading:');
  AssignFile(File1, f);
  {$I+}
  try
    Reset(File1);
    repeat
      Readln(File1, Str); // Reads the whole line from the file
      Writeln(str);
//      cli.ParseCMD(session,Str,CLIResult); // Writes the line read
      cli.ParseCMD(nil,Str,CLIResult); // Writes the line read
    until(EOF(File1)); // EOF(End Of File) The the program will keep reading new lines until there is none.
    CloseFile(File1);
  except
    on E: EInOutError do
    begin
     Writeln('File handling error occurred. Details: '+E.ClassName+'/'+E.Message);
    end;
  end;
end;

procedure TMyApplication.TermStart;
begin
 Fth:=BeginThread(@frun);
 NetRun:=False;
end;

procedure TMyApplication.TermStop;
begin
   NetRun:=False;
end;


procedure TMyApplication.DoRun;
var
  ErrorMsg: String;
//  s:String;
begin
  // quick check parameters
  ErrorMsg:=CheckOptions('h','help');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h','help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  { add your program here }
  termstart;

  clogger := TLogger.getInstance('Clients');
  clogger.setLevel(TLevelUnit.INFO);
  clogger.AddAppender(Gwapp);
  Clients:= TIEC104Clientlist.Create;
  clients.Logger:=clogger;
  Clients.onClientCreate:=@clientCreateEvent;

  Slogger := TLogger.getInstance('Server');
  slogger.setLevel(TLevelUnit.INFO);
  Slogger.AddAppender(Gwapp);
  Server := TIEC104Server.Create(self);
  Server.Name:='GWSERVER';
  Server.Logger:= Slogger;
  Server.onClientConnect:=@ServerCreateEvent;
//  server.start;

  dofile('iec.cli');
  // stop program loop
  while (not FExit) do
        begin
        Readln (cmdIN);
        cli.ParseCMD(nil,cmdIN,CLIResult);
//        write(CLIResult.cmdmsg+nl);
        write(CLIResult.read()+nl);
        end;
//  Fclient.Activ:=False;
  Terminate;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
//  writeln('HERE');
  cli :=Tcli.Create(self,
      ['exit','client','log','load','server']);
  Cli.Name:='MAIN';
  Session:=TSession.create;
  fexit:=false;
  CLIResult:=TCLIResult.Create;
end;

destructor TMyApplication.Destroy;
begin
//  FClient.destroy;
  CLIResult.destroy;
  session.Destroy;;
  clients.destroy;
  Server.destroy;
  cli.destroy;
  TLogger.freeInstances;
  inherited Destroy;
end;

procedure TMyApplication.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ',ExeName,' -h');
end;

begin
  Application:=TMyApplication.Create(nil);
  tconfiguratorunit.doBasicConfiguration;

  logger := TLogger.getInstance;
//  logger.setLevel(TLevelUnit.Warn);
  logger.setLevel(TLevelUnit.INFO);
//  logger.setLevel(TLevelUnit.debug);
  logger.addAppender(TFileAppender.Create(ExtractFilePath(ParamStr(0))+'FER1.log'));
  GWapp := TGWAppender.Create;
  logger.addAppender(GWApp);
  //  logger.addAppender(TGWAppender.Create());
  logger.info('Start');
  Application.Run;
  logger:=nil;
  Application.Free;
end.

