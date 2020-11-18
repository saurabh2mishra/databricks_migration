<#
.SYNOPSIS
    Add all groups and respective users in Databricks  (reads users and groups name from previously imported artifacts)
.PARAMETER LocalPath
    Local Path where artifacts are kept.
.EXAMPLE 
    Add-DatabricksGroupAndUsers -LocalPath $LocalPath
        
.NOTES
    Author: Saurabh Mishra
#>

function Add-DatabricksGroupAndUsers{

       [cmdletbinding()]

       param ( [parameter(Mandatory = $false)][string]$LocalPath = "C:\DatabricksArtifacts\")

       $UserDir= Join-Path -Path $LocalPath -ChildPath "\Security"
       $GroupsMembers = @{}  

       Get-ChildItem -Path $UserDir| ForEach-Object{   
             $FilePath = Join-Path -Path $UserDir  -ChildPath $_
             $json = Get-Content $FilePath | Out-String | ConvertFrom-Json
             if ($json -ne $null){
                 $users = $json.GetEnumerator().user_name
                 ForEach ($user in $users){
                     $group =  $_.ToString().Split(".")[0]
                     $GroupsMembers[$group]+= $user+","
             }  
           }
         }

       ForEach ($GroupMember in $GroupsMembers.GetEnumerator()) {
            $GroupName = $GroupMember.Key
            
            # Adding group 
            Add-DatabricksGroup -GroupName $GroupName

            $Members = $GroupMember.Value
            ForEach ($UserName in $Members.Split(',')){ 
                If($UserName.Length -gt 0){                   
                # Adding members in given group    
                Add-DatabricksGroupMember -UserName $UserName -ParentGroupName $GroupName
                Write-Host "Adding User: $UserName in Group : $GroupName"   
               }   
            }
        }
}


function  Ops-Databricks-AfterMigration{

    [cmdletbinding()]

    param (
      [parameter(Mandatory = $true)][string]$BearerToken,
      [parameter(Mandatory = $false)][string]$CustomApiRootUrl = "https://westeurope.azuredatabricks.net",
      [parameter(Mandatory = $false)][string]$Region="westeurope",
      [parameter(Mandatory = $false)][string]$DataBricksEnv="Test",
      [parameter(Mandatory = $false)][string]$LocalPath="C:\DatabricksArtifacts\",
      [parameter(Mandatory = $false)][string]$DBFSLocalPath="C:\DBFS"

      )

    # Setting Params

    $Groups=@("sg_app_opsi_business")

    # Establishing the connection to Databricks

    Set-DatabricksEnvironment -AccessToken $BearerToken -CustomApiRootUrl $CustomApiRootUrl
    Connect-Databricks -BearerToken $BearerToken -Region $Region

    # Add all users to Databricks

    $UserDir= Join-Path -Path $LocalPath -ChildPath "\Workspace\Users"
    
    Get-ChildItem -Path $UserDir| ForEach-Object{
    
        Add-DatabricksUser -BearerToken $BearerToken -Region $Region -Username $_
    
        Write-Host "User added in $DataBricksEnv :  $_"
    }


    # Create Groups

    $Groups | ForEach {
     
        Add-DatabricksGroup -GroupName $_
        Write-Host "Group added in $DataBricksEnv  :  $_"    
    }

    # Add memebers in defined group

     Add-DatabricksGroupAndUsers

    # Import all exported contents

    Import-DatabricksEnvironment -LocalPath $LocalPath -Artifacts All 


    # list DBFS folder

    Get-DatabricksDBFSFolder -BearerToken $BearerToken -Region $Region -Path /

    # Add local DBFS folder to Databricks

    Add-DatabricksDBFSFile -BearerToken $BearerToken -Region $Region -LocalRootFolder $DBFSLocalPath -FilePattern "*"  -TargetLocation '/' -Verbose
      
    
    Write-Host "`n---------Done---------" -ForegroundColor Yellow



}


$BearerToken=(New-DatabricksBearerToken -LifetimeSeconds 3600 -Comment "MigrationToken").token_value
Ops-Databricks-AfterMigration -BearerToken $BearerToken