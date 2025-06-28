CREATE TABLE [DW].[DimPointConversionRate] (
    ConversionRateKey      INT IDENTITY(1,1) PRIMARY KEY,   -- Surrogate Key
    PointConversionRateID  INT,                    -- Business Key from SA
    Rate                   DECIMAL(18,6),
    Currency               NVARCHAR(255),
    EffectiveFrom          DATETIME ,
    EffectiveTo            DATETIME NULL,
    IsCurrent              BIT 
);
GO

CREATE NONCLUSTERED INDEX IX_DimPointConversionRate_BusinessKey_SCD
ON [DW].[DimPointConversionRate] (PointConversionRateID, EffectiveFrom, EffectiveTo);
GO

CREATE NONCLUSTERED INDEX IX_DimPointConversionRate_Currency
ON [DW].[DimPointConversionRate] (Currency);
GO

CREATE NONCLUSTERED INDEX IX_DimPointConversionRate_IsCurrent
ON [DW].[DimPointConversionRate] (IsCurrent)
WHERE IsCurrent = 1;
GO
