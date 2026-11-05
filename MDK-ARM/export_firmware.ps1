param(
    [Parameter(Mandatory = $true)][string]$AxfPath,
    [Parameter(Mandatory = $true)][string]$FromElfPath
)

$ErrorActionPreference = 'Stop'
try {
    $exportAxf = Get-Item -LiteralPath $AxfPath
    $exportTool = Get-Item -LiteralPath $FromElfPath
    $exportSource = Get-Item -LiteralPath (Join-Path $PSScriptRoot '../App/Src/app_bootloader.c')
    if ($exportAxf.PSIsContainer -or $exportTool.PSIsContainer) {
        throw 'AXF and fromelf must be files.'
    }

    # 读取现有板型选择，跳过注释，避免旧注释中的板型名影响命名。
    $exportCode = [System.IO.File]::ReadAllText($exportSource.FullName)
    $exportCode = [regex]::Replace($exportCode, '(?s)/\*.*?\*/|//[^\r\n]*', '')
    $exportFunction = [regex]::Match($exportCode, '(?s)\bBootBoardId_t\s+Boot_BoardGetId\s*\(\s*void\s*\)\s*\{(?<body>.*?)\}')
    $exportSelection = [regex]::Matches($exportFunction.Groups['body'].Value, '\bBootBoardId_t\s+board_id\s*=\s*(?<board>BOOT_BOARD_[A-Z]+)\s*;')
    if (-not $exportFunction.Success -or $exportSelection.Count -ne 1) {
        throw 'Cannot find one board_id assignment in Boot_BoardGetId().'
    }
    $exportNames = @{
        BOOT_BOARD_DANJIE = 'Bootloader_Danjie'
        BOOT_BOARD_PANTAO = 'Bootloader_Pantao'
        BOOT_BOARD_NIUDAN = 'Bootloader_Niudan'
        BOOT_BOARD_WUSONG = 'Bootloader_Wusong'
        BOOT_BOARD_YITONG = 'Bootloader_Yitong'
    }
    $exportBoard = $exportSelection[0].Groups['board'].Value
    if (-not $exportNames.ContainsKey($exportBoard)) {
        throw ('Unknown board_id: ' + $exportBoard)
    }
    # 板型选择改动后必须重新编译，不能把上一板型的AXF改名导出。
    if ($exportSource.LastWriteTimeUtc -gt $exportAxf.LastWriteTimeUtc) {
        throw 'Board source is newer than AXF. Rebuild before exporting.'
    }

    $exportDir = Join-Path $PSScriptRoot 'firmware'
    New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
    $exportStem = Join-Path $exportDir $exportNames[$exportBoard]
    $exportHex = $exportStem + '.pending.hex'
    $exportBin = $exportStem + '.pending.bin'
    # HEX和BIN都从同一个AXF生成；两者均成功且校验通过后再覆盖正式文件。
    & $exportTool.FullName --i32 --output $exportHex $exportAxf.FullName
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $exportHex -PathType Leaf)) {
        throw 'fromelf HEX export failed.'
    }
    & $exportTool.FullName --bin --output $exportBin $exportAxf.FullName
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $exportBin -PathType Leaf)) {
        throw 'fromelf BIN export failed.'
    }
    $exportBytes = [System.IO.File]::ReadAllBytes($exportBin)
    if ($exportBytes.Length -lt 8 -or $exportBytes.Length -gt 0xC000) {
        throw 'Bootloader BIN must be 8..49152 bytes.'
    }
    $exportStack = [BitConverter]::ToUInt32($exportBytes, 0)
    $exportReset = [BitConverter]::ToUInt32($exportBytes, 4)
    $exportResetAddress = $exportReset -band 4294967294L
    if ($exportStack -lt 0x20000000 -or $exportStack -ge 0x20020000 -or
        ($exportReset -band 1) -eq 0 -or $exportResetAddress -lt 0x08000000 -or
        $exportResetAddress -ge 0x0800C000) {
        throw 'Invalid Bootloader vectors; expected an image at 0x08000000.'
    }
    Move-Item -LiteralPath $exportHex -Destination ($exportStem + '.hex') -Force
    Move-Item -LiteralPath $exportBin -Destination ($exportStem + '.bin') -Force
    Write-Output ('Exported ' + $exportNames[$exportBoard] + '.hex/.bin (' + $exportBytes.Length + ' bytes)')
    exit 0
}
catch {
    [Console]::Error.WriteLine('Bootloader export failed: ' + $_.Exception.Message)
    exit 1
}
