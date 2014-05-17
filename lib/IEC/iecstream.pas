unit IECStream;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  IECMAP;

Type
  TIECStream = class(TBytesStream)
    public
     function ToHexStr:string;
     function ToIECBuffer:TIECBUFFER;
     procedure WriteTime(t:Tdatetime;DST:boolean);
     function ReadTime(var DST:boolean):Tdatetime;
//     function ReadTimeStr:String;
     procedure WriteSingle(d:single);
     function ReadSingle:single;
//     procedure RewriteByteMask(mask:byte;b:byte);
//     function ReadByteMask(mask:byte):byte;
     procedure WriteAdr(c:cardinal);
     function ReadAdr:cardinal;
     procedure WriteValue(t:IEC_Stype;value:Double);
     function ReadValue(t:IEC_Stype):Double;
     procedure WriteQU(t:IEC_Stype;qubyte:byte);
     function ReadQU(t:IEC_Stype):Byte;
  end;


 TiecItem = class (TIECStream)
     minValue:Double;
     MaxValue:Double;
     ftime:Tdatetime;  // necsesarry because not all types can store time in stream
     FDST:boolean ;    // necsesarry because not all types can store time in stream
     ReversMode  :Boolean;
     fonChange:TNotifyEvent;
 private
     procedure setType(t:IEC_SType);
     procedure setDefLimits;
     procedure setObjCount(c:byte);
     procedure setCOT(cot:word);
     procedure setASDU(asdu:word);
     procedure setAdr(adr:cardinal);
     procedure setValue(newValue:double);
//     procedure setQU(qu:byte);
     procedure setQU(qu_set:IECQUSet);
     procedure setTime(ti:Tdatetime);
     function getAdr:cardinal;
     function getValue:double;
//     function getQU:byte;
     function getQU:IECQUSet;
     function getTime:tDatetime;
     function getType:IEC_SType;
     function getObjCount:byte;
     function getCOT:word;
     function getASDU:word;
 public
     Name: String;
     constructor create(t:IEC_SType;asdu:word;adr:cardinal);
     function toString:String;
     function getTimeStr:String;
     function getValueStr:String;
//     function getQUStr:String;
     property IECTyp:IEC_SType read getType write setType;
     property ASDU:word read getASDU write setASDU;
     property COT:word read getCOT write setCOT;
     property Adr:Cardinal read getAdr write setAdr;
     property Value:double read getValue write setValue;
     property QU:IECQUSet read getQu write setQU;
     property onChange:TNotifyEvent read fonchange write fonchange;
//     property TimeLength:byte read getTimeLength ;
     property Time:TDateTime read getTime ;
  end;

// TiecItems = array of TiecItem;
 TiecItems = array of TIECStream;

 Function getItemLength(t:IEC_SType):byte;
 function QusettoByte(quset:iecquset):byte;
 function QuSettoStr(quset:iecquset):String;
function ByteToQUSet(item:TIECItem;b:byte):iecquset;
function CreteItems(buffer:array of byte):TiecItems;

Var
   P_SHORT : boolean =false;

implementation

uses dateutils;

function isDST:boolean;begin result:=true;end;
function PosASDU:byte;begin result:=4;end;
function PosAdr:byte;begin result:=PosASDU+2;end;
function PosValue:byte;begin result:=PosAdr+3;end;
function PosQU(t:iec_SType):byte;
begin
 result:=-1;  //unknown QU position
 case (t) of
   M_SP_NA,M_SP_TB :                    result:=PosValue;
   C_SC_NA :                            result:=PosValue;
   M_DP_NA,M_DP_TB :                    result:=PosValue;
   C_DC_NA :                            result:=PosValue;
   M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD :    result:=PosValue+2;
   C_SE_NA,C_SE_NB :                    result:=PosValue+2;
   M_ME_NC,M_ME_TF :                    result:=PosValue+4;
   C_SE_NC:                             result:=PosValue+4;
   M_IT_NA,M_IT_TB:                     result:=PosValue+4;
   end;
