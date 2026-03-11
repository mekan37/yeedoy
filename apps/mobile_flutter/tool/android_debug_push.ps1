param(
  [string]$DeviceId = "",
  [ValidateSet("price-change", "review-reply", "business-alert", "profile")]
  [string]$Sample = "price-change",
  [string]$PackageName = "com.yeedoy.app",
  [string]$BusinessId = "11111111-1111-4111-8111-111111111111",
  [string]$MenuItemId = "33333333-3333-4333-8333-333333333333",
  [string]$TargetPath = ""
)

function Resolve-AdbPath {
  $candidates = @()

  $adbCommand = Get-Command adb -ErrorAction SilentlyContinue
  if ($adbCommand) {
    $candidates += $adbCommand.Source
  }
  if ($env:ANDROID_HOME) {
    $candidates += Join-Path $env:ANDROID_HOME "platform-tools\\adb.exe"
  }
  if ($env:ANDROID_SDK_ROOT) {
    $candidates += Join-Path $env:ANDROID_SDK_ROOT "platform-tools\\adb.exe"
  }
  if ($env:LOCALAPPDATA) {
    $candidates += Join-Path $env:LOCALAPPDATA "Android\\Sdk\\platform-tools\\adb.exe"
  }
  if ($env:USERPROFILE) {
    $candidates += Join-Path $env:USERPROFILE "AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe"
  }

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  throw "adb.exe bulunamadi. PATH veya ANDROID_HOME/ANDROID_SDK_ROOT ayarlarini kontrol edin."
}

$adb = Resolve-AdbPath
$component = "$PackageName/.MainActivity"
$adbArgs = @()

if ($DeviceId.Trim()) {
  $adbArgs += @("-s", $DeviceId)
}

$adbArgs += @(
  "shell",
  "am",
  "start",
  "-n",
  $component,
  "-a",
  "$PackageName.DEBUG_PUSH",
  "--ez",
  "yeedoy_debug_push",
  "true"
)

switch ($Sample) {
  "price-change" {
    $adbArgs += @(
      "--es",
      "type",
      "favorite_price_changed",
      "--es",
      "business_id",
      $BusinessId,
      "--es",
      "menu_item_id",
      $MenuItemId
    )
  }
  "review-reply" {
    $adbArgs += @(
      "--es",
      "type",
      "review_reply",
      "--es",
      "business_id",
      $BusinessId
    )
  }
  "business-alert" {
    $adbArgs += @(
      "--es",
      "type",
      "owner_business_reported",
      "--es",
      "business_id",
      $BusinessId
    )
  }
  "profile" {
    $adbArgs += @(
      "--es",
      "type",
      "achievement_unlocked"
    )
  }
}

if ($TargetPath.Trim()) {
  $adbArgs += @("--es", "target_path", $TargetPath)
}

Write-Host ($adb + " " + ($adbArgs -join " "))
& $adb @adbArgs

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
