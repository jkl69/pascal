unit CLI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  TLoggerUnit, TLevelUnit,
  fpjson, jsonparser,
  IECTree, IECGWEvent, IEC104Server, IEC101Serial,
  IEC104Clientlist, session;

type
  TEventArray= array of String;

  TCLI=record
     Params:array of String;
     Path:array of String;
  end;


var
  IiecTree:TIECTree;  IClients:TIEC104Clientlist;  Iserver:TIEC104Server;
  IMaster:TIEC101Master;  Ievent :TIECGWEvent;

procedure addProcess(o:TObject;Ahint:String);
//procedure addProcess(o:TObject);
procedure execCLI(asession:Tsession; txt:String);
function Parse(cmd:String):Tcli;
function setlevel(log:TLogger;level:String):boolean;
function getKey(s:String):String;
function getVal(s:String):String;
function BoolasStr(val:Boolean):String;

implementation

uses
  CLIItems, CLIserver, CLIClient, CLIMaster, CLIEvent;

var
    Process : Array of String;
    Hint :    Array of String;

procedure help(asession:Tsession);
var
 i:integer;
begin
asession.writeResult('commands are');
for i:=0 to high(process) do
//   asession.writeResult('   '+process[i]);
   asession.writeResult('   '+process[i]+#9+'- '+hint[i]);
asession.writeResult('   x'+#9+'-EXIT Application');
end;

function BoolasStr(val:Boolean):String;
begin
result:= 'FALSE';
if val then result:='TRUE';
end;

function setlevel(log:TLogger;level:String):boolean;
begin
result:=false;
if log=nil then exit;
if (TLevelUnit.tolevel(level)<>nil) then
    begin
    log.SetLevel(TLevelUnit.tolevel(level));
    result:=true;
    end;
end;

function execJson(asession:Tsession;jdata : TJSONData):boolean;
  var
    cmd:String;
    jo : TJSONObject;
  begin
  Jo :=TJSONObject(jdata);
  cmd:=jo.Strings['cmd'];
//  logger.info('cmd:'+cmd);
  if pos('item',cmd)<>0 then
     begin
//     logger.info('doItem');
     CLIItems.execJS(asession,Jo);
     end;
  exit;
  end;

function StrtoJSON(json:String):TJSONData;
var
  parser:TJSONParser;
begin
Result:=nil;
parser:=TJSONParser.Create(json);
Try
   result:=parser.Parse;
   If Assigned(result) then
      writeln('JSON '+result.AsJSON)
   else
     writeln('NO JSON TO PARSE');
 except
      On E : Exception do
      writeln('ERROR on JSON Parse'+e.Message);
  end;
 freeandnil(parser);
end;

function readJsonFile(f:String):String;
var
 File1: TextFile;
 Str: String;
begin
AssignFile(File1, f);
{$I+}
try
  Reset(File1);
  repeat
    Readln(File1, Str); // Reads the whole line from the file
    result:=result+Str;
  until(EOF(File1)); // EOF(End Of File) The the program will keep reading new lines until there is none.
  CloseFile(File1);
except
  on E: EInOutError do
  begin
   Writeln('File handling error occurred. Details: '+E.ClassName+'/'+E.Message);
  end;
end;
end;

procedure execCLI(asession:Tsession; txt:String);
var
 i:integer;
 cmd:string;
 ucli:Tcli;
begin
//writeln('session:'+asession.name);
//cmd:=asession.path+txt;
if txt<>'' then
   begin
    if (txt='item')then txt:=txt+'.';
    if (pos('item.',txt)=1) and (iIecTree<>nil)then
       begin
       txt:=copy(txt,6,length(txt));
       CLIItems.execCLI(asession,txt);  exit;
       end;

    if (txt='server') then txt:=txt+'.';
    if (pos('server.',txt)=1)and (iserver<>nil) then
       begin
       txt:=copy(txt,8,length(txt));
       CLIServer.execCLI(asession,txt);  exit;
       end;

   if (txt='client') then txt:=txt+'.';
   if (pos('client.',txt)=1)and (IClients<>nil) then
       begin
       txt:=copy(txt,8,length(txt));
       CLIClient.execCLI(asession,txt);  exit;
       end;

    if (txt='master') then txt:=txt+'.';
    if (pos('master.',txt)=1)and (imaster<>nil) then
       begin
       txt:=copy(txt,8,length(txt));
       CLIMaster.execCLI(asession,txt);  exit;
       end;

    if (txt='event') then txt:=txt+'.';
    if (pos('event.',txt)=1)and (ievent<>nil) then
      begin
      txt:=copy(txt,7,length(txt));
      CLIEvent.execCLI(asession,txt);  exit;
      end;

 ucli:=parse(txt);
 cmd:=ucli.Params[0];
 if (cmd='') then  exit;
 if (cmd='?')then  begin help(asession);  exit;  end;
 if (cmd='x')and(asession.path='')then begin  asession.terminate; exit;  end;
 if (cmd='J')then
      begin
      execJson(asession,StrtoJSON(readJSONFile('d:\source\pascal\FER\j2.json')));
      exit;
      end;
 end;

 if cmd<>'' then asession.writeResult('command not available');

end;

function getKey(s:String):String;
begin
 result:=copy(s,1,pos('=',s)-1);
end;
function getVal(s:String):String;
begin
 result:=copy(s,pos('=',s)+1,length(s));
end;

function Parse(cmd:String):Tcli;
var
  i:integer;
  p,s,t:String;
begin
setlength(result.Params,0);
setlength(result.Path,0);
if cmd<>'' then
   begin
   p:=cmd;
   if (pos(' ',cmd)>0) then
      begin
      p:=copy(cmd,1,pos(' ',cmd)-1);
//      setlength(result.Params,length(result.Params)+1);
//      result.Params[high(result.Params)]:=Stringreplace(p,'_',' ',[rfReplaceAll]);
      end;
   setlength(result.Params,length(result.Params)+1);
   result.Params[high(result.Params)]:=Stringreplace(p,'_',' ',[rfReplaceAll]);
   cmd:=copy(cmd,length(p)+2,length(cmd));
   if cmd<>'' then
      begin
      while (pos(' ',cmd)>0) do
         begin
         s:=copy(cmd,1,pos(' ',cmd)-1);
         cmd:=copy(cmd,pos(' ',cmd)+1,length(cmd));
         if s<>'' then
           begin
           setlength(result.Params,length(result.Params)+1);
           result.Params[high(result.Params)]:=Stringreplace(s,'_',' ',[rfReplaceAll]);
           end;
         end;
       if cmd<>'' then
          begin
          setlength(result.Params,length(result.Params)+1);
          result.Params[high(result.Params)]:=Stringreplace(cmd,'_',' ',[rfReplaceAll])
          end;
      end;
   end;

//    for i:= 0 to high(result.Params) do   writeln('PARAM:'+result.Params[i]+'_');
//    for i:= 0 to high(result.Path) do   writeln('PATH:'+result.Path[i]+'_');
end;

procedure addProcess(o:TObject;ahint:String);
//  procedure addProcess(o:TObject);
var
  n:String;
begin
  if o.ClassType=TIECTree then
     begin  IIecTree:=TIECTree(o); n:='item';end;

  if o.ClassType=TIEC104Clientlist then
     begin IClients:=TIEC104Clientlist(o); n:='client';  end;

  if o.ClassType=TIEC104Server then
     begin IServer:=TIEC104Server(o); n:='server';  end;

  if o.ClassType= TIEC104Clientlist then
     begin IClients:=TIEC104Clientlist(o); n:='client';  end;

  if o.ClassType=TIEC101Master then
     begin IMaster:=TIEC101Master(o); n:='master'; end;

  if o.ClassType=TIECGWEvent then
     begin IEvent:=TIECGWEvent(o); n:='event';  end;

  setlength(Process,length(Process)+1);
  Process[high(Process)]:=n;
  setlength(Hint,length(Hint)+1);
  Hint[high(Hint)]:=aHint;
end;

Initialization
 begin
 IIecTree:=nil;
 iclients:=nil;
 Iserver:=nil;
 IMaster := nil;
 IEvent := Nil;
 end;

end.