end;
function PosTime(t:iec_sType):byte;
 begin
  result:=-1;  //unknown time position
  case (t) of
    M_SP_NA,M_SP_TB :                    result:=PosValue+1;
    C_SC_NA :                            result:=PosValue+1;
    M_DP_NA,M_DP_TB :                    result:=PosValue+1;
    C_DC_NA :                            result:=PosValue+1;
    M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD :    result:=PosValue+3;
    C_SE_NA,C_SE_NB :                    result:=PosValue+3;
    M_ME_NC,M_ME_TF :                    result:=PosValue+5;
    C_SE_NC:                             result:=PosValue+5;
    M_IT_NA,M_IT_TB:                     result:=PosValue+5;
   end;
end;
Function getTimelength(t:IEC_SType):byte;
begin
 case t of
    M_SP_TB ,M_DP_TB, M_ME_TB,
    M_ME_TD,M_ME_TF, M_IT_TB : result:=7;
 else
   result:=0;
 end;
end;
Function getItemLength(t:IEC_SType):byte;
begin
 result:= PosTime(t)+getTimeLength(t);
end;

function QuSettoStr(quset:iecquset):String;
begin
  result:='[';
  if iecqu.IV in quSet then result:=result +'IV|';
  if iecqu.NT in quSet then result:=result +'NT|';
  if iecqu.SB in quSet then result:=result +'SB|';
  if iecqu.BL in quSet then result:=result +'BL|';
  if iecqu.OV in quSet then result:=result +'OV|';
  if iecqu.CA in quSet then result:=result +'CA|';
  if iecqu.CY in quSet then result:=result +'CY';
  result:=result+']';
end;

function QuSettoByte(quset:iecquset):byte;
begin
  result:=0;
  if iecqu.IV in quSet then result:=result or $80;
  if iecqu.NT in quSet then result:=result or $40;
  if iecqu.SB in quSet then result:=result or $20;
  if iecqu.BL in quSet then result:=result or $10;
  if iecqu.OV in quSet then result:=result or $01;
  if iecqu.CA in quSet then result:=result or $40;
  if iecqu.CY in quSet then result:=result or $20;
end;

function ByteToQUSet(item:TIECItem;b:byte):iecquset;
var t:IEC_SType;
begin
  result:=[];
  t:=item.IECTyp;
  if (b and $80) =$80 then result := result + [iecqu.IV];
  if (t <> IEC_SType.M_IT_NA) and (t <> IEC_SType.M_IT_TB) then
    begin
      if (b and $40) =$40 then result := result + [iecqu.NT];
      if (b and $20) =$20 then result := result + [iecqu.SB];
      if (b and $10) =$10 then result := result + [iecqu.BL];
      if (b and $01) =$01 then result := result + [iecqu.OV];
    end
  else
    begin
      if (b and $40) =$40 then result := result + [iecqu.CA];
      if (b and $20) =$20 then result := result + [iecqu.CY];
    end;
end;

function getDef_MAX(t:IEC_SType):double;
begin
  case (t) of
     M_SP_NA,M_SP_TB : result :=1;
     C_SC_NA : result :=1;
     M_DP_NA,M_DP_TB : result :=3;
     C_DC_NA : result :=3;
     M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD : result := High(SmallInt);
     C_SE_NA,C_SE_NB : result := High(SmallInt);
//     M_ME_NC,M_ME_TF,C_SE_NC : result := MaxValue(single);
     M_ME_NC,M_ME_TF,C_SE_NC : result := 1000000000000.0;
     M_IT_NA,M_IT_TB : result := High(Longint);
     C_IC_NA,C_CI_NA : result := 255;
   else
     result:=0;
   end;
end;

function getDef_MIN(t:IEC_SType):double;
begin
   case (t) of
     M_SP_NA,M_SP_TB : result :=0;
     C_SC_NA : result :=0;
     M_DP_NA,M_DP_TB : result :=0;
     C_DC_NA : result :=0;
     M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD : result := Low(SmallInt);
     C_SE_NA,C_SE_NB : result := Low(SmallInt);
//     M_ME_NC,M_ME_TF,C_SE_NC : result := MaxValue(single);
     M_ME_NC,M_ME_TF,C_SE_NC : result := -1000000000000.0;
     M_IT_NA,M_IT_TB : result := Low(Longint);
     C_IC_NA,C_CI_NA : result := 0;
   else
     result:=0;
   end;
end;

