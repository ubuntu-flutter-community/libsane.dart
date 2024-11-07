import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/dylib.dart';
import 'package:sane/src/extensions.dart';
import 'package:sane/src/logger.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/type_conversion.dart';

class SaneSync implements Sane {
  factory SaneSync() => _instance ??= SaneSync._();

  SaneSync._();

  static SaneSync? _instance;
  bool _disposed = false;

  int init({AuthCallback? authCallback}) {
    _checkIfDisposed();

    void authCallbackAdapter(
      SANE_String_Const resource,
      ffi.Pointer<SANE_Char> username,
      ffi.Pointer<SANE_Char> password,
    ) {
      final credentials = authCallback!(dartStringFromSaneString(resource)!);
      for (var i = 0;
          i < credentials.username.length && i < SANE_MAX_USERNAME_LEN;
          i++) {
        username[i] = credentials.username.codeUnitAt(i);
      }
      for (var i = 0;
          i < credentials.password.length && i < SANE_MAX_PASSWORD_LEN;
          i++) {
        password[i] = credentials.password.codeUnitAt(i);
      }
    }

    final versionCodePointer = ffi.calloc<SANE_Int>();
    final nativeAuthCallback = authCallback != null
        ? ffi.NativeCallable<SANE_Auth_CallbackFunction>.isolateLocal(
            authCallbackAdapter,
          ).nativeFunction
        : ffi.nullptr;
    try {
      final status = dylib.sane_init(versionCodePointer, nativeAuthCallback);

      logger.finest('sane_init() -> ${status.name}');

      status.check();

      final versionCode = versionCodePointer.value;

      logger.finest(
        'SANE version: ${SaneUtils.version(versionCode)}',
      );

      return versionCode;
    } finally {
      ffi.calloc.free(versionCodePointer);
      ffi.calloc.free(nativeAuthCallback);
    }
  }

  @override
  Future<void> dispose() {
    if (_disposed) return Future.value();

    final completer = Completer<void>();

    Future(() {
      _disposed = true;

      dylib.sane_exit();
      logger.finest('sane_exit()');

      completer.complete();

      _instance = null;
    });

    return completer.future;
  }

  @override
  List<SyncSaneDevice> getDevices({required bool localOnly}) {
    _checkIfDisposed();

    final deviceListPointer =
        ffi.calloc<ffi.Pointer<ffi.Pointer<SANE_Device>>>();

    try {
      final status = dylib.sane_get_devices(
        deviceListPointer,
        localOnly.asSaneBool,
      );

      logger.finest('sane_get_devices() -> ${status.name}');

      status.check();

      final devices = <SyncSaneDevice>[];

      for (var i = 0; deviceListPointer.value[i] != ffi.nullptr; i++) {
        final device = deviceListPointer.value[i].ref;
        devices.add(SyncSaneDevice(device));
      }

      return List.unmodifiable(devices);
    } finally {
      ffi.calloc.free(deviceListPointer);
    }
  }

  Future<SaneOptionDescriptor> getOptionDescriptor(SANE_Handle handle,
    int index,
  ) {
    _checkIfDisposed();

    final completer = Completer<SaneOptionDescriptor>();

    Future(() {
      final optionDescriptorPointer =
          dylib.sane_get_option_descriptor(handle, index);
      final optionDescriptor = saneOptionDescriptorFromNative(
        optionDescriptorPointer.ref,
        index,
      );

      ffi.calloc.free(optionDescriptorPointer);

      completer.complete(optionDescriptor);
    });

    return completer.future;
  }

  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors(SANE_Handle handle,
  ) {
    _checkIfDisposed();

    final completer = Completer<List<SaneOptionDescriptor>>();

    Future(() {
      final optionDescriptors = <SaneOptionDescriptor>[];

      for (var i = 0; true; i++) {
        final descriptorPointer = dylib.sane_get_option_descriptor(handle, i);
        if (descriptorPointer == ffi.nullptr) break;
        optionDescriptors.add(
          saneOptionDescriptorFromNative(descriptorPointer.ref, i),
        );
      }

      completer.complete(optionDescriptors);
    });

    return completer.future;
  }

