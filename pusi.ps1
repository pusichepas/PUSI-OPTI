# ============================================================
# PUSI OPTI
# Windows Optimization Utility
# VERSION 0.5
# ============================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase


# ============================================================
# ADMINISTRADOR
# ============================================================

function Test-Admin {

    $Identity =
        [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal =
        New-Object Security.Principal.WindowsPrincipal($Identity)

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}


if (-not (Test-Admin)) {

    [System.Windows.MessageBox]::Show(
        "PUSI OPTI necesita permisos de administrador.`n`nAbre PowerShell como administrador y vuelve a ejecutar el comando.",
        "PUSI OPTI",
        "OK",
        "Warning"
    )

    exit
}


# ============================================================
# VARIABLES DE SESION
# ============================================================

$script:ResultadosOK = 0
$script:ResultadosError = 0
$script:ResultadosOmitidos = 0

$script:DeletedBytes = 0


# ============================================================
# REGISTRO
# ============================================================

function Set-RegDWORD {

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


function Set-RegString {

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


function Remove-RegValue {

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


function Get-RegValue {

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


# ============================================================
# RESULTADOS
# ============================================================

function Add-PusiResult {

    param(
        [ValidateSet("OK","ERROR","OMITIDO")]
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
# PLAN ENERGIA PUSI
# ============================================================

function Enable-PusiPowerPlan {

    try {

        $PlanName =
            "Plan energia Pusi"

        $Existing =
            powercfg /list |
            Select-String -SimpleMatch $PlanName


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


        $PowURL =
            "https://raw.githubusercontent.com/pusichepas/PUSI-OPTI/main/Bitsum-Highest-Performance.pow"


        $TempPow =
            Join-Path `
                $env:TEMP `
                "PUSI-OPTI-POWER.pow"


        Invoke-WebRequest `
            -Uri $PowURL `
            -OutFile $TempPow `
            -UseBasicParsing `
            -ErrorAction Stop


        $PusiGuid =
            "7f34a6b5-1f2d-4c73-9b01-5b851dd62864"


        powercfg /delete $PusiGuid 2>$null |
            Out-Null


        powercfg /import $TempPow $PusiGuid |
            Out-Null


        powercfg /changename `
            $PusiGuid `
            "Plan energia Pusi" `
            "PUSI OPTI - Perfil de maximo rendimiento para sobremesa" |
            Out-Null


        powercfg /setactive $PusiGuid |
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
        $StatusBar
    )

    $script:DeletedBytes = 0


    function Clear-PusiPath {

        param(
            [string]$Path
        )

        if (-not (Test-Path $Path)) {
            return
        }

        try {

            $Files =
                Get-ChildItem `
                    -LiteralPath $Path `
                    -File `
                    -Recurse `
                    -Force `
                    -ErrorAction SilentlyContinue

            foreach ($File in $Files) {

                $script:DeletedBytes +=
                    $File.Length
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


    $StatusBar.Text =
        "Limpiando archivos temporales..."


    $Paths = @(

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
    )


    foreach ($Path in $Paths) {

        Clear-PusiPath $Path
    }


    # ========================================================
    # CHROMIUM
    # ========================================================

    $ChromiumRoots = @(

        "$env:LOCALAPPDATA\Google\Chrome\User Data",

        "$env:LOCALAPPDATA\Microsoft\Edge\User Data",

        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    )


    foreach ($Root in $ChromiumRoots) {

        if (Test-Path $Root) {

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
    }


    # ========================================================
    # OPERA
    # ========================================================

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


    # ========================================================
    # FIREFOX
    # ========================================================

    $Firefox =
        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"


    if (Test-Path $Firefox) {

        Get-ChildItem `
            $Firefox `
            -Directory `
            -ErrorAction SilentlyContinue |
        ForEach-Object {

            Clear-PusiPath "$($_.FullName)\cache2"

            Clear-PusiPath "$($_.FullName)\startupCache"

            Clear-PusiPath "$($_.FullName)\shader-cache"
        }
    }


    # ========================================================
    # PAPELERA
    # ========================================================

    try {

        Clear-RecycleBin `
            -Force `
            -ErrorAction SilentlyContinue
    }
    catch {}


    $FreedMB =
        [math]::Round(
            $script:DeletedBytes / 1MB,
            0
        )


    if ($FreedMB -ge 1024) {

        $Freed =
            "$([math]::Round($FreedMB / 1024,2)) GB"
    }
    else {

        $Freed =
            "$FreedMB MB"
    }


    return $Freed
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
            $_.Name -notmatch "Microsoft"
        } |
        Select-Object -First 1


    $Computer =
        Get-CimInstance Win32_ComputerSystem


    $OS =
        Get-CimInstance Win32_OperatingSystem


    $RAM =
        [math]::Round(
            $Computer.TotalPhysicalMemory / 1GB,
            0
        )


    $Battery =
        Get-CimInstance Win32_Battery `
            -ErrorAction SilentlyContinue


    if ($Battery) {

        $Type =
            "PORTÁTIL"
    }
    else {

        $Type =
            "SOBREMESA"
    }


    return [PSCustomObject]@{

        CPU =
            $CPU.Name

        GPU =
            $GPU.Name

        RAM =
            "$RAM GB"

        Windows =
            $OS.Caption

        Build =
            $OS.BuildNumber

        Tipo =
            $Type
    }
}


$Hardware =
    Get-PusiHardware


# ============================================================
# XAML
# ============================================================

[xml]$XAML = @"

<Window
 xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
 xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"

 Title="PUSI OPTI"
 Width="1260"
 Height="850"

 MinWidth="1100"
 MinHeight="720"

 WindowStartupLocation="CenterScreen"

 Background="#101217">


<Window.Resources>


<Style TargetType="Button">

    <Setter Property="Background" Value="#20252B"/>

    <Setter Property="Foreground" Value="White"/>

    <Setter Property="BorderBrush" Value="#3D444E"/>

    <Setter Property="BorderThickness" Value="1"/>

    <Setter Property="Padding" Value="12,8"/>

    <Setter Property="Margin" Value="4"/>

    <Setter Property="FontSize" Value="13"/>

</Style>


<Style TargetType="CheckBox">

    <Setter Property="Foreground" Value="White"/>

    <Setter Property="FontSize" Value="13"/>

    <Setter Property="Margin" Value="5"/>

</Style>


<Style TargetType="TextBlock">

    <Setter Property="Foreground" Value="White"/>

</Style>


<Style TargetType="TabItem">

    <Setter Property="Foreground" Value="White"/>

    <Setter Property="Background" Value="#181C22"/>

    <Setter Property="FontSize" Value="15"/>

    <Setter Property="FontWeight" Value="SemiBold"/>

    <Setter Property="Padding" Value="25,10"/>

</Style>


</Window.Resources>


<Grid>


<Grid.RowDefinitions>

    <RowDefinition Height="122"/>

    <RowDefinition Height="*"/>

    <RowDefinition Height="65"/>

</Grid.RowDefinitions>


<!-- ===================================================== -->
<!-- CABECERA -->
<!-- ===================================================== -->

<Border
 Grid.Row="0"

 Background="#171A20"

 BorderBrush="#303640"

 BorderThickness="0,0,0,1">


<Grid Margin="24,12">


<Grid.ColumnDefinitions>

    <ColumnDefinition Width="260"/>

    <ColumnDefinition Width="*"/>

    <ColumnDefinition Width="250"/>

</Grid.ColumnDefinitions>


<StackPanel
 VerticalAlignment="Center">


<TextBlock
 Text="PUSI OPTI"

 FontSize="32"

 FontWeight="Bold"/>


<TextBlock
 Text="Windows Optimization Utility"

 Foreground="#8E96A3"

 FontSize="13"/>


<TextBlock
 Text="v0.5"

 Foreground="#606772"

 FontSize="12"

 Margin="0,5,0,0"/>


</StackPanel>


<!-- HARDWARE -->

<Grid
 Grid.Column="1"
 VerticalAlignment="Center">


<Grid.RowDefinitions>

<RowDefinition/>

<RowDefinition/>

<RowDefinition/>

</Grid.RowDefinitions>


<TextBlock
 x:Name="InfoCPU"

 Grid.Row="0"

 Foreground="#D7DBE2"

 FontSize="12"/>


<TextBlock
 x:Name="InfoGPU"

 Grid.Row="1"

 Foreground="#D7DBE2"

 FontSize="12"/>


<TextBlock
 x:Name="InfoSistema"

 Grid.Row="2"

 Foreground="#8E96A3"

 FontSize="12"/>


</Grid>


<!-- ESTADO -->

<StackPanel
 Grid.Column="2"

 HorizontalAlignment="Right"

 VerticalAlignment="Center">


<TextBlock
 x:Name="SelectedCount"

 Text="0 ajustes seleccionados"

 FontSize="14"

 FontWeight="SemiBold"

 HorizontalAlignment="Right"/>


<TextBlock
 x:Name="RestartCount"

 Text="0 requieren reinicio"

 Foreground="#D0A24C"

 Margin="0,5,0,0"

 HorizontalAlignment="Right"/>


<Button
 x:Name="RefreshState"

 Content="ACTUALIZAR ESTADO"

 Width="180"

 Margin="0,8,0,0"/>


</StackPanel>


</Grid>


</Border>


<!-- ===================================================== -->
<!-- TABS -->
<!-- ===================================================== -->

<TabControl
 Grid.Row="1"

 Background="#101217"

 BorderBrush="#303640">


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


<TextBlock
 Text="Optimización de Windows"

 FontSize="23"

 FontWeight="Bold"/>


<WrapPanel
 Grid.Row="1"

 Margin="0,12,0,8">


<Button
 x:Name="PresetSeguro"

 Content="SEGURO"

 Width="110"/>


<Button
 x:Name="PresetRecomendado"

 Content="RECOMENDADO"

 Width="145"/>


<Button
 x:Name="PresetGaming"

 Content="PUSI GAMING"

 Width="145"/>


<Button
 x:Name="PresetAgresivo"

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


<!-- ================================================= -->
<!-- IZQUIERDA -->
<!-- ================================================= -->

<StackPanel Grid.Column="0">


<TextBlock
 Text="SISTEMA Y PRIVACIDAD"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<CheckBox
 x:Name="OptRestorePoint"

 Content="Crear punto de restauración    [SEGURO]"

 ToolTip="Crea un punto de restauración antes de realizar cambios importantes."/>


<CheckBox
 x:Name="OptTelemetry"

 Content="Desactivar telemetría    [RECOMENDADO]"

 ToolTip="Reduce la recopilación de diagnósticos y telemetría permitida por Windows."/>


<CheckBox
 x:Name="OptActivityHistory"

 Content="Desactivar historial de actividad    [RECOMENDADO]"

 ToolTip="Impide que Windows publique y almacene determinadas actividades del usuario."/>


<CheckBox
 x:Name="OptConsumerFeatures"

 Content="Desactivar contenido promocional    [SEGURO]"

 ToolTip="Reduce sugerencias, promociones y contenido patrocinado de Windows."/>


<CheckBox
 x:Name="OptDeliveryOptimization"

 Content="Desactivar P2P de Windows Update    [RECOMENDADO]"

 ToolTip="Evita compartir actualizaciones de Windows con otros equipos mediante Delivery Optimization."/>


<CheckBox
 x:Name="OptSearchWeb"

 Content="Desactivar búsquedas web en Inicio    [SEGURO]"

 ToolTip="Hace que la búsqueda del menú Inicio se centre en archivos y aplicaciones locales."/>


<CheckBox
 x:Name="OptWidgets"

 Content="Desactivar Widgets    [SEGURO]"

 ToolTip="Oculta Widgets de la barra de tareas."/>


<CheckBox
 x:Name="OptGameDVR"

 Content="Desactivar Game DVR    [RECOMENDADO]"

 ToolTip="Desactiva las funciones de grabación en segundo plano de Game DVR."/>


<CheckBox
 x:Name="OptDeepCleanup"

 Content="Limpieza profunda de temporales    [SEGURO]"

 ToolTip="Limpia temporales y cachés regenerables de Windows, navegadores, GPU y Discord. No borra contraseñas, cookies ni favoritos."/>


<Separator Margin="0,15"/>


<TextBlock
 Text="RENDIMIENTO"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<CheckBox
 x:Name="OptGameMode"

 Content="Activar Game Mode    [RECOMENDADO]"

 ToolTip="Activa el modo Juego de Windows."/>


<CheckBox
 x:Name="OptPowerThrottling"

 Content="Desactivar Power Throttling    [AGRESIVO]"

 ToolTip="Impide que Windows aplique determinadas políticas de ahorro de energía a procesos."/>


<CheckBox
 x:Name="OptBackgroundApps"

 Content="Reducir aplicaciones en segundo plano    [AGRESIVO]"

 ToolTip="Reduce la capacidad de determinadas aplicaciones para trabajar en segundo plano."/>


<CheckBox
 x:Name="OptAnimations"

 Content="Desactivar animaciones    [SEGURO]"

 ToolTip="Reduce animaciones visuales de las ventanas."/>


<CheckBox
 x:Name="OptTransparency"

 Content="Desactivar transparencias    [SEGURO]"

 ToolTip="Desactiva efectos de transparencia de la interfaz."/>


<CheckBox
 x:Name="OptTaskbarAnimations"

 Content="Desactivar animaciones de barra    [SEGURO]"

 ToolTip="Desactiva determinadas animaciones de la barra de tareas."/>


<CheckBox
 x:Name="OptVisualEffects"

 Content="Efectos visuales para rendimiento    [AGRESIVO]"

 ToolTip="Configura Windows para priorizar rendimiento visual sobre efectos."/>


</StackPanel>


<!-- ================================================= -->
<!-- DERECHA -->
<!-- ================================================= -->

<StackPanel Grid.Column="2">


<TextBlock
 Text="EXPLORADOR E INTERFAZ"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<CheckBox
 x:Name="OptFileExtensions"

 Content="Mostrar extensiones de archivo    [SEGURO]"

 ToolTip="Muestra .exe, .txt, .jpg y otras extensiones en el Explorador."/>


<CheckBox
 x:Name="OptHiddenFiles"

 Content="Mostrar archivos ocultos    [SEGURO]"

 ToolTip="Permite visualizar archivos marcados como ocultos."/>


<CheckBox
 x:Name="OptLongPaths"

 Content="Activar rutas largas    [SEGURO]"

 ToolTip="Permite a aplicaciones compatibles utilizar rutas superiores al límite clásico de 260 caracteres."/>


<CheckBox
 x:Name="OptMouseAcceleration"

 Content="Desactivar aceleración del ratón    [RECOMENDADO]"

 ToolTip="Desactiva la aceleración clásica de Windows para una respuesta de ratón más consistente."/>


<CheckBox
 x:Name="OptStickyKeys"

 Content="Desactivar Sticky Keys    [RECOMENDADO]"

 ToolTip="Evita la activación accidental de teclas especiales durante juegos."/>


<CheckBox
 x:Name="OptTaskbarSearch"

 Content="Ocultar búsqueda de la barra    [SEGURO]"

 ToolTip="Oculta el cuadro o icono de búsqueda de la barra de tareas."/>


<CheckBox
 x:Name="OptTaskView"

 Content="Ocultar Vista de tareas    [SEGURO]"

 ToolTip="Oculta el botón Vista de tareas."/>


<CheckBox
 x:Name="OptStartRecommendations"

 Content="Reducir recomendaciones de Inicio    [SEGURO]"

 ToolTip="Reduce recomendaciones y sugerencias en Inicio."/>


<Separator Margin="0,15"/>


<TextBlock
 Text="PLAN DE ENERGÍA"

 Foreground="#4FD6FF"

 FontSize="17"

 FontWeight="Bold"

 Margin="5,5,5,10"/>


<TextBlock
 Text="Perfil PUSI basado en Bitsum Highest Performance."

 Foreground="#8E96A3"

 TextWrapping="Wrap"

 Margin="5"/>


<Button
 x:Name="EnablePusiPower"

 Content="ACTIVAR PLAN ENERGIA PUSI"

 HorizontalAlignment="Stretch"/>


<Button
 x:Name="EnableBalanced"

 Content="VOLVER A EQUILIBRADO"

 HorizontalAlignment="Stretch"/>


<TextBlock
 x:Name="PowerPlanState"

 Text="Plan actual: detectando..."

 Foreground="#8E96A3"

 Margin="6,8,0,0"/>


</StackPanel>


</Grid>


</ScrollViewer>


<!-- BOTONES -->

<Grid Grid.Row="3">


<Grid.ColumnDefinitions>

<ColumnDefinition Width="*"/>

<ColumnDefinition Width="Auto"/>

</Grid.ColumnDefinitions>


<TextBlock
 x:Name="ApplyHint"

 Text="Selecciona uno o varios ajustes."

 Foreground="#8E96A3"

 VerticalAlignment="Center"/>


<StackPanel
 Grid.Column="1"

 Orientation="Horizontal">


<Button
 x:Name="RevertSelected"

 Content="REVERTIR SELECCIONADOS"

 Width="210"/>


<Button
 x:Name="ApplySelected"

 Content="APLICAR SELECCIONADOS"

 Width="210"/>


</StackPanel>


</Grid>


</Grid>


</TabItem>


<!-- ===================================================== -->
<!-- CONFIGURACION -->
<!-- ===================================================== -->

<TabItem Header="CONFIGURACIÓN">


<ScrollViewer VerticalScrollBarVisibility="Auto">


<StackPanel Margin="25">


<TextBlock
 Text="Mantenimiento y diagnóstico"

 FontSize="23"

 FontWeight="Bold"/>


<TextBlock
 Text="Herramientas integradas de Windows y PUSI OPTI."

 Foreground="#8E96A3"

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


<Button
 x:Name="FlushDNS"

 Content="VACIAR DNS"

 Width="160"/>


<Button
 x:Name="ResetNetwork"

 Content="REINICIAR RED"

 Width="170"/>


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

 Width="200"/>


<Button
 x:Name="EmptyRecycle"

 Content="VACIAR PAPELERA"

 Width="175"/>


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

 Content="OPTIMIZAR SSD / NVME"

 Width="210"/>


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
 Text="Control de actualizaciones del sistema."

 Foreground="#8E96A3"

 Margin="0,5,0,20"/>


<Border
 Background="#251E15"

 BorderBrush="#936E31"

 BorderThickness="1"

 Padding="15"

 Margin="0,0,0,20">


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
<!-- BARRA INFERIOR -->
<!-- ===================================================== -->

<Border
 Grid.Row="2"

 Background="#171A20"

 BorderBrush="#303640"

 BorderThickness="0,1,0,0">


<Grid Margin="16,7">


<Grid.RowDefinitions>

<RowDefinition Height="Auto"/>

<RowDefinition Height="Auto"/>

</Grid.RowDefinitions>


<TextBlock
 x:Name="StatusBar"

 Text="PUSI OPTI lista."

 Foreground="#B7BDC7"/>


<ProgressBar
 x:Name="Progress"

 Grid.Row="1"

 Height="7"

 Minimum="0"

 Maximum="100"

 Value="0"

 Margin="0,7,0,0"/>


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
    [Windows.Markup.XamlReader]::Load($Reader)


$StatusBar =
    $Window.FindName("StatusBar")


$Progress =
    $Window.FindName("Progress")


$SelectedCount =
    $Window.FindName("SelectedCount")


$RestartCount =
    $Window.FindName("RestartCount")


# ============================================================
# HARDWARE EN HEADER
# ============================================================

$Window.FindName("InfoCPU").Text =
    "CPU: $($Hardware.CPU)"


$Window.FindName("InfoGPU").Text =
    "GPU: $($Hardware.GPU)"


$Window.FindName("InfoSistema").Text =
    "$($Hardware.Windows) | $($Hardware.RAM) RAM | $($Hardware.Tipo)"


# ============================================================
# CHECKBOXES
# ============================================================

$Options = @(

    "OptRestorePoint",

    "OptTelemetry",

    "OptActivityHistory",

    "OptConsumerFeatures",

    "OptDeliveryOptimization",

    "OptSearchWeb",

    "OptWidgets",

    "OptGameDVR",

    "OptDeepCleanup",

    "OptGameMode",

    "OptPowerThrottling",

    "OptBackgroundApps",

    "OptAnimations",

    "OptTransparency",

    "OptTaskbarAnimations",

    "OptVisualEffects",

    "OptFileExtensions",

    "OptHiddenFiles",

    "OptLongPaths",

    "OptMouseAcceleration",

    "OptStickyKeys",

    "OptTaskbarSearch",

    "OptTaskView",

    "OptStartRecommendations"
)


$RestartOptions = @(

    "OptPowerThrottling",

    "OptGameDVR",

    "OptLongPaths",

    "OptBackgroundApps"
)


# ============================================================
# CONTADORES
# ============================================================

function Update-SelectionCounter {

    $Selected = 0
    $Restart = 0


    foreach ($Name in $Options) {

        $Control =
            $Window.FindName($Name)


        if ($Control.IsChecked) {

            $Selected++


            if ($RestartOptions -contains $Name) {

                $Restart++
            }
        }
    }


    $SelectedCount.Text =
        "$Selected ajustes seleccionados"


    $RestartCount.Text =
        "$Restart requieren reinicio"
}


foreach ($Name in $Options) {

    $Control =
        $Window.FindName($Name)


    $Control.Add_Checked({

        Update-SelectionCounter
    })


    $Control.Add_Unchecked({

        Update-SelectionCounter
    })
}


# ============================================================
# ESTADO REAL
# ============================================================

function Update-PusiState {

    $StatusBar.Text =
        "Leyendo configuración actual..."


    # GAME MODE

    $GameMode =
        Get-RegValue `
            "HKCU:\Software\Microsoft\GameBar" `
            "AutoGameModeEnabled"


    $Window.FindName("OptGameMode").IsChecked =
        ($GameMode -eq 1)


    # GAME DVR

    $DVR =
        Get-RegValue `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_Enabled"


    $Window.FindName("OptGameDVR").IsChecked =
        ($DVR -eq 0)


    # POWER THROTTLING

    $PT =
        Get-RegValue `
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
            "PowerThrottlingOff"


    $Window.FindName("OptPowerThrottling").IsChecked =
        ($PT -eq 1)


    # FILE EXTENSIONS

    $Extensions =
        Get-RegValue `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "HideFileExt"


    $Window.FindName("OptFileExtensions").IsChecked =
        ($Extensions -eq 0)


    # HIDDEN FILES

    $Hidden =
        Get-RegValue `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Hidden"


    $Window.FindName("OptHiddenFiles").IsChecked =
        ($Hidden -eq 1)


    # SEARCH

    $Search =
        Get-RegValue `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
            "SearchboxTaskbarMode"


    $Window.FindName("OptTaskbarSearch").IsChecked =
        ($Search -eq 0)


    # TASK VIEW

    $TaskView =
        Get-RegValue `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "ShowTaskViewButton"


    $Window.FindName("OptTaskView").IsChecked =
        ($TaskView -eq 0)


    # TRANSPARENCY

    $Transparency =
        Get-RegValue `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            "EnableTransparency"


    $Window.FindName("OptTransparency").IsChecked =
        ($Transparency -eq 0)


    # POWER PLAN

    $Power =
        powercfg /getactivescheme


    $Window.FindName("PowerPlanState").Text =
        "Plan actual: $Power"


    Update-SelectionCounter


    $StatusBar.Text =
        "Estado actualizado."
}


$Window.FindName("RefreshState").Add_Click({

    Update-PusiState
})


# ============================================================
# PRESETS
# ============================================================

function Clear-All {

    foreach ($Name in $Options) {

        $Window.FindName($Name).IsChecked =
            $false
    }
}


$Window.FindName("ClearSelection").Add_Click({

    Clear-All

    $StatusBar.Text =
        "Selección limpiada."
})


$Window.FindName("PresetSeguro").Add_Click({

    Clear-All


    @(

        "OptRestorePoint",

        "OptConsumerFeatures",

        "OptSearchWeb",

        "OptWidgets",

        "OptFileExtensions",

        "OptAnimations",

        "OptTransparency"

    ) |
    ForEach-Object {

        $Window.FindName($_).IsChecked =
            $true
    }
})


$Window.FindName("PresetRecomendado").Add_Click({

    Clear-All


    @(

        "OptRestorePoint",

        "OptTelemetry",

        "OptActivityHistory",

        "OptConsumerFeatures",

        "OptDeliveryOptimization",

        "OptSearchWeb",

        "OptWidgets",

        "OptGameDVR",

        "OptGameMode",

        "OptFileExtensions",

        "OptMouseAcceleration",

        "OptStickyKeys",

        "OptTaskbarSearch",

        "OptStartRecommendations"

    ) |
    ForEach-Object {

        $Window.FindName($_).IsChecked =
            $true
    }
})


$Window.FindName("PresetGaming").Add_Click({

    Clear-All


    @(

        "OptRestorePoint",

        "OptTelemetry",

        "OptActivityHistory",

        "OptConsumerFeatures",

        "OptDeliveryOptimization",

        "OptSearchWeb",

        "OptWidgets",

        "OptGameDVR",

        "OptGameMode",

        "OptPowerThrottling",

        "OptBackgroundApps",

        "OptAnimations",

        "OptTransparency",

        "OptTaskbarAnimations",

        "OptVisualEffects",

        "OptMouseAcceleration",

        "OptStickyKeys",

        "OptTaskbarSearch",

        "OptTaskView",

        "OptStartRecommendations"

    ) |
    ForEach-Object {

        $Window.FindName($_).IsChecked =
            $true
    }
})


$Window.FindName("PresetAgresivo").Add_Click({

    foreach ($Name in $Options) {

        if ($Name -ne "OptDeepCleanup") {

            $Window.FindName($Name).IsChecked =
                $true
        }
    }
})


# ============================================================
# PLAN PUSI
# ============================================================

$Window.FindName("EnablePusiPower").Add_Click({

    if ($Hardware.Tipo -eq "PORTÁTIL") {

        $Answer =
            [System.Windows.MessageBox]::Show(
                "Se ha detectado un portátil.`n`nPlan energia Pusi está orientado a sobremesa y puede aumentar consumo y temperatura.`n`n¿Continuar?",
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

        Add-PusiResult "OK"
    }
    else {

        $StatusBar.Text =
            "No se pudo activar el plan."

        Add-PusiResult "ERROR"
    }


    Update-PusiState
})


$Window.FindName("EnableBalanced").Add_Click({

    powercfg /setactive SCHEME_BALANCED |
        Out-Null


    $StatusBar.Text =
        "Plan Equilibrado activado."


    Update-PusiState
})


# ============================================================
# APLICAR
# ============================================================

$Window.FindName("ApplySelected").Add_Click({

    $SelectedNames =
        $Options |
        Where-Object {

            $Window.FindName($_).IsChecked
        }


    if ($SelectedNames.Count -eq 0) {

        [System.Windows.MessageBox]::Show(
            "No hay ningún ajuste seleccionado.",
            "PUSI OPTI",
            "OK",
            "Information"
        )

        return
    }


    $RestartSelected =
        $SelectedNames |
        Where-Object {

            $RestartOptions -contains $_
        }


    $Confirmation =
        [System.Windows.MessageBox]::Show(
            "Se aplicarán $($SelectedNames.Count) ajustes.`n`n$($RestartSelected.Count) pueden requerir reiniciar Windows.`n`n¿Continuar?",
            "PUSI OPTI - Confirmar optimización",
            "YesNo",
            "Question"
        )


    if ($Confirmation -ne "Yes") {

        return
    }


    $script:ResultadosOK = 0
    $script:ResultadosError = 0
    $script:ResultadosOmitidos = 0


    $Progress.Value = 0


    $Total =
        $SelectedNames.Count


    $Current = 0


    function Step {

        param(
            [string]$Message
        )

        $script:Current++

        $Progress.Value =
            ($script:Current / $Total) * 100

        $StatusBar.Text =
            $Message

        $Window.Dispatcher.Invoke(
            [action]{},
            "Background"
        )
    }


    $script:Current = 0


    if ($Window.FindName("OptRestorePoint").IsChecked) {

        Step "Creando punto de restauración..."

        if (New-PusiRestorePoint) {

            Add-PusiResult "OK"
        }
        else {

            Add-PusiResult "OMITIDO"
        }
    }


    if ($Window.FindName("OptTelemetry").IsChecked) {

        Step "Desactivando telemetría..."

        if (
            Set-RegDWORD `
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


    if ($Window.FindName("OptActivityHistory").IsChecked) {

        Step "Desactivando historial de actividad..."

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "EnableActivityFeed" `
            0 |
            Out-Null


        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "PublishUserActivities" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptConsumerFeatures").IsChecked) {

        Step "Desactivando contenido promocional..."


        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
            "DisableWindowsConsumerFeatures" `
            1 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptDeliveryOptimization").IsChecked) {

        Step "Configurando Delivery Optimization..."


        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" `
            "DODownloadMode" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptSearchWeb").IsChecked) {

        Step "Desactivando resultados web..."


        Set-RegDWORD `
            "HKCU:\Software\Policies\Microsoft\Windows\Explorer" `
            "DisableSearchBoxSuggestions" `
            1 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptWidgets").IsChecked) {

        Step "Desactivando Widgets..."


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarDa" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptGameDVR").IsChecked) {

        Step "Desactivando Game DVR..."


        Set-RegDWORD `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_Enabled" `
            0 |
            Out-Null


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
            "AppCaptureEnabled" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptDeepCleanup").IsChecked) {

        Step "Ejecutando limpieza profunda..."


        $Freed =
            Invoke-PusiDeepCleanup `
                -StatusBar $StatusBar


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptGameMode").IsChecked) {

        Step "Activando Game Mode..."


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\GameBar" `
            "AutoGameModeEnabled" `
            1 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptPowerThrottling").IsChecked) {

        Step "Desactivando Power Throttling..."


        Set-RegDWORD `
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
            "PowerThrottlingOff" `
            1 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptBackgroundApps").IsChecked) {

        Step "Reduciendo aplicaciones en segundo plano..."


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
            "GlobalUserDisabled" `
            1 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptAnimations").IsChecked) {

        Step "Desactivando animaciones..."


        Set-RegString `
            "HKCU:\Control Panel\Desktop\WindowMetrics" `
            "MinAnimate" `
            "0" |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptTransparency").IsChecked) {

        Step "Desactivando transparencias..."


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            "EnableTransparency" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptTaskbarAnimations").IsChecked) {

        Step "Desactivando animaciones de barra..."


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarAnimations" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptVisualEffects").IsChecked) {

        Step "Configurando efectos visuales..."


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
            "VisualFXSetting" `
            2 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptFileExtensions").IsChecked) {

        Step "Mostrando extensiones..."


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "HideFileExt" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptHiddenFiles").IsChecked) {

        Step "Mostrando archivos ocultos..."


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Hidden" `
            1 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptLongPaths").IsChecked) {

        Step "Activando rutas largas..."


        Set-RegDWORD `
            "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
            "LongPathsEnabled" `
            1 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptMouseAcceleration").IsChecked) {

        Step "Desactivando aceleración del ratón..."


        Set-RegString `
            "HKCU:\Control Panel\Mouse" `
            "MouseSpeed" `
            "0" |
            Out-Null


        Set-RegString `
            "HKCU:\Control Panel\Mouse" `
            "MouseThreshold1" `
            "0" |
            Out-Null


        Set-RegString `
            "HKCU:\Control Panel\Mouse" `
            "MouseThreshold2" `
            "0" |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptStickyKeys").IsChecked) {

        Step "Configurando Sticky Keys..."


        Set-RegString `
            "HKCU:\Control Panel\Accessibility\StickyKeys" `
            "Flags" `
            "506" |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptTaskbarSearch").IsChecked) {

        Step "Ocultando búsqueda..."


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
            "SearchboxTaskbarMode" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptTaskView").IsChecked) {

        Step "Ocultando Vista de tareas..."


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "ShowTaskViewButton" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    if ($Window.FindName("OptStartRecommendations").IsChecked) {

        Step "Reduciendo recomendaciones..."


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Start_IrisRecommendations" `
            0 |
            Out-Null


        Add-PusiResult "OK"
    }


    $Progress.Value = 100


    $StatusBar.Text =
        "Optimización terminada."


    $Extra = ""


    if ($Freed) {

        $Extra =
            "`nEspacio liberado: $Freed"
    }


    [System.Windows.MessageBox]::Show(
        "PUSI OPTI ha terminado.`n`nCorrectos: $script:ResultadosOK`nErrores: $script:ResultadosError`nOmitidos: $script:ResultadosOmitidos$Extra`n`nCambios que pueden requerir reinicio: $($RestartSelected.Count)",
        "PUSI OPTI - Resultado",
        "OK",
        "Information"
    )


    Update-PusiState
})


# ============================================================
# REVERTIR
# ============================================================

$Window.FindName("RevertSelected").Add_Click({

    if ($Window.FindName("OptTelemetry").IsChecked) {

        Remove-RegValue `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
            "AllowTelemetry" |
            Out-Null
    }


    if ($Window.FindName("OptActivityHistory").IsChecked) {

        Remove-RegValue `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "EnableActivityFeed" |
            Out-Null


        Remove-RegValue `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "PublishUserActivities" |
            Out-Null
    }


    if ($Window.FindName("OptGameDVR").IsChecked) {

        Set-RegDWORD `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_Enabled" `
            1 |
            Out-Null
    }


    if ($Window.FindName("OptGameMode").IsChecked) {

        Remove-RegValue `
            "HKCU:\Software\Microsoft\GameBar" `
            "AutoGameModeEnabled" |
            Out-Null
    }


    if ($Window.FindName("OptPowerThrottling").IsChecked) {

        Remove-RegValue `
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
            "PowerThrottlingOff" |
            Out-Null
    }


    if ($Window.FindName("OptTransparency").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            "EnableTransparency" `
            1 |
            Out-Null
    }


    if ($Window.FindName("OptAnimations").IsChecked) {

        Set-RegString `
            "HKCU:\Control Panel\Desktop\WindowMetrics" `
            "MinAnimate" `
            "1" |
            Out-Null
    }


    if ($Window.FindName("OptFileExtensions").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "HideFileExt" `
            1 |
            Out-Null
    }


    if ($Window.FindName("OptHiddenFiles").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Hidden" `
            2 |
            Out-Null
    }


    if ($Window.FindName("OptTaskbarSearch").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
            "SearchboxTaskbarMode" `
            1 |
            Out-Null
    }


    if ($Window.FindName("OptTaskView").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "ShowTaskViewButton" `
            1 |
            Out-Null
    }


    $StatusBar.Text =
        "Ajustes seleccionados revertidos."


    Update-PusiState
})


# ============================================================
# CONFIGURACION
# ============================================================

$Window.FindName("RunSFC").Add_Click({

    Start-Process `
        powershell.exe `
        -Verb RunAs `
        -ArgumentList '-NoExit -Command "sfc /scannow"'
})


$Window.FindName("RunDISM").Add_Click({

    Start-Process `
        powershell.exe `
        -Verb RunAs `
        -ArgumentList '-NoExit -Command "DISM /Online /Cleanup-Image /RestoreHealth"'
})


$Window.FindName("FlushDNS").Add_Click({

    ipconfig /flushdns |
        Out-Null


    $StatusBar.Text =
        "Caché DNS limpiada."
})


$Window.FindName("ResetNetwork").Add_Click({

    $Answer =
        [System.Windows.MessageBox]::Show(
            "Se restablecerán Winsock y TCP/IP.`n`nSerá necesario reiniciar Windows.`n`n¿Continuar?",
            "PUSI OPTI",
            "YesNo",
            "Warning"
        )


    if ($Answer -eq "Yes") {

        netsh winsock reset |
            Out-Null


        netsh int ip reset |
            Out-Null


        $StatusBar.Text =
            "Red restablecida. Reinicia Windows."
    }
})


$Window.FindName("DeepCleanup").Add_Click({

    $Freed =
        Invoke-PusiDeepCleanup `
            -StatusBar $StatusBar


    [System.Windows.MessageBox]::Show(
        "Limpieza completada.`n`nEspacio eliminado aproximadamente: $Freed",
        "PUSI OPTI",
        "OK",
        "Information"
    )
})


$Window.FindName("EmptyRecycle").Add_Click({

    Clear-RecycleBin `
        -Force `
        -ErrorAction SilentlyContinue


    $StatusBar.Text =
        "Papelera vaciada."
})


$Window.FindName("CheckTrim").Add_Click({

    $Result =
        fsutil behavior query DisableDeleteNotify


    [System.Windows.MessageBox]::Show(
        "$Result`n`nValor 0 = TRIM habilitado.",
        "PUSI OPTI - TRIM",
        "OK",
        "Information"
    )
})


$Window.FindName("OptimizeStorage").Add_Click({

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
        "Optimización de almacenamiento terminada."
})


# ============================================================
# WINDOWS UPDATE
# ============================================================

$Window.FindName("Pause7").Add_Click({

    $Now =
        (Get-Date).ToUniversalTime()


    $End =
        $Now.AddDays(7)


    Set-RegString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesStartTime" `
        $Now.ToString("yyyy-MM-ddTHH:mm:ssZ") |
        Out-Null


    Set-RegString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesExpiryTime" `
        $End.ToString("yyyy-MM-ddTHH:mm:ssZ") |
        Out-Null


    $StatusBar.Text =
        "Windows Update pausado 7 días."
})


$Window.FindName("Pause35").Add_Click({

    $Now =
        (Get-Date).ToUniversalTime()


    $End =
        $Now.AddDays(35)


    Set-RegString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesStartTime" `
        $Now.ToString("yyyy-MM-ddTHH:mm:ssZ") |
        Out-Null


    Set-RegString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesExpiryTime" `
        $End.ToString("yyyy-MM-ddTHH:mm:ssZ") |
        Out-Null


    $StatusBar.Text =
        "Windows Update pausado 35 días."
})


$Window.FindName("ResumeUpdates").Add_Click({

    Remove-RegValue `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesStartTime" |
        Out-Null


    Remove-RegValue `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesExpiryTime" |
        Out-Null


    $StatusBar.Text =
        "Pausa eliminada."
})


$Window.FindName("DisableDriverUpdates").Add_Click({

    Set-RegDWORD `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
        "ExcludeWUDriversInQualityUpdate" `
        1 |
        Out-Null


    $StatusBar.Text =
        "Drivers bloqueados en Windows Update."
})


$Window.FindName("EnableDriverUpdates").Add_Click({

    Remove-RegValue `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
        "ExcludeWUDriversInQualityUpdate" |
        Out-Null


    $StatusBar.Text =
        "Actualización de drivers restaurada."
})


$Window.FindName("DisableWU").Add_Click({

    $Answer =
        [System.Windows.MessageBox]::Show(
            "Esto puede impedir actualizaciones y parches de seguridad.`n`n¿Desactivar Windows Update?",
            "PUSI OPTI",
            "YesNo",
            "Warning"
        )


    if ($Answer -ne "Yes") {

        return
    }


    Set-RegDWORD `
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


$Window.FindName("EnableWU").Add_Click({

    Remove-RegValue `
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

Update-PusiState


$Progress.Value =
    0


# ============================================================
# MOSTRAR
# ============================================================

$Window.ShowDialog() |
    Out-Null
