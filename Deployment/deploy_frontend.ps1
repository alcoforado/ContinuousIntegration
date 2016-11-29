#
# deploy_frontend.ps1
#
param(
[string] $WebsitesFoldersToDeploy,
[string] $User="",
[string] $Password="",
[string] $MergeFilesIntoTFSProject="True"

)



Try {

	Import-Module -force -Name ((Split-Path $script:MyInvocation.MyCommand.Path)  + "\..\Modules\Utils.psm1")
	if ($MergeFilesIntoTFSProject.ToLower() -eq "true")
	{
		"Creating workspace"
		if ((Test-Path -Path .\CWSC02))
		{
			$errorSink=tf workspace /noprompt /delete TFS-GitDeployment
			rm .\CWSC02 -Recurse -Force
		}
		mkdir .\CWSC02
		cd .\CWSC02
		tf workspace /new /noprompt /collection:http://tfs01-qa:8080/tfs/defaultcollection TFS-GitDeployment
		tf get "$/Sitecore Main/Projects/CWSC02/CWSC02/*" /recursive
		cd ..\
		"Merging Git Files into TFS"
		MergeDirIntoTFS -SourceDir .\styles  -TFSDir ".\CWSC02\Sitecore Main\Projects\CWSC02\CWSC02\content\styles"  -ProjectPath ".\CWSC02\Sitecore Main\Projects\CWSC02\CWSC02\CW.CorporateSites.csproj"
		MergeDirIntoTFS -SourceDir .\scripts -TFSDir ".\CWSC02\Sitecore Main\Projects\CWSC02\CWSC02\content\scripts" -ProjectPath ".\CWSC02\Sitecore Main\Projects\CWSC02\CWSC02\CW.CorporateSites.csproj"
		cd .\CWSC02
		tf checkin /bypass
		cd ..\
	}
	$paths = $WebsitesFoldersToDeploy.Split(",");
	foreach($path in $paths)
	{
		#Copying files to destination
		$drive=MountRemotePath -RemotePath $path -User $User -Password $Password
		cp  .\styles  -Destination "${drive}:\content\"  -Recurse -Force -Exclude ".*"
		cp  .\scripts -Destination "${drive}:\content\" -Recurse -Force -Exclude ".*"
		net use ${drive}: /delete
	}
}
Finally {
tf workspace /noprompt /delete TFS-GitDeployment
}

