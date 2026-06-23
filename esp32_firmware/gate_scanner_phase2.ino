/* ============================================================
   BantayEskwela — ESP32-CAM Gate Scanner (Phase 2)
   ------------------------------------------------------------
   Scans a student QR (a "BE-<uuid>" token), then writes it to the
   Firestore "gate_scans" collection. The Guard tablet app reacts to
   that doc, looks up the student by qrData, and the guard taps
   TIME IN / TIME OUT.

   Builds on the working Phase 1 Firebase write — only the camera +
   QR decode is added on top.

   LIBRARIES NEEDED (Library Manager):
     - Firebase Arduino Client Library for ESP8266 and ESP32 (Mobizt)
     - ESP32QRCodeReader (by alvarowolfx)

   BOARD: AI Thinker ESP32-CAM
   ============================================================ */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "ESP32QRCodeReader.h"

// ====== PALITAN ANG MGA ITO ======
#define WIFI_SSID       "YOUR_WIFI_NAME"        // 2.4GHz lang
#define WIFI_PASSWORD   "YOUR_WIFI_PASSWORD"
#define API_KEY         "YOUR_WEB_API_KEY"
#define USER_EMAIL      "guard@bantayeskwela.com"
#define USER_PASSWORD   "YOUR_GUARD_PASSWORD"
#define PROJECT_ID      "bantayeskwela"
// ==================================

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// AI Thinker ESP32-CAM uses the camera; the QR reader wraps it.
ESP32QRCodeReader reader(CAMERA_MODEL_AI_THINKER);

// Debounce: ignore repeat scans of the same token within this window,
// so one student tap doesn't create many gate_scans docs.
String lastToken = "";
unsigned long lastScanMs = 0;
const unsigned long DEBOUNCE_MS = 8000; // 8 seconds

void setup() {
  Serial.begin(115200);
  delay(800);
  Serial.println();
  Serial.println("=== BantayEskwela Gate Scanner (Phase 2) ===");

  // --- WiFi ---
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(400);
  }
  Serial.print("\nWiFi OK. IP: ");
  Serial.println(WiFi.localIP());

  // --- NTP (for accurate scannedAt timestamps) ---
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");

  // --- Firebase ---
  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("Logging in to Firebase...");

  // --- QR reader / camera ---
  reader.setup();
  Serial.println("Camera ready. Starting QR scan task...");
  reader.beginOnCore(1);
}

void loop() {
  struct QRCodeData qrCodeData;

  if (reader.receiveQrCode(&qrCodeData, 100)) {
    if (qrCodeData.valid) {
      String token = String((const char *)qrCodeData.payload);
      Serial.print("QR detected: ");
      Serial.println(token);
      handleToken(token);
    }
  }
  delay(50);
}

void handleToken(String token) {
  token.trim();
  if (token.isEmpty()) return;

  // Basic sanity: our tokens start with "BE-"
  if (!token.startsWith("BE-")) {
    Serial.println("  (ignored — not a BantayEskwela token)");
    return;
  }

  // Debounce duplicates
  unsigned long now = millis();
  if (token == lastToken && (now - lastScanMs) < DEBOUNCE_MS) {
    Serial.println("  (debounced — same token, too soon)");
    return;
  }

  if (!Firebase.ready()) {
    Serial.println("  Firebase not ready yet, skipping.");
    return;
  }

  lastToken = token;
  lastScanMs = now;

  writeGateScan(token);
}

void writeGateScan(String token) {
  Serial.println("Writing gate_scan to Firestore...");
  String documentPath = "gate_scans/scan_" + String(millis());

  FirebaseJson content;
  content.set("fields/qrData/stringValue", token);
  content.set("fields/scannedAt/timestampValue", getISOTime());

  if (Firebase.Firestore.createDocument(
          &fbdo, PROJECT_ID, "", documentPath.c_str(), content.raw())) {
    Serial.println("  ✅ Scan sent. Check the Guard dashboard.");
  } else {
    Serial.print("  ❌ Failed: ");
    Serial.println(fbdo.errorReason());
  }
}

String getISOTime() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    return "2026-01-01T00:00:00Z"; // fallback if NTP not ready
  }
  char buf[30];
  strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);
  return String(buf);
}
