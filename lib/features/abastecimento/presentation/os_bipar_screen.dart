import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  final FocusNode _eanFocusNode = FocusNode();
  final FocusNode _unitizadorFocusNode = FocusNode();
  bool _isProcessing = false;
  bool _finalizacaoIniciada = false; // Evita chamar finalização múltiplas vezes

  // Cache da quantidade conferida (usado após vincular unitizador)
  int? _caixasConferidas;
  int? _unidadesConferidas;
  int? _qtConferida;

  @override
  void initState() {
    super.initState();
    // Esconde teclado quando foca (para scanner físico)
    _eanFocusNode.addListener(() {
      if (_eanFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });
    _unitizadorFocusNode.addListener(() {
      if (_unitizadorFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });
    // Foca no campo após build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _eanFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _eanController.dispose();
    _unitizadorController.dispose();
    _eanFocusNode.dispose();
    _unitizadorFocusNode.dispose();
    super.dispose();
  }

  /// Abre scanner de câmera para EAN
  void _abrirScannerCameraEan(OsDetalhe os) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Escanear Código do Produto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
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
                      Navigator.pop(context);
                      _eanController.text = codigo;
                      _biparProduto(os);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aponte a câmera para o código de barras do produto',
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

  /// Abre scanner de câmera para Unitizador
  void _abrirScannerCameraUnitizador(OsDetalhe os) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Escanear Etiqueta do Unitizador',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
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
                      Navigator.pop(context);
                      _unitizadorController.text = codigo;
                      _vincularUnitizador(os);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aponte a câmera para a etiqueta do palete/unitizador',
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

  @override
  Widget build(BuildContext context) {
    final osAsync = ref.watch(
      osDetalheNotifierProvider(widget.fase, widget.numos),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('OS ${widget.numos}'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove botão voltar
        actions: [
          // Botão Sair da OS
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.red.shade400),
            tooltip: 'Sair da OS',
            onPressed: () => _mostrarDialogSairOs(context),
          ),
        ],
      ),
      body: osAsync.when(
        data: (os) => _buildContent(context, os),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(
                      osDetalheNotifierProvider(
                        widget.fase,
                        widget.numos,
                      ).notifier,
                    )
                    .refresh(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, OsDetalhe os) {
    final caixasInteiras = os.multiplo > 0
        ? (os.qtSolicitada / os.multiplo).floor()
        : 0;
    final unidadesRestantes = os.multiplo > 0
        ? (os.qtSolicitada % os.multiplo).toInt()
        : os.qtSolicitada.toInt();
    final temCaixaQuebrada = unidadesRestantes > 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Botões de ação
            Row(
              children: [
                _buildActionButton(
                  context,
                  'BLOQUEAR',
                  Colors.red,
                  () => _mostrarDialogBloquear(context),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  context,
                  'DIVERGÊNCIA',
                  Colors.orange,
                  () => _mostrarDialogDivergencia(context),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  context,
                  'ESTOQUES',
                  Colors.blue,
                  () => _mostrarEstoques(context, os.codprod, os.descricao),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Card: Endereço de Origem (MELHORADO)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header do endereço
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ENDEREÇO DE ORIGEM',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'OS: ${os.numos}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Endereço completo com labels
                  Row(
                    children: [
                      // RUA
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'RUA',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                os.enderecoOrigem.rua,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // PRÉDIO
                      _buildEnderecoBox(
                        context,
                        'PRÉDIO',
                        os.enderecoOrigem.predio.toString().padLeft(2, '0'),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // NÍVEL
                      _buildEnderecoBox(
                        context,
                        'NÍVEL',
                        os.enderecoOrigem.nivel.toString().padLeft(2, '0'),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // APTO
                      _buildEnderecoBox(
                        context,
                        'APTO',
                        os.enderecoOrigem.apto.toString().padLeft(2, '0'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Estoque atual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Estoque atual no endereço: ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${os.qtEstoqueAtual.toStringAsFixed(0)} UN',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Card: Produto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'CÓD: ${os.codprod}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Informação do múltiplo (1 CX = X UN)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '1 CX = ${os.multiplo} UN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    os.descricao,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // CARDS DE QUANTIDADE - REDESENHADO
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  // Título da seção
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'QUANTIDADE A ABASTECER',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Total em destaque
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: os.produtoBipado ? Colors.green : Colors.blue[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TOTAL SOLICITADO',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              os.qtSolicitada.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'UNIDADES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Explicação: escolha como abastecer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Escolha como abastecer: por CAIXAS ou por UNIDADES',
                            style: TextStyle(
                              color: Colors.amber[900],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Opções: Caixas ou Unidades
                  Row(
                    children: [
                      // Opção por CAIXAS
                      Expanded(
                        child: InkWell(
                          onTap: () => _mostrarCalculadora(context, os),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.green[600]!,
                                  Colors.green[700]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'POR CAIXAS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (temCaixaQuebrada) ...[
                                  // Caixa quebrada: mostra CX + UN em coluna
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '$caixasInteiras',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            ' CX',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Text(
                                            ' + ',
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '$unidadesRestantes',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            ' UN',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'CAIXA QUEBRADA',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  // Caixas completas
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$caixasInteiras',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'CX',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Separador "OU"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OU',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      // Opção por UNIDADES
                      Expanded(
                        child: InkWell(
                          onTap: () => _mostrarCalculadora(context, os),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.blue[500]!, Colors.blue[700]!],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.straighten_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'POR UNIDADES',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      os.qtSolicitada.toStringAsFixed(0),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'UN',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Campo de bipagem ou status
            if (!os.produtoBipado) ...[
              _buildScannerInput(
                context: context,
                controller: _eanController,
                focusNode: _eanFocusNode,
                hintText: 'Aguardando leitura do produto...',
                icon: Icons.qr_code_scanner,
                onCameraPressed: () => _abrirScannerCameraEan(os),
                onDigitarPressed: () {
                  _eanFocusNode.requestFocus();
                  SystemChannels.textInput.invokeMethod('TextInput.show');
                },
                onConfirmarPressed: () => _biparProduto(os),
                onSubmitted: (_) => _biparProduto(os),
                onChanged: (value) {
                  if (value.endsWith('\n') || value.endsWith('\r')) {
                    _eanController.text = value.trim();
                    _biparProduto(os);
                  }
                },
              ),
            ] else if (!os.unitizadorVinculado) ...[
              // Produto bipado com sucesso
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'PRODUTO CONFIRMADO ✓',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Scanner para unitizador
              _buildScannerInput(
                context: context,
                controller: _unitizadorController,
                focusNode: _unitizadorFocusNode,
                hintText: 'Aguardando leitura do unitizador...',
                icon: Icons.local_shipping,
                onCameraPressed: () => _abrirScannerCameraUnitizador(os),
                onDigitarPressed: () {
                  _unitizadorFocusNode.requestFocus();
                  SystemChannels.textInput.invokeMethod('TextInput.show');
                },
                onConfirmarPressed: () => _vincularUnitizador(os),
                onSubmitted: (_) => _vincularUnitizador(os),
                onChanged: (value) {
                  if (value.endsWith('\n') || value.endsWith('\r')) {
                    _unitizadorController.text = value.trim();
                    _vincularUnitizador(os);
                  }
                },
              ),
            ] else ...[
              // Unitizador já vinculado - finalizar automaticamente
              // Mostra indicador de processamento enquanto finaliza
              Builder(
                builder: (context) {
                  // Agenda a finalização automática após o build (apenas uma vez)
                  if (!_isProcessing && !_finalizacaoIniciada) {
                    _finalizacaoIniciada = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _finalizarOs(os);
                      }
                    });
                  }
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'PRODUTO ✓',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.local_shipping,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'UNITIZADOR: ${os.codunitizador}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Finalizando tarefa...',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 16),

            // Calculadora melhorada
            OutlinedButton.icon(
              onPressed: () => _mostrarCalculadora(context, os),
              icon: const Icon(Icons.calculate),
              label: const Text('CALCULADORA UN ↔ CX'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber[700],
                side: BorderSide(color: Colors.amber[700]!),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Widget reutilizável para scanner input
  Widget _buildScannerInput({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    required VoidCallback onCameraPressed,
    required VoidCallback onDigitarPressed,
    required VoidCallback onConfirmarPressed,
    required Function(String) onSubmitted,
    required Function(String) onChanged,
  }) {
    return Column(
      children: [
        // Campo de input
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focusNode.hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !_isProcessing,
                  readOnly: false,
                  showCursor: true,
                  decoration: InputDecoration(
                    hintText: hintText,
                    prefixIcon: Icon(
                      icon,
                      color: focusNode.hasFocus
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.none,
                  onSubmitted: onSubmitted,
                  onChanged: onChanged,
                ),
              ),
              if (!_isProcessing)
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Escanear com câmera',
                  onPressed: onCameraPressed,
                ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use o leitor de código de barras ou toque na câmera',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : onDigitarPressed,
                icon: const Icon(Icons.keyboard),
                label: const Text('DIGITAR'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isProcessing ? null : onConfirmarPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'CONFIRMAR',
                        style: TextStyle(
                          fontSize: 16,
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

  Widget _buildEnderecoBox(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _biparProduto(OsDetalhe os) async {
    final ean = _eanController.text.trim();
    if (ean.isEmpty) {
      _mostrarErro('Bipe o código do produto');
      return;
    }

    // Primeiro valida o código de barras na API
    if (!mounted) return;
    setState(() => _isProcessing = true);

    final (sucesso, erro) = await ref
        .read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier)
        .biparProduto(ean);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (sucesso) {
      // Produto válido, abre bottom sheet para conferência de quantidade
      _mostrarConferenciaQuantidade(ean, os);
    } else {
      _mostrarErro(erro ?? 'Código de barras inválido!');
    }
  }

  /// Mostra bottom sheet para conferência de quantidade
  void _mostrarConferenciaQuantidade(String codigoBarras, OsDetalhe os) {
    _mostrarConferenciaQuantidadeComValores(codigoBarras, os, 0, 0);
  }

  /// Mostra bottom sheet para conferência de quantidade COM valores iniciais
  void _mostrarConferenciaQuantidadeComValores(
    String codigoBarras,
    OsDetalhe os,
    int caixasIniciais,
    int unidadesIniciais,
  ) {
    final caixasController = TextEditingController(text: '$caixasIniciais');
    final unidadesController = TextEditingController(text: '$unidadesIniciais');

    final multiplo = os.multiplo;
    final qtSolicitada = os.qtSolicitada.toInt();

    // Calcula caixas e unidades esperadas
    final caixasEsperadas = qtSolicitada ~/ multiplo;
    final unidadesEsperadas = qtSolicitada % multiplo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Calcula total digitado
            final caixasDigitadas = int.tryParse(caixasController.text) ?? 0;
            final unidadesDigitadas =
                int.tryParse(unidadesController.text) ?? 0;
            final totalDigitado =
                (caixasDigitadas * multiplo) + unidadesDigitadas;

            // Verifica se quantidade está correta
            final quantidadeCorreta = totalDigitado == qtSolicitada;
            final temDiferenca = totalDigitado != 0 && !quantidadeCorreta;
            final diferenca = totalDigitado - qtSolicitada;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'CONFERÊNCIA DE QUANTIDADE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Digite a quantidade que você pegou',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quantidade Esperada
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'QUANTIDADE ESPERADA',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$qtSolicitada',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'UN',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              if (multiplo > 1) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    unidadesEsperadas > 0
                                        ? '$caixasEsperadas CX + $unidadesEsperadas UN'
                                        : '$caixasEsperadas CX',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Informação do múltiplo
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '1 CAIXA = $multiplo UNIDADES',
                                style: TextStyle(
                                  color: Colors.amber[900],
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Campos de entrada
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              // Campo Caixas
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'CAIXAS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              final atual =
                                                  int.tryParse(
                                                    caixasController.text,
                                                  ) ??
                                                  0;
                                              if (atual > 0) {
                                                caixasController.text =
                                                    '${atual - 1}';
                                                setModalState(() {});
                                              }
                                            },
                                            icon: const Icon(Icons.remove),
                                            color: Colors.green[700],
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: caixasController,
                                              textAlign: TextAlign.center,
                                              keyboardType:
                                                  TextInputType.number,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              onChanged: (_) =>
                                                  setModalState(() {}),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              final atual =
                                                  int.tryParse(
                                                    caixasController.text,
                                                  ) ??
                                                  0;
                                              caixasController.text =
                                                  '${atual + 1}';
                                              setModalState(() {});
                                            },
                                            icon: const Icon(Icons.add),
                                            color: Colors.green[700],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${caixasDigitadas * multiplo} un',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Separador "+"
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  '+',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),

                              // Campo Unidades
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'UNIDADES',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              final atual =
                                                  int.tryParse(
                                                    unidadesController.text,
                                                  ) ??
                                                  0;
                                              if (atual > 0) {
                                                unidadesController.text =
                                                    '${atual - 1}';
                                                setModalState(() {});
                                              }
                                            },
                                            icon: const Icon(Icons.remove),
                                            color: Colors.blue[700],
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: unidadesController,
                                              textAlign: TextAlign.center,
                                              keyboardType:
                                                  TextInputType.number,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              onChanged: (_) =>
                                                  setModalState(() {}),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              final atual =
                                                  int.tryParse(
                                                    unidadesController.text,
                                                  ) ??
                                                  0;
                                              unidadesController.text =
                                                  '${atual + 1}';
                                              setModalState(() {});
                                            },
                                            icon: const Icon(Icons.add),
                                            color: Colors.blue[700],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'avulsas',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Total digitado
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: quantidadeCorreta
                                ? Colors.green[50]
                                : temDiferenca
                                ? Colors.red[50]
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: quantidadeCorreta
                                  ? Colors.green
                                  : temDiferenca
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (quantidadeCorreta)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[700],
                                      size: 20,
                                    ),
                                  if (temDiferenca)
                                    Icon(
                                      Icons.error,
                                      color: Colors.red[700],
                                      size: 20,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TOTAL DIGITADO',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: quantidadeCorreta
                                          ? Colors.green[700]
                                          : temDiferenca
                                          ? Colors.red[700]
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$totalDigitado',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: quantidadeCorreta
                                          ? Colors.green[700]
                                          : temDiferenca
                                          ? Colors.red[700]
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'UN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: quantidadeCorreta
                                          ? Colors.green[700]
                                          : temDiferenca
                                          ? Colors.red[700]
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              if (temDiferenca) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    diferenca > 0
                                        ? '+$diferenca UN (sobra)'
                                        : '$diferenca UN (falta)',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (quantidadeCorreta) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '✓ Quantidade correta!',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Botão Confirmar quantidade (quantidade correta)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: quantidadeCorreta
                                  ? () async {
                                      Navigator.pop(ctx);
                                      await _confirmarBipagem(
                                        codigoBarras,
                                        os,
                                        caixasDigitadas,
                                        unidadesDigitadas,
                                      );
                                    }
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                disabledBackgroundColor: Colors.grey[400],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    quantidadeCorreta
                                        ? Icons.check_circle
                                        : Icons.block,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'CONFIRMAR QUANTIDADE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
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
  }

  /// Confirma a bipagem e guarda quantidade em cache (não finaliza ainda!)
  /// A finalização só acontece após vincular o unitizador
  Future<void> _confirmarBipagem(
    String codigoBarras,
    OsDetalhe os,
    int caixas,
    int unidades,
  ) async {
    // Calcula quantidade total
    final qtConferida = (caixas * os.multiplo) + unidades;

    // Guarda em cache para usar depois de vincular unitizador
    if (!mounted) return;
    setState(() {
      _caixasConferidas = caixas;
      _unidadesConferidas = unidades;
      _qtConferida = qtConferida;
    });

    // Marca produto como bipado no provider (atualiza estado local)
    await ref
        .read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier)
        .marcarProdutoBipado();

    _mostrarSucesso('Quantidade conferida: $qtConferida UN');

    // Foca no campo de unitizador
    if (mounted) _unitizadorFocusNode.requestFocus();
  }

  Future<void> _vincularUnitizador(OsDetalhe os) async {
    // Evita chamadas duplicadas
    if (_isProcessing) return;

    final codigo = _unitizadorController.text.trim();
    if (codigo.isEmpty) {
      if (mounted) _mostrarErro('Bipe a etiqueta do unitizador');
      return;
    }

    // Verifica se tem os dados de conferência antes de prosseguir
    if (_qtConferida == null ||
        _caixasConferidas == null ||
        _unidadesConferidas == null) {
      if (mounted)
        _mostrarErro(
          'Erro: quantidade não conferida. Bipe o produto novamente.',
        );
      return;
    }

    if (!mounted) return;
    setState(() => _isProcessing = true);

    // Chama o método que faz tudo junto: vincula + finaliza
    final (sucesso, erro) = await ref
        .read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier)
        .vincularUnitizadorEFinalizar(
          codigoBarrasUnitizador: codigo,
          qtConferida: _qtConferida!,
          caixas: _caixasConferidas!,
          unidades: _unidadesConferidas!,
        );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (sucesso) {
      _unitizadorController.clear();
      _mostrarSucesso('Tarefa finalizada!');
      // Volta para OsEnderecoScreen que vai propagar o resultado
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      _mostrarErro(erro ?? 'Erro ao finalizar');
    }
  }

  Future<void> _finalizarOs(OsDetalhe os) async {
    // Usa os dados em cache da conferência de quantidade
    if (_qtConferida == null ||
        _caixasConferidas == null ||
        _unidadesConferidas == null) {
      _mostrarErro('Erro: quantidade não conferida');
      return;
    }

    if (!mounted) return;
    setState(() => _isProcessing = true);

    // Finaliza com quantidade normal
    final resultado = await ref
        .read(osDetalheNotifierProvider(widget.fase, widget.numos).notifier)
        .finalizarComQuantidade(
          _qtConferida!,
          _caixasConferidas!,
          _unidadesConferidas!,
        );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    final (sucesso, erro) = resultado;
    if (sucesso && mounted) {
      _mostrarSucesso('Tarefa finalizada!');
      Navigator.of(context).pop(true);
    } else if (mounted) {
      _mostrarErro(erro ?? 'Erro ao finalizar');
    }
  }

  void _mostrarDialogBloquear(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final motivoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de arraste
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ícone de alerta ou loading
                    if (isLoading) ...[
                      const SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Bloqueando...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aguarde, processando sua solicitação',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.block_rounded,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Título
                      Text(
                        'Bloquear Tarefa?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Descrição
                      Text(
                        'A tarefa será bloqueada e voltará para a fila.\nEsta ação pode ser desfeita pelo supervisor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo de motivo
                      TextField(
                        controller: motivoController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Motivo do bloqueio *',
                          hintText: 'Descreva o motivo do bloqueio...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Botões
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Cancelar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final motivo = motivoController.text.trim();
                                if (motivo.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Informe o motivo do bloqueio',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isLoading = true);

                                final (sucesso, erro) = await ref
                                    .read(
                                      osDetalheNotifierProvider(
                                        widget.fase,
                                        widget.numos,
                                      ).notifier,
                                    )
                                    .bloquear(motivo);

                                if (!mounted) return;
                                Navigator.of(ctx).pop();

                                if (sucesso) {
                                  _mostrarSucesso('Tarefa bloqueada!');
                                  Navigator.of(this.context).pop(true);
                                } else {
                                  _mostrarErro(erro ?? 'Erro ao bloquear');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Bloquear',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
  }

  void _mostrarDialogDivergencia(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final observacaoController = TextEditingController();
    String? tipoSelecionado;

    // Tipos de divergência conforme API
    final tiposDivergencia = [
      {'value': 'quantidade_menor', 'label': 'Quantidade Menor'},
      {'value': 'quantidade_maior', 'label': 'Quantidade Maior'},
      {'value': 'produto_errado', 'label': 'Produto Errado'},
      {'value': 'nao_encontrado', 'label': 'Não Encontrado'},
      {'value': 'outro', 'label': 'Outro (especificar)'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isOutro = tipoSelecionado == 'outro';

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de arraste
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ícone de alerta
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 40,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Título
                    Text(
                      'Sinalizar Divergência',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Descrição
                    Text(
                      'Selecione o tipo da divergência encontrada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dropdown de tipo
                    DropdownButtonFormField<String>(
                      value: tipoSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Tipo da divergência *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade50,
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: Colors.orange.shade300,
                        ),
                      ),
                      dropdownColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                      items: tiposDivergencia.map((tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo['value'] as String,
                          child: Text(tipo['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          tipoSelecionado = value;
                          // Limpa observação se mudar de "outro" para outro tipo
                          if (value != 'outro') {
                            observacaoController.clear();
                          }
                        });
                      },
                    ),

                    // Campo de observação (só aparece se for "outro")
                    if (isOutro) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: observacaoController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Descreva a divergência *',
                          hintText: 'Informe detalhes da divergência...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade50,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 48),
                            child: Icon(
                              Icons.edit_note,
                              color: Colors.orange.shade300,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Cancelar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              if (tipoSelecionado == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Selecione o tipo da divergência',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              final observacao = observacaoController.text
                                  .trim();

                              // Se for "outro", observação é obrigatória
                              if (tipoSelecionado == 'outro' &&
                                  observacao.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Descreva a divergência'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              Navigator.of(ctx).pop();
                              final (sucesso, erro) = await ref
                                  .read(
                                    osDetalheNotifierProvider(
                                      widget.fase,
                                      widget.numos,
                                    ).notifier,
                                  )
                                  .sinalizarDivergencia(
                                    tipoSelecionado!,
                                    observacao.isNotEmpty ? observacao : null,
                                  );
                              if (sucesso && mounted) {
                                _mostrarSucesso('Divergência sinalizada!');
                              } else {
                                _mostrarErro(erro ?? 'Erro ao sinalizar');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Confirmar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
      ),
    );
  }

  void _mostrarEstoques(BuildContext context, int codprod, String descricao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory, color: Colors.blue[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESTOQUES DO PRODUTO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Cód: $codprod',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            // Descrição do produto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                descricao,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Lista de estoques
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final estoquesAsync = ref.watch(
                    consultaEstoqueProvider(codprod),
                  );
                  return estoquesAsync.when(
                    data: (estoques) {
                      if (estoques.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum estoque encontrado',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Calcula total
                      final total = estoques.fold<double>(
                        0,
                        (sum, e) => sum + e.quantidade,
                      );

                      return Column(
                        children: [
                          // Total
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.summarize, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'TOTAL EM ESTOQUE: ',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${total.toStringAsFixed(0)} UN',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Header da lista
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'ENDEREÇO',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'QTD',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),

                          // Lista
                          Expanded(
                            child: ListView.builder(
                              itemCount: estoques.length,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemBuilder: (_, i) {
                                final e = estoques[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      // Ícone de localização
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.location_on,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Endereço
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e.endereco.isNotEmpty
                                                  ? e.endereco
                                                  : '${e.rua}.${e.predio.toString().padLeft(2, '0')}.${e.nivel.toString().padLeft(2, '0')}.${e.apto.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Rua ${e.rua}',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Quantidade
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[700],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          e.quantidade.toStringAsFixed(0),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao carregar estoques',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarCalculadora(BuildContext context, OsDetalhe os) {
    final ctrlUn = TextEditingController();
    final ctrlCx = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.calculate, color: Colors.amber[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('CALCULADORA', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info do múltiplo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '1 CX = ${os.multiplo} UN',
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Campos de conversão
              Row(
                children: [
                  // Campo Unidades
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'UNIDADES',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: ctrlUn,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            final un = int.tryParse(value) ?? 0;
                            final cx = os.multiplo > 0
                                ? (un / os.multiplo)
                                : 0.0;
                            ctrlCx.text = cx.toStringAsFixed(2);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Ícone de conversão
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.swap_horiz,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  // Campo Caixas
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'CAIXAS',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: ctrlCx,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (value) {
                            final cx =
                                double.tryParse(value.replaceAll(',', '.')) ??
                                0;
                            final un = (cx * os.multiplo).round();
                            ctrlUn.text = un.toString();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Botões de atalho
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [1, 2, 5, 10].map((cx) {
                  return ActionChip(
                    label: Text('$cx CX'),
                    onPressed: () {
                      ctrlCx.text = cx.toString();
                      ctrlUn.text = (cx * os.multiplo).toString();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  void _mostrarSucesso(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _mostrarDialogSairOs(BuildContext context) {
    final matriculaController = TextEditingController();
    final senhaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.exit_to_app,
                          color: Colors.red.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SAIR DA OS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Autorização necessária',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Aviso
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Para sair desta OS é necessária autorização de um supervisor.',
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Campo matrícula
                  TextFormField(
                    controller: matriculaController,
                    decoration: InputDecoration(
                      labelText: 'Matrícula do Supervisor',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a matrícula';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Campo senha
                  TextFormField(
                    controller: senhaController,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a senha';
                      }
                      return null;
                    },
                  ),

                  // Erro
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
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
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pop(sheetContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('CANCELAR'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;

                                  setSheetState(() {
                                    isLoading = true;
                                    errorMessage = null;
                                  });

                                  try {
                                    final (sucesso, erro) = await ref
                                        .read(
                                          osDetalheNotifierProvider(
                                            widget.fase,
                                            widget.numos,
                                          ).notifier,
                                        )
                                        .sairDaOs(
                                          int.parse(matriculaController.text),
                                          senhaController.text,
                                        );

                                    if (sucesso) {
                                      if (sheetContext.mounted) {
                                        Navigator.pop(sheetContext);
                                      }
                                      if (mounted) {
                                        Navigator.of(
                                          context,
                                        ).popUntil((route) => route.isFirst);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Saída da OS autorizada com sucesso',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } else {
                                      setSheetState(() {
                                        isLoading = false;
                                        errorMessage =
                                            erro?.replaceAll(
                                              'Exception: ',
                                              '',
                                            ) ??
                                            'Erro ao sair da OS';
                                      });
                                    }
                                  } catch (e) {
                                    setSheetState(() {
                                      isLoading = false;
                                      errorMessage = e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      );
                                    });
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'SAIR DA OS',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
