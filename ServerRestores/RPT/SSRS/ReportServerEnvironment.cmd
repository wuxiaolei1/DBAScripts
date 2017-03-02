net stop ReportServer
net start ReportServer

RSKeyMgmt -a -f \\ldssqlbproapp01\SQLBackup\VMRPTPRO1DBA01\VMRPTPRO1DBA01_ReportingServicesEncryptionKey -p W+HZ6_*$kF.j:4

net stop ReportServer
net start ReportServer

RS -i "%~dp0ReportServerEnvironment.rss" -s http://%COMPUTERNAME%/ReportServer -v Environment="%COMPUTERNAME:~0,4%" -e Mgmt2010
