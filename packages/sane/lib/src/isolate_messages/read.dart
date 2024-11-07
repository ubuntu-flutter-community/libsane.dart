import 'dart:typed_data';

import 'package:sane/src/impl/sane_sync.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class ReadMessage implements IsolateMessage<ReadResponse> {
  ReadMessage({
    required this.saneHandle,
    required this.bufferSize,
  });

  final int saneHandle;
  final int bufferSize;

  @override
  Future<ReadResponse> handle(Sane sane) async {
    return ReadResponse(
      bytes: await sane.read(saneHandle, bufferSize),
    );
  }
}

class ReadResponse implements IsolateResponse {
  ReadResponse({
    required this.bytes,
  });

  final Uint8List bytes;
}
