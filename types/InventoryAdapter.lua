
--- @alias errPeripheral
--- | "local peripheral unreachable"
--- | "remote peripheral unreachable"
---
--- @class StorageComponentUnlimited
--- @field name string peripheral name
--- @field new fun(p_name: string): StorageComponentUnlimited
--- @field checkType fun(p_name: string): boolean
--- @field getItems fun(self: table): table<itemName, itemCount>,  errPeripheral | nil
