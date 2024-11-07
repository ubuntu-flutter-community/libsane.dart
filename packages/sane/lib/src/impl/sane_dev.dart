import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/sane.dart';

final _logger = Logger('sane.dev');

class SaneDev implements Sane {
  @override
  Future<SaneOptionResult<bool>> controlBoolOption({
    required int handle,
    required int index,
    required SaneAction action,
    bool? value,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_controlBoolOption()');
      return SaneOptionResult(result: value ?? true, infos: []);
    });
  }

  @override
  Future<SaneOptionResult<Null>> controlButtonOption({
    required int handle,
    required int index,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_controlButtonOption()');
      return SaneOptionResult(result: null, infos: []);
    });
  }

  @override
  Future<SaneOptionResult<double>> controlFixedOption({
    required int handle,
    required int index,
    required SaneAction action,
    double? value,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_controlFixedOption()');
      return SaneOptionResult(result: value ?? .1, infos: []);
    });
  }

  @override
  Future<SaneOptionResult<int>> controlIntOption({
    required int handle,
    required int index,
    required SaneAction action,
    int? value,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_controlIntOption()');
      return SaneOptionResult(result: value ?? 1, infos: []);
    });
  }

  @override
  Future<SaneOptionResult<String>> controlStringOption({
    required int handle,
    required int index,
    required SaneAction action,
    String? value,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_controlStringOption()');
      return SaneOptionResult(result: value ?? 'value', infos: []);
    });
  }

  @override
  Future<void> dispose() {
    return Future(() {
      _logger.finest('sane_exit()');
    });
  }

  @override
  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors(int handle,
  ) {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_getAllOptionDescriptors()');
      return [
        SaneOptionDescriptor(
          index: 0,
          name: 'name',
          title: 'title',
          desc: 'desc',
          type: SaneOptionValueType.int,
          unit: SaneOptionUnit.none,
          size: 1,
          capabilities: [],
          constraint: null,
        ),
      ];
    });
  }

  @override
  Future<List<SaneDevDevice>> getDevices({
    required bool localOnly,
  }) {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_getDevices()');
      return [
        for (var i = 0; i < 3; i++) SaneDevDevice(i),
      ];
    });
  }

  @override
  Future<SaneOptionDescriptor> getOptionDescriptor(int handle,
    int index,
  ) {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_getOptionDescriptor()');
      return SaneOptionDescriptor(
        index: index,
        name: 'name',
        title: 'title',
        desc: 'desc',
        type: SaneOptionValueType.int,
        unit: SaneOptionUnit.none,
        size: 1,
        capabilities: [],
        constraint: null,
      );
    });
  }

  @override
  Future<SaneParameters> getParameters(int handle) {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_getParameters()');
      return SaneParameters(
        format: SaneFrameFormat.gray,
        lastFrame: true,
        bytesPerLine: 800,
        pixelsPerLine: 100,
        lines: 100,
        depth: 8,
      );
    });
  }
}

class SaneDevDevice implements SaneDevice {
  const SaneDevDevice(this.index);

  final int index;

  @override
  Future<void> cancel() {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_cancel()');
    });
  }

  @override
  Future<void> close() {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_close()');
    });
  }

  @override
  String get model => 'Model $index';

  @override
  String get name => 'Name $index';

  @override
  Future<Uint8List> read({required int bufferSize}) {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_read()');
      return Uint8List.fromList([]);
    });
  }

  @override
  Future<void> start() {
    return Future.delayed(const Duration(seconds: 1), () {
      _logger.finest('sane_start()');
    });
  }

  @override
  String get type => 'Type $index';

  @override
  String? get vendor => 'Vendor $index';
}
