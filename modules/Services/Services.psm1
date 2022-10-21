using module ../LogProvider/LogProvider.psm1

Set-StrictMode -Version "Latest"

class Services {
    [LogProvider]$Logger

    Services($Conf){
        $this.Logger = [LogProvider]::new($Conf.LogProvider)
    }
}