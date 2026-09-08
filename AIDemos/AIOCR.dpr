program AIOCR;

uses
  System.StartUpCopy,
  FMX.Forms,
  Uaiocr in 'Uaiocr.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
