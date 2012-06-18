<#
	SYNOPSIS
		A script to inventory the local computer and store information in an xml
		file
	DESCRIPTION
		This script will collect the following system information: hostname, 
		manufacturer model, bios version, smbios number, serial number, 
		processor name, number of physical processors, number of logical 
		processors, number of cores, cpu DeviceID, Disk Volume names, Drive Letters, 
		size and free space available, size of memory, free memory, network adapters 
		public and private	IP 	Addresses, mac addresses and subnets, and OS Name 
		and service pack, Local users and members of the local admin group
		
		Output will be stored in an XML file named <hostname>.xml
	PARAMETER ComputerName
		The name or IP Address of a remote system
	PARAMETER FilePath
		The path to store the output xml. The default path is C:\temp
	EXAMPLE
		.\Get-SysInfo.ps1 -ComputerName server01
		Description
		-----------
		This will invoke the SysInfo.ps1 script on server01 and save output to 
		C:\temp\server01.xml
	NOTES
		ScriptName	:	Get-SysInfo.ps1
		Created By	:	Michael Lecuona
		Date Coded	:	5/4/2012
		Last Rev	:	5/22/2012
		
#>
Param(
	$ComputerName = '.',
	$FilePath = 'C:\temp'
	)
Process {


function Get-ComputerSystem {
param (
	[string]$ComputerName = $(throw "ComputerName required")
	)
$ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName
$ComputerSystem	
}

function Get-Platform {	
	
	param(
		[string]$ComputerName = $(throw "ComputerName needed."),
		[Object]$ComputerSystem = $(throw "ComputerSystem needed.")
		)
		
	$BIOS = Get-WmiObject -Class Win32_BIOS -ComputerName $ComputerName
	
	$Platform = New-Object PSObject -Property @{"manufacturer" = $ComputerSystem.Manufacturer ; "model" = $ComputerSystem.Model ; "biosversion" = $BIOS.BIOSVersion; "smbiosversion" = $BIOS.SMBIOSBIOSVersion ; "serialnumber" = $BIOS.SerialNumber}
	$Platform
}
	
function Write-PlatformXML {

	param(
		[Object]$Platform = $(throw "Platform needed."),
		[xml]$xmlDoc = $(throw "xmlDoc required.")
	)
	
	$platformXML = $xmlDoc.CreateElement("platform")
	

	[void]$platformXML.SetAttribute("manufacturer",$platform.manufacturer)
	[void]$platformXML.SetAttribute("model",$platform.model)
	[void]$platformXML.SetAttribute("biosversion",$platform.biosversion)
	[void]$platformXML.SetAttribute("smbiosversion",$platform.smbiosversion)
	[void]$platformXML.SetAttribute("serialnumber",$platform.serialNumber)
	
	[void]$xml.AppendChild($platformXML)
}

function Get-Processor{
	param(
		[string]$ComputerName = $(throw "ComputerName required.")
	)
	
	
	$Processor = Get-WmiObject -Class Win32_Processor -ComputerName $ComputerName
	$Processor
		
}

function Write-ProcessorXML {

param (
	[string]$ComputerName = $(throw "ComputerName required."),
	[object]$ComputerSystem = $(throw "ComputerSystem required."),
	[xml]$xmlDoc = $(throw "xmlDoc required."),
	[Object]$Processor = $(throw "Processor required.")
	)	
		

		
		ForEach ($p in $Processor){
		$processorXML = $xmlDoc.CreateElement("processor")	
		[void]$processorXML.SetAttribute("name",$p.Name)
		[void]$processorXML.SetAttribute("countphysical",$ComputerSystem.NumberOfProcessors)
		[void]$processorXML.SetAttribute("countlogical",$ComputerSystem.NumberOfLogicalProcessors)
		[void]$processorXML.SetAttribute("countcores",$p.NumberOfCores)
		[void]$processorXML.SetAttribute("deviceid",$p.DeviceID)
	
		[void]$xml.AppendChild($processorXML)
		
		}
		
}

function Get-Memory{
	param(
	[string]$ComputerName = $(throw "ComputerName required.")
	)
#Capture Memory size and available
	$memorySize = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName | Select-Object -ExpandProperty TotalVisibleMemorySize
	$memoryAvailable = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName | Select-Object -ExpandProperty FreePhysicalMemory
	$memoryMods = (Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $ComputerName).Count
	$Memory = New-Object PSObject -Property @{"size" = $memorySize;"available" = $memoryAvailable;"count"=$memoryMods}
	$Memory
}	

function Write-MemoryXML{

param(
	[xml]$xmlDoc = $(throw "xmlDoc required."),
	[object]$Memory = $(throw "Memory required.")
	)

	$memoryXML = $xmlDoc.CreateElement("memory")
	
	[void]$memoryXML.SetAttribute("size",$Memory.size)
	[void]$memoryXML.SetAttribute("available",$Memory.Available)
	[Void]$memoryXML.SetAttribute("count",$Memory.count)
	
	
	[void]$xml.AppendChild($memoryXML)
	
}

function Get-OS {
param(
	[string]$ComputerName = $(throw "ComputerName required.")
	)

#Capture Operating System Name and Service Pack Major Version:
	$OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName
	$OS
}	
	
function Write-OsXML {

param(
	[xml]$xmlDoc = $(throw "xmlDoc required."),
	[object]$OS = $(throw "OS required.")
	)


	$osXML = $xmlDoc.CreateElement("os")

	[void]$osXML.SetAttribute("name",$OS.Caption)
	[void]$osXML.SetAttribute("servicepack",$OS.ServicePackMajorVersion)
	
	[void]$xml.AppendChild($osXML)
	
}	
	

function Get-NICs {
	param(
	[string]$ComputerName = $(throw "ComputerName required.")
	)
	$NIC = Get-WmiObject -query "SELECT * FROM Win32_NetworkAdapter WHERE AdapterType = 'Ethernet 802.3'" -computername $ComputerName
	$NIC
	
}

function Write-NicXML {
	param(
	[string]$ComputerName = $(throw "ComputerName required."),
	[xml]$xmlDoc = $(throw "xmlDoc required."),
	[object]$NIC = $(throw "NIC required."),
	[array]$filteredNics = @()
	)
				
	Foreach ($n in $NIC) {
	
		$nicName = $n.Name
		
		if ($filteredNICs -notcontains $nicName){
		$nicID = $n.DeviceID
		$nicIP = Get-WmiObject -query "Select IPAddress FROM Win32_NetworkAdapterConfiguration WHERE Index = $($nicID)" -computername $ComputerName
		if ($nicIP.IPAddress -ne $null){
		$nicPrivateIP = Get-WmiObject -query "Select IPAddress FROM Win32_NetworkAdapterConfiguration WHERE Index = $($nicID)" -computername $ComputerName| Select -Expand IPAddress | WHERE {$_ -notlike '*:*'}
		$nicSubnet = Get-WmiObject -query "Select IPSubnet FROM Win32_NetworkAdapterConfiguration WHERE Index = $($nicID)" -computername $ComputerName | Select -Expand IPSubnet | WHERE {$_ -like '*.*'}
		$nicPublicIP = [System.Net.Dns]::GetHostAddresses($serverName) -like "*.*" | WHERE {$_ -notlike '192.168.*'} | WHERE {$_ -notlike '10.*'}
		$nicDnsName = [System.Net.Dns]::GetHostByAddress($nicPublicIP).HostName
		$nicMAC = $n.MACAddress

		$nicXML = $xmlDoc.CreateElement("net")

		[void]$nicXML.SetAttribute("name",$nicName)
		[Void]$nicXML.SetAttribute("dnsname",$nicDnsName)
		[void]$nicXML.SetAttribute("privateIP",$nicPrivateIP)
		[void]$nicXML.SetAttribute("subnet",$nicSubnet)
		[void]$nicXML.SetAttribute("publicIP",$nicPublicIP)
		[void]$nicXML.SetAttribute("MACaddress",$nicMAC)
		
		[void]$xml.AppendChild($nicXML)
		}
		}
	}
}


function Get-Disks {

# Function returns an object containing the wmi disk info
# Requires a computername to be passed

param(
[string]$ComputerName = $(throw "ComputerName required.")
)
$Disk = Get-WmiObject -query "SELECT * FROM win32_LogicalDisk " -computername $ComputerName
$Disk
}

function Write-DiskXML{

# This function requires an xml object and an array of hashtables containing the wmi disk info

param(
[xml]$xmlDoc = $(throw "xmlDoc required."),
[object]$disk = $(throw "disk required.")
)
# Creates the Disk portion of supplied xml object


ForEach ($d in $disk){


	$diskXML = $xmlDoc.CreateElement("disk")
	
	ForEach ($dp in $d.Properties){
		[void]$diskXML.SetAttribute($dp.name,$dp.Value)
		}
	
	[void]$xml.AppendChild($diskXML)
	}

}

Function Get-Users {
	param(
	[string]$ComputerName = $(throw "ComputerName required.")
	)
	
	
	$Users = Get-WmiObject -Query "SELECT Name,PasswordExpires,PasswordChangeable,Disabled,SID,LocalAccount FROM Win32_UserAccount WHERE LocalAccount = TRUE" -ComputerName $ComputerName
	# To speed up script, the above command was used in place of the one below, which captures all user information.
	#$Users = Get-WmiObject -Class Win32_UserAccount -ComputerName $ComputerName

	$Users

}

Function Write-UsersXML {	

param(
[xml]$xmlDoc = $(throw "xmlDoc required."),
[object]$Users = $(throw "Users required.")
)
	
	
	
	foreach ($u in $Users) {
		
		if ($u.LocalAccount -eq $true){
		
		$userXML = $xmlDoc.CreateElement("localuser")
	
		foreach ($up in $u.Properties) {
			
			[Void]$userXML.SetAttribute($up.name,$up.value)
		
		}
		[void]$xml.AppendChild($userXML)
	}
}

}

function Get-AdminMember {
param($ComputerName = $(throw "ComputerName required"))

$memberOut = @()
$groups = Get-WmiObject -Query "SELECT * FROM Win32_Group WHERE LocalAccount = TRUE" -ComputerName $ComputerName
foreach ($g in $groups){
	If ($g.Name -eq "Administrators"){
		$group =[ADSI]"WinNT://$($g.Domain)/$($g.Name)" 
		$members = @($group.psbase.Invoke("Members")) 

		foreach ($member in $members){
			
			$memtoken = ($member.GetType().InvokeMember("AdsPath", 'GetProperty', $null, $member, $null)).Split("/")
			if ($memtoken[($memtoken.Count)-2] -ne "NT AUTHORITY"){
			$memberOut += ($memtoken[($memtoken.Count)-2] + "\" + $memtoken[($memtoken.Count)-1])
			
}
		} 
	}
}
$memhash = @{"Name" = $memberOut}

$AdminMember = New-Object PSObject -Property $memhash
$AdminMember
}

Function Write-AdminMemberXML {	

param(
[xml]$xmlDoc = $(throw "xmlDoc required."),
[object]$AdminMember = $(throw "AdminMember required.")
)
	

	
	foreach ($am in $AdminMember) {
		
		
		foreach ($amp in $am.Name){
		$AdminMemberXML = $xmlDoc.CreateElement("adminmember")
		[Void]$AdminMemberXML.SetAttribute("Name",$amp)
		[void]$xml.AppendChild($AdminMemberXML)
		}
	}

}


clear

IF ((Test-Path $FilePath) -ne $true) {
Write-Host "Creating $($FilePath)"
New-Item $FilePath -ItemType Directory -Force
}

try {
	#Write-Host "1"
	$filteredNICs = @()
	$filteredNics += "VirtualBox Bridged Networking Driver Miniport"
	$ServerName = (Get-ComputerSystem -ComputerName $ComputerName).Name
	#Create XML out
	$xmlDoc = New-Object xml
	
	$serverXML = "<?xml version=`"1.0`" encoding=`"utf-8`"?><server name=`"$($serverName)`"></server>"
	$xmlDoc.LoadXml($serverXML)
	
	$xml = $xmlDoc.SelectSingleNode("/server")
	
	$filteredNics += "VirtualBox Bridged Networking Driver Miniport"
	
	
	Write-PlatformXML -Platform (Get-Platform -ComputerName $ComputerName -ComputerSystem (Get-ComputerSystem -ComputerName $ComputerName)) -xmlDoc $xmlDoc
	Write-ProcessorXML -ComputerName $ComputerName -ComputerSystem (Get-ComputerSystem -ComputerName $ComputerName) -Processor (Get-Processor -ComputerName $ComputerName) -xmlDoc $xmlDoc
	Write-MemoryXML -Memory (Get-Memory -ComputerName $ComputerName) -xmlDoc $xmlDoc
	Write-OsXML -OS (Get-OS -ComputerName $ComputerName) -xmlDoc $xmlDoc
	Write-NicXML -filteredNics $filteredNICs -xmlDoc $xmlDoc -NIC (Get-NICs -ComputerName $ComputerName) -ComputerName $ComputerName
	Write-DiskXML -disk (Get-Disks -ComputerName $ComputerName) -xmlDoc $xmlDoc
	Write-UsersXML -Users (Get-Users -ComputerName $ComputerName) -xmlDoc $xmlDoc
	Write-AdminMemberXML -AdminMember (Get-AdminMember -ComputerName $ComputerName) -xmlDoc $xmlDoc
	$xmlDoc.Save("$($FilePath)\$($serverName).xml")
	Write-Host "$($FilePath)\$($serverName).xml has been written."




}

catch {
                $Message = $Error[0]
                Write-Host $Message

}

}