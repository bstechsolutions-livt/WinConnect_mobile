import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Resultado da seleção de quantidade
class QuantidadeResult {
  final int caixas;
  final int unidades;
  final int totalUnidades;
  
  QuantidadeResult({
    required this.caixas,
    required this.unidades,
    required this.multiplo,
  }) : totalUnidades = (caixas * multiplo) + unidades;
  
  final int multiplo;
}

/// Tela para seleção de quantidade (caixas/unidades)
class OsQuantidadeScreen extends StatefulWidget {
  final int numos;
  final int codprod;
  final String descricao;
  final int multiplo;
  final int qtSolicitada;
  final int caixasIniciais;
  final int unidadesIniciais;

  const OsQuantidadeScreen({
    super.key,
    required this.numos,
    required this.codprod,
    required this.descricao,
    required this.multiplo,
    required this.qtSolicitada,
    this.caixasIniciais = 0,
    this.unidadesIniciais = 0,
  });

  @override
  State<OsQuantidadeScreen> createState() => _OsQuantidadeScreenState();
}

class _OsQuantidadeScreenState extends State<OsQuantidadeScreen> {
  late int _caixas;
  late int _unidades;
  
  @override
  void initState() {
    super.initState();
    _caixas = widget.caixasIniciais;
    _unidades = widget.unidadesIniciais;
  }
  
  int get _totalDigitado => (_caixas * widget.multiplo) + _unidades;
  bool get _quantidadeCorreta => _totalDigitado == widget.qtSolicitada;
  int get _diferenca => _totalDigitado - widget.qtSolicitada;
  
  // Cálculo do esperado
  int get _caixasEsperadas => widget.qtSolicitada ~/ widget.multiplo;
  int get _unidadesEsperadas => widget.qtSolicitada % widget.multiplo;

  void _incrementarCaixas() => setState(() => _caixas++);
  void _decrementarCaixas() => setState(() { if (_caixas > 0) _caixas--; });
  void _incrementarUnidades() => setState(() => _unidades++);
  void _decrementarUnidades() => setState(() { if (_unidades > 0) _unidades--; });
  
  void _preencherEsperado() {
    setState(() {
      _caixas = _caixasEsperadas;
      _unidades = _unidadesEsperadas;
    });
  }
  
  void _limpar() {
    setState(() {
      _caixas = 0;
      _unidades = 0;
    });
  }

  void _confirmar() {
    if (_totalDigitado == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a quantidade'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    Navigator.pop(context, QuantidadeResult(
      caixas: _caixas,
      unidades: _unidades,
      multiplo: widget.multiplo,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Header: Produto
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                          child: Text('${widget.codprod}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber[700], borderRadius: BorderRadius.circular(4)),
                          child: Text('1CX=${widget.multiplo}UN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.descricao,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Quantidade esperada
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ESPERADO: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '${widget.qtSolicitada} UN',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (widget.multiplo > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _unidadesEsperadas > 0
                              ? '$_caixasEsperadas CX + $_unidadesEsperadas UN'
                              : '$_caixasEsperadas CX',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Controles de quantidade
              Expanded(
                child: Row(
                  children: [
                    // Coluna CAIXAS
                    Expanded(
                      child: _buildQuantityControl(
                        context: context,
                        label: 'CAIXAS',
                        value: _caixas,
                        color: Colors.green,
                        icon: Icons.inventory_2_rounded,
                        onIncrement: _incrementarCaixas,
                        onDecrement: _decrementarCaixas,
                        onEdit: () => _editarValor('Caixas', _caixas, (v) => setState(() => _caixas = v)),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Coluna UNIDADES
                    Expanded(
                      child: _buildQuantityControl(
                        context: context,
                        label: 'UNIDADES',
                        value: _unidades,
                        color: Colors.blue,
                        icon: Icons.straighten_rounded,
                        onIncrement: _incrementarUnidades,
                        onDecrement: _decrementarUnidades,
                        onEdit: () => _editarValor('Unidades', _unidades, (v) => setState(() => _unidades = v)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Total digitado e status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _quantidadeCorreta 
                      ? Colors.green.withValues(alpha: 0.15) 
                      : (_totalDigitado > 0 ? Colors.orange.withValues(alpha: 0.15) : isDark ? Colors.grey[800] : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _quantidadeCorreta 
                        ? Colors.green 
                        : (_totalDigitado > 0 ? Colors.orange : Colors.transparent),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_quantidadeCorreta)
                          const Icon(Icons.check_circle, color: Colors.green, size: 20)
                        else if (_totalDigitado > 0)
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'TOTAL: $_totalDigitado UN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _quantidadeCorreta ? Colors.green : (_totalDigitado > 0 ? Colors.orange : null),
                          ),
                        ),
                      ],
                    ),
                    if (_totalDigitado > 0 && !_quantidadeCorreta) ...[
                      const SizedBox(height: 4),
                      Text(
                        _diferenca > 0 ? '+$_diferenca a mais' : '$_diferenca a menos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Botões de ação rápida
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _limpar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('LIMPAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _preencherEsperado,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('PREENCHER ESPERADO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Botão confirmar
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _totalDigitado > 0 ? _confirmar : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _quantidadeCorreta ? Colors.green : Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _quantidadeCorreta ? 'CONFIRMAR ✓' : 'CONFIRMAR COM DIFERENÇA',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuantityControl({
    required BuildContext context,
    required String label,
    required int value,
    required Color color,
    required IconData icon,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          
          const Spacer(),
          
          // Botão decrementar
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: value > 0 ? onDecrement : null,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Icon(Icons.remove, size: 24),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Valor (tocável para editar)
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color),
              ),
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Botão incrementar
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onIncrement,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Icon(Icons.add, size: 24),
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
  
  void _editarValor(String titulo, int valorAtual, Function(int) onSave) {
    final controller = TextEditingController(text: valorAtual > 0 ? '$valorAtual' : '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Digitar $titulo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }
}
