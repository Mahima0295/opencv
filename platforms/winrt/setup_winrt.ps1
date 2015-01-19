<#
Copyright © Microsoft Open Technologies, Inc.
All Rights Reserved        
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.

You may obtain a copy of the License at 
http://www.apache.org/licenses/LICENSE-2.0

THIS CODE IS PROVIDED ON AN *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED WARRANTIES OR CONDITIONS OF TITLE,
FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABLITY OR NON-INFRINGEMENT.

See the Apache 2 License for the specific language governing permissions and limitations under the License.
#>

[CmdletBinding()]
Param(
    [parameter(Mandatory=$False)]
    [switch]
    $HELP,

    [parameter(Mandatory=$False)]
    [Array]
    [ValidateNotNull()]
    [ValidateCount(0, 2)]
    [ValidateSet("WP","WS")]
    $PLATFORM = "WP",

    [parameter(Mandatory=$False)]
    [Array]
    [ValidateNotNull()]
    [ValidateSet("8.1","8.0")]
    [ValidateCount(0, 2)]
    $VERSION = "8.1",

    [parameter(Mandatory=$False)]
    [Array]
    [ValidateSet("x86","x64","ARM")]
    [ValidateNotNull()]
    [ValidateCount(0, 3)]
    $ARCHITECTURE = "x86",

    [parameter(Mandatory=$False)]
    [String]
    [ValidateSet("Visual Studio 12 2013","Visual Studio 11 2012")]
    [ValidateNotNull()]
    $GENERATOR = "Visual Studio 12 2013"
)

Function Execute() {
    If ($HELP.IsPresent) {
        ShowHelp
    }

    #Assuming we are in '<ocv-sources>/platforms/winrt' we should move up to sources root directory
    Push-Location ../../
        
    $SRC = Get-Location

    $architectures = @{
        "x86" = "";
        "x64" = " Win64"
        "arm" = " ARM"
    }

    foreach($plat in $PLATFORM) {
        # Set proper platform name.
        $platName = ""
        Switch ($plat) {
            "WP" { $platName = "WindowsPhone" }
            "WS" { $platName = "WindowsStore" }
        }

        foreach($vers in $VERSION) {

            foreach($arch in $ARCHITECTURE) {

                # Set proper architecture. For MSVS this is done by selecting proper generator
                $genName = $GENERATOR
                Switch ($arch) {
                    "ARM" { $genName = $GENERATOR + $architectures['arm'] }
                    "x64" { $genName = $GENERATOR + $architectures['x64'] }
                }

                $path = "$SRC\bin\$plat\$vers\$arch"

                Write-Host "-----------------------------------------------"
                Write-Host "Target:"
                Write-Host "    Directory: $path"
                Write-Host "    Platform: $platName"
                Write-Host "    Version: $vers"
                Write-Host "    Architecture: $arch"
                Write-Host "    Generator: $genName"
    
                # Delete target directory if exists to ensure that CMake cache is cleared out.
                If (Test-Path $path) { 
                    Remove-Item -Recurse -Force $path
                }

                # Validate if required directory exists, create if it doesn't
                New-Item -ItemType Directory -Force -Path $path

                # Change location to the respective subdirectory
                Push-Location -Path $path

                # Perform the build
                Write-Host "Performing build:"
                Write-Host "    cmake -G $genName -DCMAKE_SYSTEM_NAME:String=$platName -DCMAKE_SYSTEM_VERSION:String=$vers $SRC"
                Write-Host "-----------------------------------------------"
                cmake -G $genName -DCMAKE_SYSTEM_NAME:String=$platName -DCMAKE_SYSTEM_VERSION:String=$vers $SRC

                # REFERENCE:
                # Executed from '$SRC/bin' folder.
                # Targeting x86 WindowsPhone 8.1.
                #cmake -G "Visual Studio 12 2013" -DCMAKE_SYSTEM_NAME:String=WindowsPhone -DCMAKE_SYSTEM_VERSION:String=8.1 ..
    
                # Return back to Sources folder
                Pop-Location
            }
        }
    }

    # Return back to Script folder
    Pop-Location
}

Function ShowHelp() {
    Write-Host "Configures OpenCV and generates projects for specified verion of Visual Studio/platforms/architectures."
    Write-Host "Must be executed from the sources folder containing main CMakeLists configuration."
    Write-Host "Parameter keys can be shortened down to a signle symbol (e.g. '-a') and are not case sensitive."
    Write-Host "Proper parameter sequensing is required when omitting keys." 
    Write-Host "Generates the following folder structure, depending on the supplied parameters: "
    Write-Host "     bin/ "
    Write-Host "      | "
    Write-Host "      |-WP "
    Write-Host "      |  ... "
    Write-Host "      |-WinRT "
    Write-Host "      |  |-8.0 "
    Write-Host "      |  |-8.1 "
    Write-Host "      |  |  |-x86 "
    Write-Host "      |  |  |-x64 "
    Write-Host "      |  |  |-ARM "
    Write-Host " "     		
    Write-Host " USAGE: "
    Write-Host "   Calling:"
    Write-Host "     PS> setup_winrt.ps1 [params]"
    Write-Host "     cmd> setup_winrt.bat [params]"
    Write-Host "     cmd> PowerShell.exe -ExecutionPolicy Unrestricted -File setup_winrt.ps1 [params]"
    Write-Host "   Parameters:"
    Write-Host "     setup_winrt [platform] [version] [architecture] [generator] "
    Write-Host "     setup_winrt WP x86,ARM "
    Write-Host "     setup_winrt -architecture x86 -platform WP "
    Write-Host "     setup_winrt -arc x86 -plat WP,WS "
    Write-Host "     setup_winrt -a x86 -g 'Visual Studio 11 2012' -pl WP "
    Write-Host " WHERE: "
    Write-Host "     platform -  Array of target platforms. "
    Write-Host "                 Default: WP "
    Write-Host "                 Example: WS,WP "
    Write-Host "                 Options: WP, WS ('WindowsPhone', 'WindowsStore'). "
    Write-Host "     version - Array of platform versions. "
    Write-Host "                 Default: 8.1 "
    Write-Host "                 Example: '8.0','8.1' "
    Write-Host "                 Options: 8.0, 8.1. Available options may be limited depending on your local setup (e.g. SDK availability). " 
    Write-Host "                 Note that you'll need to use quotes to specify more than one version. "
    Write-Host "     architecture - Array of target architectures to build for. "
    Write-Host "                 Default: x86 "
    Write-Host "                 Example: ARM,x64 "
    Write-Host "                 Options: x86, ARM, x64. Available options may be limited depending on your local setup. "
    Write-Host "     generator - Visual Studio instance used to generate the projects. "
    Write-Host "                 Default: Visual Studio 12 2013 "
    Write-Host "                 Example: Visual Studio 11 2012 "
    Write-Host "                 Use 'cmake --help' to find all available option on your machine. "

    Exit
}

Execute