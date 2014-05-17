unit iec101serial;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF UNIX}
  cthreads,
  {$ELSE UNIX}
  windows,
  {$ENDIF}
  Classes,  SysUtils,
  synaser, TLoggerUnit, TLevelUnit;

type

  TSerialFunctionEvent = procedure(Sender: TObject; funcNo:byte) of object;
  TRxBufEvent = procedure(Sender: TObject;const Buffer: array of byte; Count: Integer) of object;
//  TMessageBuffer = procedure(Sender: TObject; v: double) of object;
//  TRxBufEvent = procedure(Sender: TObject; buffer: pointer; Count: Integer) of object;


  TIEC101Frame = (IEC101FrameError, IEC101FrameShort,IEC101FrameLong);

  TIEC101Serial = class;

//  TIEC101Member = record
  TIEC101Member = class
     fAlive :boolean;
  protected
     FLog: TLogger;
     RXdata :array of byte;
     IEC101Port : TIEC101Serial;
     INIT :boolean;
     fdata:Tlist; //messageBuffer
     RXPRM,PRM:Boolean; // Direction 1= master to slave  0= slave to master
     RXFCB,FCB:Boolean;  // master muss jede Nachricht toggeln;
     RXFCV,FCV:Boolean;
     RXf101:byte;
     f101:byte;
     req:byte;
     fonConnect : TnotifyEvent;
     fonDisConnect : TnotifyEvent;
     fonDataRX : TRxBufEvent;// TGetStrProc;
     fonDataTx : TRxBufEvent;
     function bufferusage:double;
     procedure log(ALevel : TLevel; const AMsg : String);
     procedure setAlive(val:Boolean);
 public
     Name:String;
     linkadr:word;
     constructor Create(port:TIEC101Serial) ;
     destructor destroy;
     procedure reset;
     Function NextData:TMemoryStream;
     Function HasData:boolean;
     procedure Adddata(buffer: array of byte);
     procedure setRequest(val:Byte);
     property  Alive:Boolean read fAlive write setAlive;
     property  Logger:Tlogger read Flog write Flog;
     property  onConnect : TnotifyEvent read fonConnect write fonConnect;
     property  onDisConnect : TnotifyEvent read fonDisConnect write fonDisConnect;
     property  onDataRx:TRxBufEvent read fonDataRX write fonDataRX;
     property  onDataTx:TRxBufEvent read fonDataTX write fonDataTX;
  end;

  TIEC101Serial = class(TBlockSerial)
    protected
//      loopcount :integer;
      currentmember: TIEC101Member;
    private
       FLog: TLogger;
       ThreadID:TThreadID;
       FT0:  Word;
       fms:word;
       Fport: String;
       parity: char;
       Bytestowait: byte;
       Frame: TIEC101Frame;
       Blocklength:byte;
       buf:array[0..255] of byte;
       fonRX : TRxBufEvent;// TGetStrProc;
       fonTX :  TRxBufEvent;
       fonlog :  TGetStrProc;
       fonStart : TnotifyEvent;
       fonStop : TnotifyEvent;
       procedure ConfigIECSerial;
       function CalcCRC:byte;//(count:byte):byte;
       function IsCRC:boolean;
       procedure DecodeRX;
       Function IsLinkNo:boolean;
       Procedure ReceiveFT12Frame;
//       Function ReceiveFT12Frame:boolean;
//       Function ReceiveFT12Frame(waittime:word):boolean;
       procedure decodeControlByte;
       procedure encodeControlByte;
       procedure doFunction; virtual Abstract;
       procedure log(ALevel : TLevel; const AMsg : String);
       procedure terminate;
       procedure PingRespond(e5:Boolean);
       procedure getdata;
       procedure TXData(st:TMemorystream);
       procedure send(buffer: pointer; length: integer);
//       procedure ReqLinkStatus;
    public
       Name:String;
       baud, bits: integer;
       stopbits: integer;
       rxcount :cardinal;
       rxDatacount  :cardinal;
       txcount :cardinal;
       txDatacount  :cardinal;
       Terminated:boolean;
