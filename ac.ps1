#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# ----- TTY & ANSI Color Setup -----
$IsTty = (-not [Console]::IsOutputRedirected) -and ($null -eq $env:NO_COLOR)
$Esc = [char]27
if ($IsTty) {
    $C_Reset   = "$Esc[0m"
    $C_Bold    = "$Esc[1m"
    $C_Dim     = "$Esc[2m"
    $C_Red     = "$Esc[1;31m"
    $C_Green   = "$Esc[1;32m"
    $C_Yellow  = "$Esc[1;33m"
    $C_Blue    = "$Esc[1;34m"
    $C_Magenta = "$Esc[1;35m"
    $C_Cyan    = "$Esc[1;36m"
    $C_BgMatch = "$Esc[43;30;1m"
} else {
    $C_Reset   = ""
    $C_Bold    = ""
    $C_Dim     = ""
    $C_Red     = ""
    $C_Green   = ""
    $C_Yellow  = ""
    $C_Blue    = ""
    $C_Magenta = ""
    $C_Cyan    = ""
    $C_BgMatch = ""
}

function Write-Status([string]$Verb, [string]$Message, [string]$Color = $C_Green) {
    $padded = $Verb.PadLeft(12)
    Write-Host "${Color}${padded}${C_Reset} $Message"
}

function Write-CliError([string]$Message, [string]$UsageHint = "") {
    Write-Host "${C_Red}error:${C_Reset} ${C_Bold}${Message}${C_Reset}"
    if ($UsageHint -ne "") {
        Write-Host ""
        Write-Host "${C_Bold}${C_Green}Usage:${C_Reset} ${C_Cyan}$UsageHint${C_Reset}"
    }
    Write-Host ""
    Write-Host "For more information, try '${C_Cyan}.\ac --help${C_Reset}'."
    exit 1
}

function Show-Help {
    Write-Host "${C_Bold}AtCoder CLI Helper for Rust (1.89.0)${C_Reset}"
    Write-Host ""
    Write-Host "${C_Bold}${C_Green}Usage:${C_Reset} ${C_Cyan}.\ac${C_Reset} ${C_Cyan}<COMMAND>${C_Reset} [ARGS]..."
    Write-Host ""
    Write-Host "${C_Bold}${C_Green}Commands:${C_Reset}"
    Write-Host "  ${C_Cyan}new${C_Reset}  <CONTEST>              Create contest directory (a.rs - g.rs) and register bins"
    Write-Host "  ${C_Cyan}run${C_Reset}  <CONTEST> <PROBLEM>    Run problem with input.txt  ${C_Dim}(or: .\ac run <PATH>)${C_Reset}"
    Write-Host "  ${C_Cyan}copy${C_Reset} <CONTEST> <PROBLEM>    Strip dbg! and copy code    ${C_Dim}(or: .\ac copy <PATH>)${C_Reset}"
    Write-Host "  ${C_Cyan}note${C_Reset} [QUERY]...             Browse or search Rust/AtCoder wiki notes in notes/"
    Write-Host "  ${C_Cyan}help${C_Reset}                        Print this message"
    Write-Host ""
    Write-Host "${C_Bold}${C_Green}Options:${C_Reset}"
    Write-Host "  ${C_Cyan}-r${C_Reset}, ${C_Cyan}--release${C_Reset}               Build and run in release mode (RUST_BACKTRACE=0)"
    Write-Host "  ${C_Cyan}-h${C_Reset}, ${C_Cyan}--help${C_Reset}                  Print help"
    Write-Host ""
    Write-Host "${C_Bold}${C_Green}Examples:${C_Reset}"
    Write-Host "  ${C_Dim}`$${C_Reset} .\ac new abc400"
    Write-Host "  ${C_Dim}`$${C_Reset} .\ac run abc400 a"
    Write-Host "  ${C_Dim}`$${C_Reset} .\ac copy abc400 a"
    Write-Host "  ${C_Dim}`$${C_Reset} .\ac note"
    Write-Host "  ${C_Dim}`$${C_Reset} .\ac note segtree"
}

