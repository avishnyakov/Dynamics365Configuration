$dbHostName = $env:VMDEVOPSSTARTER_DBHOST;
if ( !$dbHostName ) { $dbHostName = $env:COMPUTERNAME }
$securedPassword = ConvertTo-SecureString "c0mp1Expa~~" -AsPlainText -Force
$CRMInstallAccountCredential = New-Object System.Management.Automation.PSCredential( "contoso\_crmadmin", $securedPassword );
$CRMServiceAccountCredential = New-Object System.Management.Automation.PSCredential( "contoso\_crmsrv", $securedPassword );
$DeploymentServiceAccountCredential = New-Object System.Management.Automation.PSCredential( "contoso\_crmdplsrv", $securedPassword );
$SandboxServiceAccountCredential = New-Object System.Management.Automation.PSCredential( "contoso\_crmsandbox", $securedPassword );
$VSSWriterServiceAccountCredential = New-Object System.Management.Automation.PSCredential( "contoso\_crmvsswrit", $securedPassword );
$AsyncServiceAccountCredential = New-Object System.Management.Automation.PSCredential( "contoso\_crmasync", $securedPassword );
$MonitoringServiceAccountCredential = New-Object System.Management.Automation.PSCredential( "contoso\_crmmon", $securedPassword );

try {
    Save-Dynamics365Resource -Resource CRM2016RTMSve -TargetDirectory C:\Install\Dynamics\CRM2016RTMSve
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red;
    Exit 1;
}
if ( Get-ChildItem C:\Install\Dynamics\CRM2016RTMSve ) {
    Write-Host "Test OK";
} else {
    Write-Host "Expected files are not found in C:\Install\Dynamics\CRM2016RTMSve, test is not OK";
    Exit 1;
}

try {
    Save-Dynamics365Resource -Resource CRM2016LanguagePackNor -TargetDirectory C:\Install\Dynamics\CRM2016LanguagePackNor
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red;
    Exit 1;
}
if ( Get-ChildItem C:\Install\Dynamics\CRM2016LanguagePackNor ) {
    Write-Host "Test OK";
} else {
    Write-Host "Expected files are not found in C:\Install\Dynamics\CRM2016LanguagePackNor, test is not OK";
    Exit 1;
}

try {
    Save-Dynamics365Resource -Resource CRM2016ServicePack2Update03Sve -TargetDirectory C:\Install\Dynamics\CRM2016ServicePack2Update03Sve
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red;
    Exit 1;
}
if ( Get-ChildItem C:\Install\Dynamics\CRM2016ServicePack2Update03Sve ) {
    Write-Host "Test OK";
} else {
    Write-Host "Expected files are not found in C:\Install\Dynamics\CRM2016LanguagePackNor, test is not OK";
    Exit 1;
}

try {
    Install-Dynamics365Server `
        -MediaDir C:\Install\Dynamics\CRM2016RTMSve `
        -LicenseKey WCPQN-33442-VH2RQ-M4RKF-GXYH4 `
        -CreateDatabase `
        -SqlServer $dbHostName\SQLInstance01 `
        -PrivUserGroup "CN=CRM01PrivUserGroup,OU=CRM groups,DC=contoso,DC=local" `
        -SQLAccessGroup "CN=CRM01SQLAccessGroup,OU=CRM groups,DC=contoso,DC=local" `
        -UserGroup "CN=CRM01UserGroup,OU=CRM groups,DC=contoso,DC=local" `
        -ReportingGroup "CN=CRM01ReportingGroup,OU=CRM groups,DC=contoso,DC=local" `
        -PrivReportingGroup "CN=CRM01PrivReportingGroup,OU=CRM groups,DC=contoso,DC=local" `
        -CrmServiceAccount $CRMServiceAccountCredential `
        -DeploymentServiceAccount $DeploymentServiceAccountCredential `
        -SandboxServiceAccount $SandboxServiceAccountCredential `
        -VSSWriterServiceAccount $VSSWriterServiceAccountCredential `
        -AsyncServiceAccount $AsyncServiceAccountCredential `
        -MonitoringServiceAccount $MonitoringServiceAccountCredential `
        -CreateWebSite `
        -WebSitePort 5555 `
        -WebSiteUrl https://$env:COMPUTERNAME.contoso.local `
        -Organization "Contoso Ltd." `
        -OrganizationUniqueName Contoso `
        -ReportingUrl http://$dbHostName/ReportServer_RSInstance01 `
        -InstallAccount $CRMInstallAccountCredential
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red;
    Exit 1;
}
$testScriptBlock = {
    try {
        Add-PSSnapin Microsoft.Crm.PowerShell -ErrorAction Ignore
        if ( Get-PSSnapin Microsoft.Crm.PowerShell -ErrorAction Ignore ) {
            $CrmOrganization = Get-CrmOrganization;
            $CrmOrganization.Version;
        } else {
            "Could not load Microsoft.Crm.PowerShell PSSnapin";
        }
    } catch {
        $_.Exception.Message;
        Exit 1;
    }
}
$testResponse = Invoke-Command -ScriptBlock $testScriptBlock $env:COMPUTERNAME -Credential $CRMInstallAccountCredential -Authentication CredSSP;
if ( $testResponse -eq "8.0.0.1088" )
{
    Write-Host "Test OK";
} else {
    Write-Host "Software installed version is '$testResponse'. Test is not OK"
    Exit 1;
}

