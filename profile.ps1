#region Basic

# Relax the code signing restriction so we can actually get work done
try { Set-ExecutionPolicy RemoteSigned Process } catch [PlatformNotSupportedException] { $_ }

# Override environment variable HOME to Powershell automatic variable to avoid loading global .gitconfig from HOMESHARE
if ( $null -eq $env:HOME ) { Set-Item Env:\HOME $HOME }

# Powershell profile directory variable
Set-Variable -Name PSProfileDirectory -Value (( [Environment]::GetFolderPath( 'MyDocuments' )) + '\WindowsPowershell' ) -Scope Global -Option AllScope, Constant -EA 0

# Add PSDefaultParameterValues
if ( $PSVersionTable.PSVersion.Major -ge 3 ) {
    if ( $PSDefaultParameterValues.Keys -notcontains 'Format-Table:Autosize' ) {
        #insert Default Parameter Values for every command
        $PSDefaultParameterValues.Add( 'Format-Table:Autosize', $True )
    }
    if ( $PSDefaultParameterValues.Keys -notcontains 'Export-Csv:NoTypeInformation' ) {
    	$PSDefaultParameterValues.Add( 'Export-Csv:NoTypeInformation', $True )
    }
}

# MicrosoftAccountID aka LiveID
$MicrosoftAccountIDValue =  ( [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups | ? Value -match "^S-1-11-96" | % Translate([System.Security.Principal.NTAccount]) | % Value )
if ( $MicrosoftAccountIDValue ) { Set-Variable -Name MicrosoftAccountID -Value $MicrosoftAccountIDValue -Option ReadOnly -EA 0 }

# Create Missing Registry Drives
New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS -EA 0 | Out-Null
New-PSDrive -Name HKCR -PSProvider Registry -Root Registry::HKEY_CLASSES_ROOT -EA 0 | Out-Null
New-PSDrive -Name HKCC -PSProvider Registry -Root Registry::HKEY_CURRENT_CONFIG -EA 0 | Out-Null

# Check admin rights
function Test-Elevation {
    $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal( $windowsIdentity )
    $WindowsBuiltInRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $windowsPrincipal.IsInRole( $WindowsBuiltInRole )
}

if ( Test-Elevation ) {
    if (( Get-ItemProperty -Path HKCR:\Microsoft.PowerShellScript.1\Shell\0 -Name 'Icon' -EA 0 ).Icon -ne 'imageres.dll,73' ) {
        New-ItemProperty -Path HKCR:\Microsoft.PowerShellScript.1\Shell\0 -Name 'Icon' -Value 'imageres.dll,73' -Force | Out-Null
        Set-ItemProperty -Path HKCR:\Microsoft.PowerShellScript.1\Shell\0\Command -Name '(Default)' -Value "`"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`" -NoProfile -NoExit -Command if(( Get-ExecutionPolicy ) -ne `'Bypass`' ) { Set-ExecutionPolicy Bypass -Scope Process -Force } ; & '%1'" -Force | Out-Null
    }
}

# Add ls as 'dir' alias for CMD
if ( !(Test-Path "$env:SystemRoot\system32\ls.bat" ) -and ( Test-Elevation )) {
    'dir %1' | Out-File -FilePath "$env:SystemRoot\system32\ls.bat" -Encoding default -Force
}

function Install-Chocolatey { Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) }

#endregion

#region Modules

# These will get loaded automatically, but it's faster to load them explicitly all at once
Import-Module Microsoft.PowerShell.Management, Microsoft.PowerShell.Security, Microsoft.PowerShell.Utility -Verbose:$false
function Import-TabModule { Import-Module TabExpansionPlusPlus -Verbose:$false -EA 0 }
if ( Test-Path ( "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" )) { Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -Verbose:$false }
#if ( $Host.Name -eq 'Windows PowerShell ISE Host' ) { Import-Module PsISEProjectExplorer -Verbose:$false -EA 0 }
if ( $host.Name -eq 'ConsoleHost' ) { Import-Module PSReadline -Verbose:$false -EA 0 }

$env:path -split ';' | % {
    if ( Test-Path "$_\git.exe" ) {
		$GitInstalled = $true ; $env:PSModulePath -split ';' | % {
            if ( Test-Path "$_\posh-git" ) { $poshGitInstalled = $true }
			if ( Test-Path "$_\PSGit" ) { $PSGitInstalled = $true }
        }
		}
	if ( $GitInstalled -and $poshGitInstalled ) { Import-Module posh-git -Verbose:$false }
    if ( $GitInstalled -and $PSGitInstalled -and !$poshGitInstalled ) { Import-Module PSGit -Verbose:$false }
}

if ( !( $env:Path -split ';' | ? { $_ -like '*git\bin' } )) {
    if ( Test-Path D:\Programs\GitPortable\bin\git.exe ) { $env:Path = $env:Path + ';D:\Programs\GitPortable\bin;D:\Programs\GitPortable\cmd' }
}

if ( Test-Path "$env:ProgramFiles\Quest Software\Management Shell for AD\Quest.ActiveRoles.ADManagement.Format.ps1xml" ) {
    Add-PSSnapin Quest.ActiveRoles.ADManagement -EA 0
    Update-FormatData -PrependPath "$env:ProgramFiles\Quest Software\Management Shell for AD\Quest.ActiveRoles.ADManagement.Format.ps1xml"
}

#endregion

#region CurrentCustomer

function adm { msiwrapper /c pkginfo.ini /i adm }
function ins { msiwrapper /c pkginfo.ini /i ins }
function rem { msiwrapper /c pkginfo.ini /i rem }
function Import-VMware { Add-PsSnapin VMware.VimAutomation.Core -ea "SilentlyContinue" }

function Get-UBSConfigData { param( $UBSConfigVariable )
    $UBSConfigData = New-Object -ComObject UBSConfigAPI.ConfigData
    $UBSConfigData.EnumVal("Data", $UBSConfigVariable, 0, $Env:COMPUTERNAME, $NULL, 1)
}

#endregion

#region Alias

Set-Alias -Name 'gt' -Value 'Get-Type'
Set-Alias -Name 'im' -Value 'Import-Module'
Set-Alias -Name 'wc' -Value 'Write-Color'
Set-Alias -Name 'wd' -Value 'Write-Debug'
Set-Alias -Name 'we' -Value 'Write-Error'
Set-Alias -Name 'wh' -Value 'Write-Host'
Set-Alias -Name 'wo' -Value 'Write-Output'
Set-Alias -Name 'wp' -Value 'Write-Progress'
Set-Alias -Name 'wv' -Value 'Write-Verbose'
Set-Alias -Name 'ww' -Value 'Write-Warning'
Set-Alias -Name 'od' -Value 'Out-Default'
Set-Alias -Name 'of' -Value 'Out-File'
Set-Alias -Name 'os' -Value 'Out-String'
Set-Alias -Name 'tc' -Value 'Test-ExConnection'
Set-Alias -Name 'cn' -Value 'Get-ComputerName'
Set-Alias -Name 'hn' -Value 'Get-ComputerName'
Set-Alias -Name 'up' -Value 'Update-Profile'

if ( Get-Command Resolve-DnsName -EA 0 ) { Set-Alias -Name 'nslookup' -Value 'Deny-CMDCommands' }

Set-Alias -Name 'ping' -Value 'Deny-CMDCommands'
Set-Alias -Name 'hostname' -Value 'Deny-CMDCommands'

#endregion

#region VSCode

function Set-VSCodeSettings {
    $VSCodeSettingsPath = "$env:APPDATA\Code\User"
    $VSCodeInsidersSettingsPath = "$env:APPDATA\Code - Insiders\User"
    if ( !(Test-Path "$env:APPDATA\Code" )) { New-Item -Path $env:APPDATA -Name Code -ItemType Directory -EA 0 }
    if ( !(Test-Path "$env:APPDATA\Code\User" )) { New-Item -Path "$env:APPDATA\Code" -Name User -ItemType Directory -EA 0 }
    if ( !(Test-Path "$env:APPDATA\Code - Insiders" )) { New-Item -Path $env:APPDATA -Name "Code - Insiders" -ItemType Directory -EA 0 }
    if ( !(Test-Path "$env:APPDATA\Code - Insiders\User" )) { New-Item -Path "$env:APPDATA\Code - Insiders" -Name User -ItemType Directory -EA 0 }

    New-Item -ItemType SymbolicLink -Path $VSCodeSettingsPath -Name "settings.json" -Value "$PSProfileDirectory\settings.json"
    New-Item -ItemType SymbolicLink -Path $VSCodeInsidersSettingsPath -Name "settings.json" -Value "$PSProfileDirectory\settings.json"
}

#endregion

#region Git

Set-Alias -Name 'ggl' -Value 'Get-GitLog'
Set-Alias -Name 'ggls' -Value 'Get-GitLogShort'
Set-Alias -Name 'ggs' -Value 'Get-GitStatus'

function Set-GitConfigGlobal { Copy-Item $PSScriptRoot\.gitconfig--global -Destination "$env:USERPROFILE\.gitconfig" -Force }
function Get-GitLogShort { git log --oneline -n3 }
function Get-GitLog { git log --oneline }

function Rename-GitTag { param( $oldtag, $newtag )
    git tag $newtag $oldtag
    git tag -d $oldtag
    git push origin :refs/tags/$oldtag
    git push origin --tags
}
#endregion

#region Console

function Resize-Console { [cmdletbinding()]param(
    [int]$x = $host.ui.rawui.windowsize.width,
    [int]$y = $host.ui.rawui.windowsize.heigth,
    [int]$buffer = 5000
    )
    $windowSize = New-Object System.Management.Automation.Host.Size($x,$y)
    $bufferSize = New-Object System.Management.Automation.Host.Size($x,$buffer)
    $host.ui.rawui.BufferSize = $bufferSize
    $host.ui.rawui.WindowSize = $windowSize
}

$consoleFontCode = @"
public delegate bool SetConsoleFont(
    IntPtr hWnd,
    uint DWORD
);

public delegate uint GetNumberOfConsoleFonts();

public delegate bool GetConsoleFontInfo(
    IntPtr hWnd,
    bool BOOL,
    uint DWORD,
    [Out] CONSOLE_FONT_INFO[] ConsoleFontInfo
);

[StructLayout(LayoutKind.Sequential)]
public struct CONSOLE_FONT_INFO {
    public uint nFont;
    public COORD dwFontSize;
}

