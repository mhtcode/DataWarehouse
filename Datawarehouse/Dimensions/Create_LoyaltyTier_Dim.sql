CREATE TABLE [DW].[DimLoyaltyTier] (
    [LoyaltyTierKey]    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [LoyaltyTierID]     INT NOT NULL,
    [Name]              NVARCHAR(255) NULL,
    [MinPoints]         INT            NULL,
    [Benefits]          NVARCHAR(255) NULL,
    [EffectiveFrom]     DATETIME       NOT NULL,
    [EffectiveTo]       DATETIME       NULL,
    [MinPointsIsCurrent] BIT           NOT NULL
);
GO

