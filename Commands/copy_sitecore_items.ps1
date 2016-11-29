#
# CopySitecoreItems.ps1
#
param(
		[string] $SrcURL,
		[string] $SrcFolder,
		[string] $SrcUser="",
		[string] $SrcPassword="",
		[string] $DstURL,
		[string] $DstFolder,
		[string] $DstUser="",
		[string] $DstPassword="",
		[string] $SmartPublish="true",
		[string] $ItemPaths="",
		[string] $Database="master"
	)


	Import-Module -force -Name ((Split-Path $script:MyInvocation.MyCommand.Path)  + "\..\Modules\Utils.psm1")
	CopySitecoreItems -SrcFolder "$SrcFolder" -SrcURL $SrcURL -SrcUser $SrcUser -SrcPassword $SrcPassword -DstURL $DstURL -DstFolder $DstFolder -DstUser $DstUser -DstPassword $DstPassword -ItemPaths $ItemPaths -Database $Database
