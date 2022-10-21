@{
    Name     = "Shima"
    Shima    = @{
        TargetDirectories   = @(".\paths\Source")
        ArchiveDirectories  = @(".\paths\ArchiveDirectory")
        InvalidFilesArchDir = ".\paths\InvalidFilesArch"
        OutDirectories      = @(".\paths\OutDirectory")
    }
    Services = @{
        LogProvider = @{
            LogDirectory      = ".\logs"
            LogFilenameFormat = '${shortdate}.log'
        } 
    }
}