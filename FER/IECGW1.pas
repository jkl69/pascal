program IECGW1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp, sockets, blcksock, IEC104Client, IEC104ClientList,
  IEC104Socket, IEC104Server, IECItems, TConfiguratorUnit, TLoggerUnit,
  TLevelUnit, TFileAppenderUnit, CLI, GWAppender, IECRouter, CLIRouter,
  IECGWEvent, CLIEvent, CLITimer, CLIClient, CLIServer,{ IECGWnetSession,}
  IECGWTimer, IECTree,tree, fpjson, CLIItems;

type

  { TMyApplication }
  //TRTXEvent = procedure(Sender: TObject;const Buffer:array of byte;count :integer) of object;

  TMyApplication = class(TCustomApplication)
  protected
    TerminalThread:TThreadID;
    Fexit: boolean;
    Clients: TIEC104Clientlist ;
    Server : TIEC104Server;
    Items : TIECTree;
    Router : TIECRouter;
    GWEvent: TIECGWEvent;
    Timer:   TIECGWTimer;
    cmdIN: String;
    procedure DoRun; override;
  private
    procedure init;
    procedure clientRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
    procedure TimerEvent(const S: string) ;
    procedure clientCreateEvent(Sender: TObject;Socket: TIEC104Socket);
    procedure clientConnectEvent(Sender: TObject;Socket: TIEC104Socket);
    procedure clientDisconectEvent(Sender: TObject;Socket: TIEC104Socket);
    procedure serverRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
    procedure serverCreateEvent(Sender: TObject;Socket: TIEC104Socket);
    procedure ItemUpdateEvent(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    Function Dofile(f:String):boolean;
    procedure termStart;
    procedure termStop;
//    Procedure DoLog(EventType : TEventType; const Msg : String); override;
    procedure WriteHelp; virtual;
//    procedure Dofile(f:String);
  end;

var
  Application: TMyApplication;
  myresult:TCLIReturn;
  mycli : Tcli;
//  CLIResult:TCLIResult;
  Logger,Slogger,clogger,ItemLogger : TLogger;
  netRun:  boolean;
  GWapp:TGWAppender;
  Fapp:TFileAppender;

const
  Process : Array [0..5] of String = ('route','event','client','server','timer','items');
  action : Array [0..3] of String = ('load','log','X','item');
  NO_PARAM='missing Parameter';

function level(c:TCLI):TCLIReturn;
begin
Result.succsess:=false;
if length(c.Params)>0 then
  if cli.setlevel(Logger,c.Params[0]) then
//  if cli.setlevel(TLevelUnit.tolevel(c.Params[0])<>nil) then
//    begin Logger.SetLevel(TLevelUnit.tolevel(c.Params[0]));Result.succsess:=true;
      begin Result.msg:='Loglevel set'; exit; end
  else Result.msg:='invalid Loglevel'
else
  Result.msg:= NO_PARAM;
end;

function load(c:TCLI):TCLIReturn;
begin
Result.succsess:=false;
if length(c.Params)>0 then
  if application.Dofile(c.Params[0]) then
     begin result.succsess:=true; result.msg:='File done';  exit; end
  else
     begin result.msg:='File NOT found';  exit; end
else
  Result.msg:= NO_PARAM;
end;

function item(c:TCLI):TCLIReturn;
var
  i:TIECTCItem;
  txt:String;
  x:integer;
  ses:TIECGWNetSession;
begin
Result.succsess:=false;
if length(c.Params)>0 then
  begin
  i:=application.Items.getIECItem(c.Params[0]);
  if i <>nil  then
     begin
     txt:=i.ToString+#13+#10;
     write(txt);
     for x:=0 to IECGWnetSession.sessionlist.Count-1 do
          begin
          ses := TIECGWNetSession(IECGWnetSession.sessionlist[x]);
          ses.sendtext(txt);
          end;

     result.succsess:=true; result.msg:='Item done';  exit; end
  else
     begin result.msg:='Item NOT found';  exit; end
  end
else
  Result.msg:= NO_PARAM;
end;

function help():TCLIReturn;
var
  x,i:integer;
begin
 result.succsess:=true;
 result.msg:= 'possible commands are:';
 setlength(result.result,length(action));
 for  i:=0 to high(action) do
     Result.result[i]:=action[i];
 x:=length(result.result);
 setlength(result.result,x+length(process));
 for  i:=0 to high(process) do
     Result.result[x+i]:=process[i];
end;

function execJson(jdata : TJSONData):boolean;
var
  cmd:String;
  jo : TJSONObject;
begin
Jo :=TJSONObject(jdata);
cmd:=jo.Strings['cmd'];
logger.info('cmd:'+cmd);
if pos('item',cmd)<>0 then
   begin
   logger.info('doItem');
   CLIItems.execJS(Jo);
   end;
exit;
end;

function exec(c:TCLI):TcliReturn;
// ('list', 'add');
begin
  if c.process<>'.' then
    begin
    if c.process=process[0] then begin result:=CLIRouter.exec(Application.Router,c); exit; end;
    if c.process=process[1] then begin result:=CLIEvent.exec(Application.GWEvent,c); exit; end;
    if c.process=process[2] then begin result:=CLIClient.exec(Application.Clients,c);exit; end;
    if c.process=process[3] then begin result:=CLIServer.exec(Application.Server,Application.Items,c);exit; end;
    if c.process=process[4] then begin result:=CLITimer.exec(Application.timer,c);exit; end;
    if c.process=process[5] then begin result:=CLIItems.exec(Application.items,c);exit; end;
    result.msg:='Process not found';
    result.succsess:=false;    exit;
    end;
  if c.action='?' then
    begin
    result:=help; exit;
    end;
  if c.action=action[0] then
    begin
    result:=load(c); exit;
    end;
  if c.action=action[1] then
    begin
    result:=level(c); exit;
    end;
  if c.action=action[2] then
    begin
    Application.Fexit:=true;
    result.succsess:=true;
    result.msg:='EXIT'; exit;
    end;
  if c.action=action[3] then
    begin result:=item(c); exit;  end;
 result.succsess:=false;
 result.msg:='command not found';
end;

function frun(p: Pointer): ptrint;
var
 s:TSocket;
 ses:TIECGWNetSession;
 sock: TTCPBlockSocket;
begin
  sock := TTCPBlockSocket.Create;
  sock.Bind('0.0.0.0','5001');
  logger.Info(' listen on port '+inttostr(sock.GetLocalSinPort));
  sock.Listen;
    repeat
    s:=sock.Accept;
    logger.Info('accept');
    ses:= TIECGWNetSession.Create(s,@exec);
    ses.logg:=logger;
    ses.ThreadID:=BeginThread(@IECGWnetSession.run,ses);
    IECGWnetSession.SessionList.Add(ses);
   until not netrun;
   ses.stop := true;
   logger.Debug('EXIT-Listen');
   sock.CloseSocket;
   freeandnil(sock);
   freeandnil(ses);
 end;

{ TMyApplication }

//TIECSocketEvent = procedure (Sender: TObject; Socket: TIEC104Socket) of object;
procedure TMyApplication.clientConnectEvent(Sender: TObject;Socket: TIEC104Socket);
var
 i:integer;
 cl:TIEC104Client;
 eva:TEventarray;
begin
  cl:= TIEC104Client (sender);
  logger.Debug('CLient Connect Event '+cl.Name);
  eva := GWEvent.getConnectEvent(cl.name);
  for i:=0 to high(eva) do
     begin
     logger.Debug('doConnectEvent:'+eva[i]);
     exec(cli.Parse(eva[i]));
     end;
end;

procedure TMyApplication.TimerEvent(const S: string);
begin
   logger.Error('****'+S);
end;

procedure TMyApplication.clientDisconectEvent(Sender: TObject;Socket: TIEC104Socket);
var
 i:integer;
 cl:TIEC104Client;
 eva:TEventarray;
begin
  cl:= TIEC104Client (sender);
  logger.Debug('CLient DisConnect Event '+cl.Name);
  eva := GWEvent.getDisConnectEvent(cl.name);
  for i:=0 to high(eva) do
     begin
     logger.Debug('doDisConnectEvent:'+eva[i]);
     exec(cli.Parse(eva[i]));
     end;
end;

procedure TMyApplication.clientCreateEvent(Sender: TObject;Socket: TIEC104Socket);
begin
 logger.Debug('CLient Create Event');
 Socket.onRXData:=@clientRXEvent;
 TIEC104Client (sender).onDisConnect:=@clientDisconectEvent;
 TIEC104Client (sender).onConnect:=@clientConnectEvent;
end;

procedure TMyApplication.clientRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
var
  CL:TIEC104Socket;
  i:integer;
  item : TIECTCItem;
  bu : TIECBUFFER;
begin
 logger.Debug('CLient Data Recieve');
 try
   item := TIECTCItem.create(Buffer,count);
   logger.debug('CRC-IEC-Stream ['+inttostr(count)+'] [ Head:6'
         +' +(IOB.lenght:'+inttostr(LastCRC.iolenght)
         +' * IOB.Count:'+inttostr(LastCRC.iobcount)
         +') =lenght:'+inttoStr(LastCRC.lenght)+']');
 except
   On Exception do
   begin logger.Fatal('CRC-ERROR IEC-Stream ['+inttostr(count)+'] [ Head:6'
         +' +(IOB.lenght:'+inttostr(LastCRC.iolenght)
         +' * IOB.Count:'+inttostr(LastCRC.iobcount)
         +') =lenght:'+inttoStr(LastCRC.lenght)+']');  exit; end;
 end;
 bu:= item.getStream;
 logger.debug(item.Name+' '+IECType[item.getType].name+':'+inttostr(item.ASDU)+':'+inttostr(item.Adr[0]));
 logger.debug(item.tostring);
 //+' :'+BufferToHexStr(bu));
 items.update(item);

 for  i:=0 to server.Connections.Count-1 do
     begin
     cl := server.Connection[i];
     cl.sendBuf(buffer,count,false);
     end;
end;

procedure TMyApplication.ServerCreateEvent(Sender: TObject ;Socket: TIEC104Socket);
begin
 logger.debug('Server Create Event');
 socket.onRXData:=@serverRXEvent;
end;

procedure TMyApplication.serverRXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
var
  i:integer;
  CL:TIEC104Client;
  item : TIECTCItem;
  bu : TIECBUFFER;
begin
// logger.debug('Server-Connection Recieve Event');
 try
   item := TIECTCItem.create(Buffer,count);
 except
   On Exception do
      begin logger.Fatal('CRC-ERROR in received IEC-Stream');  exit; end;
 end;
 bu:= item.getStream;
 logger.debug(item.Name+' '+IECType[item.getType].name+' asdu:'+inttostr(item.ASDU)+
             ' adr:'+inttostr(item.Adr[0])+' :'+BufferToHexStr(bu));
 items.update(item);
// items.update(item.getType,item.ASDU,item.Adr[0]);
 for  i:=0 to server.Connections.Count-1 do
     begin
     cl := clients.Client[i];
     if (cl<>nil) then
       cl.iecSocket.sendBuf(buffer,count,false);
     end;
end;

procedure TMyApplication.ItemUpdateEvent(Sender: TObject);
var
  i:integer;
  item : TIECTCItem;
  eva:TEventarray;
  txt: String;
begin
 item := TIECTCItem (Sender);
// logger.debug('Item Update Event '+inttostr(length(eva)));
 txt:='Update item '+IECType[item.getType].name+':'+inttostr(item.ASDU)+':'+inttostr(item.Adr[0])+
             ' val:'+floattostr(item.Value[0])+' time:'+item.TimeStr[0];
 logger.info(txt);
 eva := GWEvent.getItemEvent(item);
 for i:=0 to high(eva) do
    begin
    logger.Debug('doItemChangeEvent:'+eva[i]);
    exec(cli.Parse(eva[i]));
    end;
end;

Function TMyApplication.Dofile(f:String):boolean;
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
//      Writeln(str);
      mycli := cli.Parse(str);
      exec(mycli);
    until(EOF(File1)); // EOF(End Of File) The the program will keep reading new lines until there is none.
    CloseFile(File1);
  except
    on E: EInOutError do
    begin
     logger.error('File handling error occurred. Details: '+E.ClassName+'/'+E.Message);
     result:=false;
    end;
  end;
end;

procedure TMyApplication.TermStart;
begin
 if (not NetRun) then
     begin
     TerminalThread:=BeginThread(@frun);
     NetRun:=true;
     end;
end;

procedure TMyApplication.TermStop;
begin
  NetRun:=False;
end;

procedure TMyApplication.init;
begin
clogger := TLogger.getInstance('Clients');
clogger.setLevel(TLevelUnit.INFO);
clogger.AddAppender(Fapp);
clogger.AddAppender(Gwapp);
Clients:= TIEC104Clientlist.Create;
clients.Logger:=clogger;
Clients.onClientCreate:=@clientCreateEvent;

Slogger := TLogger.getInstance('Server');
slogger.setLevel(TLevelUnit.INFO);
Slogger.AddAppender(Fapp);
Slogger.AddAppender(Gwapp);
Server := TIEC104Server.Create(self);
Server.Name:='GWSERVER';
Server.Logger:= Slogger;
Server.onClientConnect:=@ServerCreateEvent;
//  server.start;

ItemLogger := TLogger.getInstance('Item');
ItemLogger.setLevel(TLevelUnit.INFO);
ItemLogger.AddAppender(Fapp);
ItemLogger.AddAppender(Gwapp);
Items := TIECTree.create();
Items.Logger:=Itemlogger;
Items.onChange:=@ItemUpdateEvent;

GWEvent := TIECGWEvent.create;
//  GWEvent.addConnectEvent('fer1','server.send 03 02 01');
//  GWEvent.addDisConnectEvent('fer1','server.send 03 02 00');
GWEvent.Logger:=logger;

Timer := TIECGWTimer.create;
//Timer.add('t1');
//Timer.settimer('t1',50);
Timer.Logger:=logger;
Timer.onTimer := @TimerEvent;

Router := TIECRouter.create;
Router.Logger:=logger;
//Router.addRoot('fer1');
//Router.addRoute('fer1',[4,5,6]);
end;

procedure TMyApplication.DoRun;
var
  i:integer;
  Eva: TEventArray;
  Stradr,ErrorMsg:String;
  item : TIECTCItem;
  bu: TIECBUFFER;
  Node:Tnode;
  Stream : array[0..250] of byte;
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
  dofile('iec.cli');
  termstart;

  Stream[0]:=01; Stream[1]:=03;
  Stream[2]:=03;Stream[3]:=00;
  Stream[4]:=01;Stream[5]:=01;
  Stream[6]:=01;Stream[7]:=16;Stream[8]:=00;  Stream[9]:=01;
  Stream[10]:=12;Stream[11]:=16;Stream[12]:=00;  Stream[13]:=01;
  Stream[14]:=42;Stream[15]:=16;Stream[16]:=00;  Stream[17]:=01;

//  item := TIECTCItem.create([01,01,03,00,01,00,01,10,00],10);
  writeln (BufferToHexStr(Stream,18));
  item := TIECTCItem.create(Stream,18);
  logger.info('[18] '+LastCRC.txt);
//  item := TIECTCItem.create();
//  item.setType(M_ME_TB);
  stradr:='';
 // IECItems.TypeAsNumber:=true;
  for i:=0 to item.getIOBCount()-1 do
      begin
      stradr:=stradr+' adr:'+inttostr(item.Adr[i]);
      writeln('item Path:'+item.Obj[i].path);
      end;
  writeln(item.Name+' '+IECType[item.getType].name+' asdu:'+inttostr(item.ASDU)+stradr);
//  readJSONFile('d:\source\pascal\FER\j2.json');
  execJson(StrtoJSON(readJSONFile('d:\source\pascal\FER\j2.json')));
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

  // stop program loop
  while (not FExit) do
        begin
        Readln (cmdIN);
        mycli := cli.Parse(cmdIN);
//        CLI.PrintCLI(mycli);
        myresult:=exec(mycli);
        eva:=CLI.CliReturn(myresult);
        for i:=0 to high(eva) do
           writeln(eva[i]);
        end;
  Terminate;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
  fexit:=false;
end;

destructor TMyApplication.Destroy;
begin
  clients.destroy;
  Server.destroy;
  Items.destroy;
  GWEvent.destroy;
  Timer.destroy;
  Router.destroy;
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
  logger := TLogger.getInstance;
//  logger.setLevel(TLevelUnit.Warn);
  logger.setLevel(TLevelUnit.INFO);
//  logger.setLevel(TLevelUnit.debug);
  Fapp := TFileAppender.Create(ExtractFilePath(ParamStr(0))+'FER1.log');
  logger.addAppender(Fapp);
  GWapp := TGWAppender.Create;
  logger.addAppender(GWApp);
  logger.info('Start');
  Application.init;
  Application.Run;
//  TLogger.freeInstances;
  Application.Free;

end.