//       pause:boolean;
      constructor Create;
      destructor destroy;
      class function GetErrorDesc(ErrorCode: integer): string;
      Function getConfig:TDCB;
      function getConfigStr:String;
      function setParity(p:char):boolean;
//       procedure send(a:array of byte);
      Function Start:Boolean;
      procedure Stop;
      procedure Execute; virtual Abstract;
      property  Logger:Tlogger read Flog write Flog;
      property  Port:String read Fport write Fport;
      //      property  LinkAdr:word read Flinkadr write FLinkAdr;
      property  onStart:TnotifyEvent read fonStart write fonStart;
      property  onStop:TnotifyEvent read fonStop write fonStop;
      property  onRx:TRxBufEvent read fonRX write fonRX;
      property  onTx:TRxBufEvent read fonTX write fonTX;
//      property  onLog:TGetStrProc read fonlog write fonlog;
//      property  onFunctionChange:TSerialFunctionEvent read fonFunctionChange write fonFunctionChange;
  end;

  TIEC101Master = class(TIEC101Serial)
  protected
    loopcount :integer;
  private
    FMemberList :Tlist;
    fonConnect : TnotifyEvent;
    fonDisConnect : TnotifyEvent;
    fonDataRX : TRxBufEvent;// TGetStrProc;
//    Function  GetNextMember:TIEC101Member;
    Procedure  GetNextMember;
    procedure  doPoll;
    procedure  Request;
    procedure  doFrame;
    procedure ReqData(dclass:byte);
    procedure ReqLinkStatus;
    procedure SendReset;
    procedure Execute; override;
  public
     IdleTime : word;
      constructor Create;
      destructor destroy;
      function GetMember(Index: Integer): TIEC101Member;
      function GetMember(aname:String): TIEC101Member;
      Function addMember(s:String;adr:word;alog:Tlogger):TIEC101Member;
//      Function addMember(s:String;adr:word):TIEC101Member;
      procedure sendData(stream:TMemorystream; WaitConfirm:boolean);
      property Members:Tlist Read FMemberList write FMemberList;
      property Member[Index: Integer]: TIEC101Member read GetMember;
      property  onConnect : TnotifyEvent read fonConnect write fonConnect;
      property  onDisConnect : TnotifyEvent read fonDisConnect write fonDisConnect;
      property  onDataRx:TRxBufEvent read fonDataRX write fonDataRX;
  end;

 TIEC101Slave = class(TIEC101Serial)
  private
      fmember: TIEC101Member;
      procedure confirm(Ack:boolean);
      procedure DataRespond;//(DataAvailable:boolean);
      procedure DataRespond8(data:array of Byte);
      procedure doFunction; override;
  public
     constructor Create;
     destructor destroy;
     procedure Execute; override;
     property  Member:TIEC101Member read fmember write fmember;
   end;

function hextoStr(b:array of byte;count:integer):String;
function parityToChar(p:byte):char;

const
  MessageBufferSize =100;

implementation

uses TLoggingEventUnit;

const
  ErrFTFirst = 10010;
  ErrFTCRC = 10011;

function hextoStr(b:array of byte;count:integer):String;
var i:integer;
begin
  for i:=0 to count-1 do
    result:=result+inttohex(b[i],2)+' ';
end;

function run(p : pointer) : ptrint;
var iecport:TIEC101Serial;
begin
  iecport:=TIEC101Serial(p);
  iecport.Execute;
end;

{  TIEC101Member  }
constructor TIEC101Member.Create(port: TIEC101Serial);
begin
  IEC101Port := port;
  fdata:= tlist.Create;
  RXf101:=255;
  req:=9;
  init:=False;
  falive:=False;
end;

destructor TIEC101Member.destroy;
begin
  fdata.Destroy;
end;

Function TIEC101Member.HasData:boolean;
begin
 result:=fData.Count>0;
end;

procedure TIEC101Member.log(ALevel : TLevel; const AMsg : String);
begin
  if (assigned(Flog)) then
     Flog.log(ALevel,flog.GetName+'_'+AMsg);
end;

procedure TIEC101Member.setAlive(val:Boolean);
begin
 if Falive<>val then
   begin
   fAlive:=val;
   if val then
     if assigned(onConnect) then  onConnect(self);
   if not val then
     if assigned(onDisConnect) then  onDisConnect(self);
   end;
