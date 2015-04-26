################### DESCRIPTION ###########
## DEVELOPER: AARON JACKSON
## DATE: 08/04/2015
## DESC: This script will create SQL insert scripts
################## END DESCRIPTION ########

## TEST
# .\Copy_SQL_Table.ps1 -SrcServer "EQ3DBS05" -SrcDatabase "Acquisition" -SrcTable "[Control].[DataTypeCompatability]" -DestServer "EQ3WNPRDBDW01" -Truncate
##

################ VARIABLES #################
 
  Param ( 
      [parameter(Mandatory = $true)]  
      [string] $SrcServer, 
      [parameter(Mandatory = $true)]  
      [string] $SrcDatabase, 
      [parameter(Mandatory = $true)]  
      [string] $SrcTable, 
      [parameter(Mandatory = $true)]  
      [string] $DestServer, 
      [string] $DestDatabase,
      [string] $DestTable,
      [switch] $Truncate 
  ) 
 
  Function ConnectionString([string] $ServerName, [string] $DbName)  
  { 
    "Data Source=$ServerName;Initial Catalog=$DbName;Integrated Security=True;" 
  } 
 
 
  ########## Main body ############  
  If ($DestDatabase.Length –eq 0) { 
    $DestDatabase = $SrcDatabase 
  } 
 
  If ($DestTable.Length –eq 0) { 
    $DestTable = $SrcTable 
  } 
 
  If ($Truncate) {  
    $TruncateSql = "TRUNCATE TABLE " + $DestTable 
    Sqlcmd -S $DestServer -d $DestDatabase -Q $TruncateSql 
  } 
 
  $SrcConnStr = ConnectionString $SrcServer $SrcDatabase 
  $SrcConn  = New-Object System.Data.SqlClient.SQLConnection($SrcConnStr) 
  $CmdText = "SELECT * FROM " + $SrcTable + " WITH (NOLOCK);"
  $SqlCommand = New-Object system.Data.SqlClient.SqlCommand($CmdText, $SrcConn)   
  $SrcConn.Open() 
  [System.Data.SqlClient.SqlDataReader] $SqlReader = $SqlCommand.ExecuteReader() 
 
  Try 
  { 
    $DestConnStr = ConnectionString $DestServer $DestDatabase 
    $bulkCopy = New-Object Data.SqlClient.SqlBulkCopy($DestConnStr, [System.Data.SqlClient.SqlBulkCopyOptions]::KeepIdentity) 
    $bulkCopy.DestinationTableName = $DestTable
    $bulkCopy.BatchSize = 10000 # write 10,000 records at a time
    $bulkCopy.BulkCopyTimeout = 0 #no timeout
    $bulkCopy.WriteToServer($sqlReader) 
  } 
  Catch [System.Exception] 
  { 
    $ex = $_.Exception 
    Write-Host $ex.Message 
  } 
  Finally 
  { 
    Write-Host "Table $SrcTable in $SrcDatabase database on $SrcServer has been copied to table $DestTable in $DestDatabase database on $DestServer" 
    $SqlReader.close() 
    $SrcConn.Close() 
    $SrcConn.Dispose() 
    $bulkCopy.Close() 
  } 