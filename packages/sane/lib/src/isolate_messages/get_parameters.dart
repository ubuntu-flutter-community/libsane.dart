import 'package:sane/src/impl/sane_sync.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class GetParametersMessage implements IsolateMessage<GetParametersResponse> {
  GetParametersMessage({required this.saneHandle});

  final int saneHandle;

  @override
  Future<GetParametersResponse> handle(Sane sane) async {
    return GetParametersResponse(
      parameters: await sane.getParameters(saneHandle),
    );
  }
}

class GetParametersResponse implements IsolateResponse {
  GetParametersResponse({required this.parameters});

  final SaneParameters parameters;
}
