program AISQL;

uses
  System.StartUpCopy,
  FMX.Forms,
  Uaisql in 'Uaisql.pas' {Form4};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm4, Form4);
  Application.Run;
end.