end;

procedure TIEC101Member.setRequest(val:Byte);
begin
 req:=val;
end;

procedure TIEC101Member.reset;
begin
log(debug,'Disconnect');
alive:=False;
init:=False;
end;

function TIEC101Member.Bufferusage:double;
begin
  result :=  fdata.Count / MessageBufferSize;
end;

procedure TIEC101Member.Adddata(buffer:array of byte);
var
 st:TMemorystream;
begin
 st:=TMemorystream.Create;
 st.write(buffer[0],length(buffer));
 fdata.Add(st);
 log(info,'AddData to send Bytes:'+inttoStr(length(buffer)));
 if assigned(fonDataTx) then
   fonDatatx(self,buffer,length(buffer));
 if fdata.Count>MessageBufferSize then
    begin
     log(fatal,'buffer overflow');
    end;
end;

Function TIEC101Member.NextData:TMemoryStream;
begin
 result:=nil;
 if fdata.Count>0 then
   begin
   result:=TMemoryStream(fdata[0]);
   fdata.Delete(0);
   end;
end;

{  TIEC101Serial }

constructor TIEC101Serial.Create;
begin
  inherited;// create(true);
  currentMember := nil;
  ThreadID := 0;
  fport:='COM1';
//  config(9600, 8, 'E', SB1, False, False);
   baud :=9600;
   bits := 8;
   parity:= 'E';
   stopbits := SB1;
  end;

class function TIEC101Serial.GetErrorDesc(ErrorCode: integer): string;
begin
   Result:= '';
  case ErrorCode of
    sOK:               Result := 'OK';
    ErrFTFirst:   Result := 'HEADER ERROR FirstByte' ;{JKL}
    ErrFTCRC:     Result := 'HEADER ERROR CRC';    {JKL}
  end;
  if Result = '' then
  begin
    result:=inherited;
  end;
end;

Function TIEC101Serial.getConfig:TDCB;
begin
  result:=dcb;
end;

procedure TIEC101Serial.ConfigIECSerial;
begin
  log(info,'CONFIG MASTER');
  config(baud, bits, parity, stopbits, False, False);
  if LastError<>0 then begin  log(error,'LastError:'+GetErrorDesc(LastError));   end;
end;

function parityToChar(p:byte):char;
begin
 case p of
  0 : result:= 'N';
  1 : result:= 'O';
  2 : result:= 'E';
  3 : result:= 'M';
  4 : result:= 'S';
 end;
end;

function isParity(p:char):boolean;
begin
 result := False;
 if p in ['N','n','O','o','E','e','M','m','S','s' ] then
   result := true;
end;

function TIEC101Serial.setParity(p:char):boolean;
begin
 result := false;
 if isParity(p) then
    begin
    Parity := p;
    result := true;
    end;
end;

function TIEC101Serial.getConfigStr:String;
//( baud, bits: integer; parity: char; stop: integer;softflow, hardflow: boolean);
var s,p,ptxt,sb:String;
    b:Dword;
    stb,l:byte;
begin
if InstanceActive then
   begin
   p:=device;
   ptxt:=parityToChar(DCB.Parity);
   b:= DCB.BaudRate;
   l:=DCB.ByteSize;
   stb:= DCB.StopBits;
   s:='[open]';
   end
else
  begin
    p:= Fport;
    ptxt :=Parity;
    b:=  Baud;
    l:= Bits;
    stb:= StopBits;
    s:='[close]';
  end;

 case stb of
      0 : sb:= '1';
      1 : sb:= '1.5';
      2 : sb:= '2';
 end;

  result:=format('Device%s: %s %d %d%s%s',
 //   [s,p,DCB.BaudRate,DCB.ByteSize,txt,sb]);
    [s,p,b,l,ptxt,sb]);
end;

destructor TIEC101Serial.destroy;
begin
//  fserial.destroy;
//  fmember.Destroy;
  inherited;
end;

