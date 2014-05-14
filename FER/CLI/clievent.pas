unit CLIEvent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  session, TLevelUnit,tree,
  CLI, IECGWEvent;

procedure ExecCLI(asession:Tsession;txt:String);

implementation


const
  action : Array [0..2] of String = ('timer','log','x');//list', 'connect','dis','item','delitem');
  timeraction : Array [0..5] of String = ('list','newTimer','remTimer','add','del','x');//list', 'connect','dis','item','delitem');

procedure addtimer(asession:Tsession;s:String);
begin
 if IEvent.addTimer(s) then
    asession.writeResult('event.timer.newTimer  [OK]')
 else
    asession.writeResult('event.timer.newTimer  [ERROR]');
end;

procedure addtimers(asession:Tsession;ucli:Tcli);
var i:integer;
begin
 if length(ucli.Params) >1 then
    for i:=1 to high(ucli.Params) do
       addtimer(asession,ucli.Params[i])
 else
   asession.writeResult('event.timer.newTimer  [ERROR]');
end;

procedure addtimerEvent(asession:Tsession;ucli:Tcli);
var i:integer;
begin
 if length(ucli.Params) >2 then
     begin
     IEvent.addTimerevent(ucli.Params[1],ucli.Params[2]);
     asession.writeResult('event.timer.add  [OK]');
     end
 else
   asession.writeResult('event.timer.add  [ERROR]');
end;

procedure delTimerEvent(asession:Tsession;ucli:Tcli);
var i:integer;
begin
 if length(ucli.Params) >1 then
     if IEvent.delTimerevent(ucli.Params[1]) then
        begin
        asession.writeResult('event.timer.del  [OK]');
        exit
        end;
  asession.writeResult('event.timer.del  [ERROR]');
end;

procedure deltimer(asession:Tsession;s:String);
begin
 if IEvent.delTimer(s) then
    asession.writeResult('event.timer.remTimer  [OK]')
 else
    asession.writeResult('event.timer.remTimer  [ERROR]');
end;

procedure listtimer(asession:Tsession);
var i:integer;
 t:TGWTimer;
begin
 for i:=0 to Ievent.TimerList.Count-1 do
     begin
     asession.writeResult('event.timer '+Ievent.TimerList[i]);
     end;
 for i:=0 to Ievent.TimerEvents.Count-1 do
     asession.writeResult('event.timer.event '+Ievent.TimerEvents[i]);
 asession.writeResult('event.timer  [EXIT]');
end;

procedure deltimers(asession:Tsession;ucli:Tcli);
var i:integer;
begin
 if length(ucli.Params) >1 then
    for i:=1 to high(ucli.Params) do
       deltimer(asession,ucli.Params[i])
 else
   asession.writeResult('event.timer.del  [_ERROR]');
end;

function help(asession:Tsession):boolean;
    var   i:integer;
    begin
      asession.writeResult('event commands');
      for i:=0 to high(action) do
         asession.writeResult('   '+action[i]);
    end;
function Timerhelp(asession:Tsession):boolean;
    var   i:integer;
    begin
      asession.writeResult('event.timer commands');
      for i:=0 to high(timeraction) do
         asession.writeResult('   '+timeraction[i]);
    end;

procedure TimerCLI(asession:Tsession;txt:String);
var
 cmd:String;   ucli:TCli;
begin
  IEvent.log(info,'TimerEventCMD: '+txt);
  asession.onexec:=@CLIEvent.TimerCLI;
  if asession.path<>'event.timer.' then asession.path:=asession.path+'timer.';
  if txt<>'' then
    begin
    ucli:=parse(txt);
    cmd:=ucli.Params[0];

  if (cmd='') then  exit;
  if (cmd='?')then
     begin Timerhelp(asession);  exit;  end;

  if (cmd='add')then
            begin  addtimerevent(asession,ucli); exit;  end;
  if (cmd='del')then
            begin  deltimerevent(asession,ucli); exit;  end;
  if (cmd='newTimer')then
          begin  addtimers(asession,ucli); exit;  end;
  if (cmd='remTimer')then
          begin  delTimers(asession,ucli); exit;  end;
  if (cmd='list')then
          begin  listTimer(asession); exit;  end;

  if (cmd='x')then
        begin  asession.onexec:=@CLIEvent.execCLI;  asession.path:='event.'; exit;  end;

  end;
 if txt<>'' then asession.writeResult('command not available')
end;

function log(asession:Tsession;uCLI:TCLI):Boolean;
begin
  if (length(ucli.Params)>1) then
     if cli.setlevel(IEvent.Logger,ucli.Params[1])then
      begin
      asession.writeResult('[OK]');
      exit;
      end;
 asession.writeResult('[ERROR]');
end;
procedure ExecCLI(asession:Tsession;txt:String);
var
 cmd:String;   ucli:TCli;
begin
 IEvent.log(info,'CLIEventCMD: '+txt);
 asession.onexec:=@CLIEvent.execCLI;
 if asession.path<>'event.' then asession.path:=asession.path+'event.';
 if txt<>'' then
    begin
    ucli:=parse(txt);
    cmd:=ucli.Params[0];

  if (cmd='') then  exit;
  if (cmd='?')then
     begin help(asession);  exit;  end;

  if (cmd='timer') then txt:=txt+'.';
  if (pos('timer.',txt)=1)then
         begin   txt:=copy(txt,7,length(txt)); TimerCLI(asession,txt);  exit; end;

    if (cmd='log')then
          begin  log(asession,ucli); exit;  end;
    if (cmd='x')then
          begin  asession.onexec:=@CLI.execcli;  asession.path:=''; exit;  end;

  end;
 if txt<>'' then asession.writeResult('command not available')
end;

end.

