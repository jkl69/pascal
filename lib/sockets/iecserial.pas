unit IECSerial;

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
  TRxBufEvent = procedure(Sender: TObject;Buffer: array of byte; Count: Integer) of object;
  TMessageBuffer = procedure(Sender: TObject; v: double) of object;
//  TRxBufEvent = procedure(Sender: TObject; buffer: pointer; Count: Integer) of object;


  TIEC101Frame = (IEC101FrameShort,IEC101FrameLong);

  TIEC101Serial = class(TBlockSerial)
//  TIEC101Serial = class(TThread)
//     fserial :TBlockSerial;
    private
       FLog: TLogger;
       ThreadID:TThreadID;
       fdata:Tlist;
       Fport: String;
       Flinkadr:word;
       Frame: TIEC101Frame;
 //      LinkNo:word;
       Blocklength:byte;
       Bytestowait: byte;
       PRM:Boolean; // Direction 1= master to slave  0= slave to master
       FCB:Boolean;  // master muss jede Nachricht toggeln;
       FCV:Boolean;
       fuction101:byte;
       buf:array[0..255] of byte;

       fonDataRX : TRxBufEvent;// TGetStrProc;
       fonDataTx : TRxBufEvent;
       fonRX : TRxBufEvent;// TGetStrProc;
       fonTX :  TRxBufEvent;
       fonlog :  TGetStrProc;
       fonStart : TnotifyEvent;
       fonStop : TnotifyEvent;
       fonfunctionChange : TSerialFunctionEvent;
//       fonmessagebuffer: TMessageBuffer;

       function CalcCRC:byte;//(count:byte):byte;
       procedure DecodeRX;
       Function IsLinkNo:boolean;
       procedure decodeControlByte;
//       procedure decodeControlByte(b:byte);
       procedure encodeControlByte;
       //Function encodeControlByte:byte;
//       procedure getframe;
       Function getframe:boolean;
      procedure doFunction;
//       procedure log(const txt:String);
       procedure log(ALevel : TLevel; const AMsg : String);
      procedure PingRespond(e5:Boolean);
       procedure getdata;
       procedure confirm(Ack:boolean);
       procedure DataRespond;//(DataAvailable:boolean);
       procedure  DataRespond8(data:array of Byte);
       procedure send(buffer: pointer; length: integer);
       procedure Execute;
    public
      rxcount :cardinal;
      rxDatacount  :cardinal;
      txcount :cardinal;
      txDatacount  :cardinal;
       Terminated:boolean;
//       pause:boolean;
       constructor Create;
       destructor destroy;
//       procedure Config( baud, bits: integer; parity: char; stop: integer;softflow, hardflow: boolean);
       procedure senddata(buffer: array of byte);
       procedure Start;
       procedure Stop;
       function bufferusage:double;
//       procedure send(a:array of byte);
      property Logger:Tlogger read Flog write Flog;
      property  Port:String read Fport write Fport;
      property  LinkAdr:word read Flinkadr write FLinkAdr;
      property  onStart:TnotifyEvent read fonStart write fonStart;
      property  onStop:TnotifyEvent read fonStop write fonStop;
      property  onRx:TRxBufEvent read fonRX write fonRX;
      property  onDataRx:TRxBufEvent read fonDataRX write fonDataRX;
      property  onDataTx:TRxBufEvent read fonDataTX write fonDataTX;
      property  onTx:TRxBufEvent read fonTX write fonTX;
      property  onLog:TGetStrProc read fonlog write fonlog;
      property  onFunctionChange:TSerialFunctionEvent read fonFunctionChange write fonFunctionChange;
//      property  onmessagebuffer:TMessageBuffer read fonmessagebuffer write fonmessagebuffer;
  end;

function hextoStr(b:array of byte;count:integer):String;

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

constructor TIEC101Serial.Create;
begin
  inherited;// create(true);
  Fdata:=Tlist.Create;
  ThreadID := 0;
  FlinkAdr:=1;
  fport:='COM1';
  config(9600, 8, 'E', SB1, False, False);

end;

destructor TIEC101Serial.destroy;
begin
//  fserial.destroy;
  fdata.Destroy;
  inherited;
end;

function TIEC101Serial.Bufferusage:double;
begin
  result :=  fdata.Count / MessageBufferSize;
end;

procedure TIEC101Serial.Start;
begin
Connect(fport);
  if LastError<>0 then
       begin
  //      log(error,'LastError:'+inttoStr(LastError)+' '+GetErrorDesc(LastError));
       log(error,'LastError: '+GetErrorDesc(LastError));
//       result:=False;
     end
  else
    begin
     log(info,'Opened Port: '+inttoStr(dcb.BaudRate));
     if ThreadID=0 then ThreadID:= BeginThread(@run ,self) ;
     if assigned(fonStart) then fonstart(self);
 //    result:=True;
    end;
end;

procedure TIEC101Serial.Stop;
begin
if ThreadID<>0 then
  begin
   terminated:=true;
   WaitForThreadTerminate(ThreadID,2000) ;
   CloseSocket;
   ThreadID:=0;
   if assigned(fonStop) then fonstop(self);
  end;
end;

procedure TIEC101Serial.decodeControlByte;
var  s:String;  b:byte;
begin
  if Frame = TIEC101Frame.IEC101FrameShort then
    b:= buf[1]
  else
    b:= buf[4];

  PRM:= (b and$40)=$40;
  FCB:= (b and$20)=$20;
  FCV:= (b and$10)=$10;
  fuction101:= b and $0f;
end;

