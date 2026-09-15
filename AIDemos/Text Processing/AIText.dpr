program AIText;

uses
  System.StartUpCopy,
  FMX.Forms,
  Uaitext in 'Uaitext.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
