unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ActnList, ExtCtrls, ComCtrls, Spin, monsock, wsocket, packhdrs,
  iec104sockets, TLoggerUnit, TLevelGroupUnit, WPcap;

type

  { Tmonitor }

  Tmonitor = class(TForm)
    ActionWPCAP: TAction;
    ActionServer: TAction;
    ActionRawmonitor: TAction;
    ActionList1: TActionList;
    AdapterList: TListBox;
    Socketconfig: TButton;
    B_doRawMonitor: TButton;
    B_doPcapMonitor: TButton;
    BdoServer: TButton;
    Bevel2: TBevel;
    useFilter: TCheckBox;
    Memo1: TMemo;
    Memo2: TMemo;
    monport: TSpinEdit;
    Panel1: TPanel;
    RawLog: TMemo;
    SpinTK: TSpinEdit;
    StaticText1: TStaticText;
    winpcaplog: TMemo;
    mainlog: TMemo;
    MonIpList: TListBox;
    monlist: TListBox;
    monitorControl: TPageControl;
    Panel2: TPanel;
    Panel3: TPanel;
    clientList: TListBox;
    Label6: TLabel;
    Logout: TMemo;
    PageControl1: TPageControl;
    Panelmonitor: TPanel;
    PanelPcap: TPanel;
    PanelServer: TPanel;
    RawMonitorTab: TTabSheet;
    ServerPort: TSpinEdit;
    Tab1: TTabSheet;
    Tab2: TTabSheet;
    Text1: TStaticText;
    Timer: TTimer;
    StatusBar: TStatusBar;
    monloglevel: TLevelGroup;
    PcapLogLevel: TLevelGroup;
    serverLoglevel: TLevelGroup;
    PcapMonitorTab: TTabSheet;
    procedure ActionrawmonitorExecute(Sender: TObject);
    procedure ActionServerExecute(Sender: TObject);
    procedure ActionWINPcapmonitorExecute(Sender: TObject);
    procedure clientListClick(Sender: TObject);
    procedure clientListDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure LogoutChange(Sender: TObject);
    procedure mainlogChange(Sender: TObject);
    procedure monlistClick(Sender: TObject);
    procedure monlistDblClick(Sender: TObject);
    procedure RawLogChange(Sender: TObject);
    procedure SocketconfigClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
//  private
    { private declarations }
    Function Monlistadd(s,d:string):TIEC104Socket;
    procedure RXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
    procedure PacketEvent (Sender: TObject; PacketInfo: TPacketInfo) ;

    procedure IECServerClientConnect(Sender: TObject;Socket: TIEC104Socket);
    procedure IECServerClientDisConnect(Sender: TObject;Socket: TIEC104Socket);
    procedure winpcaplogChange(Sender: TObject);
  private
     procedure doIniFile(properties:Tstringlist);
     function isinFilter(tk: byte):boolean;
  public
    { public declarations }
    procedure chkpw();
  end;


const
  sPacketLine = '%-12s  %-16s > %-16s  %4d ' ;
//               01:02:03:004  192.168.1.201:161    > 192.168.1.109:1040     81 [0O    ]
  sHeaderLine = 'Time         Source IP:Port       Dest IP:Port           Dlen              Packet Data' ;

var
    monitor: Tmonitor;

implementation

uses
   key,  windows, IECSockDlg , TLevelUnit, TAppAppenderunit;
{$R *.lfm}
{$INCLUDE version.inc}

var
 logger : TLogger;
 RawMonitor: TMonitorSocket ;
 PcapMonitor:TWPcap;
 IECServer : TIEC104Server;
 IECSocket: TIEC104Socket;
 MonLive: boolean = false;
 isMonPcap: boolean;
 monitorport:integer = 2404;

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


{ Tmonitor }
procedure Tmonitor.PacketEvent (Sender: TObject; PacketInfo: TPacketInfo) ;
var
    srcip,destip: string ;

begin
    with PacketInfo do
    begin
    if (EtherProto = PROTO_IP) and (DataLen >0) then
       if (PortSrc=monitorport)  then
        begin
          srcip:= IPToStr (AddrSrc);
          destip:= IPToStr (AddrDest);
 //         logger.debug('['+inttostr(Datalen)+'] '+srcip+' > '+destip);
//          logger.Info('['+inttostr(Datalen)+'] '+srcip+' > '+destip);
          monlistadd(srcip,destip);

          IECSocket.StreamCount:=DataLen;
          IECSocket.DecodeStream(bytebuff);
        end
       else
          logger.debug('receive '+inttostr(Datalen)+' Bytes for port '+inttostr(PortSrc));
      end ;
