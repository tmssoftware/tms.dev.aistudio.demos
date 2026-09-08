program AIChart;

uses
  System.StartUpCopy,
  FMX.Forms,
  Uaichart in 'Uaichart.pas' {Form3};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
