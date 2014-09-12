unit iectree01;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  fpjson, IECMap, IECStream, tree,
  TLoggerUnit, TLevelUnit;

type
  TItemPath=record
    typ :IEC_Stype;
    asdu :integer;
    adr :integer;
  end;

  TIECTree = class(TObject)
  protected
    FLog: TLogger;
    Froot: TTree;
    Fonchange : TnotifyEvent;
  private
    function getNode(tk:IEC_SType;asdu:integer;adr:integer):Tnode;
  public
    constructor Create;
    destructor destroy; override;
    Function  toJson(n:Tnode):TJSONArray;
    Function add(s:String):Boolean;
    function add(tk:IEC_SType;asdu:integer;adr:integer):boolean;
    Function del(tk:IEC_SType;asdu:integer;adr:integer):Boolean;
    Function addJSON(n:TNode;js:TJsonarray):Boolean;
    procedure MarkNode(n:string);
    function getIECItem(n:string):TIECItem;
    function getNode(n:string):Tnode;
    function update(item:TIECItem):boolean;
//    function update(tk:IEC_SType;asdu:integer;adr:integer):boolean;
    function getBranchNode(n:string):Tnode;
    function getBranchNode(tk:IEC_SType;asdu:integer;adr:integer):Tnode;
    procedure log(ALevel : TLevel; const AMsg : String);
    property  Logger : Tlogger read Flog write FLog;
    property  onChange : TnotifyEvent read Fonchange write Fonchange;
    property  Root : TNode read Froot.root;
  end;


implementation

{*
 This funktion decode an Item Path string
  e.g. ''  -> tk:IEC_NULL_TYPE asdu:-1  adr:-1
  e.g. '/1'  -> tk:1 asdu:-1  adr:-1
  e.g. '/9/81/93'  -> tk:9 asdu:81  adr:93

  Parameter onlyFull = true accept only an Full path
     otherwise result will allways Tk:IEC_NULL_TYPE
*}

Function StrToPath(txt:String;onlyFull:Boolean):TItemPath;
var
s:string;
begin
  result.typ:=IEC_SType.IEC_NULL_TYPE;
  result.asdu:=-1;
  result.adr:=-1;
  try
    if (pos('/',txt)=1) then
     begin
     txt:=copy(txt,pos('/',txt)+1,length(txt));
     s:=txt;
     if (pos('/',txt)>0) then s:=copy(txt,1,pos('/',txt)-1);
     result.typ:= getsType(StrtoInt(s));
     if (pos('/',txt)>0) then txt:=copy(txt,pos('/',txt)+1,length(txt))
     else txt:='';
     s:=txt;
     if (pos('/',txt)>0) then s:=copy(txt,1,pos('/',txt)-1);
     result.asdu:= Strtoint(s);
     if (pos('/',txt)>0) then txt:=copy(txt,pos('/',txt)+1,length(txt))
     else txt:='';
     txt:=copy(txt,pos('/',txt)+1,length(txt));
     result.adr:=StrtoInt(txt);
     end;
  except
    if onlyfull then result.typ:=IEC_SType.IEC_NULL_TYPE;
  end;
end;

constructor TIECTree.create;
begin
  inherited create;
  Froot := TTree.create('root');
end;

destructor TIECTree.destroy;
begin
  freeandnil(Froot);
  inherited destroy;
end;

Function TIECTree.addJSON(n:TNode;js:TJsonarray):Boolean;
begin

end;

{*
 adds an IEC item Only if Path is valid e.g. '/10/45/8912'
*}
Function TIECTree.add(s:String):Boolean;
var
 itempath:Titempath;
begin
 result:=false;
 Itempath:= StrtoPath(s,true);
 if Itempath.typ=IEC_SType.IEC_NULL_TYPE then exit;
 // result will be only true if item not allready exist
 result:= add(Itempath.typ,Itempath.asdu,Itempath.adr);
end;

//Function TNode.toJSON:TJSONObject;
Function TIECTree.toJSON(n:TNode):TJSONArray ;
var
i:integer;
JSONObject,jt:TJSONObject;
JSONArray:TJSONArray;
begin
 result:= TJSONArray.Create();
// JSONObject.Add('ic:'+inttostr(length(Fchildren)),TJsonString.Create(Fdata));
// result.Add(JSONObject);
 if  length(n.Fchildren)>0 then
     begin
//     JSONArray := TJSONArray.Create();
//     Jt := TJSONObject.Create();
     for i:=0 to high(n.Fchildren) do
       begin
//     Jt.Add(Fchildren[i].toJson);
       JSONObject := TJSONObject.Create();
       JSONObject.Add('item',TJsonString.Create(n.Fchildren[i].name));
       if  length(n.Fchildren[i].Fchildren)>0 then
//          JSONObject.Add('Children',n.Fchildren[i].toJson);
          JSONObject.Add('Children',toJson(n.Fchildren[i]));
       result.Add(JSONObject);
       end;
//       JSONObject.Add(Jt);
     end;
//  result.Add(JSONObject);
// Freeandnil(JsonObject);
// JSONObject.Destroy;
end;

procedure TIECTree.log(ALevel : TLevel; const AMsg : String);
var
 s:String;
