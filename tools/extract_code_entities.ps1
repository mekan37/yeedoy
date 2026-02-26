$targets = @("lib", "qr_menu_next/src", "qr_menu_next/app")
$files = Get-ChildItem -Path $targets -Recurse -File -Include *.dart,*.ts,*.tsx

$tables = New-Object System.Collections.Generic.HashSet[string]
$rpcs = New-Object System.Collections.Generic.HashSet[string]

foreach ($f in $files) {
  $txt = Get-Content -Raw -LiteralPath $f.FullName

  $fromMatches = [regex]::Matches($txt, "from\(\s*'([^']+)'\s*\)")
  foreach ($m in $fromMatches) {
    [void]$tables.Add($m.Groups[1].Value)
  }

  $rpcMatches = [regex]::Matches($txt, "rpc\(\s*'([^']+)'\s*")
  foreach ($m in $rpcMatches) {
    [void]$rpcs.Add($m.Groups[1].Value)
  }
}

$tables | Sort-Object | Set-Content code_tables_used.txt
$rpcs | Sort-Object | Set-Content code_rpcs_used.txt
