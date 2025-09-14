-- simple logger
local function logToFile(message, fileName)
	fileName = fileName or "storage_log.txt" -- default file
	local file = io.open(fileName, "a") -- open for append
	if file then
		file:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. tostring(message) .. "\n")
		file:close()
	else
		print("Failed to open log file: " .. fileName)
	end
end

return logToFile
