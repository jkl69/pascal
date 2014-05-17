program IECGW;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp, sockets, IEC104Client, IEC104ClientList,
  IEC104Socket, IEC101Serial,  IEC104Server, IECMap, IECStream, TConfiguratorUnit, TLoggerUnit,
  TLevelUnit, TFileAppenderUnit, CLI, GWAppender, IECRouter,

  IECGWEvent, IECTree,tree, fpjson,
  session, INIFiles, GWNetConnection, CustomServer1, blcksock;

type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected

//    Fexit: boolean;
    Fsession:Tsession;
//   cmdIN: String;
    procedure DoRun; override;
    procedure Terminate; override;
  private
//   procedure threadExit;
    procedure init;
    procedure writeConsole(const s:String);
    procedure clientRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
    procedure TimerEvent(const S: string) ;
    procedure clientCreateEvent(Sender: TObject;Socket: TIEC104Socket);
    procedure clientConnectEvent(Sender: TObject;Socket: TIEC104Socket);
    procedure MasterConnectEvent(Sender: TObject);
    procedure MasterDisConnectEvent(Sender: TObject);
    procedure clientDisConnectEvent(Sender: TObject;Socket: TIEC104Socket);
    procedure serverRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
    procedure serverCreateEvent(Sender: TObject;Socket: TIEC104Socket);
    procedure ItemEvent(Sender: TObject);
    procedure NetsocketError(Server: TCustomServer; Socket: TTCPBlockSocket);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
//    Procedure DoLog(EventType : TEventType; const Msg : String); override;
    procedure WriteHelp; virtual;
  end;

var
  Application: TMyApplication;
  NetServer : TIECGWNetServer;
  Clients: TIEC104Clientlist ;
  Server : TIEC104Server;
  Master :TIEC101Master;
  Items : TIECTree;
  Router : TIECRouter;
  GWEvent: TIECGWEvent;
//  Timer:   TIECGWTimer;
  Logger : TLogger;
  GWapp:TGWAppender;

function Executemain(p: Pointer): ptrint;
var
  Session:TSession;
  s:String;
begin
 Session := TSession(p);
 while not Session.Terminated do
     begin
     Session.writePrompt;
     Readln (s);
     session.EcexuteCmd(s);
     end;
 Application.Terminate;
end;

{ TMyApplication }

procedure TMyApplication.MasterConnectEvent(Sender: TObject);
begin
 logger.warn('MASTER connect to '+ TIEC101Member(Sender).name);
end;

procedure TMyApplication.MasterDisConnectEvent(Sender: TObject);
begin
 logger.Warn('MASTER Lost Connection to '+ TIEC101Member(Sender).name);
end;

//TIECSocketEvent = procedure (Sender: TObject; Socket: TIEC104Socket) of object;
procedure TMyApplication.clientConnectEvent(Sender: TObject;Socket: TIEC104Socket);
var
 i:integer;
 cl:TIEC104Client;
 eva:TEventarray;
begin
  cl:= TIEC104Client (sender);
  logger.INFO('** CLient Connect Event '+Socket.Name);
{*
eva := GWEvent.getConnectEvent(cl.name);
  for i:=0 to high(eva) do
     begin
     logger.Debug('doConnectEvent:'+eva[i]);
 //    exec(cli.Parse(eva[i]));
     end;*}
end;

procedure TMyApplication.writeConsole(const s:String);
begin
  write(s);
end;

procedure TMyApplication.TimerEvent(const S: string);
begin
   logger.Error('****'+S);
end;

procedure TMyApplication.clientDisConnectEvent(Sender: TObject;Socket: TIEC104Socket);
var
 i:integer;
 cl:TIEC104Client;
 eva:TEventarray;
begin
  cl:= TIEC104Client (sender);
  logger.Info('** CLient DisConnect Event '+Socket.Name);
end;

procedure TMyApplication.clientCreateEvent(Sender: TObject;Socket: TIEC104Socket);
begin
 logger.Debug('CLient Create Event');
 Socket.onRXData:=@clientRXEvent;
 TIEC104Client (sender).onDisConnect:=@clientDisConnectEvent;
 TIEC104Client (sender).onConnect:=@clientConnectEvent;
end;

procedure TMyApplication.clientRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
var
  CL:TIEC104Socket;
  i:integer;
  iecItems : TiecItems;
  item : TIECItem;
//  bu : TIECBUFFER;
begin
 logger.Debug('CLient Data Recieve');

 IECitems := IECstream.CreteItems(buffer);
 logger.Info('IECItems.count'+intToStr(length(IECItems)));
 for  i:=0 to high(IECItems) do
    begin
      item := TIECItem (IECItems[i]);
      logger.info(item.ToHexStr);
      items.update(item);
    end;

 if server<>nil then
   for  i:=0 to server.Connections.Count-1 do
     begin
     cl := server.IecSocket[i];
     cl.sendBuf(buffer,count,false);
     end;
end;

procedure TMyApplication.ServerCreateEvent(Sender: TObject ;Socket: TIEC104Socket);
begin
 logger.debug('Server Create Event');
 socket.onRXData:=@serverRXEvent;
