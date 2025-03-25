import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

///////////////////////////////////////////////////////////////
/// passerelle entre mon serveur qui nécéssite une authentification et
/// ce con de vlc qui ne prend pas de header bearer...
class VideoProxyServer {
  HttpServer? _server;

  Future<int> startProxy() async {
    final router = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_proxyHandler);
    _server = await io.serve(router, InternetAddress.loopbackIPv4, 8081);
    return _server!.port;
  }

  Future<void> stopProxy() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<Response> _proxyHandler(Request request) async {
    final token = await _getIdToken();
    if (token == null) {
      return Response.forbidden('Non authentifié');
    }

    final videoUrl = request.url.queryParameters['url'];
    if (videoUrl == null) {
      return Response.badRequest(body: 'URL de la vidéo manquante');
    }

    final decodedUrl = Uri.decodeComponent(videoUrl);
    final rangeHeader = request.headers['range'];
    final headers = {
      'Authorization': 'Bearer $token',
      if (rangeHeader != null) 'Range': rangeHeader,
    };

    try {
      final streamResponse = await http.Client().send(
        http.Request('GET', Uri.parse(decodedUrl))..headers.addAll(headers),
      );
      if (streamResponse.statusCode == 404) {
        return Response.notFound('Fichier introuvable');
      }
      bool isPartialContent = streamResponse.statusCode == 206;
      return Response(
        streamResponse.statusCode,
        body: streamResponse.stream,
        headers: {
          'Content-Type': streamResponse.headers['content-type'] ?? 'video/mp4',
          'Content-Length': streamResponse.contentLength?.toString() ?? '',
          'Accept-Ranges': 'bytes',
          if (isPartialContent) 'Content-Range': streamResponse.headers['content-range'] ?? '',
        },
      );
    } catch (e) {
      return Response.internalServerError(body: '❌ Erreur proxy : $e');
    }
  }

  Future<String?> _getIdToken() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      return user != null ? await user.getIdToken() : null;
    } catch (e) {
      return null;
    }
  }
}