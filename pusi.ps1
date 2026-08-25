# ============================================================
# PUSI OPTI TOOL
# VERSION 0.2
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
# FUNCIONES AUXILIARES
# ============================================================

function Set-RegDWORD {

    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
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
        New-Item -Path $Path -Force | Out-Null
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


function Crear-PuntoRestauracion {

    try {

        Enable-ComputerRestore `
            -Drive "C:\" `
            -ErrorAction SilentlyContinue

        Checkpoint-Computer `
            -Description "PUSI OPTI - PRE OPTIMIZACION" `
            -RestorePointType "MODIFY_SETTINGS"

        return $true

    }
    catch {

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
    Width="1180"
    Height="780"
    MinWidth="1000"
    MinHeight="650"
    WindowStartupLocation="CenterScreen"
    Background="#111318">

    <Window.Resources>

        <Style TargetType="Button">

            <Setter Property="Background" Value="#20252B"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#3A414A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,7"/>
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

            <RowDefinition Height="88"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="42"/>

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
                        FontSize="30"
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
                        Text="v0.2"
                        Foreground="#777D87"
                        HorizontalAlignment="Right"
                        Margin="0,4,0,0"/>

                </StackPanel>

            </Grid>

        </Border>


        <!-- ================================================= -->
        <!-- TABS -->
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
                            Margin="0,4,0,12"/>

                    </StackPanel>


                    <!-- PRESETS -->

                    <WrapPanel Grid.Row="1">

                        <Button
                            x:Name="PresetBasico"
                            Content="BÁSICO"
                            Width="120"/>

                        <Button
                            x:Name="PresetRecomendado"
                            Content="RECOMENDADO"
                            Width="140"/>

                        <Button
                            x:Name="PresetAgresivo"
                            Content="AGRESIVO"
                            Width="120"/>

                        <Button
                            x:Name="LimpiarSeleccion"
                            Content="LIMPIAR SELECCIÓN"
                            Width="160"/>

                    </WrapPanel>


                    <!-- AJUSTES -->

                    <ScrollViewer
                        Grid.Row="2"
                        VerticalScrollBarVisibility="Auto">

                        <Grid Margin="0,12,0,10">

                            <Grid.ColumnDefinitions>

                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="20"/>
                                <ColumnDefinition Width="*"/>

                            </Grid.ColumnDefinitions>


                            <!-- IZQUIERDA -->

                            <StackPanel Grid.Column="0">


                                <TextBlock
                                    Text="AJUSTES ESENCIALES"
                                    FontSize="17"
                                    FontWeight="Bold"
                                    Foreground="#46D9FF"
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
                                    Content="Desactivar contenido promocional de Windows"/>

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
                                    Content="Eliminar Widgets de la barra de tareas"/>

                                <CheckBox
                                    x:Name="OptTemporary"
                                    Content="Limpiar archivos temporales"/>


                                <Separator Margin="0,14"/>


                                <TextBlock
                                    Text="AJUSTES AVANZADOS - PRECAUCIÓN"
                                    FontSize="17"
                                    FontWeight="Bold"
                                    Foreground="#46D9FF"
                                    Margin="5"/>


                                <CheckBox
                                    x:Name="OptBackgroundApps"
                                    Content="Reducir aplicaciones en segundo plano"/>

                                <CheckBox
                                    x:Name="OptReservedStorage"
                                    Content="Desactivar Reserved Storage"/>

                                <CheckBox
                                    x:Name="OptHibernation"
                                    Content="Desactivar hibernación"/>

                                <CheckBox
                                    x:Name="OptOneDriveStartup"
                                    Content="Desactivar inicio automático de OneDrive"/>

                                <CheckBox
                                    x:Name="OptVisualEffects"
                                    Content="Efectos visuales orientados a rendimiento"/>

                                <CheckBox
                                    x:Name="OptStorageSense"
                                    Content="Desactivar Storage Sense automático"/>

                            </StackPanel>


                            <!-- DERECHA -->

                            <StackPanel Grid.Column="2">


                                <TextBlock
                                    Text="PREFERENCIAS Y RENDIMIENTO"
                                    FontSize="17"
                                    FontWeight="Bold"
                                    Foreground="#46D9FF"
                                    Margin="5"/>


                                <CheckBox
                                    x:Name="OptDarkMode"
                                    Content="Modo oscuro de Windows"/>

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
                                    Content="Reducir recomendaciones del menú Inicio"/>

                                <CheckBox
                                    x:Name="OptWindowSnapping"
                                    Content="Activar ajuste de ventanas"/>


                                <Separator Margin="0,14"/>


                                <TextBlock
                                    Text="PLAN DE ENERGÍA"
                                    FontSize="17"
                                    FontWeight="Bold"
                                    Foreground="#46D9FF"
                                    Margin="5"/>


                                <Button
                                    x:Name="EnableUltimate"
                                    Content="ACTIVAR MÁXIMO RENDIMIENTO"
                                    HorizontalAlignment="Stretch"/>

                                <Button
                                    x:Name="DisableUltimate"
                                    Content="VOLVER A EQUILIBRADO"
                                    HorizontalAlignment="Stretch"/>

                            </StackPanel>

                        </Grid>

                    </ScrollViewer>


                    <!-- BOTONES -->

                    <StackPanel
                        Grid.Row="3"
                        Orientation="Horizontal"
                        HorizontalAlignment="Right">

                        <Button
                            x:Name="RevertirSeleccion"
                            Content="REVERTIR SELECCIONADOS"
                            Width="200"/>

                        <Button
                            x:Name="AplicarSeleccion"
                            Content="APLICAR SELECCIONADOS"
                            Width="200"/>

                    </StackPanel>

                </Grid>

            </TabItem>


            <!-- ================================================= -->
            <!-- CONFIGURACION -->
            <!-- ================================================= -->

            <TabItem Header="CONFIGURACIÓN">

                <ScrollViewer
                    VerticalScrollBarVisibility="Auto">

                    <StackPanel Margin="25">


                        <TextBlock
                            Text="Configuración y reparación"
                            FontSize="24"
                            FontWeight="Bold"/>

                        <TextBlock
                            Text="Herramientas de mantenimiento sin accesos innecesarios."
                            Foreground="#AEB4BE"
                            Margin="0,5,0,20"/>


                        <TextBlock
                            Text="REPARACIÓN DEL SISTEMA"
                            FontSize="17"
                            FontWeight="Bold"
                            Foreground="#46D9FF"/>


                        <WrapPanel Margin="0,8">

                            <Button
                                x:Name="RunSFC"
                                Content="SFC /SCANNOW"
                                Width="180"/>

                            <Button
                                x:Name="RunDISM"
                                Content="REPARAR CON DISM"
                                Width="180"/>

                            <Button
                                x:Name="FlushDNS"
                                Content="VACIAR DNS"
                                Width="180"/>

                            <Button
                                x:Name="ResetNetwork"
                                Content="REINICIAR RED"
                                Width="180"/>

                        </WrapPanel>


                        <Separator Margin="0,18"/>


                        <TextBlock
                            Text="LIMPIEZA"
                            FontSize="17"
                            FontWeight="Bold"
                            Foreground="#46D9FF"/>


                        <WrapPanel Margin="0,8">

                            <Button
                                x:Name="CleanTemp"
                                Content="LIMPIAR TEMPORALES"
                                Width="190"/>

                            <Button
                                x:Name="CleanShaderCache"
                                Content="LIMPIAR SHADER CACHE"
                                Width="190"/>

                            <Button
                                x:Name="EmptyRecycle"
                                Content="VACIAR PAPELERA"
                                Width="190"/>

                        </WrapPanel>


                    </StackPanel>

                </ScrollViewer>

            </TabItem>


            <!-- ================================================= -->
            <!-- ACTUALIZACIONES -->
            <!-- ================================================= -->

            <TabItem Header="ACTUALIZACIONES">

                <ScrollViewer
                    VerticalScrollBarVisibility="Auto">

                    <StackPanel Margin="25">


                        <TextBlock
                            Text="Windows Update"
                            FontSize="24"
                            FontWeight="Bold"/>

                        <TextBlock
                            Text="Control de actualizaciones de Windows."
                            Foreground="#AEB4BE"
                            Margin="0,5,0,20"/>


                        <Border
                            Background="#241D15"
                            BorderBrush="#A4762B"
                            BorderThickness="1"
                            Padding="14"
                            Margin="0,0,0,20">

                            <TextBlock
                                TextWrapping="Wrap"
                                Foreground="#E8C179"
                                Text="AVISO: desactivar Windows Update también puede impedir la llegada de actualizaciones de seguridad. PUSI OPTI permite revertir estos cambios."/>

                        </Border>


                        <TextBlock
                            Text="MODO RECOMENDADO"
                            FontSize="17"
                            FontWeight="Bold"
                            Foreground="#46D9FF"/>


                        <WrapPanel Margin="0,8">

                            <Button
                                x:Name="PauseUpdates7"
                                Content="PAUSAR 7 DÍAS"
                                Width="180"/>

                            <Button
                                x:Name="PauseUpdates35"
                                Content="PAUSAR 35 DÍAS"
                                Width="180"/>

                        </WrapPanel>


                        <Separator Margin="0,18"/>


                        <TextBlock
                            Text="CONTROL DE DRIVERS"
                            FontSize="17"
                            FontWeight="Bold"
                            Foreground="#46D9FF"/>


                        <WrapPanel Margin="0,8">

                            <Button
                                x:Name="DisableDriverWU"
                                Content="NO INSTALAR DRIVERS POR WINDOWS UPDATE"
                                Width="320"/>

                            <Button
                                x:Name="EnableDriverWU"
                                Content="RESTAURAR DRIVERS"
                                Width="200"/>

                        </WrapPanel>


                        <Separator Margin="0,18"/>


                        <TextBlock
                            Text="MODO AGRESIVO"
                            FontSize="17"
                            FontWeight="Bold"
                            Foreground="#FF956B"/>


                        <TextBlock
                            TextWrapping="Wrap"
                            Foreground="#AEB4BE"
                            Margin="0,6,0,10"
                            Text="Detiene y deshabilita temporalmente el servicio principal de Windows Update. Úsalo solo cuando sea necesario."/>


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
        <!-- STATUS -->
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
# CARGAR VENTANA
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
# INFORMACION DEL EQUIPO
# ============================================================

try {

    $OS =
        Get-CimInstance Win32_OperatingSystem

    $RAM =
        (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory

    $RAMGB =
        [math]::Round($RAM / 1GB)

    $SystemStatus.Text =
        "$($OS.Caption) | $RAMGB GB RAM"

}
catch {

    $SystemStatus.Text =
        "Sistema Windows"

}


# ============================================================
# LISTA DE CHECKBOXES
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
    "OptBackgroundApps",
    "OptReservedStorage",
    "OptHibernation",
    "OptOneDriveStartup",
    "OptVisualEffects",
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


# ============================================================
# PRESETS
# ============================================================

$Window.FindName("LimpiarSeleccion").Add_Click({

    foreach ($Nombre in $Todas) {

        $Window.FindName($Nombre).IsChecked = $false

    }

})


$Window.FindName("PresetBasico").Add_Click({

    foreach ($Nombre in $Todas) {
        $Window.FindName($Nombre).IsChecked = $false
    }

    $Window.FindName("OptRestorePoint").IsChecked = $true
    $Window.FindName("OptGameDVR").IsChecked = $true
    $Window.FindName("OptFileExtensions").IsChecked = $true
    $Window.FindName("OptGameMode").IsChecked = $true

})


$Window.FindName("PresetRecomendado").Add_Click({

    foreach ($Nombre in $Todas) {
        $Window.FindName($Nombre).IsChecked = $false
    }

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
        "OptFileExtensions",
        "OptGameMode",
        "OptMouseAcceleration",
        "OptStickyKeys",
        "OptTaskbarSearch",
        "OptStartRecommendations"

    ) | ForEach-Object {

        $Window.FindName($_).IsChecked = $true

    }

})


$Window.FindName("PresetAgresivo").Add_Click({

    foreach ($Nombre in $Todas) {
        $Window.FindName($Nombre).IsChecked = $true
    }

})


# ============================================================
# APLICAR OPTIMIZACIONES
# ============================================================

$Window.FindName("AplicarSeleccion").Add_Click({

    $StatusBar.Text =
        "Aplicando optimizaciones..."


    # RESTORE POINT

    if ($Window.FindName("OptRestorePoint").IsChecked) {

        Crear-PuntoRestauracion | Out-Null

    }


    # TELEMETRIA

    if ($Window.FindName("OptTelemetry").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
            "AllowTelemetry" `
            0

    }


    # ACTIVITY HISTORY

    if ($Window.FindName("OptActivityHistory").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "EnableActivityFeed" `
            0

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
            "PublishUserActivities" `
            0

    }


    # CONSUMER FEATURES

    if ($Window.FindName("OptConsumerFeatures").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
            "DisableWindowsConsumerFeatures" `
            1

    }


    # DELIVERY OPTIMIZATION

    if ($Window.FindName("OptDeliveryOptimization").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" `
            "DODownloadMode" `
            0

    }


    # GAME DVR

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


    # LOCATION

    if ($Window.FindName("OptLocation").IsChecked) {

        Set-RegString `
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" `
            "SensorPermissionState" `
            "0"

    }


    # SEARCH WEB

    if ($Window.FindName("OptSearchWeb").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Policies\Microsoft\Windows\Explorer" `
            "DisableSearchBoxSuggestions" `
            1

    }


    # WIDGETS

    if ($Window.FindName("OptWidgets").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarDa" `
            0

    }


    # TEMP

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


    # BACKGROUND APPS

    if ($Window.FindName("OptBackgroundApps").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
            "GlobalUserDisabled" `
            1

    }


    # HIBERNATION

    if ($Window.FindName("OptHibernation").IsChecked) {

        powercfg /hibernate off

    }


    # ONEDRIVE

    if ($Window.FindName("OptOneDriveStartup").IsChecked) {

        Remove-RegValue `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
            "OneDrive"

    }


    # VISUAL EFFECTS

    if ($Window.FindName("OptVisualEffects").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
            "VisualFXSetting" `
            2

    }


    # STORAGE SENSE

    if ($Window.FindName("OptStorageSense").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" `
            "01" `
            0

    }


    # DARK MODE

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


    # LONG PATHS

    if ($Window.FindName("OptLongPaths").IsChecked) {

        Set-RegDWORD `
            "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
            "LongPathsEnabled" `
            1

    }


    # EXTENSIONES

    if ($Window.FindName("OptFileExtensions").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "HideFileExt" `
            0

    }


    # OCULTOS

    if ($Window.FindName("OptHiddenFiles").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Hidden" `
            1

    }


    # GAME MODE

    if ($Window.FindName("OptGameMode").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\GameBar" `
            "AutoGameModeEnabled" `
            1

    }


    # MOUSE ACCELERATION

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


    # STICKY KEYS

    if ($Window.FindName("OptStickyKeys").IsChecked) {

        Set-RegString `
            "HKCU:\Control Panel\Accessibility\StickyKeys" `
            "Flags" `
            "506"

    }


    # TASKBAR SEARCH

    if ($Window.FindName("OptTaskbarSearch").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
            "SearchboxTaskbarMode" `
            0

    }


    # TASK VIEW

    if ($Window.FindName("OptTaskView").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "ShowTaskViewButton" `
            0

    }


    # RECOMENDACIONES INICIO

    if ($Window.FindName("OptStartRecommendations").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "Start_IrisRecommendations" `
            0

    }


    # WINDOW SNAPPING

    if ($Window.FindName("OptWindowSnapping").IsChecked) {

        Set-RegString `
            "HKCU:\Control Panel\Desktop" `
            "WindowArrangementActive" `
            "1"

    }


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
# REVERTIR
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

    }


    if ($Window.FindName("OptGameDVR").IsChecked) {

        Set-RegDWORD `
            "HKCU:\System\GameConfigStore" `
            "GameDVR_Enabled" `
            1

    }


    if ($Window.FindName("OptWidgets").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            "TaskbarDa" `
            1

    }


    if ($Window.FindName("OptBackgroundApps").IsChecked) {

        Remove-RegValue `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
            "GlobalUserDisabled"

    }


    if ($Window.FindName("OptHibernation").IsChecked) {

        powercfg /hibernate on

    }


    if ($Window.FindName("OptVisualEffects").IsChecked) {

        Set-RegDWORD `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
            "VisualFXSetting" `
            0

    }


    if ($Window.FindName("OptGameMode").IsChecked) {

        Remove-RegValue `
            "HKCU:\Software\Microsoft\GameBar" `
            "AutoGameModeEnabled"

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


    $StatusBar.Text =
        "Reversión terminada."

})


# ============================================================
# PLAN DE ENERGIA
# ============================================================

$Window.FindName("EnableUltimate").Add_Click({

    $StatusBar.Text =
        "Activando Máximo Rendimiento..."


    $Output =
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61


    $Guid =
        [regex]::Match(
            $Output,
            '[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}'
        ).Value


    if ($Guid) {

        powercfg /setactive $Guid

    }
    else {

        powercfg /setactive SCHEME_MIN

    }


    $StatusBar.Text =
        "Plan de Máximo Rendimiento activado."

})


$Window.FindName("DisableUltimate").Add_Click({

    powercfg /setactive SCHEME_BALANCED

    $StatusBar.Text =
        "Plan Equilibrado activado."

})


# ============================================================
# REPARACIONES
# ============================================================

$Window.FindName("RunSFC").Add_Click({

    Start-Process `
        powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoExit -Command `"sfc /scannow`""

})


$Window.FindName("RunDISM").Add_Click({

    Start-Process `
        powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoExit -Command `"DISM /Online /Cleanup-Image /RestoreHealth`""

})


$Window.FindName("FlushDNS").Add_Click({

    ipconfig /flushdns | Out-Null

    [System.Windows.MessageBox]::Show(
        "La caché DNS ha sido limpiada.",
        "PUSI OPTI"
    )

})


$Window.FindName("ResetNetwork").Add_Click({

    $Resultado =
        [System.Windows.MessageBox]::Show(
            "Se restablecerán Winsock y TCP/IP.`n`nSerá necesario reiniciar.`n`n¿Continuar?",
            "PUSI OPTI",
            "YesNo",
            "Warning"
        )


    if ($Resultado -eq "Yes") {

        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null

        [System.Windows.MessageBox]::Show(
            "Red restablecida.`nReinicia Windows.",
            "PUSI OPTI"
        )

    }

})


# ============================================================
# LIMPIEZA
# ============================================================

$Window.FindName("CleanTemp").Add_Click({

    $StatusBar.Text =
        "Limpiando temporales..."


    Remove-Item `
        "$env:TEMP\*" `
        -Force `
        -Recurse `
        -ErrorAction SilentlyContinue


    Remove-Item `
        "$env:SystemRoot\Temp\*" `
        -Force `
        -Recurse `
        -ErrorAction SilentlyContinue


    $StatusBar.Text =
        "Temporales eliminados."

})


$Window.FindName("CleanShaderCache").Add_Click({

    Remove-Item `
        "$env:LOCALAPPDATA\D3DSCache\*" `
        -Force `
        -Recurse `
        -ErrorAction SilentlyContinue


    $StatusBar.Text =
        "Shader Cache limpiada."

})


$Window.FindName("EmptyRecycle").Add_Click({

    Clear-RecycleBin `
        -Force `
        -ErrorAction SilentlyContinue


    $StatusBar.Text =
        "Papelera vaciada."

})


# ============================================================
# WINDOWS UPDATE
# ============================================================

$Window.FindName("PauseUpdates7").Add_Click({

    $Fecha =
        (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ")


    Set-RegString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesExpiryTime" `
        $Fecha


    $StatusBar.Text =
        "Actualizaciones pausadas 7 días."

})


$Window.FindName("PauseUpdates35").Add_Click({

    $Fecha =
        (Get-Date).AddDays(35).ToString("yyyy-MM-ddTHH:mm:ssZ")


    Set-RegString `
        "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
        "PauseUpdatesExpiryTime" `
        $Fecha


    $StatusBar.Text =
        "Actualizaciones pausadas 35 días."

})


# ============================================================
# DRIVER WINDOWS UPDATE
# ============================================================

$Window.FindName("DisableDriverWU").Add_Click({

    Set-RegDWORD `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
        "ExcludeWUDriversInQualityUpdate" `
        1


    $StatusBar.Text =
        "Drivers bloqueados en Windows Update."

})


$Window.FindName("EnableDriverWU").Add_Click({

    Remove-RegValue `
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
        "ExcludeWUDriversInQualityUpdate"


    $StatusBar.Text =
        "Drivers restaurados en Windows Update."

})


# ============================================================
# DESACTIVAR WINDOWS UPDATE
# ============================================================

$Window.FindName("DisableWindowsUpdate").Add_Click({

    $Respuesta =
        [System.Windows.MessageBox]::Show(
            "Esto deshabilitará el servicio principal de Windows Update.`n`nTambién puede impedir actualizaciones de seguridad.`n`n¿Continuar?",
            "PUSI OPTI",
            "YesNo",
            "Warning"
        )


    if ($Respuesta -ne "Yes") {
        return
    }


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
# MOSTRAR VENTANA
# ============================================================

$Window.ShowDialog() | Out-Null
