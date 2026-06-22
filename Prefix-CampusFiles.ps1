<#
    Prefix-CampusFiles.ps1

    What this does:
    For every file in this script's folder, it creates a prefixed copy inside a
    new sub-folder named after the campus, and writes a list called the_list.csv
    in that same sub-folder for the policy details. The original files are not
    changed.

    Example, with the campus name "Mamzar":
        Assessment Policy.docx  ->  .\Mamzar\Mamzar_Assessment Policy.docx
        plus .\Mamzar\the_list.csv listing each file with columns to fill in.

    It confirms the folder, asks for the campus name, shows a preview of the new
    names, and lets you change the name or continue before anything is created.

    Run it by double-clicking "Add_a_Prefix.bat", or from PowerShell.
#>

$ErrorActionPreference = "Stop"

# The folder this script lives in. Every file here is treated as a document to prefix.
$folder = $PSScriptRoot
if (-not $folder) { $folder = (Get-Location).Path }

# --- Helper functions --------------------------------------------------------

function LH-ReadYesNo([string]$question) {
    while ($true) {
        $answer = (Read-Host "$question (Y/N)").Trim().ToUpper()
        if ($answer -eq "Y") { return $true }
        if ($answer -eq "N") { return $false }
        Write-Host "Please type Y or N."
    }
}

function LH-ReadCampusName {
    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    while ($true) {
        Write-Host ""
        Write-Host "What is the campus name to add to the files?"
        Write-Host "Be exact with the capitalisation, for example Mamzar with a capital M, not mamzar."
        $name = (Read-Host "Campus name").Trim().TrimEnd("_").Trim()
        if ($name -eq "") {
            Write-Host "The campus name cannot be empty."
            continue
        }
        if (@($name.ToCharArray() | Where-Object { $invalid -contains $_ }).Count -gt 0) {
            Write-Host "That name has characters that are not allowed in a folder name. Please try again."
            continue
        }
        return $name
    }
}

function LH-GetFilesToPrefix([string]$path) {
    # Every file in the folder, except the tool's own .bat and .ps1 files.
    return Get-ChildItem -LiteralPath $path -File |
        Where-Object { $_.Extension -ne ".bat" -and $_.Extension -ne ".ps1" }
}

# --- Confirm the folder ------------------------------------------------------

Write-Host "============================================================"
Write-Host " Add a campus prefix to policy files"
Write-Host "============================================================"
Write-Host ""
Write-Host "Folder: $folder"

$files = @(LH-GetFilesToPrefix $folder)
if ($files.Count -eq 0) {
    Write-Host ""
    Write-Host "There are no files to prefix in this folder. Nothing to do."
    return
}

Write-Host "Files found: $($files.Count)"
Write-Host ""
if (-not (LH-ReadYesNo "Is this the correct folder, with all the files that need the change?")) {
    Write-Host ""
    Write-Host "No changes made. Put this tool in the folder with the files, then run it again."
    return
}

# --- Campus name, confirmation and preview loop ------------------------------

$campus = ""
$prefix = ""

while ($true) {
    $campus = LH-ReadCampusName
    $prefix = $campus + "_"

    Write-Host ""
    Write-Host "Campus name entered: $campus"
    Write-Host "Files will be prefixed with: $prefix"
    Write-Host "A new folder will be created: $campus"
    if (-not (LH-ReadYesNo "Is this correct?")) { continue }

    Write-Host ""
    Write-Host "Preview, the copies will be named:"
    Write-Host "------------------------------------------------------------"
    foreach ($file in $files) {
        Write-Host "  $($file.Name)  ->  $prefix$($file.Name)"
    }
    Write-Host "------------------------------------------------------------"
    Write-Host "Destination folder: $(Join-Path $folder $campus)"
    Write-Host "A details list (the_list.csv) will also be created there."
    Write-Host ""
    Write-Host "[C] Continue and create the files"
    Write-Host "[N] Change the campus name"
    Write-Host "[Q] Quit without making changes"
    $choice = (Read-Host "Choose C, N or Q").Trim().ToUpper()

    if ($choice -eq "C") { break }
    if ($choice -eq "Q") {
        Write-Host ""
        Write-Host "No changes made."
        return
    }
    # Any other answer (including N) loops back to ask the campus name again.
}

# --- Create the prefixed copies and the details list ------------------------

$destination = Join-Path $folder $campus
New-Item -ItemType Directory -Path $destination -Force | Out-Null

$created = 0
$failed = @()
$listRows = @()
foreach ($file in $files) {
    $newName = $prefix + $file.Name
    $target = Join-Path $destination $newName
    try {
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        $created++
        $listRows += [PSCustomObject]@{
            "File Name"        = $newName
            "Owner (Author)"   = ""
            "Last Review Date" = ""
            "Next Review Date" = ""
            "Review Cycle"     = ""
        }
    }
    catch {
        $failed += $file.Name
    }
}

# Write the list of files with empty columns to fill in.
if ($listRows.Count -gt 0) {
    $listPath = Join-Path $destination "the_list.csv"
    $listRows | Export-Csv -LiteralPath $listPath -NoTypeInformation -Encoding UTF8
}

Write-Host ""
Write-Host "Done. $created file(s) created in:"
Write-Host "  $destination"
if ($listRows.Count -gt 0) {
    Write-Host ""
    Write-Host "A details sheet was created in that folder: the_list.csv"
    Write-Host "Open it in Excel and fill in the owner, last review, next review and cycle for each file."
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "These files could not be copied, they may be open in another program:"
    foreach ($f in $failed) {
        Write-Host "  $f"
    }
}
