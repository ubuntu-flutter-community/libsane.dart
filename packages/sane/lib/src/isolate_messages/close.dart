import 'package:sane/sane.dart';
import 'package:sane/src/isolate_messages/interface.dart';

class CloseMessage implements IsolateMessage {
  CloseMessage(this.saneHandle);

  final int saneHandle;

  @override
  Future<CloseResponse> handle(SaneSync sane) async {
    await sane.close(saneHandle);
    return CloseResponse();
  }
}

class CloseResponse implements IsolateResponse {}
