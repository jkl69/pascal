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

//  TIEC101Member = record
  TIEC101Member = class
     fdata:Tlist;
     linkadr:word;
     RXPRM,PRM:Boolean; // Direction 1= master to slave  0= slave to master
     RXFCB,FCB:Boolean;  // master muss jede Nachricht toggeln;
     RXFCV,FCV:Boolean;
     function101:byte;
  public
       constructor Create;
       destructor destroy;
  end;

  TIEC101Serial = class(TBlockSerial)
    private
       FLog: TLogger;
       ThreadID:TThreadID;
       FT0:  Word;
       fms:word;
       Fport: String;
       Bytestowait: byte;
       Frame: TIEC101Frame;
       fmember: TIEC101Member;
 //      LinkNo:word;
//       Flinkadr:word;
       Blocklength:byte;
//       RXPRM,PRM:Boolean; // Direction 1= master to slave  0= slave to master
//       RXFCB,FCB:Boolean;  // master muss jede Nachricht toggeln;
//       RXFCV,FCV:Boolean;
//       function101 : byte;

       buf:array[0..255] of byte;
       fonDataRX : TRxBufEvent;// TGetStrProc;
       fonDataTx : TRxBufEvent;
       fonRX : TRxBufEvent;// TGetStrProc;
       fonTX :  TRxBufEvent;
       fonlog :  TGetStrProc;
       fonStart : TnotifyEvent;
       fonStop : TnotifyEvent;
       fonfunctionChange : TSerialFunctionEvent;
       procedure ConfigIECSerial;
       function CalcCRC:byte;//(count:byte):byte;
       function IsCRC:boolean;
       procedure DecodeRX;
       Function IsLinkNo:boolean;
       procedure decodeControlByte;
       procedure encodeControlByte;
       Function ReceiveFT12Frame(waittime:word):boolean;
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
       parity: char;
       stopbits: integer;
       rxcount :cardinal;
       rxDatacount  :cardinal;
       txcount :cardinal;
       txDatacount  :cardinal;
       Terminated:boolean;
//       pause:boolean;
       constructor Create;
       destructor destroy;
       Function getConfig:TDCB;
       function getConfigStr:String;
       //( baud, bits: integer; parity: char; stop: integer;softflow, hardflow: boolean);
       procedure senddata(buffer: array of byte);
       function bufferusage:double;
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
      property  onDataRx:TRxBufEvent read fonDataRX write fonDataRX;
      property  onDataTx:TRxBufEvent read fonDataTX write fonDataTX;
      property  onTx:TRxBufEvent read fonTX write fonTX;
      property  onLog:TGetStrProc read fonlog write fonlog;
      property  onFunctionChange:TSerialFunctionEvent read fonFunctionChange write fonFunctionChange;
  end;

  TIEC101Master = class(TIEC101Serial)
  private
    SlaveAlive :boolean;
    procedure  doFrame;
    procedure ReqData(dclass:byte);
    procedure ReqLinkStatus;
    procedure SendReset;
//    procedure ReqData(LinkNr:word;dclass:byte);
//    procedure ReqLinkStatus(LinkNr:word);
//    procedure SendReset(LinkNr:word);
  public
      constructor Create;
      procedure Execute; override;
//      property Member[index:integer]:TIEC101Member Read getMember write setmember;
      property  Member:TIEC101Member read fmember write fmember;
  end;

 TIEC101Slave = class(TIEC101Serial)
  private
      procedure confirm(Ack:boolean);
      procedure DataRespond;//(DataAvailable:boolean);
      procedure DataRespond8(data:array of Byte);
      procedure doFunction; override;
  public
     constructor Create;
     procedure Execute; override;
     property  Member:TIEC101Member read fmember write fmember;
   end;

function hextoStr(b:array of byte;count:integer):String;
function parityToChar(p:byte):char;

const
  MessageBufferSize =100;

