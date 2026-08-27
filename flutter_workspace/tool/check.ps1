Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceRoot = (Resolve-Path (Join-Path $ScriptDirectory '..')).Path
$RepositoryRoot = (Resolve-Path (Join-Path $WorkspaceRoot '..')).Path

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        & $Command @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "$Command exited with code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

$InventoryTest = Join-Path $RepositoryRoot 'tests/flutterMigrationInventory.test.js'
$WorkspaceStructureTest = Join-Path $RepositoryRoot 'tests/flutterWorkspaceStructure.test.js'
$CiChecksTest = Join-Path $RepositoryRoot 'tests/flutterCiChecks.test.js'
$LedgerValidator = Join-Path $RepositoryRoot 'tools/flutter_migration_inventory/validate_ledgers.js'
$InventoryGenerator = Join-Path $RepositoryRoot 'tools/flutter_migration_inventory/source_inventory.js'
$ReportGenerator = Join-Path $RepositoryRoot 'tools/flutter_migration_inventory/generate_report.js'
$BoundaryTest = Join-Path $WorkspaceRoot 'tool/verify_boundaries.test.js'
$BoundaryCli = Join-Path $WorkspaceRoot 'tool/verify_boundaries.js'
$FlutterMembers = @(
    Get-ChildItem (Join-Path $WorkspaceRoot 'packages') -Directory | Sort-Object Name | ForEach-Object FullName
    Get-ChildItem (Join-Path $WorkspaceRoot 'apps') -Directory | Sort-Object Name | ForEach-Object FullName
)

Invoke-Checked -Command 'fvm' -Arguments @('dart', 'pub', 'get', '--enforce-lockfile') -WorkingDirectory $WorkspaceRoot
Invoke-Checked -Command 'node' -Arguments @('--test', $InventoryTest, $WorkspaceStructureTest, $CiChecksTest) -WorkingDirectory $RepositoryRoot
Invoke-Checked -Command 'node' -Arguments @($LedgerValidator) -WorkingDirectory $RepositoryRoot
Invoke-Checked -Command 'node' -Arguments @($InventoryGenerator) -WorkingDirectory $RepositoryRoot
Invoke-Checked -Command 'node' -Arguments @($ReportGenerator) -WorkingDirectory $RepositoryRoot
Invoke-Checked -Command 'git' -Arguments @('diff', '--exit-code', '--', 'migration/flutter/generated/source-inventory.json', 'migration/flutter/generated/coverage.md') -WorkingDirectory $RepositoryRoot
Invoke-Checked -Command 'node' -Arguments @('--test', $BoundaryTest) -WorkingDirectory $WorkspaceRoot
Invoke-Checked -Command 'node' -Arguments @($BoundaryCli, $WorkspaceRoot) -WorkingDirectory $WorkspaceRoot
Invoke-Checked -Command 'fvm' -Arguments @('dart', 'format', '--output=none', '--set-exit-if-changed', '.') -WorkingDirectory $WorkspaceRoot
Invoke-Checked -Command 'fvm' -Arguments @('dart', 'analyze') -WorkingDirectory $WorkspaceRoot
Invoke-Checked -Command 'fvm' -Arguments (@('flutter', 'test') + $FlutterMembers) -WorkingDirectory $WorkspaceRoot
Invoke-Checked -Command 'fvm' -Arguments @('flutter', 'build', 'windows', '--release') -WorkingDirectory (Join-Path $WorkspaceRoot 'apps/windows_app')
Invoke-Checked -Command 'git' -Arguments @('diff', '--quiet', '--', 'flutter_workspace', 'migration/flutter/generated') -WorkingDirectory $RepositoryRoot
Invoke-Checked -Command 'git' -Arguments @('diff', '--cached', '--quiet', '--', 'flutter_workspace', 'migration/flutter/generated') -WorkingDirectory $RepositoryRoot
