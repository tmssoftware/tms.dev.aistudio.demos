# OAuth Resource

An MCP server, built with `TMS.MCP.Server` over the Streamable HTTP transport and packaged as a Windows Service, that requires a valid OAuth bearer token on every request (`RequireBearerAuthentication`), per the MCP Authorization specification. It validates tokens by calling the [OAuth Authorization](../OAuth%20Authorization/README.md) server's RFC 7662 introspection endpoint, so the two must be run together — this is the one demo in the OAuth pair that also uses `TMS.MCP.Server` directly.

## Overview

The server exposes a tiny per-session notes API — `list_notes`, `add_note`, `delete_note` — scoped to the calling MCP session, so each connected client only ever sees its own notes. On every request, `TDemoAuthHandlers.ValidateAccessToken` calls the Authorization Server's `/introspect` endpoint and checks:

- the token is `active`
- the token's `aud` (audience) matches this resource's URI (audience binding, per the MCP Authorization spec's access-token-privilege-restriction requirement)

Only then is the request allowed through, with the token's `scope` and `sub` (subject) made available to the server.

## Requirements

- Delphi 11.0 or later
- TMS AI Studio
- A running [OAuth Authorization](../OAuth%20Authorization/README.md) server instance

## Building

1. Open `OAuthResourceServerService.dproj` in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).

## Configuration

Settings are read from an INI file next to the service executable (same base name, `.ini` extension):

```ini
[Server]
Port=8934
MCPEndpoint=/mcp
UseSSL=0
CertFile=
KeyFile=
KeyPassword=
PublicHost=
AuthorizationServerIssuer=http://localhost:9000

[Logging]
LogFile=
```

`AuthorizationServerIssuer` must point at a running [OAuth Authorization](../OAuth%20Authorization/README.md) server. If `LogFile` is left blank, it defaults to the executable's own name with a `.log` extension.

## Installing and running

Start the [OAuth Authorization](../OAuth%20Authorization/README.md) server first, then from an elevated command prompt:

```
OAuthResourceServerService.exe /install
net start "TMS MCP OAuth Resource Server"
```

To remove it:

```
net stop "TMS MCP OAuth Resource Server"
OAuthResourceServerService.exe /uninstall
```

## Setting up a client

A real MCP client that supports the MCP Authorization flow (dynamic client registration, PKCE, bearer tokens) is required — plain STDIO/HTTP clients without OAuth support cannot call this server. Point it at `http://localhost:<port>/mcp`; it will be redirected through the Authorization Server's discovery, registration, and consent flow before being issued a token.
