program IEC101Slave;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  TConfiguratorUnit,
  Forms, runtimetypeinfocontrols, Main, synaser, IECSerial,
  Portsetup, Uvaldlg, simObj, uSimDlg, uqudlg;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  tconfiguratorunit.doBasicConfiguration;
  Application.CreateForm(TSlave, Slave);
  Application.CreateForm(TPortSetup, Setup);
  Application.CreateForm(TValDlg, ValDlg);
  Application.CreateForm(TSimDlg, SimDlg);
  Application.CreateForm(TSimDlg, SimDlg);
  Application.CreateForm(TQUdlg, QUdlg);
//  tconfiguratorunit.doBasicConfiguration;
  Application.Run;
end.

