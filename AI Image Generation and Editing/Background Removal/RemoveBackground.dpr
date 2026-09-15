program RemoveBackground;

uses
  System.StartUpCopy,
  FMX.Forms,
  URemoveBackground in 'URemoveBackground.pas' {Form2},
  UAPIKeys in '..\Shared\UAPIKeys.pas' {KeysForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TKeysForm, KeysForm);
  Application.Run;
end.
