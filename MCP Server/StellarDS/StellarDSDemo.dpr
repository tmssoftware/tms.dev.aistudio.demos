program StellarDSDemo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  TMS.MCP.Attributes.Server,
  TMS.MCP.StellarDS;

var
  MCPServer: TTMSMCPAttributedServer;
  StellarDS: TTMSMCPStellarDS;
  ApiKey: string;
  i: Integer;
  Param: string;
begin
  try
    ApiKey := '';
    i := 1;
    while i <= ParamCount do
    begin
      Param := ParamStr(i);

      if (Param = '-key') or (Param = '-apikey') then
      begin
        if i < ParamCount then
        begin
          Inc(i);
          ApiKey := ParamStr(i);
        end;
      end;

      Inc(i);
    end;

    if Trim(ApiKey) = '' then
    begin

      ExitCode := 1;
      Exit;
    end;

    StellarDS := TTMSMCPStellarDS.Create(nil);
    StellarDS.Mode := moSync;
    StellarDS.AccessToken := ApiKey;
    MCPServer := TTMSMCPServerFactory.CreateFromObject(StellarDS);
    MCPServer.ServerName := 'StellarDSServer';


    try

      MCPServer.Start;
      MCPServer.Run;
    finally
      MCPServer.Free;
      StellarDS.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('Error: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