procedure TIEC101Serial.decodeControlByte;
var  s:String; i:integer;  b:byte;
begin
if currentMember<>nil then
    with currentMember do
    begin
     if Frame = TIEC101Frame.IEC101FrameShort then
       b:= buf[1]
     else
       b:= buf[4];
     RXPRM:= (b and$40)=$40;
     RXFCB:= (b and$20)=$20;
     RXFCV:= (b and$10)=$10;
     RXf101:= b and $0f;
    if Frame = TIEC101Frame.IEC101FrameLong then
       begin
       setlength(RXdata,Blocklength-3);
       for i:=0 to Blocklength-4 do
           RXdata[i]:=buf[7+i];
       if assigned(onDataRX) then
            onDataRx(self,RXdata,length(RXdata));
       end;
    end;
end;

//Function TIEC101Serial.encodeControlByte:byte;
procedure TIEC101Serial.encodeControlByte;
var  b:byte;
begin
if currentMember<>nil then
    with currentMember do
    begin
    b:= f101;
    if PRM then b:=b+$40;
    if FCB then b:=b+$20;
    if FCV then b:=b+$10;

    if Frame = TIEC101Frame.IEC101FrameShort then
       buf[1]:=b
    else
       buf[4]:=b;
    end;
end;


function TIEC101Serial.IsLinkNo:boolean;
var  linkNo:word;
begin
  if Frame = TIEC101Frame.IEC101FrameShort then
    linkNo:=buf[2]+buf[3]*256
  else
    linkNo:=buf[5]+buf[6]*256;
  if currentMember<>nil then
    result := (currentMember.linkadr=LinkNo);
end;


//Function TIEC101Serial.ReceiveFT12Frame:boolean;
Procedure TIEC101Serial.ReceiveFT12Frame;
//Function TIEC101Serial.ReceiveFT12Frame(waittime:word):boolean;
var le:TLoggingEvent;
    txt : String;
    TS : TTimeStamp;
//    Function ReceivePart2:boolean; //
    Procedure ReceivePart2;
    var waittime:word;
    begin
//      result:=false;
      waittime:=Ft0-fms;
//  log(debug,format('Receive first Byte after: %d/%d  msec left:%d',[fms,fT0,waittime]));
      Frame := TIEC101Frame.IEC101FrameError;
      if (buf[0]=$68) then
         begin
           Frame := TIEC101Frame.IEC101FrameLong;
           RecvBufferEx(@buf[1] ,3, waittime);
           waittime := DateTimeToTimeStamp (Now).Time - waittime;
           Blocklength :=buf[1];
           Bytestowait := Blocklength+2;
           RecvBufferEx(@buf[4] ,Bytestowait, waittime);
//           result:=True;
         end;
      if buf[0]=$10 then
         begin
           Frame := TIEC101Frame.IEC101FrameShort;
           RecvBufferEx(@buf[1] ,5, waittime);
           Blocklength :=0;
//           result:=True;
         end;
      if Frame = TIEC101Frame.IEC101FrameError then
          fLastError := ErrFTFirst//'HEADER ERROR firstByte['+hextostr(buf,1);
      else
        if CurrentMember=nil then   //log here is no Member assinged otherwise the member should log
           log(debug,'RX '+hextoStr(buf,6))
        else
           currentMember.log(debug,'RX '+hextoStr(buf, Blocklength+6));
    end;

begin
//  result:=true;
 FLastError :=ErrWrongParameter;
  TS := DateTimeToTimeStamp(Now);
  Bytestowait:=1;       //wait only for 1 byte ( $10 or $68)
  RecvBufferEx(@buf[0] ,Bytestowait, FT0);
  Fms := DateTimeToTimeStamp (Now).Time -ts.Time;
  if LastError <> sOK then  exit;

//  if ReceivePart2 then
 ReceivePart2;
 if LastError <> sOK then exit;

 if not isCRC then
    begin
    FLastError := ErrFTCRC;  //'HEADER ERROR CRC ';
    exit;
    end;
  FLastError :=sOK;
 //  result:=false;
end;