try {
    if ( $dbHostName -eq $env:COMPUTERNAME ) {
        Install-Dynamics365ReportingExtensions `
            -MediaDir C:\Install\Dynamics\CRM2016RTMSve\SrsDataConnector `
            -InstanceName SQLInstance01 `
            -InstallAccount $CRMInstallAccountCredential
    } else {
        Install-Dynamics365ReportingExtensions `
            -MediaDir \\$env:COMPUTERNAME\c$\Install\Dynamics\CRM2016RTMSve\SrsDataConnector `
            -ConfigDBServer $dbHostName `
            -InstanceName SQLInstance01 `
            -InstallAccount $CRMInstallAccountCredential
    }
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red;
    Exit 1;
}
if ( $dbHostName -eq $env:COMPUTERNAME ) {
    $installedProduct = Get-WmiObject Win32_Product | ? { $_.IdentifyingNumber -eq "{0C524D71-141D-0080-BFEE-D90853535253}" }
} else {
    $installedProduct = Get-WmiObject Win32_Product -ComputerName $dbHostName -Credential $CRMInstallAccountCredential | ? { $_.IdentifyingNumber -eq "{0C524D71-141D-0080-BFEE-D90853535253}" }
}
if ( $installedProduct ) {
    Write-Host "Test OK";
} else {
    Write-Host "Expected software is not installed, test is not OK";
    Exit 1;
}

try {
    Install-Dynamics365Language -MediaDir C:\Install\Dynamics\CRM2016LanguagePackNor
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red;
    Exit 1;
}
$installedProduct = Get-WmiObject Win32_Product | ? { $_.IdentifyingNumber -eq "{0C524DC1-1414-0080-8121-88490F4D5549}" }
if ( $installedProduct ) {
    Write-Host "Test OK";
} else {
    Write-Host "Expected software is not installed, test is not OK";
    Exit 1;
}
if ( -not ( Get-PSSnapin -Name Microsoft.Crm.PowerShell -ErrorAction SilentlyContinue ) )
{
    Add-PSSnapin Microsoft.Crm.PowerShell
    $RemoveSnapInWhenDone = $True
}
Write-Host "$(Get-Date) Starting New-CrmOrganization";
$importJobId = New-CrmOrganization -Name ORGLANG1044 -BaseLanguageCode 1044 -Credential $CRMInstallAccountCredential -DwsServerUrl "http://$env:COMPUTERNAME`:5555/XrmDeployment/2011/deployment.svc" -DisplayName "Organization for testing 1044 language" -SqlServerName $dbHostName\SQLInstance01 -SrsUrl http://$dbHostName/ReportServer_RSInstance01;
do {
    $operationStatus = Get-CrmOperationStatus -OperationId $importJobId -Credential $CRMInstallAccountCredential -DwsServerUrl "http://$env:COMPUTERNAME`:5555/XrmDeployment/2011/deployment.svc";
    Write-Host "$(Get-Date) operationStatus.State is $($operationStatus.State). Waiting until CRM installation job is done";
    Sleep 60;
} while ( ( $operationStatus.State -ne "Completed" ) -and ( $operationStatus.State -ne "Failed" ) )
if ( $operationStatus.State -eq "Completed" ) {
    Write-Host "Test OK";
} else {
    Write-Host "Organization was not created properly";
    Exit 1;
}

try {
    Install-Dynamics365Update -MediaDir C:\Install\Dynamics\CRM2016ServicePack2Update03Sve -InstallAccount $CRMInstallAccountCredential
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red;
    Exit 1;
}
$testScriptBlock = {
    try {
        Add-PSSnapin Microsoft.Crm.PowerShell -ErrorAction Ignore
        if ( Get-PSSnapin Microsoft.Crm.PowerShell -ErrorAction Ignore ) {
            $CrmOrganization = Get-CrmOrganization;
            $CrmOrganization.Version;
        } else {
            "Could not load Microsoft.Crm.PowerShell PSSnapin";
        }
    } catch {
        $_.Exception.Message;
        Exit 1;
    }
}
$testResponse = Invoke-Command -ScriptBlock $testScriptBlock $env:COMPUTERNAME -Credential $CRMInstallAccountCredential -Authentication CredSSP
if ( $testResponse -eq "8.2.3.8" )
{
    Write-Host "Test OK";
} else {
    Write-Host "Software installed version is '$testResponse'. Test is not OK"
    Exit 1;
}

Exit 0;
