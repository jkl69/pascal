unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ActnList, ExtCtrls, ComCtrls, Spin, monsock, wsocket, packhdrs,
  simplelog, iec104sockets, TLoggerUnit, TLevelGroupUnit, WPcap;

type

  { Tmonitor }

  Tmonitor = class(TForm)
    ActionWPCAP: TAction;
    ActionServer: TAction;
    Actionmonitor: TAction;
    ActionList1: TActionList;
    AdapterList: TListBox;
    BdoMonitor: TButton;
    BdoServer: TButton;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Button1: TButton;
    PanelPcap: TPanel;
    TabSheet1: TTabSheet;
    clientList: TListBox;
    Label6: TLabel;
    logTXT: TMemo;
    Logout: TMemo;
    MonIpList: TListBox;
    monlist: TListBox;
    monport: TSpinEdit;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panelmonitor: TPanel;
    PanelServer: TPanel;
    ServerPort: TSpinEdit;
    StaticText1: TStaticText;
    Tab1: TTabSheet;
    Tab2: TTabSheet;
    Text1: TStaticText;
    Timer: TTimer;
    MonitorSocket: TMonitorSocket ;
    IECServer : TIEC104Server;
    StatusBar: TStatusBar;
//    monloglevel: TLogLevelGroup;
    monloglevel: TLevelGroup;
    serverLoglevel: TLevelGroup;
    WPLoglevel: TLogLevelGroup;
    UsePCap: TCheckBox;
    procedure ActionmonitorExecute(Sender: TObject);
    procedure ActionServerExecute(Sender: TObject);
    procedure ActionWPCAPExecute(Sender: TObject);
    procedure AdapterListClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure clientListClick(Sender: TObject);
    procedure clientListDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure init();
    procedure monlistClick(Sender: TObject);
    procedure monlistDblClick(Sender: TObject);
    procedure trace(const S:String);
    procedure TimerTimer(Sender: TObject);
//  private
    { private declarations }
    Function Monlistadd(s,d:string):TIEC104Socket;
    procedure RXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
    procedure PacketEvent (Sender: TObject; PacketInfo: TPacketInfo) ;

    procedure IECServerClientConnect(Sender: TObject;Socket: TIEC104Socket);
    procedure IECServerClientDisConnect(Sender: TObject;Socket: TIEC104Socket);
  public
    { public declarations }
  end;

  { TLogAppender }
  TLoggAppender =class(TInterfacedObject, Ilogappender)
    public
     procedure dolog(sender:Tlog;s:string);
     procedure onLevelchange(sender:Tlog);
   end;


const
  sPacketLine = '%-12s  %-16s > %-16s  %4d ' ;
//               01:02:03:004  192.168.1.201:161    > 192.168.1.109:1040     81 [0O    ]
  sHeaderLine = 'Time         Source IP:Port       Dest IP:Port           Dlen              Packet Data' ;


 var
    logger : TLogger;
    monitor: Tmonitor;
///  MonitorPcap : TMonitorPcap;
   WPMon:TWPcap;
  IECSocket: TIEC104Socket;
  MonLive: boolean = false;
  monitorport:integer = 2404;

implementation

uses
   key,  windows, IECSockDlg , TLevelUnit, TAppAppenderunit;
{$R *.lfm}
{$INCLUDE version.inc}

var
 llog:TLog;
// logAppender:TLogappender;

const
    logmon=1;logmonsock=2;logserv=3;logservsock=4;

 function getCreateTime(FileName : string):Tdatetime;
         function DSiFileTimeToDateTime(fileTime: TFileTime; var dateTime: TDateTime): boolean;
         var
             sysTime: TSystemTime;
         begin
           Result := FileTimeToSystemTime(fileTime, sysTime);
           if Result then
               dateTime := SystemTimeToDateTime(sysTime);
         end; { DSiFileTimeToDateTime }
var
  Created : TDateTime;
  fileHandle            : cardinal;
  fsCreationTime,fsLastAccessTime,fsLastModificationTime: TfileTime;

begin
fileHandle := CreateFile(PChar(fileName), GENERIC_READ, FILE_SHARE_READ, nil,OPEN_EXISTING, 0, 0);
if fileHandle <> INVALID_HANDLE_VALUE then
   try
    GetFileTime(fileHandle, @fsCreationTime, @fsLastAccessTime,@fsLastModificationTime);
    if DSiFileTimeToDateTime(fsCreationTime, created) then
     result:=(Created);
   finally
     CloseHandle(fileHandle);
  end;
end;

Function hex2Long (theHex: String): longint;
var
 n: longint;
 x: integer;
begin
n := 0;
if theHex <> '' then
   begin
   for x := 1 to length(theHex) do
	if theHex[x] in ['0'..'9'] then
        	n := n * 16 + ord(theHex[x]) - 48
	else
          if theHex[x] in ['A'..'Z'] then
	     n := n * 16 + ord(theHex[x]) - 55
	  else
	      n := n * 16 + ord(theHex[x]) - 87;
   end;
