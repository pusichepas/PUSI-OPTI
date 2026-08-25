# ============================================================
# PUSI OPTI
# Pusi Optimization Utility
# VERSION 1.0.0
# ============================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase


# ============================================================
# CONFIGURACION
# ============================================================

$script:PusiVersion = "1.0.0"

$script:PowURL =
    "https://raw.githubusercontent.com/pusichepas/PUSI-OPTI/main/Bitsum-Highest-Performance.pow"

$script:PusiPowerGuid =
    "7f34a6b5-1f2d-4c73-9b01-5b851dd62864"

$script:SessionBackup = @{}

$script:InitialSnapshot = $null
$script:LastSnapshot = $null

$script:NeedsRestart = $false

$script:ResultadosOK = 0
$script:ResultadosError = 0
$script:ResultadosOmitidos = 0

$script:FreedBytes = 0


# ============================================================
# ADMIN
# ============================================================

function Test-PusiAdmin {

    $Identity =
        [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal =
        New-Object `
            Security.Principal.WindowsPrincipal(
                $Identity
            )

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}


if (-not (Test-PusiAdmin)) {

    [System.Windows.MessageBox]::Show(
        "PUSI OPTI necesita permisos de administrador.`n`nAbre PowerShell como administrador y vuelve a ejecutar el comando.",
        "PUSI OPTI",
        "OK",
        "Warning"
    )

    exit
}


# ============================================================
# REGISTRO
# ============================================================

function Get-PusiRegValue {

    param(
        [string]$Path,
        [string]$Name
    )

    try {

        return (
            Get-ItemProperty `
                -Path $Path `
                -Name $Name `
                -ErrorAction Stop
        ).$Name

    }
    catch {

        return $null
    }
}


function Test-PusiRegValueExists {

    param(
        [string]$Path,
        [string]$Name
    )

    try {

        Get-ItemProperty `
            -Path $Path `
            -Name $Name `
            -ErrorAction Stop |
            Out-Null

        return $true

    }
    catch {

        return $false
    }
}


function Set-PusiDWORD {

    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

    try {

        if (-not (Test-Path $Path)) {

            New-Item `
                -Path $Path `
                -Force |
                Out-Null
        }

        New-ItemProperty `
            -Path $Path `
            -Name $Name `
            -PropertyType DWord `
            -Value $Value `
            -Force `
            -ErrorAction Stop |
            Out-Null

        return $true

    }
    catch {

        return $false
    }
}


function Set-PusiString {

    param(
        [string]$Path,
        [string]$Name,
        [string]$Value
    )

    try {

        if (-not (Test-Path $Path)) {

            New-Item `
                -Path $Path `
                -Force |
                Out-Null
        }

        New-ItemProperty `
            -Path $Path `
            -Name $Name `
            -PropertyType String `
            -Value $Value `
            -Force `
            -ErrorAction Stop |
            Out-Null

        return $true

    }
    catch {

        return $false
    }
}


function Remove-PusiRegValue {

    param(
        [string]$Path,
        [string]$Name
    )

    try {

        Remove-ItemProperty `
            -Path $Path `
            -Name $Name `
            -ErrorAction SilentlyContinue

        return $true

    }
    catch {

        return $false
    }
}


# ============================================================
# BACKUP DE SESION
# ============================================================

function Backup-PusiRegValue {

    param(
        [string]$ID,
        [string]$Path,
        [string]$Name
    )

    if ($script:SessionBackup.ContainsKey($ID)) {

        return
    }


    $Exists =
        Test-PusiRegValueExists `
            -Path $Path `
            -Name $Name


    $Value = $null
    $Kind = $null


    if ($Exists) {

        try {

            $Key =
                Get-Item `
                    -Path $Path `
                    -ErrorAction Stop

            $Value =
                $Key.GetValue(
                    $Name,
                    $null,
                    "DoNotExpandEnvironmentNames"
                )

            $Kind =
                $Key.GetValueKind(
                    $Name
                ).ToString()

        }
        catch {}
    }


    $script:SessionBackup[$ID] =
        [PSCustomObject]@{

            Path = $Path

            Name = $Name

            Exists = $Exists

            Value = $Value

            Kind = $Kind
        }
}


