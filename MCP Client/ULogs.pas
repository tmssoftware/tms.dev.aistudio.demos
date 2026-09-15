unit ULogs;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo;

type
  TFormLog = class(TForm)
    memLogs: TMemo;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FDestroyed: Boolean;
  public
    { Public declarations }
    procedure Add(AMessage: string);
  end;

var
  FormLog: TFormLog;

implementation

{$R *.fmx}

{ TForm3 }

procedure TFormLog.Add(AMessage: string);
begin
  if not FDestroyed then
    memLogs.Lines.Add(AMessage);
end;

procedure TFormLog.FormCreate(Sender: TObject);
begin
  FDestroyed := False;
end;

procedure TFormLog.FormDestroy(Sender: TObject);
begin
  FDestroyed := True;
end;

end.
