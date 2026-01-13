// Configuração por cliente (White-Label)
// 
// Para buildar para um cliente específico, use:
// flutter build apk --dart-define=CLIENT=bstech
// flutter build apk --dart-define=CLIENT=cliente_x
// 
// Para rodar em dev:
// flutter run --dart-define=CLIENT=bstech

class ClientConfig {
  final String id;
  final String name;
  final String apiBaseUrl;
  final String logoPath;
  final String logoPathDark; // Logo para tema escuro (opcional)
  final int primaryColorHex;
  final int secondaryColorHex;

  const ClientConfig({
    required this.id,
    required this.name,
    required this.apiBaseUrl,
    required this.logoPath,
    this.logoPathDark = '',
    this.primaryColorHex = 0xFF2196F3, // Azul padrão
    this.secondaryColorHex = 0xFF03DAC6,
  });

  /// Cliente atual baseado no --dart-define=CLIENT=xxx
  static const String _clientId = String.fromEnvironment(
    'CLIENT',
    defaultValue: 'rofe', // Cliente padrão
  );

  /// Retorna a configuração do cliente atual
  static ClientConfig get current {
    return _clients[_clientId] ?? _clients['rofe']!;
  }

  /// Mapa de todos os clientes disponíveis
  static const Map<String, ClientConfig> _clients = {
    'bstech': ClientConfig(
      id: 'bstech',
      name: 'WinConnect',
      apiBaseUrl: 'https://winconnect.bstechsolutions.com/api',
      logoPath: 'assets/clients/bstech/logo.png',
      logoPathDark: 'assets/clients/bstech/logo_dark.png',
      primaryColorHex: 0xFF2196F3, // Azul
      secondaryColorHex: 0xFF03DAC6,
    ),
    
    'rofe': ClientConfig(
      id: 'rofe',
      name: 'Rofe',
      apiBaseUrl: 'https://immediately-vacation-implies-lung.trycloudflare.com/api',
      logoPath: 'assets/clients/rofe/logo.png',
      primaryColorHex: 0xFF1E88E5, // Azul
      secondaryColorHex: 0xFF43A047,
    ),
  };

  /// Lista todos os clientes disponíveis (útil para debug)
  static List<String> get availableClients => _clients.keys.toList();
}
