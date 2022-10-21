using namespace NLog
using namespace NLog.Config
using namespace Nlog.Targets
using namespace System.IO

class LogProvider {

    hidden [Logger]$Logger

    LogProvider($conf){

        $LoggingConfiguration = [LoggingConfiguration]::new()

        $FileTarget = [FileTarget]::new('logfile')
        $FileTarget.FileName = [Path]::Join([Path]::GetFullPath($conf.logDirectory), $conf.LogFilenameFormat)  

        $ConsoleTarget = [ConsoleTarget]::new("console")

        $LoggingConfiguration.AddRule([LogLevel]::Info, [LogLevel]::Fatal, $FileTarget)
        $LoggingConfiguration.AddRule([LogLevel]::Info, [LogLevel]::Fatal, $ConsoleTarget)
    
        [LogManager]::Configuration = $LoggingConfiguration

        $this.Logger = [LogManager]::GetLogger('logger') 
    }

    Info ($Msg) {
        $this.Logger.Info($msg)
    }
}