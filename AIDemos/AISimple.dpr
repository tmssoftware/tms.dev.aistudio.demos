program AISimple;

uses
  Vcl.Forms,
  Uaisimple in 'Uaisimple.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
