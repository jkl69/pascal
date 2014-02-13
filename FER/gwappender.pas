unit GWAppender;

{$ifdef fpc}
  {$mode objfpc}
  {$h+}
{$endif}

interface

uses
   sysutils,
   TLevelUnit, TLayoutUnit, TLoggingEventUnit, TErrorHandlerUnit,
   TAppenderUnit;

type
   TGWAppender = class (TAppender)
   private
   protected
   public
      procedure Append(AEvent : TLoggingEvent); override;
   end;

implementation

uses
  TLogLogUnit;

procedure TGWAppender.Append(AEvent : TLoggingEvent);
begin
  writeln(timetostr(now)+'_'+AEvent.GetLevel().ToString()+'-'+AEvent.GetMessage());
end;

end.

