param(
[Int32]$BuildNumber="1",
[string]$Configuration="AwsDev",
[string]$WebSiteFolder="//10.0.1.9/D$/Repositories/DevNeoWebsite",
[string]$WebURL="\\10.0.1.9\D$\Repositories\DevNeoWebsite",
[string]$Changeset="0",
[string]$Workspace="",
[string]$InstallTestContent="True",
[string]$InstallCoreContent="False",
[string]$InstallTDSMaster="True",
[string]$Password="",
[string]$User="",
[string]$SmartPublish="False",
[string]$NotifyDeployment="False"
)

#This are the variables that control username/password for each of the protected environments

Import-Module -force -Name ((Split-Path $script:MyInvocation.MyCommand.Path)  + "\..\Modules\Utils.psm1")
$Drive=MountRemotePath -RemotePath $WebSiteFolder -User $User -Password $Password 



$buildInfoXML = "<?xml version='1.0' encoding='utf-16'?><BuildInfo><add key='BuildNumber' value='$Changeset'/><add key='BuildNumber' value='$BuildNumber' /></BuildInfo>"
$env:Path=$env:Path+";C:\Program Files (x86)\MSBuild\14.0\Bin"

$buildInfoXML | out-file -FilePath ${Drive}:\App_Config\BuildInfo.xml


" ======== Publish CW.CorporateSites ======="
$publishFile="<?xml version='1.0' encoding='utf-16'?>
<Project ToolsVersion='4.0' xmlns='http://schemas.microsoft.com/developer/msbuild/2003'>
  <PropertyGroup>
    <WebPublishMethod>FileSystem</WebPublishMethod>
    <LastUsedBuildConfiguration>$Configuration</LastUsedBuildConfiguration>
    <LastUsedPlatform>Any CPU</LastUsedPlatform>
    <SiteUrlToLaunchAfterPublish />
    <LaunchSiteAfterPublish>True</LaunchSiteAfterPublish>
    <ExcludeApp_Data>False</ExcludeApp_Data>
    <DeleteExistingFiles>False</DeleteExistingFiles>
    <publishUrl>${Drive}:\.</publishUrl>
  </PropertyGroup>
</Project>"
$publishFile | out-file -FilePath c:\temp\publishFile${Configuration}.pubxml


if ($NotifyDeployment.ToLower() -eq "true")
{
 "======== Notify Users that a deployment is under way ========"

	$r=Invode-WebRequest -Uri "$WebURL/continuousintegration/BroadcastShutdownMessageToAllSitecoreUsers"
	if ($r.StatusCode -eq 200)
	{
		"======== Sleep for 2 minutes ========"
		Start-Sleep -Seconds 120
	}
} 



cd .\Projects\CWSC02\CWSC02
msbuild .\CW.CorporateSites.csproj /property:Configuration="$Configuration" /p:DeployOnBuild=true /p:PublishProfile="c:\temp\publishFile${Configuration}.pubxml"

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

if ($InstallTDSMaster.ToLower() -eq "true")
{
" ======== Syncing TDS Master ========"
	$Timestamp=""
	$TimeStampFile="$WebsiteFolder\CWMaster.Deployment.Timestamp.txt"
	if ((Test-Path "$TimeStampFile") -and ($SmartPublish.ToLower() -eq "true"))
	{
		$Timestamp=cat "$TimeStampFile"
	}
	cd ..\CW.Master
	if ($TimeStamp -ne "")
	{
		$TimeStamp="/property:IncludeItemsChangedAfter=$TimeStamp"
	}

	msbuild .\CW.Master.scproj /p:SourceWebPhysicalPath="" /p:SourceWebProject="" $TimeStamp /p:SourceWebPhysicalPath="" /property:Configuration="$Configuration" /property:Platform='Any CPU' /property:OutputPath='.\bin\Deploy' /property:SitecoreWebUrl="$WebURL" /property:SitecoreDeployFolder="${Drive}:\.\" /property:InstallSitecoreConnector=True  /property:RecursiveDeployAction=Ignore /property:DisableFileDeployment=True
	$code = $LASTEXITCODE
	if ($code -gt 0)
	{
	net use ${Drive}: /delete
	throw "Error: MSBuild returned errors. $code"
	}
	$TimeStampDate = Get-Date
	$TimeStampDate=$TimeStampDate.AddDays(-60) 
	"$($TimeStampDate.Year)-$($TimeStampDate.Month)-$($TimeStampDate.Day)" | Out-File -FilePath "$TimeStampFile"
}
else
{
" ======== Skipping TDS Master Deployment ========"
}

if ($InstallTestContent -eq "True")
{
" ======== Syncing TDS Test ========"
cd ..\TDSProject1
msbuild .\CW.TDS.Test.scproj  /p:SourceWebProject=""  /p:SourceWebPhysicalPath="" /property:Configuration="$Configuration" /property:Platform='Any CPU' /property:OutputPath='.\bin\Deploy' /property:SitecoreWebUrl="$WebURL" /property:SitecoreDeployFolder="${Drive}:\.\" /property:InstallSitecoreConnector=True  /property:RecursiveDeployAction=Ignore /property:DisableFileDeployment=True
$code = $LASTEXITCODE
if ($code -gt 0)
{
net use ${Drive}: /delete
throw "Error: MSBuild returned errors. $code"
}
}
else
{
" ======  TDS Test Deployment Skipped ======"
}




#cd .\CW.Master\bin\Deploy\_PublishedWebsites\CW.Master
#cp .\* ${Drive}:\ -force -recurse
net use ${Drive}: /delete

#/property:Configuration=GatedCheckIn /property:Platform='Any CPU'  /property:OutputPath='.\bin\GatedCheckIn' /property:SitecoreWebUrl='http://neo.qa.connectwise.com' /property:SitecoreDeployFolder='Y:\' /property:InstallSitecoreConnector=True /property:SitecoreAccessGuid='dda691a5-8391-44a3-87c3-0bc1b08c5ed8' /property:RecursiveDeployAction=Ignore /property:DisableFileDeployment=True