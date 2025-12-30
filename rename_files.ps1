$AudioDir = "hakivun"

# Check folder exists
if (-not (Test-Path $AudioDir)) {
    Write-Host "ERROR: Folder $AudioDir not found"
    exit 1
}

# Rename files
Get-ChildItem $AudioDir -File | ForEach-Object {
    $oldName = $_.Name
    # Replace multiple spaces with single underscore
    $newName = ($_.Name -replace '\s+','_')
    if ($oldName -ne $newName) {
        $oldPath = Join-Path $AudioDir $oldName
        $newPath = Join-Path $AudioDir $newName
        Write-Host "Renaming '$oldName' → '$newName'"
        Rename-Item -Path $oldPath -NewName $newName
    }
}
Write-Host "Renaming complete."
Usage:

powershell
powershell -ExecutionPolicy Bypass -File .\rename_files.ps1
This will:

Replace any spaces (single or double) with _

Leave other characters intact

Make filenames GitHub Pages-friendly

Step 2: Updated generate_rss.ps1 for GitHub Pages
powershell
# ================= CONFIG =================
$AudioDir = "hakivun"
$BaseUrl  = "https://nechama-z.github.io/podcast-nz"
$OutputFile = "feed.xml"

$FeedTitle = "Hakivun Shiur"
$Author = "Mrs Raizy Hirth"
$Description = "Shiurim from Hakivun by Mrs. Raizy Hirth"
$Email = "example@example.com"
$Language = "en-us"
# =========================================

Write-Host "Starting RSS generation"
Write-Host "Audio folder:" $AudioDir

if (-not (Test-Path $AudioDir)) {
    Write-Host "ERROR: Audio directory not found"
    exit 1
}

$episodes = @()

Get-ChildItem $AudioDir -File | ForEach-Object {

    Write-Host "Found file:" $_.Name

    # Skip non-audio files
    if ($_.Extension -notmatch "mp3|mp4|m4a|mpa") {
        Write-Host "  Skipped (extension)"
        return
    }

    # Parse date from filename
    if ($_.Name -notmatch "(\d{1,2}\.\d{1,2}\.\d{2})") {
        Write-Host "  Skipped (no date)"
        return
    }

    $date = [datetime]::ParseExact($matches[1], "MM.dd.yy", $null)

    # Set MIME type based on extension
    switch ($_.Extension.ToLower()) {
        ".mp3" { $mime = "audio/mpeg" }
        ".m4a" { $mime = "audio/mp4" }
        ".mp4" { $mime = "audio/mp4" }
        ".mpa" { $mime = "audio/mpeg" }
        default { $mime = "audio/mpeg" }
    }

    $episodes += [PSCustomObject]@{
        Title = [IO.Path]::GetFileNameWithoutExtension($_.Name)
        FileName = $_.Name
        PubDate = $date
        Size = $_.Length
        Mime = $mime
    }
}

Write-Host "Episodes found:" $episodes.Count

$episodes = $episodes | Sort-Object PubDate -Descending

# ---------- Build RSS ----------
$xml = New-Object xml
$rss = $xml.CreateElement("rss")
$rss.SetAttribute("version","2.0")
$rss.SetAttribute("xmlns:itunes","http://www.itunes.com/dtds/podcast-1.0.dtd")
$xml.AppendChild($rss) | Out-Null

$channel = $xml.CreateElement("channel")
$rss.AppendChild($channel) | Out-Null

function AddNode($parent,$name,$value) {
    $n = $xml.CreateElement($name)
    $n.InnerText = $value
    $parent.AppendChild($n) | Out-Null
}