  Future<SaneOptionResult<T>> _controlOption<T>({
    required SANE_Handle handle,
    required int index,
    required SaneAction action,
    T? value,
  }) {
    _checkIfDisposed();

    final completer = Completer<SaneOptionResult<T>>();

    Future(() {
      final optionDescriptor = saneOptionDescriptorFromNative(
        dylib.sane_get_option_descriptor(handle, index).ref,
        index,
      );
      final optionType = optionDescriptor.type;
      final optionSize = optionDescriptor.size;

      final infoPointer = ffi.calloc<SANE_Int>();

      late final ffi.Pointer valuePointer;
      switch (optionType) {
        case SaneOptionValueType.bool:
          valuePointer = ffi.calloc<SANE_Bool>(optionSize);

        case SaneOptionValueType.int:
          valuePointer = ffi.calloc<SANE_Int>(optionSize);

        case SaneOptionValueType.fixed:
          valuePointer = ffi.calloc<SANE_Word>(optionSize);

        case SaneOptionValueType.string:
          valuePointer = ffi.calloc<SANE_Char>(optionSize);

        case SaneOptionValueType.button:
          valuePointer = ffi.nullptr;

        case SaneOptionValueType.group:
          throw const SaneInvalidDataException();
      }

      if (action == SaneAction.setValue) {
        switch (optionType) {
          case SaneOptionValueType.bool:
            if (value is! bool) continue invalid;
            (valuePointer as ffi.Pointer<SANE_Bool>).value = value.asSaneBool;
            break;

          case SaneOptionValueType.int:
            if (value is! int) continue invalid;
            (valuePointer as ffi.Pointer<SANE_Int>).value = value;
            break;

          case SaneOptionValueType.fixed:
            if (value is! double) continue invalid;
            (valuePointer as ffi.Pointer<SANE_Word>).value =
                doubleToSaneFixed(value);
            break;

          case SaneOptionValueType.string:
            if (value is! String) continue invalid;
            (valuePointer as ffi.Pointer<SANE_String_Const>).value =
                value.toSaneString();
            break;

          case SaneOptionValueType.button:
            break;

          case SaneOptionValueType.group:
            continue invalid;

          invalid:
          default:
            throw const SaneInvalidDataException();
        }
      }

      final status = dylib.sane_control_option(
        handle,
        index,
        nativeSaneActionFromDart(action),
        valuePointer.cast<ffi.Void>(),
        infoPointer,
      );
      logger.finest(
        'sane_control_option($index, $action, $value) -> ${status.name}',
      );

      status.check();

      final infos = saneOptionInfoFromNative(infoPointer.value);
      late final dynamic result;
      switch (optionType) {
        case SaneOptionValueType.bool:
          result = dartBoolFromSaneBool(
            (valuePointer as ffi.Pointer<SANE_Bool>).value,
          );

        case SaneOptionValueType.int:
          result = (valuePointer as ffi.Pointer<SANE_Int>).value;

        case SaneOptionValueType.fixed:
          result =
              saneFixedToDouble((valuePointer as ffi.Pointer<SANE_Word>).value);

        case SaneOptionValueType.string:
          result = dartStringFromSaneString(
                valuePointer as ffi.Pointer<SANE_Char>,
              ) ??
              '';

        case SaneOptionValueType.button:
          result = null;

        default:
          throw const SaneInvalidDataException();
      }

      ffi.calloc.free(valuePointer);
      ffi.calloc.free(infoPointer);

      completer.complete(
        SaneOptionResult(
          result: result,
          infos: infos,
        ),
      );
    });

    return completer.future;
  }

