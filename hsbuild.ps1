param (
    $Mode = "help",
    $InitName
)

if($Mode -eq "help") {
    Write-Host "`nUse init to create a new project and build to build the current project"
}
elseif($Mode -eq "run") {
    function Get-ProjectHash {
        $Hash = Get-FileHash main.hs | Format-List -Property Hash | Out-String
        $Hash = $Hash.Trim() -replace "Hash : "
    
        foreach ($File in Get-ChildItem -Path .\Mod -Name) {
            $FileHash = Get-FileHash .\Mod\$File | Format-List -Property Hash | Out-String
            $Hash = $Hash + $FileHash.Trim() -replace "Hash : "
        }
    
        return $Hash
    }
    
    $MainHash = Get-ProjectHash
    
    if(Test-Path .\.filewatch) {
        $StoredHash = Get-Content .\.filewatch | Out-String
    }
    else {
        $StoredHash = ""
    }
    
    if($MainHash.Trim() -eq $StoredHash.Trim()) {
        .\main.exe
    }
    else {
        ghc .\main.hs .\Mod\*.hs
        .\main.exe  
    
        Remove-Item .\* -Include *.hi, *.o
        Remove-Item .\Mod\* -Include *.hi, *.o
        
        $MainHash > .\.filewatch
    }
}
elseif($Mode -eq "init") {
    if([string]::IsNullOrEmpty($InitName)) {
        $ProjectName = Read-Host -Prompt "Enter the name of the project (hsbuild-proj)"

        if([string]::IsNullOrEmpty($ProjectName)) {
            $ProjectName = "hsbuild-proj"
        }
    }
    else {
        $ProjectName = $InitName
    }
    
    New-Item -Path .\ -Name $ProjectName -ItemType "directory" | Out-Null

    New-Item -Path .\$ProjectName -Name "main.hs" -ItemType "file" -Value "import Mod.Module`n`nmain :: IO ()`nmain = func" | Out-Null
    New-Item -Path .\$ProjectName -Name "Mod" -ItemType "directory" | Out-Null
    New-Item -Path .\$ProjectName\Mod -Name "Module.hs" -ItemType "file" -Value "module Mod.Module (`n    func`n) where`n`nfunc :: IO ()`nfunc = putStrLn `"Hello from the other side`"" | Out-Null
}