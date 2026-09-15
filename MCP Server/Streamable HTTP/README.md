# Streamable HTTP

An MCP server, built with `TMS.MCP.Server`, exposing the same `get_weather` tool as [Weather API](../Weather%20API/README.md) but over the Streamable HTTP transport, including optional TLS.

## Overview

The server geocodes a city name via OpenStreetMap and fetches current conditions from Open-Meteo through a single `get_weather` tool, with verbose console logging of each step. It's intended as a companion to the plain Weather API demo for comparing the Streamable HTTP and SSE transports side by side (see [SSE](../SSE/README.md)).

## Requirements

- Delphi 11.1 or later
- TMS AI Studio
- OpenSSL libraries on the `PATH` (only required when using `--ssl`)

## Building

1. Open `StreamableHttpServerDemo.dproj` in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in `Win32\Debug` or `Win32\Release`.

## Running

```
StreamableHttpServerDemo [options]
```

**Options:**

- `--port, -p <port>`           Port number (default: 8934)
- `--ssl, -s`                   Enable SSL/TLS
- `--cert, -c <file>` / `--key, -k <file>`   Certificate and key files (PEM)
- `--pfx <file>` / `--pfxpass <password>`    Certificate as PKCS#12/PFX
- `--help, -h`                  Show help

Examples:

```
StreamableHttpServerDemo
StreamableHttpServerDemo --ssl --cert server.crt --key server.key
StreamableHttpServerDemo --ssl --pfx server.pfx --pfxpass mypassword
```

## Setting up a client

Any MCP client that supports Streamable HTTP transport can connect to `http://localhost:<port>/mcp` (or `https://` when `--ssl` is used).