procedure TIEC101Serial.send(buffer: pointer; length: integer);
 begin
 if assigned(fontx) then
    fontx(self,buf,length);
 inc(TXcount);
 if CurrentMember=nil then   //log here is no Member assinged otherwise the member should log
    log(debug,'TX: '+HEXTOSTR(buf,length))
 else
    currentMember.log(debug,'TX: '+HEXTOSTR(buf,length));
 SendBuffer(@buf,length);
end;

procedure TIEC101Serial.PingRespond(e5:boolean);
begin
 if currentMember<>nil then
    with currentMember do
    begin
    f101:=11;
    PRM:=false;
    FCB:=false;
    FCV:=false;
    buf[0]:=$10;  encodecontrolByte;
    buf[2]:=linkadr mod 256;  buf[3]:=linkadr div 256;  Blocklength:=3;
    buf[4]:=CalcCRC;  buf[5]:=$16;
    Send(@buf,6);
   end;
end;

function TIEC101Serial.IsCRC:boolean;
var c:byte;index:integer;
begin
result:= False;
if Frame = TIEC101Frame.IEC101FrameLong then  index := 4+Blocklength
else   index :=4;
c:=buf[index];
if c=CalcCRC then   result:=true;
end;

function TIEC101Serial.CalcCRC:byte;//(count:byte):byte;
var b:byte; index,i:integer;
begin
b:=0;
index:=1;
if Frame = TIEC101Frame.IEC101FrameLong then
   for i:=0 to Blocklength-1 do
      b:=b+buf[4+i]
else
  for i:=0 to 2 do
     b:=b+buf[1+i];
//log(debug,'CRC:'+inttohex(b,2));
result:=b;
end;

procedure TIEC101Serial.TXData(st:TMemorystream);
var
    data:array[0..246]of byte; i:integer;
begin
  for i:=0 to Blocklength-3 do
     data[i]:=buf[7+i];
  data[i]:=$FF;

  log(info,'DATA: '+hextostr(data,Blocklength-3));
  inc(rxDatacount);
//  if assigned(fonDataRx) then
//    fonDataRx(self,data,Blocklength-3);
end;

procedure TIEC101Serial.getdata;
var  data:array[0..246]of byte; i:integer;
begin
  for i:=0 to Blocklength-3 do
     data[i]:=buf[7+i];
  data[i]:=$FF;

  log(info,'DATA: '+hextostr(data,Blocklength-3));
  inc(rxDatacount);
//  if assigned(fonDataRx) then
//    fonDataRx(self,data,Blocklength-3);
end;

procedure TIEC101Serial.log(ALevel : TLevel; const AMsg : String);
begin
  if (assigned(Flog)) then
     Flog.log(ALevel,AMsg);
end;

procedure TIEC101Serial.DecodeRX;
var oldfunc101:byte; crc:byte;
begin
 if Frame = TIEC101Frame.IEC101FrameLong then
    log(debug,'RX '+hextoStr(buf,Blocklength+6))
 else
    log(debug,'RX '+hextoStr(buf,Blocklength+3));

 //  trigger an RX indicator
  if assigned(fonRx) then
      fonRx(self,buf,Blocklength+3);

  inc(rxcount);
  crc:=CalcCRC;//(Blocklength);
  if IsLinkNo then
      with currentMember do
      begin
       oldfunc101 := f101;
       decodeControlByte;//(buf[1]);
       log(Debug,'RX_len:'+inttostr(Blocklength)+' CRC=$'+inttoHex(crc,2)+
              ' func:'+inttoStr(f101));
//  if (oldfunc101 <> f101) and assigned(fonFunctionChange) then fonfunctionChange(self, f101);
        doFunction;
      end
  else
    log(warn,'RX wrong LinkAddress');
end;

Function TIEC101Serial.Start:Boolean;
var  tld , tlba:integer;
const
  tr=50; LBAMax=32;
begin
Connect(fport);
if LastError<>0 then
     begin
//      log(error,'LastError:'+inttoStr(LastError)+' '+GetErrorDesc(LastError));
     log(error,'LastError: '+GetErrorDesc(LastError));
     result:=False;
     end
