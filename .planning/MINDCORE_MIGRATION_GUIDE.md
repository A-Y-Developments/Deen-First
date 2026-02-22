# MINDCORE TO SURAH FOCUS MIGRATION GUIDE
# Exact Changes When Copying Screen Time Code

**Source:** `/Users/adithyafp_/Projects/mindcore`  
**Target:** Your SurahFocus project  
**Bundle ID Change:** `com.alexis.*` → `com.aydev.surahfocus`  
**App Group Change:** `group.com.alexis.screentime` → `group.com.aydev.surahfocus`

---

## STEP-BY-STEP COPY PROCESS

### Step 1: Copy Extension Folders

**Copy these folders AS-IS first:**
```bash
# From mindcore to your SurahFocus project root
cp -r /Users/adithyafp_/Projects/mindcore/ScreenTimeMonitor /path/to/SurahFocus/
cp -r /Users/adithyafp_/Projects/mindcore/Shield /path/to/SurahFocus/
```

---

### Step 2: Update ScreenTimeMonitor Entitlements

**File:** `SurahFocus/ScreenTimeMonitor/ScreenTimeMonitor.entitlements`

**FIND:**
```xml
<string>group.com.alexis.screentime</string>
```

**REPLACE WITH:**
```xml
<string>group.com.aydev.surahfocus</string>
```

**Complete file should look like:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.aydev.surahfocus</string>
	</array>
	<key>com.apple.developer.family-controls</key>
	<true/>
</dict>
</plist>
```

---

### Step 3: Update Shield Entitlements

**File:** `SurahFocus/Shield/Shield.entitlements`

Currently mindcore has:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
```

**REPLACE ENTIRE FILE WITH:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.aydev.surahfocus</string>
	</array>
</dict>
</plist>
```

---

### Step 4: Update UserDefaults in Swift Files

**CRITICAL:** Search ALL Swift files in ScreenTimeMonitor and Shield folders for hardcoded app group strings.

**FIND:**
```swift
UserDefaults(suiteName: "group.com.alexis.screentime")
```

**REPLACE WITH:**
```swift
UserDefaults(suiteName: "group.com.aydev.surahfocus")
```

**Files likely to contain this:**
- `ScreenTimeMonitor/DeviceActivityMonitorExtension.swift`
- Any repository or helper files copied from mindcore

**Search command:**
```bash
# From SurahFocus root
grep -r "group.com.alexis.screentime" ScreenTimeMonitor/ Shield/
```

**Should return ZERO results after you fix them all.**

---

### Step 5: Copy Helper Utilities to Utils/ScreenTime/

**From mindcore Helper/ to SurahFocus Utils/ScreenTime/:**

```bash
# Create the directory first
mkdir -p /path/to/SurahFocus/Sources/Utils/ScreenTime

# Copy and rename
cp /Users/adithyafp_/Projects/mindcore/Helper/TimeLimit.swift \
   /path/to/SurahFocus/Sources/Utils/ScreenTime/TimeLimit.swift

cp /Users/adithyafp_/Projects/mindcore/Helper/ScreenTimeEvents.swift \
   /path/to/SurahFocus/Sources/Utils/ScreenTime/ScreenTimeEvents.swift

cp /Users/adithyafp_/Projects/mindcore/Helper/TimeLimitHelper.swift \
   /path/to/SurahFocus/Sources/Utils/ScreenTime/TimeLimitHelper.swift
```

**Then check each file for:**
```swift
❌ UserDefaults(suiteName: "group.com.alexis.screentime")
✅ UserDefaults(suiteName: "group.com.aydev.surahfocus")
```

---

### Step 6: Adapt ScreenTimeRepository

**File:** `mindcore/Data/Repositories/ScreenTimeRepository.swift`

**DON'T copy this directly.** Use it as reference to implement your own:

`SurahFocus/Sources/Data/Repositories/ScreenTimeRepository.swift`

**Key changes:**
1. Update app group string in UserDefaults
2. Adapt to SurahFocus entity models (User, Session, BlockedApp)
3. Remove mindcore-specific logic (reward system, etc.)
4. Follow SurahFocus PRD requirements (no reward system, streak-based)

---

## VERIFICATION CHECKLIST

After copying and updating all files, run these checks:

### Check 1: No Old App Group References
```bash
# From SurahFocus root - should return ZERO results
grep -r "group.com.alexis.screentime" .
grep -r "com.alexis" .
```

### Check 2: All Entitlements Correct
```bash
# Check ScreenTimeMonitor entitlements
cat ScreenTimeMonitor/ScreenTimeMonitor.entitlements | grep "group.com.aydev.surahfocus"

