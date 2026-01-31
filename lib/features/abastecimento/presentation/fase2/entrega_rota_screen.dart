import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../shared/providers/api_service_provider.dart';
import '../../../../shared/utils/scanner_protection.dart';
import '../../../../shared/widgets/autorizar_digitacao_dialog.dart';

/// Tela de entrega - mostra a rota e permite confirmar entregas
class EntregaRotaScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> rota;

  const EntregaRotaScreen({super.key, required this.rota});

  @override
  ConsumerState<EntregaRotaScreen> createState() => _EntregaRotaScreenState();
}

class _EntregaRotaScreenState extends ConsumerState<EntregaRotaScreen> {
  late List<Map<String, dynamic>> _rota;
  int _indiceAtual = 0;
  bool _entregando = false;

  // Etapa: 0 = bipar endereço, 1 = bipar produto, 2 = bipar endereço novamente
  int _etapa = 0;
  String _codigoEndereco = '';
  String _codigoProduto = '';

  // Controllers para scanner
  final _codigoController = TextEditingController();
  final _codigoFocusNode = FocusNode();
  bool _tecladoLiberado = false;

  // Rastreabilidade de digitação (por etapa)
  int? _autorizadorMatricula;
  bool _digitadoEndereco = false;
  bool _digitadoProduto = false;

  // Proteção contra digitação manual (só permite scanner rápido)
  late final ScannerProtection _scannerProtection;

