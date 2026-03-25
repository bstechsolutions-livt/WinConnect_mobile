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

  late TextEditingController _scannerController;
  final FocusNode _scannerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _caixas = widget.caixasIniciais;
    _unidades = widget.unidadesIniciais;
    _scannerController = TextEditingController();

    // Esconde teclado virtual sempre que o campo do scanner ganhar foco
    // TextInputType.none não funciona em alguns coletores Zebra
    _scannerFocusNode.addListener(_esconderTecladoVirtual);

    // Foca no campo de scanner após build para permitir bipagem contínua
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scannerFocusNode.requestFocus();
    });
  }

  void _esconderTecladoVirtual() {
    if (_scannerFocusNode.hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }

  @override
  void dispose() {
    _scannerFocusNode.removeListener(_esconderTecladoVirtual);
    _scannerController.dispose();
    _scannerFocusNode.dispose();
    super.dispose();
  }

  void _updateCaixas(int value) {
    setState(() {
      _caixas = value < 0 ? 0 : value;
    });
  }

  void _updateUnidades(int value) {
    setState(() {
      _unidades = value < 0 ? 0 : value;
    });
  }

  // Getters para cálculos
  int get _totalDigitado => (_caixas * widget.multiplo) + _unidades;
  bool get _quantidadeCorreta => _totalDigitado == widget.qtSolicitada;
  bool get _podeConfirmar => _quantidadeCorreta;
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

    // Mantém foco no campo de scanner e esconde teclado
    _scannerFocusNode.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  /// Abre dialog para digitar valor manualmente
  void _editarValor(String titulo, int valorAtual, Function(int) onSave) {
    // Remove foco do scanner enquanto o dialog está aberto
    _scannerFocusNode.unfocus();

    final controller = TextEditingController(
      text: valorAtual > 0 ? '$valorAtual' : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Digitar $titulo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.none,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (value) {
            final v = int.tryParse(value) ?? 0;
            onSave(v);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text) ?? 0;
              onSave(v);
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      // Restaura foco no scanner após fechar o dialog
      _scannerFocusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }

  /// Abre calculadora simples em bottom sheet
  void _abrirCalculadora() {
    _scannerFocusNode.unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String display = '0';
        String operando1 = '';
        String operador = '';
        bool novoNumero = true;

        void _calcular(StateSetter setCalcState) {
          if (operando1.isEmpty || operador.isEmpty) return;
          final a = double.tryParse(operando1) ?? 0;
          final b = double.tryParse(display) ?? 0;
          double resultado = 0;

          switch (operador) {
            case '+':
              resultado = a + b;
            case '-':
              resultado = a - b;
            case '×':
              resultado = a * b;
            case '÷':
              resultado = b != 0 ? a / b : 0;
          }

          setCalcState(() {
            display = resultado == resultado.roundToDouble()
                ? resultado.toInt().toString()
                : resultado.toStringAsFixed(2);
            operando1 = '';
            operador = '';
            novoNumero = true;
          });
        }

        return StatefulBuilder(
          builder: (context, setCalcState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            Widget buildBtn(
              String text, {
              Color? color,
              Color? textColor,
              int flex = 1,
            }) {
              return Expanded(
                flex: flex,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Material(
                    color: color ??
                        (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if ('0123456789'.contains(text)) {
                          setCalcState(() {
                            if (novoNumero) {
                              display = text;
                              novoNumero = false;
                            } else {
                              display = display == '0' ? text : display + text;
                            }
                          });
                        } else if (text == 'C') {
                          setCalcState(() {
                            display = '0';
                            operando1 = '';
                            operador = '';
                            novoNumero = true;
                          });
                        } else if (text == '⌫') {
                          setCalcState(() {
                            if (display.length > 1) {
                              display =
                                  display.substring(0, display.length - 1);
                            } else {
                              display = '0';
                            }
                          });
                        } else if ('+-×÷'.contains(text)) {
                          if (operando1.isNotEmpty && !novoNumero) {
                            _calcular(setCalcState);
                          }
                          setCalcState(() {
                            operando1 = display;
                            operador = text;
                            novoNumero = true;
                          });
                        } else if (text == '=') {
                          _calcular(setCalcState);
                        }
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor ??
                                (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicador de arraste
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (operando1.isNotEmpty)
                              Text(
                                '$operando1 $operador',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey.shade400,
                                ),
                              ),
                            Text(
                              display,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Teclas
                      Row(
                        children: [
                          buildBtn('C', textColor: Colors.red),
                          buildBtn('⌫', textColor: Colors.orange),
                          buildBtn(
                            '÷',
                            color: Colors.blue,
                            textColor: Colors.white,
                          ),
                          buildBtn(
                            '×',
                            color: Colors.blue,
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          buildBtn('7'),
                          buildBtn('8'),
                          buildBtn('9'),
                          buildBtn(
                            '-',
                            color: Colors.blue,
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          buildBtn('4'),
                          buildBtn('5'),
                          buildBtn('6'),
                          buildBtn(
                            '+',
                            color: Colors.blue,
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          buildBtn('1'),
                          buildBtn('2'),
                          buildBtn('3'),
                          buildBtn(
                            '=',
                            color: Colors.green,
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          buildBtn('0', flex: 2),
                          const Spacer(),
                          const Spacer(),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Botões de aplicar
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                final val =
                                    int.tryParse(display) ??
                                    double.tryParse(display)?.toInt() ??
                                    0;
                                _updateCaixas(val);
                                Navigator.pop(ctx);
                              },
                              icon: const Icon(Icons.archive, size: 16),
                              label: const Text('CX'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                final val =
                                    int.tryParse(display) ??
                                    double.tryParse(display)?.toInt() ??
                                    0;
                                _updateUnidades(val);
                                Navigator.pop(ctx);
                              },
                              icon: const Icon(Icons.inventory_2, size: 16),
                              label: const Text('UN'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _scannerFocusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }

  void _mostrarFeedback(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        toolbarHeight: 36,
        title: Text('OS ${widget.numos}', style: const TextStyle(fontSize: 13)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 18),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, size: 18),
            tooltip: 'Calculadora',
            onPressed: () => _abrirCalculadora(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
        ],
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
                  showCursor: false,
                  keyboardType: TextInputType.none,
                  enableInteractiveSelection: false,
                  onSubmitted: (value) => _processarBipagem(value.trim()),
                ),
              ),
            ),
            // Conteúdo principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Column(
                children: [
                  // Indicador de scanner ativo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, color: Colors.green.shade700, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          'Continue bipando para adicionar ${widget.tipoBipado == 'caixa' ? 'CAIXAS' : 'UNIDADES'}',
                          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                  // CARD: PEGUE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.blue[600]!, Colors.blue[800]!]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Text('PEGUE', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 7, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(color: Colors.green[600], borderRadius: BorderRadius.circular(3)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('$_caixasEsperadas', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                    const Text(' CX', style: TextStyle(color: Colors.white70, fontSize: 8)),
                                    if (_temCaixaQuebrada) ...[
                                      const SizedBox(width: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2)),
                                        child: Text('+$_unidadesEsperadas', style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 3),
                              child: Text('ou', style: TextStyle(color: Colors.white60, fontSize: 7)),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(color: Colors.blue[400], borderRadius: BorderRadius.circular(3)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${widget.qtSolicitada}', style: const TextStyle(color: Colors.white, fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                                    const Text(' UN', style: TextStyle(color: Colors.white70, fontSize: 8)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('1 CX = ${widget.multiplo} UN', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 7)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // CARD: CONFERÊNCIA
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Text('QUANTIDADE QUE PEGOU', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 7, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          _buildCompactInput(
                            label: 'CAIXAS',
                            value: _caixas,
                            color: Colors.green,
                            onIncrement: () => _updateCaixas(_caixas + 1),
                            onDecrement: () => _updateCaixas(_caixas - 1),
                            onEdit: () => _editarValor('Caixas', _caixas, (v) => _updateCaixas(v)),
                          ),
                          const SizedBox(height: 2),
                          _buildCompactInput(
                            label: 'UNIDADES',
                            value: _unidades,
                            color: Colors.blue,
                            onIncrement: () => _updateUnidades(_unidades + 1),
                            onDecrement: () => _updateUnidades(_unidades - 1),
                            onEdit: () => _editarValor('Unidades', _unidades, (v) => _updateUnidades(v)),
                          ),
                          const Spacer(),
                          // Total
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                            decoration: BoxDecoration(
                              color: _quantidadeCorreta ? Colors.green[50] : _temDiferenca ? Colors.red[50] : Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: _quantidadeCorreta ? Colors.green : _temDiferenca ? Colors.red : Colors.grey, width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_quantidadeCorreta) Icon(Icons.check_circle, color: Colors.green[700], size: 12),
                                if (_temDiferenca) Icon(Icons.error, color: Colors.red[700], size: 12),
                                const SizedBox(width: 3),
                                Text('TOTAL: $_totalDigitado UN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _quantidadeCorreta ? Colors.green[700] : _temDiferenca ? Colors.red[700] : null)),
                                if (_temDiferenca) Text('  (${_diferenca > 0 ? '+' : ''}$_diferenca)', style: TextStyle(color: Colors.red[700], fontSize: 9, fontWeight: FontWeight.bold)),
                                if (_quantidadeCorreta) Text('  \u2713', style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Botão Confirmar
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: FilledButton(
                      onPressed: _podeConfirmar ? _confirmar : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey[400],
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_podeConfirmar ? Icons.check_circle : Icons.block, size: 12),
                          const SizedBox(width: 3),
                          const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
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

  /// Input compacto: [-] valor [+]
  Widget _buildCompactInput({
    required String label,
    required int value,
    required Color color,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
          ),
          InkWell(
            onTap: onDecrement,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              child: const Icon(Icons.remove, color: Colors.white, size: 14),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text('$value', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
              ),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              child: const Icon(Icons.add, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
