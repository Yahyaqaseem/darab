$ErrorActionPreference = "Stop"

$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$buildTools = "$sdk\build-tools\36.0.0"
$platformJar = "$sdk\platforms\android-37.0\android.jar"
$jbr = "C:\Program Files\Android\Android Studio\jbr"
$jbrBin = "$jbr\bin"

# Set Modern Java Environment for D8 and AAPT
$env:JAVA_HOME = $jbr
$env:PATH = "$jbrBin;$env:PATH"

$javac = "$jbrBin\javac.exe"
$keytool = "$jbrBin\keytool.exe"
$jarExe = "$jbrBin\jar.exe"
$adb = "$sdk\platform-tools\adb.exe"

$aapt2 = "$buildTools\aapt2.exe"
$d8 = "$buildTools\d8.bat"
$zipalign = "$buildTools\zipalign.exe"
$apksigner = "$buildTools\apksigner.bat"

Write-Host "[1/9] Compiling Resources with AAPT2..."
if (Test-Path "bin") { Remove-Item -Recurse -Force "bin" }
New-Item -ItemType Directory -Force -Path "bin\compiled_res", "bin\dex", "bin\classes" | Out-Null

& $aapt2 compile --dir res -o bin\compiled_res.zip

Write-Host "[2/9] Linking APK with minSDK 24 and targetSDK 34..."
& $aapt2 link -I $platformJar --manifest AndroidManifest.xml --min-sdk-version 24 --target-sdk-version 34 -A assets -o bin\unaligned.apk bin\compiled_res.zip --java src --auto-add-overlay

Write-Host "[3/9] Compiling Java Sources with javac (Java 8 compatibility)..."
& $javac -encoding UTF-8 -source 8 -target 8 -cp $platformJar -d bin\classes src\iq\darb\app\*.java

Write-Host "[4/9] Generating DEX Bytecode with D8 using Java 21..."
& cmd.exe /c "`"$d8`" --lib `"$platformJar`" --min-api 24 --output bin\dex bin\classes\iq\darb\app\*.class"

Write-Host "[5/9] Packaging DEX into APK..."
& $jarExe -uf bin\unaligned.apk -C bin\dex classes.dex

Write-Host "[6/9] Aligning APK with ZipAlign..."
if (Test-Path "bin\darb-aligned.apk") { Remove-Item -Force "bin\darb-aligned.apk" }
& $zipalign -p -f 4 bin\unaligned.apk bin\darb-aligned.apk

Write-Host "[7/9] Signing APK with Keystore..."
if (-not (Test-Path "debug.keystore")) {
    & $keytool -genkeypair -v -keystore debug.keystore -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000
}

& cmd.exe /c "`"$apksigner`" sign --ks debug.keystore --ks-pass pass:android --out bin\darb.apk bin\darb-aligned.apk"

Write-Host "[8/9] Installing APK to connected Android Emulator..."
& $adb install -r bin\darb.apk

Write-Host "[9/9] Launching DARB App on Emulator Screen..."
& $adb shell am start -n iq.darb.app/.MainActivity

Write-Host "SUCCESS: DARB Native APK is installed and running on your Android Emulator screen!"
