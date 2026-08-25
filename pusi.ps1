# ============================================================
# PUSI OPTI
# Windows Optimization Utility
# VERSION 0.6
#
# Requiere:
#   - PowerShell como administrador
#   - Bitsum-Highest-Performance.pow en el repositorio
#
# ============================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase


# ============================================================
# CONFIGURACION GENERAL
# ============================================================

$script:PusiVersion = "0.6"

$script:PowURL =
    "https://raw.githubusercontent.com/pusichepas/PUSI-OPTI/main/Bitsum-Highest-Performance.pow"

$script:PusiPowerGuid =
    "7f34a6b5-1f2d-4c73-9b01-5b851dd62864"

$script:SessionBackup = @{}

$script:InitialSnapshot = $null
$script:LastSnapshot    = $null

$script:ResultadosOK       = 0
$script:ResultadosError    = 0
$script:ResultadosOmitidos = 0

$script:FreedBytes = 0
$script:NeedsRestart = $false


# ============================================================
# ADMINISTRADOR
# ============================================================

function Test-PusiAdmin {

    $Identity =
        [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal =
        New-Object Security.Principal.WindowsPrincipal($Identity)

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
            -Value $Value `
            -PropertyType DWord `
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
            -Value $Value `
            -PropertyType String `
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
# BACKUP EXACTO DE SESION
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
    $Kind  = $null

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
                $Key.GetValueKind($Name).ToString()
        }
        catch {}
    }


    $script:SessionBackup[$ID] = [PSCustomObject]@{

        Path   = $Path
        Name   = $Name
        Exists = $Exists
        Value  = $Value
        Kind   = $Kind
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
                    -Value ([int]$Data.Value) `
                    -PropertyType DWord `
                    -Force |
                    Out-Null
            }


            "QWord" {

                New-ItemProperty `
                    -Path $Data.Path `
                    -Name $Data.Name `
                    -Value ([long]$Data.Value) `
                    -PropertyType QWord `
                    -Force |
                    Out-Null
            }


            "ExpandString" {

                New-ItemProperty `
                    -Path $Data.Path `
                    -Name $Data.Name `
                    -Value ([string]$Data.Value) `
                    -PropertyType ExpandString `
                    -Force |
                    Out-Null
            }


            "MultiString" {

                New-ItemProperty `
                    -Path $Data.Path `
                    -Name $Data.Name `
                    -Value $Data.Value `
                    -PropertyType MultiString `
                    -Force |
                    Out-Null
            }


            default {

                New-ItemProperty `
                    -Path $Data.Path `
                    -Name $Data.Name `
                    -Value ([string]$Data.Value) `
                    -PropertyType String `
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

    $script:ResultadosOK       = 0
    $script:ResultadosError    = 0
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
# PUNTO DE RESTAURACION
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

    $Pending = $false


    $Paths = @(

        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",

        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    )


    foreach ($Path in $Paths) {

        if (Test-Path $Path) {

            $Pending = $true
        }
    }


    try {

        $Rename =
            Get-ItemProperty `
                "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
                -Name "PendingFileRenameOperations" `
                -ErrorAction SilentlyContinue

        if ($Rename) {

            $Pending = $true
        }
    }
    catch {}


    return $Pending
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


    $CS =
        Get-CimInstance Win32_ComputerSystem


    $OS =
        Get-CimInstance Win32_OperatingSystem


    $Battery =
        Get-CimInstance Win32_Battery `
            -ErrorAction SilentlyContinue


    $RAMModules =
        Get-CimInstance Win32_PhysicalMemory `
            -ErrorAction SilentlyContinue


    $RAMGB =
        [math]::Round(
            $CS.TotalPhysicalMemory / 1GB,
            0
        )


    $RAMSpeed =
        $RAMModules |
        Where-Object ConfiguredClockSpeed |
        Select-Object -ExpandProperty ConfiguredClockSpeed |
        Sort-Object -Descending |
        Select-Object -First 1


    if (-not $RAMSpeed) {

        $RAMSpeed = "?"
    }


    if ($Battery) {

        $Type = "PORTÁTIL"
    }
    else {

        $Type = "SOBREMESA"
    }


    return [PSCustomObject]@{

        CPU =
            $CPU.Name.Trim()

        GPU =
            if ($GPU) {
                $GPU.Name.Trim()
            }
            else {
                "No detectada"
            }

        RAM =
            "$RAMGB GB"

        RAMSpeed =
            "$RAMSpeed MT/s"

        Windows =
            $OS.Caption

        Build =
            $OS.BuildNumber

        Tipo =
            $Type
    }
}


# ============================================================
# ALMACENAMIENTO
# ============================================================

function Get-PusiStorageInfo {

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
                ($Drive.FreeSpace / $Drive.Size) * 100,
                0
            )


        return [PSCustomObject]@{

            FreeGB      = $FreeGB
            TotalGB     = $TotalGB
            PercentFree = $PercentFree
        }
    }
    catch {

        return $null
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

        return $false
    }
    catch {

        return $false
    }
}


# ============================================================
# PLAN ACTUAL
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


# ============================================================
# PLAN ENERGIA PUSI
# ============================================================

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


        powercfg /delete $script:PusiPowerGuid 2>$null |
            Out-Null


        powercfg /import `
            $TempPow `
            $script:PusiPowerGuid |
            Out-Null


        powercfg /changename `
            $script:PusiPowerGuid `
            "Plan energia Pusi" `
            "PUSI OPTI - Perfil de maximo rendimiento para sobremesa" |
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
                -Force `
                -Recurse `
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
        "Limpiando temporales de Windows..."


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


    # --------------------------------------------------------
    # CHROMIUM
    # --------------------------------------------------------

    $ChromiumRoots = @(

        "$env:LOCALAPPDATA\Google\Chrome\User Data",

        "$env:LOCALAPPDATA\Microsoft\Edge\User Data",

        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    )


    foreach ($Root in $ChromiumRoots) {

        if (-not (Test-Path $Root)) {

            continue
        }


        $Profiles =
            Get-ChildItem `
                $Root `
                -Directory `
                -ErrorAction SilentlyContinue |
            Where-Object {

                $_.Name -eq "Default" -or
                $_.Name -like "Profile *"
            }


        foreach ($Profile in $Profiles) {

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
                    "$($Profile.FullName)\$_"
            }
        }
    }


    # --------------------------------------------------------
    # OPERA
    # --------------------------------------------------------

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


    # --------------------------------------------------------
    # FIREFOX
    # --------------------------------------------------------

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


    # --------------------------------------------------------
    # MINIATURAS
    # --------------------------------------------------------

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


    # --------------------------------------------------------
    # PAPELERA
    # --------------------------------------------------------

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
# SNAPSHOT DEL SISTEMA
# ============================================================

function Get-PusiSnapshot {

    $OS =
        Get-CimInstance Win32_OperatingSystem


    $Processes =
        (
            Get-Process `
                -ErrorAction SilentlyContinue
        ).Count


    $MemoryUsed =
        (
            $OS.TotalVisibleMemorySize -
            $OS.FreePhysicalMemory
        ) * 1KB


    $MemoryUsedGB =
        [math]::Round(
            $MemoryUsed / 1GB,
            2
        )


    $Storage =
        Get-PusiStorageInfo


    return [PSCustomObject]@{

        Fecha =
            Get-Date

        Procesos =
            $Processes

        RAMUsada =
            $MemoryUsedGB

        PlanEnergia =
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

        PowerThrottlingOff =
            (
                Get-PusiRegValue `
                    "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
                    "PowerThrottlingOff"
            ) -eq 1

        FreeSpace =
            if ($Storage) {
                $Storage.FreeGB
            }
            else {
                "?"
            }

        Trim =
            Test-PusiTrim

        Reinicio =
            Test-PusiPendingRestart
    }
}


