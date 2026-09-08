program AIImages;

uses
  System.StartUpCopy,
  FMX.Forms,
  Uaiimages in 'Uaiimages.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
