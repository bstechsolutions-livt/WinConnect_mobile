import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/providers/api_service_provider.dart';

part 'fase2_provider.g.dart';

// ============================================
// MODELS
// ============================================

class RuaFase2 {
  final String rua;
  final int totalUnitizadores;
  final int totalItens;

  RuaFase2({
    required this.rua,
    required this.totalUnitizadores,
    required this.totalItens,
  });

  factory RuaFase2.fromJson(Map<String, dynamic> json) {
    return RuaFase2(
      rua: json['rua']?.toString() ?? '',
      totalUnitizadores: _parseToInt(json['total_unitizadores']),
      totalItens: _parseToInt(json['total_itens']),
    );
  }
  
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

class Unitizador {
  final int id;
  final String codigo;
  final String codigoBarras;
  final String status;
  final int totalItens;
  final int itensConferidos;
  final int itensEntregues;

  Unitizador({
    required this.id,
    required this.codigo,
    required this.codigoBarras,
    required this.status,
    required this.totalItens,
    required this.itensConferidos,
    required this.itensEntregues,
  });

  factory Unitizador.fromJson(Map<String, dynamic> json) {
    return Unitizador(
      id: _parseToInt(json['id']),
      codigo: json['codigo']?.toString() ?? json['codunitizador']?.toString() ?? '',
      codigoBarras: json['codigo_barras']?.toString() ?? json['codunitizador']?.toString() ?? '',
      status: json['status']?.toString() ?? 'disponivel',
      totalItens: _parseToInt(json['total_itens'] ?? json['qtd_itens']),
      itensConferidos: _parseToInt(json['itens_conferidos']),
      itensEntregues: _parseToInt(json['itens_entregues']),
    );
  }
  
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  int get itensPendentes => totalItens - itensConferidos;
}

class ItemUnitizador {
  final int numos;
  final int codprod;
  final String descricao;
  final String? codauxiliar;
  final String embalagem;
  final String unidade;
  final int qt;
  final bool conferido;
  final bool bloqueado;
  final int tentativas;

  ItemUnitizador({
    required this.numos,
    required this.codprod,
    required this.descricao,
    this.codauxiliar,
    required this.embalagem,
    required this.unidade,
    required this.qt,
    required this.conferido,
    required this.bloqueado,
    required this.tentativas,
  });

  factory ItemUnitizador.fromJson(Map<String, dynamic> json) {
    return ItemUnitizador(
      numos: _parseToInt(json['numos']),
      codprod: _parseToInt(json['codprod']),
      descricao: json['descricao']?.toString() ?? '',
      codauxiliar: json['codauxiliar']?.toString(),
      embalagem: json['embalagem']?.toString() ?? 'UN',
      unidade: json['unidade']?.toString() ?? 'UN',
      qt: _parseToInt(json['qt']),
      conferido: json['conferido'] == true || json['conferido'] == 1 || json['conferido'] == '1',
      bloqueado: json['bloqueado'] == true || json['bloqueado'] == 1 || json['bloqueado'] == '1',
      tentativas: _parseToInt(json['tentativas']),
    );
  }
  
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

class ItemCarrinho {
  final int numos;
  final int codprod;
  final String descricao;
  final int qt;
  final String enderecoDestino;
  final DateTime? conferidoEm;

  ItemCarrinho({
    required this.numos,
    required this.codprod,
    required this.descricao,
    required this.qt,
    required this.enderecoDestino,
    this.conferidoEm,
  });

  factory ItemCarrinho.fromJson(Map<String, dynamic> json) {
    return ItemCarrinho(
      numos: _parseToInt(json['numos']),
      codprod: _parseToInt(json['codprod']),
      descricao: json['descricao']?.toString() ?? '',
      qt: _parseToInt(json['qt']),
      enderecoDestino: json['endereco_destino']?.toString() ?? '',
      conferidoEm: json['conferido_em'] != null
          ? DateTime.tryParse(json['conferido_em'].toString())
          : null,
    );
  }
  
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

class ItemRota {
  final int ordem;
  final int numos;
  final int codprod;
  final String descricao;
  final int qt;
  final EnderecoDestino endereco;

  ItemRota({
    required this.ordem,
    required this.numos,
    required this.codprod,
    required this.descricao,
    required this.qt,
    required this.endereco,
  });

  factory ItemRota.fromJson(Map<String, dynamic> json) {
    return ItemRota(
      ordem: json['ordem'] ?? 0,
      numos: json['numos'] ?? 0,
      codprod: json['codprod'] ?? 0,
      descricao: json['descricao'] ?? '',
      qt: json['qt'] ?? 0,
      endereco: EnderecoDestino.fromJson(json['endereco'] ?? {}),
    );
  }
}

class EnderecoDestino {
  final int codendereco;
  final String endereco;
  final String rua;
  final int predio;
  final int nivel;
  final int apto;

  EnderecoDestino({
    required this.codendereco,
    required this.endereco,
    required this.rua,
    required this.predio,
    required this.nivel,
    required this.apto,
  });

  factory EnderecoDestino.fromJson(Map<String, dynamic> json) {
    return EnderecoDestino(
      codendereco: json['codendereco'] ?? 0,
      endereco: json['endereco'] ?? '',
      rua: json['rua'] ?? '',
      predio: json['predio'] ?? 0,
      nivel: json['nivel'] ?? 0,
      apto: json['apto'] ?? 0,
    );
  }
}

// ============================================
// PROVIDERS
// ============================================

/// Provider para listar ruas da Fase 2
@riverpod
class RuasFase2Notifier extends _$RuasFase2Notifier {
  @override
  Future<List<RuaFase2>> build() async {
    return _fetchRuas();
  }