# ============================================================
# XAML
# ============================================================

[xml]$XAML = @"

<Window
 xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
 xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"

 Title="PUSI OPTI"

 Width="1320"
 Height="900"

 MinWidth="1120"
 MinHeight="720"

 WindowStartupLocation="CenterScreen"

 Background="#0D1015">


<Window.Resources>


    <Style TargetType="Button">

        <Setter Property="Background"
                Value="#202631"/>

        <Setter Property="Foreground"
                Value="White"/>

        <Setter Property="BorderBrush"
                Value="#394351"/>

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
                Value="White"/>

        <Setter Property="FontSize"
                Value="13"/>

        <Setter Property="Margin"
                Value="5"/>

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
                Value="#171C24"/>

        <Setter Property="FontSize"
                Value="14"/>

        <Setter Property="FontWeight"
                Value="SemiBold"/>

        <Setter Property="Padding"
                Value="24,11"/>

    </Style>


</Window.Resources>


<Grid>


<Grid.RowDefinitions>

    <RowDefinition Height="120"/>

    <RowDefinition Height="*"/>

    <RowDefinition Height="60"/>

</Grid.RowDefinitions>


<!-- ===================================================== -->
<!-- HEADER -->
<!-- ===================================================== -->

<Border
 Grid.Row="0"

 Background="#151A21"

 BorderBrush="#2D3540"

 BorderThickness="0,0,0,1">


<Grid Margin="24,12">


<Grid.ColumnDefinitions>

    <ColumnDefinition Width="260"/>

    <ColumnDefinition Width="*"/>

    <ColumnDefinition Width="300"/>

</Grid.ColumnDefinitions>


<StackPanel VerticalAlignment="Center">


    <TextBlock
     Text="PUSI OPTI"

     FontSize="34"

     FontWeight="Bold"/>


    <TextBlock
     Text="Windows Gaming Optimization"

     Foreground="#8A95A5"

     FontSize="13"/>


    <TextBlock
     x:Name="VersionText"

     Text="v0.6"

     Foreground="#586271"

     Margin="0,5,0,0"/>


</StackPanel>


<Grid
 Grid.Column="1"

 VerticalAlignment="Center">


<Grid.RowDefinitions>

    <RowDefinition/>

    <RowDefinition/>

    <RowDefinition/>

    <RowDefinition/>

</Grid.RowDefinitions>


<TextBlock
 x:Name="HeaderCPU"

 Grid.Row="0"

 Foreground="#D8DEE8"/>


<TextBlock
 x:Name="HeaderGPU"

 Grid.Row="1"

 Foreground="#D8DEE8"/>


<TextBlock
 x:Name="HeaderRAM"

 Grid.Row="2"

 Foreground="#A3ADBA"/>


<TextBlock
 x:Name="HeaderWindows"

 Grid.Row="3"

 Foreground="#A3ADBA"/>


</Grid>


<StackPanel
 Grid.Column="2"

 HorizontalAlignment="Right"

 VerticalAlignment="Center">


<TextBlock
 x:Name="HeaderSelection"

 Text="0 ajustes seleccionados"

 FontWeight="SemiBold"

 FontSize="14"

 HorizontalAlignment="Right"/>


<TextBlock
 x:Name="HeaderRestart"

 Text="REINICIO: NO"

 Foreground="#63D89A"

 FontWeight="Bold"

 Margin="0,6,0,0"

 HorizontalAlignment="Right"/>


<Button
 x:Name="RefreshAll"

 Content="ACTUALIZAR ESTADO"

 Width="190"

 Margin="0,9,0,0"/>


</StackPanel>


</Grid>


</Border>


<!-- ===================================================== -->
<!-- TABS -->
<!-- ===================================================== -->

<TabControl
 Grid.Row="1"

 Background="#0D1015"

 BorderBrush="#2D3540">


<!-- ===================================================== -->
<!-- RESUMEN -->
<!-- ===================================================== -->

<TabItem Header="RESUMEN">


<ScrollViewer
 VerticalScrollBarVisibility="Auto">


<StackPanel Margin="24">


<Grid>


<Grid.ColumnDefinitions>

    <ColumnDefinition Width="*"/>

    <ColumnDefinition Width="20"/>

    <ColumnDefinition Width="*"/>

</Grid.ColumnDefinitions>


<!-- ESTADO -->

<Border
 Grid.Column="0"

 Background="#151A21"

 BorderBrush="#2D3540"

 BorderThickness="1"

 CornerRadius="8"

 Padding="20">


<StackPanel>


<TextBlock
 Text="ESTADO DEL EQUIPO"

 FontSize="21"

 FontWeight="Bold"/>


<TextBlock
 Text="Análisis rápido de configuración y mantenimiento."

 Foreground="#8A95A5"

 Margin="0,5,0,18"/>


<Grid>


<Grid.ColumnDefinitions>

<ColumnDefinition Width="210"/>

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

<RowDefinition Height="32"/>

</Grid.RowDefinitions>


<TextBlock Grid.Row="0"
           Text="Game Mode"/>

<TextBlock
 x:Name="SummaryGameMode"
 Grid.Row="0"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="1"
           Text="Game DVR"/>

<TextBlock
 x:Name="SummaryGameDVR"
 Grid.Row="1"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="2"
           Text="Power Throttling"/>

<TextBlock
 x:Name="SummaryPowerThrottling"
 Grid.Row="2"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="3"
           Text="TRIM"/>

<TextBlock
 x:Name="SummaryTrim"
 Grid.Row="3"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="4"
           Text="Plan de energía"/>

<TextBlock
 x:Name="SummaryPowerPlan"
 Grid.Row="4"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="5"
           Text="Espacio libre C:"/>

<TextBlock
 x:Name="SummaryStorage"
 Grid.Row="5"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="6"
           Text="Reinicio pendiente"/>

<TextBlock
 x:Name="SummaryRestart"
 Grid.Row="6"
 Grid.Column="1"
 FontWeight="Bold"/>


<TextBlock Grid.Row="7"
           Text="Tipo de equipo"/>

<TextBlock
 x:Name="SummaryType"
 Grid.Row="7"
 Grid.Column="1"
 FontWeight="Bold"/>


</Grid>


</StackPanel>


</Border>


<!-- ANALISIS -->

<Border
 Grid.Column="2"

 Background="#151A21"

 BorderBrush="#2D3540"

 BorderThickness="1"

 CornerRadius="8"

 Padding="20">


<StackPanel>


<TextBlock
 Text="ANÁLISIS PUSI"

 FontSize="21"

 FontWeight="Bold"/>


<TextBlock
 Text="Incidencias y recomendaciones detectadas."

 Foreground="#8A95A5"

 Margin="0,5,0,15"/>


<TextBlock
 x:Name="AnalysisTotals"

 Text="Pulsa ANALIZAR PC."

 FontWeight="SemiBold"

 Margin="0,0,0,10"/>


<ListBox
 x:Name="AnalysisList"

 Height="230"

 Background="#10141A"

 Foreground="White"

 BorderBrush="#303947"/>


<WrapPanel Margin="0,12,0,0">