function Restore-PusiRegValue {

    param(
        [string]$ID
    )


    if (-not $script:SessionBackup.ContainsKey($ID)) {

        return $false
    }


    $Data =
        $script:SessionBackup[$ID]


    try {

        if (-not $Data.Exists) {

            Remove-PusiRegValue `
                -Path $Data.Path `
                -Name $Data.Name |
                Out-Null

            return $true
        }


        if (-not (Test-Path $Data.Path)) {

            New-Item `
                -Path $Data.Path `
                -Force |
                Out-Null
        }


        switch ($Data.Kind) {

            "DWord" {

                New-ItemProperty `
                    -Path $Data.Path `
                    -Name $Data.Name `
                    -PropertyType DWord `
                    -Value ([int]$Data.Value) `
                    -Force |
                    Out-Null
            }


            "QWord" {

                New-ItemProperty `
                    -Path $Data.Path `
                    -Name $Data.Name `
                    -PropertyType QWord `
                    -Value ([long]$Data.Value) `
                    -Force |
                    Out-Null
            }


            "ExpandString" {

                New-ItemProperty `
                    -Path $Data.Path `
                    -Name $Data.Name `
                    -PropertyType ExpandString `
                    -Value ([string]$Data.Value) `
                    -Force |
                    Out-Null
            }


            "MultiString" {

                New-ItemProperty `
                    -Path $Data.Path `
                    -Name $Data.Name `
                    -PropertyType MultiString `
                    -Value $Data.Value `
                    -Force |
                    Out-Null
            }


            default {

                New-ItemProperty `
                    -Path $Data.Path `
                    -Name $Data.Name `
                    -PropertyType String `
                    -Value ([string]$Data.Value) `
                    -Force |
                    Out-Null
            }
        }


        return $true

    }
    catch {

        return $false
    }
}


# ============================================================
# RESULTADOS
# ============================================================

function Reset-PusiResults {

    $script:ResultadosOK = 0
    $script:ResultadosError = 0
    $script:ResultadosOmitidos = 0
}


function Add-PusiResult {

    param(
        [ValidateSet(
            "OK",
            "ERROR",
            "OMITIDO"
        )]
        [string]$Type
    )


    switch ($Type) {

        "OK" {

            $script:ResultadosOK++
        }

        "ERROR" {

            $script:ResultadosError++
        }

        "OMITIDO" {

            $script:ResultadosOmitidos++
        }
    }
}


# ============================================================
# RESTORE POINT
# ============================================================

function New-PusiRestorePoint {

    try {

        Enable-ComputerRestore `
            -Drive "C:\" `
            -ErrorAction SilentlyContinue


        Checkpoint-Computer `
            -Description "PUSI OPTI - PRE OPTIMIZACION" `
            -RestorePointType "MODIFY_SETTINGS" `
            -ErrorAction Stop


        return $true

    }
    catch {

        return $false
    }
}


# ============================================================
# REINICIO PENDIENTE
# ============================================================

function Test-PusiPendingRestart {

    if (
        Test-Path `
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
    ) {

        return $true
    }


    if (
        Test-Path `
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    ) {

        return $true
    }


    try {

        $Pending =
            Get-ItemProperty `
                "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
                -Name "PendingFileRenameOperations" `
                -ErrorAction SilentlyContinue


        if ($Pending) {

            return $true
        }

    }
    catch {}


    return $false
}


# ============================================================
# HAGS
# ============================================================

function Get-PusiHAGS {

    $Value =
        Get-PusiRegValue `
            "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
            "HwSchMode"


    if ($Value -eq 2) {

        return "ACTIVO"
    }


    if ($Value -eq 1) {

        return "INACTIVO"
    }


    return "PREDETERMINADO"
}


# ============================================================
# VBS
# ============================================================

function Get-PusiVBS {

    try {

        $DG =
            Get-CimInstance `
                -Namespace "root\Microsoft\Windows\DeviceGuard" `
                -ClassName Win32_DeviceGuard `
                -ErrorAction Stop


        switch ($DG.VirtualizationBasedSecurityStatus) {

            0 {
                return "INACTIVO"
            }

            1 {
                return "CONFIGURADO"
            }

            2 {
                return "ACTIVO"
            }

            default {
                return "DESCONOCIDO"
            }
        }

    }
    catch {

        return "NO DISPONIBLE"
    }
}


# ============================================================
# HARDWARE
# ============================================================

function Get-PusiHardware {

    $CPU =
        Get-CimInstance Win32_Processor |
        Select-Object -First 1


    $GPU =
        Get-CimInstance Win32_VideoController |
        Where-Object {

            $_.Name -notmatch "Microsoft Basic"
        } |
        Sort-Object AdapterRAM -Descending |
        Select-Object -First 1


    $Computer =
        Get-CimInstance Win32_ComputerSystem


    $OS =
        Get-CimInstance Win32_OperatingSystem


    $Battery =
        Get-CimInstance Win32_Battery `
            -ErrorAction SilentlyContinue


    $Memory =
        Get-CimInstance Win32_PhysicalMemory `
            -ErrorAction SilentlyContinue


    $RAMGB =
        [math]::Round(
            $Computer.TotalPhysicalMemory / 1GB,
            0
        )


    $RAMSpeed =
        $Memory |
        Where-Object ConfiguredClockSpeed |
        Select-Object `
            -ExpandProperty ConfiguredClockSpeed |
        Sort-Object -Descending |
        Select-Object -First 1


    if (-not $RAMSpeed) {

        $RAMSpeed = "?"
    }


    $Modules =
        @(
            $Memory |
            Where-Object {
                $_.Capacity -gt 0
            }
        ).Count


    if ($Battery) {

        $Type =
            "PORTÁTIL"
    }
    else {

        $Type =
            "SOBREMESA"
    }


    $DriverDate = "?"


    if (
        $GPU -and
        $GPU.DriverDate
    ) {

        try {

            $DriverDate =
                [Management.ManagementDateTimeConverter]::ToDateTime(
                    $GPU.DriverDate
                ).ToString("dd/MM/yyyy")
        }
        catch {

            $DriverDate = "?"
        }
    }


    return [PSCustomObject]@{

        CPU =
            $CPU.Name.Trim()

        Cores =
            $CPU.NumberOfCores

        Threads =
            $CPU.NumberOfLogicalProcessors

        GPU =
            if ($GPU) {
                $GPU.Name.Trim()
            }
            else {
                "No detectada"
            }

        GPUDriver =
            if ($GPU.DriverVersion) {
                $GPU.DriverVersion
            }
            else {
                "?"
            }

        GPUDriverDate =
            $DriverDate

        RAM =
            "$RAMGB GB"

        RAMSpeed =
            "$RAMSpeed MT/s"

        RAMModules =
            $Modules

        Windows =
            $OS.Caption

        Build =
            $OS.BuildNumber

        Type =
            $Type

        LastBoot =
            $OS.LastBootUpTime
    }
}


# ============================================================
# MONITOR
# ============================================================

function Get-PusiDisplay {

    try {

        $Video =
            Get-CimInstance Win32_VideoController |
            Where-Object {

                $_.CurrentHorizontalResolution -gt 0 -and
                $_.CurrentVerticalResolution -gt 0
            } |
            Select-Object -First 1


        if (-not $Video) {

            return [PSCustomObject]@{

                Resolution = "No disponible"
                Refresh = "?"
            }
        }


        return [PSCustomObject]@{

            Resolution =
                "$($Video.CurrentHorizontalResolution)x$($Video.CurrentVerticalResolution)"

            Refresh =
                if ($Video.CurrentRefreshRate) {
                    "$($Video.CurrentRefreshRate) Hz"
                }
                else {
                    "?"
                }
        }

    }
    catch {

        return [PSCustomObject]@{

            Resolution = "No disponible"
            Refresh = "?"
        }
    }
}


# ============================================================
# ALMACENAMIENTO
# ============================================================

function Get-PusiStorageInfo {

    $FreeGB = "?"
    $TotalGB = "?"
    $PercentFree = "?"

    $Media = "Desconocido"
    $Bus = ""


    try {

        $Drive =
            Get-CimInstance Win32_LogicalDisk `
                -Filter "DeviceID='C:'"


        $FreeGB =
            [math]::Round(
                $Drive.FreeSpace / 1GB,
                1
            )


        $TotalGB =
            [math]::Round(
                $Drive.Size / 1GB,
                1
            )


        $PercentFree =
            [math]::Round(
                (
                    $Drive.FreeSpace /
                    $Drive.Size
                ) * 100,
                0
            )

    }
    catch {}


    try {

        $Disk =
            Get-PhysicalDisk |
            Sort-Object Size -Descending |
            Select-Object -First 1


        if ($Disk) {

            $Media =
                "$($Disk.MediaType)"

            $Bus =
                "$($Disk.BusType)"
        }

    }
    catch {}


    return [PSCustomObject]@{

        FreeGB =
            $FreeGB

        TotalGB =
            $TotalGB

        PercentFree =
            $PercentFree

        Media =
            $Media

        Bus =
            $Bus
    }
}


# ============================================================
# TRIM
# ============================================================

function Test-PusiTrim {

    try {

        $Result =
            fsutil behavior query DisableDeleteNotify 2>$null


        if (
            $Result -match
            "NTFS DisableDeleteNotify = 0"
        ) {

            return $true
        }

    }
    catch {}


    return $false
}


# ============================================================
# STARTUP APPS
# ============================================================

function Get-PusiStartupCount {

    $Count = 0


    $RegistryPaths = @(

        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",

        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",

        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )


    foreach ($Path in $RegistryPaths) {

        if (Test-Path $Path) {

            try {

                $Properties =
                    (
                        Get-ItemProperty `
                            $Path `
                            -ErrorAction SilentlyContinue
                    ).PSObject.Properties |
                    Where-Object {

                        $_.Name -notmatch '^PS'
                    }


                $Count +=
                    @(
                        $Properties
                    ).Count

            }
            catch {}
        }
    }


    $StartupFolders = @(

        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",

        "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    )


    foreach ($Folder in $StartupFolders) {

        if (Test-Path $Folder) {

            $Count +=
                @(
                    Get-ChildItem `
                        $Folder `
                        -File `
                        -ErrorAction SilentlyContinue
                ).Count
        }
    }


    return $Count
}


# ============================================================
# PLAN DE ENERGIA
# ============================================================

function Get-PusiActivePowerPlan {

    try {

        $Result =
            powercfg /getactivescheme


        $Name =
            [regex]::Match(
                $Result,
                '\((.+)\)'
            ).Groups[1].Value


        if ($Name) {

            return $Name
        }


        return $Result

    }
    catch {

        return "Desconocido"
    }
}


function Enable-PusiPowerPlan {

    try {

        $Existing =
            powercfg /list |
            Select-String `
                -SimpleMatch `
                "Plan energia Pusi"


        if ($Existing) {

            $Guid =
                [regex]::Match(
                    $Existing.ToString(),
                    '[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}'
                ).Value


            if ($Guid) {

                powercfg /setactive $Guid |
                    Out-Null


                return $true
            }
        }


        $TempPow =
            Join-Path `
                $env:TEMP `
                "PUSI-OPTI-POWER.pow"


        Invoke-WebRequest `
            -Uri $script:PowURL `
            -OutFile $TempPow `
            -UseBasicParsing `
            -ErrorAction Stop


        powercfg /delete `
            $script:PusiPowerGuid `
            2>$null |
            Out-Null


        powercfg /import `
            $TempPow `
            $script:PusiPowerGuid |
            Out-Null


        powercfg /changename `
            $script:PusiPowerGuid `
            "Plan energia Pusi" `
            "PUSI OPTI - Perfil de maximo rendimiento" |
            Out-Null


        powercfg /setactive `
            $script:PusiPowerGuid |
            Out-Null


        Remove-Item `
            $TempPow `
            -Force `
            -ErrorAction SilentlyContinue


        return $true

    }
    catch {

        return $false
    }
}


# ============================================================
# LIMPIEZA PROFUNDA
# ============================================================

function Invoke-PusiDeepCleanup {

    param(
        $StatusControl
    )


    $script:FreedBytes = 0


    function Clear-PusiPath {

        param(
            [string]$Path
        )


        if (-not (Test-Path $Path)) {

            return
        }


        try {

            Get-ChildItem `
                -LiteralPath $Path `
                -File `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue |
            ForEach-Object {

                $script:FreedBytes +=
                    $_.Length
            }


            Get-ChildItem `
                -LiteralPath $Path `
                -Force `
                -ErrorAction SilentlyContinue |
            Remove-Item `
                -Recurse `
                -Force `
                -ErrorAction SilentlyContinue

        }
        catch {}
    }


    $StatusControl.Text =
        "Limpiando Windows..."


    @(

        $env:TEMP,

        "$env:LOCALAPPDATA\Temp",

        "$env:SystemRoot\Temp",

        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",

        "$env:LOCALAPPDATA\Microsoft\Windows\WER",

        "$env:PROGRAMDATA\Microsoft\Windows\WER\ReportArchive",

        "$env:PROGRAMDATA\Microsoft\Windows\WER\ReportQueue",

        "$env:LOCALAPPDATA\CrashDumps",

        "$env:LOCALAPPDATA\D3DSCache",

        "$env:LOCALAPPDATA\NVIDIA\DXCache",

        "$env:LOCALAPPDATA\NVIDIA\GLCache",

        "$env:PROGRAMDATA\NVIDIA Corporation\NV_Cache",

        "$env:LOCALAPPDATA\AMD\DxCache",

        "$env:LOCALAPPDATA\AMD\GLCache",

        "$env:LOCALAPPDATA\AMD\VkCache",

        "$env:APPDATA\discord\Cache",

        "$env:APPDATA\discord\Code Cache",

        "$env:APPDATA\discord\GPUCache"

    ) |
    ForEach-Object {

        Clear-PusiPath $_
    }


    # Chromium

    $ChromiumRoots = @(

        "$env:LOCALAPPDATA\Google\Chrome\User Data",

        "$env:LOCALAPPDATA\Microsoft\Edge\User Data",

        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    )


    foreach ($Root in $ChromiumRoots) {

        if (-not (Test-Path $Root)) {

            continue
        }


        Get-ChildItem `
            $Root `
            -Directory `
            -ErrorAction SilentlyContinue |
        Where-Object {

            $_.Name -eq "Default" -or
            $_.Name -like "Profile *"

        } |
        ForEach-Object {

            $Profile =
                $_.FullName


            @(

                "Cache",

                "Code Cache",

                "GPUCache",

                "GrShaderCache",

                "DawnCache",

                "Service Worker\CacheStorage"

            ) |
            ForEach-Object {

                Clear-PusiPath `
                    "$Profile\$_"
            }
        }
    }


    # Opera

    @(

        "$env:APPDATA\Opera Software\Opera Stable\Cache",

        "$env:APPDATA\Opera Software\Opera Stable\Code Cache",

        "$env:APPDATA\Opera Software\Opera Stable\GPUCache",

        "$env:APPDATA\Opera Software\Opera GX Stable\Cache",

        "$env:APPDATA\Opera Software\Opera GX Stable\Code Cache",

        "$env:APPDATA\Opera Software\Opera GX Stable\GPUCache"

    ) |
    ForEach-Object {

        Clear-PusiPath $_
    }


    # Firefox

    $Firefox =
        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"


    if (Test-Path $Firefox) {

        Get-ChildItem `
            $Firefox `
            -Directory `
            -ErrorAction SilentlyContinue |
        ForEach-Object {

            Clear-PusiPath `
                "$($_.FullName)\cache2"

            Clear-PusiPath `
                "$($_.FullName)\startupCache"

            Clear-PusiPath `
                "$($_.FullName)\shader-cache"
        }
    }


    # Miniaturas

    try {

        Get-ChildItem `
            "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" `
            -Filter "thumbcache_*.db" `
            -Force `
            -ErrorAction SilentlyContinue |
        ForEach-Object {

            $script:FreedBytes +=
                $_.Length


            Remove-Item `
                $_.FullName `
                -Force `
                -ErrorAction SilentlyContinue
        }

    }
    catch {}


    # Papelera

    try {

        Clear-RecycleBin `
            -Force `
            -ErrorAction SilentlyContinue

    }
    catch {}


    if ($script:FreedBytes -ge 1GB) {

        return "$(
            [math]::Round(
                $script:FreedBytes / 1GB,
                2
            )
        ) GB"
    }


    return "$(
        [math]::Round(
            $script:FreedBytes / 1MB,
            0
        )
    ) MB"
}


# ============================================================
# SNAPSHOT
# ============================================================

function Get-PusiSnapshot {

    $OS =
        Get-CimInstance Win32_OperatingSystem


    $UsedKB =
        $OS.TotalVisibleMemorySize -
        $OS.FreePhysicalMemory


    $Storage =
        Get-PusiStorageInfo


    return [PSCustomObject]@{

        Procesos =
            @(
                Get-Process `
                    -ErrorAction SilentlyContinue
            ).Count

        RAMUsada =
            [math]::Round(
                ($UsedKB * 1KB) / 1GB,
                2
            )

        Plan =
            Get-PusiActivePowerPlan

        GameMode =
            (
                Get-PusiRegValue `
                    "HKCU:\Software\Microsoft\GameBar" `
                    "AutoGameModeEnabled"
            ) -eq 1

        GameDVR =
            (
                Get-PusiRegValue `
                    "HKCU:\System\GameConfigStore" `
                    "GameDVR_Enabled"
            ) -ne 0

        HAGS =
            Get-PusiHAGS

        FreeSpace =
            $Storage.FreeGB

        Startup =
            Get-PusiStartupCount

        Restart =
            Test-PusiPendingRestart
    }
}


# ============================================================
# HARDWARE GLOBAL
# ============================================================

$Hardware =
    Get-PusiHardware

$Display =
    Get-PusiDisplay


# ============================================================
# XAML
# ============================================================

[xml]$XAML = @"

<Window
 xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
 xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"

 Title="PUSI OPTI"

 Width="1380"
 Height="920"

 MinWidth="1180"
 MinHeight="760"

 WindowStartupLocation="CenterScreen"

 Background="#0B0E13">


<Window.Resources>


<Style TargetType="Button">

    <Setter Property="Background"
            Value="#202733"/>

    <Setter Property="Foreground"
            Value="White"/>

    <Setter Property="BorderBrush"
            Value="#374351"/>

    <Setter Property="BorderThickness"
            Value="1"/>

    <Setter Property="Padding"
            Value="14,9"/>

    <Setter Property="Margin"
            Value="4"/>

    <Setter Property="FontSize"
            Value="13"/>

    <Setter Property="Cursor"
            Value="Hand"/>

</Style>


<Style TargetType="CheckBox">

    <Setter Property="Foreground"
            Value="#EEF2F7"/>

    <Setter Property="FontSize"
            Value="13"/>

    <Setter Property="Margin"
            Value="6"/>

    <Setter Property="Cursor"
            Value="Hand"/>

</Style>


<Style TargetType="TextBlock">

    <Setter Property="Foreground"
            Value="White"/>

</Style>


<Style TargetType="TabItem">

    <Setter Property="Foreground"
            Value="White"/>

    <Setter Property="Background"
            Value="#151A22"/>

    <Setter Property="FontSize"
            Value="14"/>

    <Setter Property="FontWeight"
            Value="SemiBold"/>

    <Setter Property="Padding"
            Value="23,11"/>

