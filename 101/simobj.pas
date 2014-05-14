unit simObj;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
   TsimObj=class
     nexttime:tdatetime;
     inctime:integer;
     incval:double;
   private

   public
     constructor create;
     procedure updatenexttime;
   end;

implementation

uses dateutils;

constructor TsimObj.create;
 begin
   inherited;
   inctime:=10;
   incval:=1;
   updatenexttime;
   //nexttime:= IncMilliSecond(now,inctime);
 end;

procedure TsimObj.updatenexttime;
begin
  nexttime:= IncSecond(now,inctime);
end;

end.

