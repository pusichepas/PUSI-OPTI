# ============================================================
# PUSI OPTI TOOL v0.1
# ============================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ============================================================
# ADMIN CHECK
# ============================================================

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

if (-not (Test-Admin)) {

    if ($PSCommandPath) {
        Start-Process powershell.exe `
            -Verb RunAs `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    }
    else {
        [System.Windows.MessageBox]::Show(
            "PUSI OPTI necesita permisos de administrador.`n`nAbre PowerShell como administrador y vuelve a ejecutar el comando.",
            "PUSI OPTI",
            "OK",
            "Warning"
        )
    }

    exit
}


# ============================================================
# XAML
# ============================================================

[xml]$XAML = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="PUSI OPTI"
    Width="1100"
    Height="720"
    WindowStartupLocation="CenterScreen"
    ResizeMode="CanResize"
    Background="#111318">

    <Window.Resources>

        <Style TargetType="Button">
            <Setter Property="Background" Value="#21252B"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#3B4048"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="8"/>
        </Style>

        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="White"/>
        </Style>

        <Style TargetType="TabItem">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Background" Value="#1A1D22"/>
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="22,10"/>
        </Style>

    </Window.Resources>


    <Grid>

        <Grid.RowDefinitions>
            <RowDefinition Height="90"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="42"/>
        </Grid.RowDefinitions>


        <!-- ================================================= -->
        <!-- HEADER -->
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
                        Text="Windows Utility"
                        Foreground="#AEB4BE"
                        FontSize="13"/>

                </StackPanel>


                <StackPanel
                    Grid.Column="1"
                    VerticalAlignment="Center"
                    HorizontalAlignment="Right">

                    <TextBlock
                        x:Name="SystemStatus"
                        Text="Detectando sistema..."
                        Foreground="#AEB4BE"
                        HorizontalAlignment="Right"/>

                    <TextBlock
                        Text="v0.1"
                        Foreground="#777D87"
                        HorizontalAlignment="Right"
                        Margin="0,5,0,0"/>

                </StackPanel>

            </Grid>

        </Border>


        <!-- ================================================= -->
        <!-- TABS -->
        <!-- ================================================= -->

        <TabControl
            x:Name="MainTabs"
            Grid.Row="1"
            Background="#111318"
            BorderBrush="#30343B">


            <!-- ================================================= -->
            <!-- INSTALL -->
            <!-- ================================================= -->

            <TabItem Header="INSTALL">

                <Grid Margin="24">

                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <StackPanel>

                        <TextBlock
                            Text="Install Applications"
                            FontSize="24"
                            FontWeight="Bold"/>

                        <TextBlock
                            Text="Selecciona las aplicaciones que quieras instalar con Winget."
                            Foreground="#AEB4BE"
                            Margin="0,6,0,18"/>

                    </StackPanel>


                    <ScrollViewer
                        Grid.Row="1"
                        VerticalScrollBarVisibility="Auto">

                        <StackPanel>

                            <TextBlock
                                Text="Browsers"
                                FontSize="17"
                                FontWeight="Bold"
                                Margin="0,5,0,5"/>

                            <CheckBox x:Name="InstallChrome" Content="Google Chrome"/>
                            <CheckBox x:Name="InstallFirefox" Content="Mozilla Firefox"/>
                            <CheckBox x:Name="InstallBrave" Content="Brave Browser"/>


                            <Separator Margin="0,12"/>


                            <TextBlock
                                Text="Gaming"
                                FontSize="17"
                                FontWeight="Bold"
                                Margin="0,5,0,5"/>

                            <CheckBox x:Name="InstallSteam" Content="Steam"/>
                            <CheckBox x:Name="InstallDiscord" Content="Discord"/>
                            <CheckBox x:Name="InstallEpic" Content="Epic Games Launcher"/>


                            <Separator Margin="0,12"/>


                            <TextBlock
                                Text="Utilities"
                                FontSize="17"
                                FontWeight="Bold"
                                Margin="0,5,0,5"/>

                            <CheckBox x:Name="Install7Zip" Content="7-Zip"/>
                            <CheckBox x:Name="InstallNotepadPP" Content="Notepad++"/>
                            <CheckBox x:Name="InstallVLC" Content="VLC"/>
                            <CheckBox x:Name="InstallHWiNFO" Content="HWiNFO"/>
                            <CheckBox x:Name="InstallCrystalDiskInfo" Content="CrystalDiskInfo"/>

                        </StackPanel>

                    </ScrollViewer>


                    <StackPanel
                        Grid.Row="2"
                        Orientation="Horizontal"
                        HorizontalAlignment="Right">

                        <Button
                            x:Name="InstallSelectedButton"
                            Content="INSTALL SELECTED"
                            Width="180"/>

                    </StackPanel>

                </Grid>

            </TabItem>


            <!-- ================================================= -->
            <!-- TWEAKS -->
            <!-- ================================================= -->

            <TabItem Header="TWEAKS">

                <Grid Margin="24">

                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>


                    <StackPanel>

                        <TextBlock
                            Text="Windows Tweaks"
                            FontSize="24"
                            FontWeight="Bold"/>

                        <TextBlock
                            Text="Tweaks generales de Windows. No incluye tus optimizaciones manuales."
                            Foreground="#AEB4BE"
                            Margin="0,6,0,18"/>

                    </StackPanel>


                    <StackPanel
                        Grid.Row="1"
                        Orientation="Horizontal"
                        Margin="0,0,0,12">

                        <Button
                            x:Name="MinimalPresetButton"
                            Content="MINIMAL"
                            Width="120"/>

                        <Button
                            x:Name="StandardPresetButton"
                            Content="STANDARD"
                            Width="120"/>

                        <Button
                            x:Name="AdvancedPresetButton"
                            Content="ADVANCED"
                            Width="120"/>

                        <Button
                            x:Name="ClearTweaksButton"
                            Content="CLEAR"
                            Width="100"/>

                    </StackPanel>


                    <ScrollViewer
                        Grid.Row="2"
                        VerticalScrollBarVisibility="Auto">

                        <StackPanel>

                            <CheckBox x:Name="TweakRestorePoint" Content="Create Restore Point"/>
                            <CheckBox x:Name="TweakTelemetry" Content="Disable Telemetry"/>
                            <CheckBox x:Name="TweakActivityHistory" Content="Disable Activity History"/>
                            <CheckBox x:Name="TweakConsumerFeatures" Content="Disable Consumer Features"/>
                            <CheckBox x:Name="TweakGameDVR" Content="Disable Game DVR"/>
                            <CheckBox x:Name="TweakBingSearch" Content="Disable Bing Search"/>
                            <CheckBox x:Name="TweakWidgets" Content="Disable Widgets"/>
                            <CheckBox x:Name="TweakFileExtensions" Content="Show File Extensions"/>
                            <CheckBox x:Name="TweakHiddenFiles" Content="Show Hidden Files"/>
                            <CheckBox x:Name="TweakMouseAcceleration" Content="Disable Mouse Acceleration"/>

                        </StackPanel>

                    </ScrollViewer>


                    <StackPanel
                        Grid.Row="3"
                        Orientation="Horizontal"
                        HorizontalAlignment="Right">

                        <Button
                            x:Name="UndoTweaksButton"
                            Content="UNDO SELECTED"
                            Width="160"/>

                        <Button
                            x:Name="ApplyTweaksButton"
                            Content="APPLY SELECTED"
                            Width="170"/>

                    </StackPanel>

                </Grid>

            </TabItem>


            <!-- ================================================= -->
            <!-- CONFIG -->
            <!-- ================================================= -->

            <TabItem Header="CONFIG">

                <ScrollViewer
                    VerticalScrollBarVisibility="Auto">

                    <StackPanel Margin="24">

                        <TextBlock
                            Text="System Configuration"
                            FontSize="24"
                            FontWeight="Bold"/>

                        <TextBlock
                            Text="Herramientas y reparaciones de Windows."
                            Foreground="#AEB4BE"
                            Margin="0,6,0,18"/>


                        <TextBlock
                            Text="Windows Tools"
                            FontSize="17"
                            FontWeight="Bold"/>

                        <WrapPanel Margin="0,5,0,16">

                            <Button x:Name="OpenControlPanel" Content="Control Panel" Width="160"/>
                            <Button x:Name="OpenDeviceManager" Content="Device Manager" Width="160"/>
                            <Button x:Name="OpenServices" Content="Services" Width="160"/>
                            <Button x:Name="OpenRegistry" Content="Registry Editor" Width="160"/>
                            <Button x:Name="OpenTaskManager" Content="Task Manager" Width="160"/>
                            <Button x:Name="OpenMSConfig" Content="System Configuration" Width="170"/>

                        </WrapPanel>


                        <Separator Margin="0,8"/>


                        <TextBlock
                            Text="Repairs"
                            FontSize="17"
                            FontWeight="Bold"
                            Margin="0,12,0,5"/>

                        <WrapPanel>

                            <Button x:Name="RunSFC" Content="SFC Scan" Width="160"/>
                            <Button x:Name="RunDISM" Content="DISM Repair" Width="160"/>
                            <Button x:Name="FlushDNS" Content="Flush DNS" Width="160"/>
                            <Button x:Name="ResetNetwork" Content="Reset Network" Width="160"/>

                        </WrapPanel>


                        <Separator Margin="0,16"/>


                        <TextBlock
                            Text="Advanced"
                            FontSize="17"
                            FontWeight="Bold"
                            Margin="0,12,0,5"/>

                        <WrapPanel>

                            <Button x:Name="OpenPowerOptions" Content="Power Options" Width="160"/>
                            <Button x:Name="OpenNetworkConnections" Content="Network Connections" Width="170"/>
                            <Button x:Name="OpenSystemProperties" Content="System Properties" Width="170"/>
                            <Button x:Name="OpenOptionalFeatures" Content="Optional Features" Width="170"/>

                        </WrapPanel>

                    </StackPanel>

                </ScrollViewer>

            </TabItem>


            <!-- ================================================= -->
            <!-- UPDATES -->
            <!-- ================================================= -->

            <TabItem Header="UPDATES">

                <Grid Margin="24">

                    <StackPanel>

                        <TextBlock
                            Text="Windows Update"
                            FontSize="24"
                            FontWeight="Bold"/>

                        <TextBlock
                            Text="Administracion basica de actualizaciones."
                            Foreground="#AEB4BE"
                            Margin="0,6,0,22"/>


                        <TextBlock
                            Text="Windows"
                            FontSize="17"
                            FontWeight="Bold"/>

                        <WrapPanel Margin="0,8,0,20">

                            <Button
                                x:Name="OpenWindowsUpdate"
                                Content="OPEN WINDOWS UPDATE"
                                Width="190"/>

                            <Button
                                x:Name="CheckWingetUpdates"
                                Content="CHECK APP UPDATES"
                                Width="190"/>

                            <Button
                                x:Name="UpgradeAllApps"
                                Content="UPGRADE ALL APPS"
                                Width="190"/>

                        </WrapPanel>


                        <Separator/>


                        <TextBlock
                            Text="Update Preferences"
                            FontSize="17"
                            FontWeight="Bold"
                            Margin="0,18,0,8"/>

                        <CheckBox
                            x:Name="DisableDriverUpdates"
                            Content="Disable Driver Updates through Windows Update"/>

                    </StackPanel>

                </Grid>

            </TabItem>

        </TabControl>


        <!-- ================================================= -->
        <!-- STATUS BAR -->
        <!-- ================================================= -->

        <Border
            Grid.Row="2"
            Background="#171A1F"
            BorderBrush="#30343B"
            BorderThickness="0,1,0,0">

            <Grid Margin="16,0">

                <TextBlock
                    x:Name="StatusBar"
                    Text="PUSI OPTI ready."
                    VerticalAlignment="Center"
                    Foreground="#AEB4BE"/>

            </Grid>

        </Border>

    </Grid>