# ----- Target Resolution -----
function Resolve-ProblemTarget([string[]]$RestArgs) {
    if ($RestArgs.Count -eq 1) {
        $arg = $RestArgs[0]
        if ($arg -match '([a-zA-Z0-9_-]+)[/\\]([a-zA-Z0-9_-]+)\.rs$') {
            $dir = $Matches[1].ToLower()
            $prob = $Matches[2].ToLower()
            if ($dir -eq "src" -and $prob -eq "main") {
                return @{ Bin = "main"; Path = "src/main.rs"; Display = "src/main.rs" }
            }
            return @{ Bin = "${dir}-${prob}"; Path = "${dir}/${prob}.rs"; Display = "${dir}/${prob}.rs" }
        }
        Write-CliError "missing argument '<PROBLEM>'" ".\ac <run|copy> <CONTEST> <PROBLEM>"
    } elseif ($RestArgs.Count -ge 2) {
        $contest = $RestArgs[0].ToLower()
        $prob = ($RestArgs[1] -replace '\.rs$', '').ToLower()
        return @{ Bin = "${contest}-${prob}"; Path = "${contest}/${prob}.rs"; Display = "${contest}/${prob}.rs" }
    } else {
        Write-CliError "the following required arguments were not provided: <CONTEST> <PROBLEM>" ".\ac <run|copy> <CONTEST> <PROBLEM>"
    }
}

# ----- Strip dbg! Logic -----
function Strip-Dbg([string]$Source) {
    $patternMacro = '(?m)^#\[cfg\(not\(debug_assertions\)\)\]\r?\n#\[allow\(unused_macros\)\]\r?\nmacro_rules!\s+dbg\s*\{\r?\n.*?\r?\n\}\r?\n?'
    $cleaned = [regex]::Replace($Source, $patternMacro, "")

    $lines = $cleaned -split "\r?\n"
    $outLines = New-Object System.Collections.Generic.List[string]
    $inDbg = $false
    $parenDepth = 0

    foreach ($line in $lines) {
        if (-not $inDbg) {
            if ($line -match '^\s*dbg!\s*\(') {
                $opens = ([regex]::Matches($line, '\(')).Count
                $closes = ([regex]::Matches($line, '\)')).Count
                $parenDepth = $opens - $closes
                if ($parenDepth -gt 0) {
                    $inDbg = $true
                }
                continue
            }
            $outLines.Add($line)
        } else {
            $opens = ([regex]::Matches($line, '\(')).Count
            $closes = ([regex]::Matches($line, '\)')).Count
            $parenDepth += ($opens - $closes)
            if ($parenDepth -le 0) {
                $inDbg = $false
            }
        }
    }

    $result = ($outLines -join "`r`n")
    $result = [regex]::Replace($result, '(\r?\n){3,}', "`r`n`r`n")
    return $result.Trim() + "`r`n"
}

# ----- Wiki Note Parsing & Rendering -----
function Parse-NoteFile([System.IO.FileInfo]$File, [string]$NotesRoot) {
    $relPath = $File.FullName.Substring($NotesRoot.Length + 1).Replace('\', '/')
    $slug = $relPath -replace '\.md$', ''
    $category = if ($slug.Contains('/')) { $slug.Substring(0, $slug.LastIndexOf('/')) } else { "root" }

    $lines = Get-Content $File.FullName -Encoding UTF8
    $title = $slug
    $tags = ""
    $sections = New-Object System.Collections.Generic.List[hashtable]

    $curHeading = ""
    $curStartLine = 1
    $curLines = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $lineNum = $i + 1
        if ($line -match '^#\s+(.+)$' -and $title -eq $slug) {
            $title = $Matches[1].Trim()
        } elseif ($line -match '^tags:\s*(.+)$' -and $tags -eq "") {
            $tags = $Matches[1].Trim()
        } elseif ($line -match '^##\s+(.+)$') {
            if ($curHeading -ne "" -or $curLines.Count -gt 0) {
                if ($curHeading -ne "") {
                    $sections.Add(@{
                        Heading = $curHeading
                        StartLine = $curStartLine
                        Body = ($curLines -join "`n").Trim()
                    })
                }
            }
            $curHeading = $Matches[1].Trim()
            $curStartLine = $lineNum
            $curLines = New-Object System.Collections.Generic.List[string]
        } else {
            $curLines.Add($line)
        }
    }

    if ($curHeading -ne "") {
        $sections.Add(@{
            Heading = $curHeading
            StartLine = $curStartLine
            Body = ($curLines -join "`n").Trim()
        })
    } elseif ($sections.Count -eq 0 -and $curLines.Count -gt 0) {
        $sections.Add(@{
            Heading = $title
            StartLine = 1
            Body = ($curLines -join "`n").Trim()
        })
    }

    return @{
        Slug = $slug
        RelPath = "notes/$relPath"
        Category = $category
        Title = $title
        Tags = $tags
        Sections = $sections
    }
}

