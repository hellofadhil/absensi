import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class KoraDriveResult {
  const KoraDriveResult({
    required this.driveId,
    required this.fileName,
    required this.filePath,
    required this.downloadUrl,
    this.url,
    this.rawResponse,
  });

  final String driveId;
  final String fileName;
  final String filePath;
  final String downloadUrl;
  final String? url;
  final Map<String, dynamic>? rawResponse;
}

class KoraDriveService {
  static const String _apiBase = 'https://api-drive.baselab.web.id';
  static const String _defaultFolder = 'Storage/absensiQu';

  /// Returns the direct binary download URL for a given file ID
  static String getDownloadUrl(String fileId) {
    return '$_apiBase/files/$fileId/download';
  }

  /// Uploads a file to Kora Drive following the 3-step resumable upload process.
  /// 
  /// 1. Initiate upload session
  /// 2. Upload file binary payload
  /// 3. Register metadata completion
  static Future<KoraDriveResult> uploadFile(
    File file, {
    String targetDir = _defaultFolder,
  }) async {
    final apiKey = dotenv.env['KORA_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'YOUR_KORA_API_KEY_HERE') {
      throw Exception('KORA_API_KEY belum dikonfigurasi di file .env');
    }

    final fileName = path.basename(file.path);
    final sizeBytes = await file.length();
    final fileBytes = await file.readAsBytes();

    final authHeader = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    // Step 1: Initiate Resumable Upload Session
    final initRes = await http.post(
      Uri.parse('$_apiBase/files/upload/initiate'),
      headers: authHeader,
      body: jsonEncode({
        'name': fileName,
        'path': targetDir,
      }),
    );

    if (initRes.statusCode < 200 || initRes.statusCode >= 300) {
      throw Exception('Inisiasi upload Kora Drive gagal (${initRes.statusCode}): ${initRes.body}');
    }

    final initData = jsonDecode(initRes.body) as Map<String, dynamic>;
    final uploadUrl = initData['uploadUrl'] as String?;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw Exception('Sistem tidak menerima uploadUrl dari Kora Drive.');
    }

    // Step 2: Upload Binary Payload
    final putRes = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Length': sizeBytes.toString(),
      },
      body: fileBytes,
    );

    if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
      throw Exception('Upload biner ke Cloud Storage gagal (${putRes.statusCode}): ${putRes.body}');
    }

    final driveData = jsonDecode(putRes.body) as Map<String, dynamic>;
    final driveId = (driveData['id'] ?? driveData['driveId'])?.toString();
    if (driveId == null || driveId.isEmpty) {
      throw Exception('driveId tidak ditemukan setelah upload biner.');
    }

    // Step 3: Complete & Register Metadata
    final completeRes = await http.post(
      Uri.parse('$_apiBase/files/upload/complete'),
      headers: authHeader,
      body: jsonEncode({
        'driveId': driveId,
        'name': fileName,
        'path': targetDir,
        'type': 'file',
        'sizeBytes': sizeBytes,
      }),
    );

    if (completeRes.statusCode < 200 || completeRes.statusCode >= 300) {
      throw Exception('Penyelesaian registrasi berkas Kora Drive gagal (${completeRes.statusCode}): ${completeRes.body}');
    }

    final completeData = jsonDecode(completeRes.body) as Map<String, dynamic>;
    final directDownloadUrl = getDownloadUrl(driveId);
    final fileUrl = completeData['url'] as String? ?? completeData['link'] as String? ?? directDownloadUrl;

    return KoraDriveResult(
      driveId: driveId,
      fileName: fileName,
      filePath: '$targetDir/$fileName',
      downloadUrl: directDownloadUrl,
      url: fileUrl,
      rawResponse: completeData,
    );
  }
}
