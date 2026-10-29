export 'database_init_stub.dart'
    if (dart.library.io) 'database_init_io.dart'
    if (dart.library.js_interop) 'database_init_web.dart';

