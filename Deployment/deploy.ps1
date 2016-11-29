param(
[Int32]$BuildNumber="1",
[string] $Configuration="AwsDev"
)

Copy-Item .\CW.API\App_Data .\DeployPackages\$BuildNumber -recurse -force -Verbose

$buildInfoXML = "<?xml version='1.0' encoding='utf-16'?><BuildInfo><add key='BuildNumber' value='$BuildNumber' /></BuildInfo>"





new-psdrive -name Y -psProvider FileSystem -root '//10.0.1.9/D$/Repositories/devcwapi.com'
Remove-Item Y:\* -Force -recurse
Copy-Item .\DeployPackages\$BuildNumber\* Y:\  -force -recurse -Verbose
if ($LASTEXITCODE -gt 0)
{
	throw "error: Could not deploy CW.API to devcwapi.com"
}
$buildInfoXML | out-file -FilePath Y:\Config\BuildInfo.xml
remove-psdrive -name Y 

"=========== Deploy CW.Tasks =============="

new-psdrive -name Y -psProvider FileSystem -root '//10.0.1.9/D$/Repositories'
New-Item -Type dir Y:\CW.Tasks
Copy-Item .\CW.Backend.Tasks\bin\$Configuration\*  Y:\CW.Tasks\  -force -recurse -Verbose
if ($LASTEXITCODE -gt 0)
{
	throw "error: Could not deploy Backend Jobs to CW.Tasks"
}
remove-psdrive -name Y 