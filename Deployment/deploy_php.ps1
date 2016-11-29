#
# deploy_php.ps1
#
param(
[string] $WebsiteFolder="",
[string] $User="",
[string] $Password="",
[string] $Drive="V"
)
Try {
	"=========== Connecting to $WebsiteFolder ===================="
	Import-Module -Force -Name ((Split-Path $script:MyInvocation.MyCommand.Path)  + "\..\Modules\Utils.psm1")
	$Drive = MountRemotePath -RemotePath $WebsiteFolder -User $User -Password $Password 

	"=========== Mounting $WebsiteFolder into drive $Drive ============"

	"=========== Copying Files ===================="
	Copy-Item .\* ${Drive}:\  -Force -Recurse 
}
Finally {
	net use ${Drive}: /delete
}