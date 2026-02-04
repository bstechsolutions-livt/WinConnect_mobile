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

    // Esconde teclado virtual ao focar (para usar apenas scanner/teclado físico)
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  // Indicador de scanner ativo - compacto
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 6,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: Colors.green.shade700,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bipando ${widget.tipoBipado == 'caixa' ? 'CX' : 'UN'}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // CARD: O QUE PRECISA PEGAR - super compacto
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[800]!],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        // CAIXAS
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$_caixasEsperadas',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  ' CX',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                                if (_temCaixaQuebrada) ...[
                                  const SizedBox(width: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      '+$_unidadesEsperadas',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'ou',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        // UNIDADES
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${widget.qtSolicitada}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  ' UN',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Múltiplo
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '1CX=${widget.multiplo}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // CARD: CONFERÊNCIA - compacto
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'QTD PEGOU',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Input CAIXAS
                          _buildCompactInput(
                            label: 'CX',
                            value: _caixas,
                            color: Colors.green,
                            onIncrement: () => _updateCaixas(_caixas + 1),
                            onDecrement: () => _updateCaixas(_caixas - 1),
                          ),
                          const SizedBox(height: 3),
                          // Input UNIDADES
                          _buildCompactInput(
                            label: 'UN',
                            value: _unidades,
                            color: Colors.blue,
                            onIncrement: () => _updateUnidades(_unidades + 1),
                            onDecrement: () => _updateUnidades(_unidades - 1),
                          ),

                          const Spacer(),

                          // Total
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _quantidadeCorreta
                                  ? Colors.green[50]
                                  : _temDiferenca
                                  ? Colors.red[50]
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _quantidadeCorreta
                                    ? Colors.green
                                    : _temDiferenca
                                    ? Colors.red
                                    : Colors.grey,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_quantidadeCorreta)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                    size: 14,
                                  ),
                                if (_temDiferenca)
                                  Icon(
                                    Icons.error,
                                    color: Colors.red[700],
                                    size: 14,
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  'TOTAL: $_totalDigitado UN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _quantidadeCorreta
                                        ? Colors.green[700]
                                        : _temDiferenca
                                        ? Colors.red[700]
                                        : null,
                                  ),
                                ),
                                if (_temDiferenca)
                                  Text(
                                    '  (${_diferenca > 0 ? '+' : ''}$_diferenca)',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_quantidadeCorreta)
                                  Text(
                                    '  ✓',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Botão Confirmar
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: FilledButton(
                      onPressed: _quantidadeCorreta ? _confirmar : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _quantidadeCorreta
                                ? Icons.check_circle
                                : Icons.block,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'CONFIRMAR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
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

  /// Input compacto: [-] valor [+]
  Widget _buildCompactInput({
    required String label,
    required int value,
    required Color color,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          InkWell(
            onTap: onDecrement,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.remove, color: Colors.white, size: 18),
            ),
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
