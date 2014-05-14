unit CLITimer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  TLevelUnit,tree,
  CLI, IECGWTimer;

function exec(R:TIECGWTimer;c:TCLI):TcliReturn;

implementation

var
  timer:TIECGWTimer;
  cmd:TCLI;

const
  action : Array [0..3] of String = ('list', 'add','set','clear');
  NO_PARAM='missing Parameter';


function timerset:TCLIReturn;
var
  t: TGWTimer;
  i,c : integer;
begin
 result.succsess:=true;
 if length(cmd.child) < 1 then
    begin
     result.succsess:=false;
     result.msg:= 'no Timer given'; exit;
    end;
 t:=timer.getTimer(cmd.child[0]);
 if t<>nil then
    begin
    val(cmd.Params[0],i,c);
    if c<>0 then
       begin result.succsess:=False;result.msg:= 'Invalid Parameter';  exit; End;
    t.intervall := i;result.msg:= 'Timer intervall set to '+cmd.Params[0];
    exit;
    end;
 result.succsess:=false;
 result.msg:= 'Timer not found';
end;

function settimer:TCLIReturn;
 var
   i:integer;
 begin
   Result.succsess:=false;
   if length(cmd.Params)>0 then
     Result:=timerset
   else
     Result.msg:= NO_PARAM;
 end;

function Add:TCLIReturn;
 var
   i:integer;
 begin
   Result.succsess:=false;
   if length(cmd.Params)>0 then
     begin
     for i:=0 to high(cmd.Params) do
        if not timer.add(cmd.Params[i]) then
           begin Result.msg:='Timer already exist'; exit; end;
     Result.succsess:=true;
     Result.msg:='add new Timer';
     end
   else
     Result.msg:= NO_PARAM;
 end;

function list():TCLIReturn;
var
  x,i:integer;
  f,s:String;
  t : TGWTimer;
begin
 f:='=';
 result.succsess:=true;
 result.msg:= 'Timer list entrys:';
 for i:=0 to timer.list.Count-1 do
   begin
   t := TGWTimer(Timer.list.Objects[i]);
   setlength(result.result,length(result.result)+1);
   result.result[i]:=Timer.list[i]+' intervall='+inttoStr(t.intervall);
   end;
 if length(cmd.child)>0 then
      f:= cmd.child[high(cmd.child)];
end;

function help():TCLIReturn;
var
  i:integer;
begin
 result.msg:= 'possible commands are:';
 setlength(result.result,length(action));
 for  i:=0 to high(action) do
     Result.result[i]:=action[i];
end;

function exec(R:TIECGWTimer;c:TCLI):TcliReturn;
begin
 Timer:=r;
 cmd:=c;
// event.log(info,'exec');
 if cmd.action='?' then
    begin  result:=help; exit;  end;
 if cmd.action=action[0] then
    begin result:=list; exit;  end;
 if cmd.action=action[1] then
    begin  result:=add; exit;  end;
 if cmd.action=action[2] then
    begin  result:=settimer; exit;  end;
 if cmd.action=action[3] then
    begin  timer.delList();  result.succsess:=true;
    result.msg:= 'Timer list cleared:'; exit;  end;
 result.succsess:=false;
 result.msg:='command not found';
end;

end.

