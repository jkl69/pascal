program iRevision;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes
  { you can add units after this }
 ,  Sysutils;

{$I version.inc}

var
 FileVar: TextFile;
 Fname:string;
 s:string;
 i:integer;

begin
  writeln('iRevision '+versionStr);
  if ParamCount<1 then
     begin
     writeln ('Missing filemane ');
     exit;
     end;
  fname := paramStr(1);
  if not Fileexists(fname) then
     begin
     writeln ('File NOT found '+ Fname );
     exit;
     end;
//  WriteLn('File Test '+versionStr);
  AssignFile(FileVar, Fname); //
  {$I+} //use exceptions
  try
    Reset(FileVar);  // creating the file
    readln(FileVar,s);
    i:=strtoint(s)+1;
    CloseFile(FileVar);

    Rewrite(FileVar);  // creating the file
    writeln(FileVar,inttostr(i));  // creating the file
    Close(FileVar);
  except
    on E: EInOutError do
    begin
     Writeln('File handling error occurred. Details: '+E.ClassName+'/'+E.Message);
    end;
  end;
  writeln('change revision from '+s+' to '+inttostr(i));
//  WriteLn('Program finished.');
// readln;
end.