function CreteItems(buffer:array of byte):TiecItems;
var stream:TIECStream; ItemCount:byte; Block:boolean;
    t:iec_sType; index:byte; item:TIECItem; i:integer;
    txt:string; asdu:word; adr:Cardinal;
begin
  stream:=TIECStream.Create();
  stream.Write(buffer,length(buffer));
  ItemCount := buffer[1] and $7F;
  Block := (buffer[1] >=128);
  t:= getstype(buffer[0]);
  if t<>IEC_SType.IEC_NULL_TYPE then
    begin
    setlength(result,itemcount);
    index:=6;
    txt:='';
    for i:=0 to stream.Size do   txt:=txt+inttohex(stream.Bytes[i],2)+' ';
//    writeln('Stream: '+txt);
    stream.Position:=4;
    asdu:= stream.ReadWord;
    for i:=0 to ItemCount-1 do
       begin
//       writeln('PosAdr:'+inttostr(Stream.position));
       if (i=0) then
         adr:= stream.ReadAdr;
       if (i>0) and  (block) then
         inc(adr);
       if (i>0) and  (not block) then
         adr:= stream.ReadAdr;
       item:=TIECITem.Create(t,asdu,adr);
//       writeln('PosVal:'+inttostr(Stream.position));
       item.Value:=stream.ReadValue(t);
       if t in [IEC_SType.M_SP_NA, IEC_SType.M_DP_NA,
               IEC_SType.M_SP_TB, IEC_SType.M_DP_TB] then
                stream.seek(-1,TSeekOrigin.soCurrent);
//       writeln('PosQU:'+inttostr(Stream.position));
       item.qu:=ByteToQUSet(item,stream.readqu(t));
//       writeln('PosTime:'+inttostr(Stream.position));
       if getTimelength(t)=7 then  item.setTime(Stream.ReadTime(item.fdst));
//       writeln('rsize:'+inttostr(length(result))+' $Item: '+item.ToHexStr+'   Item: '+item.toString);
       result[i]:=item;
       end;
     stream.Destroy;
    end
  else
    begin
    setlength(result,1);
    result[0]:=stream;
    end;
end;


{ TIECStream }

function TIECStream.ToHexStr:string;
var i:integer;
begin
 for i:=0 to Size-1 do   result:=result+inttohex(Bytes[i],2)+' ';
end;

function TIECStream.ToIECBuffer:TIECBUFFER;
var i:integer;
begin
 setlength(result,size);
 for i:=0 to Size-1 do
    begin
     result[i]:=Bytes[i];
    end;
end;


procedure TIECStream.WriteTime(t:Tdatetime;DST:boolean);
Var
  YY,MM,DD,HH,MIN,SS,MS : word;
begin
//  msec,msec ,min ,hour+dst ,Weekday+day ,mon ,year
  DecodeDateTime(t,YY,MM,DD,HH,MIN,SS,MS);
//  DecodeDate(t,YY,MM,DD);   DecodeTime(t,HH,MIN,SS,MS);
   ms := 1000*SS+MS;
   writeByte(MS mod 256);
   writeByte(MS div 256);
   writeByte(MIN);
   if DST then hh:= hh or $80;
   writeByte(HH);
   writeByte (DD);
   writeByte (MM);
   writeByte (YY-2000);
end;

function TIECStream.ReadTime(var DST:boolean):Tdatetime;
Var
  YY,MM,DD,HH,MIN,SS,MS : word;
begin
//  Writeln('TIMEPOS:'+inttostr(position));
  ms :=ReadByte +readByte*256;
  ss := ms div 1000;
  ms := ms mod 1000;
  MIN := readByte;
  HH := readByte;
  DST := boolean (HH and $80);
  HH := HH and $7F;
  DD := readByte and $1F;
  MM :=  readByte ;
  YY :=  readByte +2000;
  result := EncodeDateTime(YY,MM,DD,HH,MIN,ss,ms);
end;

procedure TIECStream.WriteAdr(c:cardinal);
var b :array[0..3]of byte absolute c;
begin
 WriteByte(b[0]);
 WriteByte(b[1]);
 WriteByte(b[2]);
end;

function TIECStream.ReadAdr:cardinal;
var c:cardinal;
  b :array[0..3]of byte absolute c;
begin
 b[0]:=ReadByte;
 b[1]:=ReadByte;
 b[2]:=ReadByte;
 b[3]:=0;
 result:=c;
