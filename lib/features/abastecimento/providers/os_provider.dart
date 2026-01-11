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
    final response = await apiService.get('/wms/fase1/ruas/$rua/os');
    
    final osData = response['ordens'] as List? ?? [];
    final osEmAndamento = response['os_em_andamento'] as int?;
    
    final ordens = osData.map((item) => OrdemServico(
      numos: item['numos'] ?? 0,
      ordem: item['ordem'] ?? 0,
      codprod: item['codprod'] ?? 0,
      descricao: item['descricao'] ?? 'Sem descrição',
      enderecoOrigem: item['endereco_origem'] ?? '',
      quantidade: (item['qt'] as num?)?.toDouble() ?? 0.0,
      status: item['status'] ?? 'PENDENTE',
      podeExecutar: item['pode_executar'] ?? false,
    )).toList();
    
    return OsListResult(ordens: ordens, osEmAndamento: osEmAndamento);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadOsFromApi(fase, rua));
  }
}