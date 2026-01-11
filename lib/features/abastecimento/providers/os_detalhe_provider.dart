import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/os_detalhe_model.dart';
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
    final response = await apiService.get('/wms/fase1/os/$numos');

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
      ),
      enderecoDestino: EnderecoOs(
        rua: enderecoDestinoData['rua']?.toString() ?? '',
        predio: _parseInt(enderecoDestinoData['predio']) ?? 0,
        nivel: _parseInt(enderecoDestinoData['nivel']) ?? 0,
        apto: _parseInt(enderecoDestinoData['apto']) ?? 0,
        enderecoFormatado: enderecoDestinoData['endereco']?.toString() ?? '',
      ),
      status: osData['status']?.toString() ?? 'PENDENTE',
      produtoBipado: osData['produto_bipado'] == true,
      unitizadorVinculado: osData['codunitizador'] != null,
      codunitizador: osData['codunitizador']?.toString(),
    );
  }

  // Helpers para parsing seguro
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String)
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
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
  // Retorna (sucesso, mensagemErro, osEmAndamento)
  Future<(bool, String?, int?)> iniciarOs() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase1/os/$numos/iniciar', {});
      return (true, null, null);
    } catch (e) {
      final errorStr = e.toString();
      final errorMsg = _extrairMensagemErro(e);

      // Se já está em andamento, considera sucesso (pode continuar)
      if (errorMsg.contains('FASE1_ANDAMENTO') ||
          errorMsg.contains('já está em andamento')) {
        return (true, null, null);
      }

      // Se tem outra OS em andamento, extrai o número dela
      final osMatch = RegExp(
        r'OS (\d+) em andamento|os_em_andamento.*?(\d+)',
      ).firstMatch(errorStr);
      if (osMatch != null) {
        final osNum = int.tryParse(osMatch.group(1) ?? osMatch.group(2) ?? '');
        return (false, errorMsg, osNum);
      }

      return (false, errorMsg, null);
    }
  }

  // Sair da OS (requer autorização de supervisor)
  Future<(bool, String?)> sairDaOs(
    int autorizadorMatricula,
    String autorizadorSenha,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase1/os/$numos/sair', {
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
  Future<(bool, String?)> biparEndereco(String codigoEndereco) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase1/os/$numos/bipar-endereco', {
        'codigo_endereco': codigoEndereco,
      });
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  // Bipar produto (validar código de barras) - versão simples (mantida para compatibilidade)
  // Retorna (sucesso, mensagemErro)
  Future<(bool, String?)> biparProduto(String codigoBarras) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase1/os/$numos/bipar', {
        'codigo_barras': codigoBarras,
      });

      // Atualiza estado local
      state = AsyncValue.data(state.value!.copyWith(produtoBipado: true));
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
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

      await apiService.post('/wms/fase1/os/$numos/bipar', {
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
      await apiService.post('/wms/fase1/os/$numos/bipar', {
        'codigo_barras': codigoBarras,
      });

      // Produto válido, agora finaliza com a quantidade conferida
      await apiService.post('/wms/fase1/os/$numos/finalizar', {
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
      await apiService.post('/wms/fase1/os/$numos/vincular-unitizador', {
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

  // Finalizar OS com quantidade conferida
  Future<(bool, String?)> finalizarComQuantidade(
    int qtConferida,
    int caixas,
    int unidades,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase1/os/$numos/finalizar', {
        'qt_conferida': qtConferida,
        'caixas': caixas,
        'unidades': unidades,
      });
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  // Finalizar OS (versão antiga - mantida para compatibilidade)
  Future<(bool, String?)> finalizar(double quantidade) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase1/os/$numos/finalizar', {
        'quantidade': quantidade,
      });
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  // Bloquear OS
  Future<(bool, String?)> bloquear(String motivo) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase1/os/$numos/bloquear', {
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
    String descricao,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase1/os/$numos/divergencia', {
        'tipo': tipo,
        'descricao': descricao,
      });

      state = AsyncValue.data(state.value!.copyWith(divergencia: descricao));
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  // Extrai mensagem de erro da exceção
  String _extrairMensagemErro(dynamic e) {
    final errorStr = e.toString();

    // Tenta extrair mensagem JSON
    final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(errorStr);
    if (msgMatch != null) {
      return msgMatch.group(1) ?? 'Erro desconhecido';
    }

    // Se não encontrou JSON, retorna string limpa
    if (errorStr.contains('ApiException:')) {
      return errorStr.replaceAll('ApiException:', '').trim();
    }

    return errorStr;
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
