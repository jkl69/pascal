unit logappender;

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
   TLogAppender = class (TAppender)
   private
   protected
   public
      procedure Append(AEvent : TLoggingEvent); override;
   end;

implementation

uses
  main, TLogLogUnit;

procedure TLogAppender.Append(AEvent : TLoggingEvent);
begin
  main.trace(timetostr(now)+'_'+AEvent.GetLevel().ToString()+'-'+AEvent.GetMessage());
end;

end.