  @override
  void initState() {
    super.initState();
    _rota = List.from(widget.rota);

    // Inicializa proteção contra digitação manual
    _scannerProtection = ScannerProtection(
      onManualInputBlocked: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Use o scanner ou solicite autorização para digitar',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );

    // Esconde teclado quando foca (para scanner físico)
    _codigoFocusNode.addListener(_onFocusChange);

    // Foca no campo após build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codigoFocusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    if (_codigoFocusNode.hasFocus && !_tecladoLiberado) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }

  @override
  void dispose() {
    _scannerProtection.dispose();
    _codigoController.dispose();
    _codigoFocusNode.removeListener(_onFocusChange);
    _codigoFocusNode.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _itemAtual =>
      _indiceAtual < _rota.length ? _rota[_indiceAtual] : null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1117)
          : const Color(0xFFF5F7FA),
      appBar: _buildAppBar(isDark),
      body: _rota.isEmpty ? _buildVazio(isDark) : _buildBody(isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        onPressed: () => _confirmarSaida(),
      ),
      title: Column(
        children: [
          Text(
            'Entrega',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          Text(
            'Rota de Abastecimento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildVazio(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Todas as entregas concluídas!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Parabéns! Você finalizou todas\nas entregas da rota.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'FINALIZAR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final item = _itemAtual;
    if (item == null) return _buildVazio(isDark);

    // Tenta buscar endereço de várias formas possíveis
    String enderecoStr = '---';
    final enderecoField = item['endereco'];
    final enderecoDestinoField = item['endereco_destino'];

    if (enderecoField is Map<String, dynamic>) {
      enderecoStr = enderecoField['endereco']?.toString() ?? '---';
    } else if (enderecoField is String && enderecoField.isNotEmpty) {
      enderecoStr = enderecoField;
    } else if (enderecoDestinoField is Map<String, dynamic>) {
      enderecoStr = enderecoDestinoField['endereco']?.toString() ?? '---';
    } else if (enderecoDestinoField is String &&
        enderecoDestinoField.isNotEmpty) {
      enderecoStr = enderecoDestinoField;
    }

    final descricao = item['descricao'] ?? 'Produto ${item['codprod']}';
    final qt = _parseNum(item['qt']);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            // Progresso compacto
            _buildProgressoCompacto(isDark),

            const SizedBox(height: 8),

            // Conteúdo principal
            Expanded(
              child: _buildConteudoEntrega(
                isDark,
                item,
                enderecoStr,
                descricao,
                qt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressoCompacto(bool isDark) {
    final entregues = widget.rota.length - _rota.length;
    final progresso = widget.rota.isEmpty
        ? 1.0
        : (entregues / widget.rota.length);

    return Row(
      children: [
        Text(
          '$entregues/${widget.rota.length}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Item ${_indiceAtual + 1}',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildConteudoEntrega(
    bool isDark,
    Map<String, dynamic> item,
    String endereco,
    String descricao,
    double qt,
  ) {
    // Etapa 0: Bipar endereço (chegou no local)
    // Etapa 1: Bipar produto (confirma produto)
    // Etapa 2: Bipar endereço novamente (confirma entrega)
    if (_etapa == 0) {
      return _buildEtapaEndereco(
        isDark,
        item,
        endereco,
        'VÁ ATÉ O ENDEREÇO',
        false,
      );
    } else if (_etapa == 1) {
      return _buildEtapaProduto(isDark, item, endereco, descricao, qt);
    } else {
      return _buildEtapaEndereco(
        isDark,
        item,
        endereco,
        'CONFIRME A ENTREGA',
        true,
      );
    }
  }

  /// Etapa de endereço - pode ser etapa 0 (ir até) ou etapa 2 (confirmar)
  Widget _buildEtapaEndereco(
    bool isDark,
    Map<String, dynamic> item,
    String endereco,
    String instrucaoTitulo,
    bool mostrarCheckProduto,
  ) {
    // Extrair partes do endereço (formato: RUA.PREDIO.NIVEL.APTO)
    final partes = endereco.split('.');
    final rua = partes.isNotEmpty ? partes[0] : '-';
    final predio = partes.length > 1 ? partes[1] : '-';
    final nivel = partes.length > 2 ? partes[2] : '-';
    final apto = partes.length > 3 ? partes[3] : '-';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Check de produto confirmado (só na etapa 2) - inline com instrução
        if (mostrarCheckProduto)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 12, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Produto ✓',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

        // Instrução
        Text(
          instrucaoTitulo,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        // RUA destacada
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'RUA $rua',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Caixas de endereço
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEnderecoBoxEntrega(isDark, 'PRÉDIO', predio),
            _buildPonto(isDark),
            _buildEnderecoBoxEntrega(isDark, 'NÍVEL', nivel),
            _buildPonto(isDark),
            _buildEnderecoBoxEntrega(isDark, 'APTO', apto),
          ],
        ),

        const SizedBox(height: 12),

        // Indicador
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'BIPE O ENDEREÇO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Campo de scanner
        _buildCampoScanner(
          isDark,
          item,
          endereco,
          Colors.green,
          'Bipe o endereço...',
        ),

        const Spacer(),
      ],
    );
  }

  /// Etapa 2: Produto - usuário bipa o produto para confirmar
  Widget _buildEtapaProduto(
    bool isDark,
    Map<String, dynamic> item,
    String endereco,
    String descricao,
    double qt,
  ) {
    final unitizador =
        item['codunitizador']?.toString() ??
        item['unitizador']?.toString() ??
        '-';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Check de endereço confirmado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                'Endereço: $endereco ✓',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Instrução
        Text(
          'CONFIRME O PRODUTO',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 10),

        // Card do produto
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unitizador
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    'Unitizador: ',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    unitizador,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Código do produto
              Text(
                'Cód: ${item['codprod']}',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),

              // Descrição
              Text(
                descricao,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.grey.shade900,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Quantidade
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'QTD: ${qt.toStringAsFixed(0)} UN',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Indicador
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2, size: 16, color: Colors.orange),
              const SizedBox(width: 6),
              Text(
                'BIPE O PRODUTO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Campo de scanner
        _buildCampoScanner(
          isDark,
          item,
          endereco,
          Colors.orange,
          'Bipe o produto...',
        ),

        const Spacer(),
      ],
    );
  }

  /// Etapa de endereço para modal - com callbacks
  Widget _buildEtapaEnderecoModal({
    required bool isDark,
    required String enderecoEsperado,
    required TextEditingController controller,
    required bool isLoading,
    required String? erro,
    required bool tecladoLiberado,
    required void Function(String) onConfirmar,
    required VoidCallback onCancelar,
    required VoidCallback onAbrirCamera,
    required VoidCallback onDigitar,
    required void Function(void Function()) setModalState,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 32,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'BIPAR ENDEREÇO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Text(
              enderecoEsperado,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Campo de scanner
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: erro != null
                    ? Colors.red.withValues(alpha: 0.5)
                    : Colors.green.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: tecladoLiberado
                  ? TextInputType.text
                  : TextInputType.none,
              decoration: InputDecoration(
                hintText: 'Aguardando leitura...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
                prefixIcon: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.green,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt_rounded),
                      color: Colors.green,
                      onPressed: onAbrirCamera,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_rounded,
                        color: tecladoLiberado ? Colors.orange : Colors.grey,
                      ),
                      onPressed: onDigitar,
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
              onChanged: (value) {
                setModalState(() {}); // Atualiza botão CONFIRMAR
                if (value.contains('\n') || value.contains('\r')) {
                  final codigo = value
                      .replaceAll('\n', '')
                      .replaceAll('\r', '')
                      .trim();
                  if (codigo.isNotEmpty) {
                    controller.text = codigo;
                    onConfirmar(codigo);
                  }
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  onConfirmar(value);
                }
              },
            ),
          ),
          if (erro != null) ...[
            const SizedBox(height: 8),
            Text(erro, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 16),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onCancelar,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('CANCELAR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isLoading || controller.text.isEmpty
                      ? null
                      : () => onConfirmar(controller.text.trim()),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    isLoading ? 'CONFIRMANDO...' : 'CONFIRMAR',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Etapa de produto para modal - com callbacks
  Widget _buildEtapaProdutoModal({
    required bool isDark,
    required String descricao,
    required String codauxiliar,
    required TextEditingController controller,
    required bool isLoading,
    required String? erro,
    required bool tecladoLiberado,
    required void Function(String) onConfirmar,
    required VoidCallback onVoltar,
    required VoidCallback onAbrirCamera,
    required VoidCallback onDigitar,
    required void Function(void Function()) setModalState,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 32,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'BIPAR PRODUTO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  descricao,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'EAN: $codauxiliar',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Campo de scanner
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: erro != null
                    ? Colors.red.withValues(alpha: 0.5)
                    : Colors.orange.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: tecladoLiberado
                  ? TextInputType.text
                  : TextInputType.none,
              decoration: InputDecoration(
                hintText: 'Aguardando leitura...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
                prefixIcon: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.orange,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt_rounded),
                      color: Colors.orange,
                      onPressed: onAbrirCamera,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_rounded,
                        color: tecladoLiberado ? Colors.orange : Colors.grey,
                      ),
                      onPressed: onDigitar,
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
              onChanged: (value) {
                setModalState(() {}); // Atualiza botão CONFIRMAR
                if (value.contains('\n') || value.contains('\r')) {
                  final codigo = value
                      .replaceAll('\n', '')
                      .replaceAll('\r', '')
                      .trim();
                  if (codigo.isNotEmpty) {
                    controller.text = codigo;
                    onConfirmar(codigo);
                  }
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  onConfirmar(value);
                }
              },
            ),
          ),
          if (erro != null) ...[
            const SizedBox(height: 8),
            Text(erro, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 16),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onVoltar,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('VOLTAR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isLoading || controller.text.isEmpty
                      ? null
                      : () => onConfirmar(controller.text.trim()),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    isLoading ? 'CONFIRMANDO...' : 'CONFIRMAR',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Campo de scanner reutilizável
  Widget _buildCampoScanner(
    bool isDark,
    Map<String, dynamic> item,
    String endereco,
    Color cor,
    String hintText,
  ) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _codigoFocusNode.hasFocus
                  ? cor
                  : Theme.of(context).colorScheme.outline,
              width: _codigoFocusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codigoController,
                  focusNode: _codigoFocusNode,
                  enabled: !_entregando,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: Icon(
                      Icons.qr_code_scanner,
                      color: _codigoFocusNode.hasFocus ? cor : null,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: _tecladoLiberado
                      ? TextInputType.text
                      : TextInputType.none,
                  onSubmitted: (_) => _processarCodigo(item, endereco),
                  onChanged: (value) {
                    // Verifica se é digitação manual não autorizada
                    final permitido = _scannerProtection.checkInput(
                      value,
                      tecladoLiberado: _tecladoLiberado,
                      clearCallback: () {
                        _codigoController.clear();
                        _scannerProtection.reset();
                      },
                    );

                    if (!permitido) return;

                    setState(() {}); // Atualiza botão CONFIRMAR
                    if (value.endsWith('\n') || value.endsWith('\r')) {
                      _codigoController.text = value.trim();
                      _scannerProtection.reset();
                      _processarCodigo(item, endereco);
                    }
                  },
                ),
              ),
              if (!_entregando)
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => _abrirCameraEntrega(item, endereco),
                ),
              if (_entregando)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Use o leitor ou toque na câmera',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 9,
          ),
        ),

        const SizedBox(height: 8),

        // Botões
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _entregando
                    ? null
                    : () => _solicitarAutorizacaoDigitar(item, endereco),
                icon: Icon(Icons.keyboard, color: cor, size: 16),
                label: const Text('DIGITAR', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cor,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _entregando || _codigoController.text.isEmpty
                    ? null
                    : () => _processarCodigo(item, endereco),
                style: FilledButton.styleFrom(
                  backgroundColor: cor,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _entregando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'CONFIRMAR',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnderecoBoxEntrega(bool isDark, String label, String value) {
    return Container(
      width: 54,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.green.withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPonto(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        '.',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final progresso = _rota.isEmpty ? 1.0 : (_indiceAtual / widget.rota.length);
    final entregues = widget.rota.length - _rota.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso da Rota',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              Text(
                '$entregues de ${widget.rota.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 10,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemAtualCard(
    bool isDark,
    Map<String, dynamic> item,
    String endereco,
    String descricao,
    double qt,
    dynamic ordem,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$ordem',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRÓXIMA ENTREGA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Item ${_indiceAtual + 1} de ${_rota.length}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#${item['numos']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Endereço destaque
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.green,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ENTREGAR EM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        endereco,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Info do produto
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              descricao,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : Colors.grey.shade800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip(
                            isDark,
                            Icons.tag,
                            'Cód: ${item['codprod']}',
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(
                            isDark,
                            Icons.scale,
                            '${qt.toStringAsFixed(0)} UN',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(bool isDark, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProximosItens(bool isDark) {
    final proximos = _rota.skip(_indiceAtual + 1).take(3).toList();

    if (proximos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos na fila',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        ...proximos.map((item) {
          // Tenta buscar endereço de várias formas possíveis
          String itemEndereco = '---';
          final enderecoField = item['endereco'];
          final enderecoDestinoField = item['endereco_destino'];

          if (enderecoField is Map<String, dynamic>) {
            itemEndereco = enderecoField['endereco']?.toString() ?? '---';
          } else if (enderecoField is String && enderecoField.isNotEmpty) {
            itemEndereco = enderecoField;
          } else if (enderecoDestinoField is Map<String, dynamic>) {
            itemEndereco =
                enderecoDestinoField['endereco']?.toString() ?? '---';
          } else if (enderecoDestinoField is String &&
              enderecoDestinoField.isNotEmpty) {
            itemEndereco = enderecoDestinoField;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${item['ordem']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['descricao'] ?? 'Produto ${item['codprod']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  itemEndereco,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar(
    bool isDark,
    String endereco,
    Map<String, dynamic> item,
  ) {
    // Etapa 0: bipar produto (pegar do carrinho)
    // Etapa 1: bipar endereço (confirmar entrega)
    final instrucao = _etapa == 0
        ? 'Bipe o produto: ${item['descricao']}'
        : 'Bipe o endereço: $endereco';
    final hintText = _etapa == 0
        ? 'Bipe o produto...'
        : 'Bipe o endereço...';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de etapa
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _etapa == 0
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _etapa == 0 ? Icons.inventory_2 : Icons.location_on,
                    size: 16,
                    color: _etapa == 0 ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    instrucao,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _etapa == 0 ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Campo de scanner
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _codigoFocusNode.hasFocus
                      ? (_etapa == 0 ? Colors.orange : Colors.green)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codigoController,
                      focusNode: _codigoFocusNode,
                      enabled: !_entregando,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.qr_code_scanner,
                          color: _etapa == 0 ? Colors.blue : Colors.orange,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                      keyboardType: _tecladoLiberado
                          ? TextInputType.text
                          : TextInputType.none,
                      onSubmitted: (_) => _processarCodigo(item, endereco),
                      onChanged: (value) {
                        // Verifica se é digitação manual não autorizada
                        final permitido = _scannerProtection.checkInput(
                          value,
                          tecladoLiberado: _tecladoLiberado,
                          clearCallback: () {
                            _codigoController.clear();
                            _scannerProtection.reset();
                          },
                        );

                        if (!permitido) return;

                        setState(() {}); // Atualiza botão CONFIRMAR
                      },
                    ),
                  ),
                  // Botão câmera
                  IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      color: _etapa == 0 ? Colors.blue : Colors.orange,
                    ),
                    onPressed: _entregando
                        ? null
                        : () => _abrirCameraEntrega(item, endereco),
                  ),
                  // Loading
                  if (_entregando)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Botões auxiliares
            Row(
              children: [
                // Botão digitar
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _entregando
                        ? null
                        : () => _solicitarAutorizacaoDigitar(item, endereco),
                    icon: const Icon(Icons.keyboard, size: 18),
                    label: const Text('DIGITAR'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botão confirmar
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _entregando || _codigoController.text.isEmpty
                        ? null
                        : () => _processarCodigo(item, endereco),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('CONFIRMAR'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Botão alterar produto (só aparece na etapa 1 - bipar endereço)
            if (_etapa == 1) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _entregando
                      ? null
                      : () {
                          setState(() {
                            _etapa = 0;
                            _codigoProduto = '';
                            _codigoController.clear();
                          });
                        },
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('ALTERAR PRODUTO'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Removido - já declarado acima

  /// Valida se o código bipado corresponde ao endereço esperado
  /// Aceita tanto o endereço formatado (ex: 14.17.0.101) quanto o codendereco numérico (ex: 72278)
  bool _validarCodigoEndereco(
    Map<String, dynamic> item,
    String codigo,
    String enderecoEsperado,
  ) {
    // Extrai o codendereco do item (pode estar em endereco ou endereco_destino)
    String? codendereco;
    final enderecoField = item['endereco'];
    final enderecoDestinoField = item['endereco_destino'];

    if (enderecoField is Map<String, dynamic>) {
      codendereco = enderecoField['codendereco']?.toString();
    } else if (enderecoDestinoField is Map<String, dynamic>) {
      codendereco = enderecoDestinoField['codendereco']?.toString();
    }

    // Verifica se o código bipado corresponde ao codendereco numérico
    if (codendereco != null && codendereco.isNotEmpty) {
      final codigoLimpo = codigo.replaceAll(RegExp(r'[^0-9]'), '');
      if (codigoLimpo == codendereco) {
        return true;
      }
    }

    // Verifica correspondência com endereço formatado
    final enderecoFormatado = enderecoEsperado
        .replaceAll('.', '')
        .toUpperCase();
    final codigoFormatado = codigo.replaceAll('.', '').toUpperCase();

    return codigoFormatado.contains(enderecoFormatado) ||
        enderecoFormatado.contains(codigoFormatado);
  }

  /// Processa o código bipado
  Future<void> _processarCodigo(
    Map<String, dynamic> item,
    String enderecoEsperado,
  ) async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) return;

    if (_etapa == 0) {
      // Etapa 0: Bipar endereço (chegou no local)
      if (!_validarCodigoEndereco(item, codigo, enderecoEsperado)) {
        _mostrarErro('Endereço incorreto! Esperado: $enderecoEsperado');
        _codigoController.clear();
        _scannerProtection.reset();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _codigoFocusNode.requestFocus();
        });
        return;
      }

      // Endereço OK, vai para etapa do produto
      setState(() {
        _codigoEndereco = codigo;
        _etapa = 1;
        _codigoController.clear();
        _scannerProtection.reset();
        // Rastreia se endereço foi digitado
        _digitadoEndereco = _tecladoLiberado;
        _tecladoLiberado = false;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _codigoFocusNode.requestFocus();
      });
    } else if (_etapa == 1) {
      // Etapa 1: Bipar produto - valida imediatamente se é o produto correto
      final codauxiliar = item['codauxiliar']?.toString() ?? '';
      final codauxiliar2 = item['codauxiliar2']?.toString() ?? '';
      final codprod = item['codprod']?.toString() ?? '';

      // Valida se o código bipado corresponde ao produto esperado
      final codigoValido =
          codigo == codauxiliar ||
          codigo == codauxiliar2 ||
          codigo == codprod ||
          (codauxiliar.isNotEmpty && codigo.contains(codauxiliar)) ||
          (codauxiliar2.isNotEmpty && codigo.contains(codauxiliar2)) ||
          (codprod.isNotEmpty && codigo.contains(codprod));

      if (!codigoValido) {
        final descricao = item['descricao'] ?? 'Produto $codprod';
        _mostrarErro('Produto incorreto! Esperado: $descricao');
        _codigoController.clear();
        _scannerProtection.reset();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _codigoFocusNode.requestFocus();
        });
        return;
      }

      // Produto OK, vai para etapa de confirmação de endereço
      setState(() {
        _codigoProduto = codigo;
        _etapa = 2;
        _codigoController.clear();
        _scannerProtection.reset();
        // Rastreia se produto foi digitado
        _digitadoProduto = _tecladoLiberado;
        _tecladoLiberado = false;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _codigoFocusNode.requestFocus();
      });
    } else {
      // Etapa 2: Bipar endereço novamente - confirma entrega
      if (!_validarCodigoEndereco(item, codigo, enderecoEsperado)) {
        _mostrarErro('Endereço incorreto! Esperado: $enderecoEsperado');
        _codigoController.clear();
        _scannerProtection.reset();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _codigoFocusNode.requestFocus();
        });
        return;
      }

      // Tudo OK, confirma entrega na API
      await _confirmarEntregaApi(item, codigo, _codigoProduto);
    }
  }

  /// Confirma entrega na API
  Future<void> _confirmarEntregaApi(
    Map<String, dynamic> item,
    String codigoEndereco,
    String codigoProduto,
  ) async {
    setState(() => _entregando = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService
          .post('/wms/fase2/os/${item['numos']}/confirmar-entrega', {
            'codigo_barras_endereco': codigoEndereco,
            'codigo_barras_produto': codigoProduto,
            'digitado_endereco': _digitadoEndereco,
            'digitado_produto': _digitadoProduto,
            if ((_digitadoEndereco || _digitadoProduto) &&
                _autorizadorMatricula != null)
              'autorizador_matricula': _autorizadorMatricula,
          });

      if (!mounted) return;

      // Sucesso! Remove item e vai para próximo
      setState(() {
        _rota.removeAt(_indiceAtual);
        if (_indiceAtual >= _rota.length && _rota.isNotEmpty) {
          _indiceAtual = _rota.length - 1;
        }
        _etapa = 0;
        _codigoEndereco = '';
        _codigoProduto = '';
        _codigoController.clear();
        _scannerProtection.reset();
        _entregando = false;
        _tecladoLiberado = false;
        // Reseta flags de digitação
        _digitadoEndereco = false;
        _digitadoProduto = false;
        _autorizadorMatricula = null;
      });

      // Se ainda tem itens, foca para próximo com delay
      if (_rota.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _codigoFocusNode.requestFocus();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _entregando = false);
      _mostrarErro(e.toString().replaceAll('Exception: ', ''));
      _codigoController.clear();
      _scannerProtection.reset();
      // Refoca com delay para evitar conflito DOM no Flutter Web
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _codigoFocusNode.requestFocus();
      });
    }
  }

  /// Abre câmera para entrega
  void _abrirCameraEntrega(Map<String, dynamic> item, String endereco) {
    // Etapa 0 e 2: endereço, Etapa 1: produto
    final titulo = _etapa == 1 ? 'Escanear Produto' : 'Escanear Endereço';

    _abrirCamera(
      titulo: titulo,
      instrucao: _etapa == 1
          ? 'Escaneie o código do produto'
          : 'Escaneie o endereço $endereco',
      onScanned: (codigo) {
        Navigator.pop(context);
        _codigoController.text = codigo;
        _processarCodigo(item, endereco);
      },
    );
  }

  /// Solicita autorização para digitar manualmente
  Future<void> _solicitarAutorizacaoDigitar(
    Map<String, dynamic> item,
    String endereco,
  ) async {
    // Remove foco antes de abrir o dialog para evitar conflitos no Flutter Web
    FocusScope.of(context).unfocus();

    final apiService = ref.read(apiServiceProvider);

    final resultado = await AutorizarDigitacaoDialog.mostrarComDados(
      context: context,
      apiService: apiService,
    );

    if (resultado.autorizado && mounted) {
      setState(() {
        _tecladoLiberado = true;
        _autorizadorMatricula = resultado.matriculaAutorizador;
      });
      // Pequeno delay para o Flutter Web processar a mudança de estado
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _codigoFocusNode.requestFocus();
      }
    }
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Abre câmera para escanear código de barras
  void _abrirCamera({
    required String titulo,
    required String instrucao,
    required void Function(String codigo) onScanned,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            // Scanner
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: MobileScannerController(
                    facing: CameraFacing.back,
                  ),
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty &&
                        barcodes.first.rawValue != null) {
                      final codigo = barcodes.first.rawValue!;
                      Navigator.pop(ctx);
                      onScanned(codigo);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                instrucao,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEntrega(
    Map<String, dynamic> item,
    String enderecoEsperado,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extrair codauxiliar (código de barras esperado do produto)
    final codauxiliar = item['codauxiliar']?.toString() ?? '';
    final descricao = item['descricao'] ?? 'Produto ${item['codprod']}';

    // Resultado da confirmação - inclui dados da resposta da API
    Map<String, dynamic>? resultadoApi;

    // Abre modal para confirmar endereço e produto
    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Etapa: 0 = bipar endereço, 1 = bipar produto, 2 = confirmando
        int etapa = 0;
        String codigoEndereco = '';
        String codigoProduto = '';
        bool isLoading = false;
        String? erro;
        bool tecladoLiberado = false;
        // Rastreamento de digitação para log
        bool digitadoEnderecoModal = false;
        bool digitadoProdutoModal = false;
        int? autorizadorMatriculaModal;

        final enderecoController = TextEditingController();
        final produtoController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            // Valida se o produto bipado está correto
            bool validarProduto(String codigo) {
              final codprod = item['codprod']?.toString() ?? '';
              final codauxiliar2 = item['codauxiliar2']?.toString() ?? '';
              return codigo == codauxiliar ||
                  codigo == codauxiliar2 ||
                  codigo == codprod ||
                  (codauxiliar.isNotEmpty && codigo.contains(codauxiliar)) ||
                  (codauxiliar2.isNotEmpty && codigo.contains(codauxiliar2)) ||
                  (codprod.isNotEmpty && codigo.contains(codprod));
            }

            Future<void> confirmarNaApi() async {
              setModalState(() {
                etapa = 2;
                isLoading = true;
                erro = null;
              });

              try {
                final apiService = ref.read(apiServiceProvider);
                final body = <String, dynamic>{
                  'codigo_barras_endereco': codigoEndereco,
                  'codigo_barras_produto': codigoProduto,
                  'digitado_endereco': digitadoEnderecoModal,
                  'digitado_produto': digitadoProdutoModal,
                };
                if (autorizadorMatriculaModal != null) {
                  body['autorizador_matricula'] = autorizadorMatriculaModal;
                }
                final response = await apiService.post(
                  '/wms/fase2/os/${item['numos']}/confirmar-entrega',
                  body,
                );

                // Salva resultado para usar depois de fechar o modal
                resultadoApi = response;

                if (ctx.mounted) {
                  Navigator.pop(ctx, true);
                }
              } catch (e) {
                setModalState(() {
                  erro = e.toString().replaceAll('Exception: ', '');
                  isLoading = false;
                  // Volta para a etapa do produto para tentar novamente
                  etapa = 1;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Indicador de etapas
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              _buildEtapaIndicador(
                                isDark: isDark,
                                numero: 1,
                                titulo: 'Endereço',
                                ativo: etapa >= 0,
                                concluido: etapa > 0,
                              ),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: etapa > 0
                                      ? Colors.green
                                      : (isDark
                                            ? Colors.white24
                                            : Colors.grey.shade300),
                                ),
                              ),
                              _buildEtapaIndicador(
                                isDark: isDark,
                                numero: 2,
                                titulo: 'Produto',
                                ativo: etapa >= 1,
                                concluido: etapa > 1,
                              ),
                            ],
                          ),
                        ),

                        // ETAPA 0: Bipar endereço
                        if (etapa == 0) ...[
                          _buildEtapaEnderecoModal(
                            isDark: isDark,
                            enderecoEsperado: enderecoEsperado,
                            controller: enderecoController,
                            isLoading: isLoading,
                            erro: erro,
                            tecladoLiberado: tecladoLiberado,
                            onConfirmar: (codigo) {
                              setModalState(() {
                                codigoEndereco = codigo;
                                digitadoEnderecoModal = tecladoLiberado;
                                etapa = 1;
                                erro = null;
                                tecladoLiberado =
                                    false; // Reset ao mudar de etapa
                              });
                            },
                            onCancelar: () => Navigator.pop(ctx, false),
                            onAbrirCamera: () => _abrirCamera(
                              titulo: 'Escanear Endereço',
                              instrucao:
                                  'Aponte a câmera para o código do endereço',
                              onScanned: (codigo) {
                                enderecoController.text = codigo;
                                setModalState(() {
                                  codigoEndereco = codigo;
                                  digitadoEnderecoModal = false;
                                  etapa = 1;
                                  erro = null;
                                  tecladoLiberado = false;
                                });
                              },
                            ),
                            onDigitar: () async {
                              final apiService = ref.read(apiServiceProvider);
                              final autorizacao =
                                  await AutorizarDigitacaoDialog.mostrarComDados(
                                    context: ctx,
                                    apiService: apiService,
                                  );
                              if (autorizacao.autorizado) {
                                setModalState(() {
                                  tecladoLiberado = true;
                                  if (autorizacao.matriculaAutorizador !=
                                      null) {
                                    autorizadorMatriculaModal =
                                        autorizacao.matriculaAutorizador;
                                  }
                                });
                              }
                            },
                            setModalState: setModalState,
                          ),
                        ],

                        // ETAPA 1: Bipar produto
                        if (etapa == 1) ...[
                          _buildEtapaProdutoModal(
                            isDark: isDark,
                            descricao: descricao,
                            codauxiliar: codauxiliar,
                            controller: produtoController,
                            isLoading: isLoading,
                            erro: erro,
                            tecladoLiberado: tecladoLiberado,
                            onConfirmar: (codigo) {
                              // Valida produto imediatamente antes de confirmar
                              if (!validarProduto(codigo)) {
                                setModalState(() {
                                  erro =
                                      'Produto incorreto! Esperado: $descricao';
                                  produtoController.clear();
                                });
                                return;
                              }
                              codigoProduto = codigo;
                              digitadoProdutoModal = tecladoLiberado;
                              confirmarNaApi();
                            },
                            onVoltar: () {
                              setModalState(() {
                                etapa = 0;
                                erro = null;
                                tecladoLiberado = false;
                              });
                            },
                            onAbrirCamera: () => _abrirCamera(
                              titulo: 'Escanear Produto',
                              instrucao:
                                  'Aponte a câmera para o código de barras do produto',
                              onScanned: (codigo) {
                                produtoController.text = codigo;
                                // Valida produto imediatamente após escanear
                                if (!validarProduto(codigo)) {
                                  setModalState(() {
                                    erro =
                                        'Produto incorreto! Esperado: $descricao';
                                    produtoController.clear();
                                  });
                                  return;
                                }
                                codigoProduto = codigo;
                                digitadoProdutoModal = false;
                                confirmarNaApi();
                              },
                            ),
                            onDigitar: () async {
                              final apiService = ref.read(apiServiceProvider);
                              final autorizacao =
                                  await AutorizarDigitacaoDialog.mostrarComDados(
                                    context: ctx,
                                    apiService: apiService,
                                  );
                              if (autorizacao.autorizado) {
                                setModalState(() {
                                  tecladoLiberado = true;
                                  if (autorizacao.matriculaAutorizador !=
                                      null) {
                                    autorizadorMatriculaModal =
                                        autorizacao.matriculaAutorizador;
                                  }
                                });
                              }
                            },
                            setModalState: setModalState,
                          ),
                        ],

                        // ETAPA 2: Confirmando (loading)
                        if (etapa == 2) ...[
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Confirmando entrega...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmado == true && mounted && resultadoApi != null) {
      // Atualiza a rota com base na resposta da API
      final rotaConcluida = resultadoApi!['rota_concluida'] == true;
      final proximaEntrega = resultadoApi!['proxima_entrega'];
      final progresso = resultadoApi!['progresso'];

      setState(() {
        // Remove o item atual
        _rota.removeAt(_indiceAtual);

        // Se tem próxima entrega, atualiza a rota
        if (proximaEntrega != null && !rotaConcluida) {
          // A resposta já vem com a próxima entrega, então a rota local já está correta
          // após remover o item atual
        }

        // Ajusta índice se necessário
        if (_indiceAtual >= _rota.length && _rota.isNotEmpty) {
          _indiceAtual = _rota.length - 1;
        }
      });

      if (!rotaConcluida && _rota.isNotEmpty) {
        final entregues = progresso?['entregues'] ?? 0;
        final total = progresso?['total'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Entrega confirmada! $entregues de $total concluídas.'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildEtapaIndicador({
    required bool isDark,
    required int numero,
    required String titulo,
    required bool ativo,
    required bool concluido,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: concluido
                ? Colors.green
                : (ativo
                      ? Colors.blue
                      : (isDark ? Colors.white24 : Colors.grey.shade300)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: concluido
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$numero',
                    style: TextStyle(
                      color: ativo
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.grey),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 11,
            color: ativo
                ? (isDark ? Colors.white70 : Colors.grey.shade700)
                : (isDark ? Colors.white38 : Colors.grey.shade400),
            fontWeight: ativo ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarSaida() async {
    if (_rota.isEmpty) {
      Navigator.pop(context, true);
      return;
    }

    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da rota?'),
        content: Text(
          'Você ainda tem ${_rota.length} ${_rota.length == 1 ? "entrega" : "entregas"} pendentes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SAIR'),
          ),
        ],
      ),
    );

    if (sair == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  double _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
