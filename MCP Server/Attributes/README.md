# Attributes

Shows the attribute-based, declarative way to expose a plain Delphi class as an MCP server, using `TMS.MCP.Attributes.Server` instead of manually registering tools via `TMS.MCP.Server`.

## Overview

Instead of building a `TTMSMCPTool` for every operation, you mark ordinary methods on a class with `[TTMSMCPTool]` and let `TTMSMCPServerFactory.CreateFromObject` reflect over the class to build the server automatically. Method and parameter attributes (`TTMSMCPName`, `TTMSMCPDescription`, `TTMSMCPInteger`, `TTMSMCPFloat`, `TTMSMCPOptional`, `TTMSMCPIdemPotent`) let you customize the generated tool schema without writing any registration code.

`Calculator.pas` defines `TCalculatorServer`, a calculator exposing tools such as `add`, `Subtract`, `Multiply`, `Divide`, and `sqrt`, plus a few methods (`ping`, `test`, `test2`) used to exercise complex parameter/return types (records, arrays, `TStrings`).

## Requirements

- Delphi 11.0 or later
- TMS AI Studio

## Building

1. Open `AttributesDemo.dproj` in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in the `Win32\Debug` or `Win32\Release` folder.

## Setting up a client

The server communicates over STDIO, so any MCP client that supports STDIO transport can connect to it.

### Using Claude for Desktop

Add the server to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "calculator": {
      "command": "PATH_TO_EXE\\AttributesDemo.exe"
    }
  }
}
```

### Using MCP Inspector

```bash
npx @modelcontextprotocol/inspector PATH_TO_EXE\AttributesDemo.exe
```
