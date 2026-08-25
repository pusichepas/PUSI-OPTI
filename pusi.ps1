Clear-Host

Write-Host ""
Write-Host "============================================="
Write-Host "               PUSI OPTI"
Write-Host "============================================="
Write-Host ""
Write-Host "Tool cargada correctamente."
Write-Host ""

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpu = Get-CimInstance Win32_VideoController | Where-Object {$_.Name -notmatch "Microsoft"}
$ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory

Write-Host "CPU:"
Write-Host "  $($cpu.Name)"
Write-Host ""

Write-Host "GPU:"
foreach ($g in $gpu) {
    Write-Host "  $($g.Name)"
}

Write-Host ""
Write-Host "RAM:"
Write-Host "  $([math]::Round($ram / 1GB,1)) GB"

Write-Host ""
Read-Host "Pulsa ENTER para salir"
