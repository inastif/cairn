# Configure les fichiers natifs generes par `flutter create` pour le module 2.
# A lancer depuis la racine du projet :
#   powershell -ExecutionPolicy Bypass -File .\tools\configure_native.ps1
# Idempotent : peut etre relance sans risque.

$ErrorActionPreference = "Stop"

function Write-Utf8NoBom($Path, $Content) {
    [System.IO.File]::WriteAllText((Resolve-Path $Path), $Content)
}

# 1. Android : la biometrie exige une FlutterFragmentActivity.
$activity = Get-ChildItem -Path "android\app\src\main" -Recurse -Filter "MainActivity.kt" | Select-Object -First 1
if ($null -eq $activity) { throw "MainActivity.kt introuvable : lance d'abord 'flutter create'." }
$code = Get-Content $activity.FullName -Raw
if ($code -notmatch "FlutterFragmentActivity") {
    $code = $code -replace "io\.flutter\.embedding\.android\.FlutterActivity", "io.flutter.embedding.android.FlutterFragmentActivity"
    $code = $code -replace ":\s*FlutterActivity\(\)", ": FlutterFragmentActivity()"
    Write-Utf8NoBom $activity.FullName $code
    Write-Host "MainActivity : FlutterFragmentActivity OK"
} else {
    Write-Host "MainActivity deja configuree"
}

# 2. Android : Internet (indispensable en release) et biometrie.
$manifestPath = "android\app\src\main\AndroidManifest.xml"
$manifest = Get-Content $manifestPath -Raw
$permissions = @("android.permission.INTERNET", "android.permission.USE_BIOMETRIC")
foreach ($permission in $permissions) {
    if ($manifest -notmatch [regex]::Escape($permission)) {
        $manifest = $manifest -replace "(<application)", "<uses-permission android:name=`"$permission`"/>`r`n    `$1"
        Write-Host "Permission ajoutee : $permission"
    }
}
Write-Utf8NoBom $manifestPath $manifest

# 3. iOS : texte affiche par Face ID (accents en entites XML).
$plistPath = "ios\Runner\Info.plist"
if (Test-Path $plistPath) {
    $plist = Get-Content $plistPath -Raw
    if ($plist -notmatch "NSFaceIDUsageDescription") {
        $entry = "<dict>`r`n`t<key>NSFaceIDUsageDescription</key>`r`n`t<string>Face ID prot&#232;ge l'acc&#232;s &#224; tes donn&#233;es financi&#232;res.</string>"
        $plist = ([regex]"<dict>").Replace($plist, $entry, 1)
        Write-Utf8NoBom $plistPath $plist
        Write-Host "Info.plist : NSFaceIDUsageDescription ajoute"
    } else {
        Write-Host "Info.plist deja configure"
    }
}

Write-Host "`nConfiguration native terminee." -ForegroundColor Green
