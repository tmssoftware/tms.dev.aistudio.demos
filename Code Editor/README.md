# TMS MCP Code Editor Demo

This README explains how to set up and use the TMS MCP Code Editor Demo with a client using the STDIO Bridge to connect to the Named Pipe transport.

## Overview

The Code Editor Demo is a Model Context Protocol (MCP) server implementation that allows AI assistants to read and edit code in a Delphi editor component. This demo uses Named Pipe transport rather than direct STDIO, so it requires a bridge application to connect standard MCP clients.

## Requirements

- Delphi 10.0 or later
- TMS FNC UI Pack (for the editor component)
- TMS MCP SDK

## Building the Components

### 1. Building the Code Editor

1. Open the `SyntaxBridgeDemo.dproj` project in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in the `Win32\Debug` or `Win32\Release` folder.

### 2. Building the STDIO Bridge

1. Open the `MCP_STDIO_Bridge.dproj` project in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in the `Win32\Debug` or `Win32\Release` folder.

## Setup and Running

1. First, run the Code Editor application (`SyntaxBridgeDemo.exe`).
2. The editor will start and initialize the Named Pipe server with the name "MCPServer".
3. Then, run the STDIO Bridge to connect clients to the editor:
   ```
   MCP_STDIO_Bridge.exe MCPServer
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
      "command": "PATH_TO_BRIDGE\\MCP_STDIO_Bridge.exe",
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
   npx @modelcontextprotocol/inspector PATH_TO_BRIDGE\MCP_STDIO_Bridge.exe MCPServer
   ```

3. Use the Inspector UI to test the `GetCodeTool` and `SetCodeTool` functionality.