//Function TIEC101Serial.encodeControlByte:byte;
procedure TIEC101Serial.encodeControlByte;
var  b:byte;
begin
  b:= fuction101;
  if PRM then b:=b+$40;
  if FCB then b:=b+$20;
  if FCV then b:=b+$10;

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

  result := (flinkAdr=LinkNo);
end;

Function TIEC101Serial.getframe:boolean;
begin
  result:=true;
  if (buf[0]=$68) and (buf[3]=$68) then
     begin
       Frame := TIEC101Frame.IEC101FrameLong;
       Blocklength :=buf[1];
       Bytestowait :=Blocklength+2;
       log(debug,'LongHeader Blocklength:'+inttoStr(Blocklength));
       exit;
     end;
  if buf[0]=$10 then
     begin
       Frame := TIEC101Frame.IEC101FrameShort;
       Blocklength :=3;
       Bytestowait:=2;
       log(debug,'ShortHeaderCRC: $'+inttohex(CalcCRC,2));
       exit;
     end;
  log(error,'HEADER ERROR '+hextostr(buf,3));
  result:=false;
end;

procedure TIEC101Serial.send(buffer: pointer; length: integer);
begin
  if assigned(fontx) then
    fontx(self,buf,length);
 inc(TXcount);
 SendBuffer(@buf,length);
end;

procedure TIEC101Serial.PingRespond(e5:boolean);
var i:integer;
begin
  fuction101:=11;
  PRM:=false;
  FCB:=false;
  FCV:=false;
  buf[0]:=$10;  encodecontrolByte;
  buf[2]:=flinkadr mod 256;  buf[3]:=FlinkAdr div 256;  Blocklength:=3;
  buf[4]:=CalcCRC;  buf[5]:=$16;

 Send(@buf,6);
end;

procedure TIEC101Serial.senddata(buffer:array of byte);
var
 st:TMemorystream;
begin
 st:=TMemorystream.Create;
 st.write(buffer[0],length(buffer));
 fdata.Add(st);

 if assigned(fonDataTx) then  fonDatatx(self,buffer,length(buffer));

// if assigned(fonmessagebuffer) then fonmessagebuffer(self,bufferusage);

 if fdata.Count>MessageBufferSize then
    begin
     log(fatal,'buffer overflow');
    end;
end;

procedure  TIEC101Serial.DataRespond8(data:array of Byte);
var index,i:integer;

begin
 fuction101:=8;
 PRM:=false;
 FCB:=false;
 FCV:=false;
 Blocklength:=length(data)+3;

 buf[0]:=$68;
 buf[1]:=Blocklength;
 buf[2]:=Blocklength;
 buf[3]:=$68;
 Frame := TIEC101Frame.IEC101FrameLong;  encodecontrolByte;
 encodecontrolByte;
 buf[5]:=flinkAdr mod 256; buf[6]:=flinkAdr div 256;
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

procedure TIEC101Serial.DataRespond;//(DataAvailable:boolean);
var
 st:TMemorystream;
 data:array of byte;
 i:integer;
begin
  if fdata.Count > 0 then
      begin
      st:=TMemorystream (fdata[0]);
      setlength(data,st.Size);
      St.Position := 0;
      st.read(data[0],st.Size);
      dataRespond8(data);
      st.Destroy;
      fdata.Delete(0);
      end
  else
    begin
    fuction101:=9;
    PRM:=false;
    FCB:=false;
    FCV:=false;
    buf[0]:=$10;  encodecontrolByte;
    buf[2]:=flinkAdr mod 256;    buf[3]:=flinkAdr div 256;  Blocklength:=3;
    buf[4]:=CalcCRC;  buf[5]:=$16;

    Send(@buf,6);
    end;
end;

procedure TIEC101Serial.confirm(Ack:boolean);
var i:integer;
begin
  if ack then fuction101:=0
  else fuction101:=1;
  PRM:=false;
  FCB:=false;
  FCV:=false;
  buf[0]:=$10;
  Frame := TIEC101Frame.IEC101FrameShort;  encodecontrolByte;
  buf[2]:=flinkAdr mod 256;  buf[3]:=flinkAdr div 256;  blocklength:=3;
  buf[4]:=CalcCRC;  buf[5]:=$16;
  Send(@buf,6);
end;

function TIEC101Serial.CalcCRC:byte;//(count:byte):byte;
var b:byte; index,i:integer;
begin
b:=0;
index:=1;
if Frame = TIEC101Frame.IEC101FrameLong then
   index:=4;

for i:=0 to Blocklength-1 do
//For i:=0 to count-1 do
   b:=b+buf[index+i];
result:=b;
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

procedure TIEC101Serial.doFunction;

begin
  if fuction101 = 9 then   //ping
    PingRespond(false);
  if fuction101 = 0 then   //init
    Confirm(true);
  if fuction101 = 11 then   //dataRequest
      DataRespond;
  if fuction101 = 3 then //data received
    begin
    getdata;
    Confirm(true);
    end;
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
       oldfunc101 := fuction101;
       decodeControlByte;//(buf[1]);
       log(Debug,'RX_len:'+inttostr(Blocklength)+' CRC=$'+inttoHex(crc,2)+
              ' func:'+inttoStr(fuction101));
       if (oldfunc101 <>fuction101) and assigned(fonFunctionChange) then
          fonfunctionChange(self,fuction101);

       doFunction;
      end
  else
    log(warn,'RX wrong LinkAddress');
end;

procedure TIEC101Serial.Execute;
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
        if getframe then
           begin
            RecvBufferEx(@buf[index] ,Bytestowait, 500);
            DecodeRX;
           end;
        sleep(50);
     end;
 log(info,'Port is closed')
end;

end.

