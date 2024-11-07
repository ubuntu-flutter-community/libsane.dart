import 'package:sane/src/impl/sane_sync.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/structures.dart';

class GetOptionDescriptorMessage
    implements IsolateMessage<GetOptionDescriptorResponse> {
  GetOptionDescriptorMessage({
    required this.saneHandle,
    required this.index,
  });

  final int saneHandle;
  final int index;

  @override
  Future<GetOptionDescriptorResponse> handle(Sane sane) async {
    return GetOptionDescriptorResponse(
      optionDescriptor: await sane.getOptionDescriptor(saneHandle, index),
    );
  }
}

class GetOptionDescriptorResponse implements IsolateResponse {
  GetOptionDescriptorResponse({required this.optionDescriptor});

  final SaneOptionDescriptor optionDescriptor;
}
