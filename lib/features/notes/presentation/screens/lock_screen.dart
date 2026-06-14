import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'notes_list_screen.dart';

class LockScreen extends ConsumerStatefulWidget {
  final bool isSettingPin; // If true, we are setting up a state rather than unlocking
  final ValueChanged<String>? onPinConfigured;

  const LockScreen({
    Key? key,
    this.isSettingPin = false,
    this.onPinConfigured,
  }) : super(key: key);

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _enteredCode = '';
  String? _firstEnteredPin; // Used in double-confirmation when setting up a PIN
  String _statusText = 'Enter PIN to Unlock';

  @override
  void initState() {
    super.initState();
    if (widget.isSettingPin) {
      _statusText = 'Create a 4-Digit Passcode';
    }
  }

  void _onKeyPress(String num) {
    if (_enteredCode.length < 4) {
      setState(() {
        _enteredCode += num;
      });
    }

    if (_enteredCode.length == 4) {
      // Small delay to let the user see the 4th bubble fill before processing
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        _processPin();
      });
    }
  }

  void _onDelete() {
    if (_enteredCode.isNotEmpty) {
      setState(() {
        _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
      });
    }
  }

  void _processPin() {
    if (widget.isSettingPin) {
      if (_firstEnteredPin == null) {
        // First entry done, ask for confirmation
        setState(() {
          _firstEnteredPin = _enteredCode;
          _enteredCode = '';
          _statusText = 'Confirm your 4-Digit Passcode';
        });
      } else {
        // Confirmation matching check
        if (_firstEnteredPin == _enteredCode) {
          if (widget.onPinConfigured != null) {
            widget.onPinConfigured!(_enteredCode);
          }
        } else {
          setState(() {
            _enteredCode = '';
            _firstEnteredPin = null;
            _statusText = 'PIN mismatch. Create a 4-Digit Passcode';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passcodes did not match. Please try again.')),
          );
        }
      }
    } else {
      // Unlocking scenario
      final success = ref.read(authProvider.notifier).unlockWithPin(_enteredCode);
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NotesListScreen()),
        );
      } else {
        setState(() {
          _enteredCode = '';
          _statusText = 'Incorrect PIN. Try Again';
        });
      }
    }
  }

  Future<void> _triggerBiometrics() async {
    final success = await ref.read(authProvider.notifier).authenticateWithBiometrics();
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NotesListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Header
            Icon(
              widget.isSettingPin ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _statusText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Code preview dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredCode.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isFilled ? theme.colorScheme.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const Spacer(flex: 2),
            // Keyboard Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  _buildKeyboardRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeyboardRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeyboardRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bio or cancel button
                      WidgetToShowBioOrPlaceholder(
                        authState: authState,
                        onPressed: _triggerBiometrics,
                        theme: theme,
                        isSettingPin: widget.isSettingPin,
                      ),
                      _buildKeyButton('0'),
                      _buildIconButton(Icons.backspace_outlined, _onDelete),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(flex: 3),
            if (widget.isSettingPin)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map(_buildKeyButton).toList(),
    );
  }

  Widget _buildKeyButton(String key) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.12)),
      ),
      child: InkWell(
        onTap: () => _onKeyPress(key),
        customBorder: const CircleBorder(),
        child: Center(
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 68,
      height: 68,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Center(
          child: Icon(
            icon,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class WidgetToShowBioOrPlaceholder extends StatelessWidget {
  final AuthState authState;
  final VoidCallback onPressed;
  final ThemeData theme;
  final bool isSettingPin;

  const WidgetToShowBioOrPlaceholder({
    Key? key,
    required this.authState,
    required this.onPressed,
    required this.theme,
    required this.isSettingPin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isSettingPin && authState.isBiometricsSupported && authState.isBiometricsEnabled) {
      return Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              Icons.fingerprint_rounded,
              size: 28,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }
    return const SizedBox(width: 68, height: 68);
  }
}
