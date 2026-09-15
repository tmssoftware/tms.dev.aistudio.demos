{********************************************************************}
{                                                                    }
{ written by TMS Software                                            }
{            copyright (c) 2025 - 2026                               }
{            Email : info@tmssoftware.com                            }
{            Web : http://www.tmssoftware.com                        }
{                                                                    }
{ The source code is given as is. The author is not responsible      }
{ for any possible damage done due to the use of this code.          }
{ The complete source code remains property of the author and may    }
{ not be distributed, published, given or sold in any form as such.  }
{ No parts of the source code can be included in any other component }
{ or application without written authorization of the author.        }
{********************************************************************}

unit Uaisql;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.TMSFNCTypes, FMX.TMSFNCUtils, FMX.TMSFNCGraphics, FMX.TMSFNCGraphicsTypes,
  System.Rtti, FMX.TMSFNCDataGridCell, FMX.TMSFNCDataGridData,
  FMX.TMSFNCDataGridBase, FMX.TMSFNCDataGridCore, FMX.TMSFNCDataGridRenderer,
  Data.DB, Data.Win.ADODB, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.TMSFNCCustomComponent, FMX.TMSFNCDataGridDatabaseAdapter,
  FMX.TMSFNCCustomControl, FMX.TMSFNCDataGrid, TMS.MCP.CloudBase,
  TMS.MCP.CloudAI, System.JSON, FMX.ListBox, FMX.Memo.Types,
  TMS.MCP.CustomComponent;

type
  TForm4 = class(TForm)
    TMSFNCDataGrid1: TTMSFNCDataGrid;
    TMSFNCDataGridDatabaseAdapter1: TTMSFNCDataGridDatabaseAdapter;
    Panel1: TPanel;
    DataSource1: TDataSource;
    Memo1: TMemo;
    ADOQuery1: TADOQuery;
    ADOConnection1: TADOConnection;
    Button1: TButton;
    TMSMCPCloudAI1: TTMSMCPCloudAI;
    Memo2: TMemo;
    ComboBox1: TComboBox;
    AniIndicator1: TAniIndicator;
    procedure TMSMCPCloudAI1Tools0Execute(Sender: TObject; Args: TJSONObject;
      var Result: string);
    procedure TMSMCPCloudAI1Tools1Execute(Sender: TObject; Args: TJSONObject;
      var Result: string);
    procedure Button1Click(Sender: TObject);
    procedure TMSMCPCloudAI1Executed(Sender: TObject;
      AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
      AHttpResult: string);
    procedure ComboBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure SetGridWidth;
    procedure InitGrid;
  end;

var
  Form4: TForm4;

implementation

{$R *.fmx}


procedure TForm4.Button1Click(Sender: TObject);
begin
  InitGrid;

  AniIndicator1.Enabled := true;
  Button1.Enabled := false;

  TMSMCPCloudAI1.Context.Text := memo1.Lines.Text;
  TMSMCPCloudAI1.Execute();
  Cursor := crHourGlass;
end;

procedure TForm4.ComboBox1Change(Sender: TObject);
var
  i: integer;
begin
  i := integer(ComboBox1.Items.Objects[ComboBox1.ItemIndex]);
  TMSMCPCloudAI1.Service := TTMSMCPCloudAIService(i);
end;

procedure TForm4.FormCreate(Sender: TObject);
begin
  TMSMCPCloudAI1.Logging := true;
  TMSMCPCloudAI1.LogFileName := '.\..\..\aisql.log';
  TMSMCPCloudAI1.APIKeys.LoadFromFile('.\..\..\..\aikeys.cfg','tmssoftware.com');

  ComboBox1.ItemIndex := -1;
  ComboBox1.Items.Assign(TMSMCPCloudAI1.GetServices(true));
  ComboBox1.ItemIndex := 0;
  ComboBox1Change(ComboBox1);
  
  //Define the model that you downloaded to llama.cpp
  //TMSMCPCloudAI1.Settings.LlamaCppModel := '';

  TMSMCPCloudAI1.Request.ReadTimeout := 500000;
  TMSMCPCloudAI1.Request.ConnectTimeout := 500000;

  ADOConnection1.ConnectionString := 'Provider=Microsoft.Jet.OLEDB.4.0;User ID=Admin;Data Source=.\..\..\Airplanes.mdb;'+
    'Mode=Share Deny None;Jet OLEDB:System database="";Jet OLEDB:Registry Path="";Jet OLEDB:Database Password="";Jet OLEDB:Engine Type=5;'+
    'Jet OLEDB:Database Locking Mode=1;Jet OLEDB:Global Partial Bulk Ops=2;Jet OLEDB:Global Bulk Transactions=1;Jet OLEDB:New Database Password="";'+
    'Jet OLEDB:Create System Database=False;Jet OLEDB:Encrypt Database=False;Jet OLEDB:Don''t Copy Locale on Compact=False;'+
    'Jet OLEDB:Compact Without Replica Repair=False;Jet OLEDB:SFP=False;';
  ADOConnection1.Connected := true;

  InitGrid;
end;

procedure TForm4.InitGrid;
begin
  ADOQuery1.SQL.Text := 'SELECT * FROM Planes';
  ADOQuery1.Active := true;
  SetGridWidth;
end;

procedure TForm4.SetGridWidth;
var
  i: integer;
begin
  for i := 0 to TMSFNCDataGrid1.Columns.Count - 1 do
  begin
    TMSFNCDataGrid1.Columns[i].Width := 150;
  end;
end;

procedure TForm4.TMSMCPCloudAI1Executed(Sender: TObject;
  AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
  AHttpResult: string);
begin
  memo2.Lines.Text := aresponse.Content.Text;

  AniIndicator1.Enabled := false;
  Button1.Enabled := true;
end;

procedure TForm4.TMSMCPCloudAI1Tools0Execute(Sender: TObject; Args: TJSONObject;
  var Result: string);
var
  i: integer;
begin
  for i := 0 to TMSFNCDataGridDatabaseAdapter1.Columns.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + TMSFNCDataGridDatabaseAdapter1.Columns[i].FieldName;
  end;
end;

procedure TForm4.TMSMCPCloudAI1Tools1Execute(Sender: TObject; Args: TJSONObject;
  var Result: string);
var
  sql: string;
begin
  Cursor := crDefault;
  sql := Args.GetValue<string>('sql');
  ADOQuery1.SQL.Text := sql;
  ADOQuery1.Active := true;
  SetGridWidth;
  ShowMessage('Generated SQL query:'#13#10+SQL);
end;

end.