else
  begin
   configIECSerial;
   log(info,'Opened Port: '+inttoStr(dcb.BaudRate));
   Tld:= round((1000 / dcb.BaudRate) + tr);
   Tlba:= round((1000 / dcb.BaudRate) *11 * LBAMax);
   Ft0:= TLD + TLBA;
   if ThreadID=0 then ThreadID:= BeginThread(@run ,self) ;
   if assigned(fonStart) then fonstart(self);
   result:=True;
  end;
end;

procedure TIEC101Serial.terminate;
begin
if ThreadID<>0 then
  begin
   terminated:=true;
   WaitForThreadTerminate(ThreadID,2000) ;
   CloseSocket;
   ThreadID:=0;
  end;
end;

procedure TIEC101Serial.Stop;
begin
terminate;
if assigned(fonStop) then fonstop(self);
end;

{*
procedure TIEC101Serial.Execute;
var index:byte;
begin
 log(info,'Port is Execute')
end;
*}

{  TIEC101Slave }

constructor TIEC101Slave.Create;
begin
 inherited;
  fmember := TIEC101Member.Create(self);
  fmember.linkadr := 1;
  fmember.PRM := False;  // Direction 1= master to slave  0= slave to master
end;

destructor TIEC101Slave.destroy;
begin
  fmember.Destroy;
end;

procedure TIEC101Slave.doFunction;

begin
  if fmember.f101 = 9 then   //ping
    PingRespond(false);
  if fmember.f101 = 0 then   //init
     Confirm(true);
  if fmember.f101 = 11 then   //dataRequest
      DataRespond;
  if fmember.f101 = 3 then //data received
    begin
    getdata;
    Confirm(true);
    end;
end;

procedure  TIEC101Slave.DataRespond8(data:array of Byte);
var index,i:integer;
begin
 fmember.f101:=8;
 fmember.PRM:=false;
 fmember.FCB:=false;
 fmember.FCV:=false;
 Blocklength:=length(data)+3;

 buf[0]:=$68;
 buf[1]:=Blocklength;
 buf[2]:=Blocklength;
 buf[3]:=$68;
 Frame := TIEC101Frame.IEC101FrameLong;  encodecontrolByte;
 encodecontrolByte;
 buf[5]:=fmember.linkadr mod 256; buf[6]:=fmember.linkadr div 256;
 index:=7;
 for i:=0 to high(data) do
   begin
     buf[index]:=data[0+i];
     inc(index);
   end;
 //inc(index);
 buf[index]:=CalcCRC;
// fontx('index= '+inttoStr(index)+' CRC:'+inttohex(buf[index],2));
 inc(index); buf[index]:=$16;
// if assigned(fontx) then fontx(self,data,length(data));
  inc(TXDataCount);
  Send(@buf,index+1);
end;

procedure TIEC101Slave.DataRespond;//(DataAvailable:boolean);
var
 st:TMemorystream;
 data:array of byte;
 i:integer;
begin
  if member.fdata.Count > 0 then
      begin
      st:=TMemorystream (member.fdata[0]);
      setlength(data,st.Size);
      St.Position := 0;
      st.read(data[0],st.Size);
      dataRespond8(data);
      st.Destroy;
      member.fdata.Delete(0);
      end
  else
    begin
    fmember.f101:=9;
    fmember.PRM:=false;
    fmember.FCB:=false;
    fmember.FCV:=false;
    buf[0]:=$10;  encodecontrolByte;
    buf[2]:=fmember.linkadr mod 256;    buf[3]:=fmember.linkadr div 256;  Blocklength:=3;
    buf[4]:=CalcCRC;  buf[5]:=$16;
    Send(@buf,6);
    end;
end;

procedure TIEC101Slave.confirm(Ack:boolean);
var i:integer;
begin
  if ack then fmember.f101:=0
  else fmember.f101:=1;
  fmember.PRM:=false;
  fmember.FCB:=false;
  fmember.FCV:=false;
  buf[0]:=$10;
  Frame := TIEC101Frame.IEC101FrameShort;  encodecontrolByte;
  buf[2]:= fmember.linkadr mod 256;  buf[3]:= fmember.linkadr div 256;  blocklength:=3;
  buf[4]:=CalcCRC;  buf[5]:=$16;
  Send(@buf,6);
end;

