unit UAPIKeys;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit;

type
  TKeysForm = class(TForm)
    edtOpenAI: TEdit;
    edtGemini: TEdit;
    edtBFL: TEdit;
    edtStability: TEdit;
    edtReve: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KeysForm: TKeysForm;

const
  KEY_PATHS = '.\keys.ini';

procedure LoadKeys(var AOpenAI, AGemini, ABFL, AStability, AReve: string);
procedure SaveKeys(AOpenAI, AGemini, ABFL, AStability, AReve: string);

implementation

uses
  IniFiles;

{$R *.fmx}

procedure LoadKeys(var AOpenAI, AGemini, ABFL, AStability, AReve: string);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(KEY_PATHS);
  try
    AOpenAI := ini.ReadString('APIKeys', 'OpenAI', '');
    AGemini := ini.ReadString('APIKeys', 'Gemini', '');
    ABFL := ini.ReadString('APIKeys', 'BlackForestLabs', '');
    AStability := ini.ReadString('APIKeys', 'Stability', '');
    AReve := ini.ReadString('APIKeys', 'Reve', '');
  finally
    ini.Free;
  end;
end;

procedure SaveKeys(AOpenAI, AGemini, ABFL, AStability, AReve: string);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(KEY_PATHS);
  try
    ini.WriteString('APIKeys', 'OpenAI', AOpenAI);
    ini.WriteString('APIKeys', 'Gemini', AGemini);
    ini.WriteString('APIKeys', 'BlackForestLabs', ABFL);
    ini.WriteString('APIKeys', 'Stability', AStability);
    ini.WriteString('APIKeys', 'Reve', AReve);
    ini.UpdateFile;
  finally
    ini.Free;
  end;
end;

procedure TKeysForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveKeys(edtOpenAI.Text, edtGemini.Text, edtBFL.Text, edtStability.Text, edtReve.Text);
end;

procedure TKeysForm.FormCreate(Sender: TObject);
var
  o, g, b, s, r: string;
begin
  LoadKeys(o, g, b, s, r);

  edtOpenAI.Text := o;
  edtGemini.Text := g;
  edtBFL.Text := b;
  edtStability.Text := s;
  edtReve.Text := r;
end;

end.
