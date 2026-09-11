object Form6: TForm6
  Left = 0
  Top = 0
  Margins.Left = 5
  Margins.Top = 5
  Margins.Right = 5
  Margins.Bottom = 5
  Caption = 'Visual app with MCP server bridge communication'
  ClientHeight = 835
  ClientWidth = 945
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -18
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 144
  TextHeight = 25
  object TMSFNCMemo1: TTMSFNCMemo
    Left = 0
    Top = 0
    Width = 945
    Height = 835
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Align = alClient
    ParentDoubleBuffered = False
    DoubleBuffered = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -18
    Font.Name = 'Consolas'
    Font.Style = []
    TabOrder = 0
    Options.WordWrap = wwtOff
    Options.WordWrapColumn = 80
    CompletionList = <>
    LanguageFileExtensionsMap = <
      item
        Language = mlBat
        Extension = '.bat'
      end
      item
        Language = mlCsharp
        Extension = '.cs'
      end
      item
        Language = mlCSS
        Extension = '.css'
      end
      item
        Language = mlHtml
        Extension = '.html'
      end
      item
        Language = mlJavascript
        Extension = '.js'
      end
      item
        Language = mlJSON
        Extension = '.json'
      end
      item
        Extension = '.pas'
      end
      item
        Extension = '.dpr'
      end
      item
        Extension = '.dfm'
      end
      item
        Extension = '.fmx'
      end
      item
        Extension = '.inc'
      end
      item
        Extension = '.dproj'
      end
      item
        Language = mlPlainText
        Extension = '.txt'
      end
      item
        Language = mlTypeScript
        Extension = '.ts'
      end
      item
        Language = mlXml
        Extension = '.xml'
      end>
    ActiveSource = -1
    Sources = <>
    ExplicitLeft = 156
    ExplicitTop = 96
    ExplicitWidth = 595
    ExplicitHeight = 579
  end
  object TMSMCPServer1: TTMSMCPServer
    Tools = <
      item
        Name = 'GetCodeTool'
        Description = 'Get code from editor'
        Properties = <>
        OnExecute = TMSMCPServer1Tools0Execute
        ReturnType = ptString
        ReadOnlyHint = False
        DestructiveHint = False
        IdempotentHint = False
        OpenWorldHint = False
      end
      item
        Name = 'SetCodeTool'
        Description = 'Set code in this editor'
        Properties = <
          item
            Name = 'code'
            PropertyType = ptString
            Required = False
            Description = 'code to insert'
          end>
        OnExecute = TMSMCPServer1Tools1Execute
        ReturnType = ptString
        ReadOnlyHint = False
        DestructiveHint = False
        IdempotentHint = False
        OpenWorldHint = False
      end>
    Resources = <>
    Prompts = <>
    Version = '1.0.0'
    Transport = TMSMCPNamedPipeTransport1
    Left = 288
    Top = 72
  end
  object TMSMCPNamedPipeTransport1: TTMSMCPNamedPipeTransport
    PipeName = 'MCPServer'
    DefaultTimeout = 5000
    Left = 516
    Top = 72
  end
end