</Style>


<Style
 x:Key="CardStyle"
 TargetType="Border">

    <Setter Property="Background"
            Value="#151A22"/>

    <Setter Property="BorderBrush"
            Value="#2C3643"/>

    <Setter Property="BorderThickness"
            Value="1"/>

    <Setter Property="CornerRadius"
            Value="10"/>

    <Setter Property="Padding"
            Value="16"/>

    <Setter Property="Margin"
            Value="6"/>

</Style>


</Window.Resources>


<Grid>


<Grid.RowDefinitions>

<RowDefinition Height="112"/>

<RowDefinition Height="*"/>

<RowDefinition Height="62"/>

</Grid.RowDefinitions>


<!-- ===================================================== -->
<!-- HEADER -->
<!-- ===================================================== -->

<Border
 Grid.Row="0"

 Background="#141920"

 BorderBrush="#2B3440"

 BorderThickness="0,0,0,1">


<Grid Margin="24,12">


<Grid.ColumnDefinitions>

<ColumnDefinition Width="250"/>

<ColumnDefinition Width="*"/>

<ColumnDefinition Width="390"/>

</Grid.ColumnDefinitions>


<StackPanel VerticalAlignment="Center">


<TextBlock
 Text="PUSI OPTI"

 FontSize="35"

 FontWeight="Bold"/>


<TextBlock
 Text="Windows Gaming Optimization"

 Foreground="#8490A0"/>


<TextBlock
 Text="v0.7.2"

 Foreground="#525C69"

 Margin="0,5,0,0"/>


</StackPanel>


<StackPanel
 Grid.Column="1"

 VerticalAlignment="Center">


<TextBlock
 x:Name="HeaderCPU"

 Foreground="#DCE3EC"/>


<TextBlock
 x:Name="HeaderGPU"

 Foreground="#DCE3EC"/>


<TextBlock
 x:Name="HeaderRAM"

 Foreground="#9CA7B5"/>


<TextBlock
 x:Name="HeaderWindows"

 Foreground="#9CA7B5"/>


</StackPanel>


<StackPanel
 Grid.Column="2"

 Orientation="Horizontal"

 HorizontalAlignment="Right"

 VerticalAlignment="Center">


<Button
 x:Name="RefreshAll"

 Content="ACTUALIZAR ESTADO"

 Width="165"/>


</StackPanel>


</Grid>


</Border>


<!-- ===================================================== -->
<!-- TAB CONTROL -->
<!-- ===================================================== -->

<TabControl
 x:Name="MainTabs"

 Grid.Row="1"

 Background="#0B0E13"

 BorderBrush="#2B3440">


<!-- ===================================================== -->
<!-- RESUMEN -->
<!-- ===================================================== -->

<TabItem
 x:Name="TabSummary"

 Header="RESUMEN">


<ScrollViewer VerticalScrollBarVisibility="Auto">


<StackPanel Margin="18">


<!-- ESTADO SUPERIOR -->

<Grid>


<Grid.ColumnDefinitions>

<ColumnDefinition Width="*"/>

<ColumnDefinition Width="350"/>

</Grid.ColumnDefinitions>


<StackPanel>


<TextBlock
 Text="Estado del equipo"

 FontSize="25"

 FontWeight="Bold"/>


<TextBlock
 x:Name="OverallStatus"

 Text="Analizando..."

 FontSize="15"

 Foreground="#9CA7B5"

 Margin="0,5,0,0"/>


</StackPanel>


<StackPanel
 Grid.Column="1"

 HorizontalAlignment="Right">


<TextBlock
 x:Name="StatusCounts"

 Text="0 correctos | 0 recomendaciones | 0 avisos"

 FontWeight="SemiBold"

 HorizontalAlignment="Right"/>


<TextBlock
 x:Name="RestartIndicator"

 Text="REINICIO: NO"

 Foreground="#65D99A"

 FontWeight="Bold"

 Margin="0,5,0,0"

 HorizontalAlignment="Right"/>


</StackPanel>


</Grid>


<!-- TARJETAS HARDWARE -->

<UniformGrid
 Columns="3"

 Margin="0,15,0,0">


<!-- CPU -->

<Border Style="{StaticResource CardStyle}">


<StackPanel>


<TextBlock
 Text="CPU"

 Foreground="#4FD6FF"

 FontWeight="Bold"/>


<TextBlock
 x:Name="CardCPUName"

 FontSize="16"

 FontWeight="SemiBold"

 TextWrapping="Wrap"

 Margin="0,8,0,0"/>


<TextBlock
 x:Name="CardCPUDetail"

 Foreground="#93A0AF"

 Margin="0,8,0,0"/>


</StackPanel>


</Border>


<!-- GPU -->

<Border Style="{StaticResource CardStyle}">


<StackPanel>


<TextBlock
 Text="GPU"

 Foreground="#4FD6FF"

 FontWeight="Bold"/>


<TextBlock
 x:Name="CardGPUName"

 FontSize="16"

 FontWeight="SemiBold"

 TextWrapping="Wrap"

 Margin="0,8,0,0"/>


<TextBlock
 x:Name="CardGPUDriver"

 Foreground="#93A0AF"

 Margin="0,8,0,0"

 TextWrapping="Wrap"/>


</StackPanel>


</Border>


<!-- RAM -->

<Border Style="{StaticResource CardStyle}">


<StackPanel>


<TextBlock
 Text="RAM"

 Foreground="#4FD6FF"

 FontWeight="Bold"/>


<TextBlock
 x:Name="CardRAM"

 FontSize="19"

 FontWeight="SemiBold"

 Margin="0,8,0,0"/>


<TextBlock
 x:Name="CardRAMDetail"

 Foreground="#93A0AF"

 Margin="0,8,0,0"/>


</StackPanel>


</Border>


<!-- MONITOR -->

<Border Style="{StaticResource CardStyle}">


<StackPanel>


<TextBlock
 Text="MONITOR"

 Foreground="#4FD6FF"

 FontWeight="Bold"/>


<TextBlock
 x:Name="CardDisplay"

 FontSize="19"

 FontWeight="SemiBold"

 Margin="0,8,0,0"/>


<TextBlock
 x:Name="CardRefresh"

 Foreground="#93A0AF"

 Margin="0,8,0,0"/>


</StackPanel>


</Border>


<!-- STORAGE -->

<Border Style="{StaticResource CardStyle}">


<StackPanel>


<TextBlock
 Text="ALMACENAMIENTO"

 Foreground="#4FD6FF"

 FontWeight="Bold"/>


<TextBlock
 x:Name="CardStorageType"

 FontSize="19"

 FontWeight="SemiBold"

 Margin="0,8,0,0"/>


<TextBlock
 x:Name="CardStorageSpace"

 Foreground="#93A0AF"

 Margin="0,8,0,0"/>


</StackPanel>


</Border>


<!-- WINDOWS -->

<Border Style="{StaticResource CardStyle}">


<StackPanel>


<TextBlock
 Text="WINDOWS"

 Foreground="#4FD6FF"

 FontWeight="Bold"/>


<TextBlock
 x:Name="CardWindows"

 FontSize="16"

 FontWeight="SemiBold"

 TextWrapping="Wrap"

 Margin="0,8,0,0"/>


<TextBlock
 x:Name="CardWindowsDetail"

 Foreground="#93A0AF"

 Margin="0,8,0,0"/>


</StackPanel>


</Border>


</UniformGrid>


<!-- CONFIG GAMING + RECOMENDACIONES -->

<Grid Margin="0,15,0,0">


<Grid.ColumnDefinitions>

<ColumnDefinition Width="*"/>

<ColumnDefinition Width="15"/>

<ColumnDefinition Width="*"/>

</Grid.ColumnDefinitions>


<!-- CONFIG GAMING -->

<Border
 Grid.Column="0"

 Style="{StaticResource CardStyle}">


<StackPanel>


<TextBlock
 Text="CONFIGURACIÓN GAMING"

 FontSize="19"

 FontWeight="Bold"/>


<Grid Margin="0,15,0,0">


<Grid.ColumnDefinitions>

<ColumnDefinition Width="220"/>

<ColumnDefinition Width="*"/>

</Grid.ColumnDefinitions>


<Grid.RowDefinitions>

<RowDefinition Height="31"/>

<RowDefinition Height="31"/>

<RowDefinition Height="31"/>

<RowDefinition Height="31"/>

<RowDefinition Height="31"/>

<RowDefinition Height="31"/>

<RowDefinition Height="31"/>

<RowDefinition Height="31"/>

<RowDefinition Height="31"/>

</Grid.RowDefinitions>


<TextBlock Grid.Row="0" Text="Game Mode"/>

<TextBlock
 x:Name="StateGameMode"
 Grid.Row="0"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="1" Text="Game DVR"/>

<TextBlock
 x:Name="StateGameDVR"
 Grid.Row="1"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="2" Text="HAGS"/>

<TextBlock
 x:Name="StateHAGS"
 Grid.Row="2"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="3" Text="Power Throttling"/>

<TextBlock
 x:Name="StatePowerThrottling"
 Grid.Row="3"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="4" Text="Plan de energía"/>

<TextBlock
 x:Name="StatePowerPlan"
 Grid.Row="4"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="5" Text="TRIM"/>

<TextBlock
 x:Name="StateTrim"
 Grid.Row="5"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="6" Text="VBS"/>

<TextBlock
 x:Name="StateVBS"
 Grid.Row="6"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="7" Text="Programas al inicio"/>

<TextBlock
 x:Name="StateStartup"
 Grid.Row="7"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="8" Text="Procesos actuales"/>

<TextBlock
 x:Name="StateProcesses"
 Grid.Row="8"
 Grid.Column="1"
 FontWeight="Bold"/>


</Grid>


</StackPanel>


</Border>


<!-- RECOMENDACIONES -->

<Border
 Grid.Column="2"

 Style="{StaticResource CardStyle}">


<StackPanel>


<TextBlock
 Text="PUSI RECOMIENDA"

 FontSize="19"

 FontWeight="Bold"/>


<TextBlock
 Text="Acciones detectadas automáticamente."

 Foreground="#93A0AF"

 Margin="0,5,0,12"/>


<ListBox
 x:Name="RecommendationList"

 Height="225"

 Background="#10151C"

 Foreground="White"

 BorderBrush="#303B48"/>


<WrapPanel Margin="0,12,0,0">


<Button
 x:Name="AnalyzePC"

 Content="ANALIZAR PC"

 Width="140"/>


<Button
 x:Name="ApplySafeRecommendations"

 Content="APLICAR SEGURAS"

 Width="170"/>


<Button
 x:Name="CopyReport"

 Content="COPIAR INFORME"

 Width="160"/>


</WrapPanel>


</StackPanel>


</Border>


</Grid>


<!-- ANTES DESPUES -->

<Border
 Style="{StaticResource CardStyle}"

 Margin="6,15,6,6">


<StackPanel>


<TextBlock
 Text="ANTES / DESPUÉS"

 FontSize="19"

 FontWeight="Bold"/>


<TextBlock
 Text="Comparación objetiva del estado del sistema."

 Foreground="#93A0AF"

 Margin="0,5,0,12"/>


<Grid>


<Grid.ColumnDefinitions>

<ColumnDefinition Width="180"/>

<ColumnDefinition Width="*"/>

<ColumnDefinition Width="*"/>

</Grid.ColumnDefinitions>


<Grid.RowDefinitions>

<RowDefinition Height="32"/>

<RowDefinition Height="32"/>

<RowDefinition Height="32"/>

<RowDefinition Height="32"/>

<RowDefinition Height="32"/>

<RowDefinition Height="32"/>

<RowDefinition Height="32"/>

