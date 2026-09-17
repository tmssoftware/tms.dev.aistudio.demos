program WeatherApiStreamableHTTPDemo;

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
  TMS.MCP.Transport.StreamableHttp,  // Add SSE transport for SSL support
  TMS.MCP.CloudBase,
  IdSSLOpenSSL;  // Add SSL support

// Enhanced logging procedure
procedure LogToConsole(const Msg: string);
begin
  WriteLn(Format('[%s] %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), Msg]));
end;

// Enhanced weather function with logging
function GetWeather(city: string): string;
var
  cb: TTMSMCPCloudBase;
  lat, lon: string;
  temp, wind: double;
  res: string;
begin
  LogToConsole(Format('Weather request for city: %s', [city]));
  res := '';
  cb := TTMSMCPCloudBase.Create;
  try
    LogToConsole('Getting coordinates from OpenStreetMap...');
    cb.Request.Host := 'https://nominatim.openstreetmap.org';
    cb.Request.Path := '/search?q='+city+'&format=jsonv2&limit=1';
    cb.ExecuteRequest(procedure(const ARequestResult: TTMSMCPCloudBaseRequestResult)
      var
        lJValue: TJSONValue;
        lJObject: TJSONObject;
      begin
        LogToConsole(Format('Geocoding response: %s', [ARequestResult.ResultString]));
        lJValue := TJSONObject.ParseJSONValue(ARequestResult.ResultString);
        try
          if (lJValue is TJSONArray) and ((lJValue as TJSONArray).Count > 0) then
          begin
            lJObject := TJSONObject((lJValue as TJSONArray).Items[0]);
            lat := lJObject.GetValue<string>('lat');
            lon := lJObject.GetValue<string>('lon');
            LogToConsole(Format('Coordinates found: lat=%s, lon=%s', [lat, lon]));

            // Create new instance for second request
            cb.Free;
            cb := TTMSMCPCloudBase.Create;
            LogToConsole('Getting weather data from Open-Meteo...');
            cb.Request.Host := 'https://api.open-meteo.com';
            cb.Request.Path := '/v1/forecast?latitude='+lat+'&longitude='+lon+'&current=temperature_2m,wind_speed_10m';
            cb.ExecuteRequest(procedure(const ARequestResult: TTMSMCPCloudBaseRequestResult)
              var
                lJValue2: TJSONValue;
                lJObject2: TJSONObject;
              begin
                LogToConsole(Format('Weather response: %s', [ARequestResult.ResultString]));
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
                      LogToConsole(Format('Weather data extracted: temp=%.1f�C, wind=%.1f km/h', [temp, wind]));
                    end;
                  end;
                finally
                  lJValue2.Free;
                end;
              end, nil, false);
          end
          else
          begin
            LogToConsole(Format('No location found for city: %s', [city]));
          end;
        finally
          lJValue.Free;
        end;
      end, nil, false);
  except
    on E: Exception do
    begin
      LogToConsole(Format('Error getting weather data: %s', [E.Message]));
    end;
  end;
  try
    cb.Free;
  except
    // Ignore cleanup errors
  end;

  LogToConsole(Format('Weather request completed for %s: %s', [city, res]));
  Result := res;
end;

// Enhanced MCP tool handler with logging
function HandleWeatherTool(const Args: array of TValue): TValue;
var
  City: string;
  WeatherData: string;
begin
  LogToConsole('Weather tool called');

  if Length(Args) > 0 then
    City := Args[0].AsString
  else
    City := 'London'; // default city

  LogToConsole(Format('Processing weather request for: %s', [City]));

  try
    WeatherData := GetWeather(City);
    LogToConsole(Format('Weather tool completed successfully for: %s', [City]));
    Result := TValue.From<string>(WeatherData);
  except
    on E: Exception do
    begin
      LogToConsole(Format('Weather tool error: %s', [E.Message]));
      Result := TValue.From<string>('{"error":"Failed to get weather data"}');
    end;
  end;
end;

// Parse command line parameters
procedure ParseCommandLine(out UseSSL: Boolean; out Port: Integer; out CertFile, KeyFile, KeyPassword: string);
var
  i: Integer;
  Param: string;
begin
  // Default values
  UseSSL := False;
  Port := 8934;
  CertFile := '';
  KeyFile := '';
  KeyPassword := '';

  i := 1;
  while i <= ParamCount do
  begin
    Param := LowerCase(ParamStr(i));

    if (Param = '--ssl') or (Param = '-s') then
    begin
      UseSSL := True;
    end
    else if (Param = '--port') or (Param = '-p') then
    begin
      Inc(i);
      if i <= ParamCount then
        Port := StrToIntDef(ParamStr(i), 8934);
    end
    else if (Param = '--cert') or (Param = '-c') then
    begin
      Inc(i);
      if i <= ParamCount then
        CertFile := ParamStr(i);
    end
    else if (Param = '--key') or (Param = '-k') then
    begin
      Inc(i);
      if i <= ParamCount then
        KeyFile := ParamStr(i);
    end
    else if (Param = '--keypass') or (Param = '--key-password') then
    begin
      Inc(i);
      if i <= ParamCount then
        KeyPassword := ParamStr(i);
    end
    else if (Param = '--pfx') then
    begin
      Inc(i);
      if i <= ParamCount then
      begin
        CertFile := ParamStr(i);  // We'll use CertFile to store PFX path
        KeyFile := 'PFX_MODE';   // Flag to indicate PFX mode
      end;
    end
    else if (Param = '--pfxpass') or (Param = '--pfx-password') then
    begin
      Inc(i);
      if i <= ParamCount then
        KeyPassword := ParamStr(i);
    end
    else if (Param = '--help') or (Param = '-h') then
    begin
      WriteLn('Weather MCP Server');
      WriteLn('Usage: ', ExtractFileName(ParamStr(0)), ' [options]');
      WriteLn('');
            WriteLn('Options:');
      WriteLn('  --ssl, -s              Enable SSL/TLS transport');
      WriteLn('  --port, -p <port>      Port number (default: 8934)');
      WriteLn('  --cert, -c <file>      SSL certificate file path (.crt, .pem)');
      WriteLn('  --key, -k <file>       SSL private key file path (.key, .pem)');
      WriteLn('  --pfx <file>           SSL certificate in PFX/PKCS#12 format');
      WriteLn('  --keypass <password>   SSL private key password');
      WriteLn('  --pfxpass <password>   PFX file password');
      WriteLn('  --help, -h             Show this help');
      WriteLn('');
      WriteLn('Examples:');
      WriteLn('  ', ExtractFileName(ParamStr(0)));
      WriteLn('  ', ExtractFileName(ParamStr(0)), ' --ssl --cert server.crt --key server.key');
      WriteLn('  ', ExtractFileName(ParamStr(0)), ' --ssl --pfx server.pfx --pfxpass mypassword');
      Halt(0);
    end
    else
    begin
      WriteLn('Unknown parameter: ', ParamStr(i));
      WriteLn('Use --help for usage information');
      Halt(1);
    end;

    Inc(i);
  end;

  // Validate SSL configuration
  if UseSSL then
  begin
     if KeyFile = 'PFX_MODE' then
    begin
      // PFX mode validation
      if CertFile = '' then
      begin
        WriteLn('Error: PFX file must be specified with --pfx');
        Halt(1);
      end;
      if not FileExists(CertFile) then
      begin
        WriteLn('Error: PFX file not found: ', CertFile);
        Halt(1);
      end;
    end
    else
    begin
      // Separate cert/key mode validation
      if CertFile = '' then
      begin
        WriteLn('Error: SSL certificate file must be specified with --cert');
        Halt(1);
      end;
      if KeyFile = '' then
      begin
        WriteLn('Error: SSL private key file must be specified with --key');
        Halt(1);
      end;
      if not FileExists(CertFile) then
      begin
        WriteLn('Error: SSL certificate file not found: ', CertFile);
        Halt(1);
      end;
      if not FileExists(KeyFile) then
      begin
        WriteLn('Error: SSL private key file not found: ', KeyFile);
        Halt(1);
      end;
    end;
  end;
end;

// Configure SSL Transport with logging
procedure ConfigureSSLTransport(var StreamableHttpTransport: TTMSMCPStreamableHttpTransport; Port: Integer;
  const CertFile, KeyFile, KeyPassword: string);
begin
  LogToConsole('Configuring SSL transport...');
  StreamableHttpTransport := TTMSMCPStreamableHttpTransport.Create(nil, Port);

  // Use anonymous procedure for OnLog event
 // SSETransport.OnLog := procedure(const Msg: string)
   // begin
    //  LogToConsole(Format('Transport: %s', [Msg]));
  //  end;

  try
    if KeyFile = 'PFX_MODE' then
    begin
      // Configure PFX certificate
      LogToConsole(Format('Using PFX certificate: %s', [CertFile]));
      StreamableHttpTransport.CertFile := CertFile;
      StreamableHttpTransport.KeyFile := '';  // Not used in PFX mode
      StreamableHttpTransport.KeyPassword := KeyPassword;
      StreamableHttpTransport.UseSSL := True;

      // The SSE transport should handle PFX files through the SSL IOHandler
      // Set the PFX file as the certificate file
    end
    else
    begin
      // Configure separate certificate and key files
      LogToConsole(Format('Using certificate: %s, key: %s', [CertFile, KeyFile]));
      StreamableHttpTransport.ConfigureSSL(CertFile, KeyFile, KeyPassword);
    end;

    LogToConsole('SSL configuration completed');
  except
    on E: Exception do
    begin
      LogToConsole(Format('SSL configuration failed: %s', [E.Message]));
      StreamableHttpTransport.Free;
      StreamableHttpTransport := nil;
      raise;
    end;
  end;
end;

var
  Server: TTMSMCPServer;
  Tool: TTMSMCPTool;
  StreamableHttpTransport: TTMSMCPStreamableHttpTransport;
  UseSSL: Boolean;
  Port: Integer;
  CertFile, KeyFile, KeyPassword: string;

begin
  try
    FormatSettings.DecimalSeparator := '.';
    LogToConsole('Starting Weather MCP Server...');

    // Parse command line parameters
    ParseCommandLine(UseSSL, Port, CertFile, KeyFile, KeyPassword);

    // Create MCP Server
    Server := TTMSMCPServer.Create(nil);
    Server.ServerName := 'WeatherServer';
    Server.ServerVersion := '1.0.0';

    LogToConsole(Format('Server created: %s v%s', [Server.ServerName, Server.ServerVersion]));

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
    LogToConsole('Weather tool registered');

    // Configure transport based on SSL setting

    StreamableHttpTransport := TTMSMCPStreamableHttpTransport.Create(nil, Port);

    Server.Transport := StreamableHttpTransport;

    LogToConsole('Starting MCP server...');

    // Start and run the server
    Server.Start;

    LogToConsole('MCP Server started successfully');
    LogToConsole('Ready to handle weather requests...');

    // Run server loop with enhanced logging
    try
      Server.Run;
    except
      on E: Exception do
      begin
        LogToConsole(Format('Server runtime error: %s', [E.Message]));
        raise;
      end;
    end;

  except
    on E: Exception do
    begin
      LogToConsole(Format('Fatal error: %s', [E.Message]));
      ExitCode := 1;
    end;
  end;

  LogToConsole('Weather MCP Server shutting down...');

  // Cleanup
  FreeAndNil(StreamableHttpTransport);

  LogToConsole('Server shutdown complete');
end.
