-- Run on the jumpbox as the SQL Entra admin (the jumpbox's managed identity):
-- sqlcmd -S <server>.database.windows.net -d ordersdb --authentication-method ActiveDirectoryManagedIdentity -i sql-grant-orders.sql
-- Uses the identity's CLIENT ID to build its SID, so no Entra directory lookup is needed.
DECLARE @sid NVARCHAR(100) = CONVERT(NVARCHAR(100), CONVERT(VARBINARY(16), CONVERT(UNIQUEIDENTIFIER, '39836b7a-3623-4576-86a0-fef514dd3bb0')), 1);
EXEC('CREATE USER [id-orders-nimbus-cin] WITH SID = ' + @sid + ', TYPE = E');
ALTER ROLE db_datareader ADD MEMBER [id-orders-nimbus-cin];
ALTER ROLE db_datawriter ADD MEMBER [id-orders-nimbus-cin];
ALTER ROLE db_ddladmin   ADD MEMBER [id-orders-nimbus-cin];
