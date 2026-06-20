// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web print — uses Blob URL approach (not blocked by browsers)
void printImageWeb(Uint8List imageBytes, String title) {
  final base64Image = base64Encode(imageBytes);
  final dataUrl = 'data:image/png;base64,$base64Image';

  // Create blob with HTML content
  final htmlContent = '''
<!DOCTYPE html>
<html>
  <head>
    <title>$title</title>
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      body {
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
        background: #f5f5f5;
        font-family: Arial, sans-serif;
      }
      .card-container {
        background: white;
        padding: 20px;
        border-radius: 8px;
        box-shadow: 0 2px 12px rgba(0,0,0,0.15);
      }
      img {
        display: block;
        max-width: 380px;
        width: 100%;
      }
      .actions {
        margin-top: 16px;
        display: flex;
        gap: 10px;
        justify-content: center;
      }
      button {
        padding: 10px 24px;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-size: 14px;
        font-weight: 600;
      }
      .print-btn {
        background: #4CAF50;
        color: white;
      }
      .close-btn {
        background: #eee;
        color: #333;
      }
      @media print {
        body { background: white; }
        .actions { display: none; }
        .card-container { box-shadow: none; padding: 0; }
        img { max-width: 100%; }
      }
    </style>
  </head>
  <body>
    <div class="card-container">
      <img src="$dataUrl" alt="Student ID Card" />
      <div class="actions">
        <button class="print-btn" onclick="window.print()">🖨️ Print</button>
        <button class="close-btn" onclick="window.close()">✕ Close</button>
      </div>
    </div>
  </body>
</html>
''';

  // Create blob and open in new tab
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final printWindow = html.window.open(url, '_blank');

  // Revoke URL after a short delay to free memory
  Future.delayed(const Duration(seconds: 10), () {
    html.Url.revokeObjectUrl(url);
  });
}