end;

//TRxBufEvent = procedure(Sender: TObject;Buffer: array of byte; Count: Integer) of object;

procedure TMyApplication.serverRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
var
  i:integer;
  CL:TIEC104Client;
  item : TIECItem;
begin
 logger.Info('__RX__ '+hextostr(buffer,count));
// logger.debug('Server-Connection Recieve Event');
{*
try
   item := TIECItem.create(Buffer,count);
 except
   On Exception do
      begin logger.Fatal('CRC-ERROR in received IEC-Stream');  exit; end;
 end;
 if (item.getType<>TIECSType.IEC_NULL_TYPE) then
   begin
   logger.info('_serverRXEvent_'+item.Name+' '+IECType[item.getType].name+' asdu:'+inttostr(item.ASDU)+
             ' adr:'+inttostr(item.Adr[0])+' :'+BufferToHexStr(bu));
   if items<>nil then items.update(item);
   end
 else
   logger.info('_serverRXEvent_BUFFER: '+BufferToHexStr( item.getStream));
*}
end;

procedure TMyApplication.ItemEvent(Sender: TObject);
var  item    : TIECItem;
     isocket :TIEC104Socket;
begin
 item := TIECItem (sender);
 logger.info('** Update:'+item.name+' '+item.toString);

 if GWevent<>nil then
 //   GWevent.ItemEvent(item);

 if item.IECTyp in IEC_M_Type then   //Monitoring Item defult is up to SCADA
     if not item.ReversMode then     //IS Default ?
        begin
        if server<>nil then
           server.sendBuf(item.ToIECBuffer,item.Size)
        else
           logger.warn('No Server to send Item');
       end;
end;

procedure TMyApplication.Terminate;
begin
//   NetServer.Stop;
   logger.info('Application Exit:');
   inherited ;
end;

procedure TMyApplication.init;
var
 INI:TINIFile;
// GWapp:TGWAppender;
 Fapp:TFileAppender;
 lines:Tstrings;
 i:integer;
begin

 INI:= TIniFile.Create(ExtractFilePath(ParamStr(0))+'iecgw.ini');
// items.readSTypeName(INI);
logger := TLogger.getInstance;
// logger.setLevel(TLevelUnit.Warn);
logger.setLevel(TLevelUnit.INFO);

Fapp:=nil;
if ini.ReadBool('logging','logToFile',false) then
    begin
      Fapp := TFileAppender.Create(ini.ReadString('logging','File',ExtractFilePath(ParamStr(0))+'IECGW.log'));
      logger.addAppender(Fapp);
    end ;
GWapp := TGWAppender.Create;

fSession:=tsession.Create;
fsession.Name:='LocalConsole';
fsession.onexecResult:=@writeconsole;
//fsession.onTerminate:=;
fsession.onexec:=@CLI.execCLI;

Clients:=nil;
if  ini.ReadBool('client','activ',false) then
  begin
  Clients:= TIEC104Clientlist.Create;
  clients.Logger:=TLogger.getInstance('Clients');
  clients.Logger.setLevel(TLevelUnit.INFO);
  if assigned(Fapp) then
     clients.Logger.AddAppender(Fapp);
  clients.Logger.AddAppender(Gwapp);
  Clients.onClientCreate:=@clientCreateEvent;
  addProcess(Clients,ini.ReadString('client','Description',''));
  end;

server:=nil;
if  ini.ReadBool('server','activ',false) then
  begin
  Server := TIEC104Server.Create;
  Server.Port:=ini.ReadInteger('server','port',2404);
  Server.Logger:= TLogger.getInstance('Server');
  Server.Logger.setLevel(TLevelUnit.INFO);
  if assigned(Fapp) then
      Server.Logger.AddAppender(Fapp);
  Server.Logger.AddAppender(Gwapp);
  Server.Name:='GWSERVER';
  Server.onClientConnect:=@ClientconnectEvent;
  Server.onClientDisConnect:=@ClientDisconnectEvent;
//  server.start;
  addProcess(Server,ini.ReadString('server','Description',''));
  end;

Master:=nil;
if  ini.ReadBool('master','activ',false) then
  begin
  Master := TIEC101Master.Create();
  Master.Logger:= TLogger.getInstance('Master');
  Master.Logger.setLevel(TLevelUnit.info);
  if assigned(Fapp) then
      Master.Logger.AddAppender(Fapp);
  Master.Logger.AddAppender(Gwapp);
  Master.Name:='101Master';
  Master.onConnect:= @MasterconnectEvent;
  Master.onDisConnect:= @MasterDisconnectEvent;
  Master.onDataRx:= @serverRXEvent;
  Master.IdleTime:=ini.ReadInteger('master','idleTime',100);
  addProcess(Master,ini.ReadString('master','Description',''));
  end;

items:=nil;
if  ini.ReadBool('items','activ',false) then
  begin
  Items := TIECTree.create();
  Items.Logger:=TLogger.getInstance('Item');
  Items.Logger.setLevel(TLevelUnit.INFO);
  if assigned(Fapp) then
    Items.Logger.AddAppender(Fapp);
  Items.Logger.AddAppender(Gwapp);
  Items.onChange:=@ItemEvent;
  addProcess(items,ini.ReadString('items','Description',''));
  end;

