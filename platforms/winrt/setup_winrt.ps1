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
    $PLATFORMS_IN = "WP",

    [parameter(Mandatory=$False)]
    [Array]
    [ValidateNotNull()]
    $VERSIONS_IN = "8.1",

    [parameter(Mandatory=$False)]
    [Array]
    [ValidateNotNull()]
    $ARCHITECTURES_IN = "x86",

    [parameter(Mandatory=$False)]
    [String]
    [ValidateNotNull()]
    [ValidateSet("Visual Studio 12 2013","Visual Studio 11 2012")]
    $GENERATOR = "Visual Studio 12 2013"
)


Function L() {
    Param(
        [parameter(Mandatory=$true)]
        [String]
        [ValidateNotNull()]
        $str
    )

    Write-Host "INFO> $str"
}

Function D() {
    Param(
        [parameter(Mandatory=$true)]
        [String]
        [ValidateNotNull()]
        $str
    )
    
    # Use this trigger to toggle debug output
    [bool]$debug = $true

    if ($debug) {
        Write-Host "DEBUG> $str"
    }
}

Function Execute() {
    If ($HELP.IsPresent) {
        ShowHelp
    }

    # Validating arguments. 
    # This type of validation (rather than using ValidateSet()) is required to make .bat wrapper work

    D "Input Platforms: $PLATFORMS_IN" 
    $platforms = New-Object System.Collections.ArrayList
    $PLATFORMS_IN.Split("," ,[System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
        if ("WP","WS" -Contains $_) {
            [void]$platforms.Add($_)
            D "$_ is valid"
        } else {
            Throw "$($_) is not valid! Please use WP, WS" 
        }
    }
    D "Processed Platforms: $platforms"

    D "Input Versions: $VERSIONS_IN"
    $versions = New-Object System.Collections.ArrayList
    $VERSIONS_IN.Split("," ,[System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
        if ("8.0","8.1" -Contains $_) {
            [void]$versions.Add($_)
            D "$_ is valid" 
        } else {
            Throw "$($_) is not valid! Please use 8.0, 8.1" 
        }
    }
    D "Processed Versions: $versions"

    D "Input Architectures: $ARCHITECTURES_IN"
    $architectures = New-Object System.Collections.ArrayList
    $ARCHITECTURES_IN.Split("," ,[System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
        if ("x86","x64","ARM" -Contains $_) {
            $architectures.Add($_) > $null
            D "$_ is valid"
        } else {
            Throw "$($_) is not valid! Please use x86, x64, ARM" 
        }
    }
    D "Processed Architectures: $architectures"

    #Assuming we are in '<ocv-sources>/platforms/winrt' we should move up to sources root directory
    Push-Location ../../
        
    $SRC = Get-Location

    $def_architectures = @{
        "x86" = "";
        "x64" = " Win64"
        "arm" = " ARM"
    }

    foreach($plat in $platforms) {
        # Set proper platform name.
        $platName = ""
        Switch ($plat) {
            "WP" { $platName = "WindowsPhone" }
            "WS" { $platName = "WindowsStore" }
        }

        foreach($vers in $versions) {

            foreach($arch in $architectures) {

                # Set proper architecture. For MSVS this is done by selecting proper generator
                $genName = $GENERATOR
                Switch ($arch) {
                    "ARM" { $genName = $GENERATOR + $def_architectures['arm'] }
                    "x64" { $genName = $GENERATOR + $def_architectures['x64'] }
                }

                $path = "$SRC\bin\$plat\$vers\$arch"

                L "-----------------------------------------------"
                L "Target:" 
                L "    Directory: $path" 
                L "    Platform: $platName" 
                L "    Version: $vers"
                L "    Architecture: $arch"
                L "    Generator: $genName"
    
                # Delete target directory if exists to ensure that CMake cache is cleared out.
                If (Test-Path $path) { 
                    Remove-Item -Recurse -Force $path
                }

                # Validate if required directory exists, create if it doesn't
                New-Item -ItemType Directory -Force -Path $path

                # Change location to the respective subdirectory
                Push-Location -Path $path

                # Perform the build
                L "Performing build:" 
                L "cmake -G $genName -DCMAKE_SYSTEM_NAME:String=$platName -DCMAKE_SYSTEM_VERSION:String=$vers $SRC" 
                cmake -G $genName -DCMAKE_SYSTEM_NAME:String=$platName -DCMAKE_SYSTEM_VERSION:String=$vers -DCMAKE_VS_EFFECTIVE_PLATFORMS:String=$arch $SRC
                L "-----------------------------------------------"

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
    Write-Host "     setup_winrt WP 'x86,ARM' "
    Write-Host "     setup_winrt -architecture x86 -platform WP "
    Write-Host "     setup_winrt -arc x86 -plat 'WP,WS' "
    Write-Host "     setup_winrt -a x86 -g 'Visual Studio 11 2012' -pl WP "
    Write-Host " WHERE: "
    Write-Host "     platform -  Array of target platforms. "
    Write-Host "                 Default: WP "
    Write-Host "                 Example: 'WS,WP' "
    Write-Host "                 Options: WP, WS ('WindowsPhone', 'WindowsStore'). "
    Write-Host "                 Note that you'll need to use quotes to specify more than one platform. "
    Write-Host "     version - Array of platform versions. "
    Write-Host "                 Default: 8.1 "
    Write-Host "                 Example: '8.0,8.1' "
    Write-Host "                 Options: 8.0, 8.1. Available options may be limited depending on your local setup (e.g. SDK availability). " 
    Write-Host "                 Note that you'll need to use quotes to specify more than one version. "
    Write-Host "     architecture - Array of target architectures to build for. "
    Write-Host "                 Default: x86 "
    Write-Host "                 Example: 'ARM,x64' "
    Write-Host "                 Options: x86, ARM, x64. Available options may be limited depending on your local setup. "
    Write-Host "                 Note that you'll need to use quotes to specify more than one architecture. "
    Write-Host "     generator - Visual Studio instance used to generate the projects. "
    Write-Host "                 Default: Visual Studio 12 2013 "
    Write-Host "                 Example: 'Visual Studio 11 2012' "
    Write-Host "                 Use 'cmake --help' to find all available option on your machine. "

    Exit
}

Execute