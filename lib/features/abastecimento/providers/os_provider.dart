import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/os_model.dart';
import '../../../shared/providers/api_service_provider.dart';

part 'os_provider.g.dart';

// Classe para retornar OSs junto com info de OS em andamento
class OsListResult {
  final List<OrdemServico> ordens;
  final int? osEmAndamento;

  OsListResult({required this.ordens, this.osEmAndamento});
}

@Riverpod(keepAlive: false)
class OsNotifier extends _$OsNotifier {
  @override
  Future<OsListResult> build(int fase, String rua) async {
    return _loadOsFromApi(fase, rua);
  }

  Future<OsListResult> _loadOsFromApi(int fase, String rua) async {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.get('/wms/fase$fase/ruas/$rua/os');

    final osData = response['ordens'] as List? ?? [];
    final osEmAndamento = response['os_em_andamento'] as int?;

    final ordens = osData
        .map(
          (item) => OrdemServico(
            numos: _parseInt(item['numos']),
            ordem: _parseInt(item['ordem']),
            codprod: _parseInt(item['codprod']),
            descricao: item['descricao']?.toString() ?? 'Sem descrição',
            enderecoOrigem: item['endereco_origem']?.toString() ?? '',
            quantidade: _parseDouble(item['qt_solicitada']) ??
                _parseDouble(item['qt']) ??
                _parseDouble(item['quantidade']) ??
                0.0,
            status: item['status']?.toString() ?? 'PENDENTE',
            podeExecutar: item['pode_executar'] == true || item['pode_executar'] == 'true',
          ),
        )
        .toList();

    return OsListResult(ordens: ordens, osEmAndamento: osEmAndamento);
  }

  /// Converte dynamic para int (aceita String, int ou num)
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Converte dynamic para double (aceita String, int, double ou num)
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadOsFromApi(fase, rua));
  }
}
