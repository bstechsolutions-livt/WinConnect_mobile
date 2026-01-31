import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Resultado da conferência de quantidade
class ConferenciaQuantidadeResult {
  final int caixas;
  final int unidades;
  final int totalUnidades;
  final bool confirmado;

  ConferenciaQuantidadeResult({
    required this.caixas,
    required this.unidades,
    required this.multiplo,
    this.confirmado = true,
  }) : totalUnidades = (caixas * multiplo) + unidades;

  final int multiplo;
}

/// Tela de Conferência de Quantidade
class OsConferenciaQuantidadeScreen extends StatefulWidget {
  final int numos;
  final int codprod;
  final String descricao;
  final int multiplo;
  final int qtSolicitada;
  final int caixasIniciais;
  final int unidadesIniciais;
  final String? tipoBipado; // 'caixa' ou 'unidade' - tipo do código bipado

  const OsConferenciaQuantidadeScreen({
    super.key,
    required this.numos,
    required this.codprod,
    required this.descricao,
    required this.multiplo,
    required this.qtSolicitada,
    this.caixasIniciais = 0,
    this.unidadesIniciais = 0,
    this.tipoBipado,
  });

  @override
  State<OsConferenciaQuantidadeScreen> createState() =>
      _OsConferenciaQuantidadeScreenState();
}

