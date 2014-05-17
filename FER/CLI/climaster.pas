unit climaster;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  session, IEC101Serial,
  CLI;

procedure ExecCLI(asession:Tsession;txt:String);

implementation

uses
 {$IFDEF MSWINDOWS}
   Windows,
  {$ENDIF}
 synaser, TLoggerUnit, TLevelUnit;

var  m:TIEC101Member;

const
  action : Array [0..6] of String = ('list','add','start','stop','set', 'log', 'x');
  Hint : Array [0..6] of String = (
       'list master status and settings',
       'add new member [name linkadr] to reqeustList e.g. "master.add RTU-West 100"',
       'start master reqests',
       'stop master requests',
       'change master settings e.g "master.set baudrate=1200"',
       'change Member or Master-log-level  e.g. "master.log debug" , "master.log RTU1 debug"',
       'Exit master menu.');

function list(asession:Tsession;uCLI:TCLI):boolean;
var  i:integer;
     txt:String;
begin
 asession.writeResult('master.config: '+Imaster.getConfigStr);
 for i:=0 to IMaster.Members.count-1 do
    asession.writeResult(#9+'member: '+Imaster.GetMember(i).name+
                        ' LinkAdr:'+inttostr(Imaster.GetMember(i).linkadr));
end;

function configset(asession:Tsession;conf:String;var cfg:TDCB):boolean;
var
  key, val :String;
  done:Boolean;
begin
 done:=false;
 key:=getkey(conf);
 val :=getval(conf);
 try
   if key='port' then
      begin Imaster.Port:=val;  done:=true; end;
   if key='baudrate' then
      begin Imaster.baud:=strtoint(val);  done:=true; end;
   if key='parity' then
      begin  if IMaster.setParity(val[1]) then
               done:=true;
      end;
//      Imaster.parity:=val[1];  done:=true; end;
   if done then
     asession.writeResult('master.set:  '+key+':'+val+' [OK]')
   else
     asession.writeResult('master.set:  '+key+':'+val+' [ERROR]');
 except
   asession.writeResult('master.set:  '+key+':'+val+' [ERROR]');
 end;
end;

function configsettings(asession:Tsession;uCLI:TCLI):boolean;
var cfg:TDCB;
   i:integer;
begin
  cfg := imaster.DCB;
  if length(ucli.Params) >1 then
    begin
    for i:=1 to high(ucli.Params) do
       configset(asession,ucli.Params[i],cfg);
//    Imaster.Config2(cfg.BaudRate,cfg.ByteSize,parityToChar(cfg.Parity),cfg.StopBits);
    end;
end;

function mlog(asession:Tsession;uCLI:TCLI):Boolean;
var  s:String;
begin
  s:='??';
  m:=IMaster.getMember(ucli.Params[1]);
  if (m<>nil) then
   begin
   s:=m.Name;
   if cli.setlevel(m.Logger,ucli.Params[2]) then
     begin
     asession.writeResult('master.'+m.name+' log [OK]');
     exit;
     end;
   end;
  asession.writeResult('master.'+s+' log [ERROR]');
end;

function log(asession:Tsession;uCLI:TCLI):Boolean;
begin
  if (length(ucli.Params)=2) then
     if cli.setlevel(IMaster.Logger,ucli.Params[1])then
      begin
      asession.writeResult('master.log [OK]');
      exit;
      end;
  if (length(ucli.Params)=3) then
     begin
     mlog(asession,uCLI);
     exit;
     end;
 asession.writeResult('master.log [ERROR]');
end;

function req(asession:Tsession;uCLI:TCLI):Boolean;
var  s:String;
begin
 try
   begin
     s:='??';
     m:=IMaster.getMember(ucli.Params[1]);
     if (m<>nil) then
         begin
         s:=m.Name;
         m.setRequest(strtoint(ucli.Params[2]));
         asession.writeResult('master.'+s+' req [OK]');
         end
      else
       asession.writeResult('master.'+s+' req [ERROR]');
   end;
  except
     asession.writeResult('master.'+s+' req [ERROR]');
  end;
end;

function add(asession:Tsession;uCLI:TCLI):boolean;
begin
 if length(ucli.Params) =3 then
   begin
    try
      IMaster.addMember(ucli.Params[1],Strtoint(ucli.Params[2]),
                         TLogger.getInstance('Master.'+ucli.Params[1]));
      asession.writeResult('master.add [OK]');
    except
      asession.writeResult('master.add [ERROR]');
    end
   end
 else
   asession.writeResult('master.Add [ERROR]');
end;

function start(asession:Tsession):boolean;
begin
  if imaster.start then
    asession.writeResult('master.start [OK]')
  else
    asession.writeResult('master.start [ERROR]')
end;

procedure test;
begin
// imaster.Member[0].adddata([45,01,06,00,100,00,01,$40,00,1]);
// imaster.Member[0].adddata([45,01,06,00,100,00,$77,$6f,00,1]);
 imaster.Member[0].adddata([$64,01,06,00,100,00,0,0,00,$14]);
// Imaster.sendData(Imaster.Member[0].nextdata,true);
end;

function stop(asession:Tsession):boolean;
begin
  imaster.stop;
  asession.writeResult('master.stop [OK]');
end;

function help(asession:Tsession):boolean;
var
  i:integer;
begin
  asession.writeResult('master commands');
  for i:=0 to high(action) do
      asession.writeResult('   '+action[i]+#9+'- '+hint[i]);
//      asession.writeResult('   '+action[i]);
end;

procedure ExecCLI(asession:Tsession;txt:String);
var
 cmd:String;   ucli:TCli;
begin
 IMaster.Logger.Log(debug,'CLIMasterCMD: '+txt);
 asession.onexec:=@CLIMaster.execCLI;
 if asession.path<>'master.' then asession.path:=asession.path+'master.';
 if txt<>'' then
    begin
    ucli:=parse(txt);
    cmd:=ucli.Params[0];

  if (cmd='') then  exit;
  if (cmd='?')then
     begin help(asession);  exit;  end;

  if (cmd='list')then
      begin list(asession,ucli); exit end;
  if (cmd='add')then
       begin add(asession,ucli); exit end;
  if (cmd='start')then
        begin start(asession); exit end;
  if (cmd='stop')then
        begin stop(asession); exit end;
    if (cmd='set')then
          begin configsettings(asession,ucli); exit end;
    if (cmd='req')then
          begin req(asession,ucli); exit end;
    if (cmd='log')then
          begin  log(asession,ucli); exit;  end;

    if (cmd='d')then
          begin  test; exit;  end;

  if (cmd='x')then
    begin  asession.onexec:=@CLI.execcli;  asession.path:=''; exit;  end;

  end;
  if txt<>'' then asession.writeResult('command not available')
end;

end.