end ;

function Tmonitor.isinFilter(tk: byte):boolean;
begin
 if (tk = Spintk.value) then
    begin
    isinFilter := true;
    exit;
    end;
 isInFilter := false;
end;

procedure Tmonitor.RXEvent(Sender: TObject;const Buffer:array of byte;count :integer);
var
   x,tk:integer;
begin
 Tk := buffer[0];
 if (useFilter.Checked) and (not isinFilter(tk)) then
 begin
   logger.Info(IECSocket.Name+' TK:'+inttoStr(tk));
   exit;
 end;
logger.Info(IECSocket.Name+' TK:'+inttoStr(tk)+' -->');
if IECServer.Clients.Count =0 then exit;
 for x:=0 to IECServer.Clients.Count-1 do
//   IECServer.Client[x].sendBuf(buffer,count,true);
     IECServer.Client[x].sendBuf(buffer,count,false);
end;

Function Tmonitor.monlistadd(s,d:string):TIEC104Socket;
var
  x:integer;
  AppAppender: TAppAppender  ;
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

//IECSocket:= TIEC104Socket.Create('IEC_in');
IECSocket:= TIEC104Socket.Create();
logger.info('ADD new  Source '+s);
IECSocket.SocketType:=TIECMonitor;
IECSocket.Name:=s;//+' > '+d;
IECSocket.onRXData := @RXEvent;
IECSocket.setLogger('IEC_IN');
AppAppender:= TAppAppender.Create(@mainLog.Lines);
AppAppender.SetThreshold(WARN);
AppAppender.SetName('TRACE');
//AppAppender.SetThreshold(DEBUG);
//if (iecsocket.logger <> nil) then
//   IECSocket.Logger.AddAppender(AppAppender);

monlist.Items.AddObject(s,IECsocket);
result := IECSocket;
end;

procedure Tmonitor.FormCreate(Sender: TObject);
var
   AppAppender: TAppAppender  ;
begin
  logger := TLogger.GetInstance('MONITOR');
   AppAppender:= TAppAppender.Create(@mainLog.Lines);
   AppAppender.SetName('TRACE');
   AppAppender.SetThreshold(INFO);

//   logger.addAppender(TAppAppender.Create(@RawLog.Lines));
   logger.addAppender(AppAppender);
   logger.info('Application started');

   monLogLevel:=TLevelGroup.Create(Panel2,AppAppender);
   monLogLevel.Parent:=Panel2;
   monLogLevel.Width:= 174;

  // raw sockets monitoring
   RawMonitor := TMonitorSocket.Create (self) ;
   AppAppender:= TAppAppender.Create(@Rawlog.Lines);
   AppAppender.SetThreshold(DEBUG);
   RawMonitor.Logger.AddAppender(AppAppender);
   RawMonitor.onPacketEvent := @PacketEvent ;

   MonIpList.Items := LocalIPList ;
   if MonIpList.Items.Count > 0 then MonIpList.ItemIndex := 0 ;

   PcapMonitor:= TWPcap.Create(self);
   AppAppender:= TAppAppender.Create(@Winpcaplog.Lines);
   AppAppender.SetThreshold(DEBUG);
//    WPLogLevel:=TLogLevelGroup.Create(PanelMonitor,PcapMonitorTab.Log);
//    WPLogLevel.Parent:=PanelPCap;
    PcapMonitor.Logger.AddAppender(AppAppender);

    PcapLogLevel:=TLevelGroup.Create(Panel2,AppAppender);
    PcapLogLevel.Parent:=PanelPcap;
    PcapLogLevel.Width:= 174;
    PcapLogLevel.setName('PCAP_LOG');

    PcapMonitor.onPacketEvent := @PacketEvent ;
    AdapterList.Items.Assign (Wpcap.AdapterDescList) ;
    if AdapterList.Items.Count > 0 then AdapterList.ItemIndex := 0 ;

   logger.debug('Create server:');
   IECServer:= TIEC104Server.Create(self);
   IECServer.Name:='Server';
   AppAppender:= TAppAppender.Create(@logout.Lines);
//   AppAppender.SetThreshold(INFO);
   AppAppender.SetThreshold(DEBUG);
   AppAppender.SetName('TRACE');
   IECServer.Logger.AddAppender(AppAppender);
   IECServer.Port := 2404 ;

   //   IECServer.Active := False;
   IECServer.onClientConnect := @IECServerClientConnect;
   IECServer.onClientDisConnect := @IECServerClientDisConnect;

   ServerLogLevel:=TLevelGroup.Create(PanelServer,AppAppender);
   serverLoglevel.Parent:=PanelServer;

   chkpw();
