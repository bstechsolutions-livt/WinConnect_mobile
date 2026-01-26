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
    print('===== Buscando OS ativa para matrícula: $matricula =====');
    final response = await apiService.get('/wms/fase1/operador/$matricula/os-ativa');
    print('===== Resposta OS ativa: $response =====');
    
    // Se retornou dados da OS ativa
    if (response['os'] != null) {
      final osData = response['os'];
      print('===== OS encontrada: ${osData['numos']} =====');
      
      // Converte numos para int (pode vir como String ou int)
      int numos = 0;
      if (osData['numos'] != null) {
        numos = osData['numos'] is int 
            ? osData['numos'] 
            : int.tryParse(osData['numos'].toString()) ?? 0;
      }
      
      return OsAtiva(
        numos: numos,
        fase: 1, // Por enquanto só temos fase 1
        status: osData['status']?.toString() ?? '',
        enderecoBipado: osData['endereco_bipado'] == true,
        produtoBipado: osData['produto_bipado'] == true,
        unitizadorVinculado: osData['unitizador_vinculado'] == true,
        codunitizador: osData['codunitizador']?.toString(),
      );
    }
    
    print('===== Nenhuma OS ativa encontrada =====');
    return null;
  } catch (e) {
    // PROPAGA o erro para a tela tratar - não deixa continuar silenciosamente
    print('===== Erro ao buscar OS ativa: $e =====');
    rethrow;
  }
}
