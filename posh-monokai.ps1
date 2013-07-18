##############################################################################################
# posh-monokai - Windows PowerShell Monokai Console Color Scheme
# https://github.com/ntwb/posh-monokai
##############################################################################################

if ( !( Test-Path 'HKCU:\Console\Windows PowerShell' )) { New-Item 'HKCU:\Console\Windows PowerShell' } 

Push-Location
Set-Location 'HKCU:\Console\Windows PowerShell'

Write-Host -ForegroundColor Cyan        "--> [posh-monokai] "
Write-Host -nonewline -ForegroundColor Black       "Black       " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor DarkBlue    "DarkBlue    " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor DarkGreen   "DarkGreen   " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor DarkCyan    "DarkCyan    " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor DarkRed     "DarkRed     " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor DarkMagenta "DarkMagenta " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor DarkYellow  "DarkYellow  " -BackgroundColor Black
Write-Host -ForegroundColor Gray                   "Gray        " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor DarkGray    "DarkGray    " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor Blue        "Blue        " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor Green       "Green       " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor Cyan        "Cyan        " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor Red         "Red         " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor Magenta     "Magenta     " -BackgroundColor Black
Write-Host -nonewline -ForegroundColor Yellow      "Yellow      " -BackgroundColor Black
Write-Host -ForegroundColor White                  "White       " -BackgroundColor Black

Set-ItemProperty . ColorTable00 -type DWORD -value 0x003e4849
Set-ItemProperty . ColorTable01 -type DWORD -value 0x00969483
Set-ItemProperty . ColorTable02 -type DWORD -value 0x002ee2a6
Set-ItemProperty . ColorTable03 -type DWORD -value 0x00efd966
Set-ItemProperty . ColorTable04 -type DWORD -value 0x007226f9
Set-ItemProperty . ColorTable05 -type DWORD -value 0x007226f9
Set-ItemProperty . ColorTable06 -type DWORD -value 0x0074dbe6
Set-ItemProperty . ColorTable07 -type DWORD -value 0x00c2cfcf
Set-ItemProperty . ColorTable08 -type DWORD -value 0x00222827
Set-ItemProperty . ColorTable09 -type DWORD -value 0x00d28b26
Set-ItemProperty . ColorTable10 -type DWORD -value 0x002ee2a6
Set-ItemProperty . ColorTable11 -type DWORD -value 0x00efd966
Set-ItemProperty . ColorTable12 -type DWORD -value 0x007226f9
Set-ItemProperty . ColorTable13 -type DWORD -value 0x007226f9
Set-ItemProperty . ColorTable14 -type DWORD -value 0x0074dbe6
Set-ItemProperty . ColorTable15 -type DWORD -value 0x00f2f8f8
Set-ItemProperty . InsertMode             -type DWORD -value 0x00000001
Set-ItemProperty . QuickEdit              -type DWORD -value 0x00000001
Set-ItemProperty . ScreenBufferSize       -type DWORD -value 0x03e7007d #ScreenBufferSize 125 w x 999 h
Set-ItemProperty . ScreenColors           -type DWORD -value 0x0000008f # 8 = DarkGray | f = White
Set-ItemProperty . WindowSize             -type DWORD -value 0x0028007d #WindowSize 125 w x 40 h

Pop-Location

$Host.PrivateData.DebugBackgroundColor = "DarkGray"
$Host.PrivateData.ErrorBackgroundColor = "DarkGray"
