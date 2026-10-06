import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/phone_auth_service.dart';
import '../services/user_profile_service.dart';

abstract final class RastrosColors {
  static const cream = Color(0xFFFCF8EF);
  static const navy = Color(0xFF283B66);
  static const blue = Color(0xFF506EB0);
  static const teal = Color(0xFF379992);
  static const yellow = Color(0xFFFFC653);
  static const lilac = Color(0xFFD8C8F0);
  static const sky = Color(0xFFC4E0EF);
  static const muted = Color(0xFF8E9BB2);
  static const line = Color(0xFFD6D9DF);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authService,
    this.profileService,
    this.enablePhoneAuth = false,
  });

  final PhoneAuthService? authService;
  final UserProfileService? profileService;
  final bool enablePhoneAuth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final PhoneAuthService _authService =
      widget.authService ?? FirebasePhoneAuthService();
  late final UserProfileService _profileService =
      widget.profileService ?? FirestoreUserProfileService();
  bool _sendingCode = false;
  bool _verificationFinished = false;
  String? _message;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _openTesterMode() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OtpScreen(
          phoneNumber: '',
          verificationId: '',
          enablePhoneAuth: false,
          testerMode: true,
        ),
      ),
    );
  }

  String _phoneNumberWithCountryCode(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (input.trimLeft().startsWith('+')) return '+$digits';
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    return '+57$digits';
  }

  Future<void> _continue() async {
    if (!widget.enablePhoneAuth) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sendingCode = true;
      _message = null;
      _verificationFinished = false;
    });
    try {
      await _authService.sendCode(
        _phoneNumberWithCountryCode(_phoneController.text),
        onCodeSent: (verificationId) {
          if (!mounted || _verificationFinished) return;
          setState(() => _sendingCode = false);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OtpScreen(
                phoneNumber: _phoneNumberWithCountryCode(_phoneController.text),
                verificationId: verificationId,
                authService: _authService,
                profileService: _profileService,
                enablePhoneAuth: widget.enablePhoneAuth,
              ),
            ),
          );
        },
        onAutoVerified: (user) async {
          if (!mounted) return;
          _verificationFinished = true;
          try {
            await _profileService.ensureProfile(
              uid: user.uid,
              phoneNumber: user.phoneNumber,
            );
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
              (_) => false,
            );
          } catch (error) {
            if (!mounted) return;
            setState(() {
              _sendingCode = false;
              _message = 'No se pudo guardar tu perfil en Firestore: $error';
            });
          }
        },
        onError: (message) {
          if (!mounted) return;
          setState(() {
            _sendingCode = false;
            _message = message;
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sendingCode = false;
        _message = 'No se pudo enviar el código: $error';
      });
    }
    if (mounted) setState(() => _sendingCode = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 350,
                        width: double.infinity,
                        child: Image.asset(
                          key: const Key('login-pets-art'),
                          'Assets/Foto login.png',
                          fit: BoxFit.contain,
                          semanticLabel:
                              'Logo Rastros con un perro y un gato',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingresa tu número de celular\npara continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: RastrosColors.navy,
                          fontSize: 17,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('phone-input'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: !_sendingCode,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9 +()-]'),
                          ),
                        ],
                        onFieldSubmitted: (_) => _continue(),
                        validator: (value) {
                          final digits =
                              value?.replaceAll(RegExp(r'\D'), '') ?? '';
                          if (digits.length < 7 || digits.length > 15) {
                            return 'Escribe un número válido (7 a 15 dígitos).';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Celular (Colombia +57)',
                          hintStyle: const TextStyle(
                            color: RastrosColors.muted,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.call_rounded,
                            color: RastrosColors.navy,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.66),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 17,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(
                              color: RastrosColors.line,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(
                              color: RastrosColors.line,
                              width: 1.4,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(
                              color: RastrosColors.blue,
                              width: 1.6,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      PrimaryButton(
                        key: const Key('send-code-button'),
                        label: _sendingCode
                            ? 'Enviando código...'
                            : 'Enviar código de seguridad',
                        color: RastrosColors.blue,
                        onPressed: _sendingCode ? () {} : _continue,
                      ),
                      if (!widget.enablePhoneAuth) ...[
                        const SizedBox(height: 17),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                          key: const Key('tester-mode-button'),
                          onPressed: _sendingCode ? () {} : _openTesterMode,
                          style: FilledButton.styleFrom(
                            backgroundColor: RastrosColors.yellow,
                            foregroundColor: RastrosColors.navy,
                            elevation: 1,
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: const Icon(Icons.pets_rounded, size: 19),
                          label: const Text('Continuar como modo tester'),
                          ),
                        ),
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: 9),
                        Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: RastrosColors.navy,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Al continuar, aceptas nuestra Política de\n'
                        'Privacidad y tratamiento de datos personales\n'
                        '(Ley 1581 de 2012).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: RastrosColors.navy,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.authService,
    this.profileService,
    this.enablePhoneAuth = false,
    this.testerMode = false,
  });

  final String phoneNumber;
  final String verificationId;
  final PhoneAuthService? authService;
  final UserProfileService? profileService;
  final bool enablePhoneAuth;
  final bool testerMode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _digitCount = 6;
  final _controllers = List.generate(
    _digitCount,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(_digitCount, (_) => FocusNode());
  String? _message;
  late String _verificationId = widget.verificationId;
  bool _verifying = false;
  bool _resending = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    if (widget.testerMode) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
        ),
        (_) => false,
      );
      return;
    }

    if (!widget.enablePhoneAuth) {
      setState(() => _message = 'El envío real de SMS está desactivado.');
      return;
    }

    final code = _controllers.map((controller) => controller.text).join();
    if (code.length != _digitCount) {
      setState(() => _message = 'Ingresa los 6 dígitos para continuar.');
      return;
    }
    setState(() {
      _verifying = true;
      _message = null;
    });
    try {
      final authService = widget.authService ?? FirebasePhoneAuthService();
      final profileService =
          widget.profileService ?? FirestoreUserProfileService();
      final user = await authService.verifyCode(
        verificationId: _verificationId,
        smsCode: code,
      );
      await profileService.ensureProfile(
        uid: user.uid,
        phoneNumber: user.phoneNumber,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _message = 'No se pudo verificar el código o guardar tu perfil: $error';
      });
    }
  }

  Future<void> _resendCode() async {
    if (!widget.enablePhoneAuth) {
      setState(() => _message = 'El reenvío de SMS está desactivado.');
      return;
    }

    setState(() {
      _resending = true;
      _message = null;
    });
    try {
      final authService = widget.authService ?? FirebasePhoneAuthService();
      await authService.sendCode(
        widget.phoneNumber,
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resending = false;
            _message = 'Te enviamos un código nuevo.';
          });
          for (final controller in _controllers) {
            controller.clear();
          }
          _focusNodes.first.requestFocus();
        },
        onAutoVerified: (user) async {
          if (!mounted) return;
          try {
            final profileService =
                widget.profileService ?? FirestoreUserProfileService();
            await profileService.ensureProfile(
              uid: user.uid,
              phoneNumber: user.phoneNumber,
            );
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => const HomeScreen(),
              ),
              (_) => false,
            );
          } catch (error) {
            if (!mounted) return;
            setState(() {
              _resending = false;
              _message = 'No se pudo guardar tu perfil en Firestore: $error';
            });
          }
        },
        onError: (message) {
          if (!mounted) return;
          setState(() {
            _resending = false;
            _message = message;
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _message = 'No se pudo reenviar el código: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              alignment: Alignment.topCenter,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 250),
                      child: Column(
                        children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Volver',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: RastrosColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const BrandLogo(size: 48),
                    const SizedBox(height: 19),
                    const Text(
                      'Ingresa el código de 6 dígitos\nenviado a tu celular',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: RastrosColors.navy,
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (widget.phoneNumber.isNotEmpty)
                    Text(
                      widget.phoneNumber,
                      style: const TextStyle(
                        color: RastrosColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: List.generate(
                        _digitCount,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == _digitCount - 1 ? 0 : 6,
                            ),
                            child: TextField(
                              key: Key('otp-digit-$index'),
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                setState(() => _message = null);
                                if (value.isNotEmpty &&
                                    index < _digitCount - 1) {
                                  _focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                              },
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.55),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(13),
                                  borderSide: const BorderSide(
                                    color: RastrosColors.line,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(13),
                                  borderSide: const BorderSide(
                                    color: RastrosColors.line,
                                    width: 1.3,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(13),
                                  borderSide: const BorderSide(
                                    color: RastrosColors.blue,
                                    width: 1.7,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 9),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: RastrosColors.navy,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    PrimaryButton(
                      key: const Key('verify-code-button'),
                      label: _verifying
                          ? 'Verificando...'
                          : widget.testerMode
                          ? 'Continuar'
                          : 'Verificar e ingresar',
                      color: RastrosColors.teal,
                      onPressed: _verifying ? () {} : _verify,
                    ),
                    if (!widget.testerMode) ...[
                      const SizedBox(height: 18),
                      const Text(
                        '¿No recibiste el código?',
                        style: TextStyle(
                          color: RastrosColors.navy,
                          fontSize: 12,
                        ),
                      ),
                      TextButton(
                        onPressed: _resending || _verifying
                            ? null
                            : _resendCode,
                        style: TextButton.styleFrom(
                          foregroundColor: RastrosColors.navy,
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        child: Text(
                          _resending ? 'Enviando...' : 'Reenviar código',
                        ),
                      ),
                    ],
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: constraints.maxHeight * 0.34,
                    child: Image.asset(
                      key: const Key('otp-cat-art'),
                      'Assets/Foto OTP.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      semanticLabel: 'Gatito de Rastros',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 9),
              child: Row(
                children: [
                  const BrandLogo(size: 30, centered: false),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Notificaciones',
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: RastrosColors.navy,
                    ),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: RastrosColors.lilac,
                    child: Icon(
                      Icons.person_rounded,
                      color: RastrosColors.navy,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(23, 13, 23, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedTab == 0
                          ? '¡Hola, qué alegría verte!'
                          : _tabTitle,
                      style: const TextStyle(
                        color: RastrosColors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _selectedTab == 0
                          ? 'Cada huella puede ayudar a reunir una familia.'
                          : 'Muy pronto encontrarás más novedades aquí.',
                      style: const TextStyle(
                        color: RastrosColors.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 19),
                    const ImagePlaceholder(
                      height: 290,
                      label: 'Espacio para el mapa y las mascotas',
                      icon: Icons.map_outlined,
                      prominent: true,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: RastrosColors.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE9B8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: RastrosColors.navy,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '¿Viste una mascota perdida?\n'
                              'Ayúdanos a compartir su rastro.',
                              style: TextStyle(
                                color: RastrosColors.navy,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: RastrosColors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _HomeNavigationBar(
        selectedIndex: _selectedTab,
        onSelected: (index) => setState(() => _selectedTab = index),
      ),
    );
  }

  String get _tabTitle => switch (_selectedTab) {
    1 => 'Mapa',
    2 => 'Reportar una mascota',
    3 => 'Seguimiento',
    4 => 'Tu perfil',
    _ => 'Explorar',
  };
}

class _HomeNavigationBar extends StatelessWidget {
  const _HomeNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.pets_rounded, 'Explorar'),
      (Icons.map_outlined, 'Mapa'),
      (Icons.add_rounded, 'Reportar'),
      (Icons.assignment_outlined, 'Seguimiento'),
      (Icons.person_outline_rounded, 'Perfil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: RastrosColors.cream,
        border: Border.all(color: RastrosColors.line),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: RastrosColors.navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 69,
          child: Row(
            children: List.generate(items.length, (index) {
              final isSelected = index == selectedIndex;
              final isReport = index == 2;
              final (icon, label) = items[index];
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: label,
                  child: InkWell(
                    onTap: () => onSelected(index),
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isReport)
                          Container(
                            width: 43,
                            height: 43,
                            decoration: const BoxDecoration(
                              color: RastrosColors.yellow,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 30, color: Colors.white),
                          )
                        else
                          Icon(
                            icon,
                            size: 22,
                            color: isSelected
                                ? RastrosColors.blue
                                : RastrosColors.navy,
                          ),
                        if (!isReport) ...[
                          const SizedBox(height: 3),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: RastrosColors.navy,
                              fontSize: 9.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _BottomWavesPainter(),
            child: const SizedBox.expand(),
          ),
        ),
        const Positioned(
          top: 42,
          left: 19,
          child: _PawDecoration(color: RastrosColors.blue, size: 38),
        ),
        const Positioned(
          top: 17,
          right: 27,
          child: _PawDecoration(color: RastrosColors.yellow, size: 31),
        ),
        const Positioned(
          bottom: 82,
          left: 24,
          child: _PawDecoration(color: RastrosColors.lilac, size: 40),
        ),
        child,
      ],
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 46, this.centered = true});

  final double size;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      child: Image.asset(
        key: const Key('brand-logo'),
        'Assets/logo.png',
        height: size,
        fit: BoxFit.contain,
        semanticLabel: 'Rastros',
      ),
    );
  }
}

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    required this.height,
    required this.label,
    required this.icon,
    this.prominent = false,
  });

  final double height;
  final String label;
  final IconData icon;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: prominent
            ? const Color(0xFFEAF3F3).withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(prominent ? 25 : 20),
        border: prominent
            ? Border.all(color: RastrosColors.line.withValues(alpha: 0.8))
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            bottom: 13,
            child: Icon(
              Icons.pets_rounded,
              size: 23,
              color: RastrosColors.lilac.withValues(alpha: 0.8),
            ),
          ),
          Positioned(
            right: 13,
            top: 12,
            child: Icon(
              Icons.pets_rounded,
              size: 18,
              color: RastrosColors.yellow.withValues(alpha: 0.85),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: prominent ? 42 : 36,
                color: RastrosColors.navy.withValues(alpha: 0.22),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: RastrosColors.navy.withValues(alpha: 0.42),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 49,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded, size: 19),
          ],
        ),
      ),
    );
  }
}

class _PawDecoration extends StatelessWidget {
  const _PawDecoration({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.pets_rounded,
      size: size,
      color: color.withValues(alpha: 0.3),
    );
  }
}

class _BottomWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final top = size.height - 102;
    final paths = [
      (
        RastrosColors.lilac.withValues(alpha: 0.82),
        Path()
          ..moveTo(0, top + 37)
          ..cubicTo(
            size.width * 0.18,
            top - 16,
            size.width * 0.34,
            top + 92,
            size.width * 0.57,
            top + 43,
          )
          ..cubicTo(
            size.width * 0.76,
            top + 2,
            size.width * 0.88,
            top + 17,
            size.width,
            top - 7,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close(),
      ),
      (
        RastrosColors.sky.withValues(alpha: 0.9),
        Path()
          ..moveTo(0, top + 84)
          ..cubicTo(
            size.width * 0.25,
            top + 31,
            size.width * 0.36,
            top + 107,
            size.width * 0.62,
            top + 54,
          )
          ..cubicTo(
            size.width * 0.78,
            top + 19,
            size.width * 0.88,
            top + 2,
            size.width,
            top + 18,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close(),
      ),
      (
        RastrosColors.yellow.withValues(alpha: 0.56),
        Path()
          ..moveTo(0, top + 105)
          ..cubicTo(
            size.width * 0.28,
            top + 56,
            size.width * 0.43,
            top + 114,
            size.width * 0.65,
            top + 81,
          )
          ..cubicTo(
            size.width * 0.81,
            top + 58,
            size.width * 0.91,
            top + 24,
            size.width,
            top + 45,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close(),
      ),
    ];

    for (final (color, path) in paths) {
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _BottomWavesPainter oldDelegate) => false;
}