<Button
 x:Name="AnalyzePC"

 Content="ANALIZAR PC"

 Width="150"/>


<Button
 x:Name="CopyReport"

 Content="COPIAR INFORME"

 Width="170"/>


</WrapPanel>


</StackPanel>


</Border>


</Grid>


<!-- ANTES / DESPUES -->

<Border
 Background="#151A21"

 BorderBrush="#2D3540"

 BorderThickness="1"

 CornerRadius="8"

 Padding="20"

 Margin="0,20,0,0">


<StackPanel>


<TextBlock
 Text="ANTES / DESPUÉS"

 FontSize="21"

 FontWeight="Bold"/>


<TextBlock
 Text="Guarda el estado inicial y compáralo después de optimizar."

 Foreground="#8A95A5"

 Margin="0,5,0,15"/>


<Grid>


<Grid.ColumnDefinitions>

<ColumnDefinition Width="180"/>

<ColumnDefinition Width="*"/>

<ColumnDefinition Width="*"/>

</Grid.ColumnDefinitions>


<Grid.RowDefinitions>

<RowDefinition Height="34"/>

<RowDefinition Height="34"/>

<RowDefinition Height="34"/>

<RowDefinition Height="34"/>

<RowDefinition Height="34"/>

<RowDefinition Height="34"/>

</Grid.RowDefinitions>


<TextBlock
 Grid.Column="1"
 Text="ANTES"

 FontWeight="Bold"

 Foreground="#4FD6FF"/>


<TextBlock
 Grid.Column="2"
 Text="DESPUÉS"

 FontWeight="Bold"

 Foreground="#4FD6FF"/>


<TextBlock Grid.Row="1"
           Text="Procesos"/>

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


<TextBlock Grid.Row="2"
           Text="RAM usada"/>

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


<TextBlock Grid.Row="3"
           Text="Plan energía"/>

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


<TextBlock Grid.Row="4"
           Text="Game DVR"/>

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


<TextBlock Grid.Row="5"
           Text="Espacio libre C:"/>

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


</Grid>


<WrapPanel Margin="0,15,0,0">


<Button
 x:Name="SaveInitialState"

 Content="GUARDAR ESTADO INICIAL"

 Width="210"/>


<Button
 x:Name="CompareState"

 Content="COMPARAR RESULTADOS"

 Width="210"/>


</WrapPanel>


</StackPanel>


</Border>


</StackPanel>


</ScrollViewer>


</TabItem>


<!-- ===================================================== -->
<!-- OPTIMIZACION -->
<!-- ===================================================== -->

<TabItem Header="OPTIMIZACIÓN">


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
 Text="Selecciona únicamente los ajustes que quieras modificar."

 Foreground="#8A95A5"

 Margin="0,4,0,0"/>


</StackPanel>


<TextBox
 x:Name="SearchTweaks"

 Grid.Column="1"

 Height="34"

 VerticalContentAlignment="Center"

 Background="#151A21"

 Foreground="White"

 BorderBrush="#35404D"

 Padding="10,0"

 Text=""/>


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


<!-- IZQUIERDA -->

<StackPanel
 x:Name="LeftTweaks"

 Grid.Column="0">


<TextBlock
 Text="SISTEMA Y PRIVACIDAD"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<CheckBox
 x:Name="OptRestorePoint"

 Content="Crear punto de restauración"

 ToolTip="SEGURO - Crea una copia de restauración antes de modificar el sistema."/>


<CheckBox
 x:Name="OptTelemetry"

 Content="Desactivar telemetría"

 ToolTip="RECOMENDADO - Reduce la telemetría permitida mediante políticas de Windows."/>


<CheckBox
 x:Name="OptActivityHistory"

 Content="Desactivar historial de actividad"

 ToolTip="RECOMENDADO - Desactiva Activity Feed y publicación de actividades."/>


<CheckBox
 x:Name="OptConsumerFeatures"

 Content="Desactivar contenido promocional"

 ToolTip="SEGURO - Reduce sugerencias y Consumer Features de Windows."/>


<CheckBox
 x:Name="OptDelivery"

 Content="Desactivar Delivery Optimization P2P"

 ToolTip="RECOMENDADO - Evita compartir descargas de Windows Update mediante P2P."/>


<CheckBox
 x:Name="OptSearchWeb"

 Content="Desactivar resultados web en Inicio"

 ToolTip="SEGURO - Reduce resultados web en la búsqueda del menú Inicio."/>


<CheckBox
 x:Name="OptWidgets"

 Content="Ocultar Widgets"

 ToolTip="SEGURO - Oculta Widgets de la barra de tareas."/>


<CheckBox
 x:Name="OptGameDVR"

 Content="Desactivar Game DVR"

 ToolTip="RECOMENDADO - Desactiva captura y Game DVR en segundo plano."/>


<CheckBox
 x:Name="OptDeepClean"

 Content="Limpieza profunda de temporales y cachés"

 ToolTip="SEGURO - Windows, GPU, navegadores, Discord, miniaturas y papelera. No borra contraseñas ni cookies."/>


<Separator Margin="0,15"/>


<TextBlock
 Text="RENDIMIENTO"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<CheckBox
 x:Name="OptGameMode"

 Content="Activar Game Mode"

 ToolTip="RECOMENDADO - Activa el modo Juego de Windows."/>


<CheckBox
 x:Name="OptPowerThrottling"

 Content="Desactivar Power Throttling"

 ToolTip="AGRESIVO - Reduce políticas de ahorro de energía sobre procesos."/>


<CheckBox
 x:Name="OptBackgroundApps"

 Content="Reducir aplicaciones en segundo plano"

 ToolTip="AGRESIVO - Restringe determinadas tareas de aplicaciones en segundo plano."/>


<CheckBox
 x:Name="OptAnimations"

 Content="Desactivar animaciones de ventanas"

 ToolTip="SEGURO - Reduce animaciones visuales de Windows."/>


<CheckBox
 x:Name="OptTransparency"

 Content="Desactivar transparencias"

 ToolTip="SEGURO - Desactiva transparencia de la interfaz."/>


<CheckBox
 x:Name="OptTaskbarAnimations"

 Content="Desactivar animaciones de barra de tareas"

 ToolTip="SEGURO - Reduce animaciones de la barra de tareas."/>


<CheckBox
 x:Name="OptVisualPerformance"

 Content="Efectos visuales orientados a rendimiento"

 ToolTip="AGRESIVO - Prioriza rendimiento frente a efectos visuales."/>


</StackPanel>


<!-- DERECHA -->

<StackPanel
 x:Name="RightTweaks"

 Grid.Column="2">


<TextBlock
 Text="INTERFAZ Y GAMING"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<CheckBox
 x:Name="OptExtensions"

 Content="Mostrar extensiones de archivo"

 ToolTip="SEGURO - Muestra .exe, .txt, .jpg y demás extensiones."/>


<CheckBox
 x:Name="OptHiddenFiles"

 Content="Mostrar archivos ocultos"

 ToolTip="SEGURO - Muestra archivos marcados como ocultos."/>


<CheckBox
 x:Name="OptLongPaths"

 Content="Activar rutas largas"

 ToolTip="SEGURO - Habilita rutas Win32 largas para aplicaciones compatibles."/>


<CheckBox
 x:Name="OptMouseAcceleration"

 Content="Desactivar aceleración del ratón"

 ToolTip="RECOMENDADO - Elimina la aceleración clásica de puntero de Windows."/>


