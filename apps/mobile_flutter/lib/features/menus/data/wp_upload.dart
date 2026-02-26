export 'wp_upload_stub.dart'
    if (dart.library.html) 'wp_upload_web.dart'
    if (dart.library.io) 'wp_upload_io.dart';