implementation

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
constructor TIEC101Member.Create;
begin
  fdata:= tlist.Create;
end;

destructor TIEC101Member.destroy;
begin
  fdata.Destroy;
end;

{  TIEC101Serial }

constructor TIEC101Serial.Create;
begin
  inherited;// create(true);
  ThreadID := 0;
  fmember := TIEC101Member.Create;
  fmember.linkadr := 1;
  fport:='COM1';
//  config(9600, 8, 'E', SB1, False, False);
   baud :=9600;
   bits := 8;
   parity:= 'E';
   stopbits := SB1;
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
  fmember.Destroy;
  inherited;
end;

function TIEC101Serial.Bufferusage:double;
begin
  result :=  fmember.fdata.Count / MessageBufferSize;
end;

procedure TIEC101Serial.decodeControlByte;
var  s:String;  b:byte;
begin
  if Frame = TIEC101Frame.IEC101FrameShort then
    b:= buf[1]
  else
    b:= buf[4];

  fmember.RXPRM:= (b and$40)=$40;
  fmember.RXFCB:= (b and$20)=$20;
  fmember.RXFCV:= (b and$10)=$10;
  fmember.function101:= b and $0f;
end;

//Function TIEC101Serial.encodeControlByte:byte;
procedure TIEC101Serial.encodeControlByte;
var  b:byte;
begin
  b:= fmember.function101;
  if fmember.PRM then b:=b+$40;
  if fmember.FCB then b:=b+$20;
  if fmember.FCV then b:=b+$10;

  if Frame = TIEC101Frame.IEC101FrameShort then
    buf[1]:=b
  else
    buf[4]:=b;
//  result:=b;
end;


function TIEC101Serial.IsLinkNo:boolean;
var  linkNo:word;
begin
  if Frame = TIEC101Frame.IEC101FrameShort then
    linkNo:=buf[2]+buf[3]*256
  else
    linkNo:=buf[5]+buf[6]*256;

  result := (fmember.linkadr=LinkNo);
end;


Function TIEC101Serial.ReceiveFT12Frame(waittime:word):boolean;
var txt : String;
begin
  result:=true;
  txt :='HEADER ERROR FirstByte['+hextostr(buf,1)+']' ;
  Frame := TIEC101Frame.IEC101FrameError;
  if (buf[0]=$68) then
     begin
       Frame := TIEC101Frame.IEC101FrameLong;
       RecvBufferEx(@buf[1] ,3, waittime);
       waittime := DateTimeToTimeStamp (Now).Time - waittime;
       Blocklength :=buf[1];
       Bytestowait := Blocklength+2;
       RecvBufferEx(@buf[4] ,Bytestowait, waittime);
       log(debug,'LH_RX '+hextoStr(buf, Blocklength+6));
//       log(debug,'LongHeader Blocklength:'+inttoStr(Blocklength));
     end;
  if buf[0]=$10 then
     begin
       Frame := TIEC101Frame.IEC101FrameShort;
       RecvBufferEx(@buf[1] ,5, waittime);
       Blocklength :=0;
       log(debug,'SH_RX '+hextoStr(buf,6));
     end;
  if Frame <> TIEC101Frame.IEC101FrameError then
    begin
     if isCRC then
       Begin
        decodeControlByte;
        exit;
       End;
     txt :='HEADER ERROR CRC ';
     log(error,TXT);
    end
  else
    begin
      log(error,'HEADER ERROR firstByte['+hextostr(buf,1)+']');
      result:=false;
    end;
end;

procedure TIEC101Serial.send(buffer: pointer; length: integer);
begin
 if assigned(fontx) then
    fontx(self,buf,length);
 inc(TXcount);
 log(debug,'TX: '+HEXTOSTR(buf,length));
 SendBuffer(@buf,length);
end;