procedure TIEC101Slave.Execute;
var index:byte;
begin
 log(info,'Port is running');
 terminated:=false;
 while not terminated do
     begin
        Bytestowait:=4;
        index:=0;
        RecvBuffer(@buf[0],Bytestowait);
        inc(index,Bytestowait);
        ReceiveFT12Frame;
//        if ReceiveFT12Frame then
           begin
            RecvBufferEx(@buf[index] ,Bytestowait, 500);
            DecodeRX;
           end;
        sleep(100);
     end;
 log(info,'Port is closed')
end;

{  TIEC101Master }

constructor TIEC101Master.Create;
begin
 inherited;
 FMemberList:=TList.Create;
 IdleTime:=100;
end;

destructor TIEC101Master.destroy;
begin
 if InstanceActive then
     stop;
 FMemberList.destroy;
end;
  {
procedure TIEC101Master.Stop;
var i:integer;
begin
 for i:=0 to FMemberList.Count-1 do
    TIEC101Member(FMemberList[i]).reset;
 inherited;
end;
 }
procedure TIEC101Master.SendReset;
//procedure TIEC101Master.SendReset(LinkNr:word);
begin
  Frame := TIEC101Frame.IEC101FrameShort;
  with currentmember do
   begin
     f101:=0;
     FCB:=false;
     FCV:=false;
     buf[0]:=$10;
     encodecontrolByte;
     buf[2]:= linkadr mod 256;  buf[3]:=linkadr div 256;
     Blocklength:=3;
     buf[4]:=CalcCRC;  buf[5]:=$16;
     send(@buf,6);
   end;
end;

procedure TIEC101Master.sendData(stream:TMemorystream; WaitConfirm:boolean);
var index,i:integer;
begin
 //      st:=TMemorystream (member.fdata[0]);
 // IF DEBUG
//  currentMember := Member[0];
  //DEBUG
 if currentMember = nil then exit;

 with CurrentMember do begin
     Frame := TIEC101Frame.IEC101FrameLong;
     f101:=3;
     if not WaitConfirm then F101:=4;
     FCB := not FCB;
     FCV:=True;
     if not WaitConfirm then FCV:= False;
     Blocklength:= stream.Size+3;
     buf[0]:=$68;
     buf[1]:=Blocklength;
     buf[2]:=Blocklength;
     buf[3]:=$68;
     encodecontrolByte;
     buf[5]:=linkadr mod 256; buf[6]:=linkadr div 256;
     end;

 index:=7;
 stream.Position:=0;
 stream.ReadBuffer(buf[index],stream.Size);
{ for i:=0 to high(data) do
   begin
     buf[index]:=data[0+i];
     inc(index);
   end; }
 inc(index,stream.Size);
 buf[index]:=CalcCRC;
// fontx('index= '+inttoStr(index)+' CRC:'+inttohex(buf[index],2));
 inc(index); buf[index]:=$16;
// if assigned(fontx) then fontx(self,data,length(data));
  inc(TXDataCount);
  Send(@buf,index+1);
end;

procedure TIEC101Master.Request;
begin
if currentMember<>nil then
  begin
   currentMember.log(Debug,'REQUEST Function: '+inttostr(currentMember.req));
    case currentMember.req of
     10: ReqData(10);
     11: ReqData(11);
    else
      reqLinkStatus;
    end;
  end;
end;

procedure TIEC101Master.ReqLinkStatus;
//  procedure TIEC101Master.ReqLinkStatus(LinkNr:word);
begin
 Frame := TIEC101Frame.IEC101FrameShort;
  with currentmember do
   begin
    f101:=9;
    FCB:=false;
    FCV:=false;
    buf[0]:=$10;
    encodecontrolByte;
    buf[2]:=linkadr mod 256;  buf[3]:= linkadr div 256;
    Blocklength:=3;
    buf[4]:=CalcCRC;  buf[5]:=$16;
    send(@buf,6);
   end;
end;


procedure TIEC101Master.ReqData(dclass:byte);
//  procedure TIEC101Master.ReqData(LinkNr:word;dclass:byte);
begin
Frame := TIEC101Frame.IEC101FrameShort;
with currentmember do
   begin
     f101:=dclass;
     FCB := not FCB;
