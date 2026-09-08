unit frmDemo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VCL.TMSFNCTypes, VCL.TMSFNCUtils,
  VCL.TMSFNCGraphics, VCL.TMSFNCGraphicsTypes, TMS.MCP.Transport,
  TMS.MCP.Transport.NamedPipe, TMS.MCP.Server, VCL.TMSFNCCustomControl,
  VCL.TMSFNCWebBrowser, VCL.TMSFNCCustomWEBControl, VCL.TMSFNCMemo, system.rtti;

type
  TForm6 = class(TForm)
    TMSFNCMemo1: TTMSFNCMemo;
    TMSMCPServer1: TTMSMCPServer;
    TMSMCPNamedPipeTransport1: TTMSMCPNamedPipeTransport;
    function TMSMCPServer1Tools0Execute(const Args: array of TValue): TValue;
    procedure FormShow(Sender: TObject);
    function TMSMCPServer1Tools1Execute(const Args: array of TValue): TValue;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form6: TForm6;

implementation

{$R *.dfm}

procedure TForm6.FormCreate(Sender: TObject);
begin
   reportmemoryleaksonshutdown := true;
end;

procedure TForm6.FormShow(Sender: TObject);
begin
  TMSMCPServer1.Start;
end;

function TForm6.TMSMCPServer1Tools0Execute(const Args: array of TValue): TValue;
begin
  Result := TValue.From<string>(TMSFNCMemo1.Lines.text);
end;

function TForm6.TMSMCPServer1Tools1Execute(const Args: array of TValue): TValue;
begin
  TMSFNCMemo1.Lines.Text := Args[0].AsString;
  Result := 'ok'
end;

end.
