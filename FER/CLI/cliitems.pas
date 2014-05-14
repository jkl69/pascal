unit CLIItems;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  TLevelUnit,tree,
  fpjson ,
  CLI, IECStream, IECTree, session;


procedure execJS(asession:Tsession;jo : TJSONObject);
procedure ExecCLI(asession:Tsession;txt:String);


implementation

var
  tablevel:integer=0;

const
  action : Array [0..3] of String = ('list','add','set','x');

function listnode(n:Tnode):boolean;
var
  i,x:integer;
  r,s:String;
  child:TNode;
begin
 result:=true;
 for  i:=0 to high(n.Fchildren) do
     begin
     child:=n.Fchildren[i];
     r:=n.Fchildren[i].name+' ';
     for  x:=0 to high(child.Fchildren) do
         begin
         s:=child.Fchildren[x].name;
         if length(child.Fchildren[x].Fchildren)>0 then s:=s+'+';
         r:=r+s+' ';
         end;
 //    Result.result[high(Result.result)]:=r+' ';
     end;
 end;

procedure list(ja:TJSONArray);
var
  s,ts:String;
  i,t:integer;
  jo:TJSONObject;
begin
// writeln('JARRAY_size:'+inttostr(ja.count));
 for i:=0 to ja.count-1 do
    begin
    jo:=ja.Objects[i];
    ts:='';
    for t:=0 to tablevel do
      ts:=ts+'   ';
    s:=jo.Strings['item'];
//    writeln(ts+'item:'+s);
    writeln(ts+s);
    if jo.IndexOfName('Children')<>-1 then
       begin
       inc(tablevel);
       list(jo.Arrays['Children']);
       dec(tablevel);
//       delete(tab,length(tab)-4,3);
       end;
    end;
end;

procedure add(asession:Tsession;ja:TJSONArray);
//  procedure add(ja:TJSONArray);
var
  s,r:String;
  i,t:integer;
  jo:TJSONObject;
begin
//  writeResult('ADD');
// writeln('JARRAY_size:'+inttostr(ja.count));
 for i:=0 to ja.count-1 do
    begin
    r:='[ERROR]';
    jo:=ja.Objects[i];
    s:=jo.Strings['path'];
    if IIecTree.add(s) then r:='[OK]';
    asession.writeresult('item.add '+s+' '+r);
    end;
end;

function listnode2(n:Tnode):boolean;
begin
 result:=true;
 list(IIecTree.toJson(n));
end;

function listNode(asession:Tsession;n:Tnode):boolean;
var
  i:integer;
  t,s,txt:String;
  item:TIECItem;

begin
  inc(tablevel);
//  s:=inttostr(tablevel);
  t:='';
  for i:=0 to tablevel do
      t:=t+'  ';
  if  length(n.Fchildren)=0 then
     begin
     if n.Obj<>nil then
             begin
             item:=TIECItem(n.Obj);
//             txt:='  Value='+floattoStr(item.Value)+'  Qu='+QuSettoStr(item.Qu)+'  Time='+item.getTimeStr;
             txt:=item.toString;
             end;
     asession.writeResult('item '+n.name+txt);
     end;
  if  length(n.Fchildren)>0 then
      begin
      for i:=0 to high(n.Fchildren) do
         begin
         txt:='';
         if n.Fchildren[i].Obj<>nil then
             begin
              item:=TIECItem(n.Fchildren[i].Obj);
//              txt:='  Val='+floattoStr(item.Value)+'  Qu='+QusetTostr(item.Qu)+'  Time='+item.getTimeStr;
              txt:=item.toString;
             end;
         s:=t+'item '+n.Fchildren[i].name+'  '+txt;
         asession.writeResult(s);
         if  length(n.Fchildren[i].Fchildren)>0 then
             listNode(asession,n.Fchildren[i]);
         end;
     end;
  dec(tablevel);
end;

function list(asession:Tsession;uCLI:TCLI):boolean;
var
  n:Tnode;
  s:String='';