end;


procedure TIECStream.WriteSingle(d:single);
var c:cardinal absolute d;
begin
  WriteDWord(c);
end;

function TIECStream.ReadSingle:single;
var c:cardinal;
  d: single absolute c;
begin
  c:=ReadDWord;
  result:=d;
end;

procedure TIECStream.WriteValue(t:IEC_Stype;value:Double);
var oldByte:byte;
begin
 //M_MSP.. do first read before write so extent Stream if this if first time
 if (size < position+1) then
   begin WriteByte(0);position:=position-1; end;

 case (t) of
  M_SP_NA,M_SP_TB :  begin oldByte:= ReadByte and $FE; //read Qu part of byte
                        position:=position-1; //seek(-1,TSeekOrigin.soCurrent);
                        if value>1 then value:=1;
                        writeByte(oldByte + Round(value));  end;
  C_SC_NA :          begin oldByte:= ReadByte and $FE; //read Qu part of byte
                        position:=position-1; //seek(-1,TSeekOrigin.soCurrent);
                        if value>1 then value:=1;
                        writeByte(oldByte + Round(value));  end;
  M_DP_NA,M_DP_TB :  begin oldByte:= ReadByte and $FC; //read Qu part of byte
                        position:=position-1; //seek(-1,TSeekOrigin.soCurrent);
                        if value>3 then value:=3;
                        writeByte(oldByte + Round(value));  end;
  C_DC_NA :          begin oldByte:= ReadByte and $FC; //read Qu part of byte
                         position:=position-1; //seek(-1,TSeekOrigin.soCurrent);
                         if value>3 then value:=3;
                         writeByte(oldByte + Round(value));  end;
  M_ME_NA,M_ME_TB,
  M_ME_NB,M_ME_TD :  writeWord(round(Value));
  C_SE_NA,C_SE_NB :  writeWord(round(Value));
  M_ME_NC,M_ME_TF :  writeSingle(Value);
  C_SE_NC:           writeSingle(Value);
  M_IT_NA,M_IT_TB:   WriteDword(round(Value));
  C_IC_NA:           writeByte(round(Value));
  end;
end;

function TIECStream.ReadValue(t:IEC_Stype):Double;
begin
  case (t) of
     M_SP_NA,M_SP_TB :        result := ReadByte and $01;
     C_SC_NA :                result := ReadByte and $01;
     M_DP_NA,M_DP_TB :        result := ReadByte and $03;
     C_DC_NA :                result := ReadByte and $03;
     M_ME_NA,M_ME_TB,
     M_ME_NB,M_ME_TD :        result := readWord;
     C_SE_NA,C_SE_NB :        result := readWord;
     M_ME_NC,M_ME_TF :        result := ReadSingle;
     C_SE_NC:                 result := ReadSingle;
     M_IT_NA,M_IT_TB:         result := ReadDword;
     C_IC_NA:                 result := ReadByte;
   end;
end;


procedure TIECStream.WriteQU(t:IEC_Stype;qubyte:byte);
var oldByte,valByte:byte;
begin
 //M_MSP.. do first read before write so extent Stream if this if first time
 if (size < position+1) then
   begin WriteByte(0);position:=position-1; end;

 case (t) of
   M_SP_NA,M_SP_TB :  begin oldByte:= ReadByte and $01; //read Qu part of byte
                         position:=position-1; //seek(-1,TSeekOrigin.soCurrent);
                         valByte := Round(qubyte) and $FE; //
                         writeByte(oldByte or ValByte);  end;
   C_SC_NA :          begin oldByte:= ReadByte and $01; //read Qu part of byte
                         position:=position-1; //seek(-1,TSeekOrigin.soCurrent);
                         valByte := Round(qubyte) and $FE; //
                         writeByte(oldByte or ValByte);  end;
   M_DP_NA,M_DP_TB :  begin oldByte:= ReadByte and $03; //read Qu part of byte
                         position:=position-1; //seek(-1,TSeekOrigin.soCurrent);
                         valByte := Round(qubyte) and $FC; //
                         writeByte(oldByte or ValByte);  end;
   C_DC_NA :          begin oldByte:= ReadByte and $03; //read Qu part of byte
                          position:=position-1; //seek(-1,TSeekOrigin.soCurrent);
                          valByte := Round(qubyte) and $FC; //
                          writeByte(oldByte or valbyte);  end;
  M_ME_NA,M_ME_TB,
  M_ME_NB,M_ME_TD :  writebyte(qubyte);
  C_SE_NA,C_SE_NB :  writebyte(qubyte);
  M_ME_NC,M_ME_TF :  writebyte(qubyte);
  C_SE_NC:           writebyte(qubyte);
  M_IT_NA,M_IT_TB:   writebyte(qubyte);
  C_IC_NA:           writebyte(qubyte);
  end;
