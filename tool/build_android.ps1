param([ValidateSet('debug', 'release')][string]$Mode = 'debug')

$ErrorActionPreference = 'Stop'
$naviloRoot = Split-Path -Parent $PSScriptRoot
$naviloSocketDirectory = Join-Path $naviloRoot 'build\socket-tmp'
New-Item -ItemType Directory -Path $naviloSocketDirectory -Force | Out-Null
$naviloPreviousJavaOptions = $env:JAVA_TOOL_OPTIONS

try {
    # JBR 25 failed connecting its selector's Unix-domain socket in the
    # default Windows temp directory. Keep that socket within the project.
    $naviloSocketOption = '"-Djdk.net.unixdomain.tmpdir=' + $naviloSocketDirectory + '"'
    $env:JAVA_TOOL_OPTIONS = ($naviloPreviousJavaOptions + ' ' + $naviloSocketOption).Trim()
    Push-Location -LiteralPath $naviloRoot
    try {
        $naviloBuildArguments = @('build', 'apk', "--$Mode")
        if (Test-Path -LiteralPath 'config\supabase.local.json') {
            $naviloBuildArguments += '--dart-define-from-file=config/supabase.local.json'
        }
        & flutter @naviloBuildArguments
        if ($LASTEXITCODE -ne 0) {
            throw "Android build failed with exit code $LASTEXITCODE"
        }
    } finally {
        Pop-Location
    }
} finally {
    $env:JAVA_TOOL_OPTIONS = $naviloPreviousJavaOptions
}
