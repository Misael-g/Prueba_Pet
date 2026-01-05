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

      // 1. Registrar usuario en Supabase Auth con metadata
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

      // 2. Esperar a que el trigger cree el perfil
      debugPrint('⏳ Esperando a que el trigger cree el perfil...');
      await Future.delayed(const Duration(seconds: 3));

      // 3. Verificar que el perfil existe (con reintentos)
      bool perfilCreado = false;
      for (int intento = 1; intento <= 5; intento++) {
        try {
          final perfil = await client
              .from('perfiles')
              .select('id, rol')
              .eq('id', userId)
              .single();
          
          if (perfil != null) {
            debugPrint('✅ Perfil encontrado: rol=${perfil['rol']}');
            perfilCreado = true;
            break;
          }
        } catch (e) {
          debugPrint('⏳ Intento $intento/5: Perfil no disponible aún...');
          if (intento < 5) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      if (!perfilCreado) {
        throw Exception('El perfil no se creó. Contacta al administrador.');
      }

      // 4. Si es refugio, crear el registro de refugio
      if (_selectedRol == 'refugio') {
        debugPrint('🏠 Creando refugio...');
        
        // Pequeña espera adicional
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          await client.from('refugios').insert({
            'perfil_id': userId,
            'nombre_refugio': _nombreRefugioController.text.trim(),
          });
          
          debugPrint('✅ Refugio creado exitosamente');
        } catch (e) {
          debugPrint('❌ Error creando refugio: $e');
          throw Exception('No se pudo crear el refugio: ${e.toString()}');
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Te hemos enviado un correo de verificación.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              const Text(
                '📧 Por favor revisa tu bandeja de entrada y haz clic en el enlace para activar tu cuenta.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                '💡 Tip: Si no lo ves, revisa tu carpeta de spam.',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
              if (_selectedRol == 'refugio') ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  '🏠 Tu refugio ha sido creado exitosamente.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
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
        
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('already registered') || 
            errorStr.contains('already exists') ||
            errorStr.contains('duplicate')) {
          errorMsg = 'Este email ya está registrado';
        } else if (errorStr.contains('invalid email')) {
          errorMsg = 'Email inválido';
        } else if (errorStr.contains('password')) {
          errorMsg = 'La contraseña debe tener al menos 6 caracteres';
        } else if (errorStr.contains('refugio')) {
          errorMsg = 'Error al crear el refugio: ${e.toString()}';
        } else if (errorStr.contains('perfil')) {
          errorMsg = 'Error al verificar el perfil: ${e.toString()}';
        } else {
          errorMsg = 'Error: ${e.toString()}';
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