unit CLIServer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  session, IEC104Client, IEC104Server, //IECList,
  CLI;

procedure ExecCLI(asession:Tsession;txt:String);

implementation

uses
  IECItems2, IEC104Socket, tree,
  TLevelUnit;

var con:TServerConnection;

const
  action : Array [0..4] of String = ('list','start','stop','log','x');

function conlog(asession:Tsession;uCLI:TCLI):Boolean;
  begin
   try
    con:= TServerconnection(Iserver.Connection[Strtoint(ucli.Params[1])]);
    if con <> nil then
       begin
       if cli.setlevel(con.iecsock.Logger,ucli.Params[2])then
           begin
           asession.writeResult('server.log [OK]');
           exit;
           end
      else
        asession.writeResult('server.'+inttoStr(con.iecsock.ID)+'.log [ERROR]');
      end;
   except
      asession.writeResult('server.??.log [ERROR]');
   end;
  end;

function log(asession:Tsession;uCLI:TCLI):Boolean;
  begin
    if (length(ucli.Params)=2) then
       if cli.setlevel(IServer.Logger,ucli.Params[1])then
        begin
        asession.writeResult('server.log [OK]');
        exit;
        end;
    if (length(ucli.Params)=3) then
        begin conlog(asession,ucli); exit; end;
    asession.writeResult('server.log [ERROR]');
  end;

function itemsend():boolean;
var
  Node:Tnode;
  item :TIECTCItem;
  c,i: integer;
begin
{* result.succsess:=false;
 result.msg:='Item not found';
  try
   item:=tr.getIECItem(cmd.Params[0]);
   if item=nil then  exit;
   server.sendbuf(item.getStream);
   result.succsess:=true;
   result.msg:='ItemStream bytes was sended';
   Except
    On Exception do
       begin
       result.msg:=NO_PARAM;
       end;
   end;*}
 end;

function send():boolean;
var
  c,i: integer;
  s:String;
begin
{*  s:='';
  try
   for i:=0 to length(cmd.Params)-1 do
       s:=s+cmd.Params[i];
   c:=server.send(s);
   result:=true;
//   result.msg:=inttoStr(c)+' bytes was sended';
   Except
    On Exception do
       begin
       end;
   end;  *}
  end;

function list(asession:Tsession;uCLI:TCLI):boolean;
var
  i:integer; n:Tnode;  s:String='';
    isock:TIEC104Socket;
begin
  if (length(ucli.Params)>1) then
    //list connection staus
      begin
      s:= ucli.Params[1];
      asession.writeResult('Server Connection');
      end
  else
//list Server staus
    begin
      s:='port='+inttostr(iserver.Port)+'  Activ='+boolasStr(not Iserver.Terminated)+
         '  connections:'+inttostr(Iserver.Connections.Count);
      asession.writeResult('Server '+s);
      for  i:=0 to iserver.Connections.Count-1 do
            begin
            isock := iserver.IecSocket[i];
            if (isock<>nil) then
               s:='['+inttostr(i)+'] '+isock.Socket.GetRemoteSinIP+':'+inttostr(isock.Socket.GetRemoteSinPort);
               asession.writeResult('   connection'+s);
            end;
    end;
end;

function start(asession:Tsession):boolean;
var
  i:integer;
begin
  if iserver.start then
    asession.writeResult('server.start [OK]')
  else
    asession.writeResult('server.start [ERROR]')
end;

function stop(asession:Tsession):boolean;
var
  i:integer;
begin
  iserver.stop;
  asession.writeResult('server.stop [OK]');
end;

function help(asession:Tsession):boolean;
var
  i:integer;
begin
  asession.writeResult('server commands');
  for i:=0 to high(action) do
      asession.writeResult('   '+action[i]);
end;

procedure ExecCLI(asession:Tsession;txt:String);
var
 cmd:String;   ucli:TCli;
begin
 Iserver.Logger.Log(Debug,'CLIServerCMD: '+txt);
 asession.onexec:=@CLIServer.execCLI;
 if asession.path<>'server.' then asession.path:=asession.path+'server.';
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
  if (cmd='log')then
        begin log(asession,ucli); exit end;

  if (cmd='x')then
    begin  asession.onexec:=@CLI.execcli;  asession.path:=''; exit;  end;

  end;
  if txt<>'' then asession.writeResult('command not available')
end;

end.

