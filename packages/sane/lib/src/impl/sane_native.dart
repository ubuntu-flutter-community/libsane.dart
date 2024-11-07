import 'dart:async';
import 'dart:typed_data';

import 'package:sane/src/exceptions.dart';
import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/cancel.dart';
import 'package:sane/src/isolate_messages/close.dart';
import 'package:sane/src/isolate_messages/control_button_option.dart';
import 'package:sane/src/isolate_messages/control_option.dart';
import 'package:sane/src/isolate_messages/exit.dart';
import 'package:sane/src/isolate_messages/get_all_option_descriptors.dart';
import 'package:sane/src/isolate_messages/get_devices.dart';
import 'package:sane/src/isolate_messages/get_option_descriptor.dart';
import 'package:sane/src/isolate_messages/get_parameters.dart';
import 'package:sane/src/isolate_messages/init.dart';
import 'package:sane/src/isolate_messages/open.dart';
import 'package:sane/src/isolate_messages/read.dart';
import 'package:sane/src/isolate_messages/start.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class NativeSane implements Sane {
  factory NativeSane() => _instance ??= NativeSane._();

  NativeSane._();

  static NativeSane? _instance;

  bool get _disposed => _isolate?.exited == true;
  SaneIsolate? _isolate;

  Future<SaneIsolate> _getIsolate() async {
    if (_isolate?.exited == true) throw SaneDisposedError();
    return _isolate ??= await SaneIsolate.spawn();
  }

  Future<int> init({
    AuthCallback? authCallback,
  }) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(InitMessage());
    return response.versionCode;
  }

  @override
  Future<void> dispose({bool force = false}) async {
    if (force) {
      _isolate?.kill();
      return;
    }

    if (_disposed) return;

    await _isolate?.sendMessage(ExitMessage());
  }

  @override
  Future<List<SaneDevice>> getDevices({
    required bool localOnly,
  }) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      GetDevicesMessage(localOnly: localOnly),
    );

    return response.devices;
  }

  Future<int> open(String deviceName) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      OpenMessage(deviceName: deviceName),
    );

    return response.handle;
  }

  Future<int> openDevice(SaneDevice device) {
    return open(device.name);
  }

  Future<SaneOptionDescriptor> getOptionDescriptor(int handle,
    int index,
  ) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      GetOptionDescriptorMessage(
        saneHandle: handle,
        index: index,
      ),
    );

    return response.optionDescriptor;
  }

  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors(int handle,
  ) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      GetAllOptionDescriptorsMessage(saneHandle: handle),
    );

    return response.optionDescriptors;
  }

  Future<SaneOptionResult<bool>> controlBoolOption({
    required int handle,
    required int index,
    required SaneAction action,
    bool? value,
  }) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      ControlValueOptionMessage<bool>(
        saneHandle: handle,
        index: index,
        action: action,
        value: value,
      ),
    );

    return response.result;
  }

  Future<SaneOptionResult<int>> controlIntOption({
    required int handle,
    required int index,
    required SaneAction action,
    int? value,
  }) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      ControlValueOptionMessage<int>(
        saneHandle: handle,
        index: index,
        action: action,
        value: value,
      ),
    );

    return response.result;
  }

  Future<SaneOptionResult<double>> controlFixedOption({
    required int handle,
    required int index,
    required SaneAction action,
    double? value,
  }) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      ControlValueOptionMessage<double>(
        saneHandle: handle,
        index: index,
        action: action,
        value: value,
      ),
    );

    return response.result;
  }

  Future<SaneOptionResult<String>> controlStringOption({
    required int handle,
    required int index,
    required SaneAction action,
    String? value,
  }) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      ControlValueOptionMessage<String>(
        saneHandle: handle,
        index: index,
        action: action,
        value: value,
      ),
    );

    return response.result;
  }

  Future<SaneOptionResult<Null>> controlButtonOption({
    required int handle,
    required int index,
  }) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      ControlButtonOptionMessage(
        saneHandle: handle,
        index: index,
      ),
    );

    return response.result;
  }

  Future<SaneParameters> getParameters(int handle) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      GetParametersMessage(
        saneHandle: handle,
      ),
    );

    return response.parameters;
  }

  Future<void> start(int handle) async {
    final isolate = await _getIsolate();
    await isolate.sendMessage(
      StartMessage(saneHandle: handle),
    );
  }
}

class NativeSaneDevice implements SaneDevice {
  NativeSaneDevice({
    required NativeSane sane,
    required this.name,
    required this.type,
    required this.vendor,
    required this.model,
  }) : _sane = sane;

  final NativeSane _sane;

  bool _closed = false;

  int? _handlePointer;

  @override
  final String name;

  @override
  final String type;

  @override
  final String? vendor;

  @override
  final String model;

  @override
  Future<void> cancel() async {
    if (_closed) return;

    final isolate = _sane._isolate;

    if (isolate == null || _handlePointer == null) return;

    final message = CancelMessage(_handlePointer!);
    await isolate.sendMessage(message);
  }

  @override
  Future<void> close() async {
    if (_closed) return;

    _closed = true;

    final isolate = _sane._isolate;

    if (isolate == null || _handlePointer == null) return;

    final message = CloseMessage(_handlePointer!);
    await isolate.sendMessage(message);
  }

  @override
  Future<Uint8List> read({required int bufferSize}) async {
    final isolate = await _sane._getIsolate();
    final response = await isolate.sendMessage(
      ReadMessage(
        bufferSize: bufferSize,
        saneHandle: _handle,
      ),
    );

    return response.bytes;
  }

  @override
  FutureOr<void> start() {}
}
