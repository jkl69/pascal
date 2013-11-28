program sniffer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Main, key,sysutils, IECSockDlg,TConfiguratorUnit, TLevelGroupUnit, Pcap;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
//  TConfiguratorUnit.doBasicConfiguration;
  TConfiguratorUnit.doPropertiesConfiguration(ExtractFileDir(Application.ExeName) + '\log4sniffer.properties');
  Application.CreateForm(Tmonitor, monitor);
  Application.Run;
end.

