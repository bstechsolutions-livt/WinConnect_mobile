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
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.get('/wms/fase$fase/ruas');
    
    final ruasData = response['ruas'] as List? ?? [];
    
    return ruasData.map((item) => Rua(
      codigo: item['rua']?.toString() ?? '',
      nome: 'Rua ${item['rua']}', 
      quantidade: item['qtd_os'] ?? 0,
    )).toList();
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