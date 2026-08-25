# ============================================================
# PUSI OPTI
# Windows Optimization Utility
# Version 0.3
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
# FUNCIONES REGISTRO
# ============================================================

function Set-RegDWORD {

    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

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
        -Force |
        Out-Null
}


function Set-RegString {

    param(
        [string]$Path,
        [string]$Name,
        [string]$Value
    )

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
        -Force |
        Out-Null
}


function Remove-RegValue {

    param(
        [string]$Path,
        [string]$Name
    )

    Remove-ItemProperty `
        -Path $Path `
        -Name $Name `
        -ErrorAction SilentlyContinue
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
# PLAN ENERGIA PUSI
# ============================================================

function Enable-PusiPowerPlan {

    param(
        $StatusBar
    )

    $StatusBar.Text =
        "Preparando Plan energia Pusi..."


    try {

        $PlanName =
            "Plan energia Pusi"


        # ----------------------------------------------------
        # COMPROBAR SI YA EXISTE
        # ----------------------------------------------------

        $Existing =
            powercfg /list |
            Select-String -SimpleMatch $PlanName


        if ($Existing) {

            $ExistingGuid =
                [regex]::Match(
                    $Existing.ToString(),
                    '[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}'
                ).Value


            if ($ExistingGuid) {

                powercfg /setactive $ExistingGuid |
                    Out-Null


                $StatusBar.Text =
                    "Plan energia Pusi activado."


                return $true

            }

        }


        # ----------------------------------------------------
        # DESCARGAR POW
        # ----------------------------------------------------

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


        # ----------------------------------------------------
        # GUID CONTROLADO DE PUSI
        # ----------------------------------------------------

        $PusiGuid =
            "7f34a6b5-1f2d-4c73-9b01-5b851dd62864"


        powercfg /delete $PusiGuid 2>$null |
            Out-Null


        powercfg /import $TempPow $PusiGuid |
            Out-Null


        # ----------------------------------------------------
        # RENOMBRAR
        # ----------------------------------------------------

        powercfg /changename `
            $PusiGuid `
            "Plan energia Pusi" `
            "PUSI OPTI - Perfil de maximo rendimiento para sobremesa" |
            Out-Null


        # ----------------------------------------------------
        # ACTIVAR
        # ----------------------------------------------------

        powercfg /setactive $PusiGuid |
            Out-Null


        Remove-Item `
            $TempPow `
            -Force `
            -ErrorAction SilentlyContinue


        $StatusBar.Text =
            "Plan energia Pusi activado."


        return $true

    }
    catch {

        $StatusBar.Text =
            "Error al activar Plan energia Pusi."


        return $false

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

    Width="1220"
    Height="820"

    MinWidth="1050"
    MinHeight="680"

    WindowStartupLocation="CenterScreen"

    Background="#111318">


    <Window.Resources>


        <Style TargetType="Button">

            <Setter Property="Background" Value="#20252B"/>
            <Setter Property="Foreground" Value="White"/>

            <Setter Property="BorderBrush" Value="#3A414A"/>
            <Setter Property="BorderThickness" Value="1"/>

            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="Margin" Value="4"/>

            <Setter Property="FontSize" Value="13"/>

        </Style>


        <Style TargetType="CheckBox">

            <Setter Property="Foreground" Value="White"/>

            <Setter Property="FontSize" Value="13"/>

            <Setter Property="Margin" Value="6"/>

        </Style>


        <Style TargetType="TextBlock">

            <Setter Property="Foreground" Value="White"/>

        </Style>


        <Style TargetType="TabItem">

            <Setter Property="Foreground" Value="White"/>

            <Setter Property="Background" Value="#181C21"/>

            <Setter Property="FontSize" Value="15"/>

            <Setter Property="FontWeight" Value="SemiBold"/>

            <Setter Property="Padding" Value="25,10"/>

        </Style>


    </Window.Resources>


    <Grid>


        <Grid.RowDefinitions>

            <RowDefinition Height="90"/>

            <RowDefinition Height="*"/>

            <RowDefinition Height="44"/>

        </Grid.RowDefinitions>


        <!-- ================================================= -->
        <!-- CABECERA -->
        <!-- ================================================= -->


        <Border
            Grid.Row="0"

            Background="#171A1F"

            BorderBrush="#30343B"

            BorderThickness="0,0,0,1">


            <Grid Margin="24,0">


                <Grid.ColumnDefinitions>

                    <ColumnDefinition Width="*"/>

                    <ColumnDefinition Width="Auto"/>

                </Grid.ColumnDefinitions>


                <StackPanel
                    VerticalAlignment="Center">


                    <TextBlock
                        Text="PUSI OPTI"

                        FontSize="31"

                        FontWeight="Bold"/>


                    <TextBlock
                        Text="Windows Optimization Utility"

                        Foreground="#AEB4BE"

                        FontSize="13"/>


                </StackPanel>


                <StackPanel
                    Grid.Column="1"

                    VerticalAlignment="Center">


                    <TextBlock
                        x:Name="SystemStatus"

                        Text="Detectando sistema..."

                        Foreground="#AEB4BE"

                        HorizontalAlignment="Right"/>


                    <TextBlock
                        Text="v0.3"

                        Foreground="#777D87"

                        HorizontalAlignment="Right"

                        Margin="0,5,0,0"/>


                </StackPanel>


            </Grid>


        </Border>


        <!-- ================================================= -->
        <!-- PESTAÑAS -->
        <!-- ================================================= -->


        <TabControl

            Grid.Row="1"

            Background="#111318"

            BorderBrush="#30343B">


            <!-- ================================================= -->
            <!-- OPTIMIZACION -->
            <!-- ================================================= -->


            <TabItem Header="OPTIMIZACIÓN">


                <Grid Margin="20">


                    <Grid.RowDefinitions>

                        <RowDefinition Height="Auto"/>

                        <RowDefinition Height="Auto"/>

                        <RowDefinition Height="*"/>

                        <RowDefinition Height="Auto"/>

                    </Grid.RowDefinitions>


                    <StackPanel>


                        <TextBlock

                            Text="Optimización de Windows"

                            FontSize="24"

                            FontWeight="Bold"/>


                        <TextBlock

                            Text="Selecciona los cambios que quieras aplicar."

                            Foreground="#AEB4BE"

                            Margin="0,5,0,14"/>


                    </StackPanel>


                    <!-- ================================================= -->
                    <!-- PRESETS -->
                    <!-- ================================================= -->


                    <WrapPanel Grid.Row="1">


                        <Button
                            x:Name="PresetBasico"

                            Content="BÁSICO"

                            Width="115"/>


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
                            x:Name="LimpiarSeleccion"

                            Content="LIMPIAR"

                            Width="110"/>


                    </WrapPanel>


                    <!-- ================================================= -->
                    <!-- OPTIMIZACIONES -->
                    <!-- ================================================= -->


                    <ScrollViewer

                        Grid.Row="2"

                        VerticalScrollBarVisibility="Auto">


                        <Grid Margin="0,14,0,10">


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

                                    Text="AJUSTES ESENCIALES"

                                    Foreground="#46D9FF"

                                    FontSize="17"

                                    FontWeight="Bold"

                                    Margin="5"/>


                                <CheckBox
                                    x:Name="OptRestorePoint"

                                    Content="Crear punto de restauración"/>


                                <CheckBox
                                    x:Name="OptTelemetry"

                                    Content="Desactivar telemetría"/>


                                <CheckBox
                                    x:Name="OptActivityHistory"

                                    Content="Desactivar historial de actividad"/>


                                <CheckBox
                                    x:Name="OptConsumerFeatures"

                                    Content="Desactivar contenido promocional"/>


                                <CheckBox
                                    x:Name="OptDeliveryOptimization"

                                    Content="Desactivar Delivery Optimization P2P"/>


                                <CheckBox
                                    x:Name="OptGameDVR"

                                    Content="Desactivar Game DVR"/>


                                <CheckBox
                                    x:Name="OptLocation"

                                    Content="Desactivar seguimiento de ubicación"/>


                                <CheckBox
                                    x:Name="OptSearchWeb"

                                    Content="Desactivar resultados web en búsqueda"/>


                                <CheckBox
                                    x:Name="OptWidgets"

                                    Content="Desactivar Widgets"/>


                                <CheckBox
                                    x:Name="OptTemporary"

                                    Content="Limpiar archivos temporales"/>


                                <Separator Margin="0,15"/>


                                <!-- ================================================= -->
                                <!-- RENDIMIENTO -->
                                <!-- ================================================= -->


                                <TextBlock

                                    Text="RENDIMIENTO"

                                    Foreground="#46D9FF"

                                    FontSize="17"

                                    FontWeight="Bold"

                                    Margin="5"/>


                                <CheckBox
                                    x:Name="OptPowerThrottling"

                                    Content="Desactivar Power Throttling"/>


                                <CheckBox
                                    x:Name="OptBackgroundApps"

                                    Content="Reducir aplicaciones en segundo plano"/>


                                <CheckBox
                                    x:Name="OptAnimations"

                                    Content="Desactivar animaciones de Windows"/>


                                <CheckBox
                                    x:Name="OptTransparency"

                                    Content="Desactivar transparencias"/>


                                <CheckBox
                                    x:Name="OptTaskbarAnimations"

                                    Content="Desactivar animaciones de barra de tareas"/>


                                <CheckBox
                                    x:Name="OptVisualEffects"

                                    Content="Efectos visuales orientados a rendimiento"/>


                                <CheckBox
                                    x:Name="OptHibernation"

                                    Content="Desactivar hibernación"/>


                                <CheckBox
                                    x:Name="OptOneDriveStartup"

                                    Content="Desactivar inicio automático de OneDrive"/>


                                <CheckBox
                                    x:Name="OptStorageSense"

                                    Content="Desactivar Storage Sense automático"/>


                            </StackPanel>


                            <!-- ================================================= -->
                            <!-- DERECHA -->
                            <!-- ================================================= -->


                            <StackPanel Grid.Column="2">


                                <TextBlock

                                    Text="PREFERENCIAS DE WINDOWS"

                                    Foreground="#46D9FF"

                                    FontSize="17"

                                    FontWeight="Bold"

                                    Margin="5"/>


                                <CheckBox
                                    x:Name="OptDarkMode"

                                    Content="Modo oscuro"/>


                                <CheckBox
                                    x:Name="OptLongPaths"

                                    Content="Activar rutas largas"/>


                                <CheckBox
                                    x:Name="OptFileExtensions"

                                    Content="Mostrar extensiones de archivo"/>


                                <CheckBox
                                    x:Name="OptHiddenFiles"

                                    Content="Mostrar archivos ocultos"/>


                                <CheckBox
                                    x:Name="OptGameMode"

                                    Content="Activar Game Mode"/>


                                <CheckBox
                                    x:Name="OptMouseAcceleration"

                                    Content="Desactivar aceleración del ratón"/>


                                <CheckBox
                                    x:Name="OptStickyKeys"

                                    Content="Desactivar Sticky Keys"/>


                                <CheckBox
                                    x:Name="OptTaskbarSearch"

                                    Content="Ocultar búsqueda de la barra de tareas"/>


                                <CheckBox
                                    x:Name="OptTaskView"

                                    Content="Ocultar Vista de tareas"/>


                                <CheckBox
                                    x:Name="OptStartRecommendations"

                                    Content="Desactivar recomendaciones del menú Inicio"/>


                                <CheckBox
                                    x:Name="OptWindowSnapping"

                                    Content="Activar ajuste de ventanas"/>


                                <Separator Margin="0,15"/>


                                <!-- ================================================= -->
                                <!-- ENERGIA -->
                                <!-- ================================================= -->


                                <TextBlock

                                    Text="PLAN DE ENERGÍA"

                                    Foreground="#46D9FF"

                                    FontSize="17"

                                    FontWeight="Bold"

                                    Margin="5"/>


                                <TextBlock

                                    Text="Perfil orientado a máximo rendimiento en equipos de sobremesa."

                                    Foreground="#AEB4BE"

                                    TextWrapping="Wrap"

                                    Margin="5,0,5,8"/>


                                <Button

                                    x:Name="EnablePusiPower"

                                    Content="ACTIVAR PLAN ENERGIA PUSI"

                                    HorizontalAlignment="Stretch"/>


                                <Button

                                    x:Name="EnableBalanced"

                                    Content="VOLVER A EQUILIBRADO"

                                    HorizontalAlignment="Stretch"/>


                            </StackPanel>


                        </Grid>


                    </ScrollViewer>


                    <!-- ================================================= -->
                    <!-- BOTONES -->
                    <!-- ================================================= -->


                    <StackPanel

                        Grid.Row="3"

                        Orientation="Horizontal"

                        HorizontalAlignment="Right">


                        <Button

                            x:Name="RevertirSeleccion"

                            Content="REVERTIR SELECCIONADOS"

                            Width="205"/>


                        <Button

                            x:Name="AplicarSeleccion"

                            Content="APLICAR SELECCIONADOS"

                            Width="205"/>


                    </StackPanel>


                </Grid>


            </TabItem>


            <!-- ================================================= -->
            <!-- CONFIGURACION -->
            <!-- ================================================= -->


            <TabItem Header="CONFIGURACIÓN">


                <ScrollViewer VerticalScrollBarVisibility="Auto">


                    <StackPanel Margin="25">


                        <TextBlock

                            Text="Configuración y mantenimiento"

                            FontSize="24"

                            FontWeight="Bold"/>


                        <TextBlock

                            Text="Herramientas de reparación y limpieza."

                            Foreground="#AEB4BE"

                            Margin="0,5,0,20"/>


                        <TextBlock

                            Text="REPARACIÓN DEL SISTEMA"

                            Foreground="#46D9FF"

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

                            Foreground="#46D9FF"

                            FontSize="17"

                            FontWeight="Bold"/>


                        <WrapPanel Margin="0,8">


                            <Button
                                x:Name="CleanTemp"

                                Content="LIMPIAR TEMPORALES"

                                Width="195"/>


                            <Button
                                x:Name="CleanShaderCache"

                                Content="LIMPIAR SHADER CACHE"

                                Width="200"/>


                            <Button
                                x:Name="EmptyRecycle"

                                Content="VACIAR PAPELERA"

                                Width="175"/>


                        </WrapPanel>


                        <Separator Margin="0,18"/>


                        <TextBlock

                            Text="ALMACENAMIENTO"

                            Foreground="#46D9FF"

                            FontSize="17"

                            FontWeight="Bold"/>


                        <WrapPanel Margin="0,8">


                            <Button
                                x:Name="CheckTrim"

                                Content="COMPROBAR TRIM"

                                Width="180"/>


                            <Button
                                x:Name="OptimizeSSD"

                                Content="OPTIMIZAR SSD / NVME"

                                Width="210"/>


                        </WrapPanel>


                    </StackPanel>


                </ScrollViewer>


            </TabItem>


            <!-- ================================================= -->
            <!-- ACTUALIZACIONES -->
            <!-- ================================================= -->


            <TabItem Header="ACTUALIZACIONES">


                <ScrollViewer VerticalScrollBarVisibility="Auto">


                    <StackPanel Margin="25">


                        <TextBlock

                            Text="Windows Update"

                            FontSize="24"

                            FontWeight="Bold"/>


                        <TextBlock

                            Text="Control de las actualizaciones de Windows."

                            Foreground="#AEB4BE"

                            Margin="0,5,0,20"/>


                        <Border

                            Background="#241D15"

                            BorderBrush="#A4762B"

                            BorderThickness="1"

                            Padding="15"

                            Margin="0,0,0,20">


                            <TextBlock

                                TextWrapping="Wrap"

                                Foreground="#E8C179"

                                Text="AVISO: desactivar Windows Update también puede impedir actualizaciones de seguridad. Utiliza el modo agresivo solo cuando sea necesario y reactívalo después."/>


                        </Border>


                        <TextBlock

                            Text="PAUSAR ACTUALIZACIONES"

                            Foreground="#46D9FF"

                            FontSize="17"

                            FontWeight="Bold"/>


                        <WrapPanel Margin="0,8">


                            <Button
                                x:Name="PauseUpdates7"

                                Content="PAUSAR 7 DÍAS"

                                Width="180"/>


                            <Button
                                x:Name="PauseUpdates35"

                                Content="PAUSAR 35 DÍAS"

                                Width="180"/>


                            <Button
                                x:Name="ResumeUpdates"

                                Content="QUITAR PAUSA"

                                Width="180"/>


                        </WrapPanel>


                        <Separator Margin="0,18"/>


                        <TextBlock

                            Text="DRIVERS"

                            Foreground="#46D9FF"

                            FontSize="17"

                            FontWeight="Bold"/>


                        <WrapPanel Margin="0,8">


                            <Button
                                x:Name="DisableDriverWU"

                                Content="BLOQUEAR DRIVERS DE WINDOWS UPDATE"

                                Width="310"/>


                            <Button
                                x:Name="EnableDriverWU"

                                Content="RESTAURAR DRIVERS"

                                Width="200"/>


                        </WrapPanel>


                        <Separator Margin="0,18"/>


                        <TextBlock

                            Text="MODO AGRESIVO"

                            Foreground="#FF956B"

                            FontSize="17"

                            FontWeight="Bold"/>


                        <TextBlock

                            Text="Deshabilita Windows Update mediante política y detiene su servicio principal."

                            Foreground="#AEB4BE"

                            TextWrapping="Wrap"

                            Margin="0,6,0,10"/>


                        <WrapPanel>


                            <Button
                                x:Name="DisableWindowsUpdate"

                                Content="DESACTIVAR WINDOWS UPDATE"

                                Width="260"/>


                            <Button
                                x:Name="EnableWindowsUpdate"

                                Content="REACTIVAR WINDOWS UPDATE"

                                Width="260"/>


                        </WrapPanel>


                    </StackPanel>


                </ScrollViewer>


            </TabItem>


        </TabControl>


        <!-- ================================================= -->
        <!-- ESTADO -->
        <!-- ================================================= -->


        <Border

            Grid.Row="2"

            Background="#171A1F"

            BorderBrush="#30343B"

            BorderThickness="0,1,0,0">


            <TextBlock

                x:Name="StatusBar"

                Text="PUSI OPTI lista."

                Foreground="#AEB4BE"

                VerticalAlignment="Center"

                Margin="16,0"/>


        </Border>


    </Grid>


</Window>

"@


# ============================================================
# CARGAR INTERFAZ
# ============================================================

$Reader =
    New-Object System.Xml.XmlNodeReader $XAML


$Window =
    [Windows.Markup.XamlReader]::Load($Reader)


$StatusBar =
    $Window.FindName("StatusBar")


$SystemStatus =
    $Window.FindName("SystemStatus")


# ============================================================
# INFORMACION DEL SISTEMA
# ============================================================

try {

    $OS =
        Get-CimInstance Win32_OperatingSystem


    $RAM =
        (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory


    $RAMGB =
        [math]::Round(
            $RAM / 1GB
        )


    $SystemStatus.Text =
        "$($OS.Caption) | $RAMGB GB RAM"

}
catch {

    $SystemStatus.Text =
        "Windows"

}


# ============================================================
# CHECKBOXES
# ============================================================

$Todas = @(

    "OptRestorePoint",
    "OptTelemetry",
    "OptActivityHistory",
    "OptConsumerFeatures",
    "OptDeliveryOptimization",
    "OptGameDVR",
    "OptLocation",
    "OptSearchWeb",
    "OptWidgets",
    "OptTemporary",

    "OptPowerThrottling",
    "OptBackgroundApps",
    "OptAnimations",
    "OptTransparency",
    "OptTaskbarAnimations",
    "OptVisualEffects",
    "OptHibernation",
    "OptOneDriveStartup",
    "OptStorageSense",

    "OptDarkMode",
    "OptLongPaths",
    "OptFileExtensions",
    "OptHiddenFiles",
    "OptGameMode",
    "OptMouseAcceleration",
    "OptStickyKeys",
    "OptTaskbarSearch",
    "OptTaskView",
    "OptStartRecommendations",
    "OptWindowSnapping"

)


function Clear-PusiSelection {

    foreach ($Name in $Todas) {

        $Window.FindName($Name).IsChecked =
            $false

    }

}


# ============================================================
# LIMPIAR
# ============================================================

$Window.FindName("LimpiarSeleccion").Add_Click({

    Clear-PusiSelection

    $StatusBar.Text =
        "Selección limpiada."

})


# ============================================================
# PRESET BASICO
# ============================================================

$Window.FindName("PresetBasico").Add_Click({

    Clear-PusiSelection


    @(

        "OptRestorePoint",
        "OptGameDVR",
        "OptFileExtensions",
        "OptGameMode",
        "OptConsumerFeatures"

    ) | ForEach-Object {

        $Window.FindName($_).IsChecked =
            $true

    }


    $StatusBar.Text =
        "Preset Básico seleccionado."

})


# ============================================================
# PRESET RECOMENDADO
# ============================================================

$Window.FindName("PresetRecomendado").Add_Click({

    Clear-PusiSelection


    @(

        "OptRestorePoint",
        "OptTelemetry",
        "OptActivityHistory",
        "OptConsumerFeatures",
        "OptDeliveryOptimization",
        "OptGameDVR",
        "OptSearchWeb",
        "OptWidgets",
        "OptTemporary",
        "OptBackgroundApps",
        "OptFileExtensions",
        "OptGameMode",
        "OptMouseAcceleration",
        "OptStickyKeys",
        "OptTaskbarSearch",
        "OptStartRecommendations"

    ) | ForEach-Object {

        $Window.FindName($_).IsChecked =
            $true

    }


    $StatusBar.Text =
        "Preset Recomendado seleccionado."

})


# ============================================================
# PRESET GAMING
# ============================================================

$Window.FindName("PresetGaming").Add_Click({

    Clear-PusiSelection


    @(

        "OptRestorePoint",

        "OptTelemetry",
        "OptActivityHistory",
        "OptConsumerFeatures",
        "OptDeliveryOptimization",

        "OptGameDVR",

        "OptWidgets",

        "OptSearchWeb",

        "OptPowerThrottling",

        "OptBackgroundApps",

        "OptAnimations",

        "OptTransparency",

        "OptTaskbarAnimations",

        "OptVisualEffects",

        "OptGameMode",

        "OptMouseAcceleration",

        "OptStickyKeys",

        "OptTaskbarSearch",

        "OptTaskView",

        "OptStartRecommendations"

    ) | ForEach-Object {

        $Window.FindName($_).IsChecked =
            $true

    }


    $StatusBar.Text =
        "Preset PUSI GAMING seleccionado."

})


# ============================================================
# PRESET AGRESIVO
# ============================================================

$Window.FindName("PresetAgresivo").Add_Click({

    foreach ($Name in $Todas) {

        $Window.FindName($Name).IsChecked =
            $true

    }


    $StatusBar.Text =
        "Preset Agresivo seleccionado."

})


# ============================================================
# PLAN ENERGIA PUSI
# ============================================================

$Window.FindName("EnablePusiPower").Add_Click({

    $Result =
        Enable-PusiPowerPlan `
            -StatusBar $StatusBar


    if ($Result) {

        [System.Windows.MessageBox]::Show(

            "Plan energia Pusi activado correctamente.",

            "PUSI OPTI",

            "OK",

            "Information"

        )

    }
    else {

        [System.Windows.MessageBox]::Show(

            "No se pudo importar o activar Plan energia Pusi.`n`nComprueba que Bitsum-Highest-Performance.pow está subido al repositorio.",

            "PUSI OPTI",

            "OK",

            "Error"

        )

    }

})


