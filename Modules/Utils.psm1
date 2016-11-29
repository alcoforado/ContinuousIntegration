#
# Utils.psm1
#

function MountRemotePath
{
	param(
		[string] $RemotePath,
		[string] $User="",
		[string] $Password=""
	)
       
		$LettersToTry = "I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y"
		[int] $i=0;
		[string] $err="";
		
		
		do {
			$letter=$LettersToTry[$i]
			if ($User -eq "")
			{
			
				write-host "net use ${letter}: $RemotePath /persistent:no 2>&1"
				$err=net use ${letter}: $RemotePath /persistent:no 2>&1
				write-host $err
			}
			else
			{
				
				$err=net use ${letter}: $RemotePath $Password /user:$User /persistent:no 2>&1
			}
			if ($err.Contains("System error 85") -or $err.Contains("System error 1202"))
			{
				$i=$i+1
			}
			elseif ($LASTEXITCODE -eq 0)			
			{
				return $letter;
			}
			else
			{
				throw $err;
			}
		} while($i -lt $LettersToTry.Length)
		throw "No drive letters available"
} 



function CopySitecoreItems
{
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
	Try {
	#Create Certificate GUI
	$guid = [guid]::NewGuid();
	$driveSrc = MountRemotePath -RemotePath "$SrcFolder" -User $SrcUser -Password $SrcPassword
	Out-File "${driveSrc}:\JenkinsCertificate.txt" -InputObject $($guid.ToString())
	
	Invoke-WebRequest -Uri "$SrcURL/continuousintegration/createpackage" -Method Post -Body @{
	CertificationFileName = 'JenkinsCertificate.txt'
	Certification = "$($guid.ToString())"
	Name = "jenkins-src-package.zip"
	DatabaseEnvironment = "$Database"
	Author = "Jenkins" 
	Paths=$ItemPaths
	}




	if (-Not (Test-Path -Path "${driveSrc}:\jenkins-src-package.zip"))
	{
		throw "Could not find source package"
	}
	$driveDst= MountRemotePath -RemotePath "$DstFolder" -User $DstUser -Password $DstPassword
	
	#Create the certificate file
	Out-File "${driveDst}:\JenkinsCertificate.txt" -InputObject $($guid.ToString())
	cp ${driveSrc}:\jenkins-src-package.zip ${driveDst}:\ 

	#Invoke-WebRequest -Uri "$DstURL/continuousintegration/installpackage" -Method Post -Body @{
	#CertificationFileName = 'JenkinsCertificate.txt'
	#Certification = "$($guid.ToString())"
	#PackageName = "jenkins-src-package.zip"
	#Author = "Jenkins" }


	if ($LASTEXITCODE -gt 0)
	{
		throw "could not install package"
	}


	}
	Catch 
	{
		net use ${driveSrc}: /delete 
		net use ${driveDst}: /delete 
		throw
	}
	net use ${driveSrc}: /delete 
    net use ${driveDst}: /delete 

}


function FindRelativePath
{
    param(
    [string] $OriginPath,
    [string] $Path)

    $pathInfo = get-item "$Path"
    Push-Location
    cd $OriginPath
    $result = Resolve-Path ("$($pathInfo.FullName)") -Relative
    Pop-Location
    return $result


}


function MergeDirIntoTFS
{
	param(
		[string] $SourceDir,
		[string] $TFSDir,
		[string] $ProjectPath
	)
	#For each FileInfo in SourceDir
	$SourceFiles = Get-ChildItem -Path "$SourceDir "
	$ProjectDir = Split-Path -Path "$ProjectPath" -Parent
    $ProjectPathFullName = (get-item "$ProjectPath").FullName
	tf checkout "$ProjectPath"
	foreach($SrcFile in $SourceFiles) {
		$DstFile="$TFSDir\$($SrcFile.Name)"
		if ((Test-Path -Path "$DstFile"))
		{
			"Copying $SourceDir\$($SrcFile.Name) to $DstFile"
			tf checkout "$DstFile"
			cp "$($SrcFile.FullName)" "$DstFile"
		}
		else
		{
			"Adding $($SrcFile.FullName) to $DstFile"
			cp "$($SrcFile.FullName)" "$DstFile"
			tf add "$DstFile"

            $contentItemPath= FindRelativePath -OriginPath "$ProjectDir" -Path "$DstFile"
			$projContent = [IO.File]::ReadAllText("$ProjectPathFullName")
			$projContent = $projContent.Insert($projContent.IndexOf("<Content Include="),"<Content Include=`"$contentItemPath`"/>`n`t");
			$projContent>"$ProjectPath";
		}
	}
	
}

