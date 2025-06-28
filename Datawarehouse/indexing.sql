CREATE NONCLUSTERED INDEX IX_DimPerson_BusinessKey_SCD
ON DW.DimPerson (PersonID, EffectiveFrom, EffectiveTo);