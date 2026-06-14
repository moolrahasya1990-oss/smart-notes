import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'notes_provider.dart';

class AuthState {
  final bool hasPin;
  final String? savedPin;
  final bool isBiometricsEnabled;
  final bool isLocked;
  final bool isBiometricsSupported;

  AuthState({
    required this.hasPin,
    this.savedPin,
    required this.isBiometricsEnabled,
    required this.isLocked,
    required this.isBiometricsSupported,
  });

  AuthState copyWith({
    bool? hasPin,
    String? Function()? savedPin,
    bool? isBiometricsEnabled,
    bool? isLocked,
    bool? isBiometricsSupported,
  }) {
    return AuthState(
      hasPin: hasPin ?? this.hasPin,
      savedPin: savedPin != null ? savedPin() : this.savedPin,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isLocked: isLocked ?? this.isLocked,
      isBiometricsSupported: isBiometricsSupported ?? this.isBiometricsSupported,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthNotifier(this._ref) : super(AuthState(
    hasPin: false,
    isBiometricsEnabled: false,
    isLocked: false,
    isBiometricsSupported: false,
  )) {
    _init();
  }

  Future<void> _init() async {
    final repo = _ref.read(notesRepositoryProvider);
    await repo.init();
    
    final pin = repo.getPin();
    final bioEnabled = repo.isBiometricsEnabled();
    final hasPinLocal = pin != null && pin.isNotEmpty;

    bool canCheckBiometrics = false;
    bool hasBiometricHardware = false;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      hasBiometricHardware = await _localAuth.isDeviceSupported();
    } catch (_) {}

    state = AuthState(
      hasPin: hasPinLocal,
      savedPin: pin,
      isBiometricsEnabled: bioEnabled,
      isLocked: hasPinLocal, // Lock immediately on boot if PIN exists
      isBiometricsSupported: canCheckBiometrics && hasBiometricHardware,
    );

    // Auto trigger biometrics if locked and enabled
    if (state.isLocked && state.isBiometricsEnabled) {
      authenticateWithBiometrics();
    }
  }

  Future<bool> setPin(String pin) async {
    final repo = _ref.read(notesRepositoryProvider);
    await repo.savePin(pin);
    state = state.copyWith(
      hasPin: true,
      savedPin: () => pin,
      isLocked: false,
    );
    return true;
  }

  Future<void> removePin() async {
    final repo = _ref.read(notesRepositoryProvider);
    await repo.savePin(null);
    await repo.setBiometricsEnabled(false);
    state = state.copyWith(
      hasPin: false,
      savedPin: () => null,
      isBiometricsEnabled: false,
      isLocked: false,
    );
  }

  Future<void> toggleBiometrics(bool enabled) async {
    final repo = _ref.read(notesRepositoryProvider);
    await repo.setBiometricsEnabled(enabled);
    state = state.copyWith(isBiometricsEnabled: enabled);
  }

  bool unlockWithPin(String pin) {
    if (state.savedPin == pin) {
      state = state.copyWith(isLocked: false);
      return true;
    }
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!state.isBiometricsSupported || !state.isBiometricsEnabled) {
      return false;
    }
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your biometric signature to unlock Smart Notes',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        state = state.copyWith(isLocked: false);
        return true;
      }
    } catch (_) {}
    return false;
  }

  void lockApp() {
    if (state.hasPin) {
      state = state.copyWith(isLocked: true);
      if (state.isBiometricsEnabled) {
        authenticateWithBiometrics();
      }
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
