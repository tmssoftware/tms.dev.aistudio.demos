unit Calculator;

interface

uses
  System.SysUtils,
  System.Rtti,
  Rest.JSONReflect,
  System.Classes,
  TMS.MCP.Attributes, TMS.MCP.Tools;

type
  TTestInner = class(TPersistent)
  private
    FStreet: string;
    FCity: string;
    procedure SetCity(const Value: string);
    procedure SetStreet(const Value: string);
  published
    property Street: string read FStreet write SetStreet;
    property City: string read FCity write SetCity;
  end;

   TTest = class(TPersistent)
  private
    Fname: string;
    Femail: string;
    Faddresses: TArray<TTestInner>;
    procedure Setemail(const Value: string);
    procedure Setname(const Value: string);
    procedure Setaddresses(const Value: TArray<TTestInner>);
   public
    Constructor Create;
    Destructor Destroy;

   published
      property name: string read Fname write Setname;
      property email: string read Femail write Setemail;
      property addresses: TArray<TTestInner> read Faddresses write Setaddresses;

   end;

  TStringArray = array of string;

  TCustomCalculatorServer = class(TPersistent)
  public
    [TTMSMCPTool]
    function ping(atest: TTest): TTest;

    [TTMSMCPTool]
    procedure ExportToPDF(AFileName: string; AOpenInPDFReader: Boolean);

    [TTMSMCPTool]
    function test(aArray: TStrings): TStringList;

    [TTMSMCPTool]
    function test2(aArray: TStringArray): TStringArray;

    [TTMSMCPTool]
    [TTMSMCPName('add')]
    [TTMSMCPDescription('add 2 numbers together')]
    [TTMSMCPInteger]
    function UnnamedFunction([TTMSMCPInteger] a, [TTMSMCPInteger] b: Integer): Integer;

    [TTMSMCPTool]
    function Subtract(a, b: Double): Double;

    [TTMSMCPTool]
    [TTMSMCPFloat]
    [TTMSMCPName('test')]
    function Multiply(
      [TTMSMCPFloat][TTMSMCPName('test')]a: Double;
      [TTMSMCPOptional] b: Double = 5): Double;

    [TTMSMCPTool]
    [TTMSMCPIdemPotent] // Idempotent operation
    function Divide(a, b: Double): Double;

    [TTMSMCPTool]
    [TTMSMCPName('sqrt')]
    [TTMSMCPDescription('Calculate square root of a number')]
    [TTMSMCPFloat]
    function SquareRoot([TTMSMCPName('value')] a: Double): Double;


  end;

  TCalculatorServer = class(TCustomCalculatorServer);

{ TCalculatorServer }
implementation

function TCustomCalculatorServer.UnnamedFunction(a, b: Integer): Integer;
begin
  Result := a + b;

end;

function TCustomCalculatorServer.Subtract(a, b: Double): Double;
begin
  Result := a - b;

end;

function TCustomCalculatorServer.test(aArray: TStrings):TStringList;
begin
  Result := TStringList(aArray);
end;

function TCustomCalculatorServer.test2(aArray:TStringArray): TStringArray;
begin
  Result := ['test'];
end;


procedure TCustomCalculatorServer.ExportToPDF(AFileName: string;
  AOpenInPDFReader: Boolean);
begin

end;

function TCustomCalculatorServer.Multiply(a, b: Double): Double;
begin
  Result := a * b;

end;

function TCustomCalculatorServer.ping(atest: TTest): TTest;
var
  a: TTestInner;
  ad: TArray<TTestInner>;
begin
  Result := TTest.Create;
  Result.name := 'Bradley';
  ad := result.addresses;
  SetLength(ad, 2);
  a := TTestInner.Create;
  a.FStreet := 'test';
  ad[0] := a;

  result.addresses := ad;
end;

function TCustomCalculatorServer.Divide(a, b: Double): Double;
begin
  if b = 0 then
    raise Exception.Create('Division by zero is not allowed');

  Result := a / b;

end;

function TCustomCalculatorServer.SquareRoot(a: Double): Double;
begin
  if a < 0 then
    raise Exception.Create('Cannot calculate square root of negative number');

  Result := Sqrt(a);

end;

{ TTest }

constructor TTest.Create;
begin
  inherited Create;
  Faddresses := TArray<TTestInner>.Create();
end;

destructor TTest.Destroy;
begin
  //Faddresses;
  inherited;
end;

procedure TTest.Setaddresses(const Value: TArray<TTestInner>);
begin
  Faddresses := Value;
end;

procedure TTest.Setemail(const Value: string);
begin
  Femail := Value;
end;

procedure TTest.Setname(const Value: string);
begin
  Fname := Value;
end;

{ TTestInner }

procedure TTestInner.SetCity(const Value: string);
begin
  FCity := Value;
end;

procedure TTestInner.SetStreet(const Value: string);
begin
  FStreet := Value;
end;

end.
