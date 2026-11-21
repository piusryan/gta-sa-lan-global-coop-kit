Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$root = $PSScriptRoot
$configPath = Join-Path $root 'coop\server.ini'
$backupPath = Join-Path $root 'coop\server.ini.bak'
$gameExe = Join-Path $root 'gta_sa.exe'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-Config {
    if (-not (Test-Path -LiteralPath $configPath)) {
        throw ('Config file not found: ' + $configPath)
    }
    return [System.IO.File]::ReadAllText($configPath, [System.Text.Encoding]::UTF8)
}

function Get-Setting {
    param([string]$Text, [string]$Key)
    $m = [regex]::Match($Text, '(?m)^[ \t]*' + $Key + '[ \t]*=[ \t]*(.*?)[ \t]*(\r?)$')
    if ($m.Success) { return $m.Groups[1].Value }
    return ''
}

function Set-Setting {
    param([string]$Text, [string]$Key, [string]$Value)
    $pattern = '(?m)^([ \t]*' + $Key + '[ \t]*=[ \t]*).*?(\r?)$'
    $replacement = '${1}' + $Value.Replace('$', '$$') + '${2}'
    if ([regex]::IsMatch($Text, $pattern)) {
        return [regex]::Replace($Text, $pattern, $replacement)
    }
    return $Text.TrimEnd([char[]]@("`r", "`n")) + "`r`n" + $Key + ' = ' + $Value + "`r`n"
}

function Get-LanIp {
    try {
        $ips = [System.Net.Dns]::GetHostEntry($env:COMPUTERNAME).AddressList |
            Where-Object { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork -and $_.ToString() -notlike '169.254*' }
        if ($ips) { return ($ips | Select-Object -First 1).ToString() }
    } catch { }
    return 'not detected'
}

function New-Label {
    param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H)
    $c = New-Object System.Windows.Forms.Label
    $c.Text = $Text
    $c.Location = New-Object System.Drawing.Point($X, $Y)
    $c.Size = New-Object System.Drawing.Size($W, $H)
    return $c
}

function New-Button {
    param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H)
    $c = New-Object System.Windows.Forms.Button
    $c.Text = $Text
    $c.Location = New-Object System.Drawing.Point($X, $Y)
    $c.Size = New-Object System.Drawing.Size($W, $H)
    $c.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    return $c
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'GTA SA Co-op - Network Mode Switcher'
$form.Size = New-Object System.Drawing.Size(660, 640)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 248)

$title = New-Label 'GTA SA Story Co-op' 22 16 320 26
$title.Font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($title)

$sub = New-Label 'Pick a mode, check the details, then click Apply. Simple.' 22 46 440 20
$sub.ForeColor = [System.Drawing.Color]::FromArgb(90, 90, 100)
$form.Controls.Add($sub)

$badge = New-Label 'CURRENT: LAN' 480 20 150 26
$badge.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$badge.TextAlign = [System.Windows.Forms.ContentAlignment]::MiddleCenter
$badge.BackColor = [System.Drawing.Color]::FromArgb(222, 240, 255)
$badge.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($badge)

$grpMode = New-Object System.Windows.Forms.GroupBox
$grpMode.Text = '1. Choose how to play'
$grpMode.Location = New-Object System.Drawing.Point(20, 78)
$grpMode.Size = New-Object System.Drawing.Size(600, 112)
$grpMode.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($grpMode)

$rbtnLan = New-Object System.Windows.Forms.RadioButton
$rbtnLan.Text = 'LAN only  -  both PCs on the same Wi-Fi / router'
$rbtnLan.Location = New-Object System.Drawing.Point(18, 28)
$rbtnLan.Size = New-Object System.Drawing.Size(560, 28)
$rbtnLan.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$rbtnLan.Checked = $true
$grpMode.Controls.Add($rbtnLan)

$rbtnGlobal = New-Object System.Windows.Forms.RadioButton
$rbtnGlobal.Text = 'GLOBAL / Online  -  play with friends over the internet'
$rbtnGlobal.Location = New-Object System.Drawing.Point(18, 68)
$rbtnGlobal.Size = New-Object System.Drawing.Size(560, 28)
$rbtnGlobal.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$grpMode.Controls.Add($rbtnGlobal)

$grpDetails = New-Object System.Windows.Forms.GroupBox
$grpDetails.Text = '2. Server details'
$grpDetails.Location = New-Object System.Drawing.Point(20, 200)
$grpDetails.Size = New-Object System.Drawing.Size(600, 160)
$grpDetails.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($grpDetails)

