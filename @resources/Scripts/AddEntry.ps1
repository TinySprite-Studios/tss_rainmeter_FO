param(
  [Parameter(Mandatory=$true)][string]$Mode,
  [Parameter(Mandatory=$true)][string]$Menu,
  [Parameter(Mandatory=$true)][string]$PendingConfig
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

function Prompt-Name([string]$defaultName){
  $name = [Microsoft.VisualBasic.Interaction]::InputBox('Display name for this entry:', 'Add Entry', $defaultName)
  if([string]::IsNullOrWhiteSpace($name)){ return $null }
  return $name.Trim()
}

function Resolve-UrlFromInternetShortcut([string]$path){
  try {
    $line = Get-Content -Path $path | Where-Object { $_ -match '^URL=' } | Select-Object -First 1
    if($line){ return $line.Substring(4) }
  } catch {}
  return $null
}

function Escape-LuaString([string]$s){
  if($null -eq $s){ return '' }
  $s = $s.Replace('\', '\\')
  $s = $s.Replace("`r", '\r').Replace("`n", '\n')
  $s = $s.Replace("'", "\'")
  return $s
}

$item = $null

switch($Mode.ToLowerInvariant()){
  'submenu' {
    $name = [Microsoft.VisualBasic.Interaction]::InputBox('Submenu name:', 'Add Submenu', 'New Submenu')
    if([string]::IsNullOrWhiteSpace($name)){ exit 0 }
    $name = $name.Trim()
    $menuEsc = Escape-LuaString $Menu
    $nameEsc = Escape-LuaString $name
    $lua = @"
return {
  op = 'create_submenu',
  menu = '$menuEsc',
  name = '$nameEsc'
}
"@
    $dir = Split-Path -Parent $PendingConfig
    if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($PendingConfig, $lua, $utf8NoBom)
    exit 0
  }
  'folder' {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Select folder to add'
    $dlg.ShowNewFolderButton = $false
    if($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK){ exit 0 }
    $target = $dlg.SelectedPath
    $defaultName = Split-Path -Leaf $target
    if([string]::IsNullOrWhiteSpace($defaultName)){ $defaultName = $target }
    $name = Prompt-Name $defaultName
    if($null -eq $name){ exit 0 }
    $item = [ordered]@{ type='launch'; text=$name; target=$target; status=("OPEN " + $name) }
  }
  'program' {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Select program or shortcut to add'
    $dlg.Filter = 'Programs and shortcuts|*.exe;*.lnk;*.bat;*.cmd;*.url|All files|*.*'
    $dlg.Multiselect = $false
    if($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK){ exit 0 }
    $sel = $dlg.FileName
    $target = $sel
    if([IO.Path]::GetExtension($sel).ToLowerInvariant() -eq '.url'){
      $u = Resolve-UrlFromInternetShortcut $sel
      if(-not [string]::IsNullOrWhiteSpace($u)){ $target = $u }
    }
    $defaultName = [IO.Path]::GetFileNameWithoutExtension($sel)
    $name = Prompt-Name $defaultName
    if($null -eq $name){ exit 0 }
    $item = [ordered]@{ type='launch'; text=$name; target=$target; status=("OPEN " + $name) }
  }
  'link' {
    $url = [Microsoft.VisualBasic.Interaction]::InputBox('Enter web link (https://...)', 'Add Web Link', 'https://')
    if([string]::IsNullOrWhiteSpace($url)){ exit 0 }
    $url = $url.Trim()
    if(-not ($url -match '^https?://')){ $url = 'https://' + $url }
    $name = [Microsoft.VisualBasic.Interaction]::InputBox('Display name for this link:', 'Add Web Link', $url)
    if([string]::IsNullOrWhiteSpace($name)){ exit 0 }
    $item = [ordered]@{ type='launch'; text=$name.Trim(); target=$url; status=("OPEN " + $name.Trim()) }
  }
  default { exit 1 }
}

$dir = Split-Path -Parent $PendingConfig
if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }

$menuEsc = Escape-LuaString $Menu
$textEsc = Escape-LuaString ([string]$item.text)
$targetEsc = Escape-LuaString ([string]$item.target)
$statusEsc = Escape-LuaString ([string]$item.status)
$lua = @"
return {
  menu = '$menuEsc',
  item = {
    type = 'launch',
    text = '$textEsc',
    target = '$targetEsc',
    status = '$statusEsc'
  }
}
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($PendingConfig, $lua, $utf8NoBom)
exit 0