function Highlight-Terms([string]$Text, [string[]]$Terms) {
    if (-not $IsTty -or $null -eq $Terms -or $Terms.Count -eq 0) {
        return $Text
    }
    $res = $Text
    foreach ($t in $Terms) {
        if ($t.Length -gt 0) {
            $escaped = [regex]::Escape($t)
            $res = [regex]::Replace($res, "(?i)($escaped)", "${C_BgMatch}`$1${C_Reset}")
        }
    }
    return $res
}

function Render-Section([hashtable]$Note, [hashtable]$Sec, [string[]]$HighlightTerms) {
    $headingStr = Highlight-Terms $Sec.Heading $HighlightTerms
    $loc = "$($Note.RelPath):$($Sec.StartLine)"
    Write-Host "${C_Bold}${C_Yellow}## ${headingStr}${C_Reset}  ${C_Dim}[$loc]${C_Reset}"

    $inCode = $false
    foreach ($line in ($Sec.Body -split "`n")) {
        if ($line -match '^```') {
            $inCode = -not $inCode
            continue
        }
        if ($inCode) {
            if ($line -match '^\s*//') {
                Write-Host "    ${C_Dim}$line${C_Reset}"
            } else {
                $hl = Highlight-Terms $line $HighlightTerms
                Write-Host "    ${C_Cyan}$hl${C_Reset}"
            }
        } else {
            $hl = Highlight-Terms $line $HighlightTerms
            Write-Host "  $hl"
        }
    }
    Write-Host ""
}

