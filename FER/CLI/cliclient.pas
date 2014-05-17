unit CLIClient;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  TLevelUnit,  session,
  CLI, IEC104Clientlist,IEC104Client,IEC104Socket;

procedure ExecCLI(asession:Tsession;txt:String);

implementation

//uses   IEC104Client;
var      cl:TIEC104Client;

const
  action : Array [0..5] of String = ('list','add','start','stop','log', 'x');
  Hint : Array [0..5] of String = (
     'list addres of all available Clients ',
     'adds an new client with an AliasName  usage: client.add NAME [NAME NAME] ',
     'connect client usage: client.start NAME',
     'DisConnect client usage: client.start NAME',
     'set log level',
     'Exit client menu.');

Procedure log(asession:Tsession;uCLI:TCLI);
    begin
      if (length(ucli.Params)=2) then
         if cli.setlevel(IClients.Logger,ucli.Params[1])then
          begin
          asession.writeResult('client.log [OK]');
          exit;
          end;
      asession.writeResult('client.log [ERROR]');
    end;

procedure list(asession:Tsession;uCLI:TCLI);
var  i:integer;
begin
  asession.writeResult('Clients: '+inttostr(iClients.Clients.Count));
  for i:=0 to IClients.Clients.count-1 do
      begin
      cl:=TIEC104Client(IClients.Client[i]);
      asession.writeResult(#9+cl.Name+'  '+cl.host+':'+inttoStr(cl.Port)+
                    '   Activ='+boolasStr(cl.Activ)+
                    '  connected='+boolasStr(cl.iecSocket.active));
      end;
end;

Procedure add(asession:Tsession;uCLI:TCLI);
begin
  if length(ucli.Params) >1 then
   begin
      IClients.addclient(ucli.Params[1]);
      asession.writeResult('client.add [OK]');
      exit;
   end;
     asession.writeResult('client.add [ERROR]');
end;

procedure start(asession:Tsession;uCLI:TCLI);
var
  i:integer;
begin
  if length(ucli.Params) >1 then
   begin
      cl:=TIEC104Client(IClients.getClient(ucli.Params[1]));
      if cl=nil then
        begin
        asession.writeResult('client.??.start [ERROR]'); exit;
        end;
      Cl.Start;
      asession.writeResult('client.start [OK]');
      exit;
   end;
    asession.writeResult('client.??.start [ERROR]');
end;

procedure stop(asession:Tsession;uCLI:TCLI);
var
  i:integer;
begin
  if length(ucli.Params) >1 then
   begin
      cl:=TIEC104Client(IClients.getClient(ucli.Params[1]));
      if cl=nil then
        begin
        asession.writeResult('client.??.stop [ERROR]'); exit;
        end;
      Cl.Stop;
      asession.writeResult('client.stop [OK]');
      exit;
   end;
    asession.writeResult('client.??.stop [ERROR]');
end;

function help(asession:Tsession):boolean;
var
  i:integer;
begin
  asession.writeResult('client commands');
  for i:=0 to high(action) do
      asession.writeResult('   '+action[i]+#9+'- '+hint[i]);
end;

procedure ExecCLI(asession:Tsession;txt:String);
var
 cmd:String;   ucli:TCli;
begin
 IClients.Logger.Log(Debug,'CLIServerCMD: '+txt);
 asession.onexec:=@CLIClient.execCLI;
 if asession.path<>'client.' then asession.path:=asession.path+'client.';
 if txt<>'' then
    begin
    ucli:=parse(txt);
    cmd:=ucli.Params[0];

  if (cmd='') then  exit;
  if (cmd='?')then
     begin help(asession);  exit;  end;

       if (cmd='start')then
            begin start(asession,ucli); exit end;
       if (cmd='stop')then
            begin stop(asession,ucli); exit end;
    if (cmd='add')then
         begin add(asession,ucli); exit end;
    if (cmd='list')then
         begin list(asession,ucli); exit end;
    if (cmd='log')then
         begin log(asession,ucli); exit end;


  if (cmd='x')then
    begin  asession.onexec:=@CLI.execcli;  asession.path:=''; exit;  end;

  end;
  if txt<>'' then asession.writeResult('command not available')
end;


end.