# ============================================================
# EQUILIBRADO
# ============================================================

$Window.FindName("EnableBalanced").Add_Click({

    powercfg /setactive SCHEME_BALANCED |
        Out-Null


    $StatusBar.Text =
        "Plan Equilibrado activado."

})


# ============================================================
# APLICAR OPTIMIZACIONES
# ============================================================

$Window.FindName("AplicarSeleccion").Add_Click({

    $StatusBar.Text =
        "Aplicando optimizaciones..."


    # ========================================================
    # RESTORE
    # ========================================================

    if (
        $Window.FindName(
            "OptRestorePoint"
        ).IsChecked
    ) {

        $StatusBar.Text =
            "Creando punto de restauración..."


        New-PusiRestorePoint |
            Out-Null

    }


    # ========================================================
    # TELEMETRIA
    # ========================================================

    if ($Window.FindName("OptTelemetry").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
            "AllowTelemetry" `
            0

    }


    # ========================================================
    # ACTIVITY HISTORY
    # ========================================================

    if ($Window.FindName("OptActivityHistory").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "EnableActivityFeed" `
            0


        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "PublishUserActivities" `
            0


        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "UploadUserActivities" `
            0

    }


    # ========================================================
    # CONSUMER FEATURES
    # ========================================================

    if ($Window.FindName("OptConsumerFeatures").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
            "DisableWindowsConsumerFeatures" `
            1

    }


    # ========================================================
    # DELIVERY OPTIMIZATION
    # ========================================================

    if ($Window.FindName("OptDeliveryOptimization").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" `
            "DODownloadMode" `
            0

    }


    # ========================================================
    # GAME DVR
    # ========================================================

    if ($Window.FindName("OptGameDVR").IsChecked) {

        Set-RegDWORD `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_Enabled" `
            0


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
            "AppCaptureEnabled" `
            0

    }


    # ========================================================
    # LOCATION
    # ========================================================

    if ($Window.FindName("OptLocation").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" `
            "DisableLocation" `
            1

    }


    # ========================================================
    # SEARCH WEB
    # ========================================================

    if ($Window.FindName("OptSearchWeb").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Policies\Microsoft\Windows\Explorer" `
            "DisableSearchBoxSuggestions" `
            1

    }


    # ========================================================
    # WIDGETS
    # ========================================================

    if ($Window.FindName("OptWidgets").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarDa" `
            0

    }


    # ========================================================
    # TEMPORALES
    # ========================================================

    if ($Window.FindName("OptTemporary").IsChecked) {

        Remove-Item `
            "$env:TEMP\*" `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue


        Remove-Item `
            "$env:SystemRoot\Temp\*" `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue

    }


    # ========================================================
    # POWER THROTTLING
    # ========================================================

    if ($Window.FindName("OptPowerThrottling").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
            "PowerThrottlingOff" `
            1

    }


    # ========================================================
    # BACKGROUND APPS
    # ========================================================

    if ($Window.FindName("OptBackgroundApps").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
            "GlobalUserDisabled" `
            1

    }


    # ========================================================
    # ANIMACIONES
    # ========================================================

    if ($Window.FindName("OptAnimations").IsChecked) {

        Set-RegString `
            "HKCU:\Control Panel\Desktop\WindowMetrics" `
            "MinAnimate" `
            "0"

    }


    # ========================================================
    # TRANSPARENCIA
    # ========================================================

    if ($Window.FindName("OptTransparency").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            "EnableTransparency" `
            0

    }


    # ========================================================
    # TASKBAR ANIMATIONS
    # ========================================================

    if ($Window.FindName("OptTaskbarAnimations").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarAnimations" `
            0

    }


    # ========================================================
    # VISUAL EFFECTS
    # ========================================================

    if ($Window.FindName("OptVisualEffects").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
            "VisualFXSetting" `
            2

    }


    # ========================================================
    # HIBERNACION
    # ========================================================

    if ($Window.FindName("OptHibernation").IsChecked) {

        powercfg /hibernate off |
            Out-Null

    }


    # ========================================================
    # ONEDRIVE STARTUP
    # ========================================================

    if ($Window.FindName("OptOneDriveStartup").IsChecked) {

        Remove-RegValue `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
            "OneDrive"

    }


    # ========================================================
    # STORAGE SENSE
    # ========================================================

    if ($Window.FindName("OptStorageSense").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" `
            "01" `
            0

    }


    # ========================================================
    # DARK MODE
    # ========================================================

    if ($Window.FindName("OptDarkMode").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            "AppsUseLightTheme" `
            0


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            "SystemUsesLightTheme" `
            0

    }


    # ========================================================
    # LONG PATHS
    # ========================================================

    if ($Window.FindName("OptLongPaths").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
            "LongPathsEnabled" `
            1

    }


    # ========================================================
    # EXTENSIONES
    # ========================================================

    if ($Window.FindName("OptFileExtensions").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "HideFileExt" `
            0

    }


    # ========================================================
    # ARCHIVOS OCULTOS
    # ========================================================

    if ($Window.FindName("OptHiddenFiles").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Hidden" `
            1

    }


    # ========================================================
    # GAME MODE
    # ========================================================

    if ($Window.FindName("OptGameMode").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\GameBar" `
            "AutoGameModeEnabled" `
            1

    }


    # ========================================================
    # MOUSE ACCELERATION
    # ========================================================

    if ($Window.FindName("OptMouseAcceleration").IsChecked) {

        Set-RegString `
            "HKCU:\Control Panel\Mouse" `
            "MouseSpeed" `
            "0"


        Set-RegString `
            "HKCU:\Control Panel\Mouse" `
            "MouseThreshold1" `
            "0"


        Set-RegString `
            "HKCU:\Control Panel\Mouse" `
            "MouseThreshold2" `
            "0"

    }


    # ========================================================
    # STICKY KEYS
    # ========================================================

    if ($Window.FindName("OptStickyKeys").IsChecked) {

        Set-RegString `
            "HKCU:\Control Panel\Accessibility\StickyKeys" `
            "Flags" `
            "506"

    }


    # ========================================================
    # TASKBAR SEARCH
    # ========================================================

    if ($Window.FindName("OptTaskbarSearch").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
            "SearchboxTaskbarMode" `
            0

    }


    # ========================================================
    # TASK VIEW
    # ========================================================

    if ($Window.FindName("OptTaskView").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "ShowTaskViewButton" `
            0

    }


    # ========================================================
    # START RECOMMENDATIONS
    # ========================================================

    if ($Window.FindName("OptStartRecommendations").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Start_IrisRecommendations" `
            0

    }


    # ========================================================
    # WINDOW SNAPPING
    # ========================================================

    if ($Window.FindName("OptWindowSnapping").IsChecked) {

        Set-RegString `
            "HKCU:\Control Panel\Desktop" `
            "WindowArrangementActive" `
            "1"

    }


    # ========================================================
    # FINAL
    # ========================================================

    $StatusBar.Text =
        "Optimización terminada."


    [System.Windows.MessageBox]::Show(

        "Los ajustes seleccionados han sido aplicados.`n`nAlgunos cambios necesitan reiniciar Windows.",

        "PUSI OPTI",

        "OK",

        "Information"

    )

})


# ============================================================
# REVERTIR SELECCIONADOS
# ============================================================

$Window.FindName("RevertirSeleccion").Add_Click({

    $StatusBar.Text =
        "Revirtiendo ajustes..."


    if ($Window.FindName("OptTelemetry").IsChecked) {

        Remove-RegValue `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
            "AllowTelemetry"

    }


    if ($Window.FindName("OptActivityHistory").IsChecked) {

        Remove-RegValue `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "EnableActivityFeed"


        Remove-RegValue `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "PublishUserActivities"


        Remove-RegValue `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "UploadUserActivities"

    }


    if ($Window.FindName("OptConsumerFeatures").IsChecked) {

        Remove-RegValue `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
            "DisableWindowsConsumerFeatures"

    }


    if ($Window.FindName("OptDeliveryOptimization").IsChecked) {

        Remove-RegValue `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" `
            "DODownloadMode"

    }


    if ($Window.FindName("OptGameDVR").IsChecked) {

        Set-RegDWORD `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_Enabled" `
            1


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
            "AppCaptureEnabled" `
            1

    }


    if ($Window.FindName("OptLocation").IsChecked) {

        Remove-RegValue `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" `
            "DisableLocation"

    }


    if ($Window.FindName("OptSearchWeb").IsChecked) {

        Remove-RegValue `
            "HKCU:\Software\Policies\Microsoft\Windows\Explorer" `
            "DisableSearchBoxSuggestions"

    }


    if ($Window.FindName("OptWidgets").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarDa" `
            1

    }


    if ($Window.FindName("OptPowerThrottling").IsChecked) {

        Remove-RegValue `
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
            "PowerThrottlingOff"

    }


    if ($Window.FindName("OptBackgroundApps").IsChecked) {

        Remove-RegValue `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
            "GlobalUserDisabled"

    }


    if ($Window.FindName("OptAnimations").IsChecked) {

        Set-RegString `
            "HKCU:\Control Panel\Desktop\WindowMetrics" `
            "MinAnimate" `
            "1"

    }


    if ($Window.FindName("OptTransparency").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            "EnableTransparency" `
            1

    }


    if ($Window.FindName("OptTaskbarAnimations").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarAnimations" `
            1

    }


    if ($Window.FindName("OptVisualEffects").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
            "VisualFXSetting" `
            0

    }


    if ($Window.FindName("OptHibernation").IsChecked) {

        powercfg /hibernate on |
            Out-Null

    }


    if ($Window.FindName("OptStorageSense").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" `
            "01" `
            1

    }


    if ($Window.FindName("OptDarkMode").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            "AppsUseLightTheme" `
            1


        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            "SystemUsesLightTheme" `
            1

    }


    if ($Window.FindName("OptLongPaths").IsChecked) {

        Remove-RegValue `
            "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
            "LongPathsEnabled"

    }


    if ($Window.FindName("OptFileExtensions").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "HideFileExt" `
            1

    }


    if ($Window.FindName("OptHiddenFiles").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Hidden" `
            2

    }


    if ($Window.FindName("OptGameMode").IsChecked) {

        Remove-RegValue `
            "HKCU:\Software\Microsoft\GameBar" `
            "AutoGameModeEnabled"

    }


    if ($Window.FindName("OptMouseAcceleration").IsChecked) {

        Set-RegString `
            "HKCU:\Control Panel\Mouse" `
            "MouseSpeed" `
            "1"

    }


    if ($Window.FindName("OptTaskbarSearch").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
            "SearchboxTaskbarMode" `
            1

    }


    if ($Window.FindName("OptTaskView").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "ShowTaskViewButton" `
            1

    }


    if ($Window.FindName("OptStartRecommendations").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Start_IrisRecommendations" `
            1

    }


    $StatusBar.Text =
        "Ajustes seleccionados revertidos."


    [System.Windows.MessageBox]::Show(

        "Reversión terminada.`n`nAlgunos cambios pueden necesitar reiniciar Windows.",

        "PUSI OPTI",

        "OK",

        "Information"

    )

})


