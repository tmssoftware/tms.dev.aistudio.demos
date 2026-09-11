# MCP_STDIO_Bridge

A small, generic console utility that bridges STDIN/STDOUT to a Windows named pipe. It lets any STDIO-only MCP client (Claude Desktop, mcp-inspector, etc.) talk to an MCP server that only exposes the Named Pipe transport (`TMS.MCP.transport.pipes`).

## Overview

The bridge reads JSON-RPC messages line by line from STDIN, forwards each one to the target named pipe, and writes the response back to STDOUT. Requests (with an `id`) wait for a reply; notifications (no `id`) are sent fire-and-forget. This demo pairs it with the [Code Editor](../Code%20Editor/README.md) server, but the bridge itself is not specific to that demo — it works with any server exposing a named pipe via `TMS.MCP.transport.pipes`.

## Requirements

- Delphi 11.0 or later
- TMS AI Studio

## Building

1. Open `MCP_STDIO_Bridge.dproj` in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in `Win32\Debug` or `Win32\Release`.

## Running

```
MCP_STDIO_Bridge.exe [pipeName] [serverName]
```

- `pipeName` — name of the pipe to connect to (default: `MCPServer`)
- `serverName` — remote machine name, for connecting to a pipe on another computer (default: local machine)

The named-pipe MCP server (e.g. Code Editor) must already be running before the bridge is started.
