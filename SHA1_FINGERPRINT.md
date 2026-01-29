# ✅ SHA-1 Fingerprint Found!

Your debug SHA-1 fingerprint is:

```
F0:77:64:2E:43:44:ED:2B:F3:54:92:75:5D:CB:23:F9:AF:FE:44:97
```

## Next Steps (5 minutes)

### 1. Add SHA-1 to Firebase Console

1. Open: https://console.firebase.google.com/project/micro-skill-decay-detector/settings/general
2. Scroll to **Your apps** → Find your Android app
3. Click **SHA certificate fingerprints** section
4. Click **Add fingerprint**
5. Paste: `F0:77:64:2E:43:44:ED:2B:F3:54:92:75:5D:CB:23:F9:AF:FE:44:97`
6. Click **Save**

### 2. Download Updated google-services.json

1. On the same page, click **Download google-services.json**
2. Replace the file at:
   ```
   E:\MAD project\micro_skill_decay_detector\android\app\google-services.json
   ```

### 3. Restart Your App

Stop the current app (press `q` in terminal) and run:
```bash
flutter run
```

### 4. Test Google Sign-In

Tap the Google Sign-In button - it should now work! ✅

---

**The updated google-services.json will include an Android OAuth client (client_type: 1) which is required for Google Sign-In to work.**