begin
  if (length(ucli.Params)>1) then s:= ucli.Params[1];
  n:=IIECTree.getBranchNode(s);
  if n<>nil then
    begin
     listNode(asession,n);
    end
  else  asession.writeResult('item.list  [EXIT]');
end;

function set2(asession:Tsession;item:TIECItem;s:string):boolean;
var
  i:integer;  key,value:string;
begin
  try
    key:=copy(s,1,pos('=',s)-1);value:=copy(s,pos('=',s)+1,length(s));
    IIecTree.log(info,'set_'+item.name+' Key:'+key+'  value:'+value);
//    IIecTree.log(info,'set_'+IECType[item.getType].name+' Key:'+key+'  value:'+value);
    if key='val' then item.Value:=(strtofloat(value));
    IIecTree.log(info,'set_2');
    if key='inc' then item.Value:=item.Value+(strtofloat(value));
    IIecTree.log(info,'set_3');
    if key='qu' then item.Qu:=ByteToQUSet(item,strtoint(value));
    IIecTree.log(info,'set_4');
    asession.writeResult('item.set '+key+'='+value+' [OK]');
 except
   asession.writeResult('item.set  [ERROR]');
 end;
end;

function set1(asession:Tsession;uCLI:TCLI):boolean;
var
  i:integer;  n:Tnode;  s:String='';  item:TIECItem;
begin
n:=nil;
if (length(ucli.Params)>2) then
    begin
    s:= ucli.Params[1];
    n:=IIECTree.getNode(s);
    end;
if n<>nil then
    begin
    item:=TIECItem(n.Obj);
    for i:=2 to high(ucli.Params) do
       set2(asession,item,ucli.Params[i]);
    exit;
    end;

asession.writeResult('item.set  [ERROR]');
end;

function add(asession:Tsession;ucli:TCli):Boolean;
var
 i:integer ;
 r:String;

begin
  r:='[ERROR]';
  // if no parameter result ERROR
  if length(ucli.Params)=1 then asession.writeResult('item.add: '+r);
  for i:=1 to high(ucli.params) do
      begin
      if IIecTree.add(ucli.params[i])then r:='[OK]';
      asession.writeResult('item.add:'+ucli.params[i]+' '+r);
      end;
  end;

function level(asession:Tsession;uCLI:TCLI):Boolean;
begin
  if (length(ucli.Params)>1) then
     if cli.setlevel(IIecTree.Logger,ucli.Params[1])then
      begin
      asession.writeResult('[OK]');
      exit;
      end;
asession.writeResult('[ERROR]');
end;

procedure help(asession:Tsession);
var
  i:integer;
begin
  asession.writeResult('item commands');
  for i:=0 to high(action) do
      asession.writeResult('   '+action[i]);
end;

procedure execJS(asession:Tsession;Jo :TJSONObject);
var
  cmd:String;
  Cli:Tcli;
  Ja:TJSONArray;
begin
 cmd:=jo.Strings['cmd'];
if cmd='item.add' then
   begin
   add(asession,jo.Arrays['items']);
   end;
end;

procedure ExecCLI(asession:Tsession;txt:String);
var
  i:integer;
  cmd:string;
  ucli:TCli;
begin
 asession.onexec:=@CLIItems.execCLI;
 if asession.path<>'item.' then asession.path:=asession.path+'item.';
 if txt<>'' then
    begin
    ucli:=parse(txt);
    cmd:=ucli.Params[0];

  if (cmd='') then  exit;
  if (cmd='?')then  begin help(asession);  exit;  end;

  if (cmd='log')then
    begin level(asession,ucli); exit end;

  if (cmd='list')then
    begin list(asession,ucli); exit end;

  if (cmd='add')then
    begin  add(asession,ucli);  exit; end;

  if (cmd='set')then
    begin  set1(asession,ucli);  exit; end;

  if (cmd='x')then
    begin  asession.onexec:=@CLI.execcli;  asession.path:=''; exit;  end;

  end;
  if txt<>'' then asession.writeResult('command not available')
end;

end.

