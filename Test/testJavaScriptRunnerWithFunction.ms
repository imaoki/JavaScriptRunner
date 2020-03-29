/*! © 2020 imaoki | MIT License | https://github.com/imaoki */
global activated
fn activated context: = (
  assert (context == undefined)
  ::unitTest.InvokeTest()
  ok
)

struct TestStruct (
  public CurrentDir,
  public CurrentFile,
  public ParentDir,

  private actual,
  private expected,
  private testDef,
  private testObj,

  private dummyHtml,
  private sumHtml,

  private activatedObserver,
  private dummyObserver,

  public fn Setup = (
    ok
  ),

  public fn SetupStruct = (
    this.dummyHtml = this.CurrentDir + @"\dummy.html"
    this.sumHtml = this.CurrentDir + @"\sum.html"

    this.activatedObserver = DataPair Callback:::activated Context:undefined
    this.dummyObserver = DataPair Callback:this.DummyCallback Context:undefined

    this.testDef = ::unitTest.Import (this.ParentDir + @"\JavaScriptRunner.ms")
    this.testObj = this.testDef Uri:this.sumHtml

    this.testObj.AddObserver this.activatedObserver
    this.testObj.Activate()
    ok
  ),

  public fn Teardown = (
    ok
  ),

  public fn TeardownStruct = (
    -- this.testObj.Dump()
    ok
  ),

  public fn Test01AddObserver = (
    this.actual = ::TestValue (this.testObj.AddObserver this.dummyObserver)
    assert (this.actual.IsBoolean() == true)
    assert (this.actual.Value == true)
    ok
  ),

  public fn Test02GetObservers = (
    this.actual = ::TestValue (this.testObj.GetObservers())
    this.expected = ::TestValue #(this.activatedObserver, this.dummyObserver)
    assert (this.actual.Equals this.expected == true)
    ok
  ),

  public fn Test03RemoveObserver = (
    this.actual = ::TestValue (this.testObj.RemoveObserver this.dummyObserver)
    assert (this.actual.IsBoolean() == true)
    assert (this.actual.Value == true)

    this.actual = ::TestValue (this.testObj.GetObservers())
    this.expected = ::TestValue #(this.activatedObserver)
    assert (this.actual.Equals this.expected == true)
    ok
  ),

  public fn Test04SetUri = (
    -- Uriの設定
    this.actual = ::TestValue (this.testObj.SetUri this.dummyHtml)
    this.expected = ::TestValue (DotNetObject "System.Uri" this.dummyHtml)
    assert (this.actual.IsDotNetObject() == true)
    assert (this.actual.Value.Equals this.expected.Value)

    -- Uriを元に戻す
    this.actual = ::TestValue (this.testObj.SetUri this.sumHtml)
    this.expected = ::TestValue (DotNetObject "System.Uri" this.sumHtml)
    assert (this.actual.IsDotNetObject() == true)
    assert (this.actual.Value.Equals this.expected.Value)
    ok
  ),

  public fn Test05GetAbsoluteUri = (
    -- Uriの取得
    this.actual = ::TestValue (this.testObj.GetAbsoluteUri())
    this.expected = ::TestValue (DotNetObject "System.Uri" this.sumHtml).AbsoluteUri
    assert (this.actual.Equals this.expected == true)
    ok
  ),

  public fn Test06GetDocumentMode = (
    -- ドキュメントモードの取得
    this.actual = ::TestValue (this.testObj.GetDocumentMode())
    this.expected = ::TestValue 11.0d0
    assert (this.actual.Equals this.expected == true)
    ok
  ),

  public fn Test07GetUserAgent = (
    -- ユーザエージェントの取得
    this.actual = ::TestValue (this.testObj.GetUserAgent())
    assert (this.actual.IsString() == true)
    ok
  ),

  public fn Test08Eval = (
    -- `eval`関数の利用
    this.actual = ::TestValue (this.testObj.Eval "1 + 1;")
    this.expected = ::TestValue 2
    assert (this.actual.Equals this.expected == true)
    ok
  ),

  public fn Test09Invoke = (
    -- JavaScript関数の実行
    this.actual = ::TestValue (this.testObj.Invoke "sum" #(1, 1))
    -- format "actual:%\n" this.actual.Value
    this.expected = ::TestValue 2
    assert (this.actual.Equals this.expected == true)
    ok
  ),

  public fn DummyCallback context: = (
    ok
  ),

  on Create do (
    this.CurrentFile = ::unitTest.GetFullPath (getSourceFileName())
    this.CurrentDir = ::unitTest.GetDirectoryName this.CurrentFile
    this.ParentDir = ::unitTest.GetDirectoryName this.CurrentDir
  )
)

::unitTest.Run (::TestStruct())
