program ChangeText;

uses
  System.StartUpCopy,
  FMX.Forms,
  UChangeText in 'UChangeText.pas' {Form3},
  UAPIKeys in '..\Shared\UAPIKeys.pas' {KeysForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TKeysForm, KeysForm);
  Application.Run;
end.
