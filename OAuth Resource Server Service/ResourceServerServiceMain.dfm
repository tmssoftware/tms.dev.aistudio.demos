object ResourceServerService: TResourceServerService
  OldCreateOrder = False
  OnCreate = ServiceCreate
  OnDestroy = ServiceDestroy
  OnStart = ServiceStart
  OnStop = ServiceStop
  DisplayName = 'TMS MCP OAuth Resource Server (Demo)'
  Height = 543
  Width = 678
  PixelsPerInch = 144
end
