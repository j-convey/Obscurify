import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class PlexAuthService {
  static const String _plexApiUrl = 'https://clients.plex.tv';
  static const String _plexAuthUrl = 'https://app.plex.tv';
  static const String _clientIdentifier = 'apollo-music-player';
  static const String _productName = 'Apollo';
  
  // Generate a PIN for authentication
  Future<Map<String, dynamic>> _generatePin() async {
    try {
      final response = await http.post(
        Uri.parse('$_plexApiUrl/api/v2/pins?strong=true'),
        headers: {
          'Accept': 'application/json',
          'X-Plex-Product': _productName,
          'X-Plex-Client-Identifier': _clientIdentifier,
        },
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to generate PIN: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating PIN: $e');
    }
  }

  // Check PIN status and get token
  Future<Map<String, dynamic>?> _checkPin(int pinId) async {
    try {
      final response = await http.get(
        Uri.parse('$_plexApiUrl/api/v2/pins/$pinId'),
        headers: {
          'Accept': 'application/json',
          'X-Plex-Client-Identifier': _clientIdentifier,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['authToken'] != null) {
          return data;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user info from token
  Future<Map<String, dynamic>?> _getUserInfo(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_plexApiUrl/api/v2/user'),
        headers: {
          'Accept': 'application/json',
          'X-Plex-Token': token,
          'X-Plex-Client-Identifier': _clientIdentifier,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Main sign-in method
  Future<Map<String, dynamic>> signIn() async {
    try {
      // Step 1: Generate PIN
      final pinData = await _generatePin();
      final pinId = pinData['id'];
      final pinCode = pinData['code'];

      // Step 2: Construct Auth App URL
      // Build the URL manually to ensure proper fragment format
      final params = Uri(queryParameters: {
        'clientID': _clientIdentifier,
        'code': pinCode,
        'context[device][product]': _productName,
      }).query;
      final authUrl = Uri.parse('$_plexAuthUrl/auth#?$params');

      // Step 3: Launch browser for authentication
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      } else {
        return {
          'success': false,
          'error': 'Could not launch authentication URL',
        };
      }

      // Step 4: Poll for authentication (check every 2 seconds for up to 5 minutes)
      for (int i = 0; i < 150; i++) {
        await Future.delayed(const Duration(seconds: 2));
        
        final result = await _checkPin(pinId);
        if (result != null && result['authToken'] != null) {
          final token = result['authToken'];
          
          // Get user info
          final userInfo = await _getUserInfo(token);
          
          return {
            'success': true,
            'token': token,
            'username': userInfo?['username'] ?? userInfo?['email'],
          };
        }
      }

      return {
        'success': false,
        'error': 'Authentication timeout - please try again',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Validate token
  Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_plexApiUrl/api/v2/user'),
        headers: {
          'Accept': 'application/json',
          'X-Plex-Token': token,
          'X-Plex-Client-Identifier': _clientIdentifier,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get servers/resources
  Future<List<Map<String, dynamic>>> getServers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_plexApiUrl/api/v2/resources?includeHttps=1&includeRelay=1'),
        headers: {
          'Accept': 'application/json',
          'X-Plex-Token': token,
          'X-Plex-Client-Identifier': _clientIdentifier,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Filter for servers only (product == 'Plex Media Server')
        return data
            .where((resource) => resource['product'] == 'Plex Media Server' && resource['owned'] == true)
            .map((resource) => {
                  'name': resource['name'] as String,
                  'clientIdentifier': resource['clientIdentifier'] as String,
                  'provides': resource['provides'] as String,
                  'connections': resource['connections'] as List<dynamic>,
                })
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get libraries for a specific server
  Future<List<Map<String, dynamic>>> getLibraries(String token, String serverUrl) async {
    try {
      print('Fetching libraries from: $serverUrl/library/sections');
      final response = await http.get(
        Uri.parse('$serverUrl/library/sections'),
        headers: {
          'Accept': 'application/json',
          'X-Plex-Token': token,
          'X-Plex-Client-Identifier': _clientIdentifier,
        },
      );

      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
        final data = json.decode(response.body);
        print('Parsed JSON successfully');
        print('MediaContainer keys: ${data.keys}');
        
        if (data['MediaContainer'] != null) {
          print('MediaContainer found');
          final directories = data['MediaContainer']['Directory'] as List<dynamic>?;
          print('Directories: ${directories?.length ?? 0}');
          
          if (directories != null) {
            // Debug: Print all library types to see what we have
            for (var dir in directories) {
              print('Library: ${dir['title']}, Type: ${dir['type']}, Key: ${dir['key']}');
            }
            
            final musicLibraries = directories
                .where((dir) => dir['type'] == 'artist')
                .toList();
            
            print('Found ${musicLibraries.length} music libraries');
            
            return musicLibraries.map((dir) => {
                  'key': dir['key'].toString(),
                  'title': dir['title'] as String,
                  'type': dir['type'] as String,
                })
                .toList();
          } else {
            print('No directories array found');
          }
        } else {
          print('No MediaContainer in response');
        }
      } else {
        print('Failed to fetch libraries. Status: ${response.statusCode}, Body: ${response.body}');
      }
      return [];
    } catch (e, stackTrace) {
      print('Error fetching libraries: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Get best connection URL for a server
  String? getBestConnectionUrl(List<dynamic> connections) {
    debugPrint('========== CONNECTION SELECTION ==========');
    debugPrint('Available connections: ${connections.length}');
    for (var conn in connections) {
      debugPrint('  - URI: ${conn['uri']}');
      debugPrint('    Local: ${conn['local']}');
      debugPrint('    Protocol: ${conn['protocol']}');
      debugPrint('    Port: ${conn['port']}');
    }
    
    // PRIORITIZE CUSTOM PORTS (8999, 8777, 8443) over default 32400
    // These are user-configured ports and should be preferred
    final customPorts = [8999, 8777, 8443];
    
    // Try custom port HTTPS connections first (any local/remote)
    for (var customPort in customPorts) {
      for (var conn in connections) {
        if (conn['port'] == customPort && conn['uri'] != null) {
          final uri = conn['uri'] as String;
          if (uri.startsWith('https://')) {
            debugPrint('✓ Selected HTTPS connection with custom port $customPort: $uri');
            return uri;
          }
        }
      }
    }
    
    // Try local HTTPS connections (any port)
    for (var conn in connections) {
      if (conn['local'] == true && conn['uri'] != null) {
        final uri = conn['uri'] as String;
        if (uri.startsWith('https://')) {
          debugPrint('✓ Selected LOCAL HTTPS connection: $uri');
          return uri;
        }
      }
    }
    
    // Try local HTTP connections
    for (var conn in connections) {
      if (conn['local'] == true && conn['uri'] != null) {
        final uri = conn['uri'] as String;
        if (uri.startsWith('http://')) {
          debugPrint('✓ Selected LOCAL HTTP connection: $uri');
          return uri;
        }
      }
    }
    
    // Fall back to remote HTTPS connections (Plex relay - slower)
    for (var conn in connections) {
      if (conn['local'] == false && conn['uri'] != null) {
        final uri = conn['uri'] as String;
        if (uri.startsWith('https://')) {
          debugPrint('✓ Selected REMOTE HTTPS connection (relay): $uri');
          return uri;
        }
      }
    }
    
    // Try any HTTPS connection
    for (var conn in connections) {
      if (conn['uri'] != null) {
        final uri = conn['uri'] as String;
        if (uri.startsWith('https://')) {
          debugPrint('✓ Selected any HTTPS connection: $uri');
          return uri;
        }
      }
    }
    
    // Fall back to any connection
    for (var conn in connections) {
      if (conn['uri'] != null) {
        debugPrint('✓ Selected fallback connection: ${conn['uri']}');
        return conn['uri'] as String;
      }
    }
    
    debugPrint('✗ No connections found!');
    return null;
  }

  // Get all tracks from a library
  Future<List<Map<String, dynamic>>> getTracks(String token, String serverUrl, String libraryKey) async {
    try {
      print('\n--- PLEX SERVICE: getTracks called ---');
      print('PLEX SERVICE: Server URL: $serverUrl');
      print('PLEX SERVICE: Library Key: $libraryKey');
      print('PLEX SERVICE: Token: ${token.substring(0, 10)}...');
      
      // Add type=10 to get tracks specifically (not artists or albums)
      final url = '$serverUrl/library/sections/$libraryKey/all?type=10';
      print('PLEX SERVICE: Full URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'X-Plex-Token': token,
          'X-Plex-Client-Identifier': _clientIdentifier,
        },
      ).timeout(const Duration(seconds: 30));

      print('PLEX SERVICE: Response status: ${response.statusCode}');
      print('PLEX SERVICE: Response body length: ${response.body.length} bytes');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('PLEX SERVICE: JSON decoded successfully');
        
        if (data['MediaContainer'] != null) {
          print('PLEX SERVICE: MediaContainer found');
          print('PLEX SERVICE: MediaContainer keys: ${data['MediaContainer'].keys.toList()}');
          
          final metadata = data['MediaContainer']['Metadata'];
          print('PLEX SERVICE: Metadata type: ${metadata.runtimeType}');
          
          if (metadata == null) {
            print('PLEX SERVICE: WARNING - Metadata is null!');
            return [];
          }
          
          final tracks = metadata as List<dynamic>;
          print('PLEX SERVICE: Found ${tracks.length} tracks in response');
          
          if (tracks.isEmpty) {
            print('PLEX SERVICE: WARNING - Track list is empty!');
            return [];
          }
          
          // Print first track details for debugging
          if (tracks.isNotEmpty) {
            print('PLEX SERVICE: First track sample: ${tracks[0].keys.toList()}');
            print('PLEX SERVICE: First track title: ${tracks[0]['title']}');
            print('PLEX SERVICE: First track type: ${tracks[0]['type']}');
          }
          
          final mappedTracks = tracks.map((track) => {
                'title': track['title'] as String? ?? 'Unknown',
                'artist': track['originalTitle'] as String? ?? track['grandparentTitle'] as String? ?? 'Unknown Artist',
                'album': track['parentTitle'] as String? ?? 'Unknown Album',
                'duration': track['duration'] as int? ?? 0,
                'key': track['key'] as String? ?? '',
                'thumb': track['thumb'] as String? ?? '',
                'year': track['year'] as int? ?? 0,
                'addedAt': track['addedAt'] as int?,
                'Media': track['Media'] as List<dynamic>? ?? [],
              })
              .toList();
          
          print('PLEX SERVICE: Successfully mapped ${mappedTracks.length} tracks');
          print('--- PLEX SERVICE: getTracks completed ---\n');
          return mappedTracks;
        } else {
          print('PLEX SERVICE: ERROR - MediaContainer is null!');
          print('PLEX SERVICE: Response data keys: ${data.keys.toList()}');
        }
      } else {
        print('PLEX SERVICE: ERROR - HTTP ${response.statusCode}');
        print('PLEX SERVICE: Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      }
      return [];
    } catch (e, stackTrace) {
      print('PLEX SERVICE: EXCEPTION in getTracks - $e');
      print('PLEX SERVICE: Stack trace: $stackTrace');
      return [];
    }
  }
}