</Grid.RowDefinitions>


<TextBlock
 Grid.Column="1"
 Text="ANTES"
 Foreground="#4FD6FF"
 FontWeight="Bold"/>


<TextBlock
 Grid.Column="2"
 Text="DESPUÉS"
 Foreground="#4FD6FF"
 FontWeight="Bold"/>


<TextBlock Grid.Row="1" Text="Procesos"/>

<TextBlock
 x:Name="BeforeProcesses"
 Grid.Row="1"
 Grid.Column="1"
 Text="-"/>

<TextBlock
 x:Name="AfterProcesses"
 Grid.Row="1"
 Grid.Column="2"
 Text="-"/>


<TextBlock Grid.Row="2" Text="RAM usada"/>

<TextBlock
 x:Name="BeforeRAM"
 Grid.Row="2"
 Grid.Column="1"
 Text="-"/>

<TextBlock
 x:Name="AfterRAM"
 Grid.Row="2"
 Grid.Column="2"
 Text="-"/>


<TextBlock Grid.Row="3" Text="Plan energía"/>

<TextBlock
 x:Name="BeforePower"
 Grid.Row="3"
 Grid.Column="1"
 Text="-"/>

<TextBlock
 x:Name="AfterPower"
 Grid.Row="3"
 Grid.Column="2"
 Text="-"/>


<TextBlock Grid.Row="4" Text="Game DVR"/>

<TextBlock
 x:Name="BeforeDVR"
 Grid.Row="4"
 Grid.Column="1"
 Text="-"/>

<TextBlock
 x:Name="AfterDVR"
 Grid.Row="4"
 Grid.Column="2"
 Text="-"/>


<TextBlock Grid.Row="5" Text="Espacio libre"/>

<TextBlock
 x:Name="BeforeStorage"
 Grid.Row="5"
 Grid.Column="1"
 Text="-"/>

<TextBlock
 x:Name="AfterStorage"
 Grid.Row="5"
 Grid.Column="2"
 Text="-"/>


<TextBlock Grid.Row="6" Text="Apps inicio"/>

<TextBlock
 x:Name="BeforeStartup"
 Grid.Row="6"
 Grid.Column="1"
 Text="-"/>

<TextBlock
 x:Name="AfterStartup"
 Grid.Row="6"
 Grid.Column="2"
 Text="-"/>


</Grid>


<WrapPanel Margin="0,12,0,0">


<Button
 x:Name="SaveInitialState"

 Content="GUARDAR ESTADO INICIAL"

 Width="215"/>


<Button
 x:Name="CompareState"

 Content="COMPARAR RESULTADOS"

 Width="215"/>


</WrapPanel>


</StackPanel>


</Border>


</StackPanel>


</ScrollViewer>


</TabItem>


<!-- ===================================================== -->
<!-- OPTIMIZACION -->
<!-- ===================================================== -->

<TabItem
 x:Name="TabOptimization"

 Header="OPTIMIZACIÓN">


<Grid Margin="20">


<Grid.RowDefinitions>

<RowDefinition Height="Auto"/>

<RowDefinition Height="Auto"/>

<RowDefinition Height="*"/>

<RowDefinition Height="Auto"/>

</Grid.RowDefinitions>


<Grid>


<Grid.ColumnDefinitions>

<ColumnDefinition Width="*"/>

<ColumnDefinition Width="330"/>

</Grid.ColumnDefinitions>


<StackPanel>


<TextBlock
 Text="Optimización de Windows"

 FontSize="23"

 FontWeight="Bold"/>


<TextBlock
 Text="Selecciona únicamente los cambios que quieras aplicar."

 Foreground="#8A95A5"/>


</StackPanel>


<TextBox
 x:Name="SearchTweaks"

 Grid.Column="1"

 Height="34"

 Background="#151A21"

 Foreground="White"

 BorderBrush="#35404D"

 Padding="10,5"

 ToolTip="Buscar ajuste..."/>


</Grid>


<WrapPanel
 Grid.Row="1"

 Margin="0,12,0,10">


<Button
 x:Name="PresetSafe"

 Content="SEGURO"

 Width="110"/>


<Button
 x:Name="PresetRecommended"

 Content="RECOMENDADO"

 Width="145"/>


<Button
 x:Name="PresetGaming"

 Content="PUSI GAMING"

 Width="145"/>


<Button
 x:Name="PresetAggressive"

 Content="AGRESIVO"

 Width="120"/>


<Button
 x:Name="ClearSelection"

 Content="LIMPIAR"

 Width="110"/>


</WrapPanel>


<ScrollViewer
 Grid.Row="2"

 VerticalScrollBarVisibility="Auto">


<Grid>


<Grid.ColumnDefinitions>

<ColumnDefinition Width="*"/>

<ColumnDefinition Width="25"/>

<ColumnDefinition Width="*"/>

</Grid.ColumnDefinitions>


<StackPanel Grid.Column="0">


<TextBlock
 Text="SISTEMA"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<CheckBox
 x:Name="OptRestorePoint"
 Content="Crear punto de restauración"
 ToolTip="Crea un punto de restauración antes de los cambios."/>


<CheckBox
 x:Name="OptTelemetry"
 Content="Desactivar telemetría"
 ToolTip="Reduce la telemetría mediante políticas de Windows."/>


<CheckBox
 x:Name="OptActivityHistory"
 Content="Desactivar historial de actividad"/>


<CheckBox
 x:Name="OptConsumerFeatures"
 Content="Desactivar contenido promocional"/>


<CheckBox
 x:Name="OptDelivery"
 Content="Desactivar Delivery Optimization P2P"/>


<CheckBox
 x:Name="OptSearchWeb"
 Content="Desactivar resultados web en Inicio"/>


<CheckBox
 x:Name="OptWidgets"
 Content="Ocultar Widgets"/>


<CheckBox
 x:Name="OptGameDVR"
 Content="Desactivar Game DVR"/>


<CheckBox
 x:Name="OptDeepClean"
 Content="Limpieza profunda de temporales y cachés"/>


<Separator Margin="0,15"/>


<TextBlock
 Text="GAMING Y RENDIMIENTO"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<CheckBox
 x:Name="OptGameMode"
 Content="Activar Game Mode"/>


<CheckBox
 x:Name="OptHAGS"
 Content="Activar HAGS"
 ToolTip="Hardware Accelerated GPU Scheduling. Conviene probarlo porque el resultado depende del equipo y del juego."/>


<CheckBox
 x:Name="OptPowerThrottling"
 Content="Desactivar Power Throttling"/>


<CheckBox
 x:Name="OptBackgroundApps"
 Content="Reducir aplicaciones en segundo plano"/>


<CheckBox
 x:Name="OptAnimations"
 Content="Desactivar animaciones de ventanas"/>


<CheckBox
 x:Name="OptTransparency"
 Content="Desactivar transparencias"/>


<CheckBox
 x:Name="OptTaskbarAnimations"
 Content="Desactivar animaciones de barra"/>


<CheckBox
 x:Name="OptVisualPerformance"
 Content="Efectos visuales orientados a rendimiento"/>


</StackPanel>


<StackPanel Grid.Column="2">


<TextBlock
 Text="INTERFAZ"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<CheckBox
 x:Name="OptExtensions"
 Content="Mostrar extensiones de archivo"/>


<CheckBox
 x:Name="OptHiddenFiles"
 Content="Mostrar archivos ocultos"/>


<CheckBox
 x:Name="OptLongPaths"
 Content="Activar rutas largas"/>


<CheckBox
 x:Name="OptMouseAcceleration"
 Content="Desactivar aceleración del ratón"/>


<CheckBox
 x:Name="OptStickyKeys"
 Content="Reducir activación accidental de Sticky Keys"/>


<CheckBox
 x:Name="OptTaskbarSearch"
 Content="Ocultar búsqueda de la barra"/>


<CheckBox
 x:Name="OptTaskView"
 Content="Ocultar Vista de tareas"/>


<CheckBox
 x:Name="OptStartRecommendations"
 Content="Reducir recomendaciones del menú Inicio"/>


<Separator Margin="0,15"/>


<TextBlock
 Text="PLAN DE ENERGÍA"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<Button
 x:Name="EnablePusiPower"

 Content="ACTIVAR PLAN ENERGIA PUSI"

 HorizontalAlignment="Stretch"/>


<Button
 x:Name="EnableBalanced"

 Content="VOLVER A EQUILIBRADO"

 HorizontalAlignment="Stretch"/>


<TextBlock
 x:Name="PowerPlanText"

 Text="Plan actual: detectando..."

 Foreground="#8A95A5"

 Margin="5,8,0,0"/>


</StackPanel>


</Grid>


</ScrollViewer>


<Grid Grid.Row="3">


<Grid.ColumnDefinitions>

<ColumnDefinition Width="*"/>

<ColumnDefinition Width="Auto"/>

</Grid.ColumnDefinitions>


<TextBlock
 x:Name="SelectionInfo"

 Text="0 ajustes seleccionados"

 Foreground="#8A95A5"

 VerticalAlignment="Center"/>


<StackPanel
 Grid.Column="1"

 Orientation="Horizontal">


<Button
 x:Name="RevertSelected"

 Content="REVERTIR SELECCIONADOS"

 Width="215"/>


<Button
 x:Name="ApplySelected"

 Content="APLICAR SELECCIONADOS"

 Width="215"/>


</StackPanel>


</Grid>


</Grid>


</TabItem>


<!-- ===================================================== -->
<!-- MANTENIMIENTO -->
<!-- ===================================================== -->

<TabItem
 x:Name="TabMaintenance"

 Header="MANTENIMIENTO">


<ScrollViewer VerticalScrollBarVisibility="Auto">


<StackPanel Margin="25">


<TextBlock
 Text="Mantenimiento del sistema"

 FontSize="23"

 FontWeight="Bold"/>


<TextBlock
 Text="Reparación, limpieza, red y almacenamiento."

 Foreground="#8A95A5"

 Margin="0,5,0,20"/>


<TextBlock
 Text="REPARACIÓN"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"/>


<WrapPanel Margin="0,8">


<Button
 x:Name="RunSFC"
 Content="SFC /SCANNOW"
 Width="180"/>


<Button
 x:Name="RunDISM"
 Content="REPARAR CON DISM"
 Width="190"/>


</WrapPanel>


<Separator Margin="0,18"/>


<TextBlock
 Text="RED"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"/>


<WrapPanel Margin="0,8">


<Button
 x:Name="FlushDNS"
 Content="VACIAR DNS"
 Width="170"/>


<Button
 x:Name="ResetNetwork"
 Content="RESET WINSOCK / TCP"
 Width="210"/>


</WrapPanel>


<Separator Margin="0,18"/>


<TextBlock
 Text="LIMPIEZA"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"/>


<WrapPanel Margin="0,8">


<Button
 x:Name="DeepCleanup"
 Content="LIMPIEZA PROFUNDA"
 Width="210"/>


<Button
 x:Name="EmptyRecycle"
 Content="VACIAR PAPELERA"
 Width="180"/>


</WrapPanel>


<Separator Margin="0,18"/>


<TextBlock
 Text="ALMACENAMIENTO"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"/>


<WrapPanel Margin="0,8">


<Button
 x:Name="CheckTrim"
 Content="COMPROBAR TRIM"
 Width="180"/>


<Button
 x:Name="OptimizeStorage"
 Content="RETRIM SSD / NVME"
 Width="200"/>


</WrapPanel>


<Separator Margin="0,18"/>


<TextBlock
 Text="ACCESOS RÁPIDOS"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"/>


<TextBlock
 Text="Atajos útiles para revisar el equipo sin salir de PUSI OPTI."

 Foreground="#8A95A5"

 Margin="0,5,0,8"/>


<WrapPanel Margin="0,8">


