import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog para solicitar autorização de supervisor para liberar operador da rua.
///
/// Uso:
/// ```dart
/// final liberado = await LiberarRuaDialog.mostrar(
///   context: context,
///   apiService: ref.read(apiServiceProvider),
///   rua: 'A',
///   matriculaOperador: user.matricula,
/// );
/// if (liberado) {
///   // Operador liberado, voltar para seleção de ruas
/// }
/// ```
class LiberarRuaDialog extends StatefulWidget {
  final dynamic apiService;
  final String rua;
  final int? matriculaOperador;

  const LiberarRuaDialog({
    super.key,
    required this.apiService,
    required this.rua,
    this.matriculaOperador,
  });

  /// Mostra o dialog e retorna true se liberado, false caso contrário
  static Future<bool> mostrar({
    required BuildContext context,
    required dynamic apiService,
    required String rua,
    int? matriculaOperador,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LiberarRuaDialog(
        apiService: apiService,
        rua: rua,
        matriculaOperador: matriculaOperador,
      ),
    );
    return resultado ?? false;
  }

  @override
  State<LiberarRuaDialog> createState() => _LiberarRuaDialogState();
}

class _LiberarRuaDialogState extends State<LiberarRuaDialog> {
  final _matriculaController = TextEditingController();
  final _senhaController = TextEditingController();
  final _matriculaFocus = FocusNode();
  final _senhaFocus = FocusNode();

  bool _isLoading = false;
  String? _erro;
  bool _obscureSenha = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _matriculaFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _senhaController.dispose();
    _matriculaFocus.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  Future<void> _liberarRua() async {
    final matricula = _matriculaController.text.trim();
    final senha = _senhaController.text;

    if (matricula.isEmpty) {
      setState(() => _erro = 'Informe a matrícula do supervisor');
      return;
    }

    if (senha.isEmpty) {
      setState(() => _erro = 'Informe a senha do supervisor');
      return;
    }

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final body = <String, dynamic>{
        'autorizador_matricula': int.tryParse(matricula) ?? matricula,
        'autorizador_senha': senha,
      };
      
      // Adiciona matrícula do operador se disponível
      if (widget.matriculaOperador != null) {
        body['matricula'] = widget.matriculaOperador;
      }
      
      await widget.apiService.post('/wms/fase1/liberar-rua', body);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.exit_to_app_rounded,
                size: 40,
                color: Colors.red.shade700,
              ),
            ),

            const SizedBox(height: 16),

            // Título
            const Text(
              'Sair da Rua',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Descrição
            Text(
              'Para sair da Rua ${widget.rua} é necessária a autorização de um supervisor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            // Campo Matrícula
            TextField(
              controller: _matriculaController,
              focusNode: _matriculaFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _senhaFocus.requestFocus(),
              decoration: InputDecoration(
                labelText: 'Matrícula do Supervisor',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
              ),
            ),

            const SizedBox(height: 16),

            // Campo Senha
            TextField(
              controller: _senhaController,
              focusNode: _senhaFocus,
              obscureText: _obscureSenha,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _liberarRua(),
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSenha
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscureSenha = !_obscureSenha);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
              ),
            ),

            // Erro
            if (_erro != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _erro!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _liberarRua,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Liberar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