<CheckBox
 x:Name="OptStickyKeys"

 Content="Reducir activación accidental de Sticky Keys"

 ToolTip="RECOMENDADO - Evita activaciones accidentales durante juegos."/>


<CheckBox
 x:Name="OptTaskbarSearch"

 Content="Ocultar búsqueda de la barra"

 ToolTip="SEGURO - Oculta el cuadro de búsqueda de la barra de tareas."/>


<CheckBox
 x:Name="OptTaskView"

 Content="Ocultar Vista de tareas"

 ToolTip="SEGURO - Oculta el botón Vista de tareas."/>


<CheckBox
 x:Name="OptStartRecommendations"

 Content="Reducir recomendaciones del menú Inicio"

 ToolTip="SEGURO - Reduce recomendaciones y sugerencias en Inicio."/>


<Separator Margin="0,15"/>


<TextBlock
 Text="PLAN DE ENERGÍA"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<TextBlock
 Text="Perfil de máximo rendimiento de PUSI OPTI."

 Foreground="#8A95A5"

 Margin="5,0,5,10"/>


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

 Margin="5,8,5,0"/>


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

<TabItem Header="MANTENIMIENTO">


<ScrollViewer VerticalScrollBarVisibility="Auto">


<StackPanel Margin="25">


<TextBlock
 Text="Mantenimiento del sistema"

 FontSize="23"

 FontWeight="Bold"/>


<TextBlock
 Text="Reparación, red, limpieza y almacenamiento."

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


</StackPanel>


</ScrollViewer>


</TabItem>


<!-- ===================================================== -->
<!-- ACTUALIZACIONES -->
<!-- ===================================================== -->

<TabItem Header="ACTUALIZACIONES">


<ScrollViewer VerticalScrollBarVisibility="Auto">


<StackPanel Margin="25">


<TextBlock
 Text="Windows Update"

 FontSize="23"

 FontWeight="Bold"/>


<TextBlock
 Text="Control de actualizaciones y drivers."

 Foreground="#8A95A5"

 Margin="0,5,0,20"/>


<Border
 Background="#251E15"

 BorderBrush="#986F2D"

 BorderThickness="1"

 Padding="15"

 Margin="0,0,0,20">


<TextBlock
 Text="AVISO: desactivar Windows Update puede impedir parches de seguridad. Úsalo únicamente cuando sea necesario."

 Foreground="#E5BE78"

 TextWrapping="Wrap"/>


</Border>


<TextBlock
 Text="PAUSAR ACTUALIZACIONES"

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

 Background="#151A21"

 BorderBrush="#2D3540"

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

 Foreground="#B8C0CC"/>


<StackPanel
 Grid.Column="1"

 Orientation="Horizontal">


<TextBlock
 x:Name="BackupStatus"

 Text="BACKUP SESIÓN: NO"

 Foreground="#8A95A5"

 Margin="0,0,18,0"/>


<TextBlock
 x:Name="FooterRestart"

 Text="REINICIO: NO"

 Foreground="#63D89A"

 FontWeight="Bold"/>


</StackPanel>


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
# CARGAR XAML
# ============================================================

$Reader =
    New-Object System.Xml.XmlNodeReader $XAML


$Window =
    [Windows.Markup.XamlReader]::Load($Reader)


function C {

    param(
        [string]$Name
    )

    return $Window.FindName($Name)
}


$StatusBar =
    C "StatusBar"

$Progress =
    C "Progress"


# ============================================================
# HARDWARE
# ============================================================

$Hardware =
    Get-PusiHardware


(C "HeaderCPU").Text =
    "CPU: $($Hardware.CPU)"


(C "HeaderGPU").Text =
    "GPU: $($Hardware.GPU)"


(C "HeaderRAM").Text =
    "RAM: $($Hardware.RAM) @ $($Hardware.RAMSpeed) | $($Hardware.Tipo)"


(C "HeaderWindows").Text =
    "$($Hardware.Windows) | Build $($Hardware.Build)"


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

    "OptPowerThrottling",

    "OptBackgroundApps",

    "OptLongPaths"
)


# ============================================================
# CONTADOR
# ============================================================

