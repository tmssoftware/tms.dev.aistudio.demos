program AIMaps;

uses
  System.StartUpCopy,
  FMX.Forms,
  Uaimaps in 'Uaimaps.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