</Window>
"@


# ============================================================
# LOAD WINDOW
# ============================================================

$reader = New-Object System.Xml.XmlNodeReader $XAML
$Window = [Windows.Markup.XamlReader]::Load($reader)


# ============================================================
# CONTROLS
# ============================================================

$SystemStatus = $Window.FindName("SystemStatus")
$StatusBar = $Window.FindName("StatusBar")

$InstallSelectedButton = $Window.FindName("InstallSelectedButton")

$MinimalPresetButton = $Window.FindName("MinimalPresetButton")
$StandardPresetButton = $Window.FindName("StandardPresetButton")
$AdvancedPresetButton = $Window.FindName("AdvancedPresetButton")
$ClearTweaksButton = $Window.FindName("ClearTweaksButton")

$ApplyTweaksButton = $Window.FindName("ApplyTweaksButton")
$UndoTweaksButton = $Window.FindName("UndoTweaksButton")


# ============================================================
# SYSTEM INFO
# ============================================================

try {

    $OS = Get-CimInstance Win32_OperatingSystem
    $CPU = Get-CimInstance Win32_Processor | Select-Object -First 1
    $RAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory

    $RAMGB = [math]::Round($RAM / 1GB)

    $SystemStatus.Text =
        "$($OS.Caption) | $RAMGB GB RAM"

}
catch {

    $SystemStatus.Text = "Windows System"

}


