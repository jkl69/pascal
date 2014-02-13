{
   Copyright 2005-2006 Log4Delphi Project

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
}
{*----------------------------------------------------------------------------
   Contains the TAppender class.
   @version 0.5
   @author <a href="mailto:tcmiller@users.sourceforge.net">Trevor Miller</a>
  ----------------------------------------------------------------------------}
unit TAppenderUnit;

{$ifdef fpc}
  {$mode objfpc}
  {$h+}
{$endif}

interface

uses
   TLevelUnit, TLayoutUnit, TLoggingEventUnit, TErrorHandlerUnit;

type
{*----------------------------------------------------------------------------
   Implement this abstract class with specific strategies for outputting
   log statements.
  ----------------------------------------------------------------------------}
   TAppender = class (TObject)
   private
   protected
      FLayout : TLayout;
      FThreshold : TLevel;
      FErrorHandler : TErrorHandler;
      FName : String;
      FClosed : boolean;
   public
      constructor Create;
      destructor Destroy; Override;
      procedure Append(AEvent : TLoggingEvent); Virtual; Abstract;

      procedure DoAppend(AEvent : TLoggingEvent);
      procedure SetLayout(ALayout : TLayout); Virtual;
      procedure SetName(AName : String);
      procedure SetThreshold(AThreshold : TLevel);
      procedure SetErrorHandler(AHandler : TErrorHandler);

      function GetLayout() : TLayout;
      function GetName() : String;
      function GetThreshold() : TLevel;
      function GetErrorHandler() : TErrorHandler;
      function IsAsSevereAsThreshold(ALevel : Tlevel) : Boolean;
      function RequiresLayout() : Boolean; Virtual;
   end;

implementation

uses
  TLogLogUnit;

{*----------------------------------------------------------------------------
   Create an instance.
  ----------------------------------------------------------------------------}
constructor TAppender.Create;
begin
  inherited Create;
  Self.FName := Self.ClassName;
  TLogLog.debug('TAppender#Create');
end;

{*----------------------------------------------------------------------------
   Destruct this instance by freeing the layout and error handler.
  ----------------------------------------------------------------------------}
destructor TAppender.Destroy;
begin
   Self.FLayout.Free;
   Self.FErrorHandler.Free;
   TLogLog.debug('TAppender#Destroy: Appender destroyed - name=' + Self.FName);
   inherited Destroy;
end;

{*----------------------------------------------------------------------------
   Log in Appender specific way. When appropriate, Loggers will call the
   append method of appender implementations in order to log.
   @param AEvent The logging event to log
  ----------------------------------------------------------------------------}
procedure TAppender.DoAppend(AEvent : TLoggingEvent);
begin
   if ((NOT Self.FClosed)
         AND (Self.IsAsSevereAsThreshold(AEvent.GetLevel))) then
      Self.Append(AEvent);
end;

{*----------------------------------------------------------------------------
   Set the Layout for this appender to use.
   @param ALayout The layout this appender uses
  ----------------------------------------------------------------------------}
procedure TAppender.SetLayout(ALayout : TLayout);
begin
   Self.FLayout := ALayout;
     TLogLog.debug('TAppender#SetLayout: ' + ALayout.ClassName);
end;

{*----------------------------------------------------------------------------
   Set the name of this appender. The name is used by other components to
   identify this appender.
   @param AName The name of this appender
  ----------------------------------------------------------------------------}
procedure TAppender.SetName(AName : String);
begin
   Self.FName := AName;
  TLogLog.debug('TAppender#SetName: ' + AName);   
end;

{*----------------------------------------------------------------------------
   Set the threshold level for this appender to use.
   @param AThreshold The threshold level this appender uses
  ----------------------------------------------------------------------------}
procedure TAppender.SetThreshold(AThreshold : TLevel);
begin
   Self.FThreshold := AThreshold;
  TLogLog.debug('TAppender#SetThreshold: ' + AThreshold.ToString);   
end;

{*----------------------------------------------------------------------------
   Set the ErrorHandler for this appender to use.
   @param AHandler The error handler for this appender
  ----------------------------------------------------------------------------}
procedure TAppender.SetErrorHandler(AHandler : TErrorHandler);
begin
   Self.FErrorHandler := AHandler;
  TLogLog.debug('TAppender#SetErrorHandler: ' + AHandler.ClassName);   
end;

{*----------------------------------------------------------------------------
   Returns this appenders layout.
   @return The layout of this appender
  ----------------------------------------------------------------------------}
function TAppender.GetLayout() : TLayout;
begin
   Result := Self.FLayout;
end;

{*----------------------------------------------------------------------------
   Get the name of this appender. The name uniquely identifies the appender.
   @return The name of this appender
  ----------------------------------------------------------------------------}
function TAppender.GetName() : String;
begin
   Result := Self.FName;
end;

{*----------------------------------------------------------------------------
   Returns this appender's threshold level.
   @return The threshold level of this appender
  ----------------------------------------------------------------------------}
function TAppender.getThreshold() : TLevel;
begin
   Result := Self.FThreshold;
end;

{*----------------------------------------------------------------------------
   Return the currently set ErrorHandler for this appender.
   @return The error handler of this appender
  ----------------------------------------------------------------------------}
function TAppender.getErrorHandler() : TErrorHandler;
begin
   Result := Self.FErrorHandler;
end;

{*----------------------------------------------------------------------------
   Check whether the message level is below the appender's threshold. If
   there is no threshold set, then the return value is always true.
   @param ALevel The level to check against
   @return True if this appenders level is greater than or equal to the
      given level, false otherwise
  ----------------------------------------------------------------------------}
function TAppender.IsAsSevereAsThreshold(ALevel : Tlevel) : Boolean;
begin
   Result := ((Self.FThreshold = Nil)
      OR (ALevel.IsGreaterOrEqual(Self.FThreshold)));
end;

{*----------------------------------------------------------------------------
   Determine if the appender requires a layout or not. The default value is
   false, appenders that require a layout will override this method.
   @return True if this appender requires a layout, flase otherwise
  ----------------------------------------------------------------------------}
function TAppender.RequiresLayout() : Boolean;
begin
   Result := false;
end;

end.
