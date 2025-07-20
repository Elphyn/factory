local githubUser = "Elphyn"
local repoName = "factory"
local branch = "main"

local function fetchFile(path, savePath)
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s",
        githubUser, repoName, branch, path
    )
    local res = http.get(url)
    if not res then return false end

    local data = res.readAll()
    res.close()

    local file = fs.open(savePath or path, "w")
    file.write(data)
    file.close()
    return true
end

local function updateAll()
    local manifestURL = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/manifest.txt",
        githubUser, repoName, branch
    )

    local res = http.get(manifestURL)
    if not res then
        print("Failed to fetch manifest.")
        return
    end

    local lines = res.readAll()
    res.close()

    for line in lines:gmatch("[^\r\n]+") do
        print("Updating:", line)
        if fetchFile(line) then
            print("-> Success")
        else
            print("-> Failed")
        end
    end
end

updateAll()