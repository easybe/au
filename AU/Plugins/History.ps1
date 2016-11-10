# Author: Miodrag Milic <miodrag.milic@gmail.com>
# Last Change: 10-Nov-2016.

param(
    $Info,
    $Lines=30,
    $Github_UserRepo = 'chocolatey/chocolatey-coreteampackages',
    $Path = "UpdateHistory.md"
)

Write-Host "Saving history to $Path"

$res=[ordered]@{}
$log = git --no-pager log -q --grep '^AU: ' --date iso | Out-String
$all_commits = $log | sls 'commit(.|\n)+?(?=\ncommit )' -AllMatches
foreach ($commit in $all_commits.Matches.Value) {
    $commit = $commit -split '\n'

    $id       = $commit[0].Replace('commit','').Trim().Substring(0,7)
    $date     = $commit[2].Replace('Date:','').Trim()
    $date     = ([datetime]$date).Date.ToString("yyyy-MM-dd")
    $report   = $commit[5].Replace('[skip ci]','').Trim()
    $packages = ($commit[4] -replace '^\s+AU:.+?(-|:) |\[skip ci\]').Trim()

    $packages_md = $packages -split ' ' | % {
        $first = $_.Substring(0,1).ToUpper(); $rest  = $_.Substring(1)
        if ($report) {
            "[$firt]($report)[$rest](https://github.com/$Github_UserRepo/commit/$id)"
        } else {
            "[$_](https://github.com/$Github_UserRepo/commit/$id)"
        }
    }

    if (!$res.Contains($date)) { $res.$date=@() }
    $res.$date += $packages_md
}

$res = $res | select -First $Lines

$history = "# Update History`n"
foreach ($kv in $res.GetEnumerator()) { $history += "`n{0,-25} {1}`n" -f "**$($kv.Key)**", "$($kv.Value -join ' &ndash; ')" }
$history | Out-File $Path