# ============================================================
# INSTALL APPS
# ============================================================

$InstallSelectedButton.Add_Click({

    $StatusBar.Text = "Installing selected applications..."

    $Apps = @()

    if ($Window.FindName("InstallChrome").IsChecked) {
        $Apps += "Google.Chrome"
    }

    if ($Window.FindName("InstallFirefox").IsChecked) {
        $Apps += "Mozilla.Firefox"
    }

    if ($Window.FindName("InstallBrave").IsChecked) {
        $Apps += "Brave.Brave"
    }

    if ($Window.FindName("InstallSteam").IsChecked) {
        $Apps += "Valve.Steam"
    }

    if ($Window.FindName("InstallDiscord").IsChecked) {
        $Apps += "Discord.Discord"
    }

    if ($Window.FindName("InstallEpic").IsChecked) {
        $Apps += "EpicGames.EpicGamesLauncher"
    }

    if ($Window.FindName("Install7Zip").IsChecked) {
        $Apps += "7zip.7zip"
    }

    if ($Window.FindName("InstallNotepadPP").IsChecked) {
        $Apps += "Notepad++.Notepad++"
    }

    if ($Window.FindName("InstallVLC").IsChecked) {
        $Apps += "VideoLAN.VLC"
    }

    if ($Window.FindName("InstallHWiNFO").IsChecked) {
        $Apps += "REALiX.HWiNFO"
    }

    if ($Window.FindName("InstallCrystalDiskInfo").IsChecked) {
        $Apps += "CrystalDewWorld.CrystalDiskInfo"
    }


    if ($Apps.Count -eq 0) {

        [System.Windows.MessageBox]::Show(
            "No has seleccionado ninguna aplicacion.",
            "PUSI OPTI"
        )

        return
    }


    foreach ($App in $Apps) {

        $StatusBar.Text = "Installing $App..."

        Start-Process `
            winget `
            -ArgumentList "install --id $App --exact --silent --accept-package-agreements --accept-source-agreements" `
            -Wait `
            -WindowStyle Hidden

    }

    $StatusBar.Text = "Applications installed."

    [System.Windows.MessageBox]::Show(
        "Instalacion terminada.",
        "PUSI OPTI"
    )

})


