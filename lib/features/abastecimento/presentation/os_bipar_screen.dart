import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/os_detalhe_provider.dart';
import '../../../shared/models/os_detalhe_model.dart';

/// 6ª TELA - Detalhes da OS após chegar no endereço
class OsBiparScreen extends ConsumerStatefulWidget {
  final int fase;
  final int numos;
  final String faseNome;

  const OsBiparScreen({
    super.key,
    required this.fase,
    required this.numos,
    required this.faseNome,
  });

  @override
  ConsumerState<OsBiparScreen> createState() => _OsBiparScreenState();
}

class _OsBiparScreenState extends ConsumerState<OsBiparScreen> {
  final TextEditingController _eanController = TextEditingController();
  final TextEditingController _unitizadorController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _eanController.dispose();
    _unitizadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final osAsync = ref.watch(osDetalheNotifierProvider(widget.fase, widget.numos));

    return Scaffold(
      appBar: AppBar(
        title: Text('OS ${widget.numos}'),
        centerTitle: true,
      ),
      body: osAsync.when(
        data: (os) => _buildContent(context, os),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier).refresh(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, OsDetalhe os) {
    final qtCaixas = os.multiplo > 0 ? (os.qtSolicitada / os.multiplo).ceil() : 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Botões de ação
            Row(
              children: [
                _buildActionButton(context, 'BLOQUEAR', Colors.red, () => _mostrarDialogBloquear(context)),
                const SizedBox(width: 8),
                _buildActionButton(context, 'DIVERGÊNCIA', Colors.orange, () => _mostrarDialogDivergencia(context)),
                const SizedBox(width: 8),
                _buildActionButton(context, 'ESTOQUES', Colors.blue, () => _mostrarDialogEstoques(context, os.codprod)),
              ],
            ),

            const SizedBox(height: 12),

            // OS e Endereço Origem
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('OS: ${os.numos}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('Est. Atual: ${os.qtEstoqueAtual.toStringAsFixed(0)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMiniEndereco(context, os.enderecoOrigem.predio),
                      const SizedBox(width: 4),
                      _buildMiniEndereco(context, os.enderecoOrigem.nivel),
                      const SizedBox(width: 4),
                      _buildMiniEndereco(context, os.enderecoOrigem.apto),
                      const Spacer(),
                      Text('CX ${os.multiplo}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Código e Descrição
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cód: ${os.codprod}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    os.descricao,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Quantidades
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: os.produtoBipado ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('QTD ABASTECER', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
                        Text(
                          os.qtSolicitada.toStringAsFixed(0),
                          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        const Text('UN', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('QTD ABASTECER', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
                        Text(
                          qtCaixas.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        const Text('CX', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Campo de bipagem ou status
            if (!os.produtoBipado) ...[
              TextField(
                controller: _eanController,
                decoration: InputDecoration(
                  labelText: 'Bipar código do produto (EAN)',
                  hintText: 'Escaneie ou digite o código',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => _biparProduto(os),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _biparProduto(os),
                autofocus: true,
              ),
            ] else if (!os.unitizadorVinculado) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('PRODUTO BIPADO ✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _unitizadorController,
                decoration: InputDecoration(
                  labelText: 'Bipar etiqueta do Unitizador',
                  hintText: 'Escaneie a etiqueta do palete',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => _vincularUnitizador(os),
                  ),
                ),
                onSubmitted: (_) => _vincularUnitizador(os),
                autofocus: true,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_shipping, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('UNITIZADOR: ${os.codunitizador}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isProcessing ? null : () => _finalizarOs(os),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('FINALIZAR TAREFA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Calculadora
            TextButton.icon(
              onPressed: () => _mostrarCalculadora(context, os),
              icon: const Icon(Icons.calculate, color: Colors.amber),
              label: const Text('CALCULADORA', style: TextStyle(color: Colors.amber)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, Color color, VoidCallback onPressed) {
    return Expanded(
      child: SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildMiniEndereco(BuildContext context, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value.toString().padLeft(2, '0'),
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Future<void> _biparProduto(OsDetalhe os) async {
    final ean = _eanController.text.trim();
    if (ean.isEmpty) {
      _mostrarErro('Digite ou escaneie o código do produto');
      return;
    }

    setState(() => _isProcessing = true);
    final (sucesso, erro) = await ref.read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier).biparProduto(ean);
    setState(() => _isProcessing = false);

    if (sucesso) {
      _eanController.clear();
      _mostrarSucesso('Produto bipado!');
    } else {
      _mostrarErro(erro ?? 'Código inválido!');
    }
  }

  Future<void> _vincularUnitizador(OsDetalhe os) async {
    final codigo = _unitizadorController.text.trim();
    if (codigo.isEmpty) {
      _mostrarErro('Escaneie a etiqueta do unitizador');
      return;
    }

    setState(() => _isProcessing = true);
    final (sucesso, erro) = await ref.read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier).vincularUnitizador(codigo);
    setState(() => _isProcessing = false);

    if (sucesso) {
      _unitizadorController.clear();
      _mostrarSucesso('Unitizador vinculado!');
    } else {
      _mostrarErro(erro ?? 'Erro ao vincular unitizador');
    }
  }

  Future<void> _finalizarOs(OsDetalhe os) async {
    setState(() => _isProcessing = true);
    final (sucesso, erro) = await ref.read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier).finalizar(os.qtSolicitada);
    setState(() => _isProcessing = false);

    if (sucesso && mounted) {
      _mostrarSucesso('Tarefa finalizada!');
      Navigator.of(context).pop(true);
    } else {
      _mostrarErro(erro ?? 'Erro ao finalizar');
    }
  }

  void _mostrarDialogBloquear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red[50],
        title: const Text('DESEJA BLOQUEAR A\nTAREFA FASE 1?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final (sucesso, erro) = await ref.read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier).bloquear('Bloqueado pelo operador');
              if (sucesso && mounted) {
                _mostrarSucesso('Tarefa bloqueada!');
                Navigator.of(context).pop(true);
              } else {
                _mostrarErro(erro ?? 'Erro ao bloquear');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('SIM'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('NÃO'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogDivergencia(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.orange[50],
        title: const Text('SINALIZAR\nDIVERGÊNCIA?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final (sucesso, erro) = await ref.read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier).sinalizarDivergencia('OUTRO', 'Divergência sinalizada pelo operador');
              if (sucesso && mounted) {
                _mostrarSucesso('Divergência sinalizada!');
              } else {
                _mostrarErro(erro ?? 'Erro ao sinalizar');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('SIM'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('NÃO'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogEstoques(BuildContext context, int codprod) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final estoquesAsync = ref.watch(consultaEstoqueProvider(codprod));
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(child: Text('ESTOQUES', style: TextStyle(fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: estoquesAsync.when(
                data: (estoques) => estoques.isEmpty
                    ? const Center(child: Text('Nenhum estoque'))
                    : ListView.builder(
                        itemCount: estoques.length,
                        itemBuilder: (_, i) {
                          final e = estoques[i];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Text('${e.rua} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${e.predio.toString().padLeft(2, '0')} '),
                                  Text('${e.nivel.toString().padLeft(2, '0')} '),
                                  Text(e.apto.toString().padLeft(2, '0')),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                                    child: Text(e.quantidade.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarCalculadora(BuildContext context, OsDetalhe os) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CALCULADORA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Múltiplo: CX ${os.multiplo}'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Quantidade em UN', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: ctrl,
              builder: (context, value, child) {
                final qtd = int.tryParse(ctrl.text) ?? 0;
                final cx = os.multiplo > 0 ? (qtd / os.multiplo).ceil() : 0;
                return Text('= $cx caixas', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
              },
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('FECHAR'))],
      ),
    );
  }

  void _mostrarSucesso(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  void _mostrarErro(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
}