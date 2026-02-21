import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/os_detalhe_model.dart';
import '../../../shared/models/finalizacao_result_model.dart';
import '../../../shared/providers/api_service_provider.dart';

part 'os_detalhe_provider.g.dart';

@Riverpod(keepAlive: false)
class OsDetalheNotifier extends _$OsDetalheNotifier {
  @override
  Future<OsDetalhe> build(int fase, int numos) async {
    return _loadOsDetalhe(fase, numos);
  }

  Future<OsDetalhe> _loadOsDetalhe(int fase, int numos) async {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.get('/wms/fase$fase/os/$numos');

    // A API retorna: { os: {...}, produto: {...}, endereco_origem: {...}, estoque_atual: ... }
    final osData = response['os'] ?? {};
    final produtoData = response['produto'] ?? {};
    final enderecoOrigemData = response['endereco_origem'] ?? {};
    final enderecoDestinoData = response['endereco_destino'] ?? {};
    final estoqueAtual = response['estoque_atual'];

    return OsDetalhe(
      numos: _parseInt(osData['numos']) ?? numos,
      codprod:
          _parseInt(produtoData['codprod']) ??
          _parseInt(osData['codprod']) ??
          0,
      codauxiliar: produtoData['codauxiliar']?.toString() ?? '',
      codauxiliar2: produtoData['codauxiliar2']?.toString(),
      descricao: produtoData['descricao']?.toString() ?? 'Produto',
      unidade: produtoData['unidade']?.toString() ?? 'UN',
      multiplo: _parseInt(produtoData['qtunitcx']) ?? 1,
      qtSolicitada: _parseDouble(osData['qt']) ?? 0.0,
      qtEstoqueAtual: _parseDouble(estoqueAtual) ?? 0.0,
      enderecoOrigem: EnderecoOs(
        rua:
            enderecoOrigemData['rua']?.toString() ??
            osData['rua']?.toString() ??
            '',
        predio: _parseInt(enderecoOrigemData['predio']) ?? 0,
        nivel: _parseInt(enderecoOrigemData['nivel']) ?? 0,
        apto: _parseInt(enderecoOrigemData['apto']) ?? 0,
        enderecoFormatado: enderecoOrigemData['endereco']?.toString() ?? '',
        codendereco: _parseInt(enderecoOrigemData['codendereco']),
      ),
      enderecoDestino: EnderecoOs(
        rua: enderecoDestinoData['rua']?.toString() ?? '',
        predio: _parseInt(enderecoDestinoData['predio']) ?? 0,
        nivel: _parseInt(enderecoDestinoData['nivel']) ?? 0,
        apto: _parseInt(enderecoDestinoData['apto']) ?? 0,
        enderecoFormatado: enderecoDestinoData['endereco']?.toString() ?? '',
      ),
      status: osData['status']?.toString() ?? 'PENDENTE',
      // SEMPRE inicia com produtoBipado: false - operador recomeça do zero
      produtoBipado: false,
      unitizadorVinculado: false,
      codunitizador: null,
    );
  }

