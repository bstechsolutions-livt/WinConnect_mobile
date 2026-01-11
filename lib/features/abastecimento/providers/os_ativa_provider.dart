import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/providers/api_service_provider.dart';

part 'os_ativa_provider.g.dart';

class OsAtiva {
  final int numos;
  final int fase;
  final String status;
  final bool enderecoBipado;
  final bool produtoBipado;
  final bool unitizadorVinculado;
  final String? codunitizador;

  OsAtiva({
    required this.numos,
    required this.fase,
    required this.status,
    this.enderecoBipado = false,
    this.produtoBipado = false,
    this.unitizadorVinculado = false,
    this.codunitizador,
  });
}

@riverpod
Future<OsAtiva?> osAtiva(OsAtivaRef ref, int matricula) async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    final response = await apiService.get('/wms/fase1/operador/$matricula/os-ativa');
    
    // Se retornou dados da OS ativa
    if (response['os'] != null) {
      final osData = response['os'];
      return OsAtiva(
        numos: osData['numos'] ?? 0,
        fase: 1, // Por enquanto só temos fase 1
        status: osData['status'] ?? '',
        enderecoBipado: osData['endereco_bipado'] == true,
        produtoBipado: osData['produto_bipado'] == true,
        unitizadorVinculado: osData['unitizador_vinculado'] == true,
        codunitizador: osData['codunitizador']?.toString(),
      );
    }
    
    return null;
  } catch (e) {
    // Se der erro (404 ou outro), não tem OS ativa
    return null;
  }
}
