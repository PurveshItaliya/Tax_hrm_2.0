$content = Get-Content -Raw -Encoding UTF8 'd:\Umang\Tax_hrm_2.0\lib\page\attendance\viewAttendance_screen.dart'
$idx = $content.IndexOf('Future<void> showDayDetails')
if ($idx -gt 0) {
    $top = $content.Substring(0, $idx)
    $bottom = $content.Substring($idx)
    $bottom = $bottom -replace 'setDataLog', 'currentDataLog'
    $content = $top + $bottom
    Set-Content -Path 'd:\Umang\Tax_hrm_2.0\lib\page\attendance\viewAttendance_screen.dart' -Value $content -Encoding UTF8
}
