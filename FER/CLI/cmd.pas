unit CMD;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  session;

{$M+}

type

  TGenericMethod = Procedure(asession:Tsession;p:array of String) of object;
//  TGenericMethod = Procedure(p:array of String) of object;

TProcess = record
  o:Tobject;
  name:String;
  hint:String;
end;

  THelp = record
    name:String;
    hint:String;
  end;

  { TCMD }

  TCMD = class(TObject)
  private
    asize:integer;
    cmdarray:array of String;
    Function getAlias(n:string):string;
    Function PExit(minNoFoParam:integer):boolean;
  public
//    constructor create(l:integer;Source: Array of String);
    procedure execute(asession:Tsession; txt:String);
    Procedure setHelp(cmds:array of String);
    Procedure callProc(asession:Tsession;p:array of String);
  published
    Procedure set0(asession:Tsession;p:array of String);
    Procedure help(asession:Tsession;p:array of String);
    Procedure A(asession:Tsession;p:array of String);
    Procedure B(asession:Tsession;p:array of String);
 end;

var  ci:TCMD ;

implementation

uses IECList,cmd2;

function getKey(s:String):String;
begin
 result:=copy(s,1,pos('=',s)-1);
end;
function getVal(s:String):String;
begin
 result:=copy(s,pos('=',s)+1,length(s));
end;

Function TCMD.PExit(minNoFoParam:integer):boolean;
begin
  result:=false;
  if  minNoFoParam>2 then result:=true;
end;

Procedure TCMD.setHelp(cmds:array of String);
begin
 writeln('CMD_cmdLength '+inttoStr(length(cmds)));
 setlength(cmdarray,length(cmds));
 Move(cmds[0],cmdarray[0],Length(cmdarray)*4);
end;

procedure TCMD.execute(asession:Tsession; txt:String);
var
 i:integer;
 cmd:string;
// ucli:Tcli;
// it:TIECItem;
begin
end;

Procedure TCMD.help(asession:Tsession;p:array of String);
var i:integer;
    k,v:String;
begin
 writeln('cmd help called with '+p[2]);
  For i:=0 to length(cmdarray)-1 do
    begin
      k:=getKey(cmdarray[i]);
      v:=getVal(cmdarray[i]);
//      Writeln (cmdarray[i]);
      asession.writeResult(k+#9+v);
    end;
//  writeln(a(p));
end;

Procedure TCMD.set0(asession:Tsession;p:array of String);
var c2:Tcmd2;
begin
//  c2:=TCMD2.create(2,['a2','b2']);
  c2:=TCMD2.create;
  c2.setHelp(['a2=function a2','b2=Function b2']);
  writeln('cmd set called with '+p[2]);
  c2.help(asession,p);
  c2.Destroy;
end;

Procedure TCMD.A(asession:Tsession;p:array of String);
begin
  writeln('cmd A called with '+p[2]);
end;

Procedure TCMD.B(asession:Tsession;p:array of String) ;
begin
  if not pexit(2) then
   writeln('cmd B called with '+p[2]);
end;

Function TCMD.getalias(n:String):String;
begin
 result:=n;
 case n of
   '?': result:='help' ;
   'set': result:='set0';
 end;
end;

Procedure TCMD.callproc(asession:Tsession;p:array of String);
var  Fproc : TGenericMethod;       pp: pointer;
     Met   : TMethod;
begin
  writeln('search PROCEDURE _'+p[1]+'_');
//  Met.Code := TCMD.MethodAddress(m);
//  Met.Code := MethodAddress(p[1]);
  Met.Code := MethodAddress(getAlias(p[1]));
//  if Met.Code=nil then write('MET=nil ');
  Met.Data := self;

  Fproc := TGenericMethod(Met);

  if assigned(Fproc) then Fproc(asession,p)
  else Writeln('cmd "'+p[1]+'" doesn''t exist');
end;

Initialization
  begin
//    ci:=Tcmd.create(2,['a','b']);
    ci:=Tcmd.create;
    ci.setHelp(['a1=function a1','b1=Function b1']);

  end;

end.

