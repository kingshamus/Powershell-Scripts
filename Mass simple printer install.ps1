#Script below will add each printer listed as a IPP printer, easy to install when dealing with a large number of printers without having access to Entra/Intune, simply replace exampleMFPs with actual MFPnames and IPAddresses, extra printers can be added by adding the following line between the 2 existing printers "  @{ Hostname = "exampleMFP"; IP = "<0.0.0.0>" },  "

# List of printer hostnames and optional manual IP overrides
$printers = @(
    @{ Hostname = "exampleMFP"; IP = "<0.0.0.0>" },
    @{ Hostname = "example2MFP"; IP = "<0.0.0.1>" }
)

# Driver name for Microsoft IPP
$driverName = "Microsoft IPP Class Driver"

# Loop through each printer
foreach ($printer in $printers) {
    $hostname = $printer.Hostname
    $manualIP = $printer.IP
    try {
        # Initialize IP address
        $ipAddress = $null

        # Use manual IP if provided, otherwise ping to resolve IP
        if ($manualIP) {
            Write-Host "Using provided IP for ${hostname}: $manualIP"
            $ipAddress = $manualIP
        }
        else {
            Write-Host "Pinging $hostname to retrieve IPv4 address..."
            $pingResult = Test-Connection -ComputerName $hostname -Count 2 -ErrorAction Stop
            if (-not $pingResult) {
                Write-Host "Printer $hostname is unreachable. Skipping installation."
                continue
            }
            $ipAddress = $pingResult[0].IPv4Address.IPAddressToString
            Write-Host "Resolved $hostname to IPv4 address: $ipAddress"
        }

        # Check if the printer already exists
        if (Get-Printer -Name $hostname -ErrorAction SilentlyContinue) {
            Write-Host "Printer $hostname already exists. Skipping installation."
            continue
        }

        # Construct IPP URL using IP address
        $ippUrl = "ipp://$ipAddress/ipp/print"

        # Create a printer port using the IP address
        $portName = "IP_$ipAddress"
        if (-not (Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue)) {
            Add-PrinterPort -Name $portName -PrinterHostAddress $ipAddress -ErrorAction Stop
            Write-Host "Created printer port: $portName"
        }

        # Add the printer
        Add-Printer -Name $hostname -DriverName $driverName -PortName $portName -ErrorAction Stop
        Write-Host "Successfully installed printer: $hostname with IP $ipAddress"
    }
    catch {
        Write-Host "Failed to install printer: $hostname. Error: $_"
    }
}

# Verify installed printers
Write-Host "`nInstalled Printers:"
Get-Printer | Where-Object { $printers.Hostname -contains $_.Name } | Select-Object Name, DriverName, PortName