# ============================================================
# SFC
# ============================================================

$Window.FindName("RunSFC").Add_Click({

    Start-Process `
        powershell.exe `
        -Verb RunAs `
        -ArgumentList '-NoExit -Command "sfc /scannow"'

})


# ============================================================
# DISM
# ============================================================

$Window.FindName("RunDISM").Add_Click({

    Start-Process `
        powershell.exe `
        -Verb RunAs `
        -ArgumentList '-NoExit -Command "DISM /Online /Cleanup-Image /RestoreHealth"'

})


# ============================================================
# FLUSH DNS
# ============================================================

$Window.FindName("FlushDNS").Add_Click({

    ipconfig /flushdns |
        Out-Null


    $StatusBar.Text =
        "Caché DNS limpiada."

})


# ============================================================
# RESET NETWORK
# ============================================================

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


# ============================================================
# LIMPIAR TEMP
# ============================================================

$Window.FindName("CleanTemp").Add_Click({

    $StatusBar.Text =
        "Limpiando temporales..."


    Remove-Item `
        "$env:TEMP\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue


    Remove-Item `
        "$env:SystemRoot\Temp\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue


    $StatusBar.Text =
        "Temporales limpiados."

})


# ============================================================
# SHADER CACHE
# ============================================================

$Window.FindName("CleanShaderCache").Add_Click({

    Remove-Item `
        "$env:LOCALAPPDATA\D3DSCache\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue


    Remove-Item `
        "$env:LOCALAPPDATA\NVIDIA\DXCache\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue


    Remove-Item `
        "$env:LOCALAPPDATA\NVIDIA\GLCache\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue


    Remove-Item `
        "$env:LOCALAPPDATA\AMD\DxCache\*" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue


    $StatusBar.Text =
        "Shader Cache limpiada."

})


