import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../shared/providers/api_service_provider.dart';

/// Tela para guardar item no endereço de picking (Fase 2)
class GuardarItemScreen extends ConsumerStatefulWidget {
  final int numos;
  final int codprod;
  final String descricao;
  final double quantidade;
  final int codunitizador;
  final String codigoBarrasUnitizador;
  final Map<String, dynamic>? endereco;

  const GuardarItemScreen({
    super.key,
    required this.numos,
    required this.codprod,
    required this.descricao,
    required this.quantidade,
    required this.codunitizador,
    required this.codigoBarrasUnitizador,
    required this.endereco,
  });

  @override
  ConsumerState<GuardarItemScreen> createState() => _GuardarItemScreenState();
}

class _GuardarItemScreenState extends ConsumerState<GuardarItemScreen> {
  final _unitizadorController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _unitizadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final endereco = widget.endereco;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardar Item'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card do endereço destino
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'ENDEREÇO DESTINO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'RUA ${endereco?['rua'] ?? '?'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildEnderecoBox('PRÉDIO', endereco?['predio']),
                          const SizedBox(width: 8),
                          _buildEnderecoBox('NÍVEL', endereco?['nivel']),
                          const SizedBox(width: 8),
                          _buildEnderecoBox('APTO', endereco?['apto']),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Info do produto
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.descricao,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Qtd: ${widget.quantidade.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('OS: ${widget.numos}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Campo para bipar unitizador
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'CONFIRMAR GUARDA',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Bipe o código do unitizador',
                        style: TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _unitizadorController,
                        decoration: InputDecoration(
                          labelText: 'Código do Unitizador',
                          hintText: 'Escaneie o unitizador',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: _confirmarGuarda,
                          ),
                        ),
                        onSubmitted: (_) => _confirmarGuarda(),
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _isProcessing ? null : _confirmarGuarda,
                          style: FilledButton.styleFrom(backgroundColor: Colors.green),
                          child: _isProcessing
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('CONFIRMAR GUARDA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnderecoBox(String label, dynamic value) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              (value ?? 0).toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarGuarda() async {
    final codigo = _unitizadorController.text.trim();
    if (codigo.isEmpty) {
      _mostrarErro('Escaneie o código do unitizador');
      return;
    }

    // Validação local
    if (codigo != widget.codigoBarrasUnitizador) {
      _mostrarErro('Código do unitizador incorreto!');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Confirma guarda
      await apiService.post('/abastecimento/fase2/os/${widget.numos}/confirmar-guarda', {
        'codigo_barras_unitizador': codigo,
      });
      
      // Finaliza a OS
      await apiService.post('/abastecimento/fase2/os/${widget.numos}/finalizar', {});

      if (!mounted) return;
      
      _mostrarSucesso('Item guardado e OS finalizada!');
      Navigator.of(context).pop(true);
      
    } catch (e) {
      setState(() => _isProcessing = false);
      _mostrarErro('Erro: $e');
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
