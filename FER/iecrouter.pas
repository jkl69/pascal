unit IECRouter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  tree,
  TLoggerUnit, TLevelUnit;

type

  TIECRouter = class(TObject)
  protected
    FLog: TLogger;
    Froot: TTree;
    function getRoot: TNode;
  public
    constructor Create;
    destructor destroy; override;
    procedure log(ALevel : TLevel; const AMsg : String);
    function  addRoot(chanel:string):boolean;
//    function  addRoute(head:string;asdu:string):boolean;
    function  addRoute(head:string;asdu:integer):boolean;
    function  addRoute(head:string;asdu:array of integer):boolean;
    function  delRoute(head:string):boolean;
    function  moveRoute(asdu:integer;head:string):boolean;
    property  Logger : Tlogger read Flog write FLog;
    property  Root : TNode read Froot.root;
  end;


implementation

constructor TIECRouter.create;
begin
  inherited create;
  Froot := TTree.create('root');
end;

destructor TIECRouter.destroy;
begin
  freeandnil(Froot);
  inherited destroy;
end;

procedure TIECRouter.log(ALevel : TLevel; const AMsg : String);
var
 s:String;
begin
   if (assigned(Flog)) then
     begin
     s:='ROUTER_'+AMsg;
     Flog.log(ALevel,s);
     end;
end;

function TIECRouter.getRoot: TNode;
begin
  result:= Froot.root;
end;

function  TIECRouter.addRoot(chanel:string):boolean;
var
 i:integer;
begin
result := false;
if (root.DataIndex(chanel)=-1) then
    begin
    root.add(Tnode.create(chanel));
    result := true;
    end;
end;

function  TIECRouter.addRoute(head:string;asdu:array of integer):boolean;
var
 i:integer;
begin
  for i:=0 to high(asdu) do
      begin
      result:= addRoute(head,asdu[i]);
      if not result then exit;
      end;
end;

//function  TIECRouter.addRoute(head:string;asdu:string):boolean;
function  TIECRouter.addRoute(head:string;asdu:integer):boolean;
var
 i:integer;
 node:Tnode;
 sasdu:String;
begin
result := false;
sasdu:=inttostr(asdu);
node:=root.get(sasdu);
if (node<>nil) then
    begin
     log(warn,'asdu:'+sasdu+' already exist'); exit;  //asdu already exist;
    end;
node:=root.get(head);
if (node<>nil) then
    begin
    node.add(Tnode.create(sasdu));
    result := true; exit;
    end;
log(warn,'head '+head+' not found');
end;

function  TIECRouter.delRoute(head:string):boolean;
var
 i:integer;
 node,p:Tnode;
begin
result := false;
node:=root.get(head);
if (node<>nil) then
    begin
     p:=node.getParent;
     p.del(p.Dataindex(head));
     log(info,'entry:'+head+' deleted');
     result:=true;  exit;
    end;
log(warn,'head '+head+' not found');
end;

function  TIECRouter.moveRoute(asdu:integer;head:string):boolean;
var
 i:integer;
 node,p,inode:Tnode;
 sasdu:String;
begin
result := false;
sasdu:=inttostr(asdu);
node:=root.get(sasdu);
inode:=root.get(head);
if (inode=nil) then  //new position not exist;
    begin log(warn,'insert head not found'); exit; end;
if (node<>nil) then
   begin
   p:=node.getParent;
   i:=p.Dataindex(node.name);
//   i:=p.Dataindex(node.Fobject.toString);
   node:=p.cut(i);
   inode.add(node);
   log(info,'node moved'); result:=true ; exit;
   end;
log(warn,'cut asdu not found');
end;

end.

