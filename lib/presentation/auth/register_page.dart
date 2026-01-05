import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_helper.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _nombreRefugioController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRol = 'adoptante';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreController.dispose();
    _nombreRefugioController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
  if (!_formKey.currentState!.validate()) return;

  if (_passwordController.text != _confirmPasswordController.text) {
    SnackbarHelper.showError(context, 'Las contraseñas no coinciden');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final client = SupabaseConfig.client;

    debugPrint('📝 Iniciando registro...');

    // 1. Registrar usuario en Supabase Auth
    final authResponse = await client.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      data: {
        'rol': _selectedRol,
        'nombre_completo': _nombreController.text.trim(),
      },
    );

    if (authResponse.user == null) {
      throw Exception('Error al crear usuario');
    }

    final userId = authResponse.user!.id;
    debugPrint('✅ Usuario creado: $userId');

    // 2. ESPERAR a que el trigger cree el perfil
    // En lugar de crear manualmente, solo esperamos
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('⏳ Esperando a que el trigger cree el perfil...');

    // 3. Verificar que el perfil fue creado por el trigger
    for (int i = 0; i < 5; i++) {
      try {
        final perfil = await client
            .from('perfiles')
            .select('id')
            .eq('id', userId)
            .maybeSingle();
        
        if (perfil != null) {
          debugPrint('✅ Perfil creado por el trigger');
          break;
        }
      } catch (e) {
        debugPrint('⏳ Esperando trigger... intento ${i + 1}/5');
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 4. Si es refugio, crear registro de refugio
    if (_selectedRol == 'refugio') {
      debugPrint('🏠 Creando refugio...');
      
      // IMPORTANTE: NO cerrar sesión todavía
      // Esperar un poco más para asegurar que la sesión está activa
      await Future.delayed(const Duration(seconds: 1));
      
      try {
        // Verificar que la sesión siga activa
        final session = client.auth.currentSession;
        debugPrint('🔑 Sesión activa: ${session != null}');
        debugPrint('🔑 User ID actual: ${client.auth.currentUser?.id}');
        
        await client.from('refugios').insert({
          'perfil_id': userId,
          'nombre_refugio': _nombreRefugioController.text.trim(),
        });
        debugPrint('✅ Refugio creado');
      } catch (e) {
        debugPrint('❌ Error creando refugio: $e');
        debugPrint('❌ Detalles: ${e.toString()}');
        throw Exception('No se pudo crear el refugio');
      }
    }

    if (!mounted) return;

    // 5. Cerrar sesión para forzar verificación de email
    await client.auth.signOut();
    debugPrint('✅ Registro completado exitosamente');

    if (!mounted) return;

    // 6. Mostrar mensaje de éxito
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('¡Registro exitoso!')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Te hemos enviado un correo de verificación.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 12),
            Text(
              '📧 Por favor revisa tu bandeja de entrada y haz clic en el enlace para activar tu cuenta.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 12),
            Text(
              '💡 Tip: Si no lo ves, revisa tu carpeta de spam.',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  } catch (e) {
    debugPrint('❌ Error en registro: $e');
    
    if (mounted) {
      String errorMsg = 'Error al registrarse';
      
      if (e.toString().contains('already registered')) {
        errorMsg = 'Este email ya está registrado';
      } else if (e.toString().contains('Invalid email')) {
        errorMsg = 'Email inválido';
      } else if (e.toString().contains('Password')) {
        errorMsg = 'La contraseña debe tener al menos 6 caracteres';
      }
      
      SnackbarHelper.showError(context, errorMsg);
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'adoptante',
                      label: Text('Adoptante'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: 'refugio',
                      label: Text('Refugio'),
                      icon: Icon(Icons.business),
                    ),
                  ],
                  selected: {_selectedRol},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedRol = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                      Validators.validateRequired(value, 'Nombre completo'),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                if (_selectedRol == 'refugio') ...[
                  TextFormField(
                    controller: _nombreRefugioController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Refugio',
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => Validators.validateRequired(
                        value, 'Nombre del refugio'),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: Validators.validateEmail,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: Validators.validatePassword,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: Validators.validatePassword,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes cuenta? '),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: const Text(
                        'Inicia Sesión',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}