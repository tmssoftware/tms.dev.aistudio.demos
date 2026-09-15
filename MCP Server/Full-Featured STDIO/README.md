# Full-Featured STDIO

The most complete STDIO example in this demo suite, built with `TMS.MCP.Server`. Where [Simple STDIO](../Simple%20STDIO/README.md) only covers tools, this one demonstrates Tools, Resources, Prompts and Sampling together over the same STDIO transport.

## Overview

The server declares MCP protocol version `2025-11-25` but negotiates down to whatever the connecting client supports, so it can be used to explore each of the four MCP primitives against a single running process.

## Requirements

- Delphi 11.1 or later
- TMS AI Studio

## Building

1. Open `TMSMCPSTDIODemo.dproj` in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in `Win32\Debug` or `Win32\Release`.

## Setting up a client

### Using Claude for Desktop

Add to the `mcpServers` section of `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "tms-stdio-demo": {
      "command": "PATH_TO_EXE\\TMSMCPSTDIODemo.exe"
    }
  }
}
```

Restart Claude Desktop and the server will appear in the tools/resources list.

### Using MCP Inspector

```bash
npx @modelcontextprotocol/inspector PATH_TO_EXE\TMSMCPSTDIODemo.exe
```

This opens a browser UI where you can call each tool, resource, and prompt individually.

### Any MCP-compliant client

Pass the executable path as the STDIO command.
