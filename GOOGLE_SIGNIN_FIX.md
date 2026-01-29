# Google Sign-In Configuration Fix - Step-by-Step Guide

## Current Issue

Google Sign-In is failing with error codes:
- **Error 10**: `DEVELOPER_ERROR` - Missing Android OAuth client configuration
- **Error 7**: `NETWORK_ERROR` - Network issues due to missing configuration

## Quick Solution (Recommended)

Since we couldn't automatically extract your SHA-1 fingerprint, here are **manual steps** to fix this:

### Step 1: Get Your SHA-1 Fingerprint

Open a **new PowerShell or Command Prompt** window and run ONE of these commands:

**Option A - If you have Android Studio:**
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Option B - If you have Java JDK installed:**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Option C - Find keytool manually:**
1. Search for `keytool.exe` in:
   - `C:\Program Files\Java\jdk*\bin\`
   - `C:\Program Files (x86)\Java\jdk*\bin\`
   - `%LOCALAPPDATA%\Android\Sdk\jbr\bin\`
2. Once found, run:
   ```cmd
   "C:\path\to\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```

**Look for this line in the output:**
```
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```

Copy the entire SHA1 value (the part after "SHA1: ").

### Step 2: Add SHA-1 to Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select project: **micro-skill-decay-detector**
3. Click the **⚙️ gear icon** (Project Settings)
4. Scroll down to **Your apps** section
5. Find your Android app: `com.example.micro_skill_decay_detector`
6. Scroll to **SHA certificate fingerprints** section
7. Click **Add fingerprint**
8. Paste your SHA1 value
9. Click **Save**

> [!IMPORTANT]
> Firebase will automatically create an Android OAuth client when you add the SHA-1 fingerprint.

### Step 3: Download Updated google-services.json

1. Still in Firebase Console, on the same page
2. Scroll up and click **Download google-services.json**
3. Save the file
4. **Replace** the existing file at:
   ```
   E:\MAD project\micro_skill_decay_detector\android\app\google-services.json
   ```

### Step 4: Restart Your App

1. Stop the current Flutter app (press `q` in the terminal or Ctrl+C)
2. Run again:
   ```bash
   flutter run
   ```

3. Test Google Sign-In - it should now work!

---

## Alternative: Use Web Client ID (Temporary Workaround)

If you can't get the SHA-1 right now, you can try using the web client ID as a temporary workaround:

### Update auth_service.dart

Add the `serverClientId` parameter to GoogleSignIn:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'],
  serverClientId: '889292981742-ucknqtugi62s3em7r185in1prat5revr.apps.googleusercontent.com',
);
```

> [!WARNING]
> This workaround may not work on all devices and is not recommended for production. The proper fix is to add the SHA-1 fingerprint to Firebase.

---

## Verification

After completing the steps above, test Google Sign-In:

1. ✅ Tap "Sign in with Google" button
2. ✅ Select a Google account
3. ✅ Should see successful authentication
4. ✅ User should be redirected to home screen
5. ✅ Check Firebase Console → Firestore Database → `users` collection for new user entry

### Expected Console Output (Success)

```
I/flutter: User signed in: [user email]
```

**No more error code 10 or 7!**

---

## Troubleshooting

**If you still see errors after adding SHA-1:**

1. Make sure you downloaded the **updated** google-services.json
2. Verify the file was replaced in the correct location
3. Try `flutter clean` then `flutter run`
4. Check that the SHA-1 was added correctly in Firebase Console

**If keytool command doesn't work:**

- Install [Java JDK](https://www.oracle.com/java/technologies/downloads/)
- Or install [Android Studio](https://developer.android.com/studio) which includes Java

---

## Summary

The Google Sign-In error occurs because your Firebase project doesn't have an Android OAuth client configured with your app's SHA-1 fingerprint. Once you add the SHA-1 to Firebase and download the updated `google-services.json`, Google Sign-In will work correctly.
