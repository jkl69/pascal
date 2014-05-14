unit CLIRouter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  TLevelUnit,tree,
  CLI, IECRouter;

function exec(R:TIECRouter;c:TCLI):TcliReturn;


implementation

var
  router:TIECRouter;
  cmd:TCLI;
//  res:TCLIReturn;

const
  action : Array [0..3] of String = ('list', 'add','del','move');
  NO_PARAM='missing Parameter';

function listnode(n:Tnode):TCLIReturn;
var
  i,x:integer;
  r,s:String;
  child:TNode;
begin
 result.succsess:=true;
 for  i:=0 to high(n.Fchildren) do
     begin
     child:=n.Fchildren[i];
     setlength(result.result,length(result.result)+1);
     r:=n.Fchildren[i].Fdata+' ';
     for  x:=0 to high(child.Fchildren) do
         begin
         s:=child.Fchildren[x].Fdata;
         if length(child.Fchildren[x].Fchildren)>0 then s:=s+'+';
         r:=r+s+' ';
         end;
     Result.result[high(Result.result)]:=r+' ';
     end;
 end;

function list():TCLIReturn;
var
  l:TstringList;
  n:Tnode;
begin
 result.succsess:=false;
 result.msg:= 'Route list entrys:';
// l:=router.root.print;
 if length(cmd.child)>0 then
      begin
      n:= router.root.get(cmd.child[high(cmd.child)]);
      if n<>nil then begin result:=listnode(n); exit; end
      else Result.msg:='head not found'; exit;
      end;
 result:=listnode(router.root);
end;

function addchild():TCLIReturn;
var
 x,i,c:integer;
 n:Tnode;
 a:array of integer;
begin
   result.succsess:=false;
   for x:=0 to high(cmd.Params) do
       begin
       val(cmd.Params[x],i,c);
       if c<>0 then   // Param is NO number
          begin Result.msg:='param is no number'; exit; end
       else
         begin
         setlength(a,length(a)+1);
         a[x]:=i;
         end;
       end;
   if not router.addRoute(cmd.child[high(cmd.child)],a) then
      begin Result.msg:='head not found OR child already exist'; exit; end;
   result.succsess:=true;
   Result.msg:='add child';
  end;

function add():TCLIReturn;
  begin
   result.succsess:=false;
   if length(cmd.Params)>0 then
     begin
     if length(cmd.child)>0 then
         begin result:=addchild(); exit; end;

     if router.addRoot(cmd.Params[0]) then
        begin
        Result.msg:= 'add Root '+cmd.Params[0];
        result.succsess:=true;
        end
     else
        Result.msg:='alrady exist';
     end
   else
      Result.msg:= NO_PARAM;
  end;

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

function help():TCLIReturn;
var
  i:integer;
begin
 result.msg:= 'possible commands are:';
 setlength(result.result,length(action));
 for  i:=0 to high(action) do
     Result.result[i]:=action[i];
end;

function exec(R:TIECRouter;c:TCLI):TcliReturn;
// ('list', 'add');
begin
 router:=r;
 cmd:=c;
// router.log(info,'exec');
 if cmd.action='?' then
    begin
    result:=help; exit;
    end;
 if cmd.action=action[0] then
    begin
    result:=list; exit;
    end;
 if cmd.action=action[1] then
    begin
    result:=add; exit;
    end;
 if cmd.action=action[2] then
    begin
    result:=del; exit;
    end;
 if cmd.action=action[3] then
    begin
    result:=move; exit;
    end;
 result.succsess:=false;
 result.msg:='command not found';
end;

end.

