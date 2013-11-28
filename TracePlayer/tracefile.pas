unit Tracefile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  timetest;


function openfile:TStringlist;
function getPlainhex(sl:TStrings):TStringlist;
function getFinal(sl:TStrings):TStringlist;

implementation

uses main, simplelog, Dialogs;

function isTraceLine(txt:string):boolean;
    begin
       isTraceLine  := (pos('| $ ',txt) > 0)
    end;


function isTraceContinue(txt:string):boolean;
begin
   isTraceContinue  := (pos('$   ',txt) > 0)
end;

function getHexStream(txt:string):String;
begin
  getHexStream := copy(txt,LastDelimiter('|',txt)+1,length(txt));
end;

// time format 2013-11-11 12:32:53,985

function getTimeStr(s:string):String;
begin
  getTimeStr := copy(s,pos(':',s)-2,12);
end;

function getDateTimeStr(txt:string):String;
begin
  getDateTimeStr := copy(txt,pos('| $ ',txt)+4,23);
end;

function openfile:TStringlist;
Var traceFile : TextFile;
    linetext : String;
    line : Integer;
    opendialog : TopenDialog;
    lines: TStringlist;

begin
   opendialog := TopenDialog.Create(nil);
   if opendialog.Execute then
      begin
//      openfile := getfile(opendialog.FileName);
     lines:= TStringlist.Create;
     AssignFile(traceFile,opendialog.FileName);
     Reset(traceFile); {'Reset(x)' - means open the file x}
     line:=1;
     Repeat
      Readln(traceFile,linetext);
      if isTraceLine(linetext) then
           begin
//           s:= gettimeStr(linetext) ;
           lines.Append(inttoStr(line)+'_ '+linetext) ;
           end;
        inc(line);
     Until Eof(traceFile);
     CloseFile(traceFile);
     openfile := lines;
     end;
   opendialog.free;
end;

function getLineNumber(txt:string):String ;
begin
   getLineNumber := copy(txt,1,pos('_',txt));
end;

function getFinal(sl:TStrings):TStringlist;
var
    linestr,timestr,timestr_old,hexstr : String;
    lines: TStringlist;
    count,x:integer;
    msec :integer =-1;
begin
     count:=  sl.Count;
     lines:= TStringlist.Create;
     x:=0;
     timestr:='';
     timestr_old:='';
  repeat
     timestr_old :=timestr;
     linestr := sl[x];
     timestr := sl[x+1];
     hexstr := copy(sl[x+2],5,length(sl[x+2]));
     if (x > 0) then
          begin
          msec :=timediff(timestr_old,timestr);
          log.info('calc time '+timestr+'-'+timestr_old+' = '+inttostr(msec));
          lines.Append(inttostr(msec));
          end;
     lines.Append(hexstr);
     inc(x,3);
  until x >= count-1;

    getFinal := lines;
end;

function getPlainhex(sl:TStrings):TStringlist;
var
  x,count: integer;
  linetext : String;
  hexstream,hexstream2 :String;
  lines: TStringlist;
  tmpStr :String = '';
  newline : boolean= true;

begin
  count:=  sl.Count;
  log.info('Lines count '+inttostr(Count));
  lines:= TStringlist.Create;
  for x:=0 to count-1 do
    begin
    linetext := sl[x];
    hexstream2 := hexstream;
    if isTraceContinue(linetext) then
        begin
          log.info('Trace Continue '+linetext);
          tmpStr := tmpStr +getHexStream(linetext);
          newline := false;
        end
    else begin
          log.info(linetext);
           hexstream := getHexStream(linetext);
           newline := true;
         end;

    if (newline) then
         begin
           if (tmpStr = '') then
               begin
               lines.Append(getLineNumber(linetext)) ;
               lines.Append(gettimeStr(linetext)) ;
               lines.Append(HexStream) ;
                end
           else
               begin
               lines.Append(getLineNumber(linetext));
               lines.Append(gettimeStr(linetext));
               lines.Append(HexStream2+tmpStr);
               tmpStr := '';
               end;
          end;

    end;
  getPlainhex := lines;
end;

Initialization
//  Log:= TLog.create;

Finalization
//  log.Free;

end.