$grpDetails.Controls.Add((New-Label 'Name:' 16 30 70 20))
$txtName = New-Object System.Windows.Forms.TextBox
$txtName.Location = New-Object System.Drawing.Point(90, 26)
$txtName.Size = New-Object System.Drawing.Size(490, 24)
$grpDetails.Controls.Add($txtName)

$grpDetails.Controls.Add((New-Label 'Port:' 16 66 70 20))
$txtPort = New-Object System.Windows.Forms.TextBox
$txtPort.Location = New-Object System.Drawing.Point(90, 62)
$txtPort.Size = New-Object System.Drawing.Size(90, 24)
$grpDetails.Controls.Add($txtPort)

$grpDetails.Controls.Add((New-Label 'Max players:' 205 66 85 20))
$cmbPlayers = New-Object System.Windows.Forms.ComboBox
$cmbPlayers.Location = New-Object System.Drawing.Point(295, 62)
$cmbPlayers.Size = New-Object System.Drawing.Size(90, 24)
$cmbPlayers.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
@('2', '3', '4') | ForEach-Object { [void]$cmbPlayers.Items.Add($_) }
$grpDetails.Controls.Add($cmbPlayers)

$grpDetails.Controls.Add((New-Label 'Password:' 16 102 70 20))
$txtPassword = New-Object System.Windows.Forms.TextBox
$txtPassword.Location = New-Object System.Drawing.Point(90, 98)
$txtPassword.Size = New-Object System.Drawing.Size(360, 24)
$grpDetails.Controls.Add($txtPassword)

$chkShow = New-Object System.Windows.Forms.CheckBox
$chkShow.Text = 'Show'
$chkShow.Location = New-Object System.Drawing.Point(460, 100)
$chkShow.Size = New-Object System.Drawing.Size(100, 20)
$grpDetails.Controls.Add($chkShow)

$grpDetails.Controls.Add((New-Label 'Empty password = no password. For Global mode a password is strongly recommended.' 16 132 560 20))

$grpAdv = New-Object System.Windows.Forms.GroupBox
$grpAdv.Text = '3. Advanced - only if a friend cannot connect'
$grpAdv.Location = New-Object System.Drawing.Point(20, 370)
$grpAdv.Size = New-Object System.Drawing.Size(600, 86)
$grpAdv.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($grpAdv)

$grpAdv.Controls.Add((New-Label 'TURN relay:' 16 30 80 20))
$txtTurn = New-Object System.Windows.Forms.TextBox
$txtTurn.Location = New-Object System.Drawing.Point(100, 26)
$txtTurn.Size = New-Object System.Drawing.Size(480, 24)
$grpAdv.Controls.Add($txtTurn)

$hintTurn = New-Label 'metered:<app>:<api-key>   or   turn:<host>:<port>:<user>:<password>   (leave empty normally)' 100 52 480 20
$hintTurn.ForeColor = [System.Drawing.Color]::FromArgb(110, 110, 120)
$hintTurn.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$grpAdv.Controls.Add($hintTurn)

$info = New-Label '' 20 466 600 70
$info.BackColor = [System.Drawing.Color]::FromArgb(232, 244, 255)
$info.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$info.Padding = New-Object System.Windows.Forms.Padding(10, 8, 10, 8)
$form.Controls.Add($info)

$btnApply = New-Button 'Apply & Save' 22 548 150 36
$form.Controls.Add($btnApply)

$btnApplyLaunch = New-Button 'Apply & Launch GTA' 182 548 170 36
$form.Controls.Add($btnApplyLaunch)

$btnOpen = New-Button 'Open config' 362 548 120 36
$form.Controls.Add($btnOpen)

$btnCancel = New-Button 'Close' 492 548 128 36
$form.Controls.Add($btnCancel)

$ipLabel = New-Label ('Your LAN IP: ' + (Get-LanIp)) 22 596 600 20
$ipLabel.ForeColor = [System.Drawing.Color]::FromArgb(90, 90, 100)
$form.Controls.Add($ipLabel)

function Update-Info {
    if ($rbtnGlobal.Checked) {
        $info.Text = "GLOBAL MODE`r`nThe mod detects your public IP and forwards UDP 7788 automatically. Give friends the invite code shown in F9 (or your public IP). Close and restart GTA after applying."
        $info.BackColor = [System.Drawing.Color]::FromArgb(255, 242, 217)
        $badge.Text = 'MODE: GLOBAL'
        $badge.BackColor = [System.Drawing.Color]::FromArgb(255, 224, 168)
    } else {
        $info.Text = "LAN MODE`r`nBoth PCs must be on the same router. Friends connect with your LAN IP (shown at the bottom) and port 7788. Nothing else to set up."
        $info.BackColor = [System.Drawing.Color]::FromArgb(232, 244, 255)
        $badge.Text = 'MODE: LAN'
        $badge.BackColor = [System.Drawing.Color]::FromArgb(222, 240, 255)
    }
}

