object AuthServerService: TAuthServerService
  OldCreateOrder = False
  OnCreate = ServiceCreate
  OnDestroy = ServiceDestroy
  OnStart = ServiceStart
  OnStop = ServiceStop
  DisplayName = 'TMS MCP OAuth Authorization Server (Demo)'
  Height = 543
  Width = 678
  PixelsPerInch = 144
end
