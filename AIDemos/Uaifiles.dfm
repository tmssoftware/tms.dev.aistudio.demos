object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Use of files with the LLM'
  ClientHeight = 605
  ClientWidth = 858
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 21
  object Memo2: TMemo
    Left = 0
    Top = 353
    Width = 858
    Height = 252
    Align = alClient
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 858
    Height = 353
    Align = alTop
    TabOrder = 1
    DesignSize = (
      858
      353)
    object Label1: TLabel
      Left = 4
      Top = 231
      Width = 171
      Height = 21
      Anchors = [akLeft, akBottom]
      Caption = 'Prompt that will use files'
    end
    object ComboBox1: TComboBox
      Left = 4
      Top = 11
      Width = 162
      Height = 29
      Style = csDropDownList
      TabOrder = 0
      OnChange = ComboBox1Change
    end
    object Memo1: TMemo
      AlignWithMargins = True
      Left = 4
      Top = 260
      Width = 850
      Height = 89
      Align = alBottom
      Lines.Strings = (
        'Can you give a one paragraph summary of files you have?')
      TabOrder = 1
    end
    object Button1: TButton
      Left = 172
      Top = 9
      Width = 92
      Height = 31
      Caption = 'Get files'
      TabOrder = 2
      OnClick = Button1Click
    end
    object ProgressBar1: TProgressBar
      Left = 288
      Top = 15
      Width = 281
      Height = 17
      Smooth = True
      Style = pbstMarquee
      SmoothReverse = True
      State = pbsPaused
      TabOrder = 3
    end
    object ListView1: TListView
      Left = 4
      Top = 54
      Width = 844
      Height = 168
      Anchors = [akLeft, akTop, akRight, akBottom]
      Columns = <
        item
          Caption = 'ID'
          Width = 250
        end
        item
          Caption = 'Displayname'
          Width = 150
        end
        item
          Caption = 'Size'
          Width = 100
        end
        item
          Caption = 'Mime type'
          Width = 200
        end>
      RowSelect = True
      TabOrder = 4
      ViewStyle = vsReport
      OnChange = ListView1Change
    end
    object btnAdd: TButton
      Left = 596
      Top = 9
      Width = 92
      Height = 31
      Caption = 'Add'
      Enabled = False
      TabOrder = 5
      OnClick = btnAddClick
    end
    object btnDelete: TButton
      Left = 694
      Top = 9
      Width = 92
      Height = 31
      Caption = 'Delete'
      Enabled = False
      TabOrder = 7
      OnClick = btnDeleteClick
    end
    object btnExec: TButton
      Left = 192
      Top = 226
      Width = 92
      Height = 31
      Caption = 'Execute'
      TabOrder = 6
      OnClick = btnExecClick
    end
  end
  object TMSMCPCloudAI1: TTMSMCPCloudAI
    Service = aiOpenAI
    Settings.GeminiModel = 'gemini-2.5-flash'
    Settings.OpenAIModel = 'gpt-5.4-mini-2026-03-17'
    Settings.OpenAISoundModel = 'gpt-4o-mini-tts'
    Settings.OpenAITranscribeModel = 'whisper-1'
    Settings.GrokModel = 'grok-4-1-fast-reasoning'
    Settings.ClaudeModel = 'claude-sonnet-4-6'
    Settings.OllamaModel = 'llama3.2:latest'
    Settings.DeepSeekModel = 'deepseek-chat'
    Settings.PerplexityModel = 'sonar-pro'
    Settings.OllamaHost = 'localhost'
    Settings.OllamaPath = '/api/chat'
    Settings.LlamaCppHost = 'localhost'
    Settings.LlamaCppPath = '/v1/chat/completions'
    Settings.MistralModel = 'mistral-large-latest'
    Settings.MistralTranscribeModel = 'voxtral-mini-2507'
    Tools = <>
    OnExecuted = TMSMCPCloudAI1Executed
    OnGetFiles = TMSMCPCloudAI1GetFiles
    OnFileUpload = TMSMCPCloudAI1FileUpload
    Left = 448
    Top = 24
  end
  object OpenDialog1: TOpenDialog
    Filter = 
      'Text files|*.txt|CSV files|*..csv|PDF files|*.pdf|DOC files|*.do' +
      'c|Image files|*.jpg;*.jpeg;*.png;*.gif;*.webp;*.bmp|All files|*.' +
      '*'
    Left = 800
    Top = 8
  end
end