GWEvent:=nil;
if  ini.ReadBool('events','activ',false) then
  begin
  GWEvent := TIECGWEvent.create;
  //  GWEvent.addConnectEvent('fer1','server.send 03 02 01');
  //  GWEvent.addDisConnectEvent('fer1','server.send 03 02 00');
  GWEvent.Logger:=TLogger.getInstance('Event');
  GWEvent.Logger.AddAppender(Gwapp);
  GWEvent.Logger.SetLevel(info);
  addProcess(GWEvent,ini.ReadString('events','Description',''));
  end;

Router:=nil;
if  ini.ReadBool('router','activ',false) then
  begin
   Router := TIECRouter.create;
   Router.Logger:=logger;
   addProcess(Router,ini.ReadString('router','Description',''));
  end;

lines:=TstringList.Create;
lines.Add('ff');
ini.ReadSectionRaw('CLI',lines);
for i:=0 to lines.Count-1 do
     begin // writeln('LINE:'+lines[i]);
     fsession.EcexuteCmd(lines[i]);
     fsession.path:='';
     fsession.onexec:=@CLI.execCLI;
     end;
lines.Destroy;


NetServer := TIECGWNetServer.Create('127.0.0.1','5001');
NetServer.OnSocketError:=@NetsocketError;
NetServer.Start;

//ses.ThreadID:=
BeginThread(@Executemain,fSession);
logger.addAppender(GWApp);
logger.info('Application Start');
ini.Destroy;
end;

procedure TMyApplication.NetsocketError(Server: TCustomServer; Socket: TTCPBlockSocket);
begin
 logger.error('NETSocket '+socket.GetErrorDesc(socket.LastError));
end;

procedure TMyApplication.DoRun;
var
  i:integer;
  Stradr,ErrorMsg:String;
  item : TIECItem;
  iecItems : TiecItems;
  Stream : array of byte;
  mem:TIEC101Member;
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
  setlength(Stream,17);
  Stream[0]:=01; Stream[1]:=03;
  Stream[2]:=03;Stream[3]:=00;
  Stream[4]:=01;Stream[5]:=01;
  Stream[6]:=01;Stream[7]:=16;Stream[8]:=00;  Stream[9]:=01;
  Stream[10]:=12;Stream[11]:=16;Stream[12]:=00;  Stream[13]:=01;
  Stream[14]:=42;Stream[15]:=16;Stream[16]:=00;  Stream[17]:=01;

//  item := TIECTCItem.create([01,01,03,00,01,00,01,10,00],10);
//writeln (BufferToHexStr(Stream,18));
 iecItems:= CreteItems([$01, $03, 03,00,  1,1,  01,16,0,1,  12,16,0,1,  42,16,0,1]);
// iecItems := iecStream.CreteItems(Stream);

//  logger.info('[18] '+LastCRC.txt);
//  item := TIECTCItem.create();
//  item.setType(M_ME_TB);
  stradr:='';
 // IECItems.TypeAsNumber:=true;
  for i:=0 to high(IecItems)-1 do
      begin
      item := TIECItem (iecItems[i]);
      writeln('item Path:'+item.toString);
      end;
  writeln(item.Name+' '+MAP[item.IECTyp].name+' asdu:'+inttostr(item.ASDU)+stradr);
//  readJSONFile('d:\source\pascal\FER\j2.json');
//  execJson(StrtoJSON(readJSONFile('d:\source\pascal\FER\j2.json')));
//  writeln('JSON  '+items.toJson(items.root).AsJSON);
//  writeln('Items:'+item.Name+' asdu:'+inttostr(item.ASDU)+' adr:'+inttostr(item.Adr[1]));
//  bu:= item.getStream;
//  writeln (BufferToHexStr(bu));
//  Items.add(M_ME_TB,3,8193);
//item:= items.getIecItem('9:5:8193');
if item=nil then logger.error('Node no found')
else  begin
  logger.info('Node in Tree -->OK');
  logger.info('Item name:'+item.Name);
end;

//mem := master.addmember('test',100,TLogger.getInstance('Master.test'));
//mem.onDataRx :=  @ServerRxEvent; mem.onConnect:= @MasterconnectEvent;

// stop program loop
  fsession.writePrompt;
  while (not terminated) do
      begin
        sleep(1000);
      end;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TMyApplication.Destroy;
begin
if (clients<>nil) then
    clients.destroy;
if (Master<>nil) then
   Master.destroy;
if (Server<>nil) then
  Server.destroy;
if (Items<>nil) then
  Items.destroy;
if (GWEvent<>nil) then
  GWEvent.destroy;
if (Router<>nil) then
  Router.destroy;

  Fsession.Destroy;
//  NetServer.Destroy;
//  TLogger.freeInstances;
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
  Application.init;
  Application.Run;
//  TLogger.freeInstances;
  Application.Free;
end.

