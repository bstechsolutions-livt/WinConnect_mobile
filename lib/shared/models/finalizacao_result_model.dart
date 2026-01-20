/// Modelo para resultado da finalização de OS
/// Contém informações sobre próxima OS e se a rua foi finalizada
class FinalizacaoResult {
  final bool sucesso;
  final String? erro;
  final ProximaOs? proximaOs;
  final bool ruaFinalizada;
  final bool deveRegistrarDivergencia;

  FinalizacaoResult({
    required this.sucesso,
    this.erro,
    this.proximaOs,
    this.ruaFinalizada = false,
    this.deveRegistrarDivergencia = false,
  });

  factory FinalizacaoResult.success({
    ProximaOs? proximaOs,
    bool ruaFinalizada = false,
  }) {
    return FinalizacaoResult(
      sucesso: true,
      proximaOs: proximaOs,
      ruaFinalizada: ruaFinalizada,
    );
  }

  factory FinalizacaoResult.error(
    String erro, {
    bool deveRegistrarDivergencia = false,
  }) {
    return FinalizacaoResult(
      sucesso: false,
      erro: erro,
      deveRegistrarDivergencia: deveRegistrarDivergencia,
    );
  }

  factory FinalizacaoResult.fromResponse(Map<String, dynamic> response) {
    ProximaOs? proximaOs;
    if (response['proxima_os'] != null) {
      proximaOs = ProximaOs.fromJson(response['proxima_os']);
    }

    // API retorna 'rua_concluida' ou 'rua_finalizada'
    final ruaFinalizada = response['rua_concluida'] == true || 
                          response['rua_finalizada'] == true;

    return FinalizacaoResult(
      sucesso: true,
      proximaOs: proximaOs,
      ruaFinalizada: ruaFinalizada,
    );
  }
}

/// Modelo para próxima OS da mesma rua
class ProximaOs {
  final int numos;
  final int codprod;
  final String descricao;
  final double qt;
  final int codendereco;
  final String endereco;
  final String rua;

  ProximaOs({
    required this.numos,
    required this.codprod,
    required this.descricao,
    required this.qt,
    required this.codendereco,
    required this.endereco,
    required this.rua,
  });

  factory ProximaOs.fromJson(Map<String, dynamic> json) {
    return ProximaOs(
      numos: _parseInt(json['numos']),
      codprod: _parseInt(json['codprod']),
      descricao: json['descricao']?.toString() ?? 'Produto',
      qt: _parseDouble(json['qt']) ?? 0.0,
      codendereco: _parseInt(json['codendereco']),
      endereco: json['endereco']?.toString() ?? '',
      rua: json['rua']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Modelo para informações da rua atual do operador
class MinhaRuaInfo {
  final String? rua;
  final DateTime? iniciadoEm;
  final int osPendentes;

  MinhaRuaInfo({this.rua, this.iniciadoEm, this.osPendentes = 0});

  bool get estaEmRua => rua != null;

  factory MinhaRuaInfo.fromJson(Map<String, dynamic> json) {
    DateTime? iniciadoEm;
    if (json['iniciado_em'] != null) {
      iniciadoEm = DateTime.tryParse(json['iniciado_em'].toString());
    }

    return MinhaRuaInfo(
      rua: json['rua']?.toString(),
      iniciadoEm: iniciadoEm,
      osPendentes: _parseInt(json['os_pendentes']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Modelo para resultado de iniciar OS
class IniciarOsResult {
  final bool sucesso;
  final String? erro;
  final int? osEmAndamento;
  final String? ruaBloqueada; // Rua onde o operador está preso
  final bool presoEmOutraRua;

  IniciarOsResult({
    required this.sucesso,
    this.erro,
    this.osEmAndamento,
    this.ruaBloqueada,
    this.presoEmOutraRua = false,
  });

  factory IniciarOsResult.success({String? rua}) {
    return IniciarOsResult(sucesso: true);
  }

  factory IniciarOsResult.error(String erro, {int? osEmAndamento}) {
    return IniciarOsResult(
      sucesso: false,
      erro: erro,
      osEmAndamento: osEmAndamento,
    );
  }

  factory IniciarOsResult.presoEmRua(String rua, String mensagem) {
    return IniciarOsResult(
      sucesso: false,
      erro: mensagem,
      ruaBloqueada: rua,
      presoEmOutraRua: true,
    );
  }
}
