program Demo;

uses
  System.StartUpCopy,
  FMX.Forms,
  Umain in 'Umain.pas' {Form3},
  UPlannerTools in 'UPlannerTools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