class _OsConferenciaQuantidadeScreenState
    extends State<OsConferenciaQuantidadeScreen> {
  late int _caixas;
  late int _unidades;

  late TextEditingController _caixasController;
  late TextEditingController _unidadesController;
  late TextEditingController _scannerController;
  final FocusNode _caixasFocusNode = FocusNode();
  final FocusNode _unidadesFocusNode = FocusNode();
  final FocusNode _scannerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _caixas = widget.caixasIniciais;
    _unidades = widget.unidadesIniciais;
    _caixasController = TextEditingController(text: '$_caixas');
    _unidadesController = TextEditingController(text: '$_unidades');
    _scannerController = TextEditingController();

    // Esconde teclado virtual ao focar (para scanner físico)
    _caixasFocusNode.addListener(() {
      if (_caixasFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });
    _unidadesFocusNode.addListener(() {
      if (_unidadesFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });
    _scannerFocusNode.addListener(() {
      if (_scannerFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    // Foca no campo de scanner após build para permitir bipagem contínua
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scannerFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _caixasController.dispose();
    _unidadesController.dispose();
    _scannerController.dispose();
    _caixasFocusNode.dispose();
    _unidadesFocusNode.dispose();
    _scannerFocusNode.dispose();
    super.dispose();
  }

  void _updateCaixas(int value) {
    setState(() {
      _caixas = value < 0 ? 0 : value;
      _caixasController.text = '$_caixas';
    });
  }

  void _updateUnidades(int value) {
    setState(() {
      _unidades = value < 0 ? 0 : value;
      _unidadesController.text = '$_unidades';
    });
  }

  // Getters para cálculos
  int get _totalDigitado => (_caixas * widget.multiplo) + _unidades;
  bool get _quantidadeCorreta => _totalDigitado == widget.qtSolicitada;
  bool get _temDiferenca => _totalDigitado != 0 && !_quantidadeCorreta;
  int get _diferenca => _totalDigitado - widget.qtSolicitada;

  // Cálculo do esperado
  int get _caixasEsperadas => widget.qtSolicitada ~/ widget.multiplo;
  int get _unidadesEsperadas => widget.qtSolicitada % widget.multiplo;
  bool get _temCaixaQuebrada => _unidadesEsperadas > 0;

  /// Processa código de barras bipado na tela de quantidade
  /// Incrementa CX se bipou código de caixa, ou UN se bipou código de unidade
  void _processarBipagem(String codigo) {
    if (codigo.isEmpty) return;

    // Limpa o campo para próxima bipagem
    _scannerController.clear();

    // TODO: Validar se o código é o mesmo do produto
    // Por enquanto, incrementa conforme o tipo inicial que foi bipado
    if (widget.tipoBipado == 'caixa') {
      _updateCaixas(_caixas + 1);
      _mostrarFeedback('+ 1 CX', Colors.green);
    } else {
      _updateUnidades(_unidades + 1);
      _mostrarFeedback('+ 1 UN', Colors.blue);
    }

    // Mantém foco no campo de scanner
    _scannerFocusNode.requestFocus();
  }

  void _mostrarFeedback(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: cor,
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _confirmar() {
    if (_totalDigitado == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a quantidade'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      ConferenciaQuantidadeResult(
        caixas: _caixas,
        unidades: _unidades,
        multiplo: widget.multiplo,
        confirmado: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OS ${widget.numos}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Campo invisível para capturar bipagens do scanner físico
            Positioned(
              left: -1000,
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextField(
                  controller: _scannerController,
                  focusNode: _scannerFocusNode,
                  autofocus: true,
                  onSubmitted: (value) => _processarBipagem(value),
                  onChanged: (value) {
                    // Se terminou com Enter (scanner físico geralmente envia Enter)
                    if (value.endsWith('\n') || value.endsWith('\r')) {
                      _processarBipagem(value.trim());
                    }
                  },
                ),
              ),
            ),
            // Conteúdo principal
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  // Indicador de scanner ativo
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade400),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Continue bipando para adicionar ${widget.tipoBipado == 'caixa' ? 'CAIXAS' : 'UNIDADES'}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ========================================
                  // CARD: O QUE PRECISA PEGAR
                  // ========================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[800]!],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'PEGUE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),

                    // Opções de como pegar
                    Row(
                      children: [
                        // Opção CAIXAS
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$_caixasEsperadas',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Text(
                                      'CX',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_temCaixaQuebrada) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '+ $_unidadesEsperadas UN',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // OU
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'OU',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Opção UNIDADES
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${widget.qtSolicitada}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Text(
                                  'UN',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Info do múltiplo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '1 CX = ${widget.multiplo} UN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ========================================
              // CARD: CONFERÊNCIA
              // ========================================
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'QUANTIDADE QUE PEGOU',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Input CAIXAS - HORIZONTAL
                      _buildHorizontalInput(
                        label: 'CAIXAS',
                        value: _caixas,
                        controller: _caixasController,
                        focusNode: _caixasFocusNode,
                        color: Colors.green,
                        onIncrement: () => _updateCaixas(_caixas + 1),
                        onDecrement: () => _updateCaixas(_caixas - 1),
                        onChanged: (val) =>
                            _updateCaixas(int.tryParse(val) ?? 0),
                      ),

                      const SizedBox(height: 6),

                      // Input UNIDADES - HORIZONTAL
                      _buildHorizontalInput(
                        label: 'UNIDADES',
                        value: _unidades,
                        controller: _unidadesController,
                        focusNode: _unidadesFocusNode,
                        color: Colors.blue,
                        onIncrement: () => _updateUnidades(_unidades + 1),
                        onDecrement: () => _updateUnidades(_unidades - 1),
                        onChanged: (val) =>
                            _updateUnidades(int.tryParse(val) ?? 0),
                      ),

                      const Spacer(),

                      // Total digitado
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _quantidadeCorreta
                              ? Colors.green[50]
                              : _temDiferenca
                              ? Colors.red[50]
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _quantidadeCorreta
                                ? Colors.green
                                : _temDiferenca
                                ? Colors.red
                                : Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_quantidadeCorreta)
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[700],
                                size: 18,
                              ),
                            if (_temDiferenca)
                              Icon(
                                Icons.error,
                                color: Colors.red[700],
                                size: 18,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              'TOTAL: $_totalDigitado UN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _quantidadeCorreta
                                    ? Colors.green[700]
                                    : _temDiferenca
                                    ? Colors.red[700]
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (_temDiferenca) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _diferenca > 0
                                      ? '+$_diferenca'
                                      : '$_diferenca',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (_quantidadeCorreta) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '✓ OK',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Botão Confirmar
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: _quantidadeCorreta ? _confirmar : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _quantidadeCorreta ? Icons.check_circle : Icons.block,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'CONFIRMAR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }

  /// Input horizontal: [-] valor [+]
  Widget _buildHorizontalInput({
    required String label,
    required int value,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Color color,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          // Label
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),

          // Botão -
          InkWell(
            onTap: onDecrement,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.remove, color: Colors.white, size: 22),
            ),
          ),

          // Valor (clicável, aceita teclado físico, sem teclado virtual)
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  focusNode.requestFocus();
                },
                child: Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: focusNode.hasFocus ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: KeyboardListener(
                    focusNode: focusNode,
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent) {
                        final key = event.logicalKey;
                        // Números 0-9
                        if (key.keyId >= 0x30 && key.keyId <= 0x39) {
                          final digit = key.keyId - 0x30;
                          final newValue = controller.text + digit.toString();
                          controller.text = newValue;
                          onChanged(newValue);
                        }
                        // Numpad 0-9
                        else if (key.keyId >= 0x100000030 &&
                            key.keyId <= 0x100000039) {
                          final digit = key.keyId - 0x100000030;
                          final newValue = controller.text + digit.toString();
                          controller.text = newValue;
                          onChanged(newValue);
                        }
                        // Backspace
                        else if (key == LogicalKeyboardKey.backspace) {
                          if (controller.text.isNotEmpty) {
                            final newValue = controller.text.substring(
                              0,
                              controller.text.length - 1,
                            );
                            controller.text = newValue;
                            onChanged(newValue.isEmpty ? '0' : newValue);
                          }
                        }
                        // Enter - confirmar
                        else if (key == LogicalKeyboardKey.enter) {
                          FocusScope.of(context).nextFocus();
                        }
                      }
                    },
                    child: Text(
                      controller.text.isEmpty ? '0' : controller.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Botão +
          InkWell(
            onTap: onIncrement,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
