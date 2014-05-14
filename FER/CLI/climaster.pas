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
 synaser, TLevelUnit;


const
  action : Array [0..5] of String = ('list','start','stop','set', 'log', 'x');

function list(asession:Tsession;uCLI:TCLI):boolean;
var txt:String;
begin
 asession.writeResult('master.config: '+Imaster.getConfigStr);
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
      begin cfg.BaudRate:=strtoint(val);  done:=true; end;
   if done then
     asession.writeResult('master.set:  key:'+key+'_Val:'+val+' [OK]')
   else
     asession.writeResult('master.set:  key:'+key+'_Val:'+val+' [ERROR]');
 except
   asession.writeResult('master.set:  key:'+key+'_Val:'+val+' [ERROR]');
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
    Imaster.Config2(cfg.BaudRate,cfg.ByteSize,parityToChar(cfg.Parity),cfg.StopBits);
    end;
end;

function log(asession:Tsession;uCLI:TCLI):Boolean;
begin
  if (length(ucli.Params)>1) then
     if cli.setlevel(IMaster.Logger,ucli.Params[1])then
      begin
      asession.writeResult('master.log [OK]');
      exit;
      end;
 asession.writeResult('master.log [ERROR]');
end;

function start(asession:Tsession):boolean;
begin
  if imaster.start then
    asession.writeResult('master.start [OK]')
  else
    asession.writeResult('master.start [ERROR]')
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
      asession.writeResult('   '+action[i]);
end;

procedure ExecCLI(asession:Tsession;txt:String);
var
 cmd:String;   ucli:TCli;
begin
 IMaster.Logger.Log(info,'CLIServerCMD: '+txt);
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
  if (cmd='start')then
        begin start(asession); exit end;
  if (cmd='stop')then
        begin stop(asession); exit end;
  if (cmd='set')then
        begin configsettings(asession,ucli); exit end;
  if (cmd='log')then
        begin  log(asession,ucli); exit;  end;

  if (cmd='x')then
    begin  asession.onexec:=@CLI.execcli;  asession.path:=''; exit;  end;

  end;
  if txt<>'' then asession.writeResult('command not available')
end;

end.

