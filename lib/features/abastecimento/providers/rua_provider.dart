import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/rua_model.dart';
import '../../../shared/providers/api_service_provider.dart';

part 'rua_provider.g.dart';

@Riverpod(keepAlive: false)
class RuaNotifier extends _$RuaNotifier {
  @override
  Future<List<Rua>> build(int fase) async {
    final result = await _loadRuasFromApi(fase);
    return result;
  }

  Future<List<Rua>> _loadRuasFromApi(int fase) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/wms/fase$fase/ruas');
      
      // DEBUG: Ver o que a API retorna
      print('========== DEBUG RUAS FASE $fase ==========');
      print('Response completa: $response');
      print('Tipo do response: ${response.runtimeType}');
      
      final ruasData = response['ruas'] as List? ?? [];
      print('ruasData: $ruasData');
      print('Tipo do ruasData: ${ruasData.runtimeType}');
      
      if (ruasData.isNotEmpty) {
        print('Primeiro item: ${ruasData[0]}');
        print('Tipo do primeiro item: ${ruasData[0].runtimeType}');
        (ruasData[0] as Map).forEach((key, value) {
          print('  $key: $value (${value.runtimeType})');
        });
      }
      print('============================================');
      
      return ruasData.map((item) {
        // Trata quantidade - pode ser qtd_os (fase1) ou total_unitizadores (fase2)
        int quantidade = 0;
        final qtdOs = item['qtd_os'];
        final totalUnit = item['total_unitizadores'];
        final totalItens = item['total_itens'];
        
        if (qtdOs != null) {
          quantidade = _parseToInt(qtdOs);
        } else if (totalUnit != null) {
          quantidade = _parseToInt(totalUnit);
        } else if (totalItens != null) {
          quantidade = _parseToInt(totalItens);
        }
        
        return Rua(
          codigo: item['rua']?.toString() ?? '',
          nome: 'Rua ${item['rua']}', 
          quantidade: quantidade,
        );
      }).toList();
    } catch (e, stack) {
      print('========== ERRO AO CARREGAR RUAS ==========');
      print('Erro: $e');
      print('Stack: $stack');
      print('============================================');
      rethrow;
    }
  }
  
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  void toggleRuaSelection(String codigoRua) {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((rua) {
      if (rua.codigo == codigoRua) {
        return rua.copyWith(selecionada: !rua.selecionada);
      }
      return rua;
    }).toList();
    
    state = AsyncValue.data(updatedList);
  }

  List<Rua> get ruasSelecionadas {
    return state.value?.where((rua) => rua.selecionada).toList() ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadRuasFromApi(fase));
  }
}

// Provider para rua atual
@riverpod
class RuaAtual extends _$RuaAtual {
  @override
  String? build() {
    return null;
  }

  void setRuaAtual(String? rua) {
    state = rua;
  }
}