# Check Shield entitlements
cat Shield/Shield.entitlements | grep "group.com.aydev.surahfocus"

# Check main app entitlements
cat SurahFocus/SurahFocus.entitlements | grep "group.com.aydev.surahfocus"
```

### Check 3: Project.swift Has Correct Bundle IDs
```bash
# Check bundle IDs in Project.swift
cat Project.swift | grep "bundleId"
```

**Should show:**
- Main: `com.aydev.surahfocus`
- Monitor: `com.aydev.surahfocus.ScreenTimeMonitor`
- Shield: `com.aydev.surahfocus.Shield`

### Check 4: Tuist Generation Works
```bash
make clean
make generate
```

**Should succeed without errors.**

---

## COMMON MISTAKES TO AVOID

### ❌ Mistake 1: Forgetting UserDefaults in Swift Files
**Problem:** Extension can't communicate with main app  
**Solution:** Search ALL Swift files for old app group string

### ❌ Mistake 2: Wrong Bundle ID Pattern
**Problem:** Extensions don't load  
**Solution:** Must be:
- Main: `com.aydev.surahfocus`
- Extension: `com.aydev.surahfocus.ExtensionName` (NO `.app` in between)

### ❌ Mistake 3: Missing family-controls Entitlement
**Problem:** Screen Time permission denied  
**Solution:** ScreenTimeMonitor.entitlements must have:
```xml
<key>com.apple.developer.family-controls</key>
<true/>
```

### ❌ Mistake 4: Empty Shield Entitlements
**Problem:** Shield can't access shared data  
**Solution:** Add app group to Shield.entitlements (mindcore's is empty)

---

## TESTING AFTER MIGRATION

### Test 1: Build All Targets
```bash
make build
```
All 3 targets should compile successfully.

### Test 2: Grant Screen Time Permission
Run on physical device → Request permission → Should succeed

### Test 3: Apply Shield
Block an app → Shield should appear with your custom UI

### Test 4: Extension Communication
Main app sets limit → Extension receives it → Shield applies correctly

---

## QUICK REFERENCE: ALL IDENTIFIERS

```
Company ID:           com.aydev
Base Bundle ID:       com.aydev.surahfocus
App Group:            group.com.aydev.surahfocus

Main App:             com.aydev.surahfocus
ScreenTimeMonitor:    com.aydev.surahfocus.ScreenTimeMonitor
Shield:               com.aydev.surahfocus.Shield

Monthly Product:      com.aydev.surahfocus.monthly
Yearly Product:       com.aydev.surahfocus.yearly
Entitlement:          premium
```

---

## FILES THAT NEED UPDATES

**Entitlements (2 files):**
1. `ScreenTimeMonitor/ScreenTimeMonitor.entitlements` - Update app group
2. `Shield/Shield.entitlements` - ADD app group (currently empty)

**Swift Files (search and update):**
- `ScreenTimeMonitor/DeviceActivityMonitorExtension.swift`
- `Shield/ShieldConfigurationExtension.swift`
- Any copied Helper files (TimeLimit.swift, ScreenTimeEvents.swift, etc.)
- ScreenTimeRepository.swift (adapt, don't copy)

**Project Files:**
- `Project.swift` - Already correct if following SYSTEM_DESIGN.md
- `.env` - Update with correct IDs

---

## POST-MIGRATION CLEANUP

After migration is complete and tested:

```bash
# Remove any backup files
find . -name "*.orig" -delete
find . -name "*~" -delete

# Verify no references to old identifiers
grep -r "alexis" . --exclude-dir=DerivedData
grep -r "com.muslimlock" . --exclude-dir=DerivedData

# Should return ZERO results
```

---

## IF SOMETHING GOES WRONG

**Problem:** Extensions not showing in Xcode
- **Solution:** Run `make clean && make generate`

**Problem:** Shield not appearing
- **Solution:** Check entitlements have app group, check UserDefaults string

**Problem:** "Extension not found" error
- **Solution:** Verify bundle ID pattern is correct (no `.app` in extension IDs)

**Problem:** Permission denied for Screen Time
- **Solution:** Add `com.apple.developer.family-controls` to ScreenTimeMonitor entitlements

---

**🎯 FOLLOW THIS GUIDE EXACTLY - DO NOT SKIP STEPS**

Every identifier must match. One typo breaks everything with Screen Time API.
