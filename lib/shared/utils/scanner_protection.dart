import 'dart:async';

/// Proteção contra digitação manual em campos de scanner.
///
/// O scanner físico ou câmera digita extremamente rápido (todos os caracteres
/// de uma vez), enquanto a digitação manual é lenta (um caractere por vez).
///
/// Esta classe detecta digitação manual baseada na velocidade de entrada
/// e limpa o campo automaticamente, EXCETO quando o teclado foi liberado
/// pelo supervisor.
class ScannerProtection {
  /// Tempo máximo entre caracteres para considerar como scanner (em milissegundos).
  /// Scanner físico de coletor pode ser mais lento que o esperado.
  /// 500ms é bem tolerante - na prática o scanner ainda é mais rápido.
  static const int maxIntervalMs = 500;

  /// Comprimento mínimo para considerar como código válido de scanner.
  /// Códigos de barras geralmente têm pelo menos 4 caracteres.
  static const int minCodeLength = 4;

  DateTime? _lastInputTime;
  String _lastValue = '';
  Timer? _debounceTimer;

  /// Callback chamado quando digitação manual é detectada e bloqueada
  final void Function()? onManualInputBlocked;

  ScannerProtection({this.onManualInputBlocked});

  /// Verifica se a entrada é de scanner ou digitação manual.
  ///
  /// [currentValue] - O valor atual do campo de texto
  /// [tecladoLiberado] - Se true, permite digitação manual (supervisor autorizou)
  /// [clearCallback] - Callback para limpar o campo se detectar digitação manual
  ///
  /// Retorna true se deve aceitar o input, false se foi bloqueado.
  bool checkInput(
    String currentValue, {
    required bool tecladoLiberado,
    required void Function() clearCallback,
  }) {
    // Se o teclado foi liberado pelo supervisor, permite tudo
    if (tecladoLiberado) {
      _lastValue = currentValue;
      _lastInputTime = DateTime.now();
      return true;
    }

    final now = DateTime.now();

    // Se o valor diminuiu ou está vazio, é limpeza - aceita
    if (currentValue.isEmpty || currentValue.length < _lastValue.length) {
      _reset();
      return true;
    }

    // Quantidade de caracteres adicionados
    final charsAdded = currentValue.length - _lastValue.length;

    // Se adicionou muitos caracteres de uma vez (>3), é scanner - aceita
    if (charsAdded > 3) {
      _lastValue = currentValue;
      _lastInputTime = now;
      _cancelDebounce();
      return true;
    }

    // Se é o primeiro caractere
    if (_lastInputTime == null || _lastValue.isEmpty) {
      _lastValue = currentValue;
      _lastInputTime = now;
      // Inicia timer para verificar se é digitação manual lenta
      _startDebounceTimer(clearCallback);
      return true;
    }

    // Calcula intervalo desde última entrada
    final interval = now.difference(_lastInputTime!).inMilliseconds;

    // Se o intervalo é muito grande (>50ms entre caracteres), é digitação manual
    if (interval > maxIntervalMs && charsAdded <= 2) {
      // Digitação manual detectada - bloqueia
      _reset();
      clearCallback();
      onManualInputBlocked?.call();
      return false;
    }

    // Intervalo rápido - provavelmente scanner, continua monitorando
    _lastValue = currentValue;
    _lastInputTime = now;
    _startDebounceTimer(clearCallback);
    return true;
  }

  void _startDebounceTimer(void Function() clearCallback) {
    _debounceTimer?.cancel();

    // Espera 150ms após última entrada para verificar se o código está completo
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      // Se o código é muito curto após parar de digitar, provavelmente é manual
      if (_lastValue.isNotEmpty && _lastValue.length < minCodeLength) {
        clearCallback();
        onManualInputBlocked?.call();
        _reset();
      }
    });
  }

  void _cancelDebounce() {
    _debounceTimer?.cancel();
  }

  void _reset() {
    _lastValue = '';
    _lastInputTime = null;
    _debounceTimer?.cancel();
  }

  /// Reseta o estado (usar quando limpar o campo manualmente ou após processar)
  void reset() {
    _reset();
  }

  /// Libera recursos
  void dispose() {
    _debounceTimer?.cancel();
  }
}