//   close;
end;

procedure Tmonitor.LogoutChange(Sender: TObject);
begin
  if logout.Lines.Count>800 then
     logout.Clear;
end;

procedure Tmonitor.mainlogChange(Sender: TObject);
begin
    if mainlog.Lines.Count>800 then
     mainlog.Clear;
end;


procedure Tmonitor.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
timer.Enabled:=false;
if MonLive then
     begin           //Stop monitoring
       if isMonPcap then
          if PcapMonitor.connected then
               PcapMonitor.stop
           else
               RawMonitor.StopMonitor ;
     end ;

freeandnil(IECServer);
freeandnil(RawMonitor);
freeandnil(PcapMonitor);

logger.info('stopApplication:');
//TLogger.freeInstances;

end;

procedure Tmonitor.ActionrawmonitorExecute(Sender: TObject);
begin
 if MonLive then
   begin           //Stop monitoring
       RawMonitor.StopMonitor ;
       MonLive := false ;
       B_doRawMonitor.Caption := 'Start Monitor' ;
       logger.info('stopMonitoring:');
       B_doPcapMonitor.Enabled := true;
     end
 else
    begin    //Start monitoring
    RawMonitor.Addr := MonIpList.Items [MonIpList.ItemIndex] ;
    RawMonitor.StartMonitor ;
    monitorport := monport.value;
    logger.info('startMonitoring on IP:'+RawMonitor.Addr);
    MonLive := true ;
    isMonPcap := false;
    B_doRawMonitor.Caption := 'Stop Monitor' ;
    B_doPcapMonitor.Enabled := false;
    end;

end;

procedure Tmonitor.ActionWINPcapmonitorExecute(Sender: TObject);
begin
 if MonLive then
   begin           //Stop monitoring
       if PcapMonitor.connected then
         PcapMonitor.stop ;
       MonLive := false ;
       B_doPcapMonitor.Caption := 'Start Monitor' ;
       B_doRawMonitor.Enabled := true;
       logger.info('stop Pcap Monitoring:');
     end
 else
    begin    //Start monitoring
    PcapMonitor.MonAdapter :=Wpcap.getAdapter(AdapterList.ItemIndex) ;
    PcapMonitor.Start;
    logger.info('startMonitoring on Pcap:');
    MonLive := true ;
    isMonPcap := true ;
    B_doPcapMonitor.Caption := 'Stop Monitor' ;
    B_doRawMonitor.Enabled := false;
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


procedure Tmonitor.clientListClick(Sender: TObject);
var
 IECSock:TIEC104Socket;
 i,ix:integer;
begin
 ix:=clientlist.ItemIndex;
 if ix=0 then
    begin
    ServerLogLevel.setAppender(IECServer.Logger.GetAppender('TRACE'));
    IECServer.Logger.Info('IEC Server selectet');
    end;

 if ix>0 then
   begin
   IECSock:=TIEC104Socket(clientlist.Items.Objects[ix]);
   IECServer.logger.Info('Server clinet '+IECSock.Name+' selectet');
//   if (iecsock.logger <> nil )then
//      ServerLogLevel.setAppender(IECSock.Logger.GetAppender('TRACE'));
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
var
  AppAppender: TAppAppender  ;

begin
logger.Info('add Serversocket'+socket.Name);
clientlist.AddItem(socket.name,socket);

socket.setLogger('IEC_OUT');

//t:= IECServer.logger.GetAppender('TRACE');
//AppAppender := TAppAppender.Create(t.getLines);
AppAppender:= TAppAppender.Create(@logout.Lines);
AppAppender.SetThreshold(DEBUG);
//AppAppender.SetThreshold(WARN);
AppAppender.SetName('TRACE');
if (socket.logger <>nil) then
   Socket.Logger.AddAppender(AppAppender);

//socket.Log.LogLevel:=lFATAL;
//socket.Log.code:=logservsock;
end;

procedure Tmonitor.IECServerClientDisConnect(Sender: TObject;Socket: TIEC104Socket);
var
 x:integer;
 s: TIEC104Socket;
begin
 for x:=1 to clientlist.Items.Count-1 do
   begin
   s := clientlist.Items.Objects[x] as TIEC104Socket ;
//   s := (TIEC104Socket) clientlist.Items.Objects[x];
   if s= socket then
      begin
      clientlist.Items.Delete(x);
      end;
   end;
//if clientlist.Items.Count=0 then
end;

