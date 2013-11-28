unit timetest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

function timediff(t1,t2 :String):integer;


implementation

uses main;

// time format 2013-11-11 12:32:53,985
function timediff(t1,t2 :String):integer;
var
  h1,h2:string;
  min1,min2:string;
  sec1,sec2:string;
  msec1,msec2:string;
  Time1,time2 :TDatetime;
  TS1,ts2,ttmp :TTimestamp;
  tmp1: integer;
begin
  h1:= copy(t1,1,2);
  h2:= copy(t2,1,2);
  min1:= copy(t1,4,2);
  min2:= copy(t2,4,2);
  sec1:= copy(t1,7,2);
  sec2:= copy(t2,7,2);
  msec1:= copy(t1,10,3);
  msec2:= copy(t2,10,3);
  log.debug('T1 '+t1+' hour '+h1+' min '+min1+' sec '+sec1+' msec '+msec1);
  log.debug('T2 '+t2+' hour '+h2+' min '+min2+' sec '+sec2+' msec '+msec2);
  time1 := EnCodeTime(strtoint(h1),strtoint(min1),strtoint(sec1),strtoint(msec1));
  time2 := EnCodeTime(strtoint(h2),strtoint(min2),strtoint(sec2),strtoint(msec2));
  log.debug('Time1 '+datetimetoStr(time1));
  log.debug('Time2 '+datetimetoStr(time2));
  TS1:=DateTimeToTimeStamp (time1);
  TS2:=DateTimeToTimeStamp (time2);
  log.debug('Ts1 '+ inttoStr(ts1.Time));
  log.debug('Ts2 '+ inttoStr(ts2.Time));
  timediff :=  ts2.Time-ts1.Time;
  if timediff < 0 then
     begin
     log.warn('TimeDiff <0 '+inttoStr(timediff));
     ttmp := DateTimeToTimeStamp (EnCodeTime(23,59,59,999));
     tmp1 := ttmp.Time-ts1.Time;
     timediff :=  tmp1+ts2.Time;
     log.debug('Time1 to Daymax:'+inttoStr(tmp1)+'+ Time2 from Daystart:'+inttoStr(ts2.Time)+' = Timediff:'+inttostr(timediff));
     end
  else
      begin
        log.debug('TimeDiff '+inttoStr(timediff));
     end;
end;

end.

