--Script adds a named login to the DMS database in the daily environment for the next week
INSERT INTO EnvironmentAccess.dbo.LoginPermissions
        ( LoginName ,
          SQLLogin ,
          EnvironmentType ,
          Environment ,
          DatabaseName ,
          SysAdmin ,
          ViewDefinition ,
          DBOwner ,
          DataReader ,
          DataWriter ,
          AppRoleLevel ,
          StartDate ,
          EndDate
        )
VALUES  ( 'CCCSNT\Pleasecanihaveaccesstodaily' , -- LoginName - varchar(50)
          0 ,		-- SQLLogin - bit
          'DAILY' , -- EnvironmentType: 'DEV/TEST' or 'UAT/ANALYSIS' or 'SUPPORT' or 'DAILY'
          NULL ,	-- Environment:		'VM01'; 'VM02'; etc
          'DMS' ,	-- DatabaseName
          0 ,		-- SysAdmin			- 1 = Grant; 0 = Do not apply
          0 ,		-- ViewDefinition	- 1 = Grant; 0 = Do not apply
          0 ,		-- DBOwner			- 1 = Grant; 0 = Do not apply
          1 ,		-- DataReader		- 1 = Grant; 0 = Do not apply
          0 ,		-- DataWriter		- 1 = Grant; 0 = Do not apply
          0 ,		-- AppRoleLevel		- For future use
          '2013-10-02 11:21:37' ,	-- StartDate
          '2013-10-09 11:21:37'		-- EndDate
        )