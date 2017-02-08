<#
.SYNOPSIS   
Script to add an AD User or group to the Local Administrator group
    
.DESCRIPTION 
The script can use either a plaintext file or a computer name as input and will add the trustee (user or group) as an administrator to the computer
	
.PARAMETER InputFile
A path that contains a plaintext file with computer names

.PARAMETER Computer
This parameter can be used instead of the InputFile parameter to specify a single computer or a series of
computers using a comma-separated format
	
.PARAMETER Trustee
The SamAccount name of an AD User or AD Group that is to be added to the Local Administrators group

.NOTES   
Name: Set-ADAccountasLocalAdministrator.ps1
Author: Jaap Brasser
Version: 1.1.1
DateCreated: 2012-09-06
DateUpdated: 2015-11-12
Fork: Romain Zanon
DateUpdated: 2017-08-02
Fork comment: script adapted for french OS versions of Microsoft Windows

.LINK
http://www.jaapbrasser.com

.EXAMPLE   
.\set-localAdminAccount.ps1 -Computer Server01 -Trustee JaapBrasser

Description:
Will set the the JaapBrasser account as a Local Administrator on Server01

.EXAMPLE   
.\set-localAdminAccount.ps1 -Computer 'Server01,Server02' -Trustee Contoso\HRManagers

Description:
Will set the HRManagers group in the contoso domain as Local Administrators on Server01 and Server02

.EXAMPLE   
.\set-localAdminAccount.ps1 -InputFile C:\ListofComputers.txt -Trustee User01

Description:
Will set the User01 account as a Local Administrator on all servers and computernames listed in the ListofComputers file
#>
param(
    [Parameter(ParameterSetName='InputFile')]
    [string]
        $InputFile,
    [Parameter(ParameterSetName='Computer')]
    [string]
        $Computer,
    [string]
        $Trustee
)
<#
.SYNOPSIS
    Function that resolves SAMAccount and can exit script if resolution fails
#>
function Resolve-SamAccount {
param(
    [string]
        $SamAccount,
    [boolean]
        $Exit
)
    process {
        try
        {
            $ADResolve = ([adsisearcher]"(samaccountname=$Trustee)").findone().properties['samaccountname']
        }
        catch
        {
            $ADResolve = $null
        }

        if (!$ADResolve) {
            Write-Warning "User `'$SamAccount`' not found in AD, please input correct SAM Account"
            if ($Exit) {
                exit
            }
        }
        $ADResolve
    }
}

if (!$Trustee) {
    $Trustee = Read-Host "Please input trustee"
}

if ($Trustee -notmatch '\\') {
    $ADResolved = (Resolve-SamAccount -SamAccount $Trustee -Exit:$true)
    $Trustee = 'WinNT://',"$env:userdomain",'/',$ADResolved -join ''
} else {
    $ADResolved = ($Trustee -split '\\')[1]
    $DomainResolved = ($Trustee -split '\\')[0]
    $Trustee = 'WinNT://',$DomainResolved,'/',$ADResolved -join ''
}