procedure Tmonitor.winpcaplogChange(Sender: TObject);
begin
  if winpcaplog.Lines.Count>80 then
     winpcaplog.Clear;
end;

procedure Tmonitor.chkpw();
var
  ini,value:String;
  plist:Tstringlist;
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
   value:=plist.Values['KEY'];
   PWOK := checkPW(value,Application.ExeName);
   end;

if (pwok) then
   begin
   Logger.info('Licence OK');
   doIniFile(pList);
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

procedure Tmonitor.doIniFile(properties:Tstringlist);
var
  ini,value:String;
  i,errorcode:integer;
  usePcap,boolval:boolean;
begin
 value :=properties.Values['usePcap'];
 if value ='' then value:= 'false';
 usePcap := StrToBool(value);
 if (not usePcap) then
    begin
    value:=properties.Values['MonitorIP'];
    i:=MonIpList.Items.IndexOf(value);
     if i<> -1 then
        MonIpList.ItemIndex:=i
      else
         begin
          MonIpList.ItemIndex:=0;
          logger.Error('scan IP not available change to 1-st available IP');
          end;
    monitorControl.ActivePageIndex:=0;
    end
 else
    begin
    value:=properties.Values['MonitorInterface'];
    errorcode:=-1;
    for i:=0 to AdapterList.Count-1 do
      begin
      ini := AdapterList.Items[i];
      if (pos(value,ini) <> 0 ) then
        errorcode:=i;
      end;
    i:=AdapterList.Items.IndexOf(value);
    if errorcode<> -1 then
         AdapterList.ItemIndex:=errorcode
    else
        begin
         AdapterList.ItemIndex:=0;
         logger.Error('scan Interface not available change to 1-st available Interface');
         end;
    monitorControl.ActivePageIndex:=1;
    end;

 Val (properties.Values['ServerPort'],i,errorcode);
 If errorcode=0 then
              serverport.Value:=i;

 Val (properties.Values['MonitorPort'],i,errorcode);
 If errorcode=0 then
           monport.Value:=i;

  Val (properties.Values['MonitorFilter'],i,errorcode);
 If errorcode=0 then
           spintk.Value:=i;

 value :=properties.Values['MonitorFilterActiv'];
 if value ='' then value:= 'false';
 if (StrToBool(value)) then
    usefilter.Checked:=true
 else
  usefilter.Checked:=false;


 value :=properties.Values['MonitorStart'];
 if value ='' then value:= 'false';
 if (StrToBool(value)) then
    begin
    if (not usePcap) then  ActionRawmonitor.Execute
    else ActionWPCAP.Execute;
    end;

 ActionServer.Enabled:=true;
 value :=properties.Values['ServerStart'];
 if value ='' then value:= 'false';
 if (StrToBool(value)) then
     ActionServer.Execute;


end;


procedure Tmonitor.monlistClick(Sender: TObject);
var
 IECSock:TIEC104Socket;
 i,ix:integer;
begin
  ix:=monlist.ItemIndex;
  if ix=0 then
     monLogLevel.setAppender(Logger.GetAppender('TRACE'));

  if ix>0 then
     begin
     IECSock:=TIEC104Socket(monlist.Items.Objects[ix]);
     logger.Info('Monitor socket '+IECSock.Name+' selectet');
//     if (IECSock.Logger<>nil) then
//        monLogLevel.setAppender(IECSock.Logger.GetAppender('TRACE'));
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

procedure Tmonitor.RawLogChange(Sender: TObject);
begin
  if Rawlog.Lines.Count>80 then
     Rawlog.Clear;
end;

procedure Tmonitor.SocketconfigClick(Sender: TObject);
var
 dlg : TSockDlg;
begin
  dlg := TSockDlg.Create(self,IECserver.Timers);
  dlg.ShowModal;
  IECserver.Timers :=dlg.Timerset;
  dlg.Close;
  dlg.destroy;
//  IECserver.Timers;
end;

procedure Tmonitor.TimerTimer(Sender: TObject);
 var
  s,r:string;
begin
  if NOT MonLive then
      exit ;

  if isMonPcap then
       begin
       s:= 'Packets Sent: ' + IntToStr (PcapMonitor.TotSendPackets);
       r:= 'Packets Received: ' + IntToStr (PcapMonitor.TotRecvPackets);
       end
  else
     begin
     s:= 'Packets Sent: ' + IntToStr (RawMonitor.TotSendPackets);
     r:= 'Packets Received: ' + IntToStr (RawMonitor.TotRecvPackets);
     end;

  statusbar.Panels[0].Text:=r;
  statusbar.Panels[1].Text:=s;
end;


end.

