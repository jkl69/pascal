unit tree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TNode = class;

  TTree =class
      root : Tnode;
  public
      constructor create(S:String);
      destructor destroy;
   end;

  TNode = class
      name : String;
      Ffilter :boolean;
      FParent: TNode;
      Fobject: Tobject;
      Fchildren : array of TNode;
  public
      constructor create(S:String);
//      constructor create(parent:tnode;S:String);
      destructor destroy;
      procedure clear;
      Function get(s:string):Tnode;
      Function add(child:TNode):Tnode;
      procedure del(index:integer);
      Function cut(index:integer):Tnode;
      Function Dataindex(s:String):integer;
      Function getParent():Tnode;
      Function getRoot():Tnode;
      Function print:TStringlist;
//      Function  toJson:TJSONObject;
      property Obj:Tobject read Fobject write Fobject;
//      procedure print;
   end;

var
  root: Ttree;
  st:String='|-';

implementation

constructor TTree.create(S:String);
//var
//  node:Tnode;
begin
  inherited create;
  root:= TNode.create(s);
end;

destructor TTree.destroy;
begin
  root.destroy;
  inherited destroy;
end;


//constructor TNode.create(parent:tnode;S:String);
constructor TNode.create(S:String);
begin
  inherited create;
  FParent:=nil;
//  FParent:=parent;
  name:= S;
//  Fobject:= nil;
end;


destructor TNode.destroy;
var
  i:integer;
begin
//writeln(name+' destroy childrens:'+inttostr(length(Fchildren)));
  while length(Fchildren) > 0 do
     begin
       Fchildren[length(Fchildren)-1].destroy;
       setlength(Fchildren,length(Fchildren)-1);
     end;
  inherited destroy;
end;

Function TNode.getParent():Tnode;
begin
  result:= FParent;
end;

Function TNode.Dataindex(s:String):integer;
var
  i:integer;
begin
  result:=-1;
  for i:=0 to high(Fchildren) do
    if Fchildren[i].name=s then
//    if Fchildren[i].Fobject.toString=s then
           begin
           result:= i; exit;
           end;
end;

Function TNode.getRoot():Tnode;
begin
  result:=self;
  while result.Fparent<>nil do
     result:= result.FParent;
end;

// search down for node with data s;
Function TNode.get(s:string):Tnode;
var
  i:integer;
begin
  result:=nil;
  if name=s then
//  if Fobject.toString =s then
      begin
      result:=self;
      exit;
      end;
  for i:=0 to high(Fchildren) do
    begin
      result:=Fchildren[i].get(s);
      if result<>nil then exit;
    end;
end;

Function TNode.add(child:TNode):Tnode;
begin
setLength(Fchildren,Length(Fchildren)+1);
child.FParent:=self;
Fchildren[high(Fchildren)] := child;
result:=child;
end;

procedure TNode.clear;
begin
  while length(Fchildren) >0 do
        del(0);
  setlength(Fchildren,0);
end;

Function TNode.cut(index:integer):Tnode;
var
 i,x:integer;
begin
 result:= Fchildren[index];
 for i:=index to length(Fchildren)-2 do
   begin
    Fchildren[i]:=Fchildren[i+1];
   end;
setlength(Fchildren,length(Fchildren)-1);
end;

procedure TNode.del(index:integer);
var
 i,x:integer;
begin
  Fchildren[index].destroy;
//writeln('length_'+inttostr(x));
 for i:=index to length(Fchildren)-2 do
   begin
//    writeln(inttostr(i)+' copy_'+Fchildren[i+1].name+' to '+Fchildren[i].name);
    Fchildren[i]:=Fchildren[i+1];
   end;
setlength(Fchildren,length(Fchildren)-1);
end;
//procedure TNode.Print;

//procedure TNode.Print;
Function TNode.Print:TStringlist;
var
  i:integer;
begin
  result:=Tstringlist.Create;
  writeln('DATA:'+name);
//  writeln('DATA:'+Fobject.toString);
  st:='| '+st;
  for i:=0 to length(Fchildren)-1 do
    begin
     result.Append(st+inttostr(i)+' '+Fchildren[i].name);
     writeln(st+'clid:'+inttostr(i)+' '+Fchildren[i].name);
//     result.Append(st+inttostr(i)+' '+Fchildren[i].FObject.ToString);
//     writeln(st+'clid:'+inttostr(i)+' '+Fchildren[i].FObject.ToString);
      result.AddStrings(Fchildren[i].print);
    end;
  delete(st,1,2);
end;

end.
