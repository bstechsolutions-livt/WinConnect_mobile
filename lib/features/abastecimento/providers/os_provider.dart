import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/os_model.dart';
import '../../../shared/providers/api_service_provider.dart';

part 'os_provider.g.dart';

@Riverpod(keepAlive: false)
class OsNotifier extends _$OsNotifier {
  @override
  Future<List<OrdemServico>> build(int fase, String rua) async {
    return _loadOsFromApi(fase, rua);
  }

  Future<List<OrdemServico>> _loadOsFromApi(int fase, String rua) async {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.get('/abastecimento/fase$fase/ruas/$rua/os');
    
    final osData = response['ordens'] as List? ?? response['os'] as List? ?? [];
    return osData.map((item) => OrdemServico(
      numos: item['numos'],
      codprod: item['codprod'],
      produto: item['produto'] ?? 'Produto ${item['codprod']}',
      descricao: item['descricao'] ?? 'Descrição não informada',
      enderecoOrigem: item['endereco_origem'] ?? 'Origem',
      enderecoDestino: item['endereco_destino'] ?? 'Destino',
      quantidade: (item['qt'] as num?)?.toDouble() ?? 0.0,
      status: item['status'] ?? 'PENDENTE',
      divergencia: item['divergencia'],
      dtinicio: item['dtinicio'] != null ? DateTime.parse(item['dtinicio']) : null,
      dtfim: item['dtfim'] != null ? DateTime.parse(item['dtfim']) : null,
    )).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadOsFromApi(fase, rua));
  }
}