hex2Long := n;
end;

function getPW(llic:string):string;
 var
   licpos:integer;
 begin
   result:='';
   licpos:=hex2Long(copy(llic,63,2));
//   rs:=copy(longlic,1,16)  ;
   result:=copy(llic,licpos*2+1,16)  ;
   logger.debug(result);
 end;

{ TLogAppender }

procedure TLoggAppender.dolog(sender:Tlog;s: string);
begin

case sender.code of
  logmon,logmonsock : begin
           monitor.logTXT.Append(s);
           if monitor.logTXT.Lines.Count>1000 then
              monitor.logTXT.Clear;
           end;
  logserv,logservsock : begin
           monitor.Logout.Append(TimeToStr(now)+'  '+s);
           if monitor.Logout.Lines.Count>1000 then
              monitor.Logout.Clear;
           end;
  end;

end;

procedure TLoggAppender.onLevelchange(sender:Tlog);
begin
 case sender.code of
   logmon,logmonsock : monitor.trace(sender.Name+' LogLevel Changed to '+ sender.GetLogLevelStr);
   logserv,logservsock :  monitor.Logout.Append(sender.Name+' LogLevel Changed to '+ sender.GetLogLevelStr);
 end;

end;


{ Tmonitor }
procedure Tmonitor.PacketEvent (Sender: TObject; PacketInfo: TPacketInfo) ;
var
    srcip,destip: string ;

begin
    with PacketInfo do
    begin
    if (EtherProto = PROTO_IP) and (DataLen >0) then
       begin
       logger.debug('receive '+inttostr(Datalen)+' Bytes for port '+inttostr(PortSrc));
       if (PortSrc=monitorport)  then
        begin
          logger.debug('Port '+inttoStr(monitorport)+' receive '+inttostr(Datalen)+' Bytes');
          srcip:= IPToStr (AddrSrc);
          destip:= IPToStr (AddrDest);
          monlistadd(srcip,destip);

          IECSocket.StreamCount:=DataLen;
          IECSocket.DecodeStream(bytebuff);
        end
      end ;
   end;
end ;

procedure Tmonitor.RXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
var
   x:integer;
begin
 if IECServer.Clients.Count =0 then exit;
 for x:=0 to IECServer.Clients.Count-1 do
//   IECServer.Client[x].sendBuf(buffer,count,true);
   IECServer.Client[x].sendBuf(buffer,count,false);
end;

Function Tmonitor.monlistadd(s,d:string):TIEC104Socket;
var
  x:integer;
begin
if monlist.Items.Count>0 then
   Begin
   x:=0;
   repeat
    if monlist.Items[x]=s then
       begin
       IECSocket:= TIEC104Socket(monlist.Items.Objects[x]);
       result := IECSocket;
       exit;
       end;
    inc(x)
   until x=monlist.Items.Count;
   end;

IECSocket:= TIEC104Socket.Create;
logger.info('new Source found');
IECSocket.SocketType:=TIECMonitor;
IECSocket.Name:=s+' > '+d;
IECSocket.onRXData := @RXEvent;
//IECSocket.Log.LogLevel:=lDEBUG;
//IECSocket.Log.LogAppender:=logAppender;
//IECSocket.Log.LogLevel:=lFATAL;
//IECSocket.Log.LogLevel:=lFATAL;
//IECSocket.Log.code:=logmonsock;

monlist.Items.AddObject(s,IECsocket);
result := IECSocket;
end;

procedure Tmonitor.trace(const S:String);
begin
  logTXT.Append(s);
  if logTXT.Lines.Count>1000 then
    logTXT.Clear;
end;


procedure Tmonitor.FormCreate(Sender: TObject);
var
   AppAppender: TAppAppender  ;
begin
  logger := TLogger.GetInstance('MONITOR');
//  logger := TLogger.GetInstance;
//  logger.setLevel(TLevelUnit.INFO);
//    logger.addAppender(TFileAppender.Create('C:\test.log'));

   AppAppender:= TAppAppender.Create(@logtxt.Lines);
   AppAppender.SetThreshold(INFO);

//   logger.addAppender(TAppAppender.Create(@logtxt.Lines));
   logger.addAppender(AppAppender);
   logger.info('Application started');

//   log:=TLog.Create;
// logAppender:=TLogAppender.Create;
// slogAppender:=TServerLogAppender.Create;
// log.Name:='MonitorSocket';
// log.code:= logmon;
// log.LogAppender:= logAppender;

   monLogLevel:=TLevelGroup.Create(PanelMonitor,AppAppender);
