unit TAppAppenderunit;

{$mode objfpc}{$H+}

interface

uses
   Classes,
   TAppenderUnit, TLayoutUnit, TLoggingEventUnit,
   TLevelUnit, TPrintWriterUnit;

type

   PStrings = ^TStrings;

{*----------------------------------------------------------------------------
   TAppAppender appends log events to a TStrings. This can be used in
   combination with e.g. TMemos bases resources.
  ----------------------------------------------------------------------------}
   TAppAppender = class (TAppender)
   private
   protected
      FLines : TStrings;
      FPLines :   ^TStrings;
   public
//      constructor Create(AStrings : TStrings); Overload;
//      constructor Create(const AStrings : TStrings);
      constructor Create(const PStrings : PStrings);
      procedure Append(AEvent : TLoggingEvent); Override;
      procedure SetLayout(ALayout : TLayout); Virtual;
      function RequiresLayout() : Boolean; Override;
   end;


implementation

uses
   main;

{*----------------------------------------------------------------------------
   Instantiate a AppAppender and connect the TStrings designated by AStrings.
  ----------------------------------------------------------------------------}
constructor TAppAppender.Create(const PStrings : PStrings);
begin
   Fplines := PStrings;
   inherited create;
end;

procedure TAppAppender.Append(AEvent : TLoggingEvent);
var
 strings:Tstrings;
begin
   strings:=  Fplines^;
   strings.Append(AEvent.GetMessage());
//   monitor.logTXT.Append(s);
end;

procedure TAppAppender.SetLayout(ALayout : TLayout);
begin

end;

function TAppAppender.RequiresLayout() : Boolean;
begin
  RequiresLayout:=false;
end;

end.