function Update-PusiSelectionCounter {

    $Selected = 0
    $Restart  = 0


    foreach ($Name in $Options) {

        if ((C $Name).IsChecked) {

            $Selected++


            if ($RestartOptions -contains $Name) {

                $Restart++
            }
        }
    }


    (C "HeaderSelection").Text =
        "$Selected ajustes seleccionados"


    (C "SelectionInfo").Text =
        "$Selected ajustes seleccionados | $Restart pueden requerir reinicio"
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
# ESTADO DE REINICIO
# ============================================================

function Update-PusiRestartIndicator {

    $Pending =
        Test-PusiPendingRestart


    if ($Pending -or $script:NeedsRestart) {

        (C "HeaderRestart").Text =
            "REINICIO: PENDIENTE"

        (C "HeaderRestart").Foreground =
            "#E5A64B"


        (C "FooterRestart").Text =
            "REINICIO: PENDIENTE"

        (C "FooterRestart").Foreground =
            "#E5A64B"
    }
    else {

        (C "HeaderRestart").Text =
            "REINICIO: NO"

        (C "HeaderRestart").Foreground =
            "#63D89A"


        (C "FooterRestart").Text =
            "REINICIO: NO"

        (C "FooterRestart").Foreground =
            "#63D89A"
    }
}


# ============================================================
# ACTUALIZAR RESUMEN
# ============================================================

function Update-PusiSummary {

    $StatusBar.Text =
        "Actualizando estado del equipo..."


    $GameMode =
        (
            Get-PusiRegValue `
                "HKCU:\Software\Microsoft\GameBar" `
                "AutoGameModeEnabled"
        ) -eq 1


    $GameDVR =
        (
            Get-PusiRegValue `
                "HKCU:\System\GameConfigStore" `
                "GameDVR_Enabled"
        ) -ne 0


    $PowerThrottleOff =
        (
            Get-PusiRegValue `
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
                "PowerThrottlingOff"
        ) -eq 1


    if ($GameMode) {

        (C "SummaryGameMode").Text =
            "ACTIVO"

        (C "SummaryGameMode").Foreground =
            "#63D89A"
    }
    else {

        (C "SummaryGameMode").Text =
            "INACTIVO"

        (C "SummaryGameMode").Foreground =
            "#E5A64B"
    }


    if ($GameDVR) {

        (C "SummaryGameDVR").Text =
            "ACTIVO"

        (C "SummaryGameDVR").Foreground =
            "#E5A64B"
    }
    else {

        (C "SummaryGameDVR").Text =
            "DESACTIVADO"

        (C "SummaryGameDVR").Foreground =
            "#63D89A"
    }


    if ($PowerThrottleOff) {

        (C "SummaryPowerThrottling").Text =
            "DESACTIVADO"

        (C "SummaryPowerThrottling").Foreground =
            "#63D89A"
    }
    else {

        (C "SummaryPowerThrottling").Text =
            "ACTIVO"

        (C "SummaryPowerThrottling").Foreground =
            "#E5A64B"
    }


    if (Test-PusiTrim) {

        (C "SummaryTrim").Text =
            "ACTIVO"

        (C "SummaryTrim").Foreground =
            "#63D89A"
    }
    else {

        (C "SummaryTrim").Text =
            "REVISAR"

        (C "SummaryTrim").Foreground =
            "#E5A64B"
    }


    $Plan =
        Get-PusiActivePowerPlan


    (C "SummaryPowerPlan").Text =
        $Plan


    (C "PowerPlanText").Text =
        "Plan actual: $Plan"


    $Storage =
        Get-PusiStorageInfo


    if ($Storage) {

        (C "SummaryStorage").Text =
            "$($Storage.FreeGB) GB libres ($($Storage.PercentFree)%)"
    }
    else {

        (C "SummaryStorage").Text =
            "No disponible"
    }


    if (Test-PusiPendingRestart) {

        (C "SummaryRestart").Text =
            "SÍ"

        (C "SummaryRestart").Foreground =
            "#E5A64B"
    }
    else {

        (C "SummaryRestart").Text =
            "NO"

        (C "SummaryRestart").Foreground =
            "#63D89A"
    }


    (C "SummaryType").Text =
        $Hardware.Tipo


    Update-PusiRestartIndicator


    $StatusBar.Text =
        "Estado actualizado."
}


# ============================================================
# ANALISIS PUSI
# ============================================================

function Invoke-PusiAnalysis {

    (C "AnalysisList").Items.Clear()


    $Good = 0
    $Recommended = 0
    $Warnings = 0


    function Add-Good {

        param(
            [string]$Text
        )

        (C "AnalysisList").Items.Add(
            "✓ $Text"
        ) |
        Out-Null

        $script:_Good++
    }


    function Add-Recommendation {

        param(
            [string]$Text
        )

        (C "AnalysisList").Items.Add(
            "! $Text"
        ) |
        Out-Null

        $script:_Recommended++
    }


    function Add-Warning {

        param(
            [string]$Text
        )

        (C "AnalysisList").Items.Add(
            "⚠ $Text"
        ) |
        Out-Null

        $script:_Warnings++
    }


    $script:_Good = 0
    $script:_Recommended = 0
    $script:_Warnings = 0


    $GameMode =
        (
            Get-PusiRegValue `
                "HKCU:\Software\Microsoft\GameBar" `
                "AutoGameModeEnabled"
        ) -eq 1


    if ($GameMode) {

        Add-Good "Game Mode está activo."
    }
    else {

        Add-Recommendation "Game Mode está desactivado."
    }


    $DVR =
        (
            Get-PusiRegValue `
                "HKCU:\System\GameConfigStore" `
                "GameDVR_Enabled"
        ) -ne 0


    if (-not $DVR) {

        Add-Good "Game DVR está desactivado."
    }
    else {

        Add-Recommendation "Game DVR está activo."
    }


    $Plan =
        Get-PusiActivePowerPlan


    if ($Plan -eq "Plan energia Pusi") {

        Add-Good "Plan energia Pusi está activo."
    }
    else {

        Add-Recommendation "El plan actual es '$Plan'."
    }


    if (Test-PusiTrim) {

        Add-Good "TRIM está habilitado."
    }
    else {

        Add-Warning "No se pudo confirmar TRIM."
    }


    $Storage =
        Get-PusiStorageInfo


    if ($Storage) {

        if ($Storage.PercentFree -lt 10) {

            Add-Warning "La unidad C: tiene solo $($Storage.FreeGB) GB libres."
        }
        elseif ($Storage.PercentFree -lt 20) {

            Add-Recommendation "Conviene liberar espacio en C:. Queda $($Storage.PercentFree)%."
        }
        else {

            Add-Good "Espacio libre en C: correcto."
        }
    }


    if (Test-PusiPendingRestart) {

        Add-Recommendation "Windows tiene un reinicio pendiente."
    }
    else {

        Add-Good "No hay reinicio pendiente detectado."
    }


    $SpeedNumber = 0

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

        Add-Recommendation "RAM configurada a $($Hardware.RAMSpeed). Conviene comprobar XMP / EXPO en BIOS."
    }
    else {

        Add-Good "RAM detectada a $($Hardware.RAMSpeed)."
    }


    if ($Hardware.Tipo -eq "PORTÁTIL") {

        Add-Recommendation "Portátil detectado: evitar perfiles de energía agresivos cuando se use batería."
    }


    (C "AnalysisTotals").Text =
        "$script:_Good correctos | $script:_Recommended recomendados | $script:_Warnings avisos"


    $StatusBar.Text =
        "Análisis PUSI terminado."
}


# ============================================================
# INFORME
# ============================================================

function Get-PusiReport {

    $Snapshot =
        Get-PusiSnapshot


    $Lines = @(

        "PUSI OPTI - INFORME",

        "Versión: $script:PusiVersion",

        "",

        "SISTEMA",

        "Windows: $($Hardware.Windows)",

        "Build: $($Hardware.Build)",

        "CPU: $($Hardware.CPU)",

        "GPU: $($Hardware.GPU)",

        "RAM: $($Hardware.RAM) @ $($Hardware.RAMSpeed)",

        "Tipo: $($Hardware.Tipo)",

        "",

        "ESTADO",

        "Procesos: $($Snapshot.Procesos)",

        "RAM usada: $($Snapshot.RAMUsada) GB",

        "Plan de energía: $($Snapshot.PlanEnergia)",

        "Game Mode: $(if($Snapshot.GameMode){'ACTIVO'}else{'INACTIVO'})",

        "Game DVR: $(if($Snapshot.GameDVR){'ACTIVO'}else{'DESACTIVADO'})",

        "Power Throttling: $(if($Snapshot.PowerThrottlingOff){'DESACTIVADO'}else{'ACTIVO'})",

        "TRIM: $(if($Snapshot.Trim){'ACTIVO'}else{'NO CONFIRMADO'})",

        "Espacio libre C: $($Snapshot.FreeSpace) GB",

        "Reinicio pendiente: $(if($Snapshot.Reinicio){'SÍ'}else{'NO'})",

        "",

        "PUSI OPTI"
    )


    return (
        $Lines -join "`r`n"
    )
}


# ============================================================
# GUARDAR ANTES
# ============================================================

(C "SaveInitialState").Add_Click({

    $script:InitialSnapshot =
        Get-PusiSnapshot


    (C "BeforeProcesses").Text =
        "$($script:InitialSnapshot.Procesos)"


    (C "BeforeRAM").Text =
        "$($script:InitialSnapshot.RAMUsada) GB"


    (C "BeforePower").Text =
        "$($script:InitialSnapshot.PlanEnergia)"


    (C "BeforeDVR").Text =
        if ($script:InitialSnapshot.GameDVR) {
            "ACTIVO"
        }
        else {
            "DESACTIVADO"
        }


    (C "BeforeStorage").Text =
        "$($script:InitialSnapshot.FreeSpace) GB"


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
        "$($script:LastSnapshot.PlanEnergia)"


    (C "AfterDVR").Text =
        if ($script:LastSnapshot.GameDVR) {
            "ACTIVO"
        }
        else {
            "DESACTIVADO"
        }


    (C "AfterStorage").Text =
        "$($script:LastSnapshot.FreeSpace) GB"


    $StatusBar.Text =
        "Comparación actualizada."
})


# ============================================================
# ANALIZAR
# ============================================================

(C "AnalyzePC").Add_Click({

    Invoke-PusiAnalysis

    Update-PusiSummary
})


# ============================================================
# COPIAR INFORME
# ============================================================

(C "CopyReport").Add_Click({

    $Report =
        Get-PusiReport


    Set-Clipboard `
        -Value $Report


    $StatusBar.Text =
        "Informe copiado al portapapeles."


    [System.Windows.MessageBox]::Show(
        "Informe PUSI copiado al portapapeles.",
        "PUSI OPTI",
        "OK",
        "Information"
    )
})


# ============================================================
# REFRESH
# ============================================================

(C "RefreshAll").Add_Click({

    Update-PusiSummary

    Invoke-PusiAnalysis
})


# ============================================================
# PRESETS
# ============================================================

function Clear-PusiSelection {

    foreach ($Name in $Options) {

        (C $Name).IsChecked =
            $false
    }
}


(C "ClearSelection").Add_Click({

    Clear-PusiSelection

    $StatusBar.Text =
        "Selección limpiada."
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

        if (
            $Name -ne "OptRestorePoint" -and
            $Name -ne "OptDeepClean"
        ) {

            (C $Name).IsChecked =
                $true
        }
    }


    (C "OptRestorePoint").IsChecked =
        $true
})


