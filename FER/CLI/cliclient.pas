unit CLIClient;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  TLevelUnit,  session,
  CLI, IEC104Clientlist,IEC104Client,IEC104Socket;

procedure ExecCLI(asession:Tsession;txt:String);

implementation

const
  action : Array [0..1] of String = ('add', 'x');
  Hint : Array [0..1] of String = (
       'adds an new client with an AliasName  usage: client.add NAME [NAME NAME] ',
       'Exit client menu.');

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
 IClients.Logger.Log(info,'CLIServerCMD: '+txt);
 asession.onexec:=@CLIClient.execCLI;
 if asession.path<>'client.' then asession.path:=asession.path+'client.';
 if txt<>'' then
    begin
    ucli:=parse(txt);
    cmd:=ucli.Params[0];

  if (cmd='') then  exit;
  if (cmd='?')then
     begin help(asession);  exit;  end;

//  if (cmd='list')then
//      begin list(asession,ucli); exit end;


  if (cmd='x')then
    begin  asession.onexec:=@CLI.execcli;  asession.path:=''; exit;  end;

  end;
  if txt<>'' then asession.writeResult('command not available')
end;


end.

