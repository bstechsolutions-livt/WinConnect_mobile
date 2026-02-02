# Sistema de Atualização Automática - WinConnect Mobile

Este documento descreve o sistema de atualização automática híbrido implementado para o WinConnect Mobile.

## 📋 Visão Geral

O sistema suporta duas formas de atualização:

1. **OTA Update (APK completo)**: Baixa e instala novo APK quando há mudanças em plugins nativos ou assets
2. **Code Push (Shorebird)**: Patches de código Dart apenas, sem reinstalação (para hotfixes rápidos)

---

## 🔧 Configuração do Servidor (Laravel)

### 1. Rodar a Migration

```bash
cd /var/www/winconnect
php artisan migrate
```

Isso criará a tabela `app_versions` no banco de dados.

### 2. (Opcional) Rodar o Seeder inicial

```bash
php artisan db:seed --class=AppVersionSeeder
```

### 3. Criar permissão para administradores

No painel, adicione a permissão `admin.app-versions.manage` aos usuários que poderão gerenciar versões.

### 4. Criar pasta para APKs

```bash
mkdir -p /var/www/winconnect/storage/app/public/app-releases
chmod 755 /var/www/winconnect/storage/app/public/app-releases
php artisan storage:link
```

---

## 🌐 Endpoints da API

### Verificar Atualização

```
GET /api/app/check-update
```

**Query Parameters:**
- `version`: Versão atual (ex: "1.1.1")
- `build`: Número do build atual (ex: 1)
- `platform`: "android" ou "ios"
- `client`: ID do cliente (ex: "rofe", "bstech")

**Response:**
```json
{
  "success": true,
  "data": {
    "has_update": true,
    "force_update": false,
    "latest_version": "1.2.0",
    "latest_build": 2,
    "current_build": 1,
    "download_url": "http://192.168.1.25/api/app/download/1",
    "file_size": 45000000,
    "sha256_checksum": "abc123...",
    "changelog": "- Correção de bugs\n- Nova funcionalidade X",
    "released_at": "2026-02-02T10:00:00Z"
  }
}
```

### Obter Última Versão

```
GET /api/app/latest
```

### Download do APK

```
GET /api/app/download/{id}
```

### Listar Versões

```
GET /api/app/versions
```

---

## 📱 Uso no Flutter

### Verificação Automática na Inicialização

O `UpdateCheckerWrapper` já está integrado no `main.dart`. Quando o usuário faz login e acessa o Dashboard, o app automaticamente verifica se há atualizações.

### Verificação Manual

O botão "Verificar Atualização" está visível no Dashboard. O usuário pode clicar para verificar manualmente.

### Comportamento

1. Se houver atualização disponível:
   - Dialog é exibido com informações da nova versão
   - Se `force_update = true`, o usuário não pode ignorar
   - Botão "Atualizar" inicia o download

2. Durante o download:
   - Dialog de progresso é exibido
   - Porcentagem é mostrada em tempo real
   - Download pode ser cancelado (se não for forçado)

3. Após download:
   - Android abre o instalador do sistema
   - Usuário confirma a instalação
   - App é atualizado

---

## 🚀 Publicando Nova Versão

### Via Painel Web

1. Acesse o painel: `http://192.168.1.25/panel/admin/app-versions`
2. Clique em "Nova Versão"
3. Preencha:
   - **Versão**: Ex: 1.2.0
   - **Build Number**: Ex: 2 (deve ser maior que o anterior)
   - **Plataforma**: android
   - **Cliente**: all (para todos) ou um específico
   - **Arquivo APK**: Faça upload do APK
   - **Changelog**: Descreva as mudanças
   - **Forçar Update**: Marque se for crítico
4. Salve

### Via Terminal/Script

```bash
# No servidor de produção
cd /var/www/winconnect

# Usando tinker
php artisan tinker
```

```php
App\Models\AppVersion::create([
    'version' => '1.2.0',
    'build_number' => 2,
    'platform' => 'android',
    'client_id' => 'all',
    'download_url' => 'http://192.168.1.25/storage/app-releases/winconnect-v1.2.0.apk',
    'file_size' => 45000000,
    'force_update' => false,
    'changelog' => '- Correção de bugs\n- Nova feature X',
    'is_active' => true,
    'released_at' => now(),
]);
```

---

## 🐦 Shorebird (Code Push) - OPCIONAL

Para usar o Shorebird para patches rápidos:

### 1. Instalar Shorebird CLI

```bash
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
```

### 2. Login e Init

```bash
cd winconnect_mobile
shorebird login
shorebird init
```

### 3. Build com Shorebird

```bash
shorebird release android
```

### 4. Publicar Patch

```bash
shorebird patch android
```

O patch será aplicado automaticamente na próxima abertura do app.

---

## 📁 Arquivos Criados

### Laravel (Backend)

| Arquivo | Descrição |
|---------|-----------|
| `database/migrations/2026_02_02_000001_create_app_versions_table.php` | Migration da tabela |
| `app/Models/AppVersion.php` | Model Eloquent |
| `app/Http/Controllers/Api/AppVersionController.php` | Controller da API pública |
| `app/Http/Controllers/Panel/Admin/AppVersionController.php` | Controller do painel admin |
| `database/seeders/AppVersionSeeder.php` | Seeder inicial |
| `routes/api.php` | Rotas públicas adicionadas |
| `routes/panel.php` | Rotas do painel adicionadas |

### Flutter (Mobile)

| Arquivo | Descrição |
|---------|-----------|
| `lib/shared/models/app_update_info.dart` | Models Freezed |
| `lib/shared/services/app_update_service.dart` | Service de atualização |
| `lib/shared/providers/app_update_provider.dart` | Providers Riverpod |
| `lib/shared/widgets/update_dialog.dart` | Dialogs de UI |
| `lib/shared/widgets/update_checker.dart` | Widgets helper |
| `android/app/src/main/res/xml/filepaths.xml` | Config do OTA Update |
| `android/app/src/main/res/xml/network_security_config.xml` | Config de rede |
| `android/app/build.gradle.kts` | Desugaring habilitado |
| `android/app/src/main/AndroidManifest.xml` | Permissões e providers |

---

## ⚠️ Notas Importantes

1. **Build Number**: Sempre incrementar ao publicar nova versão
2. **Checksum SHA256**: Gerado automaticamente no upload, garante integridade
3. **Permissão de Instalação**: Usuário deve permitir "fontes desconhecidas" no Android
4. **Force Update**: Use com moderação, apenas para bugs críticos de segurança
5. **Tamanho do APK**: Split APK por ABI reduz tamanho (~30MB vs ~80MB)

---

## 🔍 Troubleshooting

### App não encontra atualização

1. Verifique se o `build_number` no servidor é maior que o atual
2. Verifique se `is_active = true` na versão
3. Verifique se o `client_id` corresponde ou é "all"

### Download falha

1. Verifique conectividade com o servidor
2. Verifique se a URL de download está acessível
3. Verifique permissões de rede no Android

### Instalação falha

1. Verifique permissão REQUEST_INSTALL_PACKAGES no AndroidManifest
2. Usuário deve permitir instalação de fontes desconhecidas
3. APK deve estar assinado (mesmo que com debug key)

---

## 📞 Suporte

Para problemas ou dúvidas, consulte os logs:

**Laravel:**
```bash
tail -f /var/www/winconnect/storage/logs/laravel.log
```

**Flutter:**
Debug console no Android Studio/VS Code
