{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit iecsocket_0_1;

interface

uses
  IEC104Sockets, simplelog, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('iecsocket_0_1', @Register);
end.
