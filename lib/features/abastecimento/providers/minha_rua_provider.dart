import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/finalizacao_result_model.dart';
import '../../../shared/providers/api_service_provider.dart';

part 'minha_rua_provider.g.dart';

/// Provider para gerenciar informações da rua atual do operador
/// Usa o endpoint GET /api/wms/fase1/minha-rua
@Riverpod(keepAlive: false)
class MinhaRuaNotifier extends _$MinhaRuaNotifier {
  @override
  Future<MinhaRuaInfo> build(int fase) async {
    return _loadMinhaRua(fase);
  }

  Future<MinhaRuaInfo> _loadMinhaRua(int fase) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/wms/fase$fase/minha-rua');
      return MinhaRuaInfo.fromJson(response);
    } catch (e) {
      // Se não conseguir carregar, retorna vazio (sem rua alocada)
      return MinhaRuaInfo();
    }
  }

  /// Libera o operador da rua atual (requer permissão wms.os.liberar-rua)
  Future<(bool, String?)> liberarRua() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/wms/fase$fase/liberar-rua', {});

      // Atualiza o estado para refletir que não está mais em nenhuma rua
      state = AsyncValue.data(MinhaRuaInfo());
      return (true, null);
    } catch (e) {
      return (false, _extrairMensagemErro(e));
    }
  }

  /// Atualiza os dados da rua atual
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadMinhaRua(fase));
  }

  String _extrairMensagemErro(dynamic e) {
    final errorStr = e.toString();
    final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(errorStr);
    if (msgMatch != null) {
      return msgMatch.group(1) ?? 'Erro desconhecido';
    }
    if (errorStr.contains('ApiException:')) {
      return errorStr.replaceAll('ApiException:', '').trim();
    }
    return errorStr;
  }
}
