unit IECRouter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  tree,
  TLoggerUnit, TLevelUnit;

type

  TIECRoute = class
    ASDUname:string;
    status:integer;
    level:integer;
  end;

  TRouteNode = class(Tnode)
     ritem:TIECRoute;
   public
     constructor create(S:String);
     destructor destroy;
//     Function add(child:TNode):Tnode;
    Function add(child:TRouteNode):TRouteNode;
    Function getLevel(l:integer):TRouteNode;
  end;

  TIECRouter = class(TObject)
  protected
    FLog: TLogger;
    FRoot: TRouteNode;
//    function getRoot: TNode;
//    function getRoot: TRouteNode;
  public
    constructor Create;
    destructor destroy; override;
    procedure log(ALevel : TLevel; const AMsg : String);
    function  addRoot(chaneltype,name:string):boolean;

    function  addRoute(head:string;asdu:string):boolean; //asdu can incude No. and name e.g. 100=UW_West
    function  addRoute(head:string;asdu:integer;ASDUName:String):boolean;
//    function  addRoute(head:string;asdu:array of integer):boolean;

    function  delRoute(head:string):boolean;
    function  getChannel(asdu:integer):TRouteNode;
    function  getChannel(RNode:TRouteNode):TRouteNode;

    function  moveRoute(asdu:integer;head:string):boolean;
    function  getASDUname(node:TRouteNode):String;
    function  getLevel(node:TRouteNode):integer;

    property  Logger : Tlogger read Flog write FLog;
    property  Root : TRouteNode read FRoot;
  end;


implementation

constructor TRouteNode.create(S:String);
begin
   inherited;
   ritem:=TIECRoute.Create;
   ritem.status:=-1;
   ritem.level:=0;
   ritem.ASDUname:='';
end;

destructor TRouteNode.destroy;
begin
   inherited;
end;

Function TRouteNode.add(child:TRouteNode):TRouteNode;
begin
  inherited add(child);
//  writeln('ADD To :'+text+'  LEVEL:'+inttoStr(ritem.level));
//  writeln('set '+child.text+' LEVEL: to '+inttoStr(ritem.level+1));
  child.ritem.level:=ritem.level+1;
end;

Function TRouteNode.getLevel(l:integer):TRouteNode;
//var pnode:TRouteNode;
begin
  result:=nil;
//  writeln('LEV'+inttoStr(ritem.level));
  if ritem.level=l then
     result:=self;
  if ritem.level>l then
     begin
     result:= self;
     repeat
       result:=TRouteNode(result.fparent);
     until result.ritem.level=l;
     end;
end;

constructor TIECRouter.create;
begin
  inherited create;
//  FTree := TTree.create('root');
  FRoot := TRouteNode.create('root');
end;

destructor TIECRouter.destroy;
begin
  freeandnil(FRoot);
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

function  TIECRouter.getChannel(RNode:TRouteNode):TRouteNode;
//var  cNode:TRouteNode;
begin
result:=Rnode.getLevel(1);
//  cnode:=Rnode.getLevel(1);
  if result<>nil then
    log(info,'route ASDU is :'+result.text)
  else
    log(warn,'No route to _ASDU:'+RNode.text+' found');
end;

function  TIECRouter.getChannel(asdu:integer):TRouteNode;
var  cNode,RNode:TRouteNode;
begin
result:=nil;
  log(info,'search route for ASDU '+inttoStr(ASDU));
  RNode:=TRouteNode(root.getNode(inttoStr(ASDU)));
  if RNode<>nil then
     begin
     result := getChannel(Rnode);
     exit;
     end
  else
    log(warn,'No route to ASDU:'+inttostr(ASDU)+' found');
end;

//function  TIECRouter.addRoot(chanel:string):boolean;
function  TIECRouter.addRoot(chaneltype,name:string):boolean;
var s:String;
begin
result := false;
s:=chaneltype+'.'+name;
if (root.getNodeIndex(name)=-1) then
    begin
    root.add(TRouteNode.create(name));
    result := true;
//    result := addroute(root,s,'channel');
    exit;
    end;
log(warn,'root '+s+' alrady exist');
end;

{
function  TIECRouter.addRoute(head:string;asdu:array of integer):boolean;
var
 i:integer;
begin
  for i:=0 to high(asdu) do
      begin
      result:= addRoute(head,asdu[i]);
      if not result then exit;
      end;
end; }

function  TIECRouter.addRoute(head:string;asdu:String):boolean;
var number,ASDUname:string;
    no,c:integer;
begin
result:=false;
number := copy(asdu,1,pos('=',asdu)-1);
if number='' then
   number:=copy(asdu,pos('=',asdu)+1,length(asdu))
else
  ASDUname:=copy(asdu,pos('=',asdu)+1,length(asdu));
val(number,no,c);
//log(info,'number:'+number+'_  name:'+ASDUname+'_'+inttoStr(c));
if no>0 then
  begin
  result := addRoute(head,no,ASDUname);
  end;
end;

//function  TIECRouter.addRoute(head:string;asdu:integer;aname:String):boolean;
function  TIECRouter.addRoute(head:string;asdu:integer;ASDUname:String):boolean;
var
 level,i:integer;
 node,nn:TRouteNode;
 iecrout:TIECRoute;
 sasdu:String;
begin
result := false;
log(debug,'addroute("'+head+'",'+inttostr(asdu)+',"'+ASDUname+'")');
sasdu:=inttostr(asdu);
node:=TRouteNode(root.getNode(sasdu));
if (node<>nil) then
    begin
     log(warn,'asdu:'+sasdu+' already exist'); exit;  //asdu already exist;
    end;
node:=TRouteNode(root.getNode(head));
if (node<>nil) then
    begin
    nn:=TRouteNode.create(sasdu);
    nn.ritem.ASDUname :=ASDUname;
    node.add(nn);
    result := true; exit;
    end;
log(warn,'head '+head+' not found');
end;

function  TIECRouter.getASDUname(node:TRouteNode):String;
begin
  result:=node.ritem.ASDUname;
end;

function  TIECRouter.getLevel(node:TRouteNode):integer;
begin
  result:=node.ritem.level;
end;

function  TIECRouter.delRoute(head:string):boolean;
var
 i:integer;
 node,p:Tnode;
begin
result := false;
node:=root.getNode(head);
if (node<>nil) then
    begin
     TIECRoute(node.Fobject).Destroy;
     node.Fobject:=nil;
     p:=node.getParent;
     p.del(p.GetNodeIndex(head));
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
node:=root.getNode(sasdu);
inode:=root.getNode(head);
if (inode=nil) then  //new position not exist;
    begin log(warn,'insert head not found'); exit; end;
if (node<>nil) then
   begin
   p:=node.getParent;
   i:=p.getNodeIndex(node.text);
//   i:=p.Dataindex(node.Fobject.toString);
   node:=p.cut(i);
   inode.add(node);
   log(info,'node moved'); result:=true ; exit;
   end;
log(warn,'cut asdu not found');
end;

end.

