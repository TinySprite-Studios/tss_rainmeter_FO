param(
  [Parameter(Mandatory = $true)]
  [string]$OutputPath
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-LuaResult {
  param(
    [bool]$Ok,
    [string]$Down = "N/A",
    [string]$Up = "N/A",
    [string]$Error = ""
  )

  $safeError = ($Error -replace "\\", "\\\\") -replace "'", "\\'"
  $safeDown = ($Down -replace "\\", "\\\\") -replace "'", "\\'"
  $safeUp = ($Up -replace "\\", "\\\\") -replace "'", "\\'"
  $content = @"
return {
  ok = $($Ok.ToString().ToLower()),
  down = '$safeDown',
  up = '$safeUp',
  error = '$safeError'
}
"@
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($OutputPath, $content, $utf8NoBom)
}

function Measure-DownloadMbps {
  param([int]$Seconds = 8)
  $url = "https://speed.cloudflare.com/__down?bytes=50000000"
  $deadline = (Get-Date).AddSeconds($Seconds)
  $bytes = 0L
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  while ((Get-Date) -lt $deadline) {
    $req = Invoke-WebRequest -Uri ($url + "&seed=" + [Guid]::NewGuid().ToString("N")) -UseBasicParsing -TimeoutSec 30
    $bytes += [int64]$req.RawContentLength
  }
  $sw.Stop()
  if ($sw.Elapsed.TotalSeconds -le 0) { return 0.0 }
  return [math]::Round((($bytes * 8.0) / $sw.Elapsed.TotalSeconds) / 1000000.0, 1)
}

function Measure-UploadMbps {
  param([int]$Seconds = 8)
  $url = "https://speed.cloudflare.com/__up"
  $payload = New-Object byte[] 10000000
  [System.Random]::new().NextBytes($payload)
  $deadline = (Get-Date).AddSeconds($Seconds)
  $uploaded = 0L
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  while ((Get-Date) -lt $deadline) {
    Invoke-WebRequest -Uri $url -Method POST -Body $payload -ContentType "application/octet-stream" -UseBasicParsing -TimeoutSec 30 | Out-Null
    $uploaded += [int64]$payload.Length
  }
  $sw.Stop()
  if ($sw.Elapsed.TotalSeconds -le 0) { return 0.0 }
  return [math]::Round((($uploaded * 8.0) / $sw.Elapsed.TotalSeconds) / 1000000.0, 1)
}

try {
  $down = Measure-DownloadMbps -Seconds 8
  $up = Measure-UploadMbps -Seconds 8
  Write-LuaResult -Ok $true -Down $down.ToString("0.0") -Up $up.ToString("0.0")
} catch {
  Write-LuaResult -Ok $false -Error $_.Exception.Message
}