  // Helpers para parsing seguro
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Iniciar OS (deve ser chamado antes de bipar)
  // Retorna IniciarOsResult com informações detalhadas sobre o resultado
  Future<IniciarOsResult> iniciarOs() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post(
        '/wms/fase$fase/os/$numos/iniciar',
        {},
      );
      final rua = response['rua']?.toString();
      return IniciarOsResult.success(rua: rua);
    } catch (e) {
      final errorStr = e.toString();
      final errorMsg = _extrairMensagemErro(e);

      // Se já está em andamento, considera sucesso (pode continuar)
      if (errorMsg.contains('FASE1_ANDAMENTO') ||
          errorMsg.contains('já está em andamento')) {
        return IniciarOsResult.success();
      }

      // Verifica se é erro de "preso em outra rua" (status 422)
      // A mensagem contém "Você está alocado na Rua X"
      final ruaMatch = RegExp(
        r'[Vv]ocê está alocado na [Rr]ua\s+(\w+)|alocado.*?[Rr]ua\s+(\w+)',
      ).firstMatch(errorStr);
      if (ruaMatch != null) {
        final ruaBloqueada = ruaMatch.group(1) ?? ruaMatch.group(2) ?? '';
        return IniciarOsResult.presoEmRua(ruaBloqueada, errorMsg);
      }

      // Se tem outra OS em andamento, extrai o número dela
      final osMatch = RegExp(
        r'OS (\d+) em andamento|os_em_andamento.*?(\d+)',
      ).firstMatch(errorStr);
      if (osMatch != null) {
        final osNum = int.tryParse(osMatch.group(1) ?? osMatch.group(2) ?? '');
        return IniciarOsResult.error(errorMsg, osEmAndamento: osNum);
      }

      return IniciarOsResult.error(errorMsg);
    }
  }

  // Versão antiga para compatibilidade - converte para tuple
  Future<(bool, String?, int?)> iniciarOsLegacy() async {
    final result = await iniciarOs();
    if (result.sucesso) {
      return (true, null, null);
    }
    return (false, result.erro, result.osEmAndamento);
  }

  // Sair da OS (requer autorização de supervisor)
  Future<(bool, String?)> sairDaOs(
    int autorizadorMatricula,
    String autorizadorSenha,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase$fase/os/$numos/sair', {
        'autorizador_matricula': autorizadorMatricula,
        'autorizador_senha': autorizadorSenha,
      });
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  // Bipar endereço de origem
  // Retorna (sucesso, mensagemErro)
  // Parâmetros opcionais para rastreabilidade:
  // - digitado: true se foi digitado manualmente
  // - autorizadorMatricula: matrícula de quem autorizou
  Future<(bool, String?)> biparEndereco(
    String codigoEndereco, {
    bool digitado = false,
    int? autorizadorMatricula,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase$fase/os/$numos/bipar-endereco', {
        'codigo_endereco': codigoEndereco,
        'digitado': digitado,
        if (digitado && autorizadorMatricula != null)
          'autorizador_matricula': autorizadorMatricula,
      });
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  // Bipar produto (validar código de barras)
  // APENAS valida, NÃO atualiza estado local (o estado só muda ao finalizar)
  // Retorna BiparProdutoResult com tipo ('caixa' ou 'unidade') e qtunitcx
  // Parâmetros opcionais para rastreabilidade:
  // - digitado: true se foi digitado manualmente
  // - autorizadorMatricula: matrícula de quem autorizou
  Future<BiparProdutoResult> biparProdutoComTipo(
    String codigoBarras, {
    bool digitado = false,
    int? autorizadorMatricula,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post('/wms/fase$fase/os/$numos/bipar', {
        'codigo_barras': codigoBarras,
        'digitado': digitado,
        if (digitado && autorizadorMatricula != null)
          'autorizador_matricula': autorizadorMatricula,
      });

      // API retorna: { tipo: 'caixa'|'unidade', qtunitcx: N }
      final tipo = response['tipo']?.toString() ?? 'unidade';
      final qtunitcx = (response['qtunitcx'] as num?)?.toInt() ?? 1;

      return BiparProdutoResult.success(tipo: tipo, qtunitcx: qtunitcx);
    } catch (e) {
      return BiparProdutoResult.error(_extrairMensagemErro(e));
    }
  }

  // Versão legada para compatibilidade
  // Retorna (sucesso, mensagemErro)
  Future<(bool, String?)> biparProduto(
    String codigoBarras, {
    bool digitado = false,
    int? autorizadorMatricula,
  }) async {
    final result = await biparProdutoComTipo(
      codigoBarras,
      digitado: digitado,
      autorizadorMatricula: autorizadorMatricula,
    );
    return (result.sucesso, result.erro);
  }

  // Marca produto como bipado (apenas atualiza estado local)
  // Chamado após conferência de quantidade, antes de vincular unitizador
  Future<void> marcarProdutoBipado({String? tipoBipado}) async {
    state = AsyncValue.data(state.value!.copyWith(
      produtoBipado: true,
      tipoBipado: tipoBipado,
    ));
  }

  // Bipar produto COM conferência de quantidade
  // Retorna (sucesso, mensagemErro)
  Future<(bool, String?)> biparProdutoComQuantidade(
    String codigoBarras,
    int caixas,
    int unidades,
    int multiplo,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);

      // Calcula a quantidade total em unidades
      final quantidadeTotal = (caixas * multiplo) + unidades;

      await apiService.post('/wms/fase$fase/os/$numos/bipar', {
        'codigo_barras': codigoBarras,
        'caixas': caixas,
        'unidades': unidades,
        'quantidade_conferida': quantidadeTotal,
      });

      // Atualiza estado local
      state = AsyncValue.data(state.value!.copyWith(produtoBipado: true));
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  // Bipar produto e já finalizar a OS em uma única operação
  // Retorna (sucesso, mensagemErro)
  Future<(bool, String?)> biparProdutoEFinalizar(
    String codigoBarras,
    int caixas,
    int unidades,
    int multiplo,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);

      // Calcula a quantidade total em unidades
      final quantidadeTotal = (caixas * multiplo) + unidades;

      // Primeiro valida o produto
      await apiService.post('/wms/fase$fase/os/$numos/bipar', {
        'codigo_barras': codigoBarras,
      });

      // Produto válido, agora finaliza com a quantidade conferida
      await apiService.post('/wms/fase$fase/os/$numos/finalizar', {
        'qt_conferida': quantidadeTotal,
        'caixas': caixas,
        'unidades': unidades,
      });

      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  // Vincular unitizador
  // Retorna (sucesso, mensagemErro)
  Future<(bool, String?)> vincularUnitizador(
    String codigoBarrasUnitizador,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase$fase/os/$numos/vincular-unitizador', {
        'codigo_barras_unitizador': codigoBarrasUnitizador,
      });

      // Atualiza estado local
      state = AsyncValue.data(
        state.value!.copyWith(
          unitizadorVinculado: true,
          codunitizador: codigoBarrasUnitizador,
        ),
      );
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  // Vincular unitizador E finalizar em uma única operação
  // Isso evita problemas de estado quando o widget é reconstruído
  // Retorna FinalizacaoResult com info sobre próxima OS
  Future<FinalizacaoResult> vincularUnitizadorEFinalizarComResult({
    required String codigoBarrasUnitizador,
    required int qtConferida,
    required int caixas,
    required int unidades,
    int? qtRetirada,
    int? codenderecoDevolucao,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);

      // 1. Vincula o unitizador
      await apiService.post('/wms/fase$fase/os/$numos/vincular-unitizador', {
        'codigo_barras_unitizador': codigoBarrasUnitizador,
      });

      // 2. Finaliza a OS
      final body = <String, dynamic>{
        'qt_conferida': qtConferida,
        'caixas': caixas,
        'unidades': unidades,
      };
      if (qtRetirada != null && qtRetirada > qtConferida) {
        body['qt_retirada'] = qtRetirada;
      }
      if (codenderecoDevolucao != null) {
        body['codendereco_devolucao'] = codenderecoDevolucao;
      }
      final response = await apiService.post(
        '/wms/fase$fase/os/$numos/finalizar',
        body,
      );

      return FinalizacaoResult.fromResponse(response);
    } catch (e) {
      final errorMsg = _extrairMensagemErro(e);
      final deveRegistrarDivergencia = _verificarDeveRegistrarDivergencia(e);
      return FinalizacaoResult.error(
        errorMsg,
        deveRegistrarDivergencia: deveRegistrarDivergencia,
      );
    }
  }

  // Versão antiga para compatibilidade
  Future<(bool, String?)> vincularUnitizadorEFinalizar({
    required String codigoBarrasUnitizador,
    required int qtConferida,
    required int caixas,
    required int unidades,
  }) async {
    final result = await vincularUnitizadorEFinalizarComResult(
      codigoBarrasUnitizador: codigoBarrasUnitizador,
      qtConferida: qtConferida,
      caixas: caixas,
      unidades: unidades,
    );
    return (result.sucesso, result.erro);
  }

  // Finalizar OS com quantidade conferida - retorna FinalizacaoResult
  Future<FinalizacaoResult> finalizarComQuantidadeResult(
    int qtConferida,
    int caixas,
    int unidades, {
    int? qtRetirada,
    int? codenderecoDevolucao,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final body = <String, dynamic>{
        'qt_conferida': qtConferida,
        'caixas': caixas,
        'unidades': unidades,
      };
      if (qtRetirada != null && qtRetirada > qtConferida) {
        body['qt_retirada'] = qtRetirada;
      }
      if (codenderecoDevolucao != null) {
        body['codendereco_devolucao'] = codenderecoDevolucao;
      }
      final response = await apiService.post(
        '/wms/fase$fase/os/$numos/finalizar',
        body,
      );
      return FinalizacaoResult.fromResponse(response);
    } catch (e) {
      final errorMsg = _extrairMensagemErro(e);
      final deveRegistrarDivergencia = _verificarDeveRegistrarDivergencia(e);
      return FinalizacaoResult.error(
        errorMsg,
        deveRegistrarDivergencia: deveRegistrarDivergencia,
      );
    }
  }

  // Versão antiga para compatibilidade
  Future<(bool, String?)> finalizarComQuantidade(
    int qtConferida,
    int caixas,
    int unidades,
  ) async {
    final result = await finalizarComQuantidadeResult(
      qtConferida,
      caixas,
      unidades,
    );
    return (result.sucesso, result.erro);
  }

  // Verifica se o erro indica que deve registrar divergência
  bool _verificarDeveRegistrarDivergencia(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    return errorStr.contains('deve_registrar_divergencia') ||
        errorStr.contains('registrar divergência') ||
        errorStr.contains('quantidade diferente');
  }

  // Finalizar OS (versão antiga - mantida para compatibilidade)
  Future<(bool, String?)> finalizar(double quantidade) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase$fase/os/$numos/finalizar', {
        'quantidade': quantidade,
      });
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  /// Valida endereço para devolução de sobra.
  /// Retorna mapa com codendereco, endereco_formatado, is_origem, etc.
  Future<ValidarEnderecoResult> validarEnderecoDevolucao(
    String codigoEndereco,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post(
        '/wms/fase$fase/os/$numos/validar-endereco-devolucao',
        {'codigo_endereco': codigoEndereco},
      );
      return ValidarEnderecoResult.success(
        codendereco: (response['codendereco'] as num).toInt(),
        enderecoFormatado: response['endereco_formatado']?.toString() ?? '',
        isOrigem: response['is_origem'] == true,
      );
    } catch (e) {
      return ValidarEnderecoResult.error(_extrairMensagemErro(e));
    }
  }

  // Bloquear OS
  Future<(bool, String?)> bloquear(String motivo) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase$fase/os/$numos/bloquear', {
        'motivo': motivo,
      });
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  // Sinalizar divergência
  Future<(bool, String?)> sinalizarDivergencia(
    String tipo,
    String? observacao,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = <String, dynamic>{'tipo': tipo};
      if (observacao != null && observacao.isNotEmpty) {
        data['observacao'] = observacao;
      }
      await apiService.post('/wms/fase$fase/os/$numos/divergencia', data);

      state = AsyncValue.data(state.value!.copyWith(divergencia: tipo));
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  // Extrai mensagem de erro da exceção
  String _extrairMensagemErro(dynamic e) {
    final errorStr = e.toString();

    // Tenta extrair mensagem JSON - procura "message" em qualquer lugar
    final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(errorStr);
    if (msgMatch != null) {
      return msgMatch.group(1) ?? 'Erro desconhecido';
    }

    // Tenta extrair "error" do JSON
    final errorMatch = RegExp(r'"error"\s*:\s*"([^"]+)"').firstMatch(errorStr);
    if (errorMatch != null) {
      return errorMatch.group(1) ?? 'Erro desconhecido';
    }

    // Se não encontrou JSON, limpa a string
    String cleaned = errorStr;

    // Remove prefixos comuns de exceção
    if (cleaned.contains('DioException')) {
      // Extrai apenas a parte útil
      final match = RegExp(r'message[:\s]*([^\n\r{]+)').firstMatch(cleaned);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Erro de conexão';
      }
      return 'Erro de conexão com o servidor';
    }

    if (cleaned.contains('ApiException:')) {
      cleaned = cleaned.replaceAll(RegExp(r'ApiException:\s*'), '').trim();
    }

    if (cleaned.contains('Exception:')) {
      cleaned = cleaned.replaceAll(RegExp(r'Exception:\s*'), '').trim();
    }

    // Limita tamanho da mensagem para evitar texto gigante
    if (cleaned.length > 100) {
      cleaned = '${cleaned.substring(0, 100)}...';
    }

    return cleaned.isEmpty ? 'Erro desconhecido' : cleaned;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadOsDetalhe(fase, numos));
  }
}

