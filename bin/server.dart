import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

late final client;

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/echo-user', _echoUsers);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

Future<Response> _echoUsers(Request request) async{

  // Retrieve data from 'users' table
  final response =  await client
      .from('users')
      .select()
      .execute();

  var map = {
    'users' : response.data
  };

  return Response.ok(jsonEncode(map));
}

void main(List<String> args) async {

  var dotenv = DotEnv(includePlatformEnvironment: true)..load();
  client = SupabaseClient(dotenv['SUPABASE_URL']!, dotenv['SUPABASE_KEY']!);
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final _handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(_handler, ip, port);
  print('Server listening on port ${server.port}');
}