$rbtnLan.Add_CheckedChanged({ Update-Info })
$rbtnGlobal.Add_CheckedChanged({ Update-Info })

$chkShow.Add_CheckedChanged({
    $txtPassword.UseSystemPasswordChar = -not $chkShow.Checked
})

function Save-Config {
    $mode = if ($rbtnGlobal.Checked) { '1' } else { '0' }
    $name = $txtName.Text.Trim()
    $port = $txtPort.Text.Trim()
    $players = $cmbPlayers.SelectedItem
    $pass = $txtPassword.Text
    $turn = $txtTurn.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($name)) {
        [System.Windows.Forms.MessageBox]::Show($form, 'Please enter a server name.', 'Missing name', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return $false
    }
    $portNum = 0
    if (-not [int]::TryParse($port, [ref]$portNum) -or $portNum -lt 1 -or $portNum -gt 65535) {
        [System.Windows.Forms.MessageBox]::Show($form, 'Port must be a number from 1 to 65535.', 'Bad port', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return $false
    }
    if (-not $players) { $players = '2' }
    if ($mode -eq '1' -and [string]::IsNullOrWhiteSpace($pass)) {
        $answer = [System.Windows.Forms.MessageBox]::Show($form, 'Global mode with no password means anyone who finds the server can join. Continue anyway?', 'No password', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { return $false }
    }

    try {
        $text = Read-Config
        Copy-Item -LiteralPath $configPath -Destination $backupPath -Force
        $text = Set-Setting $text 'name' $name
        $text = Set-Setting $text 'port' $port
        $text = Set-Setting $text 'max_players' $players
        $text = Set-Setting $text 'password' $pass
        $text = Set-Setting $text 'internet' $mode
        $text = Set-Setting $text 'turn' $turn
        [System.IO.File]::WriteAllText($configPath, $text, $utf8NoBom)
    } catch {
        [System.Windows.Forms.MessageBox]::Show($form, $_.Exception.Message, 'Could not save', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
    Update-Info
    return $true
}

$btnApply.Add_Click({
    if (Save-Config) {
        [System.Windows.Forms.MessageBox]::Show($form, 'Saved. Close GTA completely and start it again, then press F9 in the game to host or join.', 'Done', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

$btnApplyLaunch.Add_Click({
    if (-not (Save-Config)) { return }
    if (Get-Process -Name 'gta_sa' -ErrorAction SilentlyContinue) {
        [System.Windows.Forms.MessageBox]::Show($form, 'GTA is already running. Close it first, then use this button.', 'Game is running', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    if (Test-Path -LiteralPath $gameExe) {
        Start-Process -FilePath $gameExe -WorkingDirectory $root
    } else {
        [System.Windows.Forms.MessageBox]::Show($form, 'gta_sa.exe was not found in this folder.', 'Missing game', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

$btnOpen.Add_Click({
    if (Test-Path -LiteralPath $configPath) {
        Start-Process -FilePath 'notepad.exe' -ArgumentList ('"' + $configPath + '"')
    }
})

$btnCancel.Add_Click({ $form.Close() })

try {
    $text = Read-Config
    $mode = (Get-Setting $text 'internet').Trim()
    if ($mode -eq '1') { $rbtnGlobal.Checked = $true } else { $rbtnLan.Checked = $true }

    $name = (Get-Setting $text 'name').Trim()
    if ($name) { $txtName.Text = $name }
    $port = (Get-Setting $text 'port').Trim()
    if ($port) { $txtPort.Text = $port } else { $txtPort.Text = '7788' }
    $players = (Get-Setting $text 'max_players').Trim()
    if ($players -in $cmbPlayers.Items) { $cmbPlayers.SelectedItem = $players } else { $cmbPlayers.SelectedItem = '2' }
    $txtPassword.Text = Get-Setting $text 'password'
    $txtTurn.Text = (Get-Setting $text 'turn').Trim()
    $txtPassword.UseSystemPasswordChar = $true
    Update-Info
} catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Config problem', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}

$form.AcceptButton = $btnApply
$form.CancelButton = $btnCancel
[void]$form.ShowDialog()
