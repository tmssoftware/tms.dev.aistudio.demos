program WeatherApiSSEDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  System.Rtti,
  System.Classes,
  System.Generics.Collections,
  TMS.MCP.Server,
  TMS.MCP.Tools,
  TMS.MCP.Helpers,
  TMS.MCP.Transport.SSE,
  TMS.MCP.CloudBase;

// The weather function you provided
function GetWeather(city: string): string;
var
  cb: TTMSMCPCloudBase;
  lat, lon: string;
  temp, wind: double;
  res: string;
begin
  res := '';
  cb := TTMSMCPCloudBase.Create;
  try
    cb.Request.Host := 'https://nominatim.openstreetmap.org';
    cb.Request.Path := '/search?q='+city+'&format=jsonv2&limit=1';
    cb.ExecuteRequest(procedure(const ARequestResult: TTMSMCPCloudBaseRequestResult)
      var
        lJValue: TJSONValue;
        lJObject: TJSONObject;
      begin
        lJValue := TJSONObject.ParseJSONValue(ARequestResult.ResultString);
        try
          if (lJValue is TJSONArray) and ((lJValue as TJSONArray).Count > 0) then
          begin
            lJObject := TJSONObject((lJValue as TJSONArray).Items[0]);
            lat := lJObject.GetValue<string>('lat');
            lon := lJObject.GetValue<string>('lon');

            // Create new instance for second request
            cb.Free;
            cb := TTMSMCPCloudBase.Create;
            cb.Request.Host := 'https://api.open-meteo.com';
            cb.Request.Path := '/v1/forecast?latitude='+lat+'&longitude='+lon+'&current=temperature_2m,wind_speed_10m';
            cb.ExecuteRequest(procedure(const ARequestResult: TTMSMCPCloudBaseRequestResult)
              var
                lJValue2: TJSONValue;
                lJObject2: TJSONObject;
              begin
                lJValue2 := TJSONObject.ParseJSONValue(ARequestResult.ResultString);
                try
                  if (lJValue2 is TJSONObject) then
                  begin
                    lJObject2 := (lJValue2 as TJSONObject);
                    lJObject2 := TJSONObject(lJObject2.GetValue('current'));
                    if Assigned(lJObject2) then
                    begin
                      temp := lJObject2.GetValue<double>('temperature_2m');
                      wind := lJObject2.GetValue<double>('wind_speed_10m');
                      res := '{"temperature":'+temp.ToString+',"wind":'+wind.ToString+'}';
                    end;
                  end;
                finally
                  lJValue2.Free;
                end;
              end, nil, false);
          end;
        finally
          lJValue.Free;
        end;
      end, nil, false);
  finally
    cb.Free;
  end;
  Result := res;
end;

// MCP tool handler for weather
function HandleWeatherTool(const Args: array of TValue): TValue;
var
  City: string;
  WeatherData: string;
begin
  if Length(Args) > 0 then
    City := Args[0].AsString
  else
    City := 'London'; // default city

  WeatherData := GetWeather(City);
  Result := TValue.From<string>(WeatherData);
end;

var
  Server: TTMSMCPServer;
  Tool: TTMSMCPTool;

begin
  try
    FormatSettings.DecimalSeparator := '.';

    // Create MCP Server
    Server := TTMSMCPServer.Create(nil);
    Server.ServerName := 'WeatherServer';
    Server.ServerVersion := '1.0.0';
    Server.Transport := TTMSMCPSSETransport.Create(nil);


    // Create and configure the weather tool
    Tool := TTMSMCPTool.CreateBuilder
      .Name('get_weather')
      .Description('Get current weather information for a specified city')
      .ExecuteCallback(HandleWeatherTool)
      .ReturnType(ptJSON)
      .AddProperty
        .Name('city')
        .Description('The city name to get weather for')
        .PropertyType(ptString)
        .Required(False)
        .&End
      .Build;

    // Add tool to server
    Server.Tools.Add(Tool);

    // Start and run the server
    Server.Start;
    Server.Run;

  except
    on E: Exception do
    begin
      ExitCode := 1;
    end;
  end;
end.
