// Legacy compatibility export. New code should import core/media instead.
export 'wp_upload_stub.dart'
    if (dart.library.html) 'wp_upload_web.dart';