end;


function TIECStream.ReadQU(t:IEC_Stype):Byte;
begin
result := 0;
if (size < position+1) then
  exit;
case (t) of
  M_SP_NA,M_SP_TB :  Result:= ReadByte and $FE;//writeBytebool(0,newValue > 0);
  C_SC_NA :          Result:= ReadByte and $FE;//writeBytebool(0,newValue > 0);
  M_DP_NA,M_DP_TB :  Result:= ReadByte and $FC;
  C_DC_NA :          Result:= ReadByte and $FC;
  M_ME_NA,M_ME_TB,
  M_ME_NB,M_ME_TD :  Result:= ReadByte;
  C_SE_NA,C_SE_NB :  Result:= ReadByte;
  M_ME_NC,M_ME_TF :  Result:= ReadByte;
  C_SE_NC:           Result:= ReadByte;
  M_IT_NA,M_IT_TB:   Result:= ReadByte;
  C_IC_NA:           Result:= ReadByte;
  end;
end;

{ TiecItem }

constructor TiecItem.create(t:IEC_SType;asdu:word;adr:cardinal);
begin
  inherited create;
  if (t =IEC_SType.IEC_NULL_TYPE) then t:=IEC_SType.M_SP_NA;
  name:='Item'+inttostr(adr);
  ReversMode := False;
  setType(t);  // does also: setValue(0); setqu([]);
  setObjCount(1);
  setCOT(3); // on"C_" type cot should be 07
  setASDU(asdu);
  setAdr(adr);
//  setValue(0);  setqu([]);
  setTime(now);
  end;

function TiecItem.toString:String;
var txt:String;
begin
//txt:=format('  COT:%d  Val:%f  QU:$%x  Time:%s',[cot,value,quSetToByte(qu),gettimeStr]);
//txt:=format('  COT:%d  Val:%f  QU:%s  Time:%s',[cot,value,quSetToStr(qu),gettimeStr]);
txt:=format('  COT:%d  Val:%s  QU:%s  Time:%s',[cot,getvalueStr,quSetToStr(qu),gettimeStr]);
 result:=IECSEPERATOR+map[iectyp].name+IECSEPERATOR+
         inttoStr(ASDU)+IECSEPERATOR+inttostr(Adr)+txt;
end;

procedure TiecItem.setDefLimits;
begin
 MinValue:=getDEF_min(IECTyp);
 MaxValue:=getDEF_max(IECTyp);
end;

procedure TiecItem.setType(t:IEC_SType);
begin
 size:=getItemLength(T);
 position:=0;
 writebyte(Map[t].TK);
 setDefLimits;
 setValue(0);
 setqu([]);
end;

function TiecItem.getType:IEC_SType;
begin
 position:=0;
 result:= getSType(readbyte);
end;


procedure TiecItem.setObjCount(c:byte);
begin
  position:=1;
  writebyte(c);
end;

function TiecItem.getObjCount:byte;
begin
  position:=1;
  result:= Readbyte;
end;

procedure TiecItem.setCOT(cot:word);
begin
  position:=2;
  writeWord(cot);
end;

function TiecItem.getCOT:word;
begin
  position:=2;
  result:= ReadWord;
end;

procedure TiecItem.setASDU(asdu:word);
begin
  position:=posASDU;
  writeWord(asdu);
end;

function TiecItem.getASDU:word;
begin
  position:=posASDU;
  result := ReadWord;
end;

procedure TiecItem.setAdr(adr:cardinal);
 begin
  position:=posAdr;
  writeAdr(adr);
end;

function TiecItem.getAdr:cardinal;
begin
  position:=posAdr;
  result:= readAdr;
