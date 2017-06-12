SELECT  [TestSchema] ,
        [TestName] ,
        [TestType] ,
        [ExpectedErrorNumber] ,
        [TestCreated]
FROM    [Admin].[TestCoverage]
WHERE   [TestCreated] = 0
        AND [TestSchema] != 'AdminTests'
        AND [TestSchema] != 'AuditTests'
        AND NOT ([TestSchema] = 'WebServiceTests'
                 AND [TestType] = 'NULL Test'
                )
        AND [TestName] NOT IN (
        'test NoteUniqueIDsUQ_NoteUniqueIDs_CommonID_NoteUniqueTypeID') -- Excluded tests
ORDER BY [TestType] ,
        [TestSchema] ,
        [TestName];
