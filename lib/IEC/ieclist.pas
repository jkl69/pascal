unit IECList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  IECStream, IECMap,
  TLoggerUnit, TLevelUnit;

type

  TIECList = class(TList)
    protected
    FLog: TLogger;
    Fonchange : TnotifyEvent;
  private
    Function getItembyName(n:string):TIECItem;
    Function getItembyPath(p:Titempath):TIECItem;
  public
//  constructor Create;
//  destructor destroy; override;
    procedure log(ALevel : TLevel; const AMsg : String);
    function setItemName(it:TIECItem;n:string):boolean;
    function addItem(tk:IEC_SType;asdu:integer;adr:integer):TIECItem;
    Function addItem(s:String):TIECItem;
    Function getItem(n:string):TIECItem;
    Function getItem(tk:IEC_SType;asdu:integer;adr:integer;useBaseTypes:boolean):TIECItem;
    Function matchItem(index:integer;regex:string):boolean;
    Function update(item:TIECItem):boolean;
    Function update(IECItems:TiecItems):boolean;

    property  Logger : Tlogger read Flog write FLog;
    property  onChange : TnotifyEvent read Fonchange write Fonchange;
 end;

implementation

uses regexpr;

{*
 This funktion decode an Item Path string
  e.g. ''  -> tk:IEC_NULL_TYPE asdu:-1  adr:-1
  e.g. '/1'  -> tk:1 asdu:-1  adr:-1 -> tk:IEC_NULL_TYPE
  e.g. '/9/81/93'  -> tk:9 asdu:81  adr:93
*}

Function StrToPath(txt:String):TItemPath;
var  s:string;
begin
  result.typ:=IEC_SType.IEC_NULL_TYPE;
  result.asdu:=-1;
  result.adr:=-1;
  try
    if (pos(IECSEPERATOR,txt)=1) then
     begin     //e.g. txt= /9/10/876
     txt:=copy(txt,pos(IECSEPERATOR,txt)+1,length(txt));
     s:=txt;  //s= 9/10/876
     if (pos(IECSEPERATOR,txt)>0) then s:=copy(txt,1,pos(IECSEPERATOR,txt)-1); //s= 9
     result.typ:= getsType(StrtoInt(s));
     if (pos(IECSEPERATOR,txt)>0) then txt:=copy(txt,pos(IECSEPERATOR,txt)+1,length(txt))
     else txt:='';
     s:=txt; //s= 10/876
     if (pos(IECSEPERATOR,txt)>0) then s:=copy(txt,1,pos(IECSEPERATOR,txt)-1); //s= 10
     result.asdu:= Strtoint(s);
     if (pos(IECSEPERATOR,txt)>0) then txt:=copy(txt,pos(IECSEPERATOR,txt)+1,length(txt))
     else txt:='';
//     txt:=copy(txt,pos(IECSEPERATOR,txt)+1,length(txt));  //txt =876
     result.adr:=StrtoInt(txt);
     end;
  except
      result.typ:=IEC_SType.IEC_NULL_TYPE;
  end;
end;

{ TIECList }

procedure TIECList.log(ALevel : TLevel; const AMsg : String);
var
 s:String;
begin
   if (assigned(Flog)) then
     begin
     s:='ITEMS_'+AMsg;
     Flog.log(ALevel,s);
     end;
end;

Function TIECList.update(IECItems:TiecItems):boolean;
var i:integer;
    item : TIECItem;
begin
result:=false;
 for i:=0 to high(IECItems) do
     begin
     item := TIECItem (IECItems[i]);
     if item.IECTyp<> IEC_SType.IEC_NULL_TYPE then
        begin
        logger.Debug('Search for Item '+inttostr(i)+' '+item.ToHexStr);
        if update(item) then
           result:=true;
        end;
     end;
end;

function TIECList.Update(item:TIECItem):boolean;
//function TIECList.Update(item:TIECItem;useBaseTypes:boolean):boolean;
var
  change:boolean;
  listitem:TIECItem;
begin
  log(debug,'update Item:'+item.ToString);
  listitem :=  getitem(item.IECTyp,item.ASDU,item.Adr,true);
