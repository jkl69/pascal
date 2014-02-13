program fer1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  CustApp, sockets,
  blcksock,
  IEC104Client, IEC104ClientList, IEC104Socket,  TConfiguratorUnit,
  TLoggerUnit, TLevelUnit, TFileAppenderUnit, cliexecute;

type
  tcli=class(Tcliexecute)
     public
       function execute(ix:integer):String; override;
  end;

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
//    Procedure DoLog(EventType : TEventType; const Msg : String); override;
    procedure WriteHelp; virtual;

  end;

  var
    sock: TTCPBlockSocket;
    Fexit:boolean =False;
//    FClient: TIEC104Client ;
    Clients: TIEC104Clientlist ;
    cli :Tcli;
    Logger: TLogger;

function f(p: Pointer): ptrint;
var
 s:TSocket;
 isock:TTCPBlockSocket ;
 terminated:boolean;
 txt:string;
begin
  sock := TTCPBlockSocket.Create;
  sock.Bind('0.0.0.0','2600');
  sock.Listen;
    repeat
    s:=sock.Accept;
    writeln('ACCEPT');
    isock:=TTCPBlockSocket.create;
    try
      iSock.socket:=s;
      isock.GetSins;
      with isock do
       begin
        writeln('Start_netread');
        repeat
//           writeln('Start_Rec');
//           txt := RecvPacket(60000);
           txt := RecvString(60000);
           writeln('_Rec'+inttostr(lastError));
           if lastError=104 then break;
           SendString(cli.doCMD(txt)) ;
//           SendString('T->'+txt+nl);
           writeln('_Rec'+inttostr(lastError));
           if lastError<>0 then break;
         until Fexit;
       end;
   finally
        writeln('ERROR!!'+inttostr(isock.lastError));
   end;
   writeln('EXIT');
   until Fexit;
   iSock.Free;
 end;

function tcli.execute(ix:integer):String;
begin
//  cli :=Tcli.Create(['exit','client','log']);
//  execute:= inherited execute(ix);
  execute:='OK';
  case (ix) of
   0: begin Fexit:=true;exit; end;
   1: begin execute:=clients.cliexecute(cmdChild); exit;  end;
   2: begin logger.setLevel(TLevelUnit.debug); Exit; end;
  end;
end;

{ TMyApplication }

procedure TMyApplication.DoRun;
var
  ErrorMsg: String;
  s:String;
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
  logger := TLogger.getInstance;
  logger.setLevel(TLevelUnit.INFO);
// logger.setLevel(TLevelUnit.debug);
  logger.addAppender(TFileAppender.Create(ExtractFilePath(ParamStr(0))+'FER1.log'));
  logger.info('Start');

   Clients:= TIEC104Clientlist.Create;
  clients.Logger:=logger;

  // stop program loop
  while (not FExit) do
        begin
        Readln (S);
        write(cli.doCMD(s));
//        writeln(clexecute(s));
        end;
//  Fclient.Activ:=False;
  Terminate;
end;

constructor TMyApplication.Create(TheOwner: TComponent);

begin
  inherited Create(TheOwner);
  StopOnException:=True;
  BeginThread(@f);
  writeln('HERE');
//  cli :=Tcliexecute.Create(['a','b']);
  cli :=Tcli.Create(['exit','client','log']);
  Cli.Name:='MAIN';
  fexit:=false;
end;

destructor TMyApplication.Destroy;
begin
//  FClient.destroy;
  clients.destroy;
  cli.destroy;
  inherited Destroy;
  TLogger.freeInstances;
end;

procedure TMyApplication.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ',ExeName,' -h');
end;

var
  Application: TMyApplication;
begin
  Application:=TMyApplication.Create(nil);
  Application.Title:='My Application';
  tconfiguratorunit.doBasicConfiguration;
  Application.Run;
  Application.Free;
end.

