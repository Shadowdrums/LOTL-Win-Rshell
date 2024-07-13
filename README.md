# PowerShell Remote Control Script 🚀

This PowerShell script allows for remote control capabilities, including running commands on a remote machine via TCP. It includes functions for encryption, setting execution policies, and running as either a server or client. Additionally, it provides options for adding the script to startup and running it in the background.

---

## Features 🌟

- **Device Information Retrieval** 📋: Retrieves and displays information about the device, including device name, user name, private IP, public IP, and network name.
- **Menu Interface** 📜: User-friendly menu interface for selecting options to run as a server, run as a client, set execution policy, and exit.
- **Data Encryption** 🔒: Utilizes triple hex encoding, triple base64 encoding, and binary encoding for data encryption and decryption.
- **Server and Client Functionality** 🌐: Supports running as a server to accept connections and execute commands or as a client to connect to a remote server and send commands.
- **Script Cloning and Startup Addition** 🔄: Clones the script, adds it to startup, and runs it in the background for persistent remote control.

---

## Requirements 🛠️

- Windows PowerShell
- .NET Framework 4.5 or higher
- Administrative privileges (for adding to startup)

---

## Installation 📝

1. **Clone the Repository** 📂: Download or clone this repository to your local machine.
2. **Prepare the Script** ⚙️: Ensure that the `PWN.ps1` script is placed in the desired location.
3. **Run the Batch File** 🖱️: Use the provided `.bat` file to run the script.

---

## Usage 💡

1. **Launch the Script** 🚀: Run the script using PowerShell or the provided batch file.
2. **Display Menu** 📜: The script will display a menu with the following options:
    - `1. Run as Server`
    - `2. Run as Client`
    - `3. Exit`
    - `4. Set Execution Policy`
3. **Choose an Option** 🎛️: Enter the number corresponding to your choice and follow the prompts.

---

## Functions 📚

### Get-DeviceInformation 📋

Retrieves device information including device name, user name, private IP, public IP, and network name.

### Display-Menu 📜

Displays the main menu with options for running as a server, running as a client, setting execution policy, and exiting.

### Set-ExecutionPolicy ⚙️

Sets the execution policy for the current user scope.

### ConvertTo-Hex 🔢

Converts byte data to a hexadecimal string.

### ConvertFrom-Hex 🔄

Converts a hexadecimal string to byte data.

### TripleHexEncode 🔒

Performs triple hex encoding on byte data.

### TripleHexDecode 🔓

Performs triple hex decoding on byte data.

### TripleBase64Encode 🔒

Performs triple base64 encoding on byte data.

### TripleBase64Decode 🔓

Performs triple base64 decoding on byte data.

### BinaryEncode 🔢

Encodes byte data using binary encoding.

### BinaryDecode 🔄

Decodes byte data using binary encoding.

### Encrypt-Data 🔒

Encrypts data using a combination of triple hex encoding, triple base64 encoding, and binary encoding.

### Decrypt-Data 🔓

Decrypts data using a combination of binary decoding, triple hex decoding, and triple base64 decoding.

### Run-Server 🌐

Starts the server on the specified port, accepts connections, and executes commands received from clients.

### Run-Client 🌐

Connects to the server at the specified IP and port, sends commands, and displays responses.

### Clone-Script 📝

Clones the script to the specified file path.

### Add-To-Startup 🔄

Adds the script to startup using a scheduled task.

### Run-In-Background 🛠️

Runs the script in the background.

---

## Example 📘

```powershell
# Example usage to run as a server on port 8080
$port = 8080
Run-Server -Port $port
```

### Batch File (.bat) 🖱️
A batch file is provided to run the PowerShell script. The script content is encrypted within the batch file for security purposes. To use the batch file, simply execute it, and it will run the PowerShell script.
```
@echo off
powershell.exe -ExecutionPolicy Bypass -File "path\to\your\PWN.ps1"
```

### Security Notice ⚠️
This script is intended for educational purposes only. Ensure you have permission to run this script on any remote systems and that you understand the potential risks and implications of remote control software.

### License 📄
- This project is licensed under the MIT License.

### Additional Information ℹ️
- Environment Variables 🌍: Utilizes environment variables to retrieve device and user information.
- Error Handling ❗: Includes error handling to manage and report issues during command execution.
- User Prompts 💬: Provides clear prompts for user input to ensure ease of use.
