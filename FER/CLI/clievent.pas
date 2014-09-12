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
  action : Array [0..4] of String = ('timer','list','add','log','x');//list', 'connect','dis','item','delitem');
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

procedure setTimerCycle(asession:Tsession;ucli:Tcli);
begin
  try
    if IEvent.setTimercycle(ucli.Params[1],strtoInt(ucli.Params[2])) then
       asession.writeResult('event.timer.cycle '+ucli.Params[2]+'  [OK]')
    else
       asession.writeResult('event.timer.cycle  [ERROR]');
    exit;
  Except
    asession.writeResult('event.timer.cycle  [ERROR]');
   end;
end;

procedure listtimer(asession:Tsession);
var i:integer;
 t:TGWTimer;
begin
 asession.writeResult('event.timers:'+inttoStr(Ievent.TimerList.Count));
 for i:=0 to Ievent.TimerList.Count-1 do
     begin
       asession.writeResult(#9+'timer:'+Ievent.TimerList[i]+'  cycle:'+
                   inttoStr(TGWTimer(Ievent.TimerList.Objects[i]).intervall*100));
     end;
 asession.writeResult('event.timer.events:');
 for i:=0 to Ievent.TimerEvents.Count-1 do
     asession.writeResult(#9+'event.timer.event '+Ievent.TimerEvents[i]);
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

procedure add(asession:Tsession;uCLI:TCLI);
var i:integer;
begin
 if length(ucli.Params) >3 then
    begin
    if ucli.Params[1]='connect' then
       begin
       Ievent.addConnectEvent(ucli.Params[2],ucli.Params[3]);
       asession.writeResult('event.add connect [OK]');
       exit;
       end;
    if ucli.Params[1]='disconnect' then
       begin
       Ievent.addDisConnectEvent(ucli.Params[2],ucli.Params[3]);
       asession.writeResult('event.add disconnect [OK]');
       exit;
       end;
    asession.writeResult('event.add ?? [ERROR]');
    end
 else
   asession.writeResult('event.add  [ERROR]');
end;

procedure list(asession:Tsession;uCLI:TCLI);
var i:integer;
begin
 asession.writeResult('event.connect:');
 for i:=0 to Ievent.ConnectList.count-1 do
    asession.writeResult(#9+'onConnect '+Ievent.ConnectList[i]);
 asession.writeResult('event.disconnect:');
 for i:=0 to Ievent.DisConnectList.count-1 do
    asession.writeResult(#9+'onDisConnect '+Ievent.DisConnectList[i]);
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
//  IEvent.log(info,'TimerEventCMD: '+txt);
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
  if (cmd='cycle')then
           begin  setTimercycle(asession,ucli); exit;  end;

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
      asession.writeResult('event.log [OK]');
      exit;
      end;
 asession.writeResult('event.log [ERROR]');
end;
procedure ExecCLI(asession:Tsession;txt:String);
var
 cmd:String;   ucli:TCli;
begin
 IEvent.log(debug,'CLIEventCMD: '+txt);
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

    if (cmd='add')then
          begin  add(asession,ucli); exit;  end;
    if (cmd='list')then
          begin  list(asession,ucli); exit;  end;
    if (cmd='log')then
          begin  log(asession,ucli); exit;  end;
    if (cmd='x')then
          begin  asession.onexec:=@CLI.execcli;  asession.path:=''; exit;  end;

  end;
 if txt<>'' then asession.writeResult('command not available')
end;

end.