[StructLayout(LayoutKind.Sequential)]
public struct COORD {
    public short X;
    public short Y;
}

[DllImport("kernel32.dll")]
public static extern IntPtr GetModuleHandleA(
    string module
);

[DllImport("kernel32", CharSet=CharSet.Ansi, ExactSpelling=true, SetLastError=true)]
public static extern IntPtr GetProcAddress(
    IntPtr hModule,
    string procName
    );

[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetStdHandle(
    int nStdHandle
    );

[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetCurrentConsoleFont(
    IntPtr hConsoleOutput,
    bool bMaximumWindow,
    out CONSOLE_FONT_INFO lpConsoleCurrentFont
    );
"@
try { Add-Type -MemberDefinition $consoleFontCode -Name Console -Namespace Win32API -EA 0 | Out-Null
} catch { return }

Remove-Variable consoleFontCode

try { $z_hmod = [Win32API.Console]::GetModuleHandleA("kernel32")

"SetConsoleFont", "GetNumberOfConsoleFonts", "GetConsoleFontInfo" | % {
        $z_param = @()
        $z_proc = [Win32API.Console]::GetProcAddress($z_hmod, $_)
        $z_delegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($z_proc, "Win32API.Console+$_")
        $z_delegate.Invoke.OverloadDefinitions[0] -match "^[^(]+\((.*)\)" > $null
        $z_argtypes = $Matches[1] -split ", " | ? { $_ } | % {
                '[{0}] ${1}' -f ($_ -split ' ')
                $z_param += "$" + ($_ -split ' ')[-1]
        }
        $z_argtypes = $z_argtypes -join ", "
        $z_param = $z_param -join ", "
$z_expression = @"
            function $_($z_argtypes){
                `$$_ = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($z_proc, 'Win32API.Console+$_')
                `$$_.Invoke( $z_param )
            }
"@
Invoke-Expression $z_expression
}

$z_STD_OUTPUT_HANDLE = -11
$z_hConsoleScreen = [Win32API.Console]::GetStdHandle($z_STD_OUTPUT_HANDLE)

$z_DefaultFont = New-Object Win32API.Console+CONSOLE_FONT_INFO
[Win32API.Console]::GetCurrentConsoleFont($z_hConsoleScreen, $true, [ref]$z_DefaultFont) | Out-Null
} catch { Write-Error $_ }

function Get-ConsoleFontInfo {
    $_FontsNum = GetNumberOfConsoleFonts
    $_ConsoleFonts = New-Object Win32API.Console+CONSOLE_FONT_INFO[] $_FontsNum
    GetConsoleFontInfo $z_hConsoleScreen $false $_FontsNum $_ConsoleFonts > $null
    $_ConsoleFonts | Select-Object @{ Label = "nFont" ; Expression = { $_ConsoleFonts.Count-$_.nFont - 1 }},
    @{ Label = "dwFontSizeX" ; Expression = { $_.dwFontSize.X }}, @{ Label = "dwFontSizeY" ; Expression = { $_.dwFontSize.Y }} | Sort-Object nFont
}

function Set-ConsoleFont { [cmdletbinding()] param(
	[Parameter(position=0)][Uint32]
    $size = $z_DefaultFont.nFont,
	[IntPtr]$z_hWnd = $z_hConsoleScreen
    )
    $flag = SetConsoleFont $z_hWnd $size
    if ( !$flag ) { Get-ConsoleFontInfo ; throw "Illegal font index number. Check correct number using 'Get-ConsoleFontInfo'." }
}

#endregion

#region Custom Functions

function Get-FileEncoding {
<#
.SYNOPSIS
    Gets file encoding.
.DESCRIPTION
    The Get-FileEncoding function determines encoding by looking at Byte Order Mark (BOM).
    Based on port of C# code from http://www.west-wind.com/Weblog/posts/197245.aspx
.OUTPUTS
    System.Text.Encoding
.PARAMETER Path
    The Path of the file that we want to check.
.PARAMETER DefaultEncoding
    The Encoding to return if one cannot be inferred.
    You may prefer to use the System's default encoding:  [System.Text.Encoding]::Default
    List of available Encodings is available here: http://goo.gl/GDtzj7
.EXAMPLE
    # This command gets ps1 files in current directory where encoding is not ASCII
    Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {[string]$_.Encoding -ne 'System.Text.ASCIIEncoding'}
.EXAMPLE
    # Same as previous example but fixes encoding using set-content
    Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {[string]$_.Encoding -ne 'System.Text.ASCIIEncoding'} | foreach {(get-content $_.FullName) | set-content $_.FullName -Encoding ASCII}
.NOTES
    Version History
    v1.0   - 2010/08/10, Chad Miller - Initial release
    v1.1   - 2010/08/16, Jason Archer - Improved pipeline support and added detection of little endian BOMs. (http://poshcode.org/2075)
    v1.2   - 2015/02/03, VertigoRay - Adjusted to use .NET's [System.Text.Encoding Class](http://goo.gl/XQNeuc). (http://poshcode.org/5724)
.LINK
    http://goo.gl/bL12YV
#>
    [CmdletBinding()]
    param (
        [Alias("PSPath")]
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [String]$Path
        ,
        [Parameter(Mandatory = $False)]
        [System.Text.Encoding]$DefaultEncoding = [System.Text.Encoding]::ASCII
    )

    process {
        [Byte[]]$bom = Get-Content -Encoding Byte -ReadCount 4 -TotalCount 4 -Path $Path

        $encoding_found = $false

        foreach ($encoding in [System.Text.Encoding]::GetEncodings().GetEncoding()) {
            $preamble = $encoding.GetPreamble()
            if ($preamble) {
                foreach ($i in 0..$preamble.Length) {
                    if ($preamble[$i] -ne $bom[$i]) {
                        break
                    } elseif ($i -eq $preable.Length) {
                        $encoding_found = $encoding
                    }
                }
            }
        }

        if (!$encoding_found) {
            $encoding_found = $DefaultEncoding
        }

        $encoding_found
    }
}

function Set-PSGallery {
    if (( Get-PSRepository PSGallery ).InstallationPolicy -ne 'Trusted' ) {
        $Gallery = Get-PSRepository PSGallery
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -SourceLocation https://www.powershellgallery.com/api/v2/
        Set-PSRepository -Name PSGallery -InstallationPolicy $Gallery.InstallationPolicy
        }
}

function Set-EnvironmentVariable {
    #.Synopsis
    # Set an environment variable at the highest scope possible
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [String]$Name,

        [Parameter(Position=1)]
        [String]$Value,

        [System.EnvironmentVariableTarget]
        $Scope="Machine",

        [Switch]$FailFast
    )

    Set-Content "ENV:$Name" $Value
    $Success = $False
    do {
        try {
            [System.Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
            Write-Verbose "Set $Scope environment variable $Name = $Value"
            $Success = $True
        }
        catch [System.Security.SecurityException]
        {
            if($FailFast) {
                $PSCmdlet.ThrowTerminatingError( (New-Object System.Management.Automation.ErrorRecord (
                    New-Object AccessViolationException "Can't set environment variable in $Scope scope"
                ), "FailFast:$Scope", "PermissionDenied", $Scope) )
            } else {
                Write-Warning "Cannot set environment variables in the $Scope scope"
            }
            $Scope = [int]$Scope - 1
        }
    } while(!$Success -and $Scope -gt "Process")
}

function Get-LastBootUpTime { param(
    [Parameter( Mandatory = $true )][Alias( 'cn' )]
    [string[]]$ComputerName,
	[PSCredential] [System.Management.Automation.Credential()]$Credential
    )
    foreach ( $Computer in $ComputerName ) {
        $WmiHash = @{
            ComputerName = $Computer
            ErrorAction = 'Stop'
            Class = 'Win32_OperatingSystem'
        }
        if ( $Credential.Username -match '\S' ) {
            $WmiHash.Credential = $Credential
        }
        try {
            if ( $LastBootUpTime = Get-CimInstance @WmiHash | Select-Object -ExpandProperty LastBootUpTime -EA 0 ) {
                $LastBootUpTime = [Management.ManagementDateTimeConverter]::ToDateTime($LastBootUpTime)
                New-Object PSObject -Property @{
                    ComputerName = $Computer
                    LastBootUpTime = $LastBootUpTime
                    UpTime = [datetime]::Now - $LastBootUpTime
                }
            }
            else { Write-Warning -Message "Failed to retrieve last boot up time for $Computer (unknown failure)." }
        }
        catch { Write-Warning -Message "Failed to execute WMI query against ${Computer}: $($_.Exception.Message)" }
    }
}

function Get-IniContent {
    <#
    .Synopsis
        Gets the content of an INI file

    .Description
        Gets the content of an INI file and returns it as a hashtable

    .Notes
        Author        : Oliver Lipkau <oliver@lipkau.net>
        Blog        : http://oliver.lipkau.net/blog/
        Source        : https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version        : 1.0 - 2010/03/12 - Initial release
                      1.1 - 2014/12/11 - Typo (Thx SLDR)
                                         Typo (Thx Dave Stiff)

        #Requires -Version 2.0

    .Inputs
        System.String

    .Outputs
        System.Collections.Hashtable

    .Parameter FilePath
        Specifies the path to the input file.

    .Example
        $FileContent = Get-IniContent "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent

    .Example
        $inifilepath | $FileContent = Get-IniContent
        -----------
        Description
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent

    .Example
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"
        C:\PS>$FileContent["Section"]["Key"]
        -----------
        Description
        Returns the key "Key" of the section "Section" from the C:\settings.ini file

    .Link
        Out-IniFile
    #>

    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string]$FilePath
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"

        $ini = @{}
        switch -regex -file $FilePath
        {
            "^\[(.+)\]$" # Section
            {
                $section = $matches[1]
                $ini[$section] = @{}
                $CommentCount = 0
            }
            "^(;.*)$" # Comment
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = @{}
                }
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = "Comment" + $CommentCount
                $ini[$section][$name] = $value
            }
            "(.+?)\s*=\s*(.*)" # Key
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = @{}
                }
                $name,$value = $matches[1..2]
                $ini[$section][$name] = $value
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"
        Return $ini
    }

    End
        { Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended" }
}