//  listitem :=  getitem(item.IECTyp,item.ASDU,item.Adr,false);
  if listitem = nil then
     begin
     result:=false;
     log(warn,'Item not found');
     end
  else
    begin
    log(debug,'Item exist');
    if listitem.setCot(item.COT,false)then change:=true;
    if listitem.setValue(item.Value,false)then change:=true;
    if listitem.setQU(item.QU,false) then change:= true;
    if change then listitem.Doupdate;
//    if assigned(onchange) then onchange(item);
    result:=true;
    end;
end;

Function TIECList.getItembyName(n:string):TIECItem;
var i:integer; item :TIECItem;
begin
  result:=nil;
  for i:=0 to count-1 do
    begin
    item := TIECItem(get(i));
    if item.name=n then
       begin
       log(debug,'found');
       result:=item;
       exit;
       end;
    end;
end;

Function TIECList.getItem(tk:IEC_SType;asdu:integer;adr:integer;useBaseTypes:boolean):TIECItem;
var found:boolean; i:integer; item :TIECItem;
begin
  result:=nil;
  for i:=0 to count-1 do
    begin
    item := TIECItem(get(i));
    if useBaseTypes then found:= item.IsBaseEqual(tk,asdu,adr)
    else                 found:=item.IsEqual(tk,asdu,adr);
    if found then
       begin
       log(debug,'found');
       result:=item;
       exit;
       end;
    end;
end;

Function TIECList.getItembyPath(p:Titempath):TIECItem;
var i:integer; item :TIECItem;
begin
  result:=getItem(p.typ,p.asdu,p.adr,false);
end;

 Function TIECList.getItem(n:string):TIECItem;
 var p:Titempath;
 begin
  result:=getItembyname(n);
  if result=nil then
     begin
     p:= StrtoPath(n);
     if p.typ=IEC_SType.IEC_NULL_TYPE then
       begin log(TLevelUnit.ERROR,'getItem_PathSyntax');
       exit;
       end;
     result:=getItembyPath(p);
     end;
 end;

 Function TIECList.matchItem(index:integer;regex:string):boolean;
 var  m:string; RegexObj: TRegExpr;
      item : TIECItem;
 begin
  result:=false;
  RegexObj := TRegExpr.Create;
  RegexObj.Expression := regex;
  item := TIECItem(get(index));
  m:= item.PathtoStr(false);
  if RegexObj.Exec(item.name) then
     result:=true;
  if not result then
     begin
     if RegexObj.Exec(m) then
       result:=true;
     end;
 if result then
    log(debug,'match['+regex+'] found in '+item.name+'  ' +m)
 else
    log(debug,'match['+regex+'] NOT found in '+item.name+'  ' +m);

 RegexObj.Free;
end;

function TIECList.setItemName(it:TIECItem;n:string):boolean;
var i:integer; item :TIECItem;
begin
 result:=false;
 item:=getItembyName(n);
 if item=nil then
    begin
    it.Name:=n;
    result:=true;
    end;
end;

function TIECList.addItem(tk:IEC_SType;asdu:integer;adr:integer):TIECItem;
//function TIECList.addItem(tk:IEC_SType;asdu:integer;adr:integer):boolean;
var i:integer;
//  search:String;
//  snode,node:Tnode;
  item:TIECItem;
begin
result:=nil;
 for i:=0 to count-1 do
    begin
    item := TIECItem(get(i));
    if item.IsEqual(tk,asdu,adr) then
       begin
       log(TLevelUnit.ERROR,'Already exist');
       exit;
       end;
    end;
 item := TIECItem.create(tk,asdu,adr);
 item.onChange:=Fonchange;
 add(item);
 log(info,'Item added');
 result:=item;
end;

Function TIECList.addItem(s:String):TIECItem;
//Function TIECList.addItem(s:String):Boolean;
var  itempath:Titempath;
begin
  result:=nil;
  log(info,'StrtoPath '+s);
  Itempath:= StrtoPath(s);
  if Itempath.typ=IEC_SType.IEC_NULL_TYPE then
    log(TLevelUnit.ERROR,'AddItem_PathSyntax')
  else
    begin
    log(info,'AddItem_Path_OK');
    // result will be only true if item not allready exist
    result:=addItem(Itempath.typ,Itempath.asdu,Itempath.adr);
    end
end;

end.

