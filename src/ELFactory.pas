unit ELFactory;

interface

uses
  SysUtils, TypInfo, Rtti, Generics.Defaults, ElAst;

function GetElFactory: IExpressionFactory;
procedure CloseElFactory;

implementation

uses
  Dialogs, ElScanner, El, ElParser, ElUtils;

{$Region 'TExpressionFactory'}

type
  TExpressionFactory = class(TSingletonImplementation, IExpressionFactory)
  private
    class var Factory: TExpressionFactory;
    class destructor Destroy;
  private
    FContext: TELContext;
  public
    constructor Create;
    destructor Destroy; override;
    function GetContext: TELContext;
    function CreateValueExpression(const Expr: string; Node: TNode; ExpectedType: PTypeInfo): TValueExpression;
    function CreateMethodExpression(const Expr: string; ExpectedType: PTypeInfo; ParamTypes: array of PTypeInfo): TMethodExpression;
  end;

{$EndRegion}

{$Region 'TMyResolver'}

  TMyResolver = class(TElResolver)
  public
    function GetValue(Ctx: TElContext; Obj: TObject; const Prop: TValue): TValue; override;
  end;

{$EndRegion}

{$Region 'TMyContext'}

  TMyContext = class(TELContext)
  private
    FVarMap: TVariableMapper;
    FResolver: TElResolver;
  public
    constructor Create;
    destructor Destroy; override;
    function GetElResolver: TElResolver; override;
    function GetVariableMapper: TVariableMapper; override;
    function GetFunctionMapper: TFunctionMapper; override;
  end;

{$EndRegion}

{$Region 'TValueExpressionImpl'}

  TValueExpressionImpl = class(TValueExpression)
  private
    FExpectedType: PTypeInfo;
    FNode: TNode;
  public
    constructor Create(const Expr: string; Node: TNode; ExpectedType: PTypeInfo);
    destructor Destroy; override;
    function GetValue(Ctx: TElContext): TValue; override;
    procedure SetValue(Ctx: TElContext; Value: TValue); override;
    function IsReadOnly(Ctx: TElContext): Boolean; override;
    property ExpectedType: PTypeInfo read FExpectedType;
  end;

{$EndRegion}

function GetELFactory: IExpressionFactory;
begin
  Result := TExpressionFactory.Factory;
end;

procedure CreateDrawingFactory(CacheTable: TCachedExpression);
begin
  FreeAndNil(TExpressionFactory.Factory);
  TExpressionFactory.Factory.FContext.PutContext(TCachedExpression, CacheTable);
end;

procedure CloseElFactory;
begin
  FreeAndNil(TExpressionFactory.Factory);
end;

{ ExperssionFactory }

class destructor TExpressionFactory.Destroy;
begin
  FreeAndNil(Factory);
end;

constructor TExpressionFactory.Create;
begin
  inherited Create;
  FContext := TMyContext.Create;
end;

destructor TExpressionFactory.Destroy;
begin
  FContext.Free;
  inherited;
end;

function TExpressionFactory.GetContext: TElContext;
begin
  Result := FContext;
end;

function TExpressionFactory.CreateValueExpression(const Expr: string; Node: TNode; ExpectedType: PTypeInfo): TValueExpression;
begin
  Result := TValueExpressionImpl.Create(Expr, Node, ExpectedType);
end;

function TExpressionFactory.CreateMethodExpression(const Expr: string; ExpectedType: PTypeInfo; ParamTypes: array of PTypeInfo): TMethodExpression;
begin
  Result := nil;
end;

{ TMyContext }

constructor TMyContext.Create;
begin
  inherited Create;
  FVarMap := TVariableMapper.Create;
  FResolver := TMyResolver.Create;
end;

destructor TMyContext.Destroy;
begin
  FResolver.Free;
  FVarMap.Free;
  inherited;
end;

function TMyContext.GetElResolver: TElResolver;
begin
  Result := FResolver;
end;

function TMyContext.GetFunctionMapper: TFunctionMapper;
begin
  Result := nil;
end;

function TMyContext.GetVariableMapper: TVariableMapper;
begin
  Result := FVarMap;
end;

{ TValueExpression }

constructor TValueExpressionImpl.Create(const Expr: string; Node: TNode; ExpectedType: PTypeInfo);
begin
  inherited Create(Expr);
  FNode := Node;
  FExpectedType := ExpectedType;
end;

destructor TValueExpressionImpl.Destroy;
begin
  FNode.Free;
  inherited;
end;

function TValueExpressionImpl.GetValue(Ctx: TElContext): TValue;
begin
  if FNode = nil then
    Result := ''
  else
  begin
    Result := FNode.GetValue(Ctx);
    if ExpectedType <> nil then
      Result := VM.CoerceToType(Result, ExpectedType);
  end;
end;

function TValueExpressionImpl.IsReadOnly(Ctx: TElContext): Boolean;
begin
  Result := FNode.IsReadOnly(Ctx);
end;

procedure TValueExpressionImpl.SetValue(Ctx: TElContext; Value: TValue);
begin
  FNode.SetValue(Ctx, Value);
end;

{ TMyResolver }

function TMyResolver.GetValue(Ctx: TElContext; Obj: TObject; const Prop: TValue): TValue;
var
  s: string;
begin
  Result := Prop;
  if Ctx is TMyContext then
  begin
    Ctx.PropertyResolved := True;
    s := LowerCase(Prop.AsString);
    if s = 'MyFunc' then
      Result := TMyContext(Ctx).GetMyFunc + 1
    else if s = 'count' then
      Result := TMyContext(Ctx).GetCount
    else
    begin
      Ctx.PropertyResolved := False;
      Result := Prop;
    end;
  end;
end;


end.

