#requires -Version 5.1
<#
.SYNOPSIS
    Simple Windows LAPS password viewer for Helpdesk.

.DESCRIPTION
    Provides a lightweight GUI for native Windows LAPS stored in on-premises
    Active Directory. Uses Get-LapsADPassword and Set-LapsADPasswordExpirationTime.

    The signed-in user's AD permissions determine what can be viewed or changed.
    No credentials or passwords are stored by this script.

.NOTES
    Requires the Microsoft Windows LAPS PowerShell module/cmdlets to be available.
    Run in Windows PowerShell 5.1 or PowerShell 7 on a Windows management PC
    that has access to Active Directory.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ----- Prerequisite check -----
$requiredCommands = @(
    'Get-LapsADPassword',
    'Set-LapsADPasswordExpirationTime'
)

$missing = $requiredCommands | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }

if ($missing) {
    [System.Windows.Forms.MessageBox]::Show(
        "The following Windows LAPS PowerShell command(s) are not available:`r`n`r`n$($missing -join "`r`n")`r`n`r`nInstall/enable the Windows LAPS management tools on this computer and try again.",
        "Windows LAPS tools not found",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

# ----- Main form -----
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows LAPS Helpdesk"
$form.StartPosition = "CenterScreen"
$form.ClientSize = New-Object System.Drawing.Size(640, 405)
$form.MinimumSize = New-Object System.Drawing.Size(656, 444)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.MaximizeBox = $false

# Computer name
$lblComputer = New-Object System.Windows.Forms.Label
$lblComputer.Text = "Computer name:"
$lblComputer.Location = New-Object System.Drawing.Point(18, 20)
$lblComputer.AutoSize = $true
$form.Controls.Add($lblComputer)

$txtComputer = New-Object System.Windows.Forms.TextBox
$txtComputer.Location = New-Object System.Drawing.Point(18, 43)
$txtComputer.Size = New-Object System.Drawing.Size(480, 25)
$txtComputer.CharacterCasing = 'Upper'
$form.Controls.Add($txtComputer)

$btnSearch = New-Object System.Windows.Forms.Button
$btnSearch.Text = "Search"
$btnSearch.Location = New-Object System.Drawing.Point(510, 41)
$btnSearch.Size = New-Object System.Drawing.Size(108, 29)
$form.Controls.Add($btnSearch)

$btnReset = New-Object System.Windows.Forms.Button
$btnReset.Text = "Reset"
$btnReset.Location = New-Object System.Drawing.Point(510, 76)
$btnReset.Size = New-Object System.Drawing.Size(108, 29)
$form.Controls.Add($btnReset)

# Account
$lblAccount = New-Object System.Windows.Forms.Label
$lblAccount.Text = "Managed account:"
$lblAccount.Location = New-Object System.Drawing.Point(18, 94)
$lblAccount.AutoSize = $true
$form.Controls.Add($lblAccount)

$txtAccount = New-Object System.Windows.Forms.TextBox
$txtAccount.Location = New-Object System.Drawing.Point(18, 115)
$txtAccount.Size = New-Object System.Drawing.Size(600, 25)
$txtAccount.ReadOnly = $true
$form.Controls.Add($txtAccount)

# Password
$lblPassword = New-Object System.Windows.Forms.Label
$lblPassword.Text = "Password:"
$lblPassword.Location = New-Object System.Drawing.Point(18, 153)
$lblPassword.AutoSize = $true
$form.Controls.Add($lblPassword)

$txtPassword = New-Object System.Windows.Forms.TextBox
$txtPassword.Location = New-Object System.Drawing.Point(18, 174)
$txtPassword.Size = New-Object System.Drawing.Size(480, 25)
$txtPassword.ReadOnly = $true
$txtPassword.UseSystemPasswordChar = $true
$form.Controls.Add($txtPassword)

$btnShow = New-Object System.Windows.Forms.Button
$btnShow.Text = "Show"
$btnShow.Location = New-Object System.Drawing.Point(510, 172)
$btnShow.Size = New-Object System.Drawing.Size(108, 29)
$btnShow.Enabled = $false
$form.Controls.Add($btnShow)

$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Text = "Copy password"
$btnCopy.Location = New-Object System.Drawing.Point(510, 207)
$btnCopy.Size = New-Object System.Drawing.Size(108, 29)
$btnCopy.Enabled = $false
$form.Controls.Add($btnCopy)

# Update / expiration
$lblUpdated = New-Object System.Windows.Forms.Label
$lblUpdated.Text = "Password updated:"
$lblUpdated.Location = New-Object System.Drawing.Point(18, 217)
$lblUpdated.AutoSize = $true
$form.Controls.Add($lblUpdated)

$txtUpdated = New-Object System.Windows.Forms.TextBox
$txtUpdated.Location = New-Object System.Drawing.Point(18, 238)
$txtUpdated.Size = New-Object System.Drawing.Size(480, 25)
$txtUpdated.ReadOnly = $true
$form.Controls.Add($txtUpdated)

$lblExpires = New-Object System.Windows.Forms.Label
$lblExpires.Text = "Password expires:"
$lblExpires.Location = New-Object System.Drawing.Point(18, 278)
$lblExpires.AutoSize = $true
$form.Controls.Add($lblExpires)

$txtExpires = New-Object System.Windows.Forms.TextBox
$txtExpires.Location = New-Object System.Drawing.Point(18, 299)
$txtExpires.Size = New-Object System.Drawing.Size(480, 25)
$txtExpires.ReadOnly = $true
$form.Controls.Add($txtExpires)

$btnExpire = New-Object System.Windows.Forms.Button
$btnExpire.Text = "Expire now"
$btnExpire.Location = New-Object System.Drawing.Point(510, 297)
$btnExpire.Size = New-Object System.Drawing.Size(108, 29)
$btnExpire.Enabled = $false
$form.Controls.Add($btnExpire)

# Status
$status = New-Object System.Windows.Forms.Label
$status.Text = "Enter a computer name and click Search."
$status.Location = New-Object System.Drawing.Point(18, 344)
$status.Size = New-Object System.Drawing.Size(600, 38)
$status.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($status)

# ----- Helpers -----
function Clear-LapsDisplay {
    $txtAccount.Clear()
    $txtPassword.Clear()
    $txtUpdated.Clear()
    $txtExpires.Clear()
    $btnShow.Enabled = $false
    $btnCopy.Enabled = $false
    $btnExpire.Enabled = $false
    $btnShow.Text = "Show"
    $txtPassword.UseSystemPasswordChar = $true
}

function Reset-LapsForm {
    Clear-LapsDisplay
    $txtComputer.Clear()
    Set-Status "Enter a computer name and click Search." 'Normal'
    $txtComputer.Focus()
}

function Set-Status {
    param(
        [string]$Text,
        [ValidateSet('Normal','Success','Error','Warning')]
        [string]$Type = 'Normal'
    )

    $status.Text = $Text

    switch ($Type) {
        'Success' { $status.ForeColor = [System.Drawing.Color]::DarkGreen }
        'Error'   { $status.ForeColor = [System.Drawing.Color]::Firebrick }
        'Warning' { $status.ForeColor = [System.Drawing.Color]::DarkOrange }
        default   { $status.ForeColor = [System.Drawing.Color]::DimGray }
    }
}

function Search-LapsPassword {
    $computer = $txtComputer.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($computer)) {
        Clear-LapsDisplay
        Set-Status "Enter a computer name." 'Warning'
        $txtComputer.Focus()
        return
    }

    Clear-LapsDisplay
    Set-Status "Searching Active Directory..." 'Normal'
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $form.Refresh()

    try {
        $result = Get-LapsADPassword -Identity $computer -AsPlainText -ErrorAction Stop

        # Get-LapsADPassword can return more than one result in some scenarios.
        # Use the first current password entry.
        $result = @($result) | Select-Object -First 1

        if (-not $result) {
            throw "No Windows LAPS data was returned."
        }

        $txtAccount.Text = if ($result.Account) { [string]$result.Account } else { "(not reported)" }

        if ($result.Password) {
            $txtPassword.Text = [string]$result.Password
            $btnShow.Enabled = $true
            $btnCopy.Enabled = $true
            $btnExpire.Enabled = $true
        }

        $txtUpdated.Text = if ($result.PasswordUpdateTime) {
            ([datetime]$result.PasswordUpdateTime).ToString("dddd, MMMM d, yyyy  h:mm:ss tt")
        } else {
            "(not reported)"
        }

        $txtExpires.Text = if ($result.ExpirationTimestamp) {
            ([datetime]$result.ExpirationTimestamp).ToString("dddd, MMMM d, yyyy  h:mm:ss tt")
        } else {
            "(not reported)"
        }

        if ($result.Password) {
            $source = if ($result.Source) { " Source: $($result.Source)." } else { "" }
            Set-Status "Password retrieved successfully.$source" 'Success'
        }
        elseif ($result.DecryptionStatus -eq 'Unauthorized') {
            Set-Status "LAPS data was found, but your account is not authorized to decrypt the password." 'Error'
        }
        else {
            $detail = if ($result.DecryptionStatus) { " Decryption status: $($result.DecryptionStatus)." } else { "" }
            Set-Status "LAPS data was found, but no readable password was returned.$detail" 'Warning'
        }
    }
    catch {
        $message = $_.Exception.Message

        if ($message -match 'cannot find|not found|does not exist|identity') {
            Set-Status "Computer '$computer' was not found, or no Windows LAPS data is available." 'Error'
        }
        elseif ($message -match 'access|denied|unauthorized|insufficient') {
            Set-Status "Access denied. Your account may not have permission to read this computer's LAPS password." 'Error'
        }
        else {
            Set-Status "Lookup failed: $message" 'Error'
        }
    }
    finally {
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
}

# ----- Events -----
$btnSearch.Add_Click({
    Search-LapsPassword
})

$btnReset.Add_Click({
    Reset-LapsForm
})

$txtComputer.Add_KeyDown({
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        $_.SuppressKeyPress = $true
        Search-LapsPassword
    }
})

$btnShow.Add_Click({
    if ($txtPassword.UseSystemPasswordChar) {
        $txtPassword.UseSystemPasswordChar = $false
        $btnShow.Text = "Hide"
    }
    else {
        $txtPassword.UseSystemPasswordChar = $true
        $btnShow.Text = "Show"
    }
})

$btnCopy.Add_Click({
    if (-not [string]::IsNullOrWhiteSpace($txtPassword.Text)) {
        try {
            [System.Windows.Forms.Clipboard]::SetText($txtPassword.Text)
            Set-Status "Password copied to the clipboard." 'Success'
        }
        catch {
            Set-Status "Unable to copy password to the clipboard: $($_.Exception.Message)" 'Error'
        }
    }
})

$btnExpire.Add_Click({
    $computer = $txtComputer.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($computer)) {
        return
    }

    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Expire the Windows LAPS password for $computer now?`r`n`r`nThis sets the AD expiration timestamp to the current time. The computer will generate a new password at its next Windows LAPS policy processing cycle.",
        "Expire LAPS password",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    Set-Status "Setting the LAPS password expiration time..." 'Normal'
    $form.Refresh()

    try {
        Set-LapsADPasswordExpirationTime -Identity $computer -ErrorAction Stop | Out-Null
        Set-Status "Password marked expired. The computer will rotate it at its next LAPS policy processing cycle." 'Success'
        $txtExpires.Text = "Expired / rotation requested"
    }
    catch {
        Set-Status "Unable to expire the password: $($_.Exception.Message)" 'Error'
    }
    finally {
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
})

$form.Add_Shown({
    $txtComputer.Focus()
})

[void]$form.ShowDialog()
