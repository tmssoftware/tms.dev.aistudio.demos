program AttributesDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  TMS.MCP.Attributes.Server,
  TMS.MCP.Tools,
  TMS.mcp.Helpers,
  TMS.MCP.Transport.STDIO,
  TMS.MCP.JSON,
  Calculator in 'Calculator.pas';

var
  MCPServer: TTMSMCPAttributedServer;
  Calculator: TCalculatorServer;


begin
  try
    Calculator := TCalculatorServer.Create;
    MCPServer := TTMSMCPServerFactory.CreateFromObject(Calculator);
    //PServer.Tools[0].OnGenerateInputSchema := Calculator.GenerateInputSchema;
    MCPServer.ServerName := 'CalculatorServer';

    try
      MCPServer.Start;
      MCPServer.Run;
    finally
      MCPServer.Free;
      Calculator.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('Error: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
