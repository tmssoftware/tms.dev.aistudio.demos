# StellarDS MCP Server

An attribute-based MCP server (see [Attributes](../Attributes/README.md) for the pattern) that wraps the `TTMSMCPStellarDS` component to expose TMS StellarDS as a set of MCP tools over STDIO, so an AI assistant can query and manage a StellarDS backend directly.

## Overview

`TTMSMCPServerFactory.CreateFromObject` reflects over `TTMSMCPStellarDS` (from `TMS.MCP.StellarDS`) to build the server's tool set automatically. The component runs in synchronous mode (`moSync`) and authenticates against StellarDS using an access token supplied on the command line.

## Requirements

- Delphi 11.0 or later
- TMS AI Studio
- A TMS StellarDS access token

## Building

1. Open `StellarDSDemo.dproj` in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in `Win32\Debug` or `Win32\Release`.

## Running

```
StellarDSDemo -key <your-stellards-access-token>
```

The `-apikey` alias is also accepted. The server exits with an error if no access token is supplied.

## Setting up a client

The server communicates over STDIO, so any MCP client that supports STDIO transport can connect to it.

```json
{
  "mcpServers": {
    "stellards": {
      "command": "PATH_TO_EXE\\StellarDSDemo.exe",
      "args": ["-key", "YOUR_ACCESS_TOKEN"]
    }
  }
}
```