<Button
 x:Name="OpenStartupApps"
 Content="APPS DE INICIO"
 Width="180"/>


<Button
 x:Name="OpenGraphicsSettings"
 Content="CONFIG. GRÁFICOS"
 Width="190"/>


<Button
 x:Name="OpenAdvancedDisplay"
 Content="PANTALLA AVANZADA"
 Width="205"/>


<Button
 x:Name="OpenPowerOptions"
 Content="OPCIONES DE ENERGÍA"
 Width="210"/>


<Button
 x:Name="CreateRestorePointNow"
 Content="CREAR RESTAURACIÓN"
 Width="205"/>


</WrapPanel>


</StackPanel>


</ScrollViewer>


</TabItem>


<!-- ===================================================== -->
<!-- ACTUALIZACIONES -->
<!-- ===================================================== -->

<TabItem
 x:Name="TabUpdates"

 Header="ACTUALIZACIONES">


<ScrollViewer VerticalScrollBarVisibility="Auto">


<StackPanel Margin="25">


<TextBlock
 Text="Windows Update"

 FontSize="23"

 FontWeight="Bold"/>


<Border
 Background="#251E15"

 BorderBrush="#956F32"

 BorderThickness="1"

 Padding="15"

 Margin="0,15,0,20">


<TextBlock
 Text="AVISO: desactivar Windows Update puede impedir la recepción de parches de seguridad."

 Foreground="#E2BD79"

 TextWrapping="Wrap"/>


</Border>


<TextBlock
 Text="PAUSA"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"/>


<WrapPanel Margin="0,8">


<Button
 x:Name="Pause7"
 Content="PAUSAR 7 DÍAS"
 Width="170"/>


<Button
 x:Name="Pause35"
 Content="PAUSAR 35 DÍAS"
 Width="170"/>


<Button
 x:Name="ResumeUpdates"
 Content="QUITAR PAUSA"
 Width="170"/>


</WrapPanel>


<Separator Margin="0,18"/>


<TextBlock
 Text="DRIVERS"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"/>


<WrapPanel Margin="0,8">


<Button
 x:Name="DisableDriverUpdates"
 Content="BLOQUEAR DRIVERS DE WINDOWS UPDATE"
 Width="310"/>


<Button
 x:Name="EnableDriverUpdates"
 Content="RESTAURAR DRIVERS"
 Width="190"/>


</WrapPanel>


<Separator Margin="0,18"/>


<TextBlock
 Text="MODO AGRESIVO"

 Foreground="#FF956B"

 FontSize="17"

 FontWeight="Bold"/>


<WrapPanel Margin="0,8">


<Button
 x:Name="DisableWU"
 Content="DESACTIVAR WINDOWS UPDATE"
 Width="260"/>


<Button
 x:Name="EnableWU"
 Content="REACTIVAR WINDOWS UPDATE"
 Width="260"/>


</WrapPanel>


</StackPanel>


</ScrollViewer>


</TabItem>


</TabControl>


<!-- ===================================================== -->
<!-- FOOTER -->
<!-- ===================================================== -->

<Border
 Grid.Row="2"

 Background="#141920"

 BorderBrush="#2B3440"

 BorderThickness="0,1,0,0">


<Grid Margin="16,7">


<Grid.RowDefinitions>

<RowDefinition Height="Auto"/>

<RowDefinition Height="Auto"/>

</Grid.RowDefinitions>


<Grid>


<Grid.ColumnDefinitions>

<ColumnDefinition Width="*"/>

<ColumnDefinition Width="Auto"/>

</Grid.ColumnDefinitions>


<TextBlock
 x:Name="StatusBar"

 Text="PUSI OPTI lista."

 Foreground="#B8C1CC"/>


<TextBlock
 x:Name="BackupStatus"

 Grid.Column="1"

 Text="BACKUP SESIÓN: NO"

 Foreground="#8A95A5"/>


</Grid>


<ProgressBar
 x:Name="Progress"

 Grid.Row="1"

 Height="7"

 Minimum="0"

 Maximum="100"

 Value="0"

 Margin="0,8,0,0"/>


</Grid>


</Border>


</Grid>


</Window>

"@


# ============================================================
# CARGAR VENTANA
# ============================================================

$Reader =
    New-Object System.Xml.XmlNodeReader $XAML


$Window =
    [Windows.Markup.XamlReader]::Load(
        $Reader
    )


function C {

    param(
        [string]$Name
    )

    return $Window.FindName(
        $Name
    )
}


$StatusBar =
    C "StatusBar"

$Progress =
    C "Progress"


# ============================================================
# HEADER
# ============================================================

(C "HeaderCPU").Text =
    "CPU: $($Hardware.CPU)"


(C "HeaderGPU").Text =
    "GPU: $($Hardware.GPU)"


(C "HeaderRAM").Text =
    "RAM: $($Hardware.RAM) @ $($Hardware.RAMSpeed)"


(C "HeaderWindows").Text =
    "$($Hardware.Windows) | Build $($Hardware.Build) | $($Hardware.Type)"


# ============================================================
# TARJETAS
# ============================================================

function Update-PusiHardwareCards {

    $Storage =
        Get-PusiStorageInfo


    $DisplayNow =
        Get-PusiDisplay


    (C "CardCPUName").Text =
        $Hardware.CPU


    (C "CardCPUDetail").Text =
        "$($Hardware.Cores) núcleos | $($Hardware.Threads) hilos"


    (C "CardGPUName").Text =
        $Hardware.GPU


    (C "CardGPUDriver").Text =
        "Driver $($Hardware.GPUDriver) | $($Hardware.GPUDriverDate)"


    (C "CardRAM").Text =
        "$($Hardware.RAM) @ $($Hardware.RAMSpeed)"


    (C "CardRAMDetail").Text =
        "$($Hardware.RAMModules) módulo(s) detectado(s)"


    (C "CardDisplay").Text =
        $DisplayNow.Resolution


    (C "CardRefresh").Text =
        "Frecuencia actual: $($DisplayNow.Refresh)"


    $StorageType =
        "$($Storage.Bus) $($Storage.Media)".Trim()


    if (
        [string]::IsNullOrWhiteSpace(
            $StorageType
        )
    ) {

        $StorageType =
            "Unidad del sistema"
    }


    (C "CardStorageType").Text =
        $StorageType


    (C "CardStorageSpace").Text =
        "$($Storage.FreeGB) GB libres de $($Storage.TotalGB) GB"


    (C "CardWindows").Text =
        $Hardware.Windows


    $Uptime =
        (Get-Date) -
        $Hardware.LastBoot


    (C "CardWindowsDetail").Text =
        "Build $($Hardware.Build) | Encendido: $([math]::Floor($Uptime.TotalDays)) d $($Uptime.Hours) h"
}


# ============================================================
# OPCIONES
# ============================================================

$Options = @(

    "OptRestorePoint",

    "OptTelemetry",

    "OptActivityHistory",

    "OptConsumerFeatures",

    "OptDelivery",

    "OptSearchWeb",

    "OptWidgets",

    "OptGameDVR",

    "OptDeepClean",

    "OptGameMode",

    "OptHAGS",

    "OptPowerThrottling",

    "OptBackgroundApps",

    "OptAnimations",

    "OptTransparency",

    "OptTaskbarAnimations",

    "OptVisualPerformance",

    "OptExtensions",

    "OptHiddenFiles",

    "OptLongPaths",

    "OptMouseAcceleration",

    "OptStickyKeys",

    "OptTaskbarSearch",

    "OptTaskView",

    "OptStartRecommendations"
)


$RestartOptions = @(

    "OptGameDVR",

    "OptHAGS",

    "OptPowerThrottling",

    "OptBackgroundApps",

    "OptLongPaths"
)


function Update-PusiSelectionCounter {

    $Count =
        0


    $Restart =
        0


    foreach ($Name in $Options) {

        if ((C $Name).IsChecked) {

            $Count++


            if (
                $RestartOptions -contains
                $Name
            ) {

                $Restart++
            }
        }
    }


    (C "SelectionInfo").Text =
        "$Count ajustes seleccionados | $Restart pueden requerir reinicio"
}


foreach ($Name in $Options) {

    (C $Name).Add_Checked({

        Update-PusiSelectionCounter
    })


    (C $Name).Add_Unchecked({

        Update-PusiSelectionCounter
    })
}


# ============================================================
# COLOR DE ESTADOS
# ============================================================

function Set-PusiGood {

    param(
        $Control,
        [string]$Text
    )


    $Control.Text =
        $Text


    $Control.Foreground =
        "#63D89A"
}


function Set-PusiWarning {

    param(
        $Control,
        [string]$Text
    )


    $Control.Text =
        $Text


    $Control.Foreground =
        "#E5A64B"
}


function Set-PusiNeutral {

    param(
        $Control,
        [string]$Text
    )


    $Control.Text =
        $Text


    $Control.Foreground =
        "#A5AFBC"
}


# ============================================================
# ANALISIS
# ============================================================

