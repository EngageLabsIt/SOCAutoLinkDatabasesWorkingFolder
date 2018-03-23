# Sql Source Control Auto Link (Working folder and git)

Red Gate SQL Source Control (4 or later) working folder/git automated link

## Description

This tool is based on PowerShell scripts which link automatically your databases to Red Gate SQL Source Control. It does everything the _right click_and_link to source control_ does unde the hood when you manually link a database to the Source Control via SQL Server Management studio. It lets you to choose what are the databases involved and it links also the static data and the filters configuration of your SQL Source Control. Additionally, it gets the latest changes of the database strucutres as well as the static data.
You can change the settings as you wish, as it's described in the _Global Settings and Param_ section.

__Warning:__ this tool works only for working folder and git setup.

## Prerequisites

In order to execute the script, you need to:

- get and install SQL Server

- setup [Red Gate SQL Source Control](https://www.red-gate.com/products/sql-development/sql-source-control/)

- setup [Red Gate SQL Compare](https://www.red-gate.com/products/sql-development/sql-compare/) _(optional)_

- setup [Red Gate SQL Data Compare](https://www.red-gate.com/products/sql-development/sql-data-compare/) _(optional)_

if you don't have any of the comparison tool, you can execute this script distributing the executable files into a dependency folder. If you design to use this tool avoiding getting the latest versions of data and structures (you will need a DLM Automation license, as described [here](https://documentation.red-gate.com/sc13/using-the-command-line/integrating-the-command-line-with-applications) for SQL Compare, and [here](https://documentation.red-gate.com/sdc13/using-the-command-line/integrating-the-command-line-with-applications) for SQL Data Compare).

## Global settings and params

Below the functions definition area, into the _GLOBAL SETTINGS_ section, you will find a set of hard coded and customizable variables. In order to choose the folder to start from, please read [my blog post here](https://alessandroalpi.blog/2016/06/28/automatically-link-databases-to-red-gate-sql-source-control/).

The global variables are the following:

- `$executeStepByStep`, which is the flag for executing step by step the script, in order to check the status of the script. The default value is `$false`

- `$ProductName`, which is the name of your _Product_, that is the name of your database folder into the workspace (we use `Product.DatabaseScope`, for example `DamnTools.TodoExplorerDB`)

- `$databasesPath`, which is the mdf/ndf/ldf path for the database (in development lines we don't care about using different paths)

- `$DB<n>Scope`, which is the name of the database without the _branch_ suffix (mandatory when you have server branches on TFS/VSTS or SVN). You need to create a scope for each database you want to link

- `$DB<n>CreationScript`, which is the script for creating the database, related to the previous variable

- `$databases`, which is the array of the databases you'd like to link to the Source Control. This is hard coded, but you can change it (please contribute) reading, for example, from a json array or an API.

The hard coded variables are:

- `$socPath`, which is the installation path of the SoC (Red Gate Source Control), typically `%LOCALAPPDATA%\Red Gate\SQL Source Control <version>\"`

- `$SQLComparePath`, which is the path of the SQL Compare installation (or the dependency folder if you distribute only the dlls and executables), please read [here](https://documentation.red-gate.com/sc13/licensing/changes-to-distribution-of-command-line)

- `$SQLDataComparePath`, which is the path of the SQL Data Compare installation (or the dependency folder if you distribute only the dlls and executables), please read [here](https://documentation.red-gate.com/sc13/licensing/changes-to-distribution-of-command-line)

- `$SqlToolbeltLicenseSerialNumber`, which is the license number (you can leave it empty if you'll use the executable from your licensed installation of the comparison tools)

- `$hooksPath`, which is the working folder/git hooks configuration file for `WorkingFolder.xml` and `Git.xml`

- `$xmlConfigurationsFilePath`, which is the configuration file for the linked databases, called `LinkedDatabases.xml`

## How it works

The tool is based upon a Red Gate SQL Source Control installation. It changes automatically the `LinkedDatabases.xml` file, adding the databases you're working on and simulate the manual behavior for linking databases to Source Control via SSMS. At the end of the script execution, you will get also a set of Transient and Working base folders. In order to undersand better how SQL Source Control works behind the scenes, please read [this guide](https://documentation.red-gate.com/soc6/reference-information/how-sql-source-control-works-behind-the-scenes).
Once you execute the PowerShell, you need to fill in the SERVER/INSTANCE name, then, you've to choose which databases you want to link to the Source Control (0 all databases, 1 --> n a single database).

This is the pipeline:

- check for any running SSMS

  - if SSMS is running, an error message is returned

  - else, the script continues

- prompt for SERVER/INSTANCE name (in case of default instance, the default one is used and you can leave this value blank)

- based on the option you choose (0 or 1 --> n) a loop starts, doing the following tasks for each database:

  - removal of the datrabase node from `LinkedDatabases.xml` using the `RemoveAndSaveXmlConfiguration` function

  - removal of the _under the hood_ folders of the the database (WorkingBase and Transient, if they exist) using the `RemoveWorkingBaseAndTransientFolders` function

  - drop of the database (if exists) with the `DropDatabaseIfExists` function

  - creation of the database with the `CreateDatabaseFromScript` function, using the scripts provided by you (there's an example in the zip file in this repo)

  - creation of the _under the hoods_ folders with the `CreateWorkingBaseAndTransientFolders` function

  - creation of the database node into the `LinkedDatabases.xml` file using the `AddAndSaveXmlConfiguration` function

  - creation of the `Filters.scpf`, `RedGateDatabaseInfo.xml`, `RedGate.ssc` files into the _under the hood_ folders using the `GeneratingWorkingBaseAndTransient` function

  - __optionally__ get of the latest structures with the `GetLatestDatabaseStructure` function

  - __optionally__ get of the latest data with the `GetLatestDatabaseData` function

## Additional notes

When the script tries to get the structures and data from the source control, it runs the SQL Compare and SQL Data Compare executables, diff-ing the workspaces and the destination databases. The SQL Comparison tools need a license activation. So, __keep in mind that you cannot execute it without a trial or a licensed version of the Comparison tools__ or the Red Gate SQL Toolbelt. For more details, please read [here](https://suxstellino.wordpress.com/2016/06/28/automatically-link-databases-to-red-gate-sql-source-control/).
However, the other scripts work also without the _getting of the latest version_. This means that you have to do it manually. With the license, you can leave the script as is, attaching also other stuff like a load data script as well as any other database related tasks.

If you want to avoid any get, you've to comment the last section of the loop, as described in the following snippet:

```powershell
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

In order to start using the tool, you can read [my blog post here](https://alessandroalpi.blog/2016/06/28/automatically-link-databases-to-red-gate-sql-source-control/).
As you may noticed, there is a compressed folder into the repo. Inside it there are three sample folders (the databases with the `Product.DatabaseScope`) and three sql script for creating the databases. Then, the Powershell script itself, which is the copy of the `ps1` you can find on the root of the repository.
You can execute the script within ISE or any other Powershell tool (Visual Studio Code suggested), or create a batch file which executes the Powershell itself.

In order to consume also the comparison tools, you have to create a `Dependencies` folder in which you have to put the redistributable files, as described [here](https://documentation.red-gate.com/sc13/licensing/changes-to-distribution-of-command-line) for SQL Compare and [here](https://documentation.red-gate.com/sdc13/using-the-command-line/integrating-the-command-line-with-applications) for SQL Data Compare. The script will look by default to a sub-folder with that name, but you can customize the path.

## Please Contribute

Feel free to fork and contribute and to send us pull requests. We'd like to improve this solution. However, check for the currently active issues [here](https://github.com/EngageITServices/SOCAutoLinkDatabasesWorkingFolder/issues).

## A special thanks to

Many thanks to Red Gate for its great support. I'd like to thanks [David Atkinson](https://twitter.com/dtabase), [Alex Yates](https://twitter.com/_alexyates_) and Michael Upton for the [repo](https://github.com/MatthewFlatt/SOCAutoLinkDatabases) I've used to start with this implementation.
