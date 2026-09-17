# Weather API

A minimal MCP server exposing a single `get_weather` tool, built with `TMS.MCP.Server`. The same tool is implemented three times, one per transport, so you can compare them side by side: STDIO (`WeatherApiSTDIODemo`), SSE (`WeatherApiSSEDemo`), and Streamable HTTP (`WeatherApiStreamableHTTPDemo`). Start here if you're new to the TMS MCP SDK.

## Overview

Each variant exposes a `get_weather` tool that geocodes a city name via the OpenStreetMap API and fetches current conditions from the Open-Meteo API.

- **WeatherApiSTDIODemo** — the simplest of the three: STDIO transport, plus an optional `units` parameter (`celsius`/`fahrenheit`) on the tool itself.
- **WeatherApiSSEDemo** and **WeatherApiStreamableHTTPDemo** — identical to each other apart from transport. Both add verbose console logging of each request and geocoding/weather lookup step, a configurable port, and optional TLS (self-signed cert/key files or a PFX).

## Requirements

- Delphi 11.1 or later
- TMS AI Studio
- OpenSSL libraries on the `PATH` (only required when using `--ssl` with the SSE or Streamable HTTP variant)

## Building

Open the corresponding `.dproj` in your Delphi IDE and build it (Shift+F9 or Run → Build). The compiled executable is written to `Win32\Debug` or `Win32\Release`.

## Running the SSE / Streamable HTTP variants

```
WeatherApiSSEDemo [options]
WeatherApiStreamableHTTPDemo [options]
```

**Options:**

- `--port, -p <port>`           Port number (default: 8934)
- `--ssl, -s`                   Enable SSL/TLS
- `--cert, -c <file>` / `--key, -k <file>`   Certificate and key files (PEM)
- `--pfx <file>` / `--pfxpass <password>`    Certificate as PKCS#12/PFX
- `--help, -h`                  Show help

Examples:

```
WeatherApiSSEDemo
WeatherApiSSEDemo --ssl --cert server.crt --key server.key
WeatherApiSSEDemo --ssl --pfx server.pfx --pfxpass mypassword
```

The STDIO variant takes no command-line options; the `units` parameter is passed as a tool argument instead.

## Setting up a client

### STDIO (`WeatherApiSTDIODemo`)

Any MCP client that supports STDIO transport can connect directly.

**Claude for Desktop** — add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "weather": {
      "command": "PATH_TO_EXE\\WeatherApiSTDIODemo.exe"
    }
  }
}
```

**MCP Inspector:**

```bash
npx @modelcontextprotocol/inspector PATH_TO_EXE\WeatherApiSTDIODemo.exe
```

### SSE (`WeatherApiSSEDemo`)

Any MCP client that supports SSE transport can connect to `http://localhost:<port>/sse` (or `https://` when `--ssl` is used).

### Streamable HTTP (`WeatherApiStreamableHTTPDemo`)

Any MCP client that supports Streamable HTTP transport can connect to `http://localhost:<port>/mcp` (or `https://` when `--ssl` is used).
