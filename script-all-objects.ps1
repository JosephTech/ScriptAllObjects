#Powershell Script
#Scripts out all tables, views, user defined functions and stored procs from target db
#Use to grab a quick snapshot of the database state into SVN after release

#Parameters:
#1 : ServerName
#2 : DatabaseName
#3 : AccountName
#4 : Password

param(
	[Parameter(Mandatory=$True,Position=1)]
	$ServerName,
	[Parameter(Mandatory=$True,Position=2)]
	$databaseName,
	[Parameter(Mandatory=$True,Position=3)]
	$dbUser,
	[Parameter(Mandatory=$True,Position=4)]
	$dbPassword
)

"Scripting with following parameters: Server=$ServerName DB=$databaseName User=$dbUser PWD=$dbPassword"


[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')

$serverInstance = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $ServerName
$serverInstance.ConnectionContext.LoginSecure = $false
$serverInstance.ConnectionContext.set_Login($dbUser)
$SqlUPwd = ConvertTo-SecureString $dbPassword -AsPlainText -Force 

$serverInstance.ConnectionContext.set_SecurePassword($SqlUpwd)


$dbs=$serverInstance.Databases
$invocation = (Get-Variable MyInvocation).Value
$dbpath = Split-Path $invocation.MyCommand.Path
$dbpath += "\"
Write-Host $dbpath

foreach ($db in $dbs | where-object {$_.name -eq $databaseName})
{
       $dbname = "$db".replace("[","").replace("]","")	   
	   Write-Host $dbname
	   
	   $IncludeTypes = @("Tables","StoredProcedures","UserDefinedFunctions","Views")		
	   $ExcludeSchemas = @("sys","Information_Schema")

		$so = new-object ('Microsoft.SqlServer.Management.Smo.ScriptingOptions')
		$so.IncludeIfNotExists = 0
		$so.SchemaQualify = 1
		$so.AllowSystemObjects = 0
		$so.ScriptDrops = 0 
		$so.IncludeHeaders = 0
		$so.Indexes = 1
		$so.DriAll = 1
		$so.Permissions = 1
		$so.Triggers = 1
	   
		foreach($type in $IncludeTypes)
		{
			$typeSuffix = $type.Substring(0, $type.Length-1)
			Write-Host $typeSuffix
			$objpath = "$dbpath" + "$Type" + "\"
			if(!(Test-Path $objpath))
			{
				$null = new-item -type directory -name "$type" -path $dbpath
			}
			
			if (!(Test-Path $dbpath))			
			{
				$null=new-item -type directory -name "$dbname"-path "$path"
			}
			
			foreach($obj in $db.$type)
			{
				if($ExcludeSchemas -notcontains $obj.Schema)
				{
					$ObjName = "$obj".replace("[","").replace("]","") 
					$OutFile = "$objpath" + "$ObjName" + "." + "$typeSuffix" + ".sql"
					Write-Host $OutFile
					$obj.Script($so)+"GO" | out-File $OutFile #-Append					
				}
			}
		}
}
