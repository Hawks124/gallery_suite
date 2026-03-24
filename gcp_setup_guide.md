# ☁️ Google Cloud Platform (GCP) Configuration

For the Google login popup to open and our package to be able to read photos, the client application must be configured in Google Cloud. The Google Console was recently updated to the new **Google Auth Platform** interface.

Here are the 5 steps to follow **on your web browser**.

---

### Step 1: Create or Select the GCP Project
1.  Go to the [Google Cloud Console](https://console.cloud.google.com/).
2.  If you already have a **Firebase** project, select it at the top. Otherwise, create a new project.

### Step 2: Enable the Google Photos API
1.  In the top search bar, type **Google Photos Library API**.
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
3.  Search for and check `.../auth/photoslibrary.readonly`.
4.  If you can't find it, scroll down to "Manually add scopes" and paste: `https://www.googleapis.com/auth/photoslibrary.readonly`.
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

### Step 5: Flutter Integration (Zero-Config)
If your project already uses **Firebase** (`google-services.json` file present):
1.  Go to your **Firebase Console Project Settings**.
2.  Make sure the SHA-1 fingerprint you just used is properly added to your Android application.
3.  **Download the `google-services.json` file again** and replace the old one in `android/app/`.
4.  The `gallery_suite` package will automatically detect the configuration!

---

### 🚀 Step 6: Moving to Production and Verification
Once your application is ready to be published on the stores, you need to change its status on GCP to remove the 100 test user limit.

1.  **Change Status**: In the **Audience** tab, change the status from "Testing" to **In Production**.
2.  **Complete Branding**: Click on **Branding** and fill in all the fields (App logo, App domain, Privacy Policy link, Terms of service link).
3.  **Verify Brand**: Click the "Verify" button. Google will validate your logo and links. Once verified, you will need to click **Publish** for it to be visible to everyone.

> [!IMPORTANT]
> **Sensitive Scopes Justification (Verification Required)**
> The `photoslibrary.readonly` scope is considered **Sensitive** by Google. Google often rejects justifications that are too short. Use this template (copy-paste):
>
> **Example Template:**
> *"This application integrates a custom media picker to allow users to share visual content. The 'photoslibrary.readonly' scope is essential for users to browse, preview, and select their Google Photos directly from the native interface of our application. Data is accessed only during an explicit user selection action and is neither stored nor sold."*
>
> **🎬 Crucial Element: The Demo Video**
> Google requires a video (YouTube or public Google Drive link) showing:
> 1.  The launch of the authentication from your application.
> 2.  The OAuth consent screen (showing your project name and the requested scopes).
> 3.  The successful login and the proper display of the Google Photos grid in `gallery_suite`.
> 4.  The final action: the user selects a Cloud image and uses it in the app.
>
> **📝 Additional info**
> Provide all the details to help the **human reviewer** at Google:
> - **Context**: Briefly describe your application (e.g., private chat, social network).
> - **Test Access**: If your application requires an account, provide test credentials (username/password) so the reviewer can reach the "Google Photos" button.
> - **The Video**: Always mention that the attached demo video illustrates the entire user journey.

---

**That's it! Restart the application and test the connection.** 🚀
