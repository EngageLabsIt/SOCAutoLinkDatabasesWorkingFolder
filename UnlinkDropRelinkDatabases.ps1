
#region FUNCTIONS

#this function creates the entry for the configuration xml file (RedGate config file)
function AddAndSaveXmlConfiguration (
    [string]$serverName = $(Throw 'serverName is required'), 
    [string]$databaseName = $(Throw 'databaseName is required'), 
    [string]$workSpacePath = $(Throw 'workSpacePath is required'), 
    [string]$workingFolderHooksPath = $(Throw 'workingFolderHooksPath is required'), 
    [string]$workingBasePath = $(Throw 'workingBasePath is required'), 
    [string]$transientPath = $(Throw 'transientPath is required'),
    [xml]$xmlLinkedDatabases = $(Throw 'xmlLinkedDatabases is required'),
    [string]$xmlConfigurationsFilePath = $(Throw 'xmlConfigurationsFilePath is required'))
{
    #value node
    $xmlValueNode = $xmlLinkedDatabases.LinkedDatabaseStore.LinkedDatabaseList.AppendChild($xmlLinkedDatabases.CreateElement("value"))
    $xmlValueNode.SetAttribute("version", "7")
    $xmlValueNode.SetAttribute("type", "LinkedDatabase")
        #DatabaseId node
        $xmlDatabaseIdNode = $xmlValueNode.AppendChild($xmlLinkedDatabases.CreateElement("DatabaseId"))
        $xmlDatabaseIdNode.SetAttribute("version", "2")
        $xmlDatabaseIdNode.SetAttribute("type", "DatabaseId")
            #ServerAndInstanceName node
            $xmlServerAndInstanceNameNode = $xmlDatabaseIdNode.AppendChild($xmlLinkedDatabases.CreateElement("ServerAndInstanceName"))
            $xmlServerAndInstanceNameNode = $xmlServerAndInstanceNameNode.AppendChild($xmlLinkedDatabases.CreateTextNode($serverName))
            #DatabaseName node
            $xmlDatabaseNameNode = $xmlDatabaseIdNode.AppendChild($xmlLinkedDatabases.CreateElement("DatabaseName"))
            $xmlDatabaseNameNode = $xmlDatabaseNameNode.AppendChild($xmlLinkedDatabases.CreateTextNode($databaseName))
        #ISrcCLocation node
        $xmlISrcCLocationNode = $xmlValueNode.AppendChild($xmlLinkedDatabases.CreateElement("ISrcCLocation"))
        $xmlISrcCLocationNode.SetAttribute("version", "2")
        $xmlISrcCLocationNode.SetAttribute("type", "WorkingFolderGenericLocation")
            #LocalRepositoryFolder node
            $xmlLocalRepositoryFolderNode = $xmlISrcCLocationNode.AppendChild($xmlLinkedDatabases.CreateElement("LocalRepositoryFolder"))
            $xmlLocalRepositoryFolderNode = $xmlLocalRepositoryFolderNode.AppendChild($xmlLinkedDatabases.CreateTextNode($workSpacePath+'\'))
            #HooksConfigFile node
            $xmlHooksConfigFileNode = $xmlISrcCLocationNode.AppendChild($xmlLinkedDatabases.CreateElement("HooksConfigFile"))
            $xmlHooksConfigFileNode = $xmlHooksConfigFileNode.AppendChild($xmlLinkedDatabases.CreateTextNode($workingFolderHooksPath))
            #HooksFileInRepositoryFolder node
            $xmlHooksFileInRepositoryFolderNode = $xmlISrcCLocationNode.AppendChild($xmlLinkedDatabases.CreateElement("HooksFileInRepositoryFolder"))
            $xmlHooksFileInRepositoryFolderNode = $xmlHooksFileInRepositoryFolderNode.AppendChild($xmlLinkedDatabases.CreateTextNode("False"))
        #IWorkspaceId node
        $xmlIWorkspaceIdNode = $xmlValueNode.AppendChild($xmlLinkedDatabases.CreateElement("IWorkspaceId"))
        $xmlIWorkspaceIdNode.SetAttribute("version", "1")
        $xmlIWorkspaceIdNode.SetAttribute("type", "WorkspaceId")
            #RootPath node
            $xmlRootPathWFNode = $xmlIWorkspaceIdNode.AppendChild($xmlLinkedDatabases.CreateElement("RootPath"))
            $xmlRootPathWFNode = $xmlRootPathWFNode.AppendChild($xmlLinkedDatabases.CreateTextNode($workingBasePath))
        #SharedModel node
        $xmlSharedModelNode = $xmlValueNode.AppendChild($xmlLinkedDatabases.CreateElement("SharedModel"))
        $xmlSharedModelNode = $xmlSharedModelNode.AppendChild($xmlLinkedDatabases.CreateTextNode("False"))
        #ScriptTransientId node
        $xmlScriptTransientIdNode = $xmlValueNode.AppendChild($xmlLinkedDatabases.CreateElement("ScriptTransientId"))
        $xmlScriptTransientIdNode.SetAttribute("version", "1")
        $xmlScriptTransientIdNode.SetAttribute("type", "WorkspaceId")
            #RootPath node
            $xmlRootPathTRNode = $xmlScriptTransientIdNode.AppendChild($xmlLinkedDatabases.CreateElement("RootPath"))
            $xmlRootPathTRNode = $xmlRootPathTRNode.AppendChild($xmlLinkedDatabases.CreateTextNode($transientPath))

    $xmlLinkedDatabases.Save($xmlConfigurationsFilePath)
}

function RemoveAndSaveXmlConfiguration (
    [string]$xmlConfigurationsFilePath = $(Throw 'xmlConfigurationsFilePath is required'),
    [System.Xml.XmlElement]$nodeToRemove = $(Throw 'dbNode is required')
)
{
    $xmlLinkedDatabases.LinkedDatabaseStore.LinkedDatabaseList.RemoveChild($nodeToRemove) | Out-Null
    $xmlLinkedDatabases.Save($xmlConfigurationsFilePath)
}

function CreateDatabaseFromScript(
    [string]$createDatabaseScript = $(Throw 'createDatabaseScript is required'),
    [string]$serverName = $(Throw 'serverName is required'),
    [string]$databasesPath = $(Throw 'databasesPath is required'),
    [string]$databaseName = $(Throw 'databaseName is required')
)
{
    if(!(Test-Path (Join-Path $databasesPath $databaseName)))
    {
        New-Item -ItemType Directory -Path (Join-Path $databasesPath $databaseName) | Out-Null
    }
    
    Invoke-Sqlcmd -inputfile $createDatabaseScript -serverinstance $serverName -Variable DatabaseFilesPath="$databasesPath", DatabaseName="$databaseName"
}

function DropDatabaseIfExists (
    [string]$dropDatabaseScript = $(Throw 'dropDatabaseScript is required'),
    [string]$databaseName = $(Throw 'databaseName is required'),
    [string]$serverName = $(Throw 'serverName is required')
)
{
    $databaseExists = Invoke-Sqlcmd -Query "DECLARE @v int; SELECT @v=DB_ID('$databaseName'); SELECT @v AS DBExists;" -serverinstance $serverName
    if (![string]::IsNullOrEmpty($databaseExists.DBExists))
    {
        $dropScript = $dropDatabaseScript -replace "<DB>", $databaseName
        Invoke-Sqlcmd -Query $dropScript -serverinstance $serverName
    }
}

function RemoveWorkingBaseAndTransientFolders (
    [string]$workingBase = $(Throw 'workingBase is required'),
    [string]$transient = $(Throw 'transient is required')
)
{
    if((Test-Path $workingBase))
    {
       Remove-Item $workingBase -Recurse
    }
    if((Test-Path $transient))
    {
       Remove-Item $transient -Recurse
    }    
}

function CreateWorkingBaseAndTransientFolders (
    [string]$workingBase = $(Throw 'workingBase is required'),
    [string]$transient = $(Throw 'transient is required')
)
{
    New-Item $workingBase -type Directory | Out-Null
    New-Item $transient -type Directory | Out-Null
}

function GeneratingWorkingBaseAndTransient (
    [string]$sourceFolder = $(Throw 'sourceFolder is required'),
    [string]$targetWorkingBase = $(Throw 'targetWorkingBase is required'),
    [string]$targetTransient = $(Throw 'targetTransient is required')
)
{
    #working base is the copy of the database, at this time, an empty structure made by folders only
    robocopy $sourceFolder $targetWorkingBase /e /xf *.* | Out-Null
    Copy-Item $sourceFolder\RedGateDatabaseInfo.xml $targetWorkingBase | Out-Null #must be copied
    Copy-Item $sourceFolder\RedGate.ssc $targetWorkingBase | Out-Null #must be copied

    #transient folder is a copy of the latest version of the source control
    Copy-Item $sourceFolder\* $targetTransient -Recurse | Out-Null

    if (Test-Path $sourceFolder\Filter.scpf)
    {
        Copy-Item $sourceFolder\Filter.scpf $targetTransient -Force | Out-Null #must be refreshed
    }
}


function GetLatestDatabaseStructure(
    [string]$sourceFolder = $(Throw 'sourceFolder is required'),
    [string]$serverName = $(Throw 'serverName is required'),
    [string]$databaseName = $(Throw 'databaseName is required'),
    [string]$SqlCompareFolder = $(Throw 'SqlCompareFolder is required'),
    [string]$LicenseSerialNumber = $(Throw 'LicenseSerialNumber is required')
)
{
    Set-Location $SqlCompareFolder
    $command = "./sqlcompare"
    $arguments = " /activateSerial: $LicenseSerialNumber"
    $arguments = "/scripts1:$sourceFolder"
    $arguments += " /server2:$serverName"
    $arguments += " /database2:$databaseName"
    $arguments += " /options:IgnoreCollations,IgnoreFillFactor,IgnoreWhiteSpace,IncludeDependencies,IgnoreUserProperties,IgnoreWithElementOrder,IgnoreDatabaseAndServerName,DecryptPost2kEncryptedObjects"
    $arguments += " /Synchronize"
    $arguments += " /Force"
    $arguments += " /Quiet"
    Invoke-Expression "$command $arguments" | Out-Null

}

function GetLatestDatabaseData(
    [string]$sourceFolder = $(Throw 'sourceFolder is required'),
    [string]$serverName = $(Throw 'serverName is required'),
    [string]$databaseName = $(Throw 'databaseName is required'),
    [string]$SqlDataCompareFolder = $(Throw 'SqlDataCompareFolder is required'),
    [string]$LicenseSerialNumber = $(Throw 'LicenseSerialNumber is required')
)
{
    
    Set-Location $SqlDataCompareFolder
    $command = "./sqldatacompare"
    $arguments = " /activateSerial: $LicenseSerialNumber"
    $arguments = "/scripts1:$sourceFolder"
    $arguments += " /server2:$serverName"
    $arguments += " /database2:$databaseName"
    $arguments += " /Synchronize"
    $arguments += " /Force"
    $arguments += " /Quiet"
    Invoke-Expression "$command $arguments" | Out-Null
}

#endregion

cls

Write-Host "This script will create and link the development databases.." -ForegroundColor Cyan
Write-Host

#region GLOBAL SETTINGS
$CurrentFolder = Split-Path $MyInvocation.MyCommand.Definition -Parent

#set this to true if you want a step by step execution
$executeStepByStep = $false

#current barnch folder (you can change this if you move the file deeper in the path)
$BranchFolder = Split-Path $MyInvocation.MyCommand.Definition -Parent
#this is the point to get the Database branch folder (in order to create the workspace folder)
$databaseBranchFolder = $BranchFolder
$BranchSuffix = Split-Path $BranchFolder -Leaf

#product (brand) name, change it with your name (it cannot be blank)
$ProductName = "Foo"
#databases path, change it with your databases path
$databasesPath = "C:\Foo\Databases\"
#database scope settings (list of custom database "scope", scope is the "meaning" of the database and it needs the branch name for being a complete name)
$DB1Scope = 'DB1'
$DB2Scope = 'DB2'
$DB3Scope = 'DB3'
#database scripts (you can change the names of each script, and also the text within them)
$DB1CreationScript = '01 - Create database DB1.sql'
$DB2CreationScript = '02 - Create database DB2.sql'
$DB3CreationScript = '03 - Create database DB3.sql'
#endregion

#region WORKING VARIABLES

# list of needed database (specify the position = specify the sorting of scripts execution, if you need any)
$DB1Name = $DB1Scope+"_"+$BranchSuffix
$DB2Name = $DB2Scope+"_"+$BranchSuffix
$DB3Name = $DB3Scope+"_"+$BranchSuffix

$databases = (
        ($DB1Scope, $DB1Name, $DB1CreationScript, 1),
        ($DB2Scope, $DB2Name, $DB2CreationScript, 2),
        ($DB3Scope, $DB3Name, $DB3CreationScript, 3)
    )

# RedGate - hard-coded to version 5, change it if you have another version.
$socPath = $env:LOCALAPPDATA + "\Red Gate\SQL Source Control 5\"
$SQLComparePath = Join-Path $CurrentFolder -ChildPath "Dependencies"
$SQLDataComparePath = Join-Path $CurrentFolder -ChildPath "Dependencies"
$SqlToolbeltLicenseSerialNumber = ""
$workingFolderHooksPath = Join-Path $socPath "ReservedCommandLineHooks\WorkingFolder.xml"
$xmlConfigurationsFilePath = Join-Path $socPath LinkedDatabases.xml

# script sql template for DROP DATABASE (needed for dropping the database before recreating it)
$dropDatabaseScript = "EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'<DB>'
GO
USE [master]
GO
ALTER DATABASE [<DB>] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE [<DB>]
GO"

[xml]$xmlLinkedDatabases = Get-Content ($xmlConfigurationsFilePath)
#endregion

#check whether the SSMS process is running (if you want to refresh the database status you need to restart SSMS)
if((get-process "Ssms" -ea SilentlyContinue) -ne $null){
    Write-Host "Please close SQL Server Management Studio before executing this script." -ForegroundColor Red
    exit
}

#region SERVER MANAGEMENT
$MachineName = $env:computername
$FullServerName = Read-Host "Server name\Instance name (empty to auto-discover)"
Write-Host 
if ($FullServerName -eq "")
{
    Write-Host "Gathering instance data.." -ForegroundColor Yellow

    # default instance name (the first in the registry key)
    $InstanceName = (get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances | Select-Object -first 1
    $serverName = $MachineName + "\"+ $InstanceName
} else 
{
    $serverName = $FullServerName
}
Write-Host "Instance name set to '$serverName'" -ForegroundColor Gray
Write-Host 
#endregion

#region MENU
Write-Host "Choose an option:" -ForegroundColor Yellow
Write-Host "0 - All databases" -ForegroundColor White
foreach ($database in $databases)
{
    Write-Host $database[3] '-' $database[1] -ForegroundColor White
}

Do 
{ 
    $selectedOption = Read-host
} 
while ($selectedOption -ne $null -and $selectedOption -notin 0..6)
#endregion

#region LINKING DATABASES AND SCRIPT EXECUTION

#check for base databases path
Write-Host "Creating base databases folders... " -ForegroundColor Yellow

if(!(Test-Path $databasesPath))
{
    New-Item -ItemType Directory -Path $databasesPath | Out-Null
    Write-Host "Folder '$databasesPath' created successfully." -ForegroundColor Gray
} 
else 
{
    Write-Host "Folder '$databasesPath' already exists. No user action required." -ForegroundColor Gray
}

Write-Host "Base databases path set to '$databasesPath'." -ForegroundColor Gray
Write-Host

if ($selectedOption -eq 0)
{
    Write-Host "Linking all databases" -ForegroundColor Yellow
}
else
{
    Write-Host "Linking database"$databases[$selectedOption - 1][1] -ForegroundColor Yellow
}

#configuration file (RedGate) xml node to manage
$linkedDatabasesXmlNode = $xmlLinkedDatabases.LinkedDatabaseStore.LinkedDatabaseList.value

#loop setting by database (list of databases on the top, hard coded)
foreach ($database in $databases)
{
    $databaseScope = $database[0] #is the macro database area 
    $databaseName = $database[1] #name of the database
    $databaseOption = $database[3] #option related to the database in the "start menu"

    if ($databaseOption -eq $selectedOption -or $selectedOption -eq 0)
    {

        $createDatabaseScript = Join-Path  $CurrentFolder $database[2] #path of the script to execute in order to create the database
        $databaseFilesPath = Join-Path $databasesPath $databaseName #path of the target database
        $databaseWorkSpaceFolder = Join-Path $databaseBranchFolder $ProductName'.'$databaseScope #path of the workspace which contains the database

        Write-Host "Managing database: '$databaseName'" -ForegroundColor White

        #unlinking the databases from the source control working folder
        #delete info from the RedGate Source Control xml configuration file (if exists)
        $dbNode = $xmlLinkedDatabases.LinkedDatabaseStore.LinkedDatabaseList.value | where {$_.DatabaseId.DatabaseName -eq $databaseName}
    
        if ($dbNode)
        {
            if ($executeStepByStep)
            {
                write-host "remove workingbase and transient from xml" -ForegroundColor Yellow -BackgroundColor Red
                read-host
            }

            #removing node on xml config file
            Write-Host " Removing nodes from RedGate XML config file for '$databaseName'... " -ForegroundColor DarkGray -NoNewline
            RemoveAndSaveXmlConfiguration -xmlConfigurationsFilePath $xmlConfigurationsFilePath -nodeToRemove $dbNode
            Write-Host "Done!" -ForegroundColor Gray
        
            if ($executeStepByStep)
            {
                write-host "remove folders" -ForegroundColor Yellow -BackgroundColor Red
                read-host
            }
    
            #remove working bases and transient folders from the filesystem
            Write-Host " Removing the working base and the transient settings from the xml configuration file... " -ForegroundColor DarkGray -NoNewline
            RemoveWorkingBaseAndTransientFolders -workingBase $dbNode.IWorkspaceId.RootPath -transient $dbNode.ScriptTransientId.RootPath
            Write-Host "Done!" -ForegroundColor Gray
        }

        if ($executeStepByStep)
        {
            write-host "drop and create the db" -ForegroundColor Yellow -BackgroundColor Red
            read-host
        }

        #drop and create the database
        Write-Host " Dropping '$databaseName' database if exists, then re-create it with '$createDatabaseScript' setup script... " -ForegroundColor DarkGray -NoNewline
        DropDatabaseIfExists -dropDatabaseScript $dropDatabaseScript -databaseName $databaseName -serverName $serverName
        CreateDatabaseFromScript -serverName $serverName -databaseScope $databaseScope -databasesPath $databasesPath -databaseName $databaseName -createDatabaseScript $createDatabaseScript
        Write-Host "Done!" -ForegroundColor Gray
    
        if ($executeStepByStep)
        {
            write-host "create workingbase and transient on disk" -ForegroundColor Yellow -BackgroundColor Red
            read-host
        }

        # create working bases and transient folders
        $randomWorkingBaseFileName = [System.IO.Path]::GetRandomFileName()
        $randomWorkingBaseDirectoryName = Join-Path (Join-Path $socPath WorkingBases) $randomWorkingBaseFileName
        $randomTransientFileName = [System.IO.Path]::GetRandomFileName()
        $randomTransientDirectoryName = Join-Path (Join-Path $socPath Transients) $randomTransientFileName
        Write-Host " Creating the working base '$randomWorkingBaseFileName' and the transient '$randomTransientFileName'... " -ForegroundColor DarkGray -NoNewline
        CreateWorkingBaseAndTransientFolders -workingBase $randomWorkingBaseDirectoryName -transient $randomTransientDirectoryName
        Write-Host "Done!" -ForegroundColor Gray

        if ($executeStepByStep)
        {
            write-host "create workingbases and transients on xml" -ForegroundColor Yellow -BackgroundColor Red
            read-host
        }

        # create the info in the RedGate Source Control xml configuration file
        Write-Host " Creating nodes for the RedGate XML config file for '$databaseName'... " -ForegroundColor DarkGray -NoNewline
        AddAndSaveXmlConfiguration -serverName $serverName -databaseName $databaseName -workspacePath $databaseWorkSpaceFolder -workingFolderHooksPath $workingFolderHooksPath -workingBasePath $randomWorkingBaseDirectoryName -transientPath $randomTransientDirectoryName -xmlLinkedDatabases $xmlLinkedDatabases -xmlConfigurationsFilePath $xmlConfigurationsFilePath
        Write-Host "Done!" -ForegroundColor Gray
    
        if ($executeStepByStep)
        {
            write-host "copying working bases" -ForegroundColor Yellow -BackgroundColor Red
            read-host
        }
        # copy the content of the working folder into the transient and working bases
        GeneratingWorkingBaseAndTransient -sourceFolder $databaseWorkSpaceFolder -targetWorkingBase $randomWorkingBaseDirectoryName -targetTransient $randomTransientDirectoryName
    
        #getting latest version of structures 
        Write-Host " Getting latest versions of '$databaseName'... " -ForegroundColor DarkGray
        Write-Host "   Comparing structures..." -ForegroundColor DarkGray -NoNewline
        GetLatestDatabaseStructure -sourceFolder $databaseWorkSpaceFolder -serverName $serverName -databaseName $databaseName -SqlCompareFolder "$SQLComparePath" -LicenseSerialNumber $SqlToolbeltLicenseSerialNumber
        Write-Host "Done!" -ForegroundColor Gray

        if ($executeStepByStep)
        {
            write-host "getting latest versions of data" -ForegroundColor Yellow -BackgroundColor Red
            read-host
        }

        #getting latest version of data
        Write-Host "   Comparing data..." -ForegroundColor DarkGray -NoNewline
        GetLatestDatabaseData -sourceFolder $databaseWorkSpaceFolder -serverName $serverName -databaseName $databaseName -SqlDataCompareFolder "$SQLDataComparePath" -LicenseSerialNumber $SqlToolbeltLicenseSerialNumber
        Write-Host "Done!" -ForegroundColor Gray
        
        Write-Host "New environment for database '$databaseName' ready!" -ForegroundColor White
        Write-Host

        if ($executeStepByStep)
        {
            write-host "Next database" -ForegroundColor Yellow -BackgroundColor Green
            read-host
        }
    #>
    }
}

Write-Host "Environment for databases completed successfully!" -ForegroundColor Yellow

Write-Host 
Write-Host "Starting SQL Server Management Studio..." -ForegroundColor Cyan

start-process ssms -verb runAs

#endregion
