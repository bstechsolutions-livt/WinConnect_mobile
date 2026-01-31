import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Resultado da autorização de digitação manual
class AutorizacaoDigitacao {
  final bool autorizado;
  final int? matriculaAutorizador;
  final String? nomeAutorizador;

  const AutorizacaoDigitacao({
    required this.autorizado,
    this.matriculaAutorizador,
    this.nomeAutorizador,
  });

  /// Retorna uma autorização negada
  static const negada = AutorizacaoDigitacao(autorizado: false);

  /// Retorna uma autorização aprovada
  factory AutorizacaoDigitacao.aprovada({
    required int matricula,
    String? nome,
  }) {
    return AutorizacaoDigitacao(
      autorizado: true,
      matriculaAutorizador: matricula,
      nomeAutorizador: nome,
    );
  }
}

/// Dialog para solicitar autorização de supervisor para digitação manual.
///
/// Uso:
/// ```dart
/// final resultado = await AutorizarDigitacaoDialog.mostrar(
///   context: context,
///   apiService: ref.read(apiServiceProvider),
/// );
/// if (resultado.autorizado) {
///   // Liberar teclado para digitação
///   // resultado.matriculaAutorizador contém a matrícula de quem autorizou
/// }
/// ```
class AutorizarDigitacaoDialog extends StatefulWidget {
  final dynamic apiService;

  const AutorizarDigitacaoDialog({
    super.key,
    required this.apiService,
  });

  /// Mostra o dialog e retorna AutorizacaoDigitacao com dados do autorizador
  static Future<AutorizacaoDigitacao> mostrarComDados({
    required BuildContext context,
    required dynamic apiService,
  }) async {
    final resultado = await showDialog<AutorizacaoDigitacao>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AutorizarDigitacaoDialog(apiService: apiService),
    );
    return resultado ?? AutorizacaoDigitacao.negada;
  }

  /// Mostra o dialog e retorna true se autorizado, false caso contrário
  /// (mantido para compatibilidade)
  static Future<bool> mostrar({
    required BuildContext context,
    required dynamic apiService,
  }) async {
    final resultado = await mostrarComDados(
      context: context,
      apiService: apiService,
    );
    return resultado.autorizado;
  }

  @override
  State<AutorizarDigitacaoDialog> createState() =>
      _AutorizarDigitacaoDialogState();
}

class _AutorizarDigitacaoDialogState extends State<AutorizarDigitacaoDialog> {
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

  Future<void> _autorizar() async {
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
      final response = await widget.apiService.post('/wms/autorizar-digitacao', {
        'autorizador_matricula': int.tryParse(matricula) ?? matricula,
        'autorizador_senha': senha,
      });

      if (!mounted) return;

      // Extrai dados do autorizador da resposta
      final autorizador = response['autorizador'] as Map<String, dynamic>?;
      final matriculaAutorizador = autorizador?['matricula'] as int? ??
          int.tryParse(matricula);
      final nomeAutorizador = autorizador?['nome'] as String?;

      Navigator.pop(
        context,
        AutorizacaoDigitacao.aprovada(
          matricula: matriculaAutorizador!,
          nome: nomeAutorizador,
        ),
      );
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
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_alt_rounded,
                size: 40,
                color: Colors.orange.shade700,
              ),
            ),

            const SizedBox(height: 16),

            // Título
            const Text(
              'Autorização Necessária',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Descrição
            Text(
              'Para digitar o código manualmente, é necessária a autorização de um supervisor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            // Campo matrícula
            TextField(
              controller: _matriculaController,
              focusNode: _matriculaFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Matrícula do Supervisor',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _senhaFocus.requestFocus(),
            ),

            const SizedBox(height: 16),

            // Campo senha
            TextField(
              controller: _senhaController,
              focusNode: _senhaFocus,
              obscureText: _obscureSenha,
              decoration: InputDecoration(
                labelText: 'Senha do Supervisor',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSenha ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureSenha = !_obscureSenha);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _autorizar(),
            ),

            // Erro
            if (_erro != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _erro!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
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
                    child: const Text('CANCELAR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _autorizar,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
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
                        : const Text(
                            'AUTORIZAR',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