if (!$InputFile) {
	if (!$Computer) {
		$Computer = Read-Host "Please input computer name"
	}
	[string[]]$Computer = $Computer.Split(',')
	$Computer | ForEach-Object {
		$_
		Write-Host "Adding `'$ADResolved`' to Administrators group on `'$_`'"
		try {
			([ADSI]"WinNT://$_/Administrateurs,group").add($Trustee)
			Write-Host -ForegroundColor Green "Successfully completed command for `'$ADResolved`' on `'$_`'"
		} catch {
			Write-Warning "$_"
		}	
	}
}
else {
	if (!(Test-Path -Path $InputFile)) {
		Write-Warning "Input file not found, please enter correct path"
		exit
	}
	Get-Content -Path $InputFile | ForEach-Object {
		Write-Host "Adding `'$ADResolved`' to Administrators group on `'$_`'"
		try {
			([ADSI]"WinNT://$_/Administrateurs,group").add($Trustee)
			Write-Host -ForegroundColor Green "Successfully completed command"
		} catch {
			Write-Warning "$_"
		}        
	}
}
# SIG # Begin signature block
# MIIG/gYJKoZIhvcNAQcCoIIG7zCCBusCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXofoKdWbcNBV2djdwyRW2f/n
# H4qgggQfMIIEGzCCAwOgAwIBAgIJAPTErmNzNhkZMA0GCSqGSIb3DQEBCwUAMIGZ
# MQswCQYDVQQGEwJOQzEVMBMGA1UECAwMUHJvdmluY2UgU3VkMQ8wDQYDVQQHDAZO
# b3VtZWExDzANBgNVBAoMBkxlQ3ViZTEaMBgGA1UECwwRSVQgaW5mcmFzdHJ1Y3R1
# cmUxEjAQBgNVBAMMCWxlY3ViZS5uYzEhMB8GCSqGSIb3DQEJARYSb3N0aWNrZXQu
# bGVjdWJlLm5jMB4XDTE2MTIwNjIyMzEwMVoXDTE3MTIwNjIyMzEwMVowgYExCzAJ
# BgNVBAYTAk5DMRUwEwYDVQQIDAxQcm92aW5jZSBTdWQxDzANBgNVBAcMBk5vdW1l
# YTEPMA0GA1UECgwGTGVDdWJlMRYwFAYDVQQLDA1JVCBPcGVyYXRpb25zMSEwHwYD
# VQQDDBhDb2RlIFNpZ25pbmcgQ2VydGlmaWNhdGUwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQDNOHE8TJdS7FDyONLNKXHor8jrV84Ytcs3i/m5qrWi8IhH
# cEIwWfjzMFCrP7RzFZizZL6hcOqpe1DaKONCbx4fKsCjGZ8vvgouOJ56y6v11sEG
# qBDRYud39kpEWETm79TQdX8xX01S6uJo0fYNHVkB/X6Lry2UA92YijVMIh1ZFnh7
# TdmsiayuDGSxkl8Uitm7aFi9b6b7jF+PHeWcLZuFg+q43uVVq2qKIPaoyRxVaGKW
# +gqxtrGG6simxXHhHzgSwVYC7NlCPblgKagZShmohR0qZYe5SU5F6nYK/9mUdJeK
# VYx9fhVXRrgUKpMDn6lJKNA0pNcjxiWcg4sMhZrrAgMBAAGjfDB6MB0GA1UdDgQW
# BBQMbtdc4GCdECJCYxqt8qwpKRXb5zAJBgNVHRMEAjAAMAsGA1UdDwQEAwIE8DAu
# BgNVHSUBAf8EJDAiBggrBgEFBQcDAwYKKwYBBAGCNwIBFQYKKwYBBAGCNwIBFjAR
# BglghkgBhvhCAQEEBAMCBBAwDQYJKoZIhvcNAQELBQADggEBADjEvzqEUyo1O6ve
# CyP37IK/3WJGrWLnNVQu61WoAWlAo63iTsgUWCqOuIHDw6dQPkPtx8NPx/i0WO2L
# 3iRA7XAZD673Fd8kt0B9jlhOTxCvp/he5cQiuQbn2F9ElaW5MJsjRAajJZrgy2JD
# rGsj1JJzwYmfKgaOPAIrbfi+uFFZG4/XnwCOSwMPaK44C5E+qdRcFH8OtPJGL5A9
# aozeqxrXCXk4A03fytnn8cWI/itMzFKEgyoCI7gKn3OG5uFQtChWeF6XwCiLNOcB
# JcPiZeRbcDLaG4p/KZOlITtLK6I8uW/ktqWrlyekhbUAaFtglG/XmrT5seco7Rrq
# u2hr4uExggJJMIICRQIBATCBpzCBmTELMAkGA1UEBhMCTkMxFTATBgNVBAgMDFBy
# b3ZpbmNlIFN1ZDEPMA0GA1UEBwwGTm91bWVhMQ8wDQYDVQQKDAZMZUN1YmUxGjAY
# BgNVBAsMEUlUIGluZnJhc3RydWN0dXJlMRIwEAYDVQQDDAlsZWN1YmUubmMxITAf
# BgkqhkiG9w0BCQEWEm9zdGlja2V0LmxlY3ViZS5uYwIJAPTErmNzNhkZMAkGBSsO
# AwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEWMCMGCSqG
# SIb3DQEJBDEWBBTyPHrZCQoaZOxgNpq8KHrVkiVRDDANBgkqhkiG9w0BAQEFAASC
# AQCJs9/LC3jQMxFoaOP9qkgo3GVXI1/gAwZOcBoUcAiUdyr4vfdRxRKIuQgd8Duy
# SSmxczs3vle9AbnCq7ZAhsLVmpOr/H/rvcnCjd22bHkR+VINeNd3QWWVR3iNN/4p
# aqaa6gsSDDZSVJpgNRf6wgbZhXSSz3qbOZYMMRRsOPBjSaG0UnpPo/W/SWUh0Dzj
# wZxIq0YgBVIfvv5ZH2SVatEZhtUOVMqmjzg+6mCjELAMtxthz4PcKUoU0z7JMWLQ
# ZjoBH+ybps6nkcE0X1BeHkAk/BHk2aLlloxxfGahlzxAY+zzE2t4dYzUnflRsnsz
# YWf++QP4EIr2KDLFxi6mW3FF
# SIG # End signature block
