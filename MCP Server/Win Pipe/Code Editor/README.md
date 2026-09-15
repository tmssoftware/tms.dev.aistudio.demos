# Code Editor

An MCP server, built with `TMS.MCP.Server`, that allows AI assistants to read and edit code in a Delphi editor component. This demo uses the Named Pipe transport rather than direct STDIO, so it requires the sibling [MCP STDIO Bridge](../MCP STDIO Bridge/README.md) application to connect standard MCP clients (Claude Desktop, mcp-inspector, etc.), which only speak STDIO.

## Overview

`SyntaxBridgeDemo` hosts an editor UI and an MCP server over a named pipe. `MCPSTDIOBridge` is a small console app that pipes STDIN/STDOUT to/from that named pipe, so any STDIO-only MCP client can drive the editor as if it were talking to a normal STDIO server.

## Requirements

- Delphi 11.1 or later
- TMS FNC UI Pack (for the editor component)
- TMS MCP SDK

## Building the Components

### 1. Building the Code Editor

1. Open the `SyntaxBridgeDemo.dproj` project in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in the `Win32\Debug` or `Win32\Release` folder.

### 2. Building the STDIO Bridge

1. Open the `MCPSTDIOBridge.dproj` project in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in the `Win32\Debug` or `Win32\Release` folder.

## Setup and Running

1. First, run the Code Editor application (`SyntaxBridgeDemo.exe`).
2. The editor will start and initialize the Named Pipe server with the name "MCPServer".
3. Then, run the STDIO Bridge to connect clients to the editor:
   ```
   MCPSTDIOBridge.exe MCPServer
   ```
   - The first parameter is the pipe name (default: "MCPServer").
   - You can optionally specify a server name as a second parameter for remote connections.

## Setting Up a Client

You can use any MCP client that supports STDIO transport to connect to this server through the bridge. Here are two common options:

### Option 1: Using Claude for Desktop

1. Install [Claude for Desktop](https://claude.ai/download).
2. Edit the Claude Desktop configuration file located at:
   - macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Windows: `%APPDATA%\Claude\claude_desktop_config.json`
3. Add the Code Editor to the `mcpServers` section:

```json
{
  "mcpServers": {
    "codeeditor": {
      "command": "PATH_TO_BRIDGE\\MCPSTDIOBridge.exe",
      "args": ["MCPServer"]
    }
  }
}
```

Replace `PATH_TO_BRIDGE` with the absolute path to your compiled bridge executable.

4. Restart Claude for Desktop.
5. In a separate window, make sure the SyntaxBridgeDemo application is running.
6. Ask Claude about the code in the editor, e.g., "What code is currently in the editor?" or "Write a simple Delphi class to handle JSON parsing".

### Option 2: Using MCP Inspector

1. Install the MCP Inspector tool:
   ```bash
   npm install -g @modelcontextprotocol/inspector
   ```

2. Run the Inspector with the bridge (while the editor is running):
   ```bash
   npx @modelcontextprotocol/inspector PATH_TO_BRIDGE\MCPSTDIOBridge.exe MCPServer
   ```

3. Use the Inspector UI to test the `GetCodeTool` and `SetCodeTool` functionality.