function Invoke-NoteCommand([string[]]$QueryArgs, [string]$RootDir) {
    $notesRoot = Join-Path $RootDir "notes"
    if (-not (Test-Path $notesRoot)) {
        Write-CliError "notes/ directory not found"
    }

    $mdFiles = Get-ChildItem -Path $notesRoot -Filter "*.md" -Recurse | Sort-Object FullName
    $notes = foreach ($f in $mdFiles) {
        Parse-NoteFile $f $notesRoot
    }

    # No args -> Show Wiki Directory Tree
    if ($QueryArgs.Count -eq 0) {
        Write-Host "${C_Bold}Rust & AtCoder Wiki Notes${C_Reset} ${C_Dim}($($notes.Count) pages in notes/)${C_Reset}"
        Write-Host ""

        $grouped = $notes | Group-Object { $_.Category }
        foreach ($g in $grouped) {
            Write-Host "${C_Bold}${C_Green}[$($g.Name)]${C_Reset}"
            foreach ($n in $g.Group) {
                $padSlug = $n.Slug.PadRight(24)
                $tagInfo = if ($n.Tags -ne "") { " ${C_Dim}# $($n.Tags)${C_Reset}" } else { "" }
                Write-Host "  ${C_Cyan}${padSlug}${C_Reset} $($n.Title)${tagInfo}"
            }
            Write-Host ""
        }
        Write-Host "${C_Dim}Tip: Run '.\ac note <SLUG>' to read a page, or '.\ac note <KEYWORD>...' to search.${C_Reset}"
        return
    }

    # Check exact/suffix slug match (when single query arg matches a page path)
    if ($QueryArgs.Count -eq 1) {
        $q = ($QueryArgs[0].Replace('\', '/') -replace '^notes/', '' -replace '\.md$', '').ToLower()
        $exactPage = $notes | Where-Object {
            $_.Slug.ToLower() -eq $q -or ($_.Slug.Split('/')[-1].ToLower() -eq $q)
        } | Select-Object -First 1

        if ($null -ne $exactPage) {
            Write-Status "Page" "$($exactPage.Title) ${C_Dim}($($exactPage.RelPath))${C_Reset}" $C_Green
            if ($exactPage.Tags -ne "") {
                Write-Host "        ${C_Dim}tags: $($exactPage.Tags)${C_Reset}"
            }
            Write-Host ""
            foreach ($sec in $exactPage.Sections) {
                Render-Section $exactPage $sec @()
            }
            return
        }
    }

    # Multi-keyword Wiki Search across sections
    $terms = $QueryArgs | ForEach-Object { $_.ToLower() }
    $matchedList = New-Object System.Collections.Generic.List[hashtable]

    # First pass: match against section heading + section body + file slug
    foreach ($n in $notes) {
        $slugMeta = $n.Slug.ToLower()
        foreach ($sec in $n.Sections) {
            $haystack = "$slugMeta $($sec.Heading) $($sec.Body)".ToLower()
            $allMatch = $true
            foreach ($t in $terms) {
                if (-not $haystack.Contains($t)) {
                    $allMatch = $false
                    break
                }
            }
            if ($allMatch) {
                $matchedList.Add(@{ Note = $n; Section = $sec })
            }
        }
    }

    # Fallback: if no specific section matched, include page title & tags in haystack
    if ($matchedList.Count -eq 0) {
        foreach ($n in $notes) {
            $pageMeta = "$($n.Slug) $($n.Title) $($n.Tags)".ToLower()
            foreach ($sec in $n.Sections) {
                $haystack = "$pageMeta $($sec.Heading) $($sec.Body)".ToLower()
                $allMatch = $true
                foreach ($t in $terms) {
                    if (-not $haystack.Contains($t)) {
                        $allMatch = $false
                        break
                    }
                }
                if ($allMatch) {
                    $matchedList.Add(@{ Note = $n; Section = $sec })
                }
            }
        }
    }

    if ($matchedList.Count -eq 0) {
        Write-Status "Search" "0 matches for '${C_Bold}$($QueryArgs -join ' ')${C_Reset}'" $C_Yellow
        Write-Host "  ${C_Dim}Try '.\ac note' to list all available topics and tags.${C_Reset}"
        return
    }

    Write-Status "Found" "$($matchedList.Count) section(s) matching '${C_Bold}$($QueryArgs -join ' ')${C_Reset}'" $C_Green
    Write-Host ""

    foreach ($m in $matchedList) {
        Render-Section $m.Note $m.Section $QueryArgs
    }
}

# ----- Argument Parsing -----
$Release = $false
$Positional = New-Object System.Collections.Generic.List[string]

foreach ($a in $args) {
    if ($a -eq "-h" -or $a -eq "--help" -or $a -eq "help") {
        Show-Help
        exit 0
    } elseif ($a -eq "-r" -or $a -eq "--release") {
        $Release = $true
    } else {
        $Positional.Add($a)
    }
}

if ($Positional.Count -eq 0) {
    Show-Help
    exit 0
}

$Command = $Positional[0].ToLower()
$Rest = @()
if ($Positional.Count -gt 1) {
    $Rest = $Positional[1..($Positional.Count - 1)]
}

$RootDir = $PSScriptRoot
Set-Location $RootDir

switch ($Command) {
    "new" {
        if ($Rest.Count -lt 1) {
            Write-CliError "the following required arguments were not provided: <CONTEST>" ".\ac new <CONTEST>"
        }
        $contest = $Rest[0].ToLower()
        $contestDir = Join-Path $RootDir $contest
        $templatePath = Join-Path $RootDir "template.rs"
        $cargoTomlPath = Join-Path $RootDir "Cargo.toml"

        if (-not (Test-Path $templatePath)) {
            Write-CliError "template.rs not found in workspace root"
        }

        if (-not (Test-Path $contestDir)) {
            New-Item -ItemType Directory -Path $contestDir | Out-Null
            Write-Status "Created" "directory ${C_Bold}${contest}/${C_Reset}"
        }

        $problems = @("a", "b", "c", "d", "e", "f", "g")
        $cargoContent = Get-Content $cargoTomlPath -Raw
        $addedBins = @()

        foreach ($p in $problems) {
            $filePath = Join-Path $contestDir "${p}.rs"
            $relPath = "${contest}/${p}.rs"
            $binName = "${contest}-${p}"

            if (-not (Test-Path $filePath)) {
                Copy-Item $templatePath $filePath
                Write-Status "Created" "${relPath}"
            } else {
                Write-Status "Skipped" "${relPath} ${C_Dim}(already exists)${C_Reset}" $C_Yellow
            }

            if ($cargoContent -notmatch "(?m)^name\s*=\s*`"$([regex]::Escape($binName))`"") {
                $binEntry = "`r`n[[bin]]`r`nname = `"$binName`"`r`npath = `"$relPath`"`r`n"
                Add-Content -Path $cargoTomlPath -Value $binEntry -NoNewline
                $addedBins += $binName
            }
        }

        if ($addedBins.Count -gt 0) {
            Write-Status "Registered" "$($addedBins.Count) bin targets in Cargo.toml ${C_Dim}($($contest)-a .. $($contest)-g)${C_Reset}" $C_Cyan
        }
    }

    "run" {
        $target = Resolve-ProblemTarget $Rest
        $filePath = Join-Path $RootDir $target.Path
        $inputPath = Join-Path $RootDir "input.txt"

        if (-not (Test-Path $filePath)) {
            Write-CliError "source file not found: $($target.Display)"
        }
        if (-not (Test-Path $inputPath)) {
            New-Item -ItemType File -Path $inputPath | Out-Null
        }

        $modeLabel = if ($Release) { "release" } else { "dev" }
        Write-Status "Compiling" "$($target.Display) ${C_Dim}($modeLabel)${C_Reset}" $C_Cyan

        if ($Release) {
            & cargo build --release --quiet --bin $target.Bin
        } else {
            & cargo build --quiet --bin $target.Bin
        }
        if ($LASTEXITCODE -ne 0) {
            Write-CliError "compilation failed for $($target.Display)"
        }

        $exePath = Join-Path $RootDir "target\$(if ($Release) { 'release' } else { 'debug' })\$($target.Bin).exe"
        Write-Status "Running" "`"$($target.Display)`" < input.txt" $C_Green
        Write-Host "${C_Dim}----- Output -----${C_Reset}"

        $prevBacktrace = $env:RUST_BACKTRACE
        if ($Release) {
            $env:RUST_BACKTRACE = "0"
        }
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Get-Content $inputPath -Raw | & $exePath
        $exitCode = $LASTEXITCODE
        $sw.Stop()
        $env:RUST_BACKTRACE = $prevBacktrace

        $elapsedMs = $sw.ElapsedMilliseconds
        $timeColor = if ($elapsedMs -lt 500) { $C_Green } elseif ($elapsedMs -lt 2000) { $C_Yellow } else { $C_Red }
        Write-Host "${C_Dim}------------------${C_Reset}"
        if ($exitCode -eq 0) {
            Write-Status "Finished" "in ${timeColor}${elapsedMs} ms${C_Reset}" $C_Green
        } else {
            Write-Status "Failed" "exit code $exitCode (${timeColor}${elapsedMs} ms${C_Reset})" $C_Red
            exit $exitCode
        }
    }

    "copy" {
        $target = Resolve-ProblemTarget $Rest
        $filePath = Join-Path $RootDir $target.Path

        if (-not (Test-Path $filePath)) {
            Write-CliError "source file not found: $($target.Display)"
        }

        $raw = Get-Content $filePath -Raw
        $cleaned = Strip-Dbg $raw
        Set-Clipboard -Value $cleaned

        $cleanLines = ($cleaned.TrimEnd() -split "\r?\n").Count
        Write-Status "Copied" "$($target.Display) -> Clipboard ${C_Dim}($cleanLines lines, stripped dbg!)${C_Reset}" $C_Green
    }

    "note" {
        Invoke-NoteCommand $Rest $RootDir
    }

    default {
        Write-CliError "unrecognized subcommand '$Command'" ".\ac <new|run|copy|note> [ARGS]..."
    }
}