# ============================================================
# PRESETS
# ============================================================

$MinimalPresetButton.Add_Click({

    $Window.FindName("TweakRestorePoint").IsChecked = $true
    $Window.FindName("TweakFileExtensions").IsChecked = $true
    $Window.FindName("TweakGameDVR").IsChecked = $true

})


$StandardPresetButton.Add_Click({

    $MinimalPresetButton.RaiseEvent(
        (New-Object Windows.RoutedEventArgs([Windows.Controls.Button]::ClickEvent))
    )

    $Window.FindName("TweakTelemetry").IsChecked = $true
    $Window.FindName("TweakActivityHistory").IsChecked = $true
    $Window.FindName("TweakConsumerFeatures").IsChecked = $true
    $Window.FindName("TweakBingSearch").IsChecked = $true
    $Window.FindName("TweakWidgets").IsChecked = $true

})


$AdvancedPresetButton.Add_Click({

    $StandardPresetButton.RaiseEvent(
        (New-Object Windows.RoutedEventArgs([Windows.Controls.Button]::ClickEvent))
    )

    $Window.FindName("TweakHiddenFiles").IsChecked = $true
    $Window.FindName("TweakMouseAcceleration").IsChecked = $true

})


$ClearTweaksButton.Add_Click({

    @(
        "TweakRestorePoint",
        "TweakTelemetry",
        "TweakActivityHistory",
        "TweakConsumerFeatures",
        "TweakGameDVR",
        "TweakBingSearch",
        "TweakWidgets",
        "TweakFileExtensions",
        "TweakHiddenFiles",
        "TweakMouseAcceleration"
    ) | ForEach-Object {

        $Window.FindName($_).IsChecked = $false

    }

})


# ============================================================
# APPLY TWEAKS
# ============================================================

