param(
[Int32] $BuildNumber="1",
[string] $Configuration="AwsDev",
[string] $CWAPIFolder="",
[string] $CWTaskFolder="",
[string] $User="",
[string] $Password=""
)


"=========== Deploy CW.API =============="

Import-Module -force -Name ((Split-Path $script:MyInvocation.MyCommand.Path)  + "\..\Modules\Utils.psm1")
$Drive=MountRemotePath -RemotePath $CWAPIFolder -User $User -Password $Password 

Copy-Item .\CW.API\App_Data .\DeployPackages\$BuildNumber -recurse -force -Verbose
$buildInfoXML = "<?xml version='1.0' encoding='utf-16'?><BuildInfo><add key='BuildNumber' value='$BuildNumber' /></BuildInfo>"
Copy-Item .\DeployPackages\$BuildNumber\* ${Drive}:\  -force -recurse -Verbose
if ($LASTEXITCODE -gt 0)
{
	net use ${Drive}: /delete
	throw "error: Could not deploy CW.API to $CWAPIFolder"
}
$buildInfoXML | out-file -FilePath ${Drive}:\Config\BuildInfo.xml
net use ${Drive}: /delete



"=========== Deploy CW.Tasks =============="
$Drive=MountRemotePath -RemotePath $CWTaskFolder -User $User -Password $Password 

Copy-Item .\CW.Backend.Tasks\bin\$Configuration\*  ${Drive}:\  -force -recurse -Verbose
if ($LASTEXITCODE -gt 0)
{
	net use ${Drive}: /delete
	throw "error: Could not deploy Backend Jobs to $CWTaskFolder"
}
net use ${Drive}: /delete

