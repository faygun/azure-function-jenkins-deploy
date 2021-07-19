Param (
	# Azure AD
	[Parameter(Mandatory=$true)]
    [string] $DeploymentServicePrincipalName,

	[Parameter(Mandatory=$true)]
    [string] $DeploymentServicePrincipalPassword,

	[Parameter(Mandatory=$true)]
    [string] $TenantId,

	[Parameter(Mandatory=$true)]
    [string] $WebAppName,

	[Parameter(Mandatory=$true)]
    [string] $ResourceGroupName,
	
	[Parameter(Mandatory=$true)]
    [string] $ArchiveFilePath
)

$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

#Install Az powershell module if it does not exist. This module is required to work with Azure resources
If(-not(Get-InstalledModule Az -ErrorAction silentlycontinue)){
    Install-Module -Name Az -Confirm:$False -Force
}

Import-Module -Name Az

function PublishAPIToAzure(){
	try{
		$webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName

		if($webapp){
			write-host "Stopping $WebAppName"
			Stop-AzWebApp -WebApp $webapp
			write-host "Publishing $WebAppName"
			Publish-AzWebApp -ArchivePath $ArchiveFilePath -WebApp $webapp  -Force
			write-host "Published $WebAppName"
			Start-AzWebApp -WebApp $webapp
			write-host "Started $WebAppName"
		}
		else{
			write-host "Azure Web app by the name $WebAppName not found"
		}
	}
	catch{
		Write-Warning $Error[0]
	}
	
}

function LoginToAzure(){


# Temporary fix to tunnel traffic towards HN proxy server
# Teamcity servers HNAP84 and HNAP85 are configured to hve free access to Azure so clear out the proxy before deploying as below
[System.Net.WebRequest]::DefaultWebProxy =
    [System.Net.GlobalProxySelection]::GetEmptyWebProxy()

$securedPassword = ConvertTo-SecureString $DeploymentServicePrincipalPassword -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($DeploymentServicePrincipalName , $securedPassword )

Connect-AzAccount -TenantId $TenantId -Credential $psCred -ServicePrincipal

PublishAPIToAzure
}

.\Retry-Command.ps1 -ScriptBlock { LoginToAzure }