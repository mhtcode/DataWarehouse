CREATE TABLE [DW].[DimCrew] (
  [Crew_ID] INT PRIMARY KEY,
  [NAT_CODE] nvarchar(255),
  [Name] nvarchar(255),
  [Phone] nvarchar(255),
  [Email] nvarchar(255),
  [Address] nvarchar(255),
  [City] nvarchar(255),
  [Country] nvarchar(255),
  [Date_Of_Birth] date,
  [Gender] nvarchar(255),
  [Postal_Code] nvarchar(255),
  [Role] nvarchar(255)
)
GO

CREATE NONCLUSTERED INDEX IX_DimCrew_Role
ON [DW].[DimCrew] (Role);
GO

CREATE NONCLUSTERED INDEX IX_DimCrew_Country_City
ON [DW].[DimCrew] (Country, City);
GO

CREATE NONCLUSTERED INDEX IX_DimCrew_Name
ON [DW].[DimCrew] (Name);
GO

CREATE NONCLUSTERED INDEX IX_DimCrew_NAT_CODE
ON [DW].[DimCrew] (NAT_CODE);
GO
