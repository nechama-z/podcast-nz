# ================= CONFIG =================
$AudioDir = "."
$BaseUrl = "https://nechama-z.github.io/podcast-nz"   # CHANGE THIS
$OutputFile = "feed.xml"

$FeedTitle = "Hakivun Shiur"
$Author = "Mrs Raizy Hirth"
$Description = "Shiurim from Hakivun by Mrs. Raizy Hirth"
$Email = "ngurwitz@gmail.com"
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

    if ($_.Extension -notmatch "mp3|m4a|mpa") {
        Write-Host "  Skipped (extension)"
        return
    }

    if ($_.Name -notmatch "(\d{1,2}\.\d{1,2}\.\d{2})") {
        Write-Host "  Skipped (no date)"
        return
    }

    $date = [datetime]::ParseExact($matches[1], "MM.dd.yy", $null)
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

AddNode $channel "title" $FeedTitle
AddNode $channel "link" $BaseUrl
AddNode $channel "language" $Language
AddNode $channel "description" $Description
AddNode $channel "itunes:author" $Author
AddNode $channel "itunes:explicit" "no"

$owner = $xml.CreateElement("itunes:owner")
AddNode $owner "itunes:name" $Author
AddNode $owner "itunes:email" $Email
$channel.AppendChild($owner) | Out-Null

foreach ($ep in $episodes) {

    Write-Host "Adding episode:" $ep.Title

    $item = $xml.CreateElement("item")
    AddNode $item "title" $ep.Title
    AddNode $item "pubDate" $ep.PubDate.ToString("r")

    $url = "$BaseUrl/$($ep.FileName -replace ' ','%20')"
    AddNode $item "guid" $url

    $enc = $xml.CreateElement("enclosure")
    $enc.SetAttribute("url",$url)
    $enc.SetAttribute("length",$ep.Size)
    $enc.SetAttribute("type",$ep.Mime)
    $item.AppendChild($enc) | Out-Null

    $channel.AppendChild($item) | Out-Null
}

$xml.Save($OutputFile)
Write-Host "DONE. RSS written to $OutputFile"