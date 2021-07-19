
Param (
	[Parameter(Mandatory=$true)]
    [string] $PublishFolder,

	[Parameter(Mandatory=$true)]
    [string] $Destination
)

$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot

function ArchiveBinaries(){

	# Check if publish path exists
	if(Test-path $PublishFolder)
	{
		if(Test-path $Destination) {
			Remove-item $Destination
		}

		$parentDestinationFolder = Split-Path -Path $Destination

		if(-not (Test-path $parentDestinationFolder)){
			New-Item -Path $parentDestinationFolder -ItemType Directory
		}

		Add-Type -assembly "system.io.compression.filesystem"
		write-host "Compressing contents from $PublishFolder into $Destination"
		[io.compression.zipfile]::CreateFromDirectory($PublishFolder, $Destination)
	}
	else
	{
	 write-host "publish folder not found at $publishFolder"
	}
}

ArchiveBinaries
