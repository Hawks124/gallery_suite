# ☁️ Google Cloud Platform (GCP) Configuration

For the Google login popup to open and our package to be able to read photos, the client application must be configured in Google Cloud. The Google Console was recently updated to the new **Google Auth Platform** interface.

Here are the 5 steps to follow **on your web browser**.

---

### Step 1: Create or Select the GCP Project
1.  Go to the [Google Cloud Console](https://console.cloud.google.com/).
2.  If you already have a **Firebase** project, select it at the top. Otherwise, create a new project.

### Step 2: Enable the Google Photos API
1.  In the top search bar, type **Google Photos Picker API** (Do *not* select the legacy "Library API" which was deprecated for general use in March 2025).
2.  Click on the corresponding result.
3.  Click the blue **Enable** button. *If you see "Disable", it means it's already active.*

### Step 3: Configure the "Google Auth Platform"
Google has regrouped the old "OAuth Consent Screen" under this new interface.
1.  In the left hamburger menu, go to **APIs & Services** > **OAuth consent screen**.
2.  You should land on the **Google Auth Platform** screen. Use the left sidebar of this screen:

#### 🅰️ Branding
1.  Click on **Branding** in the left menu.
2.  **App Name**: Enter the public name of your application.
3.  **User support email**: Select your email address.
4.  Click **Save** at the bottom.

#### 🇧 Audience
1.  Click on **Audience** in the left menu.
2.  **User Type**: Make sure to select **External**.
3.  **Test Users**: Click **+ ADD USERS** and add **your Google email address**. This is crucial as long as the app is not officially published.
4.  Click **Save**.

#### 🅲 Data Access (Scopes)
1.  Click on **Data Access** in the left menu.
2.  Click **ADD OR REMOVE SCOPES**.
3.  Search for and check `.../auth/photospicker.mediaitems.readonly`.
4.  If you can't find it, scroll down to "Manually add scopes" and paste: `https://www.googleapis.com/auth/photospicker.mediaitems.readonly`.
5.  Click **Add to table** then **Update** and finally **Save**.

---

### Step 4: Create Credentials (Client IDs)
1.  Click on **Clients** in the left menu of the Google Auth Platform (or go to **APIs & Services** > **Credentials**).
2.  Click **+ CREATE CREDENTIALS** > **OAuth client ID**.
3.  **For Android**:
    *   Application type: **Android**.
    *   Name: `Android Client`.
    *   **Package name**: Enter exactly your app's bundle ID (e.g., `com.mycompany.app`).
    *   **SHA-1 certificate fingerprint**: This is the signature of your PC/Mac.
        *   On Windows (PowerShell): 
            ```powershell
            keytool -list -v -keystore "C:\Users\YOURNAME\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
            ```
        *   Copy the line `SHA1: XX:XX...` and paste it into GCP.
    *   Click **CREATE**.

---

### Step 5: Generate an API Key (Required for Picker API)
In addition to the OAuth Client ID, the new Google Photos Picker API requires a standard API Key.
1. In the left menu of the Google Auth Platform, go to **Credentials**.
2. Click **+ CREATE CREDENTIALS** > **API key**.
3. A popup will appear with your new API Key. Copy it. You can optionally restrict it to your Android/iOS apps for better security.

---

### Step 6: Flutter Integration Initialization
The modern Picker API uses a secure **PKCE OAuth2 flow** that requires explicit initialization at the start of your application. You will need three pieces of information from the previous steps:

1.  **`clientId`**: The Client ID string you created in Step 4.
2.  **`apiKey`**: The API Key you generated in Step 5.
3.  **`redirectScheme`**: This is your `clientId` but **reversed**.
    *   *Example Client ID*: `12345-abcde.apps.googleusercontent.com`
    *   *Example Redirect Scheme*: `com.googleusercontent.apps.12345-abcde`

In your `main.dart` or initialization service, add the following code:

```dart
import 'package:gallery_suite/gallery_suite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the Google Photos Service globally
  GooglePhotosService.instance.init(
    clientId: 'YOUR_OAUTH_CLIENT_ID.apps.googleusercontent.com',
    redirectScheme: 'com.googleusercontent.apps.YOUR_OAUTH_CLIENT_ID', // Reversed Client ID
    apiKey: 'YOUR_GOOGLE_CLOUD_API_KEY', 
  );

  runApp(const MyApp());
}
```

---

### 🚀 Step 7: Moving to Production and Verification
Once your application is ready to be published on the stores, you need to change its status on GCP to remove the 100 test user limit.

1.  **Change Status**: In the **Audience** tab, change the status from "Testing" to **In Production**.
2.  **Complete Branding**: Click on **Branding** and fill in all the fields (App logo, App domain, Privacy Policy link, Terms of service link).
3.  **Verify Brand**: Click the "Verify" button. Google will validate your logo and links. Once verified, you will need to click **Publish** for it to be visible to everyone.

> [!NOTE]
> **The 2025 Google Photos Policy Shift**
> In March 2025, Google fundamentally restricted the legacy `photoslibrary.readonly` scope. Apps attempting to read the user's entire library automatically are now met with `403 PERMISSION_DENIED` errors unless they pass an extremely rigorous and expensive CASA Tier-2 security audit.
> 
> `gallery_suite` fully mitigates this by adopting the modern **Picker API** flow (`photospicker.mediaitems.readonly`). Because the Picker API forces the user to manually select which photos they are sharing via a Google-hosted secure window, it complies with the latest privacy guidelines and completely bypasses the need for the Tier-2 audit. 
> 
> **Standard Verification is still needed for Production (Over 100 users):**
> You must still record a short demo video showing your app's OAuth login flow and submit it to the Google Trust & Safety team. However, they will approve it quickly because you are using the compliant Picker API.

---

**That's it! Hot Restart the application and test the connection.** 🚀
