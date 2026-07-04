import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class OneClickDeploy {
  static final OneClickDeploy instance = OneClickDeploy._init();
  OneClickDeploy._init();

  // Deploy to free static hosting (Netlify)
  Future<Map<String, dynamic>> deployToNetlify({
    required String projectId,
    required String siteName,
    required String buildDir,
    String? netlifyToken,
  }) async {
    if (netlifyToken == null) {
      return {'success': false, 'error': 'Netlify token required'};
    }

    try {
      // Create zip of build directory
      final zipPath = await _zipDirectory(buildDir);
      
      // Deploy to Netlify
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.netlify.com/api/v1/sites'),
      );
      
      request.headers['Authorization'] = 'Bearer $netlifyToken';
      request.fields['name'] = siteName;
      request.files.add(await http.MultipartFile.fromPath('file', zipPath));
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseData);
        return {
          'success': true,
          'url': data['url'],
          'admin_url': data['admin_url'],
          'site_id': data['site_id'],
        };
      } else {
        return {'success': false, 'error': responseData};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Deploy to Vercel
  Future<Map<String, dynamic>> deployToVercel({
    required String projectId,
    required String buildDir,
    String? vercelToken,
  }) async {
    if (vercelToken == null) {
      return {'success': false, 'error': 'Vercel token required'};
    }

    try {
      // Vercel deployment API
      final response = await http.post(
        Uri.parse('https://api.vercel.com/v13/deployments'),
        headers: {
          'Authorization': 'Bearer $vercelToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': 'kitsune-byte-$projectId',
          'files': await _getFilesMap(buildDir),
          'framework': 'flutter',
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'url': data['url'],
          'id': data['id'],
        };
      } else {
        return {'success': false, 'error': data};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Deploy to self-hosted VPS (SSH)
  Future<Map<String, dynamic>> deployToVPS({
    required String projectId,
    required String buildDir,
    required String host,
    required String username,
    required String privateKey,
    String? domain,
  }) async {
    try {
      // Use Process.run to execute SSH commands
      final result = await Process.run('ssh', [
        '-i', privateKey,
        '$username@$host',
        'mkdir -p /var/www/kitsune/$projectId'
      ]);

      if (result.exitCode != 0) {
        return {'success': false, 'error': result.stderr};
      }

      // SCP files
      final scpResult = await Process.run('scp', [
        '-r',
        '-i', privateKey,
        '$buildDir/',
        '$username@$host:/var/www/kitsune/$projectId/',
      ]);

      if (scpResult.exitCode == 0) {
        return {
          'success': true,
          'url': domain ?? 'http://$host/kitsune/$projectId',
        };
      } else {
        return {'success': false, 'error': scpResult.stderr};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Helper: Zip directory
  Future<String> _zipDirectory(String dirPath) async {
    final zipPath = '${dirPath}_deploy.zip';
    final result = await Process.run('zip', ['-r', zipPath, '.'], workingDirectory: dirPath);
    return zipPath;
  }

  // Helper: Get files map for Vercel
  Future<List<Map<String, dynamic>>> _getFilesMap(String dirPath) async {
    final files = <Map<String, dynamic>>[];
    final dir = Directory(dirPath);
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: dirPath);
        final content = await entity.readAsBytes();
        files.add({
          'file': relativePath,
          'data': base64Encode(content),
          'encoding': 'base64',
        });
      }
    }
    
    return files;
  }
}