procedure TIEC101Serial.PingRespond(e5:boolean);
var i:integer;
begin
  fmember.function101:=11;
  fmember.PRM:=false;
  fmember.FCB:=false;
  fmember.FCV:=false;
  buf[0]:=$10;  encodecontrolByte;
  buf[2]:=fmember.linkadr mod 256;  buf[3]:=fmember.linkadr div 256;  Blocklength:=3;
  buf[4]:=CalcCRC;  buf[5]:=$16;

 Send(@buf,6);
end;

procedure TIEC101Serial.senddata(buffer:array of byte);
var
 st:TMemorystream;
begin
 st:=TMemorystream.Create;
 st.write(buffer[0],length(buffer));
 fmember.fdata.Add(st);

 if assigned(fonDataTx) then  fonDatatx(self,buffer,length(buffer));

// if assigned(fonmessagebuffer) then fonmessagebuffer(self,bufferusage);

 if fmember.fdata.Count>MessageBufferSize then
    begin
     log(fatal,'buffer overflow');
    end;
end;

function TIEC101Serial.IsCRC:boolean;
var c:byte;index:integer;
begin
result:= False;
if Frame = TIEC101Frame.IEC101FrameLong then
   index := 4+Blocklength
else
   index :=4;
c:=buf[index];
//log(debug,intTostr(index)+'CRC_:'+intTostr(c));
if c=CalcCRC then
   result:=true;
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
//log(debug,'['+intTostr(i)+']
log(debug,'CRC:'+inttohex(b,2));
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
  if assigned(fonDataRx) then
    fonDataRx(self,data,Blocklength-3);
end;

procedure TIEC101Serial.getdata;
var  data:array[0..246]of byte; i:integer;
begin
  for i:=0 to Blocklength-3 do
     data[i]:=buf[7+i];
  data[i]:=$FF;

  log(info,'DATA: '+hextostr(data,Blocklength-3));
  inc(rxDatacount);
  if assigned(fonDataRx) then
    fonDataRx(self,data,Blocklength-3);
end;

procedure TIEC101Serial.log(ALevel : TLevel; const AMsg : String);
//var s:String;
begin
  if (assigned(Flog)) then
     begin
//     s:=+AMsg;
     Flog.log(ALevel,AMsg);
     end;
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
      begin
       oldfunc101 := fmember.function101;
       decodeControlByte;//(buf[1]);
       log(Debug,'RX_len:'+inttostr(Blocklength)+' CRC=$'+inttoHex(crc,2)+
              ' func:'+inttoStr(fmember.function101));
       if (oldfunc101 <> fmember.function101) and assigned(fonFunctionChange) then
          fonfunctionChange(self, fmember.function101);

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
   fmember.Fdata:=Tlist.Create;
   fmember.PRM := False;  // Direction 1= master to slave  0= slave to master
end;

procedure TIEC101Slave.doFunction;

begin
  if fmember.function101 = 9 then   //ping
    PingRespond(false);
  if fmember.function101 = 0 then   //init
     Confirm(true);
  if fmember.function101 = 11 then   //dataRequest
      DataRespond;
  if fmember.function101 = 3 then //data received
    begin
    getdata;
    Confirm(true);
    end;
end;

procedure  TIEC101Slave.DataRespond8(data:array of Byte);
var index,i:integer;
begin
 fmember.function101:=8;
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
    fmember.function101:=9;
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
  if ack then fmember.function101:=0
  else fmember.function101:=1;
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
        if ReceiveFT12Frame(FT0) then
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
 fmember.PRM := True;  // Direction 1= master to slave  0= slave to master
end;

procedure TIEC101Master.SendReset;
//procedure TIEC101Master.SendReset(LinkNr:word);
begin
  Frame := TIEC101Frame.IEC101FrameShort;
  fmember.function101:=0;
  fmember.FCB:=false;
  fmember.FCV:=false;
  buf[0]:=$10;
  encodecontrolByte;
  buf[2]:= fmember.linkadr mod 256;  buf[3]:=fmember.linkadr div 256;
  Blocklength:=3;
  buf[4]:=CalcCRC;  buf[5]:=$16;
  send(@buf,6);
