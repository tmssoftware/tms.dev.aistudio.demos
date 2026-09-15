# Simple STDIO

The smallest possible `TMS.MCP.Server` example: a handful of tools over the STDIO transport, shown in both supported registration styles.

## Overview

Every MCP server exposes "tools" an AI assistant can call during a conversation: the assistant sees each tool's name and description, decides when to call it, supplies arguments, and the server runs the corresponding Delphi code and returns a result.

This demo shows two ways to register a tool, producing identical results:

- **Manual / explicit** (`greet`, `add`) — create a `TTMSMCPTool`, set its properties, then `Server.Tools.Add(Tool)`. Best when you need full control or want to keep a reference to the tool (e.g. to attach an `OnGenerateInputSchema` handler).
- **Fluent builder** (`word_count`, `current_time`) — chain `TTMSMCPTool.CreateBuilder` calls and finish with `.Build`. Best for concise, read-at-a-glance registrations.

## Requirements

- Delphi 11.0 or later
- TMS AI Studio

## Building

1. Open `SimpleSTDIOServer.dproj` in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in `Win32\Debug` or `Win32\Release`.

## Setting up a client

### Using Claude for Desktop

```json
{
  "mcpServers": {
    "simple-stdio": {
      "command": "PATH_TO_EXE\\SimpleSTDIOServer.exe"
    }
  }
}
```

### Using MCP Inspector

```bash
npx @modelcontextprotocol/inspector PATH_TO_EXE\SimpleSTDIOServer.exe
```

## Available tools

- `greet` — returns a personalised greeting (`name`, optional `formal`)
- `add` — adds two integers together
- `word_count` — counts the words in a piece of text
- `current_time` — returns the current date/time
