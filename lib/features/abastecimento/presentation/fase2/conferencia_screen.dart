import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../shared/providers/api_service_provider.dart';

/// Tela de conferência cega (Fase 2)
/// Bipa produto + digita quantidade
class ConferenciaScreen extends ConsumerStatefulWidget {
  final int numos;
  final int codprod;
  final String descricao;
  final String codauxiliar;
  final double quantidade;
  final String unidade;

  const ConferenciaScreen({
    super.key,
    required this.numos,
    required this.codprod,
    required this.descricao,
    required this.codauxiliar,
    required this.quantidade,
    required this.unidade,
  });

  @override
  ConsumerState<ConferenciaScreen> createState() => _ConferenciaScreenState();
}

class _ConferenciaScreenState extends ConsumerState<ConferenciaScreen> {
  final _eanController = TextEditingController();
  final _qtdController = TextEditingController();
  final _qtdFocusNode = FocusNode();
  
  bool _produtoBipado = false;
  bool _isProcessing = false;
  int _tentativas = 0;

  @override
  void dispose() {
    _eanController.dispose();
    _qtdController.dispose();
    _qtdFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conferência Cega'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info do produto
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Produto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.descricao,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip('Cód: ${widget.codprod}'),
                          const SizedBox(width: 8),
                          _buildInfoChip('OS: ${widget.numos}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Etapa 1: Bipar produto
              if (!_produtoBipado) ...[
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_scanner, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'ETAPA 1: BIPAR PRODUTO',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _eanController,
                          decoration: InputDecoration(
                            labelText: 'Código de barras (EAN)',
                            hintText: 'Escaneie o produto',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: _biparProduto,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onSubmitted: (_) => _biparProduto(),
                          autofocus: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Produto bipado com sucesso
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'PRODUTO BIPADO ✓',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Etapa 2: Digitar quantidade
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.calculate, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'ETAPA 2: DIGITAR QUANTIDADE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Conferência cega - digite a quantidade que você contou',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_tentativas > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Tentativa ${_tentativas + 1}/3',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _qtdController,
                          focusNode: _qtdFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Quantidade (${widget.unidade})',
                            hintText: 'Digite a quantidade contada',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          onSubmitted: (_) => _conferirQuantidade(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _isProcessing ? null : _conferirQuantidade,
                            style: FilledButton.styleFrom(backgroundColor: Colors.green),
                            child: _isProcessing
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('CONFIRMAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Aviso sobre conferência cega
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Conferência cega: você tem 3 tentativas para acertar a quantidade.',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Future<void> _biparProduto() async {
    final ean = _eanController.text.trim();
    if (ean.isEmpty) {
      _mostrarErro('Escaneie ou digite o código do produto');
      return;
    }

    // Valida localmente primeiro
    if (ean != widget.codauxiliar) {
      _mostrarErro('Código de barras incorreto!');
      return;
    }

    setState(() {
      _produtoBipado = true;
    });
    
    _mostrarSucesso('Produto bipado com sucesso!');
    
    // Foca no campo de quantidade
    _qtdFocusNode.requestFocus();
  }

  Future<void> _conferirQuantidade() async {
    final qtdStr = _qtdController.text.trim();
    if (qtdStr.isEmpty) {
      _mostrarErro('Digite a quantidade');
      return;
    }

    final qtd = double.tryParse(qtdStr);
    if (qtd == null || qtd <= 0) {
      _mostrarErro('Quantidade inválida');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/abastecimento/fase2/os/${widget.numos}/conferir', {
        'codigo_barras': widget.codauxiliar,
        'quantidade': qtd,
      });

      if (!mounted) return;
      
      _mostrarSucesso('Conferência realizada!');
      Navigator.of(context).pop(true);
      
    } catch (e) {
      setState(() => _isProcessing = false);
      
      final errorStr = e.toString();
      
      // Verifica se foi bloqueada
      if (errorStr.contains('bloqueada') || errorStr.contains('BLOQUEADA')) {
        _mostrarErro('OS bloqueada após 3 tentativas incorretas!');
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      
      // Extrai número de tentativas
      final tentativasMatch = RegExp(r'"tentativas"\s*:\s*(\d+)').firstMatch(errorStr);
      if (tentativasMatch != null) {
        setState(() {
          _tentativas = int.parse(tentativasMatch.group(1)!);
        });
      }
      
      _mostrarErro('Quantidade incorreta! Tente novamente.');
      _qtdController.clear();
      _qtdFocusNode.requestFocus();
    }
  }

  void _mostrarSucesso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}