# ============================================================
# BUSCADOR DE TWEAKS
# ============================================================

(C "SearchTweaks").Add_TextChanged({

    $Search =
        (C "SearchTweaks").Text.Trim().ToLower()


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
# PLAN ENERGIA PUSI
# ============================================================

(C "EnablePusiPower").Add_Click({

    if ($Hardware.Tipo -eq "PORTÁTIL") {

        $Answer =
            [System.Windows.MessageBox]::Show(
                "Se ha detectado un portátil.`n`nPlan energia Pusi está orientado a máximo rendimiento y puede aumentar consumo y temperatura.`n`n¿Continuar?",
                "PUSI OPTI",
                "YesNo",
                "Warning"
            )


        if ($Answer -ne "Yes") {

            return
        }
    }


    $StatusBar.Text =
        "Activando Plan energia Pusi..."


    if (Enable-PusiPowerPlan) {

        $StatusBar.Text =
            "Plan energia Pusi activado."
    }
    else {

        [System.Windows.MessageBox]::Show(
            "No se pudo importar o activar Plan energia Pusi.`n`nComprueba que Bitsum-Highest-Performance.pow está en la raíz de tu repositorio.",
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


    $StatusBar.Text =
        "Plan Equilibrado activado."


    Update-PusiSummary
})


# ============================================================
# PREPARAR BACKUP
# ============================================================

function Backup-PusiSelectedSettings {


    if ((C "OptTelemetry").IsChecked) {

        Backup-PusiRegValue `
            "Telemetry" `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
            "AllowTelemetry"
    }


    if ((C "OptActivityHistory").IsChecked) {

        Backup-PusiRegValue `
            "ActivityFeed" `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "EnableActivityFeed"


        Backup-PusiRegValue `
            "PublishActivities" `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "PublishUserActivities"
    }


    if ((C "OptConsumerFeatures").IsChecked) {

        Backup-PusiRegValue `
            "ConsumerFeatures" `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
            "DisableWindowsConsumerFeatures"
    }


    if ((C "OptDelivery").IsChecked) {

        Backup-PusiRegValue `
            "DeliveryMode" `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" `
            "DODownloadMode"
    }


    if ((C "OptSearchWeb").IsChecked) {

        Backup-PusiRegValue `
            "SearchWeb" `
            "HKCU:\Software\Policies\Microsoft\Windows\Explorer" `
            "DisableSearchBoxSuggestions"
    }


    if ((C "OptWidgets").IsChecked) {

        Backup-PusiRegValue `
            "Widgets" `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarDa"
    }


    if ((C "OptGameDVR").IsChecked) {

        Backup-PusiRegValue `
            "GameDVR" `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_Enabled"


        Backup-PusiRegValue `
            "AppCapture" `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
            "AppCaptureEnabled"
    }


    if ((C "OptGameMode").IsChecked) {

        Backup-PusiRegValue `
            "GameMode" `
            "HKCU:\Software\Microsoft\GameBar" `
            "AutoGameModeEnabled"
    }


    if ((C "OptPowerThrottling").IsChecked) {

        Backup-PusiRegValue `
            "PowerThrottling" `
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
            "PowerThrottlingOff"
    }


    if ((C "OptBackgroundApps").IsChecked) {

        Backup-PusiRegValue `
            "BackgroundApps" `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
            "GlobalUserDisabled"
    }


    if ((C "OptAnimations").IsChecked) {

        Backup-PusiRegValue `
            "Animations" `
            "HKCU:\Control Panel\Desktop\WindowMetrics" `
            "MinAnimate"
    }


    if ((C "OptTransparency").IsChecked) {

        Backup-PusiRegValue `
            "Transparency" `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            "EnableTransparency"
    }


    if ((C "OptTaskbarAnimations").IsChecked) {

        Backup-PusiRegValue `
            "TaskbarAnimations" `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarAnimations"
    }


    if ((C "OptVisualPerformance").IsChecked) {

        Backup-PusiRegValue `
            "VisualPerformance" `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
            "VisualFXSetting"
    }


    if ((C "OptExtensions").IsChecked) {

        Backup-PusiRegValue `
            "Extensions" `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "HideFileExt"
    }


    if ((C "OptHiddenFiles").IsChecked) {

        Backup-PusiRegValue `
            "HiddenFiles" `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Hidden"
    }


    if ((C "OptLongPaths").IsChecked) {

        Backup-PusiRegValue `
            "LongPaths" `
            "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
            "LongPathsEnabled"
    }


    if ((C "OptMouseAcceleration").IsChecked) {

        Backup-PusiRegValue `
            "MouseSpeed" `
            "HKCU:\Control Panel\Mouse" `
            "MouseSpeed"


        Backup-PusiRegValue `
            "MouseThreshold1" `
            "HKCU:\Control Panel\Mouse" `
            "MouseThreshold1"


        Backup-PusiRegValue `
            "MouseThreshold2" `
            "HKCU:\Control Panel\Mouse" `
            "MouseThreshold2"
    }


    if ((C "OptStickyKeys").IsChecked) {

        Backup-PusiRegValue `
            "StickyKeys" `
            "HKCU:\Control Panel\Accessibility\StickyKeys" `
            "Flags"
    }


    if ((C "OptTaskbarSearch").IsChecked) {

        Backup-PusiRegValue `
            "TaskbarSearch" `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
            "SearchboxTaskbarMode"
    }


    if ((C "OptTaskView").IsChecked) {

        Backup-PusiRegValue `
            "TaskView" `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "ShowTaskViewButton"
    }


    if ((C "OptStartRecommendations").IsChecked) {

        Backup-PusiRegValue `
            "StartRecommendations" `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Start_IrisRecommendations"
    }


    if ($script:SessionBackup.Count -gt 0) {

        (C "BackupStatus").Text =
            "BACKUP SESIÓN: OK"

        (C "BackupStatus").Foreground =
            "#63D89A"
    }
}


# ============================================================
# APLICAR
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
            "No hay ajustes seleccionados.",
            "PUSI OPTI",
            "OK",
            "Information"
        )

        return
    }


    $AggressiveSelected =
        @(
            "OptPowerThrottling",
            "OptBackgroundApps",
            "OptVisualPerformance"
        ) |
        Where-Object {
            (C $_).IsChecked
        }


    $RestartSelected =
        $Selected |
        Where-Object {
            $RestartOptions -contains $_
        }


    $Message =
        "Se aplicarán $($Selected.Count) ajustes.`n`n"


    if ($AggressiveSelected.Count -gt 0) {

        $Message +=
            "Ajustes agresivos: $($AggressiveSelected.Count)`n"
    }


    $Message +=
        "Pueden requerir reinicio: $($RestartSelected.Count)`n`n¿Continuar?"


    $Confirm =
        [System.Windows.MessageBox]::Show(
            $Message,
            "PUSI OPTI - Confirmar",
            "YesNo",
            "Question"
        )


    if ($Confirm -ne "Yes") {

        return
    }


    Reset-PusiResults

    Backup-PusiSelectedSettings


    $Progress.Value = 0

    $Current =
        0


    $Total =
        $Selected.Count


    function Pusi-Step {

        param(
            [string]$Text
        )

        $script:_CurrentStep++


        $Progress.Value =
            (
                $script:_CurrentStep /
                $Total
            ) * 100


        $StatusBar.Text =
            $Text


        $Window.Dispatcher.Invoke(
            [action]{},
            "Background"
        )
    }


    $script:_CurrentStep = 0
    $Freed = $null


    # --------------------------------------------------------
    # RESTORE POINT
    # --------------------------------------------------------

    if ((C "OptRestorePoint").IsChecked) {

        Pusi-Step "Creando punto de restauración..."


        if (New-PusiRestorePoint) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "OMITIDO"
        }
    }


    # --------------------------------------------------------
    # TELEMETRIA
    # --------------------------------------------------------

    if ((C "OptTelemetry").IsChecked) {

        Pusi-Step "Desactivando telemetría..."


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


    # --------------------------------------------------------
    # ACTIVITY HISTORY
    # --------------------------------------------------------

    if ((C "OptActivityHistory").IsChecked) {

        Pusi-Step "Desactivando historial de actividad..."


        $A =
            Set-PusiDWORD `
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
                "EnableActivityFeed" `
                0


        $B =
            Set-PusiDWORD `
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
                "PublishUserActivities" `
                0


        if ($A -and $B) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # CONSUMER FEATURES
    # --------------------------------------------------------

    if ((C "OptConsumerFeatures").IsChecked) {

        Pusi-Step "Desactivando contenido promocional..."


        if (
            Set-PusiDWORD `
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
                "DisableWindowsConsumerFeatures" `
                1
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # DELIVERY
    # --------------------------------------------------------

    if ((C "OptDelivery").IsChecked) {

        Pusi-Step "Configurando Delivery Optimization..."


        if (
            Set-PusiDWORD `
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" `
                "DODownloadMode" `
                0
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # SEARCH WEB
    # --------------------------------------------------------

    if ((C "OptSearchWeb").IsChecked) {

        Pusi-Step "Desactivando resultados web..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Policies\Microsoft\Windows\Explorer" `
                "DisableSearchBoxSuggestions" `
                1
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # WIDGETS
    # --------------------------------------------------------

    if ((C "OptWidgets").IsChecked) {

        Pusi-Step "Ocultando Widgets..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                "TaskbarDa" `
                0
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # GAME DVR
    # --------------------------------------------------------

    if ((C "OptGameDVR").IsChecked) {

        Pusi-Step "Desactivando Game DVR..."


        $A =
            Set-PusiDWORD `
                "HKCU:\System\GameConfigStore" `
                "GameDVR_Enabled" `
                0


        $B =
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
                "AppCaptureEnabled" `
                0


        if ($A -and $B) {

            Add-PusiResult "OK"

            $script:NeedsRestart =
                $true
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # CLEAN
    # --------------------------------------------------------

    if ((C "OptDeepClean").IsChecked) {

        Pusi-Step "Ejecutando limpieza profunda..."


        $Freed =
            Invoke-PusiDeepCleanup `
                -StatusControl $StatusBar


        Add-PusiResult "OK"
    }


    # --------------------------------------------------------
    # GAME MODE
    # --------------------------------------------------------

    if ((C "OptGameMode").IsChecked) {

        Pusi-Step "Activando Game Mode..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\GameBar" `
                "AutoGameModeEnabled" `
                1
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # POWER THROTTLING
    # --------------------------------------------------------

    if ((C "OptPowerThrottling").IsChecked) {

        Pusi-Step "Desactivando Power Throttling..."


        if (
            Set-PusiDWORD `
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
                "PowerThrottlingOff" `
                1
        ) {

            Add-PusiResult "OK"

            $script:NeedsRestart =
                $true
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # BACKGROUND APPS
    # --------------------------------------------------------

    if ((C "OptBackgroundApps").IsChecked) {

        Pusi-Step "Reduciendo aplicaciones en segundo plano..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
                "GlobalUserDisabled" `
                1
        ) {

            Add-PusiResult "OK"

            $script:NeedsRestart =
                $true
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # ANIMACIONES
    # --------------------------------------------------------

    if ((C "OptAnimations").IsChecked) {

        Pusi-Step "Desactivando animaciones..."


        if (
            Set-PusiString `
                "HKCU:\Control Panel\Desktop\WindowMetrics" `
                "MinAnimate" `
                "0"
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # TRANSPARENCIA
    # --------------------------------------------------------

    if ((C "OptTransparency").IsChecked) {

        Pusi-Step "Desactivando transparencias..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
                "EnableTransparency" `
                0
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # TASKBAR ANIMATIONS
    # --------------------------------------------------------

    if ((C "OptTaskbarAnimations").IsChecked) {

        Pusi-Step "Desactivando animaciones de barra..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                "TaskbarAnimations" `
                0
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # VISUAL PERFORMANCE
    # --------------------------------------------------------

    if ((C "OptVisualPerformance").IsChecked) {

        Pusi-Step "Configurando efectos visuales..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
                "VisualFXSetting" `
                2
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # EXTENSIONES
    # --------------------------------------------------------

    if ((C "OptExtensions").IsChecked) {

        Pusi-Step "Mostrando extensiones..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                "HideFileExt" `
                0
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # OCULTOS
    # --------------------------------------------------------

    if ((C "OptHiddenFiles").IsChecked) {

        Pusi-Step "Mostrando archivos ocultos..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                "Hidden" `
                1
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # LONG PATHS
    # --------------------------------------------------------

    if ((C "OptLongPaths").IsChecked) {

        Pusi-Step "Activando rutas largas..."


        if (
            Set-PusiDWORD `
                "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
                "LongPathsEnabled" `
                1
        ) {

            Add-PusiResult "OK"

            $script:NeedsRestart =
                $true
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # RATON
    # --------------------------------------------------------

    if ((C "OptMouseAcceleration").IsChecked) {

        Pusi-Step "Desactivando aceleración del ratón..."


        $A =
            Set-PusiString `
                "HKCU:\Control Panel\Mouse" `
                "MouseSpeed" `
                "0"


        $B =
            Set-PusiString `
                "HKCU:\Control Panel\Mouse" `
                "MouseThreshold1" `
                "0"


        $D =
            Set-PusiString `
                "HKCU:\Control Panel\Mouse" `
                "MouseThreshold2" `
                "0"


        if ($A -and $B -and $D) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # STICKY KEYS
    # --------------------------------------------------------

    if ((C "OptStickyKeys").IsChecked) {

        Pusi-Step "Configurando Sticky Keys..."


        if (
            Set-PusiString `
                "HKCU:\Control Panel\Accessibility\StickyKeys" `
                "Flags" `
                "506"
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # SEARCH TASKBAR
    # --------------------------------------------------------

    if ((C "OptTaskbarSearch").IsChecked) {

        Pusi-Step "Ocultando búsqueda de barra..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
                "SearchboxTaskbarMode" `
                0
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # TASK VIEW
    # --------------------------------------------------------

    if ((C "OptTaskView").IsChecked) {

        Pusi-Step "Ocultando Vista de tareas..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                "ShowTaskViewButton" `
                0
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    # --------------------------------------------------------
    # START
    # --------------------------------------------------------

    if ((C "OptStartRecommendations").IsChecked) {

        Pusi-Step "Reduciendo recomendaciones..."


        if (
            Set-PusiDWORD `
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                "Start_IrisRecommendations" `
                0
        ) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "ERROR"
        }
    }


    $Progress.Value =
        100


    Update-PusiSummary

    Invoke-PusiAnalysis


    $ResultMessage =
        "Optimización completada.`n`n" +
        "Correctos: $script:ResultadosOK`n" +
        "Errores: $script:ResultadosError`n" +
        "Omitidos: $script:ResultadosOmitidos"


    if ($Freed) {

        $ResultMessage +=
            "`nEspacio liberado aprox.: $Freed"
    }


    if ($script:NeedsRestart) {

        $ResultMessage +=
            "`n`nSe recomienda reiniciar Windows."
    }


    [System.Windows.MessageBox]::Show(
        $ResultMessage,
        "PUSI OPTI - Resultado",
        "OK",
        "Information"
    )


    $StatusBar.Text =
        "Optimización terminada."
})


# ============================================================
# REVERTIR EXACTAMENTE DESDE BACKUP DE SESION
# ============================================================

(C "RevertSelected").Add_Click({

    if ($script:SessionBackup.Count -eq 0) {

        [System.Windows.MessageBox]::Show(
            "No existe un backup de esta sesión.`n`nPUSI OPTI guarda los valores originales cuando aplica cambios. Si ya cerraste la aplicación, utiliza el punto de restauración.",
            "PUSI OPTI",
            "OK",
            "Information"
        )

        return
    }


    $Restored = 0


    $Map = @{

        OptTelemetry =
            @("Telemetry")

        OptActivityHistory =
            @(
                "ActivityFeed",
                "PublishActivities"
            )

        OptConsumerFeatures =
            @("ConsumerFeatures")

        OptDelivery =
            @("DeliveryMode")

        OptSearchWeb =
            @("SearchWeb")

        OptWidgets =
            @("Widgets")

        OptGameDVR =
            @(
                "GameDVR",
                "AppCapture"
            )

        OptGameMode =
            @("GameMode")

        OptPowerThrottling =
            @("PowerThrottling")

        OptBackgroundApps =
            @("BackgroundApps")

        OptAnimations =
            @("Animations")

        OptTransparency =
            @("Transparency")

        OptTaskbarAnimations =
            @("TaskbarAnimations")

        OptVisualPerformance =
            @("VisualPerformance")

        OptExtensions =
            @("Extensions")

        OptHiddenFiles =
            @("HiddenFiles")

        OptLongPaths =
            @("LongPaths")

        OptMouseAcceleration =
            @(
                "MouseSpeed",
                "MouseThreshold1",
                "MouseThreshold2"
            )

        OptStickyKeys =
            @("StickyKeys")

        OptTaskbarSearch =
            @("TaskbarSearch")

        OptTaskView =
            @("TaskView")

        OptStartRecommendations =
            @("StartRecommendations")
    }


    foreach ($Option in $Map.Keys) {

        if ((C $Option).IsChecked) {

            foreach ($BackupID in $Map[$Option]) {

                if (
                    Restore-PusiRegValue `
                        $BackupID
                ) {

                    $Restored++
                }
            }
        }
    }


    $script:NeedsRestart =
        $true


    Update-PusiSummary


    [System.Windows.MessageBox]::Show(
        "Reversión terminada.`n`nValores originales restaurados: $Restored`n`nSe recomienda reiniciar Windows.",
        "PUSI OPTI",
        "OK",
        "Information"
    )


    $StatusBar.Text =
        "Configuración original de sesión restaurada."
})


# ============================================================
# SFC
# ============================================================

(C "RunSFC").Add_Click({

    Start-Process `
        powershell.exe `
        -Verb RunAs `
        -ArgumentList `
        '-NoExit -Command "sfc /scannow"'
})


# ============================================================
# DISM
# ============================================================

(C "RunDISM").Add_Click({

    Start-Process `
        powershell.exe `
        -Verb RunAs `
        -ArgumentList `
        '-NoExit -Command "DISM /Online /Cleanup-Image /RestoreHealth"'
})


# ============================================================
# DNS
# ============================================================

(C "FlushDNS").Add_Click({

    ipconfig /flushdns |
        Out-Null


    $StatusBar.Text =
        "Caché DNS limpiada."
})


# ============================================================
# RESET RED
# ============================================================

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


        Update-PusiRestartIndicator


        $StatusBar.Text =
            "Red restablecida. Reinicia Windows."
    }
})


# ============================================================
# LIMPIEZA
# ============================================================

(C "DeepCleanup").Add_Click({

    $Freed =
        Invoke-PusiDeepCleanup `
            -StatusControl $StatusBar


    [System.Windows.MessageBox]::Show(
        "Limpieza profunda terminada.`n`nEspacio liberado aproximado: $Freed`n`nNo se han eliminado contraseñas, cookies, favoritos ni perfiles de navegador.",
        "PUSI OPTI",
        "OK",
        "Information"
    )


    Update-PusiSummary
})


# ============================================================
# PAPELERA
# ============================================================

(C "EmptyRecycle").Add_Click({

    Clear-RecycleBin `
        -Force `
        -ErrorAction SilentlyContinue


    $StatusBar.Text =
        "Papelera vaciada."
})


# ============================================================
# TRIM
# ============================================================

(C "CheckTrim").Add_Click({

    $Result =
        fsutil behavior query DisableDeleteNotify


    [System.Windows.MessageBox]::Show(
        "$Result`n`nNTFS DisableDeleteNotify = 0 significa que TRIM está habilitado.",
        "PUSI OPTI - TRIM",
        "OK",
        "Information"
    )
})


# ============================================================
# RETRIM
# ============================================================

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
# WINDOWS UPDATE - PAUSA
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
        $Now.ToString("yyyy-MM-ddTHH:mm:ssZ") |
        Out-Null


    Set-PusiString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesExpiryTime" `
        $End.ToString("yyyy-MM-ddTHH:mm:ssZ") |
        Out-Null
}


(C "Pause7").Add_Click({

    Set-PusiUpdatePause 7


    $StatusBar.Text =
        "Pausa de actualizaciones solicitada por 7 días."
})


(C "Pause35").Add_Click({

    Set-PusiUpdatePause 35


    $StatusBar.Text =
        "Pausa de actualizaciones solicitada por 35 días."
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


# ============================================================
# DRIVERS WU
# ============================================================

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


# ============================================================
# DESACTIVAR WINDOWS UPDATE
# ============================================================

(C "DisableWU").Add_Click({

    $Confirm =
        [System.Windows.MessageBox]::Show(
            "Esto puede impedir que Windows reciba actualizaciones y parches de seguridad.`n`n¿Continuar?",
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


# ============================================================
# REACTIVAR WINDOWS UPDATE
# ============================================================

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
# INICIALIZACION
# ============================================================

Update-PusiSelectionCounter

Update-PusiSummary

Invoke-PusiAnalysis


$Progress.Value =
    0


# ============================================================
# MOSTRAR
# ============================================================

$Window.ShowDialog() |
    Out-Null