//   monLogLevel:=TLevelGroup.Create(PanelMonitor,logger);
   monLogLevel.Parent:=Panelmonitor;

  // raw sockets monitoring
   MonitorSocket := TMonitorSocket.Create (self) ;
   MonitorSocket.onPacketEvent := @PacketEvent ;
   MonIpList.Items := LocalIPList ;
   if MonIpList.Items.Count > 0 then MonIpList.ItemIndex := 0 ;

    WPmon:= TWPcap.Create(self);
//    WPLogLevel:=TLogLevelGroup.Create(PanelMonitor,Wpmon.Log);
//    WPLogLevel.Parent:=PanelPCap;
//    WPmon.Log.LogAppender:=wlogAppender;
    WPmon.onPacketEvent := @PacketEvent ;
    AdapterList.Items.Assign (Wpcap.AdapterDescList) ;

   logger.debug('Create server:');
   IECServer:= TIEC104Server.Create(self);
   IECServer.Name:='Server';
//   IECServer.Log.code:=logserv;
//   IECServer.Log.LogAppender:=logAppender;
AppAppender:= TAppAppender.Create(@logout.Lines);
AppAppender.SetThreshold(INFO);
     IECServer.Logger.AddAppender(AppAppender);
   IECServer.Port := 2404 ;
   IECServer.Active := False;
   IECServer.onClientConnect := @IECServerClientConnect;
   IECServer.onClientDisConnect := @IECServerClientDisConnect;
   ServerLogLevel:=TLevelGroup.Create(PanelServer,AppAppender);
   serverLoglevel.Parent:=PanelServer;

   init();
//   close;
end;


procedure Tmonitor.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   if MonLive then
     begin           //Stop monitoring
         if UsePCap.Checked then
            begin
                if WPmon.connected then
               WPmon.stop ;
            end
         else
            MonitorSocket.StopMonitor ;
         MonLive := false ;
         BdoMonitor.Caption := 'Start Monitor' ;
         logger.info('stopMonitoring:');
       end ;

freeandnil(IECServer);
freeandnil(MonitorSocket);

freeandnil(WPMon);
logger.info('stopApplication:');
TLogger.freeInstances;
end;

procedure Tmonitor.ActionmonitorExecute(Sender: TObject);
begin
 if MonLive then
   begin           //Stop monitoring
       if UsePCap.Checked then
          begin
              if WPmon.connected then
             WPmon.stop ;
          end
       else
          MonitorSocket.StopMonitor ;
       MonLive := false ;
       BdoMonitor.Caption := 'Start Monitor' ;
       logger.info('stopMonitoring:');
//       logger.Debug('DstopMonitoring:');
     end
 else
    begin    //Start monitoring
    if UsePCap.Checked then
      begin
      WPmon.MonAdapter :=Wpcap.getAdapter(AdapterList.ItemIndex) ;
      WPmon.Start;
//      log.info('startMonitoring on Pcap:');
      end
    else
       begin
       MonitorSocket.Addr := MonIpList.Items [MonIpList.ItemIndex] ;
       MonitorSocket.StartMonitor ;
       logger.info('startMonitoring on IP:'+MonitorSocket.Addr);
       end;
    MonLive := true ;
    BdoMonitor.Caption := 'Stop Monitor' ;
    monitorport := monport.value;
    end;

end;

procedure Tmonitor.ActionServerExecute(Sender: TObject);
begin
  if IECServer.Active then
   begin
   Bdoserver.Caption:= 'Start Server';
   IECServer.Active:=false;
   ServerPort.Enabled:=true;
   end
else
   begin
   Bdoserver.Caption:= 'Stop Server';
   IECServer.Port:= ServerPort.value;
   IECServer.Active:= true;
   ServerPort.Enabled:=false;
   end;
end;

procedure Tmonitor.ActionWPCAPExecute(Sender: TObject);
begin
  if WPmon.connected then
     WPmon.stop
  else
    begin
      WPmon.MonAdapter :=Wpcap.getAdapter(AdapterList.ItemIndex) ;
      WPmon.Start;
    end;
end;

procedure Tmonitor.AdapterListClick(Sender: TObject);
begin
end;

procedure Tmonitor.Button1Click(Sender: TObject);
begin
  close;
end;

procedure Tmonitor.clientListClick(Sender: TObject);
var
 IECSock:TIEC104Socket;
 i,ix:integer;
begin
 ix:=clientlist.ItemIndex;
 if ix=0 then
    begin
    for i:=1 to clientlist.Count-1 do
       begin
       IECSock:=TIEC104Socket(clientlist.Items.Objects[i]);
//       IECsock.Log.LogLevel:=lFATAL;
       end;
//    ServerLogLevel.setlog(IECServer.log);
    end;

 if ix>0 then
   begin
   for i:=1 to clientlist.Count-1 do
     begin
         IECSock:=TIEC104Socket(clientlist.Items.Objects[i]);
         if i<>ix then
