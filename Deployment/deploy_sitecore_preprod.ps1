param(
[Int32]$BuildNumber="1",
[string]$Configuration="AwsDev",
[string]$WebSiteFolder="//10.0.1.9/D$/Repositories/DevNeoWebsite",
[string]$WebURL="\\10.0.1.9\D$\Repositories\DevNeoWebsite",
[string]$Changeset="0",
[string]$Workspace="",
[string]$InstallCoreContent="False",
[string]$User="",
[string]$Password=""
)

Import-Module -force -Name ((Split-Path $script:MyInvocation.MyCommand.Path)  + "\..\Modules\Utils.psm1")
$buildInfoXML = "<?xml version='1.0' encoding='utf-16'?><BuildInfo><add key='BuildNumber' value='$Changeset'/><add key='BuildNumber' value='$BuildNumber' /></BuildInfo>"
$env:Path=$env:Path+";C:\Program Files (x86)\MSBuild\14.0\Bin"


$Drive=MountRemotePath -RemotePath $WebSiteFolder -User $User -Password $Password 


if ($LASTEXITCODE -gt 0)
{
	throw "Could not connect to $WebSiteFolder"
}

" ======== Drive $Drive mounted successfully for $WebSiteFolder ======="


$buildInfoXML | out-file -FilePath ${Drive}:\App_Config\BuildInfo.xml


" ======== Publish CW.CorporateSites ======="
$publishFile=@"
<?xml version="1.0" encoding="utf-16"?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <WebPublishMethod>FileSystem</WebPublishMethod>
    <LastUsedBuildConfiguration>$Configuration</LastUsedBuildConfiguration>
    <LastUsedPlatform>Any CPU</LastUsedPlatform>
    <SiteUrlToLaunchAfterPublish />
    <LaunchSiteAfterPublish>True</LaunchSiteAfterPublish>
    <ExcludeApp_Data>False</ExcludeApp_Data>
    <publishUrl>${Drive}:\.</publishUrl>
    <DeleteExistingFiles>False</DeleteExistingFiles>
  </PropertyGroup>
</Project>
"@
$publishFile | out-file -FilePath c:\temp\publishFile.pubxml
cd .\Projects\CWSC02\CWSC02
msbuild .\CW.CorporateSites.csproj /property:Configuration="$Configuration" /p:DeployOnBuild=true /p:PublishProfile="c:\temp\publishFile.pubxml"

if ($LASTEXITCODE -gt 0)
{
net use ${Drive}: /delete
throw "Error: CW.CorporateSites deployment returned errors"
}
" ======== Copying Files to Website ========"
copy-item .\obj\$Configuration\Package\PackageTmp\* ${Drive}:\ -verbose -recurse -force

" ======== Syncing TDS Core ========"
if ($InstallCoreContent -eq "True")
{
cd ..\CW.CoreItems

msbuild .\CW.CoreItems.scproj /p:SourceWebPhysicalPath="" /p:SourceWebProject="" /p:SitecoreAccessGuid="7ef8d4e8-ab80-4854-9da0-1cfc926cbc8b"  /p:SourceWebPhysicalPath="" /property:Configuration="$Configuration" /property:Platform='Any CPU' /property:OutputPath='.\bin\Deploy' /property:SitecoreWebUrl="$WebURL" /property:SitecoreDeployFolder="${Drive}:\.\" /property:InstallSitecoreConnector=True  /property:RecursiveDeployAction=Ignore /property:DisableFileDeployment=True
$code = $LASTEXITCODE
if ($code -gt 0)
{
net use ${Drive}: /delete 
throw "Error: MSBuild returned errors. $code"
}
}
else{
" ======== Skip TDS Core Installation========"
}

" ======== Syncing TDS Master ========"
cd ..\CW.Master
msbuild .\CW.Master.scproj /p:SourceWebPhysicalPath="" /p:SourceWebProject=""  /p:SourceWebPhysicalPath="" /property:Configuration="$Configuration" /property:Platform='Any CPU' /property:OutputPath='.\bin\Deploy' /property:SitecoreWebUrl="$WebURL" /property:SitecoreDeployFolder="${Drive}:\.\" /property:InstallSitecoreConnector=True  /property:RecursiveDeployAction=Ignore /property:DisableFileDeployment=True
$code = $LASTEXITCODE
if ($code -gt 0)
{
net use ${Drive}: /delete
throw "Error: MSBuild returned errors. $code"
}





#cd .\CW.Master\bin\Deploy\_PublishedWebsites\CW.Master
#cp .\* ${Drive}:\ -force -recurse
net use ${Drive}: /delete

#/property:Configuration=GatedCheckIn /property:Platform='Any CPU'  /property:OutputPath='.\bin\GatedCheckIn' /property:SitecoreWebUrl='http://neo.qa.connectwise.com' /property:SitecoreDeployFolder='Y:\' /property:InstallSitecoreConnector=True /property:SitecoreAccessGuid='dda691a5-8391-44a3-87c3-0bc1b08c5ed8' /property:RecursiveDeployAction=Ignore /property:DisableFileDeployment=True