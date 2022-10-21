using namespace System.IO
using namespace System.Text

$DebugPreference = 'Continue'
Set-StrictMode -Version 'latest'

enum ParseState {
	Start
	IdOpen
	TestNameOpen
	TitleOpen
	Finish
}

class Shima {

	[string[]]$TargetDirectories
	[string]$InvalidFilesArchDir
	[string[]]$ArchiveDirectories
	[string[]]$OutDirectories

	[ShimaFile[]]$ShimaFiles

	Shima([hashtable]$Conf) {
		$this.TargetDirectories = $Conf.TargetDirectories
		$this.ArchiveDirectories = $Conf.ArchiveDirectories
		$this.InvalidFilesArchDir = $Conf.InvalidFilesArchDir
		$this.OutDirectories = $Conf.OutDirectories
	}

	LoadFiles () {
		foreach ($dir in $this.TargetDirectories) {
			foreach ($file in [directory]::GetFiles($dir, "*.*")) {
				$shimaFile = [ShimaFile]::new($file)
				$this.ShimaFiles += , $shimaFile
			}
		}
	}

	Export () {
		foreach ($shimaFile in $this.ShimaFiles) {
			foreach ($dir in $this.OutDirectories) {
				$outFilename = [Path]::join($dir, ("r_{0}" -f [path]::GetFileName($shimaFile.FileName)))
				[file]::WriteAllText($outFilename, $shimaFile.GetText())
				$Global:Services.Logger.Info("Shima file $($shimaFile.FileName) export to file $outFilename")
			}
			foreach ($dir in $this.ArchiveDirectories) {
				$outFilename = [Path]::join($dir, [path]::GetFileName($shimaFile.FileName))
				[file]::Copy($shimaFile.FileName, $outFilename)
				$Global:Services.Logger.Info("Shima file $($shimaFile.FileName) archived to file $outFilename")
			}
			[file]::Delete($shimaFile.FileName)
		}
	}
}

class ShimaFile {

	[ParseState]$State = [ParseState]::Start
	[string]$FileName 
	[string]$OpenTestName
	[ShimaResult[]]$ShimaResults

	ShimaFile ([string]$FileName) {

		$this.FileName = $FileName
		$this.State = [ParseState]::Start

		foreach ($line in [file]::ReadAllLines($FileName)) {
			$this.ParseLine($line)
		}
	}

	ParseLine([string]$line) {

		switch ($this.State) {
			
			([ParseState]::Start) {
			
				if ($line.StartsWith('ID#')) {
					$this.State = $this.State = [ParseState]::IdOpen
				}
			}

			([ParseState]::IdOpen) {

				if ($line.StartsWith('Name	')) {
					$this.State = $this.State = [ParseState]::TestNameOpen
					$splits = $line.Split("`t")
					if ($splits.Count -eq 2) {
						$this.OpenTestName = $splits[1]
					}
					else {
						throw "Test name parser error, $line"
					}
				}
				else {
					throw "Testname parese error, $line"
				}

			}

			([ParseState]::TestNameOpen) {
				
				if ($line.StartsWith('	Data Filename')) {
					$this.State = $this.State = [ParseState]::TitleOpen
				}
				else {
					throw "Table title parese error, $line"
				}
				
			}

			([ParseState]::TitleOpen) {
				if ($line -eq "") {
					$this.State = [ParseState]::Start
					break
				}
				$splits = $line.Split("`t")
				if ($splits[3] -match "\d{10}") {
					$this.ShimaResults += , [ShimaResult]@{
						Accession  = $splits[3]
						TestName   = $this.OpenTestName
						TestResult = $splits[4]
					}
				}
			}
			Default {
				throw "Unknown state"
			}
		}
	}

	[string] GetText () {

		if ($this.ShimaResults.Count -eq 0) { throw '$this.ShimaResults.Count is 0' }

		$sb = [StringBuilder]::new()

		$sb.AppendLine("Accession,TestName,TestResult")

		foreach ($testResult in $this.ShimaResults) {
			$sb.AppendFormat("{0},{1},{2}`r`n", $testResult.Accession, $testResult.TestName, $testResult.TestResult)
		}

		return $sb.ToString()
	}
}

class ShimaResult {
	[string]$Accession
	[string]$TestName
	[string]$TestResult
}