//           IECsock.Log.LogLevel:=IECServer.Log.LogLevel
//         else
//           IECsock.Log.LogLevel:=lFATAL;
    end;
//   ServerLogLevel.setlog(TIEC104Socket(clientlist.Items.Objects[ix]).log);
   end;
end;

procedure Tmonitor.clientListDblClick(Sender: TObject);
var
IECSock:TIEC104Socket;
IECSockDlg : TSockDlg;
ix:integer;
begin
 ix:=clientlist.ItemIndex;
 if ix>0 then
   begin
   IECSock := TIEC104Socket(clientlist.Items.Objects[ix]);
   iecsockdlg:=TSockdlg.Create(self,IECSock);
   iecsockdlg.ShowModal;
   iecsockdlg.Close;
   end;
end;


procedure Tmonitor.IECServerClientConnect(Sender: TObject;Socket: TIEC104Socket);
begin
clientlist.AddItem(socket.name,socket);
//socket.Log.LogLevel:=lFATAL;
//socket.Log.code:=logservsock;
end;

procedure Tmonitor.IECServerClientDisConnect(Sender: TObject;Socket: TIEC104Socket);
var
 x:integer;
begin
for x:=1 to clientlist.Items.Count-1 do
  if clientlist.Items.Objects[x]= socket then
      clientlist.Items.Delete(x);

//if clientlist.Items.Count=0 then
end;

procedure Tmonitor.init();
var
  ini:String;
  llic:string;
  plist:Tstringlist;
  i,code:integer;
  PWOK:boolean;

begin
 Caption:=caption+'  '+versionStr;

 ini:=getcurrentDir+'\sniffer.ini';
 PWOK:=false;
 if fileexists(ini) then
    begin
    statusbar.Panels[2].Text:=ini;
    plist:=Tstringlist.Create;
    pList.LoadFromFile(ini);
    llic:=plist.Values['KEY'];
    PWOK := checkPW(llic,Application.ExeName);
    end;

if (pwok) then
    begin
    ActionServer.Enabled:=true;
    Logger.info('Licence OK');
    ini:=plist.Values['MonitorIP'];
    i:=MonIpList.Items.IndexOf(ini);
    if i<>-1 then
         MonIpList.ItemIndex:=i;
    Val (plist.Values['ServerPort'],i,Code);
    If Code=0 then
           serverport.Value:=i;
    ActionMonitor.Execute;
    ActionServer.Execute;
    end
else
    begin
     if PasswordBox('Password','PLS. Enter Password')=pwStr then
        begin
        ActionServer.Enabled:=true;
        end
     else
       Logger.error('Licence ERROR no Server Available');//+llic);
     end;
end;

procedure Tmonitor.monlistClick(Sender: TObject);
var
 IECSock:TIEC104Socket;
 i,ix:integer;
begin
  ix:=monlist.ItemIndex;
  if ix=0 then
    begin
    for i:=1 to monlist.Count-1 do
        begin
        IECSock:=TIEC104Socket(monlist.Items.Objects[i]);
//        IECsock.Log.LogLevel:=lFATAL;
        end;
 //   monLogLevel.setlog(log);
    end;

  if ix>0 then
    begin
    for i:=1 to monlist.Count-1 do
      begin
          IECSock:=TIEC104Socket(monlist.Items.Objects[i]);
          if i<>ix then
//            IECsock.Log.LogLevel:=log.LogLevel
//          else
//            IECsock.Log.LogLevel:=lFATAL;
     end;
//    monLogLevel.setlog(TIEC104Socket(monlist.Items.Objects[ix]).log);

    end;
end;

procedure Tmonitor.monlistDblClick(Sender: TObject);
 var
 IECSock:TIEC104Socket;
 IECSockDlg : TSockDlg;
 ix:integer;
begin
  ix:=monlist.ItemIndex;
  if ix>0 then
    begin
    IECSock := TIEC104Socket(monlist.Items.Objects[ix]);
    iecsockdlg:=TSockdlg.Create(self,IECSock);
    iecsockdlg.ShowModal;
    iecsockdlg.Close;
    end;
end;

procedure Tmonitor.TimerTimer(Sender: TObject);
 var
  s,r:string;
begin
  if NOT MonLive then
      exit ;

  if usePcap.Checked then
       begin
       s:= 'Packets Sent: ' + IntToStr (WPmon.TotSendPackets);
       r:= 'Packets Received: ' + IntToStr (Wpmon.TotRecvPackets);
       end
  else
     begin
     s:= 'Packets Sent: ' + IntToStr (MonitorSocket.TotSendPackets);
     r:= 'Packets Received: ' + IntToStr (MonitorSocket.TotRecvPackets);
     end;

  statusbar.Panels[0].Text:=r;
  statusbar.Panels[1].Text:=s;
end;


end.

