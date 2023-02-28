#!/usr/bin/env pwsh

# Define the parameters for the script
param (
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')]
    [string] [ipaddress]$ip_address_1,

    [Parameter(Mandatory=$true)]
    [ValidatePattern('^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')]
    [string] [ipaddress]$ip_address_2,

    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if ($_ -match '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$') {
            return $true
        } elseif ($_ -as [int] -ge 0 -and $_ -as [int] -le 32) {
            return $true
        } else {
            return $false
        }
    })]
    [string]$network_mask
)



# Define a function to check whether two IP addresses are in the same network
function Check-IPAddressesInSameNetwork {
    Param(
        $ip1 = [IPAddress]$args[0],
        $ip2 = [IPAddress]$args[1],
        $mask = [int]$args[2]
    )

    # Split the IP addresses and network mask into octets
    $ip1Octets = $ip1.Split(".")
    $ip2Octets = $ip2.Split(".")
    try {
        $maskOctets = if ($mask -match "^\d{1,2}$") { 
            # If the network mask is a number, calculate the subnet mask
            $SubnetMask = [System.Net.IPAddress]::Parse("255.255.255.255").Address -shr (32 - $network_mask)
            $SubnetMask = [System.Net.IPAddress]::Parse($SubnetMask)
            $SubnetMask.GetAddressBytes()
        } else { 
            # Otherwise, split the network mask into octets
            $mask.Split(".") 
        }
    } catch { 
        throw "Invalid network mask: $network_mask" 
    }

    # Compare the bits of each octet to see if the IP addresses belong to the same network
    for ($i = 0; $i -lt 4; $i++) {
        $ip1Octet = [int]$ip1Octets[$i]
        $ip2Octet = [int]$ip2Octets[$i]
        $maskOctet = [int]$maskOctets[$i]
        if (($ip1Octet -band $maskOctet) -ne ($ip2Octet -band $maskOctet)) {
            return $false 
        }
    }
    return $true
}

# Check whether the two IP addresses are in the same network
if (-not (Check-IPAddressesInSameNetwork $ip_address_1 $ip_address_2 $network_mask)) {
    # If they're not in the same network, output "no"
    Write-Output "no"
} else {
    Write-Output "yes"
}