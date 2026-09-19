param(
    [string]$RuntimeRoot = 'C:\Gunny-DDTank30\runtime',
    [int]$PollSeconds = 2
)
$ErrorActionPreference='Stop'
$stateRoot='C:\Gunny-DDTank30\state'
New-Item -ItemType Directory -Force -Path $stateRoot | Out-Null
$logPath=Join-Path $stateRoot 'supervisor.log'
function Log([string]$m){Add-Content -LiteralPath $logPath -Value ((Get-Date -Format o)+' '+$m) -Encoding UTF8}
$runtimeGuard=Join-Path $PSScriptRoot 'Test-DDTank30Clr2Runtime.ps1'
if(-not(Test-Path -LiteralPath $runtimeGuard)){throw "missing runtime guard: $runtimeGuard"}
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runtimeGuard -RuntimeRoot $RuntimeRoot
if($LASTEXITCODE-ne0){throw "DDTank30 CLR2 runtime guard failed with exit $LASTEXITCODE"}
Log 'CLR2 runtime guard passed'
function Listener([int]$port){@(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object {$_.LocalPort -eq $port})}
function Wait-OwnedPort([int]$port,[int]$processId,[int]$timeoutSec){
    $end=(Get-Date).AddSeconds($timeoutSec)
    while((Get-Date)-lt$end){
        if(@(Listener $port | Where-Object {$_.OwningProcess -eq $processId}).Count -gt 0){return}
        $proc=Get-Process -Id $processId -ErrorAction SilentlyContinue
        if(-not $proc){throw "process $processId exited before port $port"}
        Start-Sleep -Milliseconds 500
    }
    throw "timeout waiting for port $port from pid $processId"
}
function Start-Role([string]$name,[string]$subdir,[string]$exeName,[int]$port,[int]$timeoutSec){
    $dir=Join-Path $RuntimeRoot $subdir
    $exe=Join-Path $dir $exeName
    if(-not(Test-Path -LiteralPath $exe)){throw "missing runtime executable: $exe"}
    $busy=@(Listener $port)
    if($busy.Count -gt 0){throw "port $port already occupied before $name startup"}
    $psi=New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName=$exe
    $psi.Arguments='--start'
    $psi.WorkingDirectory=$dir
    $psi.UseShellExecute=$false
    $psi.CreateNoWindow=$true
    $psi.RedirectStandardInput=$true
    $proc=New-Object System.Diagnostics.Process
    $proc.StartInfo=$psi
    if(-not $proc.Start()){throw "failed to start $name"}
    $stdin=$proc.StandardInput
    Wait-OwnedPort $port $proc.Id $timeoutSec
    Log "$name ready pid=$($proc.Id) port=$port"
    [pscustomobject]@{Name=$name;Process=$proc;Stdin=$stdin;Port=$port}
}
$roles=New-Object System.Collections.Generic.List[object]
try {
    Log 'supervisor starting'
    $roles.Add((Start-Role 'center' 'center' 'Center.Service.exe' 9302 60))
    $roles.Add((Start-Role 'fighting' 'fighting' 'Fighting.Service.exe' 9308 90))
    $roles.Add((Start-Role 'game' 'game' 'Road.Service.exe' 9300 120))
    Log 'stack ready'
    while($true){
        foreach($role in $roles){if($role.Process.HasExited){throw "$($role.Name) exited code=$($role.Process.ExitCode)"}}
        Start-Sleep -Seconds $PollSeconds
    }
}
catch {
    Log ("supervisor failed: " + $_.Exception.GetType().FullName + ": " + $_.Exception.Message)
    throw
}
finally {
    Log 'supervisor stopping children'
    for($i=$roles.Count-1;$i-ge0;$i--){
        $role=$roles[$i]
        try{if(-not $role.Process.HasExited){$role.Stdin.WriteLine('exit');$role.Stdin.Flush()}}catch{}
    }
    Start-Sleep -Seconds 3
    for($i=$roles.Count-1;$i-ge0;$i--){$role=$roles[$i];try{if(-not $role.Process.HasExited){$role.Process.Kill()}}catch{}}
}
