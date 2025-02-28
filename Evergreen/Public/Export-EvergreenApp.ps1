function Export-EvergreenApp {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline,
            HelpMessage = "Pass an application object from Get-EvergreenApp.")]
        [ValidateNotNull()]
        [System.Array] $InputObject,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Specify the path to the JSON file.",
            ParameterSetName = "Path")]
        [ValidateNotNull()]
        [System.IO.FileInfo] $Path
    )

    process {
        if (Test-Path -Path $Path) {
            # Add the new details to the existing file content
            $params = @{
                Path        = $Path
                ErrorAction = "Stop"
                Verbose     = $VerbosePreference
            }
            $Content = Get-Content @params | ConvertFrom-Json -ErrorAction "Stop"
            $InputObject += $Content
        }

        # Sort the content and keep unique versions
        $Properties = $InputObject | Get-Member | `
            Where-Object { $_.MemberType -eq "NoteProperty" } | Select-Object -ExpandProperty "Name" -Unique | `
            Sort-Object -Descending
        $OutputObject = $InputObject | Select-Object -Unique -Property $Properties

        # Export the data to file
        $OutputObject | Sort-Object -Property @{ Expression = { [System.Version] $_.Version }; Descending = $false } -ErrorAction "SilentlyContinue" | `
            ConvertTo-Json -ErrorAction "Stop" | `
            Out-File -FilePath $Path -Encoding "Utf8" -NoNewline -Verbose:$VerbosePreference

        if ($PSCmdlet.ShouldProcess($Path, "Output to pipeline")) {
            $Output = [PSCustomObject] @{
                Path = Resolve-Path -Path $Path
            }
            Write-Output -InputObject $Output
        }
    }
}