end;

procedure TIEC101Master.ReqLinkStatus;
//  procedure TIEC101Master.ReqLinkStatus(LinkNr:word);
begin
  Frame := TIEC101Frame.IEC101FrameShort;
  fmember.function101:=9;
  fmember.FCB:=false;
  fmember.FCV:=false;
  buf[0]:=$10;
  encodecontrolByte;
  buf[2]:=fmember.linkadr mod 256;  buf[3]:=fmember.linkadr div 256;
  Blocklength:=3;
  buf[4]:=CalcCRC;  buf[5]:=$16;
  send(@buf,6);
end;

procedure TIEC101Master.ReqData(dclass:byte);
//  procedure TIEC101Master.ReqData(LinkNr:word;dclass:byte);
begin
  Frame := TIEC101Frame.IEC101FrameShort;
  fmember.function101:=dclass;
  fmember.FCB := not fmember.FCB;
//  log(info,'FCB:'+booltostr(FCB));
  fmember.FCV :=true;
  buf[0]:=$10;
  encodecontrolByte;
  buf[2]:=fmember.linkadr mod 256;  buf[3]:=fmember.linkadr div 256;
  Blocklength:=3;
  buf[4]:=CalcCRC;  buf[5]:=$16;
  send(@buf,6);
end;

procedure  TIEC101Master.doFrame;
var
 i:integer;
 data : array of byte;
 st:TMemorystream;
begin
  if Frame= TIEC101Frame.IEC101FrameLong then
     begin
     setlength(data,Blocklength-3);
     for i:=0 to Blocklength-4 do
         data[i]:=buf[7+i];
//     log(info,'RX_DATA: '+hextoStr(data,length(data)));
     if assigned(onDataRX) then
        onDataRx(self,data,length(data));
     ReqData(10);
     end;

  if fmember.function101 = 255 then
     begin
     slaveAlive:=false;
     log(info,'Request Link Status'); ReqLinkStatus;
     end;

  if fmember.function101 = 0 then
     begin
      log(debug,'slave ACK');
      SlaveAlive:= True;
      ReqLinkStatus;
      exit;
     end;
  if fmember.function101 = 1 then
     begin
     log(debug,'slave NACK');
     fmember.function101 :=255;
     end;

  if fmember.function101 = 11 then
     begin log(info,'slave Link OK');
      if not SlaveAlive then
         SendReset;
      if SlaveAlive then
         ReqData(10);
     end;

  if fmember.function101 = 9 then
      if SlaveAlive then
         begin
          log(Debug,'slaveData NACK');
          if Fmember.fdata.Count>0 then
             begin
              st := TMemoryStream (fmember.fdata[0]);
              TXData(st);
             end
          else ReqData(10);
         end;
end;

procedure TIEC101Master.Execute;
var index:byte;
    TS : TTimeStamp;
begin
 log(info,'Port is running');
 terminated:=false;
 fmember.function101:=255;
 while not terminated do
     begin
//       log(info,'Master Poll');
       doFrame;
       //       ReqLinkStatus(100);
       TS := DateTimeToTimeStamp(Now);
       Bytestowait:=1; //wait only for 1 byte ( $10 or $68)
       RecvBufferEx(@buf[0] ,Bytestowait, FT0);
       Fms := DateTimeToTimeStamp (Now).Time -ts.Time;
       if LastError<>0 then
          begin
           log(error,'LastError:'+GetErrorDesc(LastError));
           fmember.function101:=255;
           log(info,'Slave Disconnect:');
          end
       else
         begin
         log(debug,'Receive first Byte after:'+inttostr(fms)+
            '/'+intTostr(fT0)+' msec left:'+inttostr(Ft0-fms));
         ReceiveFT12Frame(Ft0-Fms);
         end;
       sleep(100);
     end;
 log(info,'Port is closed')
end;

end.

