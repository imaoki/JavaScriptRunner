/*! © 2015 imaoki | MIT License | https://github.com/imaoki */
/**
JavaScriptを実行する。
@remarks
ECMAScript5に対応するためには`WebBrowser`のドキュメントモードが`11`以上でなければならない。
ドキュメントモードの明示的な指定は`Uri`プロパティに指定するHTMLに以下のような`meta`要素を記述する。

```html
<meta http-equiv='x-ua-compatible' content='ie=edge'>
```
*/
struct JavaScriptRunner (
  /**
  @prop <DotNetObject:System.Uri> JavaScriptを定義したHTMLファイルのURI。
  コンストラクタには文字列で指定すればよいが、インスタンス生成後は`SetUri`メソッドを使用して設定すること。
  */
  public Uri,

  /** @prop <String> 変数名に使用する一意の識別子。 */
  private id = "",
  /** @prop <String> イベントハンドラを格納するグローバル変数の名前。 */
  private handlerName = "",
  /** @prop <String> インスタンスを格納するグローバル変数の名前。 */
  private instanceName = "",

  /** @prop <DotNetObject:System.Windows.Forms.WebBrowser> */
  private webBrowser = DotNetObject "System.Windows.Forms.WebBrowser",

  /** @prop <Array<DataPair Callback:<MAXScriptFunction> Context:<Any>>> */
  private observers = #(),

  /**
  HTMLの読み込み完了を監視するオブザーバを登録する。
  @param observer <DataPair Callback:<MAXScriptFunction> Context:<Any>>
  `Callback`
  : 通知を受け取る関数。

  `Context`
  : オブザーバパターンにおける実装の一貫性のためのプロパティなので本クラスでは不要。
    指定する場合は以下のように使い分ける。

    構造体メソッドを使う場合
    : 構造体のインスタンスを指定する。

    独立した関数を使う場合
    : 不要であれば`undefined`を指定しておく。
  @return <BooleanClass> 成功もしくは既に存在する場合は`true`、失敗した場合は`false`。
  */
  public fn AddObserver observer = (
    local result = this.findObserver observer > 0
    if not result do (
      append this.observers observer
      result = this.findObserver observer > 0
    )
    result
  ),

  /**
  全てのオブザーバを取得する。
  @return <Array<DataPair Callback:<MAXScriptFunction> Context:<Any>>>
  */
  public fn GetObservers = (
    for observer in this.observers collect observer
  ),

  /**
  オブザーバを削除する。
  @param observer <DataPair Callback:<MAXScriptFunction> Context:<Any>>
  @return <BooleanClass> 成功もしくは存在しなかった場合は`true`、失敗した場合は`false`。
  */
  public fn RemoveObserver observer = (
    local index = this.findObserver observer
    local result = index == 0
    if not result do (
      deleteItem this.observers index
      result = this.findObserver observer == 0
    )
    result
  ),

  /**
  `Uri`のHTMLを読み込み、読み込みの完了をオブザーバに通知する。
  @return <OkClass>
  @remarks 実行時の大まかな処理の流れは以下のようになる。

  01. `JavaScriptRunner`のインスタンスを生成

  02. HTMLの読み込み完了を監視するオブザーバを登録

  03. `Activate`メソッドの呼び出し

  04. 非同期処理によりオブザーバが呼ばれる

  05. オブザーバの中で処理を開始する

  利用者側はオブザーバがエントリポイントとなるように設計しなければならない。
  具体的な実装例はテストを参照すること。
  */
  public fn Activate = (
    this.defineVariableNames()
    this.registerGlobals()

    local handler = GlobalVars.Get this.handlerName
    DotNet.AddEventHandler this.webBrowser "DocumentCompleted" handler

    if not this.isInstanceOfUri this.Uri do (
      this.SetUri this.Uri
    )

    if this.isInstanceOfUri this.Uri do (
      this.webBrowser.Navigate this.Uri
    )
    ok
  ),

  /**
  現在の内部状態を出力する。
  @param indent: <String>
  @param out: <FileStream|StringStream|WindowStream> 出力先。既定値は`listener`。
  @return <OkClass>
  */
  public fn Dump indent:"" out:listener = (
    format "%JavaScriptRunner\n" indent to:out
    if this.isInstanceOfUri this.Uri then (
      format "%  Uri:\"%\"\n" indent this.Uri.AbsoluteUri to:out
    )
    else (
      format "%  Uri:%\n" indent this.Uri to:out
    )
    format "%  id:\"%\"\n" indent this.id to:out
    format "%  handlerName:\"%\"\n" indent this.handlerName to:out
    format "%  instanceName:\"%\"\n" indent this.instanceName to:out

    format "%  webBrowser.Document:%\n" indent this.webBrowser.Document to:out
    format "%    documentMode:%\n" indent (this.GetDocumentMode()) to:out
    format "%    userAgent:\"%\"\n" indent (this.GetUserAgent()) to:out
    ok
  ),

  /**
  `eval`関数を実行する。
  @param js <String> JavaScriptコード。
  @return <Any>
  */
  public fn Eval js = (
    this.Invoke "eval" #(js)
  ),

  /**
  絶対URIを取得する。
  @return <String>
  */
  public fn GetAbsoluteUri = (
    local result = ""
    if this.isInstanceOfUri this.Uri do (
      result = this.Uri.AbsoluteUri
    )
    result
  ),

  /**
  `WebBrowser`のドキュメントモードを取得する。
  @return <Integer>
  */
  public fn GetDocumentMode = (
    this.Eval "document.documentMode;"
  ),

  /**
  `WebBrowser`のユーザエージェント文字列を取得する。
  @return <Integer>
  */
  public fn GetUserAgent = (
    this.Eval "navigator.userAgent;"
  ),

  /**
  `Uri`にて定義されたJavaScript関数を実行する。
  @param methodName <String> 関数名。
  @param arguments <Array<Any>> 関数に渡す引数。
  @return <Any> JavaScript関数の実行結果。
  */
  public fn Invoke methodName arguments = (
    this.webBrowser.Document.InvokeScript methodName arguments
  ),

  /**
  オブザーバにJavaScriptが実行可能になったことを通知する。
  @return <OkClass>
  */
  public fn Notify = (
    for observer in this.observers do (
      observer.Callback context:observer.Context
    )
    this.dispose()
    ok
  ),

  /**
  HTMLファイルのURIをセットする。
  @param uriString <String>
  @return <DotNetObject:System.Uri>
  */
  public fn SetUri uriString = (
    if classOf uriString == String then (
      this.Uri = DotNetObject "System.Uri" uriString
    )
    else (
      this.Uri = undefined
    )
    this.Uri
  ),

  /**
  イベントハンドラ、およびインスタンスの格納先となるグローバル変数の名前を決定する。
  @return <OkClass>
  */
  private fn defineVariableNames = (
    this.id = this.generateId()
    this.handlerName = this.id + "Handler"
    this.instanceName = this.id + "Instance"
    ok
  ),

  /**
  イベントハンドラの削除、およびグローバル変数の削除を行う。
  @return <OkClass>
  */
  private fn dispose = (
    DotNet.RemoveEventHandlers this.webBrowser "DocumentCompleted"
    this.unregisterGlobals()
    ok
  ),

  /**
  @param observer <DataPair Callback:<MAXScriptFunction> Context:<Any>>
  @return <Integer>
  */
  private fn findObserver observer = (
    local index = 0
    for i = 1 to this.observers.Count while index == 0 do (
      if this.observers[i].Callback == observer.Callback \
          and this.observers[i].Context == observer.Context do (
        index = i
      )
    )
    index
  ),

  /**
  システム時間を基に11桁の数字文字列を生成する。
  @return <String>
  */
  private fn generateId = (
    local systemTime = timeGetTime() as String
    local hashValue = abs (getHashValue ("JavaScriptRunner" + systemTime) 17)
    "javaScriptRunner" + formattedPrint hashValue format:"011d"
  ),

  /**
  @param obj <Any>
  @return <BooleanClass>
  */
  private fn isInstanceOfUri obj = (
    classOf obj == DotNetObject \
        and stricmp ((DotNet.GetType obj).ToString()) "System.Uri" == 0
  ),

  /**
  @return <OkClass>
  */
  private fn registerGlobals = (
    local code = StringStream ""
    format "global %\n" this.instanceName to:code
    format "global %\n" this.handlerName to:code
    format "fn % sender eventArgs = (\n" this.handlerName to:code
    format "  %.Notify()\n" this.instanceName to:code
    format ")" to:code
    code = code as String

    execute code
    GlobalVars.Set this.instanceName this
    ok
  ),

  /**
  @return <OkClass>
  */
  private fn unregisterGlobals = (
    local varNames = #(this.handlerName, this.instanceName)
    for varName in varNames do (
      if GlobalVars.IsGlobal varName do (
        GlobalVars.Set varName undefined
        GlobalVars.Remove varName
      )
    )
    ok
  ),

  on Create do (
    if classOf this.Uri == String do (
      this.SetUri this.Uri
    )
  )
)
