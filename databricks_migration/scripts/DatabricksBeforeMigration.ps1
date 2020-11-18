<#
.SYNOPSIS
    Copying all files and folders from DBFS.
.DESCRIPTION
    Copying a file or folder of files to DBFS. Supports exact path or pattern matching. Target folder in DBFS does not need to exist - they will be created as needed.
    Existing files will be overwritten.

.PARAMETER BearerToken
    Your Databricks Bearer token to authenticate to your workspace (see User Settings in Databricks WebUI)

.PARAMETER Region
    Azure Region - must match the URL of your Databricks workspace, example westeurope

.PARAMETER DBFSPath
    DBFS folder location e.g. /FileStore or /

.PARAMETER DBFSLocalPath
    Local folder where DBFS folderss/files should be copied.

.PARAMETER DataBricksEnv
    This is super optional parameter. Can be dropped off from param list.
    
.EXAMPLE 
    
    Copy-DatabricksDBFSFolders -BearerToken $BearerToken -Region $Region -DBFSPath "/" -DBFSLocalPath '/test'
        
.NOTES
    Author: Saurabh Mishra
#>

function  Copy-DatabricksDBFSFolders {
    
    [cmdletbinding()]

    param (
        
      [parameter(Mandatory = $true)][string]$BearerToken,
      [parameter(Mandatory = $false)][string]$Region="westeurope",
      [parameter(Mandatory = $false)][string]$DBFSPath = '/FileStore',  
      [parameter(Mandatory = $false)][string]$DBFSLocalPath='C:\DBFS',      
      [parameter(Mandatory = $false)][string]$DataBricksEnv="Test"
    
    )

    $Folders = Get-DatabricksDBFSFolder -BearerToken $BearerToken -Region $Region -Path $DBFSPath

    $Folders | ForEach {
  
        If (($_.is_dir  -eq 'True') -and ($_.path.Contains('/FileStore') -or $_.path.Contains('/user'))){ 

          Copy-DatabricksDBFSFolders -BearerToken $BearerToken -DBFSPath $_.path

         } 
        
        Else {
          
          If ($_.path -ne $null){
          
            $NewFile = $DBFSLocalPath + $_.path.Replace("/", "\")
          
            $NewPath = $NewFile.SubString(0, $NewFile.LastIndexOf('\'))
          
          If(!(test-path $NewPath)){
          
            New-Item -ItemType Directory -Force -Path $NewPath
          
          }
       
           Write-Host "Copying files ....$NewFile"
     
           Get-DatabricksDBFSFile -BearerToken $BearerToken -Region $Region -DBFSFile $_.path  -TargetFile $NewFile
       
        }
      }
    }
  }



function  Ops-Databricks-BeforeMigration{
   
   param (

      [parameter(Mandatory = $false)][true]$BearerToken,
      [parameter(Mandatory = $false)][string]$CustomApiRootUrl = "https://westeurope.azuredatabricks.net",
      [parameter(Mandatory = $false)][string]$Region="westeurope",
      [parameter(Mandatory = $false)][string]$DBFSPath = '/FileStore',  
      [parameter(Mandatory = $false)][string]$LocalPath='C:\DatabricksArtifacts\',  
      [parameter(Mandatory = $false)][string]$DBFSLocalPath='C:\DBFS\'

     )

   # Establishing the connection to Databricks

   Set-DatabricksEnvironment -AccessToken $BearerToken -CustomApiRootUrl $CustomApiRootUrl
   Connect-Databricks -BearerToken $BearerToken -Region $Region

   If(!(test-path $LocalPath)){
     
           New-Item -ItemType Directory -Force -Path $LocalPath
     }

   If(!(test-path $DBFSLocalPath)){
  
           New-Item -ItemType Directory -Force -Path $DBFSLocalPath
     }

    # Get all files and environment
    
    Export-DatabricksEnvironment -LocalPath $LocalPath -CleanLocalPath

    # Get DBFS Folders

    Copy-DatabricksDBFSFolders -BearerToken $BearerToken -DBFSPath $DBFSPath

    Write-Host "`n---------Done---------" -ForegroundColor Yellow

}


Ops-Databricks-BeforeMigration -BearerToken $BearerToken
