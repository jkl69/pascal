program IECItemTest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes ,sysutils ,IECMap, IECStream
  { you can add units after this };
var
  st:TIECStream;
  bu: array of byte;
  b:byte; i,x:integer;
  bol:boolean;
  ityp:iec_Stype;
  it:TiecItem;
  iecItems:TiecItems;
  txt:string;
  qs:iecquset;
  qq:iecqu;

procedure WriteSingle(d:single);
var c:cardinal absolute d;
begin
  st.WriteDWord(c);
end;

function ReadSingle:single;
var c:cardinal;
  d: single absolute c;
begin
  c:=st.ReadDWord;
  result:=d;
end;

begin
 setlength(bu,4);
 bu[0]:=32;
 bu[1]:=33;
 bu[2]:=34;
 bu[3]:=0;

 st:=  TIECStream.Create();
// st.Write(bu[0],length(bu));
//st.WriteAnsiString('test');
 //st.WriteAnsiString('12345');
 st.WriteTime(now,true);

 writeln('size'+inttostr(st.Size));

 st.Position:=0;
 for i:=0 to st.Size-1 do
    writeln(inttohex(st.Bytes[i],2));
st.Position:=0;
writeln(DatetimetoStr(st.ReadTime(bol)));
writeln('DST:'+booltostr(bol));

 st.Position:=0;  st.WriteByte($f0);
//  st.Position:=0; st.WriteByteBool(3,true);
 st.Position:=0;
  writeln('$byte '+inttohex(st.ReadByte,2));
  st.Position:=0;
 WriteSingle(5.5);

 st.Position:=0;
// b:= st.ReadByte;
 for i:=0 to 3 do
   writeln(inttohex(st.Bytes[i],2));
// writeln(inttostr(st.Bytes[1]));
   st.Position:=0;
   writeln('single:'+floattostr(readsingle));


//   it:=TiecItem.create(IEC_SType.M_ME_NA,100,8193);
   it:=TiecItem.create(IEC_SType.M_SP_NA,101,66100);
   it.value:=3; it.QU:=[IECQU.BL,IECQU.NT];  qs:=it.qu;
   writeln(it.toString);

   writeln(it.ToHexStr);

   writeln('changeTyp:');
   it.IECTyp:=IEC_SType.M_IT_TB;
   it.Value:=67890;
   it.QU:=[IECqu.CA];
   writeln(it.toString);

   writeln(it.ToHexStr);


   txt:='';
   it:=TiecItem.create(IEC_SType.M_ME_NA,100,8193);
   it.value:=100;
   it.QU:=[IECQU.IV];
   writeln(it.toString);
   writeln(it.ToHexStr);

   txt:='';

   it:=TiecItem.create(IEC_SType.M_DP_NA,101,4100);
   it.value:=2;
   it.QU:=[IECQU.iv];
   qs:=it.qu;
   writeln(it.toString);
   writeln(it.ToHexStr);

writeln('Create Item from Stream test');writeln('');
iecitems:=   CreteItems([$f4,$01,$03,$56]);
//CreteItems([$01,02,03,00,100,0,01,$10,0,1,02,10,0,0]);
//iecItems:= CreteItems([$09,02,03,00,101,0,01,$20,0,5,1,0,2,$20,0,10,0,0]);
//iecItems:= CreteItems([$09,03,03,00,101,0,01,$20,0,5,1,0,5,$20,0,10,0,0,5,$30,1,55,55,$80]);
//iecItems:= CreteItems([$09, $83, 03,00,  101,0,  01,$20,0,  5,1,0,  10,0,0,  55,55,$80]);
//iecItems:= CreteItems([$01, $03, 03,00,  1,1,  01,$10,0,1,  5,16,0,0,  10,10,0,1]);
iecItems:= CreteItems([$01, $03, 03,00,  1,1,  01,16,0,1,  12,16,0,1,  42,16,0,1]);
writeln('Created Items count: '+inttoStr(length(iecitems)));
ityp:= getSType(iecItems[0].Bytes[0]);
if ityp <> IEC_SType.IEC_NULL_TYPE then
   begin
   for i:=0 to high(iecitems) do
    begin
      it:=TiecItem ( iecitems[i]);
      writeln(it.ToHexStr);
      writeln(it.toString);
    end;
   end
else
  writeln('Unkwon Type: '+iecItems[0].ToHexStr);

 writeln('');
{*
iecitems := CreteItems([$09,01,03,00,101,0,01,$20,0,5,1,0]);
writeln('Created Items count: '+inttoStr(length(iecitems)));
ityp:= getSType(iecItems[0].Bytes[0]);
if ityp <> IEC_SType.IEC_NULL_TYPE then
   begin
   for i:=0 to high(iecitems) do
    begin
      it:=TiecItem ( iecitems[i]);
      writeln(it.ToHexStr);
      writeln(it.toString);
    end;
   end
else
  writeln('Unkwon Type: '+iecItems[0].ToHexStr);
*}
 readln;

end.

