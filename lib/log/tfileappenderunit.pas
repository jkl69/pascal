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
   Contains the TFileAppender class.
   @version 0.5
   @author <a href="mailto:tcmiller@users.sourceforge.net">Trevor Miller</a>
  ----------------------------------------------------------------------------}
unit TFileAppenderUnit;

{$ifdef fpc}
  {$mode objfpc}
  {$h+}
{$endif}

interface

uses
   Classes,
   TWriterAppenderUnit, TLayoutUnit;

type
{*----------------------------------------------------------------------------
   FileAppender appends log events to a file.
  ----------------------------------------------------------------------------}
   TFileAppender = class (TWriterAppender)
   protected
      FFileStream : TFileStream;
      FAppend : Boolean;
      FFileName : String;
   public
      constructor Create(); Overload;
      constructor Create(const AFileName : String); Overload;
      constructor Create(const AFileName : String; ALayout : TLayout); Overload;
      constructor Create(const AFileName : String; ALayout : TLayout;
        AAppend : Boolean); Overload;
      destructor Destroy; Override;
      procedure setAppend(const AAppend : Boolean);
      procedure SetFile(const AFileName : String);
      procedure setLayout(ALayout : TLayout); Override;
   end;

implementation

uses
  SysUtils,
  TLevelUnit, TSimpleLayoutUnit, TLogLogUnit;

{*----------------------------------------------------------------------------
   Instantiate a new FileAppender instance.
  ----------------------------------------------------------------------------}
constructor TFileAppender.Create();
begin
  inherited create;
  Self.FClosed := true;
  TLogLog.debug('TFileAppender#Create');  
end;

{*----------------------------------------------------------------------------
   Instantiate a FileAppender and open the file designated by filename.
   @param AFileName The name of the file to log to
  ----------------------------------------------------------------------------}
constructor TFileAppender.Create(const AFileName : String);
begin
   self.Create(AFileName, TSimpleLayout.Create, false);
end;

{*----------------------------------------------------------------------------
   Instantiate a FileAppender and open the file designated by filename.
   @param AFileName The name of the file to log to
   @param ALayout The layout to use
  ----------------------------------------------------------------------------}
constructor TFileAppender.Create(const AFileName : String; ALayout : TLayout);
begin
   self.Create(AFileName, ALayout, false);
end;

{*----------------------------------------------------------------------------
   Instantiate a FileAppender and open the file designated by filename.
   @param AFileName The name of the file to log to
   @param ALayout The layout to use
   @param AAppend Open the file in append mode
  ----------------------------------------------------------------------------}
constructor TFileAppender.Create(const AFileName : String; ALayout : TLayout;
  AAppend : Boolean);
begin
   inherited Create;
   FAppend := AAppend;
   Self.FThreshold := TLevelUnit.DEBUG;
   Self.FImmediateFlush := true;
   Self.Flayout := ALayout;
   Self.SetFile(AFileName);
   Self.WriteHeader;
  TLogLog.debug('TAppender#Create');   
end;

{*----------------------------------------------------------------------------
   Close the file and destroy the instance.
  ----------------------------------------------------------------------------}
destructor TFileAppender.Destroy;
begin
   Self.Close();
   Self.FFileStream.Free;
   TLogLog.Debug('TFileAppender#Destroy');   
   inherited Destroy;
end;

{*----------------------------------------------------------------------------
   Close the current file and open the new file given.
   @param AFileName The name of the new file to use
  ----------------------------------------------------------------------------}
procedure TFileAppender.SetFile(const AFileName : String);
begin
   Self.FFileName := AFileName;
   if (Self.FFileStream <> Nil) then
     Self.FFileStream.Free;
   if (not DirectoryExists(ExtractFileDir(AFileName))) then
      ForceDirectories(ExtractFileDir(AFileName));
   if (FileExists(AFileName) AND FAppend) then begin
        FFileStream := TFileStream.Create(AFileName, fmOpenReadWrite or fmShareDenyWrite);
        FFileStream.Position := FFileStream.Size;
   end else
      FFileStream := TFileStream.Create(AFileName, fmCreate);
   Self.SetStream(FFileStream);
   Self.FClosed := false;
   TLogLog.Debug('TFileAppender#SetFile: ' + AFileName);   
end;

{*----------------------------------------------------------------------------
   Set the Layout for this appender to use.
   @param ALayout The layout this appender uses
  ----------------------------------------------------------------------------}
procedure TFileAppender.SetLayout(ALayout : TLayout);
begin
  inherited SetLayout(ALayout);
  Self.WriteHeader;
end;

{*----------------------------------------------------------------------------
   Set whether this appender will append to the file or rewrite the contents.
   @param AAppend True for appending, false for rewriting
  ----------------------------------------------------------------------------}
procedure TFileAppender.setAppend(const AAppend : Boolean);
begin
  Self.FAppend := AAppend;
end;

end.
 