// Provider para consulta de estoques do produto
@Riverpod(keepAlive: false)
Future<List<EstoqueProduto>> consultaEstoque(
  ConsultaEstoqueRef ref,
  int codprod,
) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.get('/wms/consulta-estoque/$codprod');

  final estoques = response['estoques'] as List? ?? [];
  return estoques
      .map(
        (item) => EstoqueProduto(
          rua: item['rua']?.toString() ?? '',
          endereco: item['endereco']?.toString() ?? '',
          predio: item['predio'] ?? 0,
          nivel: item['nivel'] ?? 0,
          apto: item['apto'] ?? 0,
          quantidade: double.tryParse(item['qt']?.toString() ?? '0') ?? 0.0,
        ),
      )
      .toList();
}

/// Resultado da operação de bipar produto
/// Retorna o tipo do código bipado ('caixa' ou 'unidade') e qtunitcx
class BiparProdutoResult {
  final bool sucesso;
  final String? erro;
  final String? tipo; // 'caixa' ou 'unidade'
  final int qtunitcx;

  const BiparProdutoResult._({
    required this.sucesso,
    this.erro,
    this.tipo,
    this.qtunitcx = 1,
  });

  factory BiparProdutoResult.success({
    required String tipo,
    required int qtunitcx,
  }) =>
      BiparProdutoResult._(
        sucesso: true,
        tipo: tipo,
        qtunitcx: qtunitcx,
      );

  factory BiparProdutoResult.error(String mensagem) => BiparProdutoResult._(
        sucesso: false,
        erro: mensagem,
      );

  /// Retorna true se o código bipado foi da CAIXA
  bool get isCaixa => tipo == 'caixa';

  /// Retorna true se o código bipado foi da UNIDADE
  bool get isUnidade => tipo == 'unidade';
}

/// Resultado da validação de endereço para devolução de sobra
class ValidarEnderecoResult {
  final bool sucesso;
  final String? erro;
  final int? codendereco;
  final String? enderecoFormatado;
  final bool isOrigem;

  const ValidarEnderecoResult._({
    required this.sucesso,
    this.erro,
    this.codendereco,
    this.enderecoFormatado,
    this.isOrigem = false,
  });

  factory ValidarEnderecoResult.success({
    required int codendereco,
    required String enderecoFormatado,
    required bool isOrigem,
  }) =>
      ValidarEnderecoResult._(
        sucesso: true,
        codendereco: codendereco,
        enderecoFormatado: enderecoFormatado,
        isOrigem: isOrigem,
      );

  factory ValidarEnderecoResult.error(String mensagem) =>
      ValidarEnderecoResult._(
        sucesso: false,
        erro: mensagem,
      );
}