function Invoke-PusiAnalysis {

    (C "RecommendationList").Items.Clear()


    $Good =
        0


    $Recommended =
        0


    $Warnings =
        0


    function Good {

        param(
            [string]$Text
        )


        (C "RecommendationList").Items.Add(
            "✓ $Text"
        ) |
        Out-Null


        $script:TmpGood++
    }


    function Recommend {

        param(
            [string]$Text
        )


        (C "RecommendationList").Items.Add(
            "! $Text"
        ) |
        Out-Null


        $script:TmpRecommended++
    }


    function Warning {

        param(
            [string]$Text
        )


        (C "RecommendationList").Items.Add(
            "⚠ $Text"
        ) |
        Out-Null


        $script:TmpWarnings++
    }


    $script:TmpGood = 0
    $script:TmpRecommended = 0
    $script:TmpWarnings = 0


    # Game Mode

    $GameMode =
        (
            Get-PusiRegValue `
                "HKCU:\Software\Microsoft\GameBar" `
                "AutoGameModeEnabled"
        ) -eq 1


    if ($GameMode) {

        Good "Game Mode está activo."
    }
    else {

        Recommend "Activar Game Mode."
    }


    # DVR

    $DVR =
        (
            Get-PusiRegValue `
                "HKCU:\System\GameConfigStore" `
                "GameDVR_Enabled"
        ) -ne 0


    if (-not $DVR) {

        Good "Game DVR está desactivado."
    }
    else {

        Recommend "Desactivar Game DVR."
    }


    # HAGS

    $HAGS =
        Get-PusiHAGS


    if ($HAGS -eq "ACTIVO") {

        Good "HAGS está activo."
    }
    else {

        Recommend "HAGS está inactivo o en valor predeterminado. Conviene probarlo y comparar."
    }


    # Power plan

    $Plan =
        Get-PusiActivePowerPlan


    if ($Plan -eq "Plan energia Pusi") {

        Good "Plan energia Pusi está activo."
    }
    else {

        Recommend "Plan actual: $Plan."
    }


    # Trim

    if (Test-PusiTrim) {

        Good "TRIM está habilitado."
    }
    else {

        Warning "No se pudo confirmar TRIM."
    }


    # Storage

    $Storage =
        Get-PusiStorageInfo


    if (
        $Storage.PercentFree -ne "?"
    ) {

        if (
            $Storage.PercentFree -lt 10
        ) {

            Warning "Unidad C: casi llena. Solo queda $($Storage.PercentFree)% libre."
        }
        elseif (
            $Storage.PercentFree -lt 20
        ) {

            Recommend "Conviene liberar espacio en C:. Queda $($Storage.PercentFree)%."
        }
        else {

            Good "Espacio libre en C: correcto."
        }
    }


    # RAM

    $SpeedNumber =
        0


    [int]::TryParse(
        (
            $Hardware.RAMSpeed `
                -replace '[^\d]',
            ''
        ),
        [ref]$SpeedNumber
    ) |
    Out-Null


    if (
        $SpeedNumber -gt 0 -and
        $SpeedNumber -le 2400
    ) {

        Recommend "RAM a $($Hardware.RAMSpeed). Revisar XMP/EXPO en BIOS."
    }
    else {

        Good "RAM detectada a $($Hardware.RAMSpeed)."
    }


    if (
        $Hardware.RAMModules -eq 1
    ) {

        Recommend "Solo se detecta un módulo de RAM. Conviene revisar configuración de memoria."
    }


    # Refresh rate

    $DisplayNow =
        Get-PusiDisplay


    $RefreshNumber =
        0


    [int]::TryParse(
        (
            $DisplayNow.Refresh `
                -replace '[^\d]',
            ''
        ),
        [ref]$RefreshNumber
    ) |
    Out-Null


    if (
        $RefreshNumber -gt 0 -and
        $RefreshNumber -le 60
    ) {

        Recommend "Pantalla funcionando actualmente a $($DisplayNow.Refresh). Revisar si el monitor admite una frecuencia superior."
    }
    elseif (
        $RefreshNumber -gt 60
    ) {

        Good "Pantalla funcionando a $($DisplayNow.Refresh)."
    }


    # Startup

    $Startup =
        Get-PusiStartupCount


    if ($Startup -ge 25) {

        Warning "$Startup elementos detectados en inicio automático."
    }
    elseif ($Startup -ge 15) {

        Recommend "$Startup elementos configurados al inicio. Conviene revisarlos."
    }
    else {

        Good "$Startup elementos detectados al inicio."
    }


    # Restart

    if (Test-PusiPendingRestart) {

        Recommend "Windows tiene un reinicio pendiente."
    }
    else {

        Good "No hay reinicio pendiente."
    }


    # Laptop

    if ($Hardware.Type -eq "PORTÁTIL") {

        Recommend "Portátil detectado: evitar perfiles agresivos cuando se use batería."
    }


    # Driver GPU age - only informational

    if (
        $Hardware.GPUDriver -ne "?"
    ) {

        Good "Driver GPU detectado: $($Hardware.GPUDriver)."
    }


    # Final

    $Good =
        $script:TmpGood


    $Recommended =
        $script:TmpRecommended


    $Warnings =
        $script:TmpWarnings


    (C "StatusCounts").Text =
        "$Good correctos | $Recommended recomendaciones | $Warnings avisos"


    if ($Warnings -gt 0) {

        (C "OverallStatus").Text =
            "Hay elementos que conviene revisar."

        (C "OverallStatus").Foreground =
            "#E98967"

    }
    elseif ($Recommended -gt 0) {

        (C "OverallStatus").Text =
            "Equipo operativo. Hay recomendaciones disponibles."

        (C "OverallStatus").Foreground =
            "#E5A64B"

    }
    else {

        (C "OverallStatus").Text =
            "Equipo preparado para gaming."

        (C "OverallStatus").Foreground =
            "#63D89A"
    }
}


# ============================================================
# ACTUALIZAR ESTADOS
# ============================================================

function Update-PusiSummary {

    $StatusBar.Text =
        "Analizando equipo..."


    Update-PusiHardwareCards


    # GAME MODE

    $GameMode =
        (
            Get-PusiRegValue `
                "HKCU:\Software\Microsoft\GameBar" `
                "AutoGameModeEnabled"
        ) -eq 1


    if ($GameMode) {

        Set-PusiGood `
            (C "StateGameMode") `
            "ACTIVO"

    }
    else {

        Set-PusiWarning `
            (C "StateGameMode") `
            "INACTIVO"
    }


    # DVR

    $DVR =
        (
            Get-PusiRegValue `
                "HKCU:\System\GameConfigStore" `
                "GameDVR_Enabled"
        ) -ne 0


    if ($DVR) {

        Set-PusiWarning `
            (C "StateGameDVR") `
            "ACTIVO"

    }
    else {

        Set-PusiGood `
            (C "StateGameDVR") `
            "DESACTIVADO"
    }


    # HAGS

    $HAGS =
        Get-PusiHAGS


    if ($HAGS -eq "ACTIVO") {

        Set-PusiGood `
            (C "StateHAGS") `
            "ACTIVO"

    }
    else {

        Set-PusiWarning `
            (C "StateHAGS") `
            $HAGS
    }


    # POWER THROTTLING

    $PT =
        (
            Get-PusiRegValue `
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
                "PowerThrottlingOff"
        ) -eq 1


    if ($PT) {

        Set-PusiGood `
            (C "StatePowerThrottling") `
            "DESACTIVADO"

    }
    else {

        Set-PusiWarning `
            (C "StatePowerThrottling") `
            "ACTIVO"
    }


    # POWER PLAN

    $Plan =
        Get-PusiActivePowerPlan


    (C "StatePowerPlan").Text =
        $Plan


    (C "PowerPlanText").Text =
        "Plan actual: $Plan"


    if (
        $Plan -eq
        "Plan energia Pusi"
    ) {

        (C "StatePowerPlan").Foreground =
            "#63D89A"

    }
    else {

        (C "StatePowerPlan").Foreground =
            "#E5A64B"
    }


    # TRIM

    if (Test-PusiTrim) {

        Set-PusiGood `
            (C "StateTrim") `
            "ACTIVO"

    }
    else {

        Set-PusiWarning `
            (C "StateTrim") `
            "REVISAR"
    }


    # VBS

    $VBS =
        Get-PusiVBS


    Set-PusiNeutral `
        (C "StateVBS") `
        $VBS


    # STARTUP

    $Startup =
        Get-PusiStartupCount


    (C "StateStartup").Text =
        "$Startup"


    if ($Startup -ge 25) {

        (C "StateStartup").Foreground =
            "#E98967"

    }
    elseif ($Startup -ge 15) {

        (C "StateStartup").Foreground =
            "#E5A64B"

    }
    else {

        (C "StateStartup").Foreground =
            "#63D89A"
    }


    # PROCESS

    $Processes =
        @(
            Get-Process `
                -ErrorAction SilentlyContinue
        ).Count


    (C "StateProcesses").Text =
        "$Processes"


    # RESTART

    $PendingRestart =
        Test-PusiPendingRestart

    if ($PendingRestart -or $script:NeedsRestart) {

        (C "RestartIndicator").Text =
            "REINICIO: PENDIENTE"

        (C "RestartIndicator").Foreground =
            "#E5A64B"

    }
    else {

        (C "RestartIndicator").Text =
            "REINICIO: NO"

        (C "RestartIndicator").Foreground =
            "#63D89A"
    }


    Invoke-PusiAnalysis


    $StatusBar.Text =
        "Análisis actualizado."
}


# ============================================================
# SNAPSHOT ANTES
# ============================================================

(C "SaveInitialState").Add_Click({

    $script:InitialSnapshot =
        Get-PusiSnapshot


    (C "BeforeProcesses").Text =
        "$($script:InitialSnapshot.Procesos)"


    (C "BeforeRAM").Text =
        "$($script:InitialSnapshot.RAMUsada) GB"


    (C "BeforePower").Text =
        "$($script:InitialSnapshot.Plan)"


    (C "BeforeDVR").Text =
        if ($script:InitialSnapshot.GameDVR) {
            "ACTIVO"
        }
        else {
            "DESACTIVADO"
        }


    (C "BeforeStorage").Text =
        "$($script:InitialSnapshot.FreeSpace) GB"


    (C "BeforeStartup").Text =
        "$($script:InitialSnapshot.Startup)"


    $StatusBar.Text =
        "Estado inicial guardado."
})


# ============================================================
# COMPARAR
# ============================================================

(C "CompareState").Add_Click({

    if (-not $script:InitialSnapshot) {

        [System.Windows.MessageBox]::Show(
            "Primero pulsa GUARDAR ESTADO INICIAL.",
            "PUSI OPTI",
            "OK",
            "Information"
        )

        return
    }


    $script:LastSnapshot =
        Get-PusiSnapshot


    (C "AfterProcesses").Text =
        "$($script:LastSnapshot.Procesos)"


    (C "AfterRAM").Text =
        "$($script:LastSnapshot.RAMUsada) GB"


    (C "AfterPower").Text =
        "$($script:LastSnapshot.Plan)"


    (C "AfterDVR").Text =
        if ($script:LastSnapshot.GameDVR) {
            "ACTIVO"
        }
        else {
            "DESACTIVADO"
        }


    (C "AfterStorage").Text =
        "$($script:LastSnapshot.FreeSpace) GB"


    (C "AfterStartup").Text =
        "$($script:LastSnapshot.Startup)"


    $StatusBar.Text =
        "Comparación actualizada."
})


# ============================================================
# INFORME
# ============================================================

function Get-PusiReport {

    $Snapshot =
        Get-PusiSnapshot


    $Storage =
        Get-PusiStorageInfo


    $DisplayNow =
        Get-PusiDisplay


    return @"

PUSI OPTI - INFORME
Versión $script:PusiVersion

=========================
HARDWARE
=========================

CPU:
$($Hardware.CPU)
$($Hardware.Cores) núcleos / $($Hardware.Threads) hilos

GPU:
$($Hardware.GPU)

Driver GPU:
$($Hardware.GPUDriver)

RAM:
$($Hardware.RAM)
$($Hardware.RAMSpeed)
Módulos detectados: $($Hardware.RAMModules)

Monitor:
$($DisplayNow.Resolution)
$($DisplayNow.Refresh)

Almacenamiento:
$($Storage.Bus) $($Storage.Media)
$($Storage.FreeGB) GB libres de $($Storage.TotalGB) GB

Windows:
$($Hardware.Windows)
Build $($Hardware.Build)

Equipo:
$($Hardware.Type)


=========================
ESTADO GAMING
=========================

Game Mode:
$(if($Snapshot.GameMode){"ACTIVO"}else{"INACTIVO"})

Game DVR:
$(if($Snapshot.GameDVR){"ACTIVO"}else{"DESACTIVADO"})

HAGS:
$($Snapshot.HAGS)

Plan de energía:
$($Snapshot.Plan)

TRIM:
$(if(Test-PusiTrim){"ACTIVO"}else{"NO CONFIRMADO"})

VBS:
$(Get-PusiVBS)

Procesos:
$($Snapshot.Procesos)

RAM usada:
$($Snapshot.RAMUsada) GB

Programas al inicio:
$($Snapshot.Startup)

Reinicio pendiente:
$(if($Snapshot.Restart){"SÍ"}else{"NO"})


=========================
PUSI OPTI
=========================

"@
}


