# SOCAutoLinkDatabasesWorkingFolder
Red Gate SQL Source Control (4 or later) working folder automated link

## Description
This tool is a PowerShell script which links automatically your databases to Red Gate SQL Source Control. It does everything the _right click_ and _link to source control_ does unde the hood when you manually link a database to the Source Control via SQL Server Management studio. It lets you to choose what are the databases involved and it links also the static data and the filters configuration of your SQL Source Control.
It uses a typical path for remote source control manamger, with the branch folder and the database folder within. You can change the settings as you wish, as it's described in the _Global Settings and Param_ section.

## Prerequisites
In order to execute the script, you need to:
- setup SQL Server, no matter how is the version
- setup [Red Gate SQL Source Control](http://www.red-gate.com/products/sql-development/sql-source-control/)
- (optional) setup [Red Gate SQL Compare](http://www.red-gate.com/products/sql-development/sql-compare/)
- (optional) setup [Red Gate SQL Data Compare](http://www.red-gate.com/products/sql-development/sql-data-compare/)

if you don't have any of the comparison tool, you can execute this script distributing the executable files, following [this guide](https://documentation.red-gate.com/display/SC12/Changes+to+distribution+of+command+line).

## Global settings and params
After the functions definition area there is a region called _GLOBAL SETTINGS_ in which you will find a set of hard coded and customizable variables. The  script will use itself in order to get the folder to start with, so it works if it's been put into the _branch folder_. For more details, please read [my blog post here](https://suxstellino.wordpress.com/2016/06/28/automatically-link-databases-to-red-gate-sql-source-control/).
You can find:
- `$executeStepByStep`, which is the flag for executing step by step the script, in order to check the status of the folder. The default value is `$false`.
- `$ProductName`, which is the name of your _Product_, that is the name of your database folder into the workspace (we use `Product.DatabaseScope`, for example `DamnTools.TodoExplorerDB`).
- `$databasesPath`, which is the mdf/ndf/ldf path for the database (in development lines we don't care about using different disks).
- `$DB<n>Scope`, which is the name of the database without the _branch_ suffix (mandatory when you have server branches on TFS/VSTS or SVN). You need to create a scope for each database you want to link.
- `$DB<n>CreationScript`, which is the script related to the previous variable.
- `$databases`, which is the array of the database you'd like to link to the Source Control. You only know what they will be.

The hard coded variables are:
- `$socPath`, which is the installation path of the SoC (Red Gate Source Control), typically `%LOCALAPPDATA%\Red Gate\SQL Source Control <version>\"`.
- `$SQLComparePath`, which is the path of the SQL Compare installation (or the dependency folder if you distribute only the dlls and executables), please read [here](https://documentation.red-gate.com/display/SC12/Changes+to+distribution+of+command+line).
- `$SQLDataComparePath`, which is the path of the SQL Data Compare installation (or the dependency folder if you distribute only the dlls and executables), please read [here](https://documentation.red-gate.com/display/SC12/Changes+to+distribution+of+command+line).
- `$SqlToolbeltLicenseSerialNumber`, which is the license number (you can leave it empty if you'll use the executable from your licensed installation of the comparison tools).
- `$workingFolderHooksPath`, which is the working folder hooks configuration file `WorkingFolder.xml`
- `$xmlConfigurationsFilePath`, which is the linked database configuration file `LinkedDatabases.xml`

## How it works
The tool is based upon a Red Gate SQL Source Control installation. It changes automatically a set of configuration files, like `LinkedDatabases.xml` and `WorkingFolder.xml` and it's been tested only with the *working folder* source control option. This means that, likely, it'll work also with `git` and other source control based on folders, but it's not been tested with them. I'll wait for your contribution also for implementing the *direct link* to the source control.
Once you execute the script, it checks for any active SSMS instance. If so, it asks you to close them. Don't worry, in the eng SSMS will be restarted, in order to _refresh_ the status of the linked databases.
This is its pipeline:
- it asks for a named instance (or the default one is used)
- it shows a list of options (`0` for all the databases you've specified, another one for running the script just for one database)
- based on the option you choose, it loops for each database, doing the following tasks:
  - removes the node of the database on the `LinkedDatabases.xml` using the `RemoveAndSaveXmlConfiguration` function
  - removes the _under the hood_ folders of the the database (WorkingBase and Transient) using the `RemoveWorkingBaseAndTransientFolders` function
  - drops the database with the `DropDatabaseIfExists` function
  - creates the database with the `CreateDatabaseFromScript` function, using the scripts provided by you (there's just an example in the repo)
  - creates the _under the hoods_ folders with the `CreateWorkingBaseAndTransientFolders` function
  - creates the node for the database into the `LinkedDatabases.xml` file using the `AddAndSaveXmlConfiguration` function
  - populates the _under the hood_ folders with `Filters.scpf`, `RedGateDatabaseInfo.xml`, `RedGate.ssc` and thw workspace content using the `GeneratingWorkingBaseAndTransient` function
  - gets the latest structures with the `GetLatestDatabaseStructure` function
  - gets the latest data with the `GetLatestDatabaseData` function

## Additional notes
When the script tries to get the structures and data from the source control, it executes the SQL Compare and SQL Data Compare executable, diff-ing the workspace with the destination database. The execution of the SQL Comparison tools needs a license activation. So, *keep in mind that* you cannot execute it without a trial or a licensed version of the Comparison tools or the Red Gate SQL Toolbelt. For more details, please read [here](https://suxstellino.wordpress.com/2016/06/28/automatically-link-databases-to-red-gate-sql-source-control/).
However, the tool works also without the _getting of the latest version_. This means that you have to do it manually, but, since it's likely that you have some _load script_ you will break your steps into something like:
- execute this script
- get for each database manually using SQL Source Control
- execute some other script for loading data
With the license, you can leave the script as is, attaching a simple execution of another load data script, and you'll get just a one click execution instead. This is up to you.

If you want to avoid any get, you've to comment the last section of the loop, as described in the following snippet:

```
[...]
<#
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
      #>
[...]
```

## How to run the tool
In order to start using the tool, you can read [my blog post here](https://suxstellino.wordpress.com/2016/06/28/automatically-link-databases-to-red-gate-sql-source-control/).
You will find a compressed folder to work with. Inside it there are three sample folders (the databases with the `Product.DatabaseScope`) and three sql script for creating the databases on SQL Server. Then, the Powershell script, which is the copy of the `ps1` you can find on the root of the repository.
You can execute the script within ISE or any other Powershell tool, or create a batch file which executes the Powershell itself.

In order to consume also the comparison tools, you have to create a `Dependencies` folder in which you have to put the redistributable files, as described [here](https://documentation.red-gate.com/display/SC12/Changes+to+distribution+of+command+line). The script will look by default to a sub-folder with that name, but you can customize the path.

## A special thanks to
Many thanks to Red Gate for its great support. 
I'd like to thanks [David Atkinson](https://twitter.com/dtabase), [Alex Yates](https://twitter.com/_alexyates_) and Mike Hupton for the [repo](https://github.com/MatthewFlatt/SOCAutoLinkDatabases) I've used to start with this implementation.