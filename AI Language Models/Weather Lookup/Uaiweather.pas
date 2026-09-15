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

unit Uaiweather;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  TMS.MCP.CloudBase, TMS.MCP.CloudAI, Vcl.ExtCtrls, Vcl.ComCtrls, System.JSON,
  TMS.MCP.CustomComponent, System.Generics.Collections;

type
  TForm1 = class(TForm)
    Memo2: TMemo;
    Panel1: TPanel;
    ComboBox1: TComboBox;
    Memo1: TMemo;
    Button1: TButton;
    ProgressBar1: TProgressBar;
    TMSMCPCloudAI1: TTMSMCPCloudAI;
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure TMSMCPCloudAI1Executed(Sender: TObject;
      AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
      AHttpResult: string);
    procedure TMSMCPCloudAI1Tools0Execute(Sender: TObject; Args: TJSONObject;
      var Result: string);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}


function GetWeather(City: string): string;
var
  cb: TTMSMCPCloudBase;
  lat,lon: string;
  temp,wind: double;
  res: string;

begin
  res := '';

  cb := TTMSMCPCloudBase.Create;
  cb.Request.Host := 'https://nominatim.openstreetmap.org';
  cb.Request.Path := '/search?q='+city+'&format=jsonv2&limit=1';

  cb.ExecuteRequest(procedure(const ARequestResult: TTMSMCPCloudBaseRequestResult)
    var
      lJValue: TJSONValue;
      lJObject: TJSONObject;
    begin
      lJValue := TJSONObject.ParseJSONValue(ARequestResult.ResultString);

      if (lJValue is TJSONArray) then
      begin
        lJObject := TJSONObject( (lJValue as TJSONArray).Items[0]);
        lat := lJObject.GetValue<string>('lat');
        lon := lJObject.GetValue<string>('lon');

        cb := TTMSMCPCloudBase.Create;
        cb.Request.Host := 'https://api.open-meteo.com';
        cb.Request.Path := '/v1/forecast?latitude='+lat+'&longitude='+lon+'&current=temperature_2m,wind_speed_10m';

        cb.ExecuteRequest(procedure(const ARequestResult: TTMSMCPCloudBaseRequestResult)
          var
            lJValue: TJSONValue;
            lJObject: TJSONObject;
          begin
            lJValue := TJSONObject.ParseJSONValue(ARequestResult.ResultString);

            if (lJValue is TJSONObject) then
            begin
              lJObject := (lJValue as TJSONObject);
              lJObject := TJSONObject(lJObject.GetValue('current'));
              temp := lJObject.GetValue<double>('temperature_2m');
              wind := lJObject.GetValue<double>('wind_speed_10m');
              res := '{"temperature":'+temp.ToString+',"wind":'+wind.ToString+'}';
            end;

            end, nil, false);
          end;

    end, nil, false);

  Result := res;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  TMSMCPCloudAI1.Context.Text := Memo1.Text;
  TMSMCPCloudAI1.Execute();
  ProgressBar1.State := pbsNormal;
  memo2.Lines.Clear;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
var
  i: integer;
begin
  i := integer(ComboBox1.Items.Objects[ComboBox1.ItemIndex]);
  TMSMCPCloudAI1.Service := TTMSMCPCloudAIService(i);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  TMSMCPCloudAI1.Logging := true;
  TMSMCPCloudAI1.LogFileName := '.\..\..\aiweather.log';

  TMSMCPCloudAI1.APIKeys.LoadFromFile('.\..\..\..\aikeys.cfg','tmssoftware.com');
  ComboBox1.Items.Assign(TMSMCPCloudAI1.GetServices(true));
  ComboBox1.ItemIndex := 0;
  ComboBox1Change(ComboBox1);
  
  //Define the model that you downloaded to llama.cpp
  //TMSMCPCloudAI1.Settings.LlamaCppModel := '';

  TMSMCPCloudAI1.Request.ReadTimeout := 500000;
  TMSMCPCloudAI1.Request.ConnectTimeout := 500000;
end;

procedure TForm1.TMSMCPCloudAI1Executed(Sender: TObject;
  AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
  AHttpResult: string);
begin
  ProgressBar1.State := pbsPaused;
  if AHttpStatusCode = 200 then
  begin
    memo2.Text := AResponse.Content.Text;
  end
  else
    ShowMessage('HTTP error code: '+AHttpStatusCode.ToString+#13#13+ AHttpResult);
end;

procedure TForm1.TMSMCPCloudAI1Tools0Execute(Sender: TObject; Args: TJSONObject;
  var Result: string);
begin
  Result := GetWeather(Args.GetValue<string>('city'));
end;

end.
