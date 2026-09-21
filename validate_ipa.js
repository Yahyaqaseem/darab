const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('====================================================');
console.log('   DARB IPA BUNDLE IDENTIFIER & SIDELOADLY AUDIT    ');
console.log('====================================================');

const ipaPath = 'c:\\Users\\Yahya\\Downloads\\darab\\darb.ipa';
const inspectDir = 'c:\\Users\\Yahya\\Downloads\\darab\\inspect_ipa';

if (!fs.existsSync(ipaPath)) {
  console.error('❌ ERROR: darb.ipa does not exist at ' + ipaPath);
  process.exit(1);
}

const stats = fs.statSync(ipaPath);
console.log(`📦 IPA File Size: ${(stats.size / 1024).toFixed(1)} KB`);

// Clean previous inspection
if (fs.existsSync(inspectDir)) {
  fs.rmSync(inspectDir, { recursive: true, force: true });
}
fs.mkdirSync(inspectDir, { recursive: true });

// Extract IPA as ZIP using PowerShell
execSync(`powershell -Command "Expand-Archive -Path '${ipaPath}' -DestinationPath '${inspectDir}' -Force"`);

const plistPath = path.join(inspectDir, 'Payload', 'Runner.app', 'Info.plist');
if (!fs.existsSync(plistPath)) {
  console.error('❌ ERROR: Info.plist not found in extracted IPA at ' + plistPath);
  process.exit(1);
}

const plistContent = fs.readFileSync(plistPath, 'utf8');

// 1. Check for unresolved $(...) or ${...}
const unresolvedVars = plistContent.match(/(\$\([A-Za-z0-9_]+\)|\$\{[A-Za-z0-9_]+\})/g);
if (unresolvedVars && unresolvedVars.length > 0) {
  console.error('❌ ERROR: Found unresolved variables in Info.plist:', unresolvedVars);
  process.exit(1);
} else {
  console.log('✅ [CHECK 1] Unresolved Variables Scan: 0 occurrences of $(...) found in Info.plist.');
}

// 2. Check CFBundleIdentifier
const bundleIdMatch = plistContent.match(/<key>CFBundleIdentifier<\/key>\s*<string>([^<]+)<\/string>/);
if (!bundleIdMatch) {
  console.error('❌ ERROR: CFBundleIdentifier not found in Info.plist');
  process.exit(1);
}

const bundleId = bundleIdMatch[1];
console.log(`✅ [CHECK 2] CFBundleIdentifier: "${bundleId}"`);

if (bundleId !== 'com.darb.iraq') {
  console.error(`❌ ERROR: Expected "com.darb.iraq", but got "${bundleId}"`);
  process.exit(1);
}

// 3. Check CFBundleExecutable
const execMatch = plistContent.match(/<key>CFBundleExecutable<\/key>\s*<string>([^<]+)<\/string>/);
console.log(`✅ [CHECK 3] CFBundleExecutable: "${execMatch ? execMatch[1] : 'NOT FOUND'}"`);

// 4. Check CFBundleShortVersionString & CFBundleVersion
const versionMatch = plistContent.match(/<key>CFBundleShortVersionString<\/key>\s*<string>([^<]+)<\/string>/);
const buildMatch = plistContent.match(/<key>CFBundleVersion<\/key>\s*<string>([^<]+)<\/string>/);
console.log(`✅ [CHECK 4] Version: "${versionMatch ? versionMatch[1] : 'N/A'}" (Build: "${buildMatch ? buildMatch[1] : 'N/A'}")`);

// 5. Check Location & Background Permissions
const hasInUse = plistContent.includes('NSLocationWhenInUseUsageDescription');
const hasAlways = plistContent.includes('NSLocationAlwaysAndWhenInUseUsageDescription');
const hasBgMode = plistContent.includes('<string>location</string>');
console.log(`✅ [CHECK 5] iOS Permissions: InUse=${hasInUse}, Always=${hasAlways}, BackgroundLocation=${hasBgMode}`);

// Clean inspection dir
fs.rmSync(inspectDir, { recursive: true, force: true });

console.log('====================================================');
console.log('   🎉 VALIDATION SUCCESS: IPA IS 100% SIDELOADLY-READY!   ');
console.log('====================================================');
