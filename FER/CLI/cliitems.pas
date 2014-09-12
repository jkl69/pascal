unit CLIItems;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  TLevelUnit,tree,
  fpjson ,
  CLI, IECStream, IECList, session;


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
     r:=n.Fchildren[i].text+' ';
     for  x:=0 to high(child.Fchildren) do
         begin
         s:=child.Fchildren[x].text;
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
  i,t:integer; it:TIECItem;
  jo:TJSONObject;
begin
//  writeResult('ADD');
// writeln('JARRAY_size:'+inttostr(ja.count));
 for i:=0 to ja.count-1 do
    begin
    r:='[ERROR]';
    jo:=ja.Objects[i];
    s:=jo.Strings['path'];
    it:=IIecList.addItem(s);
    if it<>nil then r:='[OK]';
//    if IIecTree.add(s) then r:='[OK]';
    asession.writeresult('item.add '+s+' '+r);
    end;
end;

{function listnode2(n:Tnode):boolean;
begin
 result:=true;
 list(IIecTree.toJson(n));
end;}

function list2(asession:Tsession;uCLI:TCLI):boolean;
var
  index:integer;
  item:TIECItem;
begin
 for index:=0 to IIecList.Count-1 do
     begin
     item:=TIECItem(IIecList[index]);
//      asession.writeResult('check match '+item.PathtoStr(false)+' name:'+item.Name);
     if IIECList.matchItem(index,ucli.Params[1]) then
       asession.writeResult('item '+item.tostring);
//       asession.writeResult('item '+item.PathtoStr(false)+'  [match]');
     end;
end;

function list(asession:Tsession;uCLI:TCLI):boolean;
var  i:integer;  item:TIECItem;
begin
  if (length(ucli.Params)>1) then
     begin
     list2(asession,ucli);
     end
  else
  for i:=0 to IIecList.count-1 do
      begin
      item := TIECItem(IIecList[i]);
      asession.writeResult('item '+item.tostring);
      end;
  asession.writeResult('item.list  [EXIT]')
end;

function set2(asession:Tsession;item:TIECItem;s:string):boolean;
var
  i:integer; done:boolean; key,value:string;
begin
  try
    done:=false;
    key:=copy(s,1,pos('=',s)-1);value:=copy(s,pos('=',s)+1,length(s));
//    IIecTree.log(debug,'set_'+item.name+'  '+key+':'+value);
    IIeclist.log(debug,'set_'+item.name+'  '+key+':'+value);
//    IIecTree.log(info,'set_'+IECType[item.getType].name+' Key:'+key+'  value:'+value);
//    if key='name' then begin item.name:=value; done:=true; end;
    if key='name' then begin
      if IIecList.setItemname(item,value) then done:=true;
      end;
    if key='cot' then begin item.setCOT(strtoint(value),true); done:=true; end;
//    if key='cot' then begin item.COT:=(strtoint(value)); done:=true; end;
    if key='val' then begin item.setValue(strtofloat(value),true);done:=true; end;
    if key='inc' then begin item.setValue(item.Value+(strtofloat(value)),true);done:=true; end;
    if key='qu' then begin item.setQu(ByteToQUSet(item,strtoint(value)),true);done:=true; end;
    if done then asession.writeResult('item.set '+key+'='+value+' [OK]')
    else asession.writeResult('item.set '+key+'='+value+' [ERROR]')
 except
   asession.writeResult('item.set '+key+'='+value+' [ERROR]');
 end;
end;

function set1(asession:Tsession;uCLI:TCLI):boolean;
var
  i:integer;  n:Tnode;  s:String='';  item:TIECItem;
begin
if (length(ucli.Params)>2) then
  begin
  item:=IIecList.getItem(ucli.Params[1]);
  if item<>nil then
     begin
//     asession.writeResult('item.??.set  [Found]');
     for i:=2 to high(ucli.Params) do
        set2(asession,item,ucli.Params[i]);
     exit;
     end
  else
    asession.writeResult('item.??.set  [ERROR]');
  exit;
  end;
asession.writeResult('item.set  [ERROR]');
end;

function set11(asession:Tsession;uCLI:TCLI):boolean;
var
  index,i:integer;   s:String='';  item:TIECItem;
begin
result:=false;
if (length(ucli.Params)>2) then
  begin
  for index:=0 to IIecList.Count-1 do
      begin
      item:=TIECItem(IIecList[index]);
//      asession.writeResult('check match '+item.PathtoStr(false)+' name:'+item.Name);
      if IIECList.matchItem(index,ucli.Params[1]) then
        begin
        result:=true;
        asession.writeResult('item '+item.PathtoStr(false)+'  [match]');
        for i:=2 to high(ucli.Params) do
           set2(asession,item,ucli.Params[i]);
        end;
      end;
  if result then exit;
  end;
//else
asession.writeResult('item.set  [ERROR]');
end;

function add(asession:Tsession;ucli:TCli):Boolean;
var  i:integer ; r,k,v:String;
    it: TIECItem;
begin
  r:='[ERROR]';
  if length(ucli.Params)=1 then asession.writeResult('item.add: '+r);
  for i:=1 to high(ucli.params) do
      begin
      k:=getKey(ucli.params[i]);
      v:=getVal(ucli.params[i]);
//      if IIecList.addItem(ucli.params[i])then r:='[OK]';
      it:= IIecList.addItem(v);
      if it<>nil then
        begin
        r:='[OK]';
//        if k<>v then it.Name:=v;  //allowes double names
        if k<>'' then IIecList.setItemname(it,k); //allowes only unique Names
        end;
      asession.writeResult('item.add:'+ucli.params[i]+' '+r);
      end;
  end;

function level(asession:Tsession;uCLI:TCLI):Boolean;
begin
  if (length(ucli.Params)>1) then
    if cli.setlevel(IIecList.Logger,ucli.Params[1])then
//      if cli.setlevel(IIecTree.Logger,ucli.Params[1])then
      begin
      asession.writeResult('item.log:'+ucli.Params[1]+' [OK]');
      exit;
      end;
asession.writeResult('item.log: '+IIecList.Logger.GetLevel().ToString()+' [EXIT]');
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
  //  begin  set1(asession,ucli);  exit; end;
    begin  set11(asession,ucli);  exit; end;

  if (cmd='x')then
    begin  asession.onexec:=@CLI.execcli;  asession.path:=''; exit;  end;

  end;
  if txt<>'' then asession.writeResult('command not available')
end;

end.

