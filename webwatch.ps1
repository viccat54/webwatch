function GetIniContent($filePath) {

    $ini = [ordered]@{}

    switch -regex -file $filePath {
        "^\[(.+)\]" {
            $section = $matches[1]
            $ini[$section] = @{}
        }
        "(.+?)\s*=(.*)" {
            $name, $value = $matches[1..2]
            if($section -eq $null) {
                $section = "Default"
                $ini[$section] = @{}
            }
            $ini[$section][$name] = $value
        }
    }

    return $ini
}

function checkFile($file) {
    if(-not(Test-Path $file -PathType Leaf)) {
        New-Item $file -type file
    }
}

function checkPath($path) {
    if(-not(Test-Path $path -PathType Container)) {
        New-Item $path -Type Directory
    }
}

function deleteOldLog($currentPath) {
    $logPath = "$currentPath\webwatch_log\"

    if(Test-Path $logPath -PathType Container) {
        $ago7d = (Get-Date).AddDays(-7)
        $folders = Get-ChildItem $logPath
        foreach($folder in $folders){
            $f_time = Get-Date $(Get-Date -Format "$folder 00:00")
            if ($f_time -lt $ago7d) {
                Remove-Item -Path $folder.FullName -Recurse
            }
        }
    }
}

# Log Path
$ymd = Get-Date -Format "yyyy-MM-dd"
$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = "$currentPath\webwatch_log\$ymd\"
checkPath($logPath)
deleteOldLog($currentPath)

# setting Path
$settingPath = "$currentPath\setting.ini"
checkFile($settingPath)
$setting = GetIniContent($settingPath)

# List Path
$listPath = "$currentPath\list.ini"


# 自己証明書対応(このスクリプトの中だけで変わることは確認済み)
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# ベース時間
$t = Get-Date -Format "yyyy/MM/dd HH:00"
$basetime = Get-Date $t

# 間隔　m分
if ($setting.Default.interval -eq $null) {
    $interval = 5
    "interval=5" | Out-File -Append -FilePath $settingPath -Encoding utf8
} else {
    $interval = $setting.Default.interval
}

while (($basetime) -lt (Get-Date)){
    $basetime = $basetime.AddMinutes($interval)
}

# Invoke-WebRequest の progress 表示 off
$progressPreference = 'silentlyContinue'

# sound 設定
if ($setting.Default.sound -eq $null) {
    $soundPath = "C:\windows\Media\Alarm05.wav"
    "sound=C:\windows\Media\Alarm05.wav" | Out-File -Append -FilePath $settingPath -Encoding utf8
} else {
    $soundPath = $setting.Default.sound
}

$sound = New-Object System.Media.SoundPlayer $soundPath

#### 単純疎通確認




while(1){
    checkPath($logPath)
    checkFile($settingPath)
    checkFile($listPath)

    #Setting 取得
    $setting = GetIniContent($settingPath)
    $check_list = GetIniContent($listPath)

    Clear-Host
    Write-Output "PowerShell Version: $($PSVersionTable.PSVersion)"

    $playAlert = $false;
    $sound.Stop()

    foreach($name in $check_list.keys) {

        $time = (Get-Date).ToString("yyyy-MM-dd")
        $logFile = "{0}{1}_{2}.log" -f $logPath, $name, $time
        $logMsg = ""

        $message = "[{0}] {1}" -f $name, $check_list[$name].URL

        Write-Output "----" 
        try{
            $resopnse = Invoke-WebRequest -Uri $check_list[$name].URL -UseBasicParsing -TimeoutSec 5 -EA Stop
            Write-Host -BackgroundColor DarkGreen -ForegroundColor White -NoNewline -Object " OK  "
            Write-Output " $(Get-Date -Format g) $message"
            Write-Host -BackgroundColor DarkGreen -ForegroundColor White -Object " $($resopnse.StatusCode) "
            $logMsg = "OK $(Get-Date -Format g) $message $($resopnse.StatusCode)"
        } catch{
            $playAlert = $true;
            Write-Host -BackgroundColor Red -ForegroundColor White -NoNewline -Object " NG  "
            Write-Output " $(Get-Date -Format g) $message"
            Write-Host -BackgroundColor Red -ForegroundColor White -Object " $($_.Exception.Response.StatusCode.Value__) "
            $logMsg = "NG $(Get-Date -Format g) $message $($_.Exception.Response.StatusCode.Value__)"
        }

        $logMsg | Out-File -Append -FilePath $LogFile -Encoding utf8
    }

    if ($playAlert) {
        $sound.PlayLooping();
    }

    # 待機
    Write-Output "次回チェック時間: $basetime"
    sleep (($basetime) - (Get-Date)).TotalSeconds;

    $basetime = $basetime.AddMinutes($interval)
}

# Invoke-WebRequest の progress 表示 on
$progressPreference = 'Continue'

