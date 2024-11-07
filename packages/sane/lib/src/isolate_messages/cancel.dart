import 'package:sane/src/impl/sane_sync.dart';
import 'package:sane/src/isolate_messages/interface.dart';

class CancelMessage implements IsolateMessage {
  CancelMessage(this.saneHandle);

  final int saneHandle;

  @override
  Future<CancelResponse> handle(SaneSync sane) async {
    await sane.cancel(saneHandle);
    return CancelResponse();
  }
}

class CancelResponse implements IsolateResponse {}
