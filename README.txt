・Webwatch 使い方

	1. 任意の場所にzip解凍して、webwatchフォルダーを開いてください。
	2. webwatch.ps1を右クリックで「Powershellで実行」を選択すると起動します。
	3. または PowerShellを起動し、コマンド ”PowerShell -ExecutionPolicy Bypass [webwatch.ps1のファイルパス]”を入力して起動する。

		1) 起動の時に一回Listを全部チェックします。
		2) チェック間隔により画面に次回チェック時間が表示される。
		3) チェックしたログはwebwatch_log内に保存される。
		4) webwatch.ps1を起動した時には7日より前のログの削除処理を行います。



・設定
	1. webwatchフォルダー配下のsetting.ini

		1) interval=[数字]でチェック間隔を指定できます。
			1> 記入なしだとデフォルトinterval=5になります。

		2) sound=[音声ファイルのパス]でアラートに流す音声を指定できます。
			1> 記入なしだとデフォルトsound=C:\windows\Media\Alarm05.wavになります。

	2. webwatchフォルダー配下のlist.ini

		1) チェックしたいWebサイトを
		   [ラベル]
		   URL = http://example.com　の形式で記入してください。