  Future<List<RuaFase2>> _fetchRuas() async {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.get('/wms/fase2/ruas');
    final lista = response['ruas'] as List? ?? [];
    return lista.map((e) => RuaFase2.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchRuas());
  }
}

/// Provider para listar unitizadores de uma rua
@riverpod
class UnitizadoresFase2Notifier extends _$UnitizadoresFase2Notifier {
  @override
  Future<List<Unitizador>> build(String rua) async {
    return _fetchUnitizadores();
  }

  Future<List<Unitizador>> _fetchUnitizadores() async {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.get('/wms/fase2/ruas/$rua/unitizadores');
    final lista = response['unitizadores'] as List? ?? [];
    return lista.map((e) => Unitizador.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchUnitizadores());
  }
}

/// Provider para gerenciar o unitizador selecionado e seus itens
@Riverpod(keepAlive: true)
class UnitizadorSelecionadoNotifier extends _$UnitizadorSelecionadoNotifier {
  @override
  ({Unitizador? unitizador, List<ItemUnitizador> itens, int totalConferidos})
      build() {
    return (unitizador: null, itens: [], totalConferidos: 0);
  }

  /// Bipa/seleciona um unitizador pelo código de barras
  Future<(bool, String?)> biparUnitizador(String codigoBarras) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post('/wms/fase2/unitizador/bipar', {
        'codigo_barras': codigoBarras,
      });

      final unitizador = Unitizador.fromJson(response['unitizador'] ?? {});
      final itens = (response['itens'] as List? ?? [])
          .map((e) => ItemUnitizador.fromJson(e))
          .toList();
      final totalConferidos = response['total_conferidos'] ?? 0;

      state = (
        unitizador: unitizador,
        itens: itens,
        totalConferidos: totalConferidos
      );

      return (true, null);
    } catch (e) {
      return (false, e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Confere um produto (conferência cega)
  Future<(bool, String?, Map<String, dynamic>?)> conferirProduto(
    int numos,
    String codigoBarras,
    int quantidade,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response =
          await apiService.post('/wms/fase2/os/$numos/conferir-produto', {
        'codigo_barras': codigoBarras,
        'quantidade': quantidade.toString(),
      });

      // Atualiza a lista de itens (marca como conferido)
      final itensAtualizados = state.itens.map((item) {
        if (item.numos == numos) {
          return ItemUnitizador(
            numos: item.numos,
            codprod: item.codprod,
            descricao: item.descricao,
            codauxiliar: item.codauxiliar,
            embalagem: item.embalagem,
            unidade: item.unidade,
            qt: item.qt,
            conferido: true,
            bloqueado: item.bloqueado,
            tentativas: item.tentativas,
          );
        }
        return item;
      }).toList();

      state = (
        unitizador: state.unitizador,
        itens: itensAtualizados,
        totalConferidos: state.totalConferidos + 1
      );

      return (true, response['message']?.toString(), response);
    } catch (e) {
      return (false, e.toString().replaceAll('Exception: ', ''), null);
    }
  }

  void limpar() {
    state = (unitizador: null, itens: [], totalConferidos: 0);
  }
}

/// Provider para o carrinho do operador
@Riverpod(keepAlive: true)
class CarrinhoNotifier extends _$CarrinhoNotifier {
  @override
  Future<List<ItemCarrinho>> build() async {
    return _fetchCarrinho();
  }

  Future<List<ItemCarrinho>> _fetchCarrinho() async {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.get('/wms/fase2/meu-carrinho');
    final lista = response['itens'] as List? ?? [];
    return lista.map((e) => ItemCarrinho.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchCarrinho());
  }
}

/// Provider para a rota calculada
@Riverpod(keepAlive: true)
class RotaEntregaNotifier extends _$RotaEntregaNotifier {
  @override
  ({List<ItemRota> rota, int totalItens}) build() {
    return (rota: [], totalItens: 0);
  }

  /// Calcula a rota de entrega
  Future<(bool, String?)> calcularRota() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post('/wms/fase2/calcular-rota', {});

      final rota = (response['rota'] as List? ?? [])
          .map((e) => ItemRota.fromJson(e))
          .toList();
      final totalItens = response['total_itens'] ?? 0;

      state = (rota: rota, totalItens: totalItens);
      return (true, null);
    } catch (e) {
      return (false, e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Obtém a próxima entrega da rota
  Future<ItemRota?> proximaEntrega() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/wms/fase2/proxima-entrega');
      return ItemRota.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Confirma a entrega de uma OS
  Future<(bool, String?, int)> confirmarEntrega(
    int numos,
    String enderecoConfirmado,
  ) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response =
          await apiService.post('/wms/fase2/os/$numos/confirmar-entrega', {
        'endereco_confirmado': enderecoConfirmado,
      });

      // Remove da rota
      final rotaAtualizada =
          state.rota.where((item) => item.numos != numos).toList();
      final itensRestantes = response['itens_restantes'] ?? rotaAtualizada.length;

      state = (rota: rotaAtualizada, totalItens: itensRestantes);

      return (true, response['message']?.toString(), itensRestantes as int);
    } catch (e) {
      return (false, e.toString().replaceAll('Exception: ', ''), state.totalItens);
    }
  }

  void limpar() {
    state = (rota: [], totalItens: 0);
  }
}
