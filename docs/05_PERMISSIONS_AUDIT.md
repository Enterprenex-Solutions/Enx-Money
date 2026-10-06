# 05. Permissions Audit

## Purpose
Every requested Android permission must have a legitimate, clearly communicated purpose tied to core app functionality. Over-requesting permissions is a leading cause of Play Store rejection.

---

## 5.1 Sensitive Permissions Requiring Justification
The following sensitive permissions require explicit justification and scrutiny under Google Play Developer Program Policies:
* **CAMERA** (`android.permission.CAMERA`)
* **LOCATION** (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`)
* **MICROPHONE** (`android.permission.RECORD_AUDIO`)
* **CONTACTS** (`READ_CONTACTS`, `WRITE_CONTACTS`, `GET_ACCOUNTS`)
* **SMS** (`SEND_SMS`, `RECEIVE_SMS`, `READ_SMS`, `RECEIVE_WAP_PUSH`, `RECEIVE_MMS`)
* **CALL LOG** (`READ_CALL_LOG`, `WRITE_CALL_LOG`, `PROCESS_OUTGOING_CALLS`)
* **STORAGE** (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE`)
* **BLUETOOTH** (`BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`)
* **NOTIFICATIONS** (`POST_NOTIFICATIONS`)

---

## 5.2 Audit Rule
For every permission, ask:
> **"Does my application genuinely require this to function?"**
> If the answer is no — **remove it**.

---

## 5.3 Examples
* **Bad (unjustifiable):** A calculator or bookkeeping app requesting Contacts, Location, and Microphone.
* **Good (justifiable):** A video-calling app requesting Camera (required), Microphone (required), and Contacts (potentially required, depending on the specific feature).

---

## 5.4 Permissions Audit Table

| Permission | Requested? | Feature Supported | Justified? | Runtime Request Used? |
| :--- | :--- | :--- | :--- | :--- |
| **Camera** (`CAMERA`) | **No** | N/A — No camera scanning or photo capture required | **No** — Not required for bookkeeping or ledger | N/A (Not declared in manifest) |
| **Location** (`FINE/COARSE`) | **No** | N/A — Addresses and districts are selected via dependent dropdowns | **No** — Geolocation tracking is unnecessary | N/A (Not declared in manifest) |
| **Microphone** (`RECORD_AUDIO`) | **No** | N/A — No voice notes or audio features | **No** — Audio capture is unnecessary | N/A (Not declared in manifest) |
| **Contacts** (`READ/WRITE`) | **No** | Counterparty entry is handled manually or via system intent | **No** — Broad address book access is unjustified | N/A (Android Contact Picker / manual entry used) |
| **SMS** (`SEND/RECEIVE/READ`) | **No** | Ledger reminders use system SMS/WhatsApp external intents (`sms:`, `whatsapp://`) | **No** — Direct background SMS dispatch is unjustified | N/A (Delegated to OS default SMS app) |
| **Call Log** (`READ_CALL_LOG`) | **No** | N/A — Zero telephony tracking or call history integration | **No** — Unrelated to financial ledger management | N/A (Not declared in manifest) |
| **Storage** (`EXTERNAL_STORAGE`) | **No** | App uses app-specific private storage (`getExternalFilesDir`) and OS Share Sheet | **No** — Scoped storage compliant (Android 10+) | N/A (Scoped storage used; zero broad storage permissions) |
| **Bluetooth** (`BLUETOOTH_*`) | **No** | N/A — No hardware peripheral or wireless beacon features | **No** — Unrelated to core bookkeeping | N/A (Not declared in manifest) |
| **Notifications** (`POST_NOTIFICATIONS`) | **No** | Critical financial reminders use user-initiated system intents | **No** — No intrusive background push spam | N/A (Not declared; local user actions only) |
| **Internet** (`INTERNET`) | **Yes** | Secure HTTPS/TLS 1.3 REST API communication with backend | **Yes** — Core app synchronization & auth | Normal permission (Granted by Android at install) |
| **Network State** (`ACCESS_NETWORK_STATE`) | **Yes** | Detects online/offline connectivity to route requests or use local cache | **Yes** — Essential for offline resilience | Normal permission (Granted by Android at install) |

---

## 5.5 Implementation Notes

1. **Runtime Permission Requests:**
   * Do not rely solely on manifest declarations. For any future permission addition, request permissions dynamically at runtime.
2. **In-Context Explanation:**
   * Always explain in-context (at the exact moment of request) why the permission is needed before presenting the system prompt.
3. **Android Contact Picker Usage:**
   * Use the Android Contact Picker (`Intent(Intent.ACTION_PICK, ContactsContract.Contacts.CONTENT_URI)`) instead of requesting broad `READ_CONTACTS` permission when counterparty auto-selection is required.
   * This strictly complies with Google's updated **Contacts Permissions policy** (effective January 27, 2027) which tightens requirements and penalizes apps requesting broad contact access.
4. **Google User Data Policy Compliance:**
   * All data handling complies with Google's User Data policy: no background access, no persistent tracking, and no credential extraction.

---

## Sign-off Checklist

- [x] **Every requested permission mapped to a specific feature:** Only `INTERNET` and `ACCESS_NETWORK_STATE` are requested in `client/android/app/src/main/AndroidManifest.xml`, strictly mapped to secure API communication and offline detection.
- [x] **Unjustified permissions removed:** All 9 sensitive permissions (`CAMERA`, `LOCATION`, `MICROPHONE`, `CONTACTS`, `SMS`, `CALL_LOG`, `STORAGE`, `BLUETOOTH`, `NOTIFICATIONS`) are completely absent from the production manifest.
- [x] **Runtime permission prompts implemented with clear in-context explanations:** No sensitive runtime permissions requested; in-app prompts inform users whenever external intents (browser, WhatsApp, email) are triggered.
- [x] **Contact Picker used instead of full Contacts access where possible:** Fully compliant with Google's updated January 27, 2027 policy.
- [x] **Re-audited whenever a new feature or SDK adds a permission:** Audited across `AndroidManifest.xml`, Flutter plugin registrants, and third-party dependencies.
