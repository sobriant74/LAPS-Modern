# LAPS-Modern

A simple GUI for retrieving native Windows LAPS passwords from
on-premises Active Directory.

Designed as a lightweight replacement for the legacy Microsoft LAPS UI.

## Features

- Search by computer name
- Display the managed local administrator account
- Retrieve the current Windows LAPS password
- Show/hide password
- Copy password to clipboard
- Display password update and expiration times
- Expire the current password to request rotation

## Requirements

- Windows
- Windows PowerShell 5.1 or later
- Microsoft Windows LAPS PowerShell module
- Active Directory connectivity
- Appropriate permissions to retrieve Windows LAPS passwords

The application uses the permissions of the currently logged-in user.
It does not store credentials or bypass Active Directory permissions.

## Usage

Run:

```powershell
.\Windows-LAPS-Helpdesk.ps1

Or launch with:

powershell.exe -ExecutionPolicy Bypass -File .\Windows-LAPS-Helpdesk.ps1
Required LAPS command

The computer running the tool must have:

Get-LapsADPassword

available.

Security

This tool does not contain or store administrator credentials.

Password access is controlled entirely by your existing Windows LAPS
Active Directory permissions.
