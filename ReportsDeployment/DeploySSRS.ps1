CLS
#*******************************************#
# Initialise Variables
# Environment - Can be bin\Debug or Release
#*******************************************#
$targetServer = "VM02RPTPRODBA01"
$projectname = "Common Reports-CPF BACS"
$reportnames = @("CPFData","DisbursementTotals")

# DO NOT CHANGE AFTER THIS LINE #
$environment = "bin\Debug"
$warnings = $null
$newDataSourcePath= "/Data Sources/"

#*******************************************#
# Create Report Destination Folders
# Get the target directory from the Project File
# Get the target server from the Project File
#*******************************************#


$projectfileLocation = $projectname + "/bin/DebugLocal/*.rptproj"

Get-ChildItem  $projectfileLocation | ForEach-Object {
[XML]$ProjectFile = Get-Content -Path $_

$targetFolderPath = $ProjectFile.SelectNodes("//Options") | Where-Object {$_.OutputPath -eq $environment} | %{$_.TargetFolder}
$targetServer = "http://" + $targetServer + "/ReportServer"
}

#Report Server Address
$reportServerUri = $targetServer + "/ReportService2010.asmx?wsdl"
Write-Host -fore Green "Deploying reports to " $reportServerUri

#Create Connection to SSRS
$rs = New-WebServiceProxy -Uri $reportServerUri -UseDefaultCredential #-Namespace "SSRS"

#Create Folder 
$targetParentFolder = "/"
$targetFolderPath.Split("{/}", [System.stringSplitOptions]::RemoveEmptyEntries) | 


Foreach-Object{

try
{
	$rs.CreateFolder($_, $targetParentFolder,  $null)
	Write-Host -fore Green "Created new folder: $_"
}
catch [System.Web.Services.Protocols.SoapException]
{
	if ($_.Exception.Detail.InnerText -match "[^rsItemAlreadyExists400]")
	{
		Write-Host -fore Yellow "Folder: $_ already exists."
	}
	else
	{
		$msg = "Error creating folder: $_. Msg: '{0}'" -f $_.Exception.Detail.InnerText
		Write-Error $msg
	}
}
$targetParentFolder = $targetParentFolder + $_

 }
 

#*******************************************#
# Create Reports
# get the directory for reports
# Overwrite if exists
#*******************************************#

Foreach ($reportName in $reportnames)
{ 
	$reportnamepath = $PSScriptRoot + "\" + $projectname + "\Bin\" + $reportName + ".rdl"
    $bytes = [System.IO.File]::ReadAllBytes($reportnamepath)

    Write-Output "Uploading report ""$reportName"" to ""$targetFolderPath""..."
    $report = $rs.CreateCatalogItem(
        "Report",         # Catalog item type
        $reportName,      # Report name
        $targetFolderPath,# Destination folder
        $true,            # Overwrite report if it exists?
        $bytes,           # .rdl file contents
        $null,            # Properties to set.
        [ref]$warnings)   # Warnings that occured while uploading.

    $warnings | ForEach-Object {
        Write-Output ("Warning: {0}" -f $_.Message)
		
		
		#*******************************************#
		# Update Shared Data Sources
		#*******************************************#
							
		$reportPath = $targetFolderPath + "/" + $reportName
	
		$dataSources = $rs.GetItemDataSources($reportPath)
		$dataSources | ForEach-Object {
		
		$newDataSourceName = $_.Name
		$newDataSourcePath = "/Data Sources/" + $newDataSourceName
		$proxyNamespace = $_.GetType().Namespace
		$myDataSource = New-Object ("$proxyNamespace.DataSource")
		$myDataSource.Name = $newDataSourceName
		$myDataSource.Item = New-Object ("$proxyNamespace.DataSourceReference")
		$myDataSource.Item.Reference = $newDataSourcePath


		$_.item = $myDataSource.Item

		$rs.SetItemDataSources($reportPath, $_)

		Write-Host "Report's DataSource Reference ($($_.Name)): $($_.Item.Reference)"
		}
    }

}
			


