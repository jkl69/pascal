unit key;

{$mode objfpc}{$H+}

interface

uses
  Classes, windows, SysUtils;

function createPW(s:String):String;
function DecodePW(s:String):String;
function getPWtime(s:String):String;
function DecodePos(s:String):integer;
function EncodePW(s:String):String;
function EncodePW(s:String;var pos :Integer):String;
function getCreatedate(FileName : string):Tdatetime;
function CreatedateHexstr(s:String):String;
Function hex2double (theHex: String): Double;

function checkPW(hex,fname:String):boolean;

implementation

uses  strutils;

Type
  TDoubleAndBytes = Record
    case byte of
      0 : (dabDouble : Double);
      1 : (dabBytes : Array [0..7] Of Byte);
      2 : (dabInt64 : Int64);
  end;

function GetPCName: string;
var
  buffer: array[0..MAX_COMPUTERNAME_LENGTH + 1] of Char;
  Size: Cardinal;
begin
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  Windows.GetComputerName(@buffer, Size);
  Result := StrPas(buffer);
end;

function getCreatedate(FileName : string):Tdatetime;
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
  STime : TSystemTime;

begin
fileHandle := CreateFile(PChar(fileName), GENERIC_READ, FILE_SHARE_READ, nil,OPEN_EXISTING, 0, 0);
if fileHandle <> INVALID_HANDLE_VALUE then
   try
    GetFileTime(fileHandle, @fsCreationTime, @fsLastAccessTime,@fsLastModificationTime);
    if DSiFileTimeToDateTime(fsCreationTime, created) then
//     result:=Datetimetostr(Created);
     getCreatedate:=(Created);
   finally
     CloseHandle(fileHandle);
  end;
end;

//Function hex2Long (theHex: String): longint;
Function hex2double (theHex: String): Double;
var
  int:integer;
  R : array[0..7] of byte;
  my:TDoubleAndBytes;

begin
int:=Hextobin(pchar(theHex),pchar(@r[0]),8);
for int:=7 downto 0 do
   my.dabBytes[7-int]:=r[int];
//my.dabBytes[0]:=30; my.dabBytes[1]:=21; my.dabBytes[2]:=176; my.dabBytes[3]:=139;
//my.dabBytes[4]:=81; my.dabBytes[5]:=56; my.dabBytes[6]:=228; my.dabBytes[7]:=64;
  hex2double:=my.dabDouble;
end;

//function HexToBin(HexValue: PChar;BinValue: PChar;BinBufSize: Integer):Integer;

function CreatedateHexstr(s:String):String;
var
  t:Tdatetime;
  i:Int64;
begin
  t:= getcreatedate(s);
  i:=Int64(t);
  CreatedateHexstr:= hexstr(i,16);
end;

function createPW(s:String):String;
begin
createPW:='';
if not FileExists(s) then
   exit;
createPW:=s+'@'+GetPCName;
end;

function EncodePW(s:String):String;
var
  pos:integer;
begin
  EncodePW:=EncodePW(s,pos);
end;

{function checkPW(hex,fname:string):boolean;
var
  p:integer;
  fname:String  ;
begin
  fname:=DecodePW(hex);
  p:=pos('@',fname);
  pcname:=copy(fname,p+1,length(fname)-p);
  if  pcname<>getPCName then
     exit;
  fname:=copy(fname,1,p-1);
end;
}
function checkPW(hex,fname:String):boolean;
var
  p:integer;
  pcname,pwfname,hext:String;
begin
  checkPW:=false;
  pwfname:=DecodePW(hex);
  p:=pos('@',pwfname);
  pcname:=copy(pwfname,p+1,length(pwfname)-p);
//  if  pcname<>getPCName then
//     exit;
  pwfname:=copy(pwfname,1,p-1);
  if  fname<>pwfname then
     exit;
  hext:=CreatedateHexstr(pwfname);
  if hext<> getpwTime(hex) then
    exit;
  checkPW:=true;
end;

Function hex2Long (theHex: String): Int64;
var
 barray : array[0..7] of byte;
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

function DecodePos(s:String):integer;
//var
//  t:String;
begin
// t:=copy(s,length(s)-1,2) ;
  DecodePos:=hex2Long(copy(s,length(s)-1,2));
  if DecodePos >=(length(s)-16) then
     DecodePos:=0;
//  DecodePos:=hex2Long(t);
end;

Function HexToStr(s: String): String;
Var i: Integer;
Begin
  Result:=''; i:=1;
  While i<Length(s) Do Begin
    Result:=Result+Chr(StrToIntDef('$'+Copy(s,i,2),0));
    Inc(i,2);
  End;
End;

function getPWtime(s:String):String;
var
  pos,d:integer;
begin
  pos:=DecodePos(s)*2;
  getPWtime:=copy(s,pos+1,16);
end;

function DecodePW(s:String):String;
var
  pos,d:integer;
  txt:String;
begin
  pos:=DecodePos(s)*2;
  txt:=copy(s,1,pos);
  DecodePW:=HexToStr(txt);
  txt:=copy(s,pos+17,length(s)-17-pos);
  DecodePW:=DecodePW +HexToStr(txt);
end;

function EncodePW(s:String;var pos:integer):String;
var
 i:integer;
 hextime,sl:String ;
 dt:Tdatetime;
begin
  EncodePW:=createPW(s);
  pos:=Random(length(EncodePW));
  if EncodePW='' then
     exit;
  sl:='';
//  hextime:=CreatedateHexstr(s);
  for i:=0 to length(EncodePW)-1 do
      begin
        if i=pos then
           sl:=sl+CreatedateHexstr(s);
        sl:=sl+hexstr(word(EncodePW[i+1]),2);
      end;
  EncodePW:=sl+hexstr(pos,2);
//  DecodePW:=sl+'_'+hextime;
end;

end.

