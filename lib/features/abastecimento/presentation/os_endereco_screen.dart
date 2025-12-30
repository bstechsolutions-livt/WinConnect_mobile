import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/os_detalhe_provider.dart';
import '../../../shared/models/os_detalhe_model.dart';
import 'os_bipar_screen.dart';

/// 5ª TELA - Endereço Origem
/// Mostra apenas o endereço onde o operador deve ir buscar o produto
class OsEnderecoScreen extends ConsumerWidget {
  final int fase;
  final int numos;
  final String faseNome;

  const OsEnderecoScreen({
    super.key,
    required this.fase,
    required this.numos,
    required this.faseNome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final osAsync = ref.watch(osDetalheNotifierProvider(fase, numos));

    return Scaffold(
      appBar: AppBar(
        title: Text('OS $numos'),
        centerTitle: true,
      ),
      body: osAsync.when(
        data: (os) => _buildContent(context, ref, os),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Erro ao carregar OS', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18)),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(osDetalheNotifierProvider(fase, numos).notifier).refresh(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, OsDetalhe os) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            
            // RUA no topo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'RUA ${os.enderecoOrigem.rua}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Título
            Text(
              'Endereço Origem',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Endereço em caixas grandes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEnderecoBox(context, 'PRÉDIO', os.enderecoOrigem.predio),
                const SizedBox(width: 12),
                _buildEnderecoBox(context, 'NÍVEL', os.enderecoOrigem.nivel),
                const SizedBox(width: 12),
                _buildEnderecoBox(context, 'APTO', os.enderecoOrigem.apto),
              ],
            ),
            
            const Spacer(),
            
            // Botão "Cheguei no endereço"
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton(
                onPressed: () async {
                  // Iniciar a OS antes de navegar para bipagem
                  final (sucesso, erro, osEmAndamento) = await ref
                      .read(osDetalheNotifierProvider(fase, numos).notifier)
                      .iniciarOs();
                  
                  if (!context.mounted) return;
                  
                  if (!sucesso) {
                    // Se tem outra OS em andamento, oferece opção de ir para ela
                    if (osEmAndamento != null) {
                      _mostrarDialogOsEmAndamento(context, ref, osEmAndamento, erro ?? '');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(erro ?? 'Erro ao iniciar OS'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                    return;
                  }
                  
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OsBiparScreen(
                        fase: fase,
                        numos: numos,
                        faseNome: faseNome,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CHEGUEI NO ENDEREÇO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEnderecoBox(BuildContext context, String label, int value) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogOsEmAndamento(BuildContext context, WidgetRef ref, int osEmAndamento, String mensagem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OS em Andamento', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Navega para a OS em andamento
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OsBiparScreen(
                    fase: fase,
                    numos: osEmAndamento,
                    faseNome: faseNome,
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: Text('IR PARA OS $osEmAndamento'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR'),
          ),
        ],
      ),
    );
  }
}