$ApplyTweaksButton.Add_Click({

    $StatusBar.Text = "Applying tweaks..."


    if ($Window.FindName("TweakRestorePoint").IsChecked) {

        try {

            Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue

            Checkpoint-Computer `
                -Description "PUSI OPTI - PRE TWEAKS" `
                -RestorePointType "MODIFY_SETTINGS"

        }
        catch {}

    }


    if ($Window.FindName("TweakGameDVR").IsChecked) {

        New-Item `
            "HKCU:\System\GameConfigStore" `
            -Force |
            Out-Null

        Set-ItemProperty `
            "HKCU:\System\GameConfigStore" `
            GameDVR_Enabled `
            0

    }


    if ($Window.FindName("TweakMouseAcceleration").IsChecked) {

        Set-ItemProperty `
            "HKCU:\Control Panel\Mouse" `
            MouseSpeed `
            "0"

        Set-ItemProperty `
            "HKCU:\Control Panel\Mouse" `
            MouseThreshold1 `
            "0"

        Set-ItemProperty `
            "HKCU:\Control Panel\Mouse" `
            MouseThreshold2 `
            "0"

    }


    if ($Window.FindName("TweakFileExtensions").IsChecked) {

        Set-ItemProperty `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            HideFileExt `
            0

    }


    if ($Window.FindName("TweakHiddenFiles").IsChecked) {

        Set-ItemProperty `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            Hidden `
            1

    }


    $StatusBar.Text = "Tweaks applied."

    [System.Windows.MessageBox]::Show(
        "Tweaks aplicados.",
        "PUSI OPTI"
    )

})


# ============================================================
# UNDO
# ============================================================

$UndoTweaksButton.Add_Click({

    $StatusBar.Text = "Undoing selected tweaks..."


    if ($Window.FindName("TweakGameDVR").IsChecked) {

        Set-ItemProperty `
            "HKCU:\System\GameConfigStore" `
            GameDVR_Enabled `
            1

    }


    if ($Window.FindName("TweakMouseAcceleration").IsChecked) {

        Set-ItemProperty `
            "HKCU:\Control Panel\Mouse" `
            MouseSpeed `
            "1"

    }


    if ($Window.FindName("TweakFileExtensions").IsChecked) {

        Set-ItemProperty `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            HideFileExt `
            1

    }


    if ($Window.FindName("TweakHiddenFiles").IsChecked) {

        Set-ItemProperty `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            Hidden `
            2

    }


    $StatusBar.Text = "Selected tweaks reverted."

})


# ============================================================
# CONFIG BUTTONS
# ============================================================

$Window.FindName("OpenControlPanel").Add_Click({
    Start-Process control.exe
})

$Window.FindName("OpenDeviceManager").Add_Click({
    Start-Process devmgmt.msc
})

$Window.FindName("OpenServices").Add_Click({
    Start-Process services.msc
})

$Window.FindName("OpenRegistry").Add_Click({
    Start-Process regedit.exe
})

$Window.FindName("OpenTaskManager").Add_Click({
    Start-Process taskmgr.exe
})

$Window.FindName("OpenMSConfig").Add_Click({
    Start-Process msconfig.exe
})


$Window.FindName("RunSFC").Add_Click({

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoExit -Command sfc /scannow"

})


$Window.FindName("RunDISM").Add_Click({

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoExit -Command DISM /Online /Cleanup-Image /RestoreHealth"

})


$Window.FindName("FlushDNS").Add_Click({

    ipconfig /flushdns | Out-Null

    [System.Windows.MessageBox]::Show(
        "DNS cache limpiada.",
        "PUSI OPTI"
    )

})


$Window.FindName("ResetNetwork").Add_Click({

    $Result = [System.Windows.MessageBox]::Show(
        "Esto restablecera Winsock y TCP/IP.`nPuede ser necesario reiniciar.`n`nContinuar?",
        "PUSI OPTI",
        "YesNo",
        "Warning"
    )

    if ($Result -eq "Yes") {

        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null

        [System.Windows.MessageBox]::Show(
            "Network reset aplicado. Reinicia Windows.",
            "PUSI OPTI"
        )

    }

})


$Window.FindName("OpenPowerOptions").Add_Click({
    Start-Process powercfg.cpl
})

$Window.FindName("OpenNetworkConnections").Add_Click({
    Start-Process ncpa.cpl
})

$Window.FindName("OpenSystemProperties").Add_Click({
    Start-Process SystemPropertiesAdvanced.exe
})

$Window.FindName("OpenOptionalFeatures").Add_Click({
    Start-Process optionalfeatures.exe
})


# ============================================================
# UPDATES
# ============================================================

$Window.FindName("OpenWindowsUpdate").Add_Click({

    Start-Process "ms-settings:windowsupdate"

})


$Window.FindName("CheckWingetUpdates").Add_Click({

    Start-Process powershell.exe `
        -ArgumentList "-NoExit -Command winget upgrade"

})


$Window.FindName("UpgradeAllApps").Add_Click({

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoExit -Command winget upgrade --all --accept-package-agreements --accept-source-agreements"

})


# ============================================================
# SHOW
# ============================================================

$Window.ShowDialog() | Out-Null