  Future<SaneOptionResult<bool>> controlBoolOption({
    required SANE_Handle handle,
    required int index,
    required SaneAction action,
    bool? value,
  }) {
    return _controlOption<bool>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  Future<SaneOptionResult<int>> controlIntOption({
    required SANE_Handle handle,
    required int index,
    required SaneAction action,
    int? value,
  }) {
    return _controlOption<int>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  Future<SaneOptionResult<double>> controlFixedOption({
    required SANE_Handle handle,
    required int index,
    required SaneAction action,
    double? value,
  }) {
    return _controlOption<double>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  Future<SaneOptionResult<String>> controlStringOption({
    required SANE_Handle handle,
    required int index,
    required SaneAction action,
    String? value,
  }) {
    return _controlOption<String>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  Future<SaneOptionResult<Null>> controlButtonOption({
    required SANE_Handle handle,
    required int index,
  }) {
    return _controlOption<Null>(
      handle: handle,
      index: index,
      action: SaneAction.setValue,
      value: null,
    );
  }

  Future<SaneParameters> getParameters(SANE_Handle handle) {
    _checkIfDisposed();

    final completer = Completer<SaneParameters>();

    Future(() {
      final nativeParametersPointer = ffi.calloc<SANE_Parameters>();
      final status = dylib.sane_get_parameters(
        handle,
        nativeParametersPointer,
      );
      logger.finest('sane_get_parameters() -> ${status.name}');

      status.check();

      final parameters = saneParametersFromNative(nativeParametersPointer.ref);

      ffi.calloc.free(nativeParametersPointer);

      completer.complete(parameters);
    });

    return completer.future;
  }

  @pragma('vm:prefer-inline')
  void _checkIfDisposed() {
    if (_disposed) throw SaneDisposedError();
  }
}

class SyncSaneDevice implements SaneDevice, ffi.Finalizable {
  factory SyncSaneDevice(SANE_Device device) {
    final vendor = device.vendor.toDartString();
    return SyncSaneDevice._(
      name: device.name.toDartString(),
      vendor: vendor == 'Noname' ? null : vendor,
      type: device.type.toDartString(),
      model: device.model.toDartString(),
    );
  }

  SyncSaneDevice._({
    required this.name,
    required this.vendor,
    required this.model,
    required this.type,
  });

  static final _finalizer = ffi.NativeFinalizer(dylib.addresses.sane_close);

  SANE_Handle? _handle;

  bool _closed = false;

  @override
  final String name;

  @override
  final String type;

  @override
  final String? vendor;

  @override
  final String model;

  @override
  void cancel() {
    _checkIfDisposed();

    final handle = _handle;

    if (handle == null) return;

    dylib.sane_cancel(handle);
  }

  SANE_Handle _open() {
    final namePointer = name.toSaneString();
    final handlePointer = ffi.calloc.allocate<SANE_Handle>(
      ffi.sizeOf<SANE_Handle>(),
    );

    try {
      dylib.sane_open(namePointer, handlePointer).check();
      final handle = handlePointer.value;
      _finalizer.attach(this, handle);
      return handle;
    } finally {
      ffi.calloc.free(namePointer);
      ffi.calloc.free(handlePointer);
    }
  }

  @override
  void close() {
    if (_closed) return;

    _closed = true;

    if (_handle == null) return;

    _finalizer.detach(this);
    dylib.sane_close(_handle!);
  }

  @override
  Uint8List read({required int bufferSize}) {
    _checkIfDisposed();

    final handle = _handle ??= _open();

    final lengthPointer = ffi.calloc<SANE_Int>();
    final bufferPointer = ffi.calloc<SANE_Byte>(bufferSize);

    try {
      dylib.sane_read(handle, bufferPointer, bufferSize, lengthPointer).check();

      logger.finest('sane_read()');

      final length = lengthPointer.value;
      final buffer = bufferPointer.cast<Uint8>().asTypedList(length);

      return buffer;
    } finally {
      ffi.calloc.free(lengthPointer);
      ffi.calloc.free(bufferPointer);
    }
  }

  @override
  void start() {
    _checkIfDisposed();

    final handle = _handle ??= _open();

    dylib.sane_start(handle).check();
  }

  @pragma('vm:prefer-inline')
  void _checkIfDisposed() {
    if (_closed) throw SaneDisposedError();
  }
}