(C "CopyReport").Add_Click({

    Set-Clipboard `
        -Value (
            Get-PusiReport
        )


    $StatusBar.Text =
        "Informe copiado."


    [System.Windows.MessageBox]::Show(
        "Informe PUSI copiado al portapapeles.",
        "PUSI OPTI",
        "OK",
        "Information"
    )
})


# ============================================================
# ANALIZAR
# ============================================================

(C "AnalyzePC").Add_Click({

    Update-PusiSummary
})


(C "RefreshAll").Add_Click({

    Update-PusiSummary
})


# ============================================================
# SELECCION
# ============================================================

function Clear-PusiSelection {

    foreach ($Name in $Options) {

        (C $Name).IsChecked =
            $false
    }
}


(C "ClearSelection").Add_Click({

    Clear-PusiSelection
})


(C "PresetSafe").Add_Click({

    Clear-PusiSelection


    @(

        "OptRestorePoint",

        "OptConsumerFeatures",

        "OptSearchWeb",

        "OptWidgets",

        "OptAnimations",

        "OptTransparency",

        "OptExtensions"

    ) |
    ForEach-Object {

        (C $_).IsChecked =
            $true
    }
})


(C "PresetRecommended").Add_Click({

    Clear-PusiSelection


    @(

        "OptRestorePoint",

        "OptTelemetry",

        "OptActivityHistory",

        "OptConsumerFeatures",

        "OptDelivery",

        "OptSearchWeb",

        "OptWidgets",

        "OptGameDVR",

        "OptGameMode",

        "OptExtensions",

        "OptMouseAcceleration",

        "OptStickyKeys",

        "OptTaskbarSearch",

        "OptStartRecommendations"

    ) |
    ForEach-Object {

        (C $_).IsChecked =
            $true
    }
})


(C "PresetGaming").Add_Click({

    Clear-PusiSelection


    @(

        "OptRestorePoint",

        "OptTelemetry",

        "OptActivityHistory",

        "OptConsumerFeatures",

        "OptDelivery",

        "OptSearchWeb",

        "OptWidgets",

        "OptGameDVR",

        "OptGameMode",

        "OptHAGS",

        "OptPowerThrottling",

        "OptBackgroundApps",

        "OptAnimations",

        "OptTransparency",

        "OptTaskbarAnimations",

        "OptVisualPerformance",

        "OptMouseAcceleration",

        "OptStickyKeys",

        "OptTaskbarSearch",

        "OptTaskView",

        "OptStartRecommendations"

    ) |
    ForEach-Object {

        (C $_).IsChecked =
            $true
    }
})


(C "PresetAggressive").Add_Click({

    foreach ($Name in $Options) {

        if ($Name -ne "OptDeepClean") {

            (C $Name).IsChecked =
                $true
        }
    }
})


# ============================================================
# APLICAR RECOMENDACIONES SEGURAS
# ============================================================

(C "ApplySafeRecommendations").Add_Click({

    $Confirm =
        [System.Windows.MessageBox]::Show(
            "PUSI aplicará únicamente recomendaciones consideradas seguras/recomendadas.`n`nNo se aplicará automáticamente Power Throttling, VBS ni otros ajustes agresivos.`n`n¿Continuar?",
            "PUSI OPTI",
            "YesNo",
            "Question"
        )


    if ($Confirm -ne "Yes") {

        return
    }


    New-PusiRestorePoint |
        Out-Null


    # Game Mode

    Set-PusiDWORD `
        "HKCU:\Software\Microsoft\GameBar" `
        "AutoGameModeEnabled" `
        1 |
        Out-Null


    # Game DVR

    Set-PusiDWORD `
        "HKCU:\System\GameConfigStore" `
        "GameDVR_Enabled" `
        0 |
        Out-Null


    Set-PusiDWORD `
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
        "AppCaptureEnabled" `
        0 |
        Out-Null


    # Widgets

    Set-PusiDWORD `
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
        "TaskbarDa" `
        0 |
        Out-Null


    # Search web

    Set-PusiDWORD `
        "HKCU:\Software\Policies\Microsoft\Windows\Explorer" `
        "DisableSearchBoxSuggestions" `
        1 |
        Out-Null


    # Consumer features

    Set-PusiDWORD `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
        "DisableWindowsConsumerFeatures" `
        1 |
        Out-Null


    $script:NeedsRestart =
        $true


    Update-PusiSummary


    [System.Windows.MessageBox]::Show(
        "Recomendaciones seguras aplicadas.`n`nNo se han aplicado ajustes agresivos.`n`nSe recomienda reiniciar Windows.",
        "PUSI OPTI",
        "OK",
        "Information"
    )
})


# ============================================================
# BUSCADOR
# ============================================================

(C "SearchTweaks").Add_TextChanged({

    $Search =
        (C "SearchTweaks").Text.ToLower().Trim()


    foreach ($Name in $Options) {

        $Control =
            C $Name


        $Text =
            $Control.Content.ToString().ToLower()


        if (
            [string]::IsNullOrWhiteSpace($Search) -or
            $Text.Contains($Search)
        ) {

            $Control.Visibility =
                "Visible"

        }
        else {

            $Control.Visibility =
                "Collapsed"
        }
    }
})


# ============================================================
# PLAN PUSI
# ============================================================

(C "EnablePusiPower").Add_Click({

    if ($Hardware.Type -eq "PORTÁTIL") {

        $Confirm =
            [System.Windows.MessageBox]::Show(
                "Se ha detectado un portátil.`n`nPlan energia Pusi aumenta consumo y puede elevar temperaturas.`n`n¿Continuar?",
                "PUSI OPTI",
                "YesNo",
                "Warning"
            )


        if ($Confirm -ne "Yes") {

            return
        }
    }


    $StatusBar.Text =
        "Activando Plan energia Pusi..."


    if (-not (Enable-PusiPowerPlan)) {

        [System.Windows.MessageBox]::Show(
            "No se pudo activar Plan energia Pusi.`n`nComprueba que Bitsum-Highest-Performance.pow sigue en GitHub.",
            "PUSI OPTI",
            "OK",
            "Error"
        )
    }


    Update-PusiSummary
})


(C "EnableBalanced").Add_Click({

    powercfg /setactive SCHEME_BALANCED |
        Out-Null


    Update-PusiSummary
})


# ============================================================
# BACKUP SELECCIONADOS
# ============================================================

