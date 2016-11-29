#
# create_branch.ps1
# Create a branch given a TFS path Origin and a TFS path Dst
#
	param(
		[string] $Origin,
		[string] $Dst,
		[string] $WorkspaceName,
        [string] $User="",
        [string] $Password=""
	)
	Try {
        if ($User -ne "")
        {
            $LoginParam="`"/login:$User,$Password`""
        }
        else
        {
            $LoginParam=""
		}
		Push-Location
	    "Creating workspace"
		#Delete workspace if it is already exists
        if ((Test-Path -Path .\$WorkspaceName))
		{
			$errorSink=tf workspace $LoginParam /noprompt /delete $WorkspaceName
			rm .\$WorkspaceName -Recurse -Force
		}
		mkdir .\$WorkspaceName
		cd .\$WorkspaceName
       
        tf workspace /new /noprompt /collection:http://tfs01-qa:8080/tfs/defaultcollection /permission:Public $LoginParam $WorkspaceName 		
		"Delete $Dst Branch if it exists"
        tf get "$Dst" /recursive $LoginParam
		$LocalDst = $Dst.Replace("$",".")
		if ((Test-Path -Path "$LocalDst"))
		{
			tf delete $LoginParam $Dst 
			tf checkin /noprompt /bypass / $LoginParam
		}
		"Create the new branch"
        tf branch "$Origin" "$Dst" /noprompt $LoginParam
		tf checkin /bypass /noprompt $LoginParam
		Pop-Location
        "Delete workspace $WorkspaceName"
		tf workspace /noprompt /delete $LoginParam $WorkspaceName 
		rm .\$WorkspaceName -Recurse -Force
	}
	Catch
	{
		Pop-Location
		$errorSink=tf workspace /noprompt /delete $LoginParam $WorkspaceName
		rm .\$WorkspaceName -Recurse -Force 
		throw
	}


