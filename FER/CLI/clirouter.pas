unit CLIRouter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  session, TLevelUnit,tree,
  CLI, IECRouter;

procedure ExecCLI(asession:Tsession;txt:String);

implementation

var slevel:String='|-';

const
  action : Array [0..5] of String = ('root','add', 'list','set','log', 'x');
  Hint : Array [0..5] of String = (
     'add an chanel as root for ASDUs e.g.: route.root client NAME',
     'add an ASDU below an chanel or other ASDU e.g.: route.add client.FER ASDU',
     'list of route tree.',
     'set route Parameters e.g. rote.set 55 name=Trasfomer_1',
     'show / set log level',
     'Exit route menu.');


{
function del():TCLIReturn;
  begin
   result.succsess:=false;
   if length(cmd.Params)>0 then
     begin
     if router.delRoute(cmd.Params[0]) then
       begin Result.succsess:=true; Result.msg:= 'route del';exit; end
     else
       begin Result.msg:= 'Entry not found';exit; end;
     end
   else
     Result.msg:= NO_PARAM;
  end;

function move():TCLIReturn;
  begin
  result.succsess:=false;
  if length(cmd.Params)>1 then
     begin
     if router.moveRoute(strtoint(cmd.Params[0]),cmd.Params[1]) then
       begin Result.succsess:=true; Result.msg:= 'route del';exit; end
     else
       begin Result.msg:= 'Entry not found';exit; end;
     end
  else
     Result.msg:= NO_PARAM;
  end;

}

function help(asession:Tsession):boolean;
var
  i:integer;
begin
  asession.writeResult('route commands');
  for i:=0 to high(action) do
      asession.writeResult('   '+action[i]+#9+'- '+hint[i]);
// irouter.Root.print;
end;

function log(asession:Tsession;uCLI:TCLI):Boolean;
begin
  if (length(ucli.Params)>1) then
    if cli.setlevel(IRouter.Logger,ucli.Params[1])then
      begin
      asession.writeResult('route.log:'+ucli.Params[1]+' [OK]');
      exit;
      end
  else
    begin
    asession.writeResult('route.log:'+ucli.Params[1]+' [ERROR]');
    exit;
    end;

asession.writeResult('route.log: '+IIecList.Logger.GetLevel().ToString()+' [EXIT]');
end;

function addroot(asession:Tsession;uCLI:TCLI):boolean;
  begin
  result:=false;
  if (length(ucli.Params)>2) and (irouter.addRoot(ucli.Params[1],ucli.Params[2])) then
       begin
       asession.writeResult('route.root  [OK]');
       exit;
       end ;
  asession.writeResult('route.root  [ERROR]');
 end;

function set2(asession:Tsession;rnode:TRouteNode;param:string):boolean;
var
  i:integer; done:boolean; key,value:string;
begin
  try
    done:=false;
    key:=copy(param,1,pos('=',param)-1);value:=copy(param,pos('=',param)+1,length(param));
    IRouter.log(debug,'set_'+RNode.text+'  '+key+':'+value);
    if key='name' then
      begin
      RNode.ritem.ASDUname:=value;
      asession.writeResult('route.set '+key+'='+value+' [OK]')
      end
    else asession.writeResult('route.set '+key+'='+value+' [ERROR]')
 except
   asession.writeResult('item.set '+key+'='+value+' [ERROR]');
 end;
end;

function set1(asession:Tsession;uCLI:TCLI):boolean;
var
  index,i:integer; rnode:TRouteNode;
begin
result:=false;
if (length(ucli.Params)>2) then
  begin
  rnode := TRouteNode(Irouter.Root.getNode(ucli.Params[1]));
  if rnode<>nil then
    begin
    for i:=2 to  high(ucli.Params) do
        begin
        set2(asession,RNode,ucli.Params[i]);
        end;
   exit;
   end;
  end;
asession.writeResult('route.set  [ERROR]');
end;

function add(asession:Tsession;uCLI:TCLI):boolean;
var i:integer;
begin
  result:=false;
//  try
  if (length(ucli.Params)>2) then
      begin
      for i:=2 to  high(ucli.Params) do
          begin
          if (irouter.addRoute(ucli.Params[1],ucli.Params[i])) then
             asession.writeResult('route.add  '+ucli.Params[i]+' [OK]')
          else
             asession.writeResult('route.add  '+ucli.Params[i]+' [ERROR]');
          end ;
      exit;
      end;
//   except   asession.writeResult('route.add  [ERROR]');   end;
  asession.writeResult('route.add  [ERROR]');
 end;

function listnode(asession:Tsession;n:TRouteNode):boolean;
var
  i:integer; txt:String;
  child:TRouteNode;
begin
 slevel:='| '+slevel;
 for  i:=0 to high(n.Fchildren) do
     begin
     child:=TRouteNode(n.Fchildren[i]);
     txt:=slevel+' ';
     if (Irouter.getASDUname(child)<>'') then
   //     txt:= txt+' Name:'+ Irouter.getASDUname(child);
        txt:=txt+ Irouter.getASDUname(child)+'_';
     txt:=txt+child.text;
     asession.writeResult(txt);//
//             ' Level:'+inttostr(Irouter.getlevel(child)));
     listnode(asession,child);
     end;
 delete(slevel,1,2);
 end;

function list(asession:Tsession;uCLI:TCLI):boolean;
var
  n:TRouteNode;
begin
 n:= Irouter.root;
 listnode(asession,n);
 asession.writeResult('route.list  [EXIT]');
end;

procedure ExecCLI(asession:Tsession;txt:String);
var
 cmd:String;   ucli:TCli;
begin
 IEvent.log(debug,'CLIEventCMD: '+txt);
 asession.onexec:=@CLIRouter.execCLI;
 if asession.path<>'route.' then asession.path:=asession.path+'route.';
 if txt<>'' then
    begin
    ucli:=parse(txt);
    cmd:=ucli.Params[0];

  if (cmd='') then  exit;
  if (cmd='?')then
     begin help(asession);  exit;  end;

    if (cmd='root')then
            begin  addroot(asession,ucli); exit;  end;
    if (cmd='add')then
            begin  add(asession,ucli); exit;  end;
    if (cmd='list')then
            begin  list(asession,ucli); exit;  end;
    if (cmd='set')then
            begin  set1(asession,ucli); exit;  end;
    if (cmd='log')then
            begin  log(asession,ucli); exit;  end;
  if (cmd='x')then
        begin  asession.onexec:=@CLI.execcli;  asession.path:=''; exit;  end;

  end;
 if txt<>'' then asession.writeResult('command not available')
end;

end.

