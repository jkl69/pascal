program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  SysUtils, Classes, CLI
  { you can add units after this };
var
  c:char;
begin
//  read(c);
//  writeln('pressed:'+inttostr(Ord(c)));

  PrintCLI(parse('list'));
  writeln('');
  PrintCLI(parse('client.list'));
  writeln('');
  PrintCLI(parse('route.addroot  fer1'));
  writeln('');
  PrintCLI(parse('route:fer1.add 9 12 3 '));
  writeln('');
  PrintCLI(parse('route:fer1:9.add 55 77'));
  writeln('');
  PrintCLI(parse('event:client:fer1.onconnect '+#39+'server.send 555555'+#39+' '+#39+'load ss1.cli'+#39));
  writeln('');
  PrintCLI(parse('item:9:1:8193.set 5'));

end.