end;

procedure TiecItem.setValue(newValue:double);
var
 oldValue:Double;
 t:IEC_SType;
begin
if NewValue > maxValue then newValue:= MaxValue;
if NewValue < minValue then newValue:= MinValue;
oldValue:=Value;
if (newValue<>oldValue) then
   if posValue <> -1 then
     begin
       t:=IECTyp;
       position:=posValue;
//       writeln('size:'+inttostr(size)+'   Pos:'+inttostr(position)+'    setValue:'+floattoStr(newValue));
       writeValue(t,NewValue);
       setTime(now);
     end;
end;

function TiecItem.getValue:Double;
var t:IEC_SType;
begin
if posValue <> -1 then
  begin
    t:=IECTyp;
    position:=posValue;
//    if position >= size then    //Stream contains no Value  begin writeValue(t,0); result:=0.001; exit; end;
    result := ReadValue(t);
  end;
end;

function TiecItem.getValueStr:String;
var t:IEC_SType;
  function ToBool(v:double):String;
  begin
    result:='0_0';
    if round(v)=1 then result:= 'OFF';
    if round(v)=2 then result:= 'ON';
    if round(v)=3 then result:= '1_1';
  end;
begin
 t:=IECTyp;
 case (t) of
   M_SP_NA,M_SP_TB :        result := ToBool(value+1);
   C_SC_NA :                result := ToBool(value+1);
   M_DP_NA,M_DP_TB :        result := ToBool(value);
   C_DC_NA :                result := ToBool(value);
   M_ME_NA,M_ME_TB,
   M_ME_NB,M_ME_TD :        result := floattoStr(round(value));
   C_SE_NA,C_SE_NB :        result := floattoStr(round(value));
   M_ME_NC,M_ME_TF :        result := floattoStr(value);
   C_SE_NC:                 result := floattoStr(value);
   M_IT_NA,M_IT_TB:         result := floattoStr(round(value));
   C_IC_NA:                 result := floattoStr(round(value));
   else result:=floattoStr(value);
 end;
end;

//procedure TiecItem.setQU(qu:byte);
procedure TiecItem.setQU(qu_set:IECQUSet);
var
 oldQU_set:IECQUSet;  qubyte:byte; t:IEC_SType;
 i:integer;
begin
t:=IECTyp;
//position:=posqu(t);
//if (size < position+1) then   writeQu(t,qubyte);
oldqu_set:=QU;
  if (oldqu_set<>qu_set) then
     begin
       qubyte:=QUSetToByte(QU_Set);
       i := posqu(t);
       position:=posqu(t);
//       writeln('Pos:'+inttostr(i)+'    setQUByte:'+inttostr(qubyte));
       writeQU(t,qubyte);
       setTime(now);
     end;
end;

//function TiecItem.getQUStr:String;begin end;

//function TiecItem.getQU:byte;
function TiecItem.getQU:IECQUSet;
var
 QuByte:byte;t:IEC_SType; index:byte;
begin
 t:=IECTyp;
 index:= posQU(t);
 if (index =-1) then exit;
 position:=posqu(t);
 QUByte:= ReadQu(t);
// writeln('Pos:'+inttostr(index)+'    getQUByte:'+inttostr(qubyte));
 result := byteToQUSet(self,qubyte);
// writeln('getQU:'+inttostr(result));
end;

procedure TiecItem.setTime(ti:Tdatetime);
begin
 if getTimelength(iectyp) >0 then
   begin
   position:=PosTime(IECTyp);
   writetime(ti,isdst)
   end
 else
    begin
     fTime:=ti;
     FDst:=isDST;
    end;
 if assigned(onChange) then onchange(self);
end;

function TiecItem.getTime:tDatetime;
begin
 if getTimelength(IECTyp) >0 then
   begin
    position:=PosTime(IECTyp);
    result :=readTime(fDST);
   end
 else
   result:=fTime;
end;

function TiecItem.getTimeStr:String;
Var
  YY,MM,DD,HH,MIN,SS,MS : word;
  dst:String;
begin
 DecodeTime(Time,HH,MIN,SS,MS);
 dst:='w';
 if (fDST) then dst:='s';
 result := Datetimetostr(time)+','+inttoStr(Ms)+dst;
end;

end.