# ============================================================
# PAPELERA
# ============================================================

$Window.FindName("EmptyRecycle").Add_Click({

    Clear-RecycleBin `
        -Force `
        -ErrorAction SilentlyContinue


    $StatusBar.Text =
        "Papelera vaciada."

})


# ============================================================
# COMPROBAR TRIM
# ============================================================

$Window.FindName("CheckTrim").Add_Click({

    $Result =
        fsutil behavior query DisableDeleteNotify


    [System.Windows.MessageBox]::Show(

        "$Result`n`n0 = TRIM habilitado",

        "PUSI OPTI - TRIM",

        "OK",

        "Information"

    )

})


# ============================================================
# OPTIMIZAR SSD / NVME
# ============================================================

$Window.FindName("OptimizeSSD").Add_Click({

    $StatusBar.Text =
        "Ejecutando ReTrim..."


    try {

        $Volumes =
            Get-Volume |
            Where-Object {
                $_.DriveLetter -and
                $_.DriveType -eq "Fixed"
            }


        foreach ($Volume in $Volumes) {

            Optimize-Volume `
                -DriveLetter $Volume.DriveLetter `
                -ReTrim `
                -ErrorAction SilentlyContinue |
                Out-Null

        }


        $StatusBar.Text =
            "Optimización SSD/NVMe finalizada."

    }
    catch {

        $StatusBar.Text =
            "No se pudo completar ReTrim."

    }

})


# ============================================================
# PAUSA 7 DIAS
# ============================================================

$Window.FindName("PauseUpdates7").Add_Click({

    $Now =
        (Get-Date).ToUniversalTime()


    $End =
        $Now.AddDays(7)


    Set-RegString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesStartTime" `
        $Now.ToString("yyyy-MM-ddTHH:mm:ssZ")


    Set-RegString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesExpiryTime" `
        $End.ToString("yyyy-MM-ddTHH:mm:ssZ")


    $StatusBar.Text =
        "Actualizaciones pausadas 7 días."

})


# ============================================================
# PAUSA 35 DIAS
# ============================================================

$Window.FindName("PauseUpdates35").Add_Click({

    $Now =
        (Get-Date).ToUniversalTime()


    $End =
        $Now.AddDays(35)


    Set-RegString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesStartTime" `
        $Now.ToString("yyyy-MM-ddTHH:mm:ssZ")


    Set-RegString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesExpiryTime" `
        $End.ToString("yyyy-MM-ddTHH:mm:ssZ")


    $StatusBar.Text =
        "Actualizaciones pausadas 35 días."

})


# ============================================================
# QUITAR PAUSA
# ============================================================

$Window.FindName("ResumeUpdates").Add_Click({

    Remove-RegValue `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesStartTime"


    Remove-RegValue `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesExpiryTime"


    $StatusBar.Text =
        "Pausa de Windows Update eliminada."

})


# ============================================================
# BLOQUEAR DRIVER UPDATE
# ============================================================

$Window.FindName("DisableDriverWU").Add_Click({

    Set-RegDWORD `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
        "ExcludeWUDriversInQualityUpdate" `
        1


    $StatusBar.Text =
        "Drivers bloqueados en Windows Update."

})


# ============================================================
# RESTAURAR DRIVERS
# ============================================================

$Window.FindName("EnableDriverWU").Add_Click({

    Remove-RegValue `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
        "ExcludeWUDriversInQualityUpdate"


    $StatusBar.Text =
        "Actualización de drivers restaurada."

})


# ============================================================
# DESACTIVAR WINDOWS UPDATE
# ============================================================

$Window.FindName("DisableWindowsUpdate").Add_Click({

    $Answer =
        [System.Windows.MessageBox]::Show(

            "Esto impedirá las actualizaciones automáticas de Windows y puede bloquear parches de seguridad.`n`n¿Continuar?",

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
        1


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

$Window.FindName("EnableWindowsUpdate").Add_Click({

    Remove-RegValue `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
        "NoAutoUpdate"


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
# MOSTRAR
# ============================================================

$Window.ShowDialog() |
    Out-Null