function Backup-PusiSelected {

    $Entries = @(

        @(
            "OptTelemetry",
            "Telemetry",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
            "AllowTelemetry"
        ),

        @(
            "OptGameMode",
            "GameMode",
            "HKCU:\Software\Microsoft\GameBar",
            "AutoGameModeEnabled"
        ),

        @(
            "OptGameDVR",
            "GameDVR",
            "HKCU:\System\GameConfigStore",
            "GameDVR_Enabled"
        ),

        @(
            "OptHAGS",
            "HAGS",
            "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers",
            "HwSchMode"
        ),

        @(
            "OptPowerThrottling",
            "PowerThrottle",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling",
            "PowerThrottlingOff"
        ),

        @(
            "OptAnimations",
            "Animations",
            "HKCU:\Control Panel\Desktop\WindowMetrics",
            "MinAnimate"
        ),

        @(
            "OptTransparency",
            "Transparency",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize",
            "EnableTransparency"
        ),

        @(
            "OptExtensions",
            "Extensions",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
            "HideFileExt"
        ),

        @(
            "OptHiddenFiles",
            "HiddenFiles",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
            "Hidden"
        ),

        @(
            "OptLongPaths",
            "LongPaths",
            "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem",
            "LongPathsEnabled"
        ),

        @(
            "OptTaskbarSearch",
            "TaskbarSearch",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search",
            "SearchboxTaskbarMode"
        ),

        @(
            "OptTaskView",
            "TaskView",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
            "ShowTaskViewButton"
        )
    )


    foreach ($Entry in $Entries) {

        if ((C $Entry[0]).IsChecked) {

            Backup-PusiRegValue `
                $Entry[1] `
                $Entry[2] `
                $Entry[3]
        }
    }


    if ($script:SessionBackup.Count -gt 0) {

        (C "BackupStatus").Text =
            "BACKUP SESIÓN: OK"


        (C "BackupStatus").Foreground =
            "#63D89A"
    }
}


# ============================================================
# APLICAR SELECCIONADOS
# ============================================================

(C "ApplySelected").Add_Click({

    $Selected =
        @(
            $Options |
            Where-Object {

                (C $_).IsChecked
            }
        )


    if ($Selected.Count -eq 0) {

        [System.Windows.MessageBox]::Show(
            "No hay ningún ajuste seleccionado.",
            "PUSI OPTI",
            "OK",
            "Information"
        )

        return
    }


    $Confirm =
        [System.Windows.MessageBox]::Show(
            "Se aplicarán $($Selected.Count) ajustes.`n`nPUSI guardará los valores originales de esta sesión cuando sea posible.`n`n¿Continuar?",
            "PUSI OPTI",
            "YesNo",
            "Question"
        )


    if ($Confirm -ne "Yes") {

        return
    }


    Reset-PusiResults

    Backup-PusiSelected


    $Progress.Value =
        0


    $Total =
        $Selected.Count


    $script:CurrentStep =
        0


    function Step {

        param(
            [string]$Text
        )


        $script:CurrentStep++


        $Progress.Value =
            (
                $script:CurrentStep /
                $Total
            ) * 100


        $StatusBar.Text =
            $Text


        $Window.Dispatcher.Invoke(
            [action]{},
            "Background"
        )
    }


    $Freed =
        $null


    if ((C "OptRestorePoint").IsChecked) {

        Step "Creando punto de restauración..."


        if (New-PusiRestorePoint) {

            Add-PusiResult "OK"

        }
        else {

            Add-PusiResult "OMITIDO"
        }
    }


    if ((C "OptTelemetry").IsChecked) {

        Step "Desactivando telemetría..."


        if (
            Set-PusiDWORD `
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
                "AllowTelemetry" `
                0
        ) {

            Add-PusiResult "OK"

        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    if ((C "OptActivityHistory").IsChecked) {

        Step "Desactivando historial de actividad..."


        Set-PusiDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "EnableActivityFeed" `
            0 |
            Out-Null


        Set-PusiDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "PublishUserActivities" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptConsumerFeatures").IsChecked) {

        Step "Desactivando contenido promocional..."


        Set-PusiDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
            "DisableWindowsConsumerFeatures" `
            1 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptDelivery").IsChecked) {

        Step "Configurando Delivery Optimization..."


        Set-PusiDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" `
            "DODownloadMode" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptSearchWeb").IsChecked) {

        Step "Desactivando búsqueda web..."


        Set-PusiDWORD `
            "HKCU:\Software\Policies\Microsoft\Windows\Explorer" `
            "DisableSearchBoxSuggestions" `
            1 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptWidgets").IsChecked) {

        Step "Ocultando Widgets..."


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarDa" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptGameDVR").IsChecked) {

        Step "Desactivando Game DVR..."


        Set-PusiDWORD `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_Enabled" `
            0 |
            Out-Null


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
            "AppCaptureEnabled" `
            0 |
            Out-Null


        $script:NeedsRestart =
            $true


        Add-PusiResult "OK"
    }


    if ((C "OptDeepClean").IsChecked) {

        Step "Ejecutando limpieza profunda..."


        $Freed =
            Invoke-PusiDeepCleanup `
                $StatusBar


        Add-PusiResult "OK"
    }


    if ((C "OptGameMode").IsChecked) {

        Step "Activando Game Mode..."


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\GameBar" `
            "AutoGameModeEnabled" `
            1 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptHAGS").IsChecked) {

        Step "Activando HAGS..."


        Set-PusiDWORD `
            "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
            "HwSchMode" `
            2 |
            Out-Null


        $script:NeedsRestart =
            $true


        Add-PusiResult "OK"
    }


    if ((C "OptPowerThrottling").IsChecked) {

        Step "Desactivando Power Throttling..."


        Set-PusiDWORD `
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
            "PowerThrottlingOff" `
            1 |
            Out-Null


        $script:NeedsRestart =
            $true


        Add-PusiResult "OK"
    }


    if ((C "OptBackgroundApps").IsChecked) {

        Step "Reduciendo aplicaciones en segundo plano..."


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
            "GlobalUserDisabled" `
            1 |
            Out-Null


        $script:NeedsRestart =
            $true


        Add-PusiResult "OK"
    }


    if ((C "OptAnimations").IsChecked) {

        Step "Desactivando animaciones..."


        Set-PusiString `
            "HKCU:\Control Panel\Desktop\WindowMetrics" `
            "MinAnimate" `
            "0" |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptTransparency").IsChecked) {

        Step "Desactivando transparencias..."


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            "EnableTransparency" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptTaskbarAnimations").IsChecked) {

        Step "Desactivando animaciones de barra..."


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarAnimations" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptVisualPerformance").IsChecked) {

        Step "Configurando efectos visuales..."


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
            "VisualFXSetting" `
            2 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptExtensions").IsChecked) {

        Step "Mostrando extensiones..."


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "HideFileExt" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptHiddenFiles").IsChecked) {

        Step "Mostrando archivos ocultos..."


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Hidden" `
            1 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptLongPaths").IsChecked) {

        Step "Activando rutas largas..."


        Set-PusiDWORD `
            "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
            "LongPathsEnabled" `
            1 |
            Out-Null


        $script:NeedsRestart =
            $true


        Add-PusiResult "OK"
    }


    if ((C "OptMouseAcceleration").IsChecked) {

        Step "Desactivando aceleración del ratón..."


        Set-PusiString `
            "HKCU:\Control Panel\Mouse" `
            "MouseSpeed" `
            "0" |
            Out-Null


        Set-PusiString `
            "HKCU:\Control Panel\Mouse" `
            "MouseThreshold1" `
            "0" |
            Out-Null


        Set-PusiString `
            "HKCU:\Control Panel\Mouse" `
            "MouseThreshold2" `
            "0" |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptStickyKeys").IsChecked) {

        Step "Configurando Sticky Keys..."


        Set-PusiString `
            "HKCU:\Control Panel\Accessibility\StickyKeys" `
            "Flags" `
            "506" |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptTaskbarSearch").IsChecked) {

        Step "Ocultando búsqueda..."


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
            "SearchboxTaskbarMode" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptTaskView").IsChecked) {

        Step "Ocultando Vista de tareas..."


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "ShowTaskViewButton" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ((C "OptStartRecommendations").IsChecked) {

        Step "Reduciendo recomendaciones..."


        Set-PusiDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Start_IrisRecommendations" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    $Progress.Value =
        100


    Update-PusiSummary


    $Message =
        "Optimización completada.`n`n" +
        "Correctos: $script:ResultadosOK`n" +
        "Errores: $script:ResultadosError`n" +
        "Omitidos: $script:ResultadosOmitidos"


    if ($Freed) {

        $Message +=
            "`nEspacio liberado: $Freed"
    }


    if ($script:NeedsRestart) {

        $Message +=
            "`n`nSe recomienda reiniciar Windows."
    }


    [System.Windows.MessageBox]::Show(
        $Message,
        "PUSI OPTI",
        "OK",
        "Information"
    )
})


# ============================================================
# REVERTIR SESION
# ============================================================

(C "RevertSelected").Add_Click({

    if ($script:SessionBackup.Count -eq 0) {

        [System.Windows.MessageBox]::Show(
            "No existe backup de cambios en esta sesión.`n`nSi PUSI ya fue cerrado, utiliza el punto de restauración.",
            "PUSI OPTI",
            "OK",
            "Information"
        )

        return
    }


    $RestoreMap = @{

        OptTelemetry =
            @("Telemetry")

        OptGameMode =
            @("GameMode")

        OptGameDVR =
            @("GameDVR")

        OptHAGS =
            @("HAGS")

        OptPowerThrottling =
            @("PowerThrottle")

        OptAnimations =
            @("Animations")

        OptTransparency =
            @("Transparency")

        OptExtensions =
            @("Extensions")

        OptHiddenFiles =
            @("HiddenFiles")

        OptLongPaths =
            @("LongPaths")

        OptTaskbarSearch =
            @("TaskbarSearch")

        OptTaskView =
            @("TaskView")
    }


    $Count =
        0


    foreach ($Option in $RestoreMap.Keys) {

        if ((C $Option).IsChecked) {

            foreach ($ID in $RestoreMap[$Option]) {

                if (
                    Restore-PusiRegValue `
                        $ID
                ) {

                    $Count++
                }
            }
        }
    }


    $script:NeedsRestart =
        $true


    Update-PusiSummary


    [System.Windows.MessageBox]::Show(
        "Valores restaurados: $Count`n`nSe recomienda reiniciar Windows.",
        "PUSI OPTI",
        "OK",
        "Information"
    )
})


# ============================================================
# SFC / DISM
# ============================================================

(C "RunSFC").Add_Click({

    Start-Process `
        powershell.exe `
        -Verb RunAs `
        -ArgumentList `
        '-NoExit -Command "sfc /scannow"'
})


(C "RunDISM").Add_Click({

    Start-Process `
        powershell.exe `
        -Verb RunAs `
        -ArgumentList `
        '-NoExit -Command "DISM /Online /Cleanup-Image /RestoreHealth"'
})


# ============================================================
# RED
# ============================================================

(C "FlushDNS").Add_Click({

    ipconfig /flushdns |
        Out-Null


    $StatusBar.Text =
        "Caché DNS limpiada."
})


(C "ResetNetwork").Add_Click({

    $Confirm =
        [System.Windows.MessageBox]::Show(
            "Se restablecerán Winsock y TCP/IP.`n`nSerá necesario reiniciar Windows.`n`n¿Continuar?",
            "PUSI OPTI",
            "YesNo",
            "Warning"
        )


    if ($Confirm -eq "Yes") {

        netsh winsock reset |
            Out-Null


        netsh int ip reset |
            Out-Null


        $script:NeedsRestart =
            $true


        Update-PusiSummary
    }
})


# ============================================================
# LIMPIEZA
# ============================================================

(C "DeepCleanup").Add_Click({

    $Freed =
        Invoke-PusiDeepCleanup `
            $StatusBar


    [System.Windows.MessageBox]::Show(
        "Limpieza terminada.`n`nLiberado aproximadamente: $Freed`n`nNo se han eliminado contraseñas, cookies ni favoritos.",
        "PUSI OPTI",
        "OK",
        "Information"
    )


    Update-PusiSummary
})


(C "EmptyRecycle").Add_Click({

    Clear-RecycleBin `
        -Force `
        -ErrorAction SilentlyContinue


    Update-PusiSummary
})


# ============================================================
# TRIM
# ============================================================

(C "CheckTrim").Add_Click({

    $Result =
        fsutil behavior query DisableDeleteNotify


    [System.Windows.MessageBox]::Show(
        "$Result`n`nNTFS DisableDeleteNotify = 0 significa TRIM habilitado.",
        "PUSI OPTI",
        "OK",
        "Information"
    )
})


(C "OptimizeStorage").Add_Click({

    $StatusBar.Text =
        "Ejecutando ReTrim..."


    Get-Volume |
    Where-Object {

        $_.DriveLetter -and
        $_.DriveType -eq "Fixed"

    } |
    ForEach-Object {

        Optimize-Volume `
            -DriveLetter $_.DriveLetter `
            -ReTrim `
            -ErrorAction SilentlyContinue |
            Out-Null
    }


    $StatusBar.Text =
        "ReTrim terminado."
})


# ============================================================
# ACCESOS RAPIDOS
# ============================================================

(C "OpenStartupApps").Add_Click({

    try {

        Start-Process "ms-settings:startupapps"

        $StatusBar.Text =
            "Abriendo aplicaciones de inicio."

    }
    catch {

        [System.Windows.MessageBox]::Show(
            "No se pudo abrir Aplicaciones de inicio.",
            "PUSI OPTI",
            "OK",
            "Error"
        )
    }
})


(C "OpenGraphicsSettings").Add_Click({

    try {

        Start-Process "ms-settings:display-advancedgraphics"

        $StatusBar.Text =
            "Abriendo configuración de gráficos."

    }
    catch {

        try {

            Start-Process "ms-settings:display"

        }
        catch {}
    }
})


(C "OpenAdvancedDisplay").Add_Click({

    try {

        Start-Process "ms-settings:display-advanced"

        $StatusBar.Text =
            "Abriendo configuración de pantalla avanzada."

    }
    catch {

        try {

            Start-Process "ms-settings:display"

        }
        catch {}
    }
})


(C "OpenPowerOptions").Add_Click({

    try {

        Start-Process "control.exe" `
            -ArgumentList "/name Microsoft.PowerOptions"

        $StatusBar.Text =
            "Abriendo Opciones de energía."

    }
    catch {

        [System.Windows.MessageBox]::Show(
            "No se pudieron abrir las Opciones de energía.",
            "PUSI OPTI",
            "OK",
            "Error"
        )
    }
})


(C "CreateRestorePointNow").Add_Click({

    $StatusBar.Text =
        "Creando punto de restauración..."


    if (New-PusiRestorePoint) {

        [System.Windows.MessageBox]::Show(
            "Punto de restauración creado correctamente.",
            "PUSI OPTI",
            "OK",
            "Information"
        )

        $StatusBar.Text =
            "Punto de restauración creado."

    }
    else {

        [System.Windows.MessageBox]::Show(
            "Windows no permitió crear el punto de restauración.`n`nPuede existir otro creado recientemente o Protección del sistema puede estar desactivada.",
            "PUSI OPTI",
            "OK",
            "Warning"
        )

        $StatusBar.Text =
            "No se pudo crear el punto de restauración."
    }
})


# ============================================================
# WINDOWS UPDATE
# ============================================================

function Set-PusiUpdatePause {

    param(
        [int]$Days
    )


    $Now =
        (Get-Date).ToUniversalTime()


    $End =
        $Now.AddDays($Days)


    Set-PusiString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesStartTime" `
        $Now.ToString(
            "yyyy-MM-ddTHH:mm:ssZ"
        ) |
        Out-Null


    Set-PusiString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesExpiryTime" `
        $End.ToString(
            "yyyy-MM-ddTHH:mm:ssZ"
        ) |
        Out-Null
}


(C "Pause7").Add_Click({

    Set-PusiUpdatePause 7


    $StatusBar.Text =
        "Pausa solicitada: 7 días."
})


(C "Pause35").Add_Click({

    Set-PusiUpdatePause 35


    $StatusBar.Text =
        "Pausa solicitada: 35 días."
})


(C "ResumeUpdates").Add_Click({

    Remove-PusiRegValue `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesStartTime" |
        Out-Null


    Remove-PusiRegValue `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesExpiryTime" |
        Out-Null


    $StatusBar.Text =
        "Pausa eliminada."
})


(C "DisableDriverUpdates").Add_Click({

    Set-PusiDWORD `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
        "ExcludeWUDriversInQualityUpdate" `
        1 |
        Out-Null


    $StatusBar.Text =
        "Drivers bloqueados en Windows Update."
})


(C "EnableDriverUpdates").Add_Click({

    Remove-PusiRegValue `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
        "ExcludeWUDriversInQualityUpdate" |
        Out-Null


    $StatusBar.Text =
        "Actualización de drivers restaurada."
})


(C "DisableWU").Add_Click({

    $Confirm =
        [System.Windows.MessageBox]::Show(
            "Esto puede impedir actualizaciones y parches de seguridad.`n`n¿Continuar?",
            "PUSI OPTI",
            "YesNo",
            "Warning"
        )


    if ($Confirm -ne "Yes") {

        return
    }


    Set-PusiDWORD `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        "NoAutoUpdate" `
        1 |
        Out-Null


    Stop-Service `
        wuauserv `
        -Force `
        -ErrorAction SilentlyContinue


    Set-Service `
        wuauserv `
        -StartupType Disabled `
        -ErrorAction SilentlyContinue


    $StatusBar.Text =
        "Windows Update desactivado."
})


(C "EnableWU").Add_Click({

    Remove-PusiRegValue `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        "NoAutoUpdate" |
        Out-Null


    Set-Service `
        wuauserv `
        -StartupType Manual `
        -ErrorAction SilentlyContinue


    Start-Service `
        wuauserv `
        -ErrorAction SilentlyContinue


    $StatusBar.Text =
        "Windows Update reactivado."
})


# ============================================================
# INICIO
# ============================================================

Update-PusiSelectionCounter

Update-PusiSummary

$Progress.Value =
    0


$Window.ShowDialog() |
    Out-Null