function Out-IniFile {
    <#
    .Synopsis
        Write hash content to INI file

    .Description
        Write hash content to INI file

    .Notes
        Author        : Oliver Lipkau <oliver@lipkau.net>
        Blog        : http://oliver.lipkau.net/blog/
        Source        : https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version        : 1.0 - 2010/03/12 - Initial release
                      1.1 - 2012/04/19 - Bugfix/Added example to help (Thx Ingmar Verheij)
                      1.2 - 2014/12/11 - Improved handling for missing output file (Thx SLDR)

        #Requires -Version 2.0

    .Inputs
        System.String
        System.Collections.Hashtable

    .Outputs
        System.IO.FileSystemInfo

    .Parameter Append
        Adds the output to the end of an existing file, instead of replacing the file contents.

    .Parameter InputObject
        Specifies the Hashtable to be written to the file. Enter a variable that contains the objects or type a command or expression that gets the objects.

    .Parameter FilePath
        Specifies the path to the output file.

     .Parameter Encoding
        Specifies the type of character encoding used in the file. Valid values are "Unicode", "UTF7",
         "UTF8", "UTF32", "ASCII", "BigEndianUnicode", "Default", and "OEM". "Unicode" is the default.

        "Default" uses the encoding of the system's current ANSI code page.

        "OEM" uses the current original equipment manufacturer code page identifier for the operating
        system.

     .Parameter Force
        Allows the cmdlet to overwrite an existing read-only file. Even using the Force parameter, the cmdlet cannot override security restrictions.

     .Parameter PassThru
        Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.

    .Example
        Out-IniFile $IniVar "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini

    .Example
        $IniVar | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and overwrites the file if it is already present

    .Example
        $file = Out-IniFile $IniVar "C:\myinifile.ini" -PassThru
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and saves the file into $file

    .Example
	$Category1 = @{ Key1 = Value1 ; Key2 = Value2 }
    $Category2 = @{ Key1 = Value1 ; Key2 = Value2 }
    $NewINIContent = @{ Category1 =$Category1; Category2 =$Category2}
    Out-IniFile -InputObject $NewINIContent -FilePath "C:\MyNewFile.INI"
        -----------
        Description
        Creating a custom Hashtable and saving it to C:\MyNewFile.INI
    .Link
        Get-IniContent
    #>

    [CmdletBinding()]
    Param(
        [switch]$Append,

        [ValidateSet("Unicode","UTF7","UTF8","UTF32","ASCII","BigEndianUnicode","Default","OEM")]
        [Parameter()]
        [string]$Encoding = "Unicode",


        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^([a-zA-Z]\:)?.+\.ini$')]
        [Parameter(Mandatory=$True)]
        [string]$FilePath,

        [switch]$Force,

        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [Hashtable]$InputObject,

        [switch]$Passthru
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Filepath"

        if ($append) {$outfile = Get-Item $FilePath}
        else {$outFile = New-Item -ItemType file -Path $Filepath -Force:$Force}
        if (!($outFile)) {Throw "Could not create File"}
        foreach ($i in $InputObject.keys)
        {
            if (!($($InputObject[$i].GetType().Name) -eq "Hashtable"))
            {
                #No Sections
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $i"
                Add-Content -Path $outFile -Value "$i=$($InputObject[$i])" -Encoding $Encoding
            } else {
                #Sections
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$i]"
                Add-Content -Path $outFile -Value "[$i]" -Encoding $Encoding
                Foreach ($j in $($InputObject[$i].keys | Sort-Object))
                {
                    if ($j -match "^Comment[\d]+") {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $j"
                        Add-Content -Path $outFile -Value "$($InputObject[$i][$j])" -Encoding $Encoding
                    } else {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $j"
                        Add-Content -Path $outFile -Value "$j=$($InputObject[$i][$j])" -Encoding $Encoding
                    }

                }
                Add-Content -Path $outFile -Value "" -Encoding $Encoding
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Writing to file: $path"
        if ($PassThru) {Return $outFile}
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

function Add-AliasToCMD-LS { 'dir %1' | Out-File -FilePath "$env:SystemRoot\system32\ls.bat" -Encoding default -Force }

if (  !( Get-Command Microsoft.PowerShell.Archive\Expand-Archive )) {
	function Expand-Archive { param( $file, $destination )
		$shell = New-Object -ComObject Shell.Application
		$file = (Get-Item $file).FullName
		$zip = $shell.NameSpace($file)
		$zip.items() | % { $shell.Namespace($destination).copyhere($_, 0x14) }
	}
}

function Move-ChildItem { param($path, $destination)
	$files = Get-ChildItem $path
	$files | % {
		if ( $_ -is [System.IO.DirectoryInfo] ) {
			if ( !( Test-Path -Path "$destination\$_" )) { New-Item "$destination\$_" -ItemType Directory -Force | Out-Null }
			Move-ChildItem "$path\$_" "$destination\$_"
		} else { Move-Item -Path "$path\$_" -Destination $destination -Force }
	}
	Remove-Item $path
}

function Get-ADAcl { param([string]$name)
	Push-Location ad:
	(Get-Acl (Get-QADObject $name).DN).access | Select identityreference -Unique
	Pop-Location
}

function Get-ComputerName { Write-Color $env:COMPUTERNAME -ForegroundColor Yellow }

function Get-PersonalFolderPath { param( [switch]$AdminTools,[switch]$ApplicationData,[switch]$CDBurning,[switch]$CommonAdminTools,[switch]$CommonApplicationData,[switch]$CommonDesktopDirectory,[switch]$CommonDocuments,[switch]$CommonMusic,[switch]$CommonOemLinks,[switch]$CommonPictures,[switch]$CommonProgramFiles,[switch]$CommonProgramFilesX86,[switch]$CommonPrograms,[switch]$CommonStartMenu,[switch]$CommonStartup,[switch]$CommonTemplates,[switch]$CommonVideos,[switch]$Cookies,[switch]$Desktop,[switch]$DesktopDirectory,[switch]$Favorites,[switch]$Fonts,[switch]$History,[switch]$InternetCache,[switch]$LocalApplicationData,[switch]$LocalizedResources,[Alias('Documents')][switch]$MyDocuments,[Alias('Music')][switch]$MyMusic,[Alias('Pictures')][switch]$MyPictures,[Alias('Videos')][switch]$MyVideos,[switch]$NetworkShortcuts,[switch]$Personal,[switch]$PrinterShortcuts,[switch]$ProgramFiles,[switch]$ProgramFilesX86,[switch]$Programs,[switch]$Recent,[switch]$Resources,[switch]$SendTo,[switch]$StartMenu,[switch]$Startup,[switch]$System,[switch]$SystemX86,[switch]$Templates,[switch]$UserProfile,[switch]$Windows )
	[array]$params = $PsBoundParameters | % { $_.keys }
	$currentEAP = $ErrorActionPreference
	$ErrorActionPreference = 'SilentlyContinue'
	$params | % { [environment]::GetFolderPath("$_") }
	$ErrorActionPreference = $currentEAP
}

function Get-IPConfig { param( [Switch]$ip, [Switch]$MAC, [Switch]$all )
	Process {
		If ( $MAC ) { IPConfig.exe -all | Select-String 'IPv4','Physical' }
		ElseIf ( $ip ) { IPConfig.exe -all | Select-String 'IPv4' }
		ElseIf ( $all ) { IPConfig.exe -all }
		Else { IPConfig }
		}
	End { "`r`n" }
}

function Get-MemberDefinition { param(
	[Parameter(position=0,Mandatory=$true,ValueFromPipeline=$true)][Alias('Object')]$args,
    [Parameter(position=1)]$Name
	)
	process { if ( $Name ) { ( $args | Get-Member -Name $Name ).Definition } else { ( $args | Get-Member ) } }
}

function Get-PersonalFiles { param( [Parameter(position=0,ValueFromPipeline=$true)]$servers )
	if ( !$servers ) {
		$LDAPFilter = '(&(OperatingSystem=*Server*)(!(CanonicalName=*Infoscreenserver*)))'

		if ( ( Get-Command Get-QADComputer -EA 0) -eq $true ) {
			[array]$adComputers = ( Get-QADComputer -LDAPFilter $LDAPFilter -SecurityMask 'None' -DontUseDefaultIncludedProperties -IncludedProperties Name,OperatingSystem | ? { $_.OperatingSystem -match 'Server' } ).Name
		}
		if ( !$adComputers ) { Import-Module ActiveDirectory -Verbose:$false ; [array]$adComputers = (( Get-ADComputer -Filter * -Properties Name,OperatingSystem | ? { $_.OperatingSystem -match 'Server' } ) | Select-Object -ExpandProperty Name) }
		[array]$servers = $adComputers
	}

	$servers | % {
		$ComputerName = $_
		Write-host $ComputerName
		if ( Test-Path "\\$ComputerName\c$\Users\$env:USERNAME" ) {
			Get-ChildItem "\\$ComputerName\c$\Users\$env:USERNAME\Desktop\" -Exclude 'WindowsPowershell','Visual Studio*'| Select -ExpandProperty Name
			Get-ChildItem "\\$ComputerName\c$\Users\$env:USERNAME\Documents\" -Exclude 'WindowsPowershell','Visual Studio*'| Select -ExpandProperty Name
			Get-ChildItem "\\$ComputerName\c$\Users\$env:USERNAME\Downloads\" -Exclude 'WindowsPowershell','Visual Studio*' | Select -ExpandProperty Name
		} else {
			if ( Test-Path "\\$ComputerName\c$\Documents and Settings\$env:USERNAME\" ) {
				Get-ChildItem "\\$ComputerName\c$\Documents and Settings\$env:USERNAME\Desktop\" -Exclude 'WindowsPowershell','Visual Studio*' | Select -ExpandProperty Name
				Get-ChildItem "\\$ComputerName\c$\Documents and Settings\$env:USERNAME\My Documents\" -Exclude 'WindowsPowershell','Visual Studio*' | Select -ExpandProperty Name
			}
		}
	}
}

function Get-QCommand {
	if ( !$args[0] ) { Get-Command -PSSnapin Quest.ActiveRoles*
    } else { Get-Command $args[0] | ? { $_.PSSnapIn -like 'Quest.ActiveRoles*' } }
}

function Get-RegistryChildItem { param( [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]$arg )
	$hive = ((( $arg -replace '\[' ) -replace '\]' ) -replace ':' -split '\\' )[0]
	$partialpath = ((( $arg -replace '\[' ) -replace '\]' ) -split('\\',2 ))[-1]
	switch ( $hive ) {
		'HKEY_CURRENT_USER' { $hive = 'HKCU' }
		'HKEY_LOCAL_MACHINE' { $hive = 'HKLM' }
		'HKEY_USERS' { $hive = 'HKU' }
		'HKEY_CURRENT_CONFIG' { $hive = 'HKCC' }
		'HKEY_CLASSES_ROOT' { $hive = 'HKCR' }
	}
	Get-Item ( $hive + ':\' + $partialpath )
	Get-ChildItem -Path ( $hive + ':\' + $partialpath ) -Recurse | % {
		Get-Item (( $hive + ':\' + $partialpath ) + '\\' + (( $_.Name -split '\\' )[-1]))
	}
}

function Get-RegistryItemProperty { param( [Parameter(position=0,Mandatory=$true,ValueFromPipeline=$true)]$arg )
	$hive = ((( $arg -replace '\[' ) -replace '\]' ) -replace ':' -split '\\' )[0]
	$itemName = ((( $arg -replace '\[' ) -replace '\]' ) -split '\\' )[-1]
	$partialpath = (((( $arg -replace '\[' ) -replace '\]' ) -split( '\\',2 ))[-1] ) -replace $itemName
	switch ( $hive ) {
		'HKEY_CURRENT_USER' { $hive = 'HKCU' }
		'HKEY_LOCAL_MACHINE' { $hive = 'HKLM' }
		'HKEY_USERS' { $hive = 'HKU' }
		'HKEY_CURRENT_CONFIG' { $hive = 'HKCC' }
		'HKEY_CLASSES_ROOT' { $hive = 'HKCR' }
	}
	Get-ItemProperty -Path ( $hive + ':\' + $partialpath ) -Name $itemName | Select-Object -ExpandProperty $itemName
}

if ( $PSVersionTable.PSVersion.Major -ge 5 ) { function Find-PackageGUI { Find-Package -IncludeDependencies | Out-Gridview -PassThru | Install-Package -Verbose } } #For the upcoming WMF 5.0 OneGet feature, hell yee!

function Get-Shortcut {	param( $path )
	$obj = New-Object -ComObject WScript.Shell
	if ( !$path ) {
		$pathUser = [Environment]::GetFolderPath('StartMenu')
		$pathCommon = [Environment]::GetFolderPath('CommonStartMenu')

		$path = Get-ChildItem $pathUser, $pathCommon -Filter *.lnk -Recurse
	}
	$path | % {
		$link = $obj.CreateShortcut( $_.FullName )

		$info = @{}
		$info.Hotkey = $link.Hotkey
		$info.TargetPath = $link.TargetPath
		$info.LinkPath = $link.FullName
		$info.Arguments = $link.Arguments
		$info.Target = try { Split-Path $info.TargetPath -Leaf } catch { 'n/a'}
		$info.Link = try { Split-Path $info.LinkPath -Leaf } catch { 'n/a'}
		$info.WindowStyle = $link.WindowStyle
		$info.IconLocation = $link.IconLocation

		New-Object PSObject -Property $info
	}
}

function Grant-Elevation {
    $parameterValuesHelpMsg1 = "Script was trying to execute itself as elevated but one of the provided"
    $parameterValuesHelpMsg2 = "parameter values was arrays/other objects - there is no support for it."

    $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal( $windowsIdentity )
    $WindowsBuiltInRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

    if ( !$windowsPrincipal.IsInRole( $WindowsBuiltInRole )) {
        if ( $script:psISE.CurrentFile.Fullpath ) {
            # This fixes error wen script is located at mapped network drive
            $private:scriptFullPath = $script:psISE.CurrentFile.Fullpath
                if ( $scriptFullPath.Contains([io.path]::VolumeSeparatorChar )) { # check for a drive letter
                    $private:psDrive = Get-PSDrive -Name $scriptFullPath.Substring(0,1) -PSProvider 'FileSystem'
                    if ( $psDrive.DisplayRoot ) { # check if it's a mapped network drive
                        $scriptFullPath = $scriptFullPath.Replace( $psDrive.Name + [io.path]::VolumeSeparatorChar, $psDrive.DisplayRoot )
                    }
                }
            Start-Process powershell_ise.exe -Verb Runas -WorkingDirectory $PWD -ArgumentList "`"$scriptFullPath`""
        }
        else {
            # This fixes error wen script is located at mapped network drive
            $private:scriptFullPath = $script:MyInvocation.MyCommand.Path
            if ( $scriptFullPath.Contains([io.path]::VolumeSeparatorChar )) { # check for a drive letter
                $private:psDrive = Get-PSDrive -Name $scriptFullPath.Substring(0,1) -PSProvider 'FileSystem'
                if ( $psDrive.DisplayRoot ) { # check if it's a mapped network drive
                    $scriptFullPath = $scriptFullPath.Replace( $psDrive.Name + [io.path]::VolumeSeparatorChar, $psDrive.DisplayRoot )
                }
            }
            if (( $script:MyInvocation.BoundParameters.GetEnumerator() | % { $_.Value.count -gt 1 } ) -match $true ) {

                [string[]]$ArgumentList = @( '-NoLogo','-NoExit','-ExecutionPolicy', 'bypass')
                $ArgumentList += @( '-Command', "Set-Location `'$PWD`' ; Write-Host `"$parameterValuesHelpMsg1`" ; Write-Host `"$parameterValuesHelpMsg2`" ")
            } else {
                [string[]]$ArgumentList = @( '-NoLogo','-NoExit','-ExecutionPolicy', 'bypass')
                $ArgumentList += @( '-Command', "Set-Location `'$PWD`' ; & `'$scriptFullPath`' " )
                $ArgumentList += $script:MyInvocation.BoundParameters.GetEnumerator() | % { "-$( $_.Key )", "$( $_.Value )" }
                $ArgumentList += $script:MyInvocation.UnboundArguments
            }
            Start-Process PowerShell.exe -Verb Runas -WorkingDirectory $PWD -ArgumentList $ArgumentList
            Exit
        }
}
}

function Grant-SePrivilege { param(
	# For granting all types of SePrivilege, maybe I can use it in the future ;)
	# The privilege to adjust: http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
	[ValidateSet(
	"SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege",
	"SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege",
	"SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege",
	"SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege",
	"SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege",
	"SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege",
	"SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege",
	"SeRestorePrivilege", "SeSecurityPrivilege", "SeShutdownPrivilege", "SeSyncAgentPrivilege",
	"SeSystemEnvironmentPrivilege", "SeSystemProfilePrivilege", "SeSystemtimePrivilege",
	"SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege",
	"SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]
	$Privilege,
	# The process on which to adjust the privilege. Defaults to the current process.
	$ProcessId = $pid,
	# Switch to disable the privilege, rather than enable it.
	[Switch]$Disable
	)

	# Taken from P/Invoke.NET with minor adjustments.
 $definition = @'
 using System;
 using System.Runtime.InteropServices;

 public class AdjPriv
 {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
   ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);

  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid
  {
   public int Count;
   public long Luid;
   public int Attr;
  }

  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool EnablePrivilege(long processHandle, string privilege, bool disable)
  {
   bool retVal;
   TokPriv1Luid tp;
   IntPtr hproc = new IntPtr(processHandle);
   IntPtr htok = IntPtr.Zero;
   retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
   tp.Count = 1;
   tp.Luid = 0;
   if(disable)
   {
    tp.Attr = SE_PRIVILEGE_DISABLED;
   }
   else
   {
    tp.Attr = SE_PRIVILEGE_ENABLED;
   }
   retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
   retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
   return retVal;
  }
 }
'@

	$processHandle = ( Get-Process -Id $ProcessId ).Handle
	$type = Add-Type $definition -PassThru
	$type[0]::EnablePrivilege($processHandle, $Privilege, $Disable)
}

function Grant-SeTakeOwnershipPrivilege {
	# Enable SeTakeOwnershipPrivilege: http://forum.sysinternals.com/tip-easy-way-to-enable-privileges_topic15745.html
$typeDefinition = @"
using System;
using System.Runtime.InteropServices;
namespace Win32Api {
public class NtDll {
    [DllImport("ntdll.dll", EntryPoint="RtlAdjustPrivilege")]
    public static extern int RtlAdjustPrivilege(ulong Privilege, bool Enable, bool CurrentThread, ref bool Enabled);
    }
}
"@
	Add-Type -TypeDefinition $typeDefinition -PassThru | Out-Null
	$bEnabled = $false
	[Win32Api.NtDll]::RtlAdjustPrivilege(9, $true, $false, [ref]$bEnabled) | Out-Null
}

function Get-Type { param( [Parameter(ValueFromPipeline=$true)]$args ) ( $args ).GetType() }

function New-SymbolicLink {
	<#
	.SYNOPSIS
		Creates a Symbolic link to a file or directory

	.DESCRIPTION
		Creates a Symbolic link to a file or directory as an alternative to mklink.exe

	.PARAMETER Path
		Name of the path that you will reference with a symbolic link.

	.PARAMETER SymName
		Name of the symbolic link to create. Can be a full path/unc or just the name.
		If only a name is given, the symbolic link will be created on the current directory that the
		function is being run on.

	.PARAMETER File
		Create a file symbolic link

	.PARAMETER Directory
		Create a directory symbolic link

	.NOTES
		Name: New-SymLink
		Author: Boe Prox
		Created: 15 Jul 2013


	.EXAMPLE
		New-SymLink -Path "C:\users\admin\downloads" -SymName "C:\users\admin\desktop\downloads" -Directory

		SymLink                          Target                   Type
		-------                          ------                   ----
		C:\Users\admin\Desktop\Downloads C:\Users\admin\Downloads Directory

		Description
		-----------
		Creates a symbolic link to downloads folder that resides on C:\users\admin\desktop.

	.EXAMPLE
		New-SymLink -Path "C:\users\admin\downloads\document.txt" -SymName "SomeDocument" -File

		SymLink                             Target                                Type
		-------                             ------                                ----
		C:\users\admin\desktop\SomeDocument C:\users\admin\downloads\document.txt File

		Description
		-----------
		Creates a symbolic link to document.txt file under the current directory called SomeDocument.
	#>
	[cmdletbinding( DefaultParameterSetName = 'Directory', SupportsShouldProcess=$True )]
	Param(
	[parameter(Position=0,ParameterSetName='Directory',ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,Mandatory=$True)]
	[parameter(Position=0,ParameterSetName='File',ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,Mandatory=$True)]
	[ValidateScript({
		If ( Test-Path $_ ) { $True } Else {
			Throw "`'$_`' doesn't exist!"
		}
	})]
	[string]$Path,
	[parameter(Position=1,ParameterSetName='Directory')]
	[parameter(Position=1,ParameterSetName='File')]
	[string]$SymName,
	[parameter(Position=2,ParameterSetName='File')]
	[switch]$File,
	[parameter(Position=2,ParameterSetName='Directory')]
	[switch]$Directory
	)
	Begin {
	#Verify user is administrator
	$admin = ( New-Object System.Security.principal.windowsprincipal([System.Security.Principal.WindowsIdentity]::GetCurrent()) ).isInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
	If ( !$admin ) {
			Write-Warning 'You must be an Administrator to run this function!'
			Break
		}
	Try {
		$null = [mklink.symlink]
		} Catch {
Add-Type @"
using System;
using System.Runtime.InteropServices;
namespace mklink
{
	public class symlink
	{
		[DllImport("kernel32.dll")]
		public static extern bool CreateSymbolicLink(string lpSymlinkFileName, string lpTargetFileName, int dwFlags);
	}
}
"@
	}
	}
	Process {
		#Assume target Symlink is on current directory if not giving full path or UNC
		If ($SymName -notmatch "^(?:[a-z]:\\)|(?:\\\\\w+\\[a-z]\$)") {
			$SymName = "{0}\{1}" -f $pwd,$SymName
		}
		$Flag = @{
			File = 0
			Directory = 1
		}
		If ($PScmdlet.ShouldProcess($Path,'Create Symbolic Link')) {
			Try {
				$return = [mklink.symlink]::CreateSymbolicLink($SymName,$Path,$Flag[$PScmdlet.ParameterSetName])
				If ($return) {
					$object = New-Object PSObject -Property @{
						SymLink = $SymName
						Target = $Path
						Type = $PScmdlet.ParameterSetName
					}
					$object.pstypenames.insert(0,'System.File.SymbolicLink')
					$object
				} Else {
					Throw "Unable to create symbolic link!"
				}
			} Catch {
				Write-warning ("{0}: {1}" -f $path,$_.Exception.Message)
			}
		}
	}
}

function New-UniverseMode { New-Item -ItemType Directory -Path ( [Environment]::GetFolderPath('Desktop') + '\' + 'Universe Mode.{ED7BA470-8E54-465E-825C-99712043E01C}' ) | Out-Null }

function Deny-CMDCommands {
	$cmdError = 'Using old CMD/DOS commands is no longer tolerated because Powershell it is not a shell of you grandpa!'
	switch ( $^ ) {
	"cd" { Write-Host "Use Set-Location instead!" }
	"hostname" { Write-Host 'Use $env:COMPUTERNAME instead!' }
    "nslookup" { Write-Host "Use Resolve-DnsName instead!" }
	"ping" { Write-Host "Use Test-Connection instead!" }
	}
	Write-Error $cmdError
}

function Select-Value { [Cmdletbinding()] param(
        [parameter(Mandatory=$true)] [String] $Value,
        [parameter(ValueFromPipeline=$true)] $InputObject
    )
    Process {
		# Identify the PropertyName for respective matching Value, in order to populate it Default Properties
		$Property = ( $PSItem.properties.Where({ $_.Value -Like "$Value" })).Name
		If ( $Property ) {
			# Create Property a set which includes the 'DefaultPropertySet' and Property for the respective 'Value' matched
			$DefaultPropertySet = $PSItem.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames
			$TypeName = ( $PSItem.PSTypenames )[0]
			Get-TypeData $TypeName | Remove-TypeData
			Update-TypeData -TypeName $TypeName -DefaultDisplayPropertySet ( $DefaultPropertySet+$Property | Select-Object -Unique )
			# Output Objects
			$PSItem | Where-Object {$_.properties.Value -like "$value"}
		}
    }
}

function Show-Colors { [enum]::GetValues( [ConsoleColor] ) | % { Write-Host $_ -ForegroundColor $_ } }

function Set-PinnedApplication {
    <#
	.SYNOPSIS
		This function are used to pin and unpin programs from the taskbar and Start-menu in Windows
	.DESCRIPTION
		The function have to parameteres which are mandatory:
		Action: PinToTaskbar, PinToStartMenu, UnPinFromTaskbar, UnPinFromStartMenu
		FilePath: The path to the program to perform the action on
	.EXAMPLE
		Set-PinnedApplication -Action UnPinFromTaskbar
		Displays all application which can be Unpined from Taskbar
	.EXAMPLE
		Set-PinnedApplication -Action PinToTaskbar -FilePath 'C:\WINDOWS\system32\notepad.exe'
	.EXAMPLE
		Set-PinnedApplication -Action UnPinFromTaskbar -FilePath 'C:\WINDOWS\system32\notepad.exe'
	.EXAMPLE
		Set-PinnedApplication -Action PinToStartMenu -FilePath 'C:\WINDOWS\system32\notepad.exe'
	.EXAMPLE
		Set-PinnedApplication -Action UnPinFromStartMenu -FilePath 'C:\WINDOWS\system32\notepad.exe'
	#>
    [CmdletBinding()] param(
        [Parameter(Mandatory = $false)][ValidateSet('PintoStartMenu', 'UnpinfromStartMenu', 'PintoTaskbar', 'UnpinfromTaskbar')][string]$Action,
        [Parameter(Mandatory = $false, ValueFromPipeline = $True)][string]$FilePath
    )
    if ( $Action -eq '' -or $FilePath -eq '' ) { Get-ChildItem "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" | Select-Object -ExpandProperty FullName ; break }

    if ( !( Test-Path $FilePath )) { Write-Host 'FilePath does not exist.' ; return }

    function InvokeVerb {
        param( [string]$FilePath, $verb )
        $verb = $verb -replace '&'
        $path = Split-Path $FilePath
        $shell = New-Object -ComObject 'Shell.Application'
        $folder = $shell.Namespace($path)
        $Item = $folder.Parsename(( Split-Path $FilePath -Leaf ))

        # for Windows 10 17604 and later only unpin verb is returned, pin verb is not available even if Right-Click Menu displays it
        $Verbs = $Item.Verbs()
        [array]$dataVerbs = $Item.Verbs() | Select-Object -ExpandProperty Name
        $verbNumber = $dataVerbs.IndexOf( ( $dataVerbs | ? { ( $_ -replace '&' ) -eq $verb } ) )

        if ( $verbNumber ) {
            # Dosen't work if we select verb by name, you have to use number of the verb!
            $Verbs.Item($verbNumber).DoIt()
        } else { Write-Verbose "Verb $verb not found." }
    }

    function GetVerb {
        param( [int]$verbId )
        try {
            $null = [CosmosKey.Util.MuiHelper]
        } catch {
            $def = [Text.StringBuilder]""
            [void]$def.AppendLine('[DllImport("user32.dll")]')
            [void]$def.AppendLine('public static extern int LoadString(IntPtr h,uint id, System.Text.StringBuilder sb,int maxBuffer);')
            [void]$def.AppendLine('[DllImport("kernel32.dll")]')
            [void]$def.AppendLine('public static extern IntPtr LoadLibrary(string s);')
            Add-Type -MemberDefinition $def.ToString() -Name MuiHelper -Namespace CosmosKey.Util
        }
        if ( !$global:CosmosKey_Utils_MuiHelper_Shell32 ) { $global:CosmosKey_Utils_MuiHelper_Shell32 = [CosmosKey.Util.MuiHelper]::LoadLibrary('shell32.dll') }
        $maxVerbLength = 255
        $verbBuilder = New-Object Text.StringBuilder '', $maxVerbLength
        [void][CosmosKey.Util.MuiHelper]::LoadString($CosmosKey_Utils_MuiHelper_Shell32, $verbId, $verbBuilder, $maxVerbLength)
        return $verbBuilder.ToString()
    }

    $verbs = @{
        'PintoStartMenu'     = 5381
        'UnpinfromStartMenu' = 5382
        'PintoTaskbar'       = 5386
        'UnpinfromTaskbar'   = 5387
    }

    if ( !$verbs.$Action ) {
        Throw 'Action $action not supported`nSupported actions are:`n`tPintoStartMenu`n`tUnpinfromStartMenu`n`tPintoTaskbar`n`tUnpinfromTaskbar'
    }
    InvokeVerb -FilePath $FilePath -Verb $( GetVerb -VerbId $verbs.$action )
}

function Optimize-OSConfiguration {
	$win32_OSVersion = (Get-CimInstance Win32_OperatingSystem).version
	if ((( $win32_OSVersion -split '\.' )[0] -ge 6 ) -and (( $win32_OSVersion -split '\.' )[1] -ge 1 )) {

	$myPinnedApplications = "$env:SystemRoot\system32\dsa.msc", "$env:SystemRoot\system32\compmgmt.msc", "$env:SystemRoot\system32\dhcpmgmt.msc", "$env:SystemRoot\system32\dnsmgmt.msc", "$env:SystemRoot\system32\gpmc.msc"
	$myPinnedApplications | % { Set-PinnedApplication -Action PintoTaskbar $_ -EA 0 }
	}
	if ((( $win32_OSVersion -split '\.' )[0] -ge 6 ) -and (( $win32_OSVersion -split '\.' )[1] -eq 1 )) {
	}
	if ((( $win32_OSVersion -split '\.' )[0] -ge 6 ) -and (( $win32_OSVersion -split '\.' )[1] -ge 2 )) {
		if ( !(Test-Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Windows PowerShell")) {
			New-Item -ItemType Directory -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Name 'Windows PowerShell' | Out-Null

			$AppLocation = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
			$WshShellPowershell = New-Object -ComObject WScript.Shell
			$Shortcut = $WshShellPowershell.CreateShortcut("$env:AppData\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk")
			$shortcut.TargetPath = $AppLocation
			$shortcut.WindowStyle = 0
			$shortcut.IconLocation = "powershell.exe, 0"
			$shortcut.WorkingDirectory = '%HOMEDRIVE%%HOMEPATH%'
			$Shortcut.Save()

			$AppLocation = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell_ise.exe"
			$WshShellISE = New-Object -ComObject WScript.Shell
			$Shortcut = $WshShellISE.CreateShortcut("$env:AppData\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell ISE.lnk")
			$shortcut.TargetPath = $AppLocation
			$shortcut.WindowStyle = 0
			$shortcut.IconLocation = "powershell_ise.exe, 0"
			$shortcut.WorkingDirectory = '%HOMEDRIVE%%HOMEPATH%'
			$Shortcut.Save()
		}
	}
}

function Get-ParsedDate { param([string]$DateString, [string]$Format, [switch]$Trim )
    if ( $Trim ) { $DateString = $DateString.SubString( 0, $Format.Length ) }
    [DateTime]::ParseExact( $DateString, $Format, [Globalization.CultureInfo]::InvariantCulture )
}

function Out-Diff {
	<#
	.Synopsis
		Redirects a Universal DIFF encoded text from the pipeline to the host using colors to highlight the differences.
	.Description
		Helper function to highlight the differences in a Universal DIFF text using color coding.
	.Parameter InputObject
		The text to display as Universal DIFF.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[PSObject]$InputObject
	)
    Process {
        $contentLine = $InputObject | Out-String
        if ($contentLine -match "^Index:") {
            Write-Host $contentLine -ForegroundColor Cyan -NoNewline
        } elseif ($contentLine -match "^(\+|\-|\=){3}") {
            Write-Host $contentLine -ForegroundColor Gray -NoNewline
        } elseif ($contentLine -match "^\@{2}") {
            Write-Host $contentLine -ForegroundColor Gray -NoNewline
        } elseif ($contentLine -match "^\+") {
            Write-Host $contentLine -ForegroundColor Green -NoNewline
        } elseif ($contentLine -match "^\-") {
            Write-Host $contentLine -ForegroundColor Red -NoNewline
        } else {
            Write-Host $contentLine -NoNewline
        }
    }
}

function Search-File { param(
    [Parameter(Position=0,Mandatory=$true)][string]$SearchString,
    [Parameter(Position=1,Mandatory=$true, ValueFromPipeline = $true)][string]$path = ( Get-Location ).Path
    )
    # if (Get-acl 'C:\Users\$env:USERNAME\AppData\Local\Application Data').Access | ? { $_.AccessControlType -eq 'Deny' } then exclude folder
    try {
    [array]$dataDirectory = $null
	Get-ChildItem $path | ? { $_.Attributes -match 'Directory' -and $_.Attributes -notmatch 'System' -and $_.Attributes -notmatch 'Hidden' -and $_.Attributes -notmatch 'ReparsePoint' } | % {
    $detect = Get-Item $_.FullName
    if ( $detect ) { $dataDirectory += $_ }}
    [array]$dataDirectory | % {
    $path = $_.FullName
    [System.IO.Directory]::EnumerateFiles($path,$SearchString,[System.IO.SearchOption]::AllDirectories)
    }
    } catch { $_ }
}

function shell: { param( [Parameter(Position=1)]$Name,[switch]$ListAvailable)
	if ( $ListAvailable -or !$Name ) { ( Get-ItemProperty -LiteralPath (( Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\explorer\FolderDescriptions ).PSPath )).Name | Sort-Object }
	if ( $Name ) { explorer.exe "shell:$Name" }
}

function Enter-Scope { $host.EnterNestedPrompt() }

function Test-ExConnection { param( [Parameter(Position=1,ValueFromPipeline=$true)]$ComputerName, [int]$Count=1, [switch]$t, [switch]$Detailed )
	if ( $t ) { $Count = 999999999 }
		$destination = ( Get-CimInstance Win32_PingStatus -Filter "Address=`"$ComputerName`" AND ResolveAddressNames=$true" ).ProtocolAddressResolved
	if ( $Detailed ) {
		Test-Connection -ComputerName $ComputerName -Count $Count | Select-Object @{ Name = 'Source';Expression = { $_.PSComputerName } },@{ Name = 'Destination';Expression = { $destination } },IPV4Address,IPV6Address,@{ Name = 'Bytes';Expression = { $_.BufferSize } },@{ Name = 'Time(ms)';Expression = { $_.ResponseTime } }
	} else {
		Test-Connection -ComputerName $ComputerName -Count $Count | Select-Object @{ Name = 'Destination';Expression = { $destination } },IPV4Address,@{ Name = 'Bytes';Expression = { $_.BufferSize } },@{ Name = 'Time(ms)';Expression = { $_.ResponseTime } }
	}
}

function Test-PsRemoting { param( [Parameter(Mandatory = $true)]$computername )
    try {
        $errorActionPreference = "Stop"
        $result = Invoke-Command -ComputerName $computername -ScriptBlock { 1 }
    } catch {
        Write-Verbose $_
        return $false
    }
    if ( $result -ne 1 ) {
        Write-Verbose "Remoting to $computerName returned an unexpected result."
        return $false
    }
    $true
}

function Test-FileLock { param( [string]$filePath )
	$filelocked = $false
	$fileInfo = New-Object System.IO.FileInfo $filePath
	trap {
		Set-Variable -Name Filelocked -Value $true -Scope 1
		continue
	}
	$fileStream = $fileInfo.Open( [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None )
	if ( $fileStream ) {
		$fileStream.Close()
	}
	$filelocked
}

function Test-Port {param([cmdletbinding()]
    [Alias('Hostname','Server')][Parameter(Position=0)]
    [string[]]$ComputerName=$env:COMPUTERNAME,
    [Parameter(Position=1,Mandatory=$true)]
    [int]$Port
    )
    $test = New-Object System.Net.Sockets.TcpClient
    Try {
        Write-Verbose "$($ComputerName):$Port"
        $test.Connect($ComputerName, $Port)
        Write-Verbose "Connection successful"
        return $true
    } Catch {
        Write-Verbose "Connection failed"
        return $false
    } Finally {
        $test.Close()
    }
}

function Test-PortExtended {
	<#
	.SYNOPSIS
		Tests port on ComputerName.

	.DESCRIPTION
		Tests port on ComputerName.

	.PARAMETER ComputerName
		Name of server to test the port connection on.

	.PARAMETER port
		Port to test

	.PARAMETER tcp
		Use tcp port

	.PARAMETER udp
		Use udp port

	.PARAMETER UDPTimeOut
		Sets a timeout for UDP port query. (In milliseconds, Default is 1000)

	.PARAMETER TCPTimeOut
		Sets a timeout for TCP port query. (In milliseconds, Default is 1000)

	.NOTES
		Name: Test-Port.ps1
		Author: Boe Prox
		DateCreated: 18Aug2010
		List of Ports: http://www.iana.org/assignments/port-numbers

		To Do:
			Add capability to run background jobs for each host to shorten the time to scan.
	.LINK
		https://boeprox.wordpress.org

	.EXAMPLE
		Test-Port -ComputerName 'server' -port 80
		Checks port 80 on server 'server' to see if it is listening

	.EXAMPLE
		'server' | Test-Port -port 80
		Checks port 80 on server 'server' to see if it is listening

	.EXAMPLE
		Test-Port -ComputerName @("server1","server2") -port 80
		Checks port 80 on server1 and server2 to see if it is listening

	.EXAMPLE
		Test-Port -comp dc1 -port 17 -udp -UDPtimeout 10000

		Server   : dc1
		Port     : 17
		TypePort : UDP
		Open     : True
		Notes    : "My spelling is Wobbly.  It's good spelling but it Wobbles, and the letters
				get in the wrong places." A. A. Milne (1882-1958)

		Description
		-----------
		Queries port 17 (qotd) on the UDP port and returns whether port is open or not

	.EXAMPLE
		@("server1","server2") | Test-Port -port 80
		Checks port 80 on server1 and server2 to see if it is listening

	.EXAMPLE
		(Get-Content hosts.txt) | Test-Port -port 80
		Checks port 80 on servers in host file to see if it is listening

	.EXAMPLE
		Test-Port -ComputerName (Get-Content hosts.txt) -port 80
		Checks port 80 on servers in host file to see if it is listening

	.EXAMPLE
		Test-Port -ComputerName (Get-Content hosts.txt) -port @(1..59)
		Checks a range of ports from 1-59 on all servers in the hosts.txt file

	#>
	[cmdletbinding( DefaultParameterSetName = '', ConfirmImpact = 'low')]
	Param(
	[Parameter(Mandatory = $True, ParameterSetName = '', Position = 0, ValueFromPipeline = $True)]
	[array]$ComputerName,
	[Parameter(Mandatory = $True, ParameterSetName = '', Position = 1)]
	[array]$Port,
	[Parameter(Mandatory = $False, ParameterSetName = '')]
	[int]$TCPtimeout=1000,
	[Parameter(Mandatory = $False, ParameterSetName = '')]
	[int]$UDPtimeout=1000,
	[Parameter(Mandatory = $False, ParameterSetName = '')]
	[switch]$TCP,
	[Parameter(Mandatory = $False, ParameterSetName = '')]
	[switch]$UDP
	)
	Begin {
	If ( !$tcp -and !$udp) { $tcp = $True }
	#Typically you never do this, but in this case I felt it was for the benefit of the function as any errors will be noted in the output of the report
	$ErrorActionPreference = 'SilentlyContinue'
	$report = @()
	}
	Process {
	ForEach ($c in $ComputerName) {
		ForEach ($p in $port) {
			If ($tcp) {
			#Create temporary holder
			$temp = "" | Select Server, Port, TypePort, Open, Notes
			#Create object for connecting to port on ComputerName
			$tcpobject = new-Object system.Net.Sockets.TcpClient
			#Connect to remote machine's port
			$connect = $tcpobject.BeginConnect($c,$p,$null,$null)
			#Configure a timeout before quitting
			$wait = $connect.AsyncWaitHandle.WaitOne($TCPtimeout,$false)
			#If timeout
			If(!$wait) {
				#Close connection
				$tcpobject.Close()
				Write-Verbose "Connection Timeout"
				#Build report
				$temp.Server = $c
				$temp.Port = $p
				$temp.TypePort = "TCP"
				$temp.Open = "False"
				$temp.Notes = "Connection to Port Timed Out"
			} Else {
				$error.Clear()
				$tcpobject.EndConnect($connect) | out-Null
				#If error
				If($error[0]){
					#Begin making error more readable in report
					[string]$string = ($error[0].exception).message
					$message = (($string.split(":")[1]).replace('"',"")).TrimStart()
					$failed = $true
				}
				#Close connection
				$tcpobject.Close()
				#If unable to query port to due failure
				If($failed){
					#Build report
					$temp.Server = $c
					$temp.Port = $p
					$temp.TypePort = "TCP"
					$temp.Open = "False"
					$temp.Notes = "$message"
				} Else{
					#Build report
					$temp.Server = $c
					$temp.Port = $p
					$temp.TypePort = "TCP"
					$temp.Open = "True"
					$temp.Notes = ""
				}
			}
			#Reset failed value
			$failed = $Null
			#Merge temp array with report
			$report += $temp
			}
			If ($udp) {
			#Create temporary holder
			$temp = "" | Select Server, Port, TypePort, Open, Notes
			#Create object for connecting to port on ComputerName
			$udpobject = new-Object system.Net.Sockets.Udpclient
			#Set a timeout on receiving message
			$udpobject.client.ReceiveTimeout = $UDPTimeout
			#Connect to remote machine's port
			Write-Verbose "Making UDP connection to remote server"
			$udpobject.Connect("$c",$p)
			#Sends a message to the host to which you have connected.
			Write-Verbose "Sending message to remote host"
			$a = new-object system.text.asciiencoding
			$byte = $a.GetBytes("$(Get-Date)")
			[void]$udpobject.Send($byte,$byte.length)
			#IPEndPoint object will allow us to read datagrams sent from any source.
			Write-Verbose "Creating remote endpoint"
			$remoteendpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0)
			Try {
				#Blocks until a message returns on this socket from a remote host.
				Write-Verbose "Waiting for message return"
				$receivebytes = $udpobject.Receive([ref]$remoteendpoint)
				[string]$returndata = $a.GetString($receivebytes)
				If ($returndata) {
					Write-Verbose "Connection Successful"
					#Build report
					$temp.Server = $c
					$temp.Port = $p
					$temp.TypePort = "UDP"
					$temp.Open = "True"
					$temp.Notes = $returndata
					$udpobject.close()
				}
			}
			Catch {
				If ($Error[0].ToString() -match "\bRespond after a period of time\b") {
					#Close connection
					$udpobject.Close()
					#Make sure that the host is online and not a false positive that it is open
					If (Test-Connection -ComputerName $c -Count 1 -Quiet) {
						Write-Verbose "Connection Open"
						#Build report
						$temp.Server = $c
						$temp.Port = $p
						$temp.TypePort = "UDP"
						$temp.Open = "True"
						$temp.Notes = ""
					} Else {
						<#
						It is possible that the host is not online or that the host is online,
						but ICMP is blocked by a firewall and this port is actually open.
						#>
						Write-Verbose "Host maybe unavailable"
						#Build report
						$temp.Server = $c
						$temp.Port = $p
						$temp.TypePort = "UDP"
						$temp.Open = "False"
						$temp.Notes = "Unable to verify if port is open or if host is unavailable."
					}
				} ElseIf ($Error[0].ToString() -match "forcibly closed by the remote host" ) {
					#Close connection
					$udpobject.Close()
					Write-Verbose "Connection Timeout"
					#Build report
					$temp.Server = $c
					$temp.Port = $p
					$temp.TypePort = "UDP"
					$temp.Open = "False"
					$temp.Notes = "Connection to Port Timed Out"
				} Else {
					$udpobject.close()
				}
			}
			#Merge temp array with report
			$report += $temp
			}
		}
	}
	}
	End {
	$report
	}
}

function Test-RDP { param([cmdletbinding()]
    [Alias('HostName','Server')]
    [parameter(Position=0)]$ComputerName,
    [parameter(Position=1)]$Port = '3389'
    )
    Write-Verbose "$($ComputerName):$Port"
    Test-Port $ComputerName $Port
}

function Test-PSR { param([cmdletbinding()]
    [Alias('HostName','Server')]
    [parameter(Position=0)]$ComputerName,
    [parameter(Position=1)]$Port = '5985'
    )
    Write-Verbose "Checking $($ComputerName):$Port ... "
    Test-Port $ComputerName $Port
}

function Write-Color { param ( $ForegroundColor )
	# save the current color
    $fc = $host.UI.RawUI.ForegroundColor
    # set the new color
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    # output
    if ( $args ) { Write-Output $args } else { $input | Write-Output }
    # restore the original color
    $host.UI.RawUI.ForegroundColor = $fc
}

function New-DynamicParameter {
	<#>
	.SYNOPSIS
		Create a new dynamic parameter object for use with a dynamicparam block.
	.DESCRIPTION
		New-DynamicParameter allows simplified creation of runtime (dynamic) parameters.
	.PARAMETER ParameterName
		The name of the parameter to create.
	.PARAMETER ParameterType
		The .NET type of this parameter.
	.PARAMETER Mandatory
		Set the mandatory flag for this parameter.
	.PARAMETER Position
		Define a position for the parameter.
	.PARAMETER ValueFromPipeline
		The parameter can be filled from the input pipeline.
	.PARAMETER ValueFromPipelineByPropertyName
		The parameter can be filled from a specific property in the input pipeline.
	.PARAMETER ParameterSetName
		Assign the parameter to a specific parameter set.
	.PARAMETER ValidateNotNullOrEmpty
		Disallow null or empty values for the parameter if the parameter is specified.
	.PARAMETER ValidatePattern
		Test the parameter value using a regular expression.
	.PARAMETER ValidatePatternOptions
		Regular expression options which dictate the behaviour of ValidatePattern.
	.PARAMETER ValidateRange
		A minimum and maximum value to compare the argument to.
	.PARAMETER ValidateScript
		Test the parameter value using a script.
	.PARAMETER ValidateSet
		Test the parameter value against a set of values.
	.PARAMETER ValidateSetIgnoreCase
		ValidateSet can be configured to be case sensitive by setting this parameter to $false. The default behaviour for ValidateSet ignores case.
	.INPUTS
		System.Object
		System.Object[]
		System.String
		System.Type
	.OUTPUTS
		System.Management.Automation.RuntimeDefinedParameter
	.EXAMPLE
		New-DynamicParameter Name -DefaultValue "Test" -ParameterType "String" -Mandatory -ValidateSet "Test", "Live"
	.EXAMPLE
		New-DynamicParameter Name -ValueFromPipelineByPropertyName
	.EXAMPLE
		New-DynamicParameter Name -ValidateRange 1, 2
	.NOTES
		Author: Chris Dent

		Change log:
		24/10/2014 - Chris Dent - Added support for ValidatePattern options and ValidateSet case sensitivity.
		22/10/2014 - Chris Dent - First release.
	<#>
	[CmdLetBinding()]
	param(
	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[Alias('Name')]
	[String]$ParameterName,
	[Object]$DefaultValue,
	[Type]$ParameterType = "Object",
	[Switch]$Mandatory,
	[Int32]$Position = -2147483648,
	[Switch]$ValueFromPipeline,
	[Switch]$ValueFromPipelineByPropertyName,
	[String]$ParameterSetName = "__AllParameterSets",
	[Switch]$ValidateNotNullOrEmpty,
	[ValidateNotNullOrEmpty()]
	[RegEx]$ValidatePattern,
	[Text.RegularExpressions.RegexOptions]$ValidatePatternOptions = [Text.RegularExpressions.RegexOptions]::IgnoreCase,
	[Object[]]$ValidateRange,
	[ValidateNotNullOrEmpty()]
	[ScriptBlock]$ValidateScript,
	[ValidateNotNullOrEmpty()]
	[Object[]]$ValidateSet,
	[Boolean]$ValidateSetIgnoreCase = $true
	)

	$AttributeCollection = @()

	$ParameterAttribute = New-Object Management.Automation.ParameterAttribute
	$ParameterAttribute.Mandatory = $Mandatory
	$ParameterAttribute.Position = $Position
	$ParameterAttribute.ValueFromPipeline = $ValueFromPipeline
	$ParameterAttribute.ValueFromPipelineByPropertyName = $ValueFromPipelineByPropertyName

	$AttributeCollection += $ParameterAttribute

	if ($psboundparameters.ContainsKey('ValidateNotNullOrEmpty')) {
		$AttributeCollection += New-Object Management.Automation.ValidateNotNullOrEmptyAttribute
	}
	if ($psboundparameters.ContainsKey('ValidatePattern')) {
		$ValidatePatternAttribute = New-Object Management.Automation.ValidatePatternAttribute($ValidatePattern.ToString())
		$ValidatePatternAttribute.Options = $ValidatePatternOptions

		$AttributeCollection += $ValidatePatternAttribute
	}
	if ($psboundparameters.ContainsKey('ValidateRange')) {
		$AttributeCollection += New-Object Management.Automation.ValidateRangeAttribute($ValidateRange)
	}
	if ($psboundparameters.ContainsKey('ValidateScript')) {
		$AttributeCollection += New-Object Management.Automation.ValidateScriptAttribute($ValidateScript)
	}
	if ($psboundparameters.ContainsKey('ValidateSet')) {
		$ValidateSetAttribute = New-Object Management.Automation.ValidateSetAttribute($ValidateSet)
		$ValidateSetAttribute.IgnoreCase = $ValidateSetIgnoreCase

		$AttributeCollection += $ValidateSetAttribute
	}

	$Parameter = New-Object Management.Automation.RuntimeDefinedParameter($ParameterName, $ParameterType, $AttributeCollection)
	if ($psboundparameters.ContainsKey('DefaultValue')) {
		$Parameter.Value = $DefaultValue
	}
	return $Parameter
}
#endregion

#region Update-Profile
function Get-WebFile { param( $url,$fullPath )
    $reg = ( Get-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' ).property | ? { $_ -eq 'ProxyServer' }
    $is = Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name AutoConfigURL -EA 0
    if ( $is ) {
        try { Start-BitsTransfer -Source $url -Destination $fullPath -EA 1 }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            try { throw $_ }
            catch {
				$Credentials = Get-Credential
				Start-BitsTransfer -Source $url -Destination $fullPath -ProxyUsage SystemDefault -ProxyAuthentication Basic -ProxyCredential $Credentials | Out-Null
            }
        }
    } elseif ( !$reg -and !$env:USERDNSDOMAIN ) {
        Set-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Type DWORD -Value 1
        Set-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer -Type String -Value $proxy | Out-Null
    } else { Start-BitsTransfer -Source $url -Destination $fullPath | Out-Null }
}

function Deploy-Profile {
    $LDAPFilter = "(&(OperatingSystem=*Server*)(!(Name=$env:COMPUTERNAME)))"
    if ( Get-Command Get-QADComputer -EA 0 ) {
        [array]$adComputers = ( Get-QADComputer -LDAPFilter $LDAPFilter -SecurityMask 'None' -DontUseDefaultIncludedProperties -IncludedProperties Name,OperatingSystem | ? { $_.OperatingSystem -match 'Server 2008' -and $_.Name -ne $env:COMPUTERNAME } ).Name
    }
    if ( !$adComputers ) { Import-Module activedirectory ; [array]$adComputers = ( Get-ADComputer -Filter * -Properties Name,OperatingSystem | ? { $_.OperatingSystem -match 'Server 2008' -and $_.Name -ne $env:COMPUTERNAME } ).Name }
    if ( $adComputers.Count -ge 1 ) {

        $adComputers | % {
            $ComputerName = $_
            if ( Test-Connection -ComputerName $ComputerName -Count 1 -Quiet ) {
                if ( Test-Path "\\$ComputerName\c$\Users" ) {
                    if ( Test-Path "\\$ComputerName\c$\Users\$env:USERNAME\Documents" ) {
                        if ( !( Test-Path "\\$ComputerName\c$\Users\$env:USERNAME\Documents\WindowsPowershell" -EA 0 ) ) {
                        New-Item -Path "\\$ComputerName\c$\Users\$env:USERNAME\Documents\WindowsPowershell" -ItemType Directory | Out-Null }
                        Write-host $ComputerName
                        Copy-Item ( Resolve-Path $profile ) -Destination "\\$ComputerName\c$\Users\$env:USERNAME\Documents\WindowsPowershell" -Force | Out-Null
                        } else { "You never logged into $ComputerName so profile cannot be copied." }
                } else { '2003' }
            }
        }
    }
}

function Reset-Profile { . $Profile.CurrentUserAllHosts }

function Update-Profile { param(
    [Parameter( Mandatory = $true )]$GitHubAccountName,
    [Parameter( Mandatory = $true )]$GitHubRepositoryName
    )
    $psProfileFileName = 'profile.ps1'
    $urlPSProfile = "https://raw.githubusercontent.com/$GitHubAccountName/$GitHubRepositoryName/master/$psProfileFileName"
    $psPersonalPatch = [Environment]::GetFolderPath('MyDocuments') + '\' + 'WindowsPowerShell'
    $psProfileFullPath = $psPersonalPatch + '\' + $psProfileFileName

    $date = Get-Date -Format dd.MM.yyyy
    Move-Item $psPersonalPatch\profile.ps1 "$psPersonalPatch\profile-$date.ps1" -EA 0

    #Get-WebFile $urlPSProfile $psProfileFullPath
    #Invoke-WebRequest $urlPSProfile -OutFile $psProfileFullPath | Out-Null

    Reset-Profile
}
#endregion

#region Info
if ( $host.name -eq 'PowerGUIScriptEditorHost' ) { return }

$color_decoration = [ConsoleColor]::DarkGreen
$color_Host = [ConsoleColor]::Green
$color_Location = [ConsoleColor]::Cyan

if ( $host.Name -eq 'ConsoleHost' ) {
    #$Host.UI.RawUI.BackgroundColor = 'Black'
    #$Host.UI.RawUI.ForegroundColor = 'White'
    Resize-Console -x 140 -y 35 -EA 0 ; Resize-Console -x 140 -y 35 -EA 0
    $OSVersionMajor = [int](( Get-CimInstance Win32_OperatingSystem ).version -split '\.')[0]
    $OSVersionMinor = [int](( Get-CimInstance Win32_OperatingSystem ).version -split '\.')[1]
    if ( $OSVersionMajor -eq 6 -and $OSVersionMinor -le 1 ) { Set-ConsoleFont 6 -EA 0 }
    #if ( $OSVersionMajor -eq 6 -and $OSVersionMinor -ge 2 ) { Set-ConsoleFont 7 -EA 0 }
}

if ( $host.name -eq 'Windows PowerShell ISE Host' ) {
    $Host.PrivateData.RestoreDefaults()
    $Host.PrivateData.RestoreDefaultConsoleTokenColors()
    $Host.PrivateData.RestoreDefaultTokenColors()
    $Host.PrivateData.RestoreDefaultXmlTokenColors()
}

#add global variable if it doesn't already exist
if ( !( $global:z_LastCheck )) {
    $global:z_LastCheck = Get-Date
    $global:z_SystemDrive = Get-CimInstance -Query ("Select Freespace,Size from win32_logicaldisk where deviceid = '" + $env:SystemDrive + "'")
}

#only refresh disk information once every 15 minutes
if (( New-TimeSpan $global:z_LastCheck ).TotalMinutes -ge 15 ) {
    $global:z_SystemDrive = Get-CimInstance -Query "Select Freespace,Size from win32_logicaldisk where deviceid = 'c:'"
    $global:z_LastCheck = Get-Date
}

#[int]$z_FreeMem = ( Get-CimInstance -query "Select FreeAndZeroPageListBytes from Win32_PerfFormattedData_PerfOS_Memory" ).FreeAndZeroPageListBytes/1mb
[int]$z_FreeMem  =  [math]::round( ( Get-CimInstance -Class Win32_OperatingSystem ).FreePhysicalMemory / 1024, 2 )
$z_DiskInfo = "{0:N2}" -f (( $z_SystemDrive.freespace/1gb )/( $z_SystemDrive.size/1gb ) * 100 )

#uptime
[TimeSpan]$z_Up = New-TimeSpan ([System.Convert]::ToDateTime(( Get-CimInstance -ClassName Win32_OperatingSystem ).LastBootUpTime )) $( Get-Date )
$z_Uptime = "$( $z_Up.days )d $( $z_Up.hours )h $( $z_Up.minutes )m $( $z_Up.seconds )s"

#$z_InfoText = "CPU:" + $z_CPU + "% Process:" + $z_ProcessCount + $z_DiskInfo + ' ' + ( [char]0x25b2 ) + $z_Uptime + ' ' + ( Get-Date -format g )
$z_InfoText = ' ' + "Memory: {0}MB | C: {1}% free | {2}{3} | {4}" -f $z_FreeMem,$z_DiskInfo,( [char]0x25b2 ),$z_Uptime,( Get-Date -format g ) + ' '

$z_SystemInfo = [char]0x250c
$z_SystemInfo += ( [char]0x2500 ).ToString() * $z_InfoText.length
$z_SystemInfo += [char]0x2510
$z_SystemInfo += "`n"
$z_SystemInfo += ( [char]0x2502 ) + $z_InfoText + ( [char]0x2502 )
$z_SystemInfo += "`n"
$z_SystemInfo += [char]0x2514
$z_SystemInfo += ( [char]0x2500 ).ToString() * $z_InfoText.length
$z_SystemInfo += [char]0x2518
#endregion

#region Powershell Prompt

function Get-ShortPath { param( [string]$path )
    $location = $path.Replace( $env:USERPROFILE, '~' )
    # remove prefix for UNC paths
    $location = $location -replace "^[^:]+::"
    # make path shorter like tabs in Vim,
    # handle paths starting with \\ and . correctly
    # return ( $location -replace "\\( \.? )( [^\\] )[^\\]*( ?=\\ )","\$1$2" )
    # return standard location
    return $location
}

function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE
    # Make sure that Windows and .Net know where we are at all times
    [Environment]::CurrentDirectory = ( Get-Location -PSProvider FileSystem ).ProviderPath

    # Check Running Jobs
    if (( Get-Job -State Running ).Count -ne 0 ) { $jobsCount = ( Get-Job -State Running ).Count }

    #Set the PowerShell session time, computername and current location in the title bar

    #Get start time for the current PowerShell session, $pid is a special variable for the current PowerShell process ID
    [datetime]$psStart = ( Get-Process -id $pid ).StartTime

    #Strip off the millisecond part with Substring(). The millisecond part will come after the last period
    $s = (( Get-Date ) - $psStart ).ToString()
    $elapsed = $s.Substring( 0,$s.LastIndexOf('.'))

    if ( $env:COMPUTERNAME -ne $env:USERDOMAIN ) {
    $title = "{0}{1}{2}{3}{4}{5}{6}{7}{8}" -f ( Get-ShortPath ( Get-Location ).Path ),' | ',$env:USERDNSDOMAIN,'\',$env:USERNAME,'@',$env:computername,' | ',$elapsed
    } else {
    $title = "{0}{1}{2}{3}{4}{5}{6}" -f ( Get-ShortPath ( Get-Location ).Path ),' | ',$env:USERDOMAIN,'@',$env:computername,' | ',$elapsed
    }

    $admin = ( New-Object System.Security.principal.windowsprincipal([System.Security.Principal.WindowsIdentity]::GetCurrent()) ).isInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    if ( $admin ) { $host.ui.rawui.WindowTitle = 'Administrator: ' + $title } else { $host.ui.rawui.WindowTitle = $title }

    Write-Host "$( ( Get-History -count 1 ).Id + 1 )" -NoNewline -ForegroundColor Yellow

    if ( $env:COMPUTERNAME -ne $env:USERDOMAIN ) {
    Write-Host $env:USERDNSDOMAIN -NoNewline -ForegroundColor DarkCyan
    Write-Host '\' -NoNewline
    }

    Write-Host '[' -NoNewline
    Write-Host $env:COMPUTERNAME -NoNewline -ForegroundColor Red
    Write-Host ']' -NoNewline
    Write-Host $env:USERNAME -NoNewline -ForegroundColor $color_Host
    Write-Host ' ' -NoNewline -ForegroundColor $color_decoration

    if ( $jobsCount ) {
    Write-Host '[' -ForegroundColor White -NoNewline
    Write-Host $jobsCount -ForegroundColor Red -NoNewline
    Write-Host ']' -ForegroundColor White -NoNewline
    Write-Host ' ' -NoNewline
    }

    Write-Host ( Get-ShortPath ( Get-Location ).Path ) -NoNewline -ForegroundColor $color_Location

    if ( Get-Command Write-VcsStatus -EA SilentlyContinue ) { Write-VcsStatus }

    Write-Host ' ' -NoNewline
    Write-Host ( '+' * $NestedPromptLevel ) -NoNewline
    Write-Host '>' -NoNewline

    $global:LASTEXITCODE = $realLASTEXITCODE
    return ' '
}
#endregion

Write-Host "Welcome Bartosz, together with Powershell we will rule the galaxy because it's not a shell of you grandpa!" -ForegroundColor Green
Write-Host $z_SystemInfo #-ForegroundColor Green
Write-Host ""

#Set-Location $HOME