//  log(info,'FCB:'+booltostr(FCB));
     FCV :=true;
     buf[0]:=$10;
     encodecontrolByte;
     buf[2]:= linkadr mod 256;  buf[3]:= linkadr div 256;
     Blocklength:=3;
     buf[4]:=CalcCRC;  buf[5]:=$16;
     send(@buf,6);
   end;
end;

Function TIEC101Master.addMember(s:String;adr:word;alog:Tlogger):TIEC101Member;
var
  i:integer;
  m: TIEC101Member;
  alist:TStrings;
begin
 m := TIEC101Member.Create(self);
 m.name := s;
 m.PRM:=True;   // Direction 1= master
 m.FCB:=False;
 m.FCV:=False;
 m.linkadr:=adr;
 m.onConnect:=Fonconnect;
 m.onDisConnect:=FonDisconnect;
 m.onDataRx:=FonDataRX;
 FMemberList.Add(m);
 if alog<>nil then
   begin
   m.Logger:= aLog;
   m.Logger.setLevel(TLevelUnit.info);
   alist:=logger.GetAllAppenders;
   for i:= 0 to alist.Count-1 do
      m.Logger.AddAppender(logger.GetAppender(alist[i]));
   end;
 result:=m;
end;

function TIEC101Master.GetMember(Index: Integer): TIEC101Member;
begin
 Result := TIEC101Member(FMemberList[Index]);
end;

function TIEC101Master.GetMember(aname:String): TIEC101Member;
var i:integer;
    m:TIEC101Member;
begin
 Result := nil;
 for i:=0 to FMemberlist.Count-1do
   if TIEC101Member(FMemberlist[i]).name=aname then
     begin
     result:=TIEC101Member(FMemberlist[i]);
     exit;
     end;
end;

//Function  TIEC101Master.GetNextMember:TIEC101Member;
Procedure  TIEC101Master.GetNextMember;
var
  index:integer;
begin
  if FMemberList.Count=0 then
     begin
     if (loopcount mod 10) =0 then
             log(Warn,'No Mebmer Assinged');
     currentMember:=nil;
//     result:=nil;
     exit;
     end;
  if currentMember= nil then
     begin currentMember:=TIEC101Member (FMemberList[0]);
     end
  else
    begin
    index :=FMemberList.IndexOf(currentMember)+1;
    if index= FMemberList.Count then  index:=0;//last member reached
    currentMember:= TIEC101Member(FMemberList[index]);
    end;
end;

procedure  TIEC101Master.doPoll;
begin
 GetNextMember;
 if currentMember<>nil then
    with currentMember do begin
      if alive and (not init) then
         SendReset;
      if alive and init then
         begin
         if HasData then
           SendData(NextData,True)
         else
           Request;
         end;

    if NOT alive then ReqLinkStatus;
    end;
end;

procedure  TIEC101Master.doFrame;
var
 i:integer;
 data : array of byte;
 st:TMemorystream;
begin
 if currentMember=nil then
    begin
    if (loopcount mod 10) =0 then
            log(Warn,'No Mebmer Assinged');
    exit;
    end;
 with currentMember do
  begin
    if (not Alive) and (Rxf101 = 11) then
        begin
        log(debug,'ALIVE');
        Alive:= True;
        end;
    if (not Init)and (Rxf101 = 0) then
        begin
        init:= True;
        log(debug,'INIT');
        end;
  end;
end;

procedure TIEC101Master.Execute;
var i:integer;
begin
 log(info,'Port is running');
 terminated:=false;
// fmember.function101:=255;
 while not terminated do
     begin
//       log(info,'Master Poll');
       doPoll;
       if currentMember <>nil then
          begin
          ReceiveFT12Frame;
          if lastError =sOK then
            begin
            decodeControlByte;
            doFrame;
            end
          else
            begin
            currentMember.log(Debug,getErrordesc(lasterror));
            currentMember.reset;
            end;
          end;
       sleep(idleTime);
       inc(loopcount);
     end;
  for i:=0 to FMemberList.Count-1 do
     TIEC101Member(FMemberList[i]).reset;
  log(info,'Port is closed')
end;

end.