begin
   if (assigned(Flog)) then
     begin
     s:='ITEMS_'+AMsg;
     Flog.log(ALevel,s);
     end;
end;

procedure TIECTree.MarkNode(n:string);
begin

end;

Function TIECTree.del(tk:IEC_SType;asdu:integer;adr:integer):Boolean;
var
 n:Tnode;
begin
 n:=getNode(tk,asdu,adr);
 n.obj.destroy;
 n.destroy;
end;

function TIECTree.getIECItem(n:string):TIECItem;
var
  node:Tnode;
begin
 result := nil;
 node:= getnode(n);
 if node<>nil then
   result:= TIECItem (node.obj)
 else
   log(warn,n+' NOT found');
end;

function TIECTree.getBranchNode(n:string):Tnode;
var
 index:integer;
 ItemPath:TItemPath;
 child:array[0..2] of String;
begin
  ItemPath:= strtopath(n,false);
  log(info,'search part /'+inttoStr(MAP[ItemPath.typ].TK)+'/'+inttostr(ItemPath.asdu)+'/'+inttostr(ItemPath.adr));
  result:=getBranchNode(ItemPath.typ,ItemPath.asdu,ItemPath.adr);
  if result=nil then
     log(warn,n+' Not found');
end;

 {*#
 #  search a node in tree stops search on -1
 *}
function TIECTree.getBranchNode(tk:IEC_SType;asdu:integer;adr:integer):Tnode;
var
  search:String;
//  node:Tnode;
begin
  result := root;
  if tk=IEC_SType.IEC_NULL_TYPE then exit;
  result:=nil;
  search := inttostr(map[tk].TK);
  result:=root.get(search);
  if result=nil then  //tk not exist
        exit;
  //node is now tk
//  log(debug,'found node tk');
  if asdu=-1 then exit;
  search := inttostr(asdu);
  result:=result.get(search);
  if result=nil then  //asdu for this tk not exist
     exit;
  //node is now tk:asdu
//  log(debug,'found node tk:asdu');
  if adr=-1 then exit;
  search := inttostr(adr);
  result:=result.get(search);
end;

function TIECTree.getNode(n:string):Tnode;
var
 index:integer;
 ItemPath:TItemPath;
 child:array[0..2] of String;
begin
  ItemPath:= strtopath(n,true);
  log(info,'search full /'+inttoStr(map[ItemPath.typ].TK)+'/'+inttostr(ItemPath.asdu)+'/'+inttostr(ItemPath.adr));
  result:=getNode(ItemPath.typ,ItemPath.asdu,ItemPath.adr);
  if result=nil then
     log(warn,n+' Not found');
end;

function TIECTree.getNode(tk:IEC_SType;asdu:integer;adr:integer):Tnode;
var
  search:String;
  node:Tnode;
begin
  result := nil;
  search := inttostr(MAP[tk].TK);
  node:=root.get(search);
  if node=nil then  //tk not exist
        exit;
  //node is now tk
//  log(debug,'found node tk');
  search := inttostr(asdu);
  node:=node.get(search);
  if node=nil then  //asdu for this tk not exist
     exit;
  //node is now tk:asdu
//  log(debug,'found node tk:asdu');
  search := inttostr(adr);
  node:=node.get(search);
  if node=nil then  //adr for this tk:asdu not exist
     exit;
  //node is now tk:asdu:adr
//  log(debug,'found node tk:asdu:adr');
  result := node;
end;

//function TIECTree.update(tk:IEC_SType;asdu:integer;adr:integer):boolean;
function TIECTree.update(item:TIECItem):boolean;
var
  node:Tnode;
  ditem:TIECItem;
begin
  log(debug,'update Item:'+item.ToString);
//  log(debug,'update to value:'+floattostr(item.value[0]));
  node := getnode(item.IECTyp,item.ASDU,item.Adr);
//  node := getNode(tk,asdu,adr);
  if node = nil then
     begin
     log(warn,'Item not found');
     end
  else
    begin
    log(debug,'Item exist');
    ditem := TIECItem (node.Obj);
    ditem.COT:= item.COT;
    ditem.Value:= item.Value;
    ditem.QU:= item.QU;
//    if assigned(onchange) then onchange(item);
    end;
end;

function TIECTree.add(tk:IEC_SType;asdu:integer;adr:integer):boolean;
var
  search:String;
  snode,node:Tnode;
  item:TIECItem;
begin
  search := inttostr(MAP[tk].TK);
  snode:=root.get(search);
  if snode=nil then  //tk not exist yet
        node:=root.add(TNode.create(search))
  else  node:=snode;
  //node is now tk
  search := inttostr(asdu);
  snode:=node.get(search);
  if snode=nil then  //asdu for this tk not exist yet
     node:=node.add(TNode.create(search))
  else  node:=snode;
  //node is now tk:asdu
  search := inttostr(adr);
  snode:=node.get(search);
  if snode=nil then  //adr for this tk:asdu not exist yet
     begin
     node:=node.add(TNode.create(search));
     item:=TIECItem.create(tk,asdu,adr);
     node.obj:= item;
     item.onChange:=Fonchange;
     result:=true;
     end
  else   //Item tk:asdu:adr already exist NOT add
     begin
     result:=false;
     end;
end;


end.

