# 🚀 Sistema de Atualização Automática - WinConnect Mobile

> **Documentação completa para manutenção e referência futura**  
> Última atualização: Fevereiro 2026

---

## 📋 Sumário

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Configuração do Servidor](#configuração-do-servidor)
4. [Fluxo de Download Inicial](#fluxo-de-download-inicial)
5. [Como Publicar Atualizações](#como-publicar-atualizações)
6. [Comandos Shorebird](#comandos-shorebird)
7. [Estrutura de Arquivos](#estrutura-de-arquivos)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

O WinConnect Mobile utiliza um **sistema híbrido de atualização** que combina:

| Tipo | Tecnologia | Uso |
|------|------------|-----|
| **Code Push** | Shorebird | Correções rápidas de código Dart (sem novo APK) |
| **OTA Update** | APK via Laravel | Atualizações nativas completas (novo APK) |

### Vantagens:
- ✅ **Shorebird**: Atualizações instantâneas (~5 segundos) sem Play Store
- ✅ **OTA Update**: Suporte a mudanças nativas (permissões, plugins, etc)
- ✅ **Controle total**: Você gerencia as versões e releases

---

## 🏗️ Arquitetura do Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                               │
│  ┌─────────────────┐       ┌──────────────────────────────────┐ │
│  │  Shorebird SDK  │       │     App Update Service           │ │
│  │  (Code Push)    │       │  - Verifica versão na API        │ │
│  │                 │       │  - Baixa APK se necessário       │ │
│  │  Patches Dart   │       │  - Instala automaticamente       │ │
│  └────────┬────────┘       └───────────────┬──────────────────┘ │
│           │                                │                     │
└───────────┼────────────────────────────────┼─────────────────────┘
            │                                │
            ▼                                ▼
    ┌───────────────┐              ┌─────────────────────┐
    │  Shorebird    │              │   Laravel Backend   │
    │    Cloud      │              │  192.168.1.25       │
    │               │              │  /var/www/winconnect│
    │  Armazena     │              │                     │
    │  patches      │              │  - API /api/mobile/ │
    │  de código    │              │  - Storage APKs     │
    └───────────────┘              └─────────────────────┘
```

---

## 🖥️ Configuração do Servidor

### Informações do Servidor
- **IP**: `192.168.1.25`
- **Path**: `/var/www/winconnect`
- **URL Base API**: `http://192.168.1.25/api/mobile/`

### Arquivos Criados no Laravel

```
WinConnect/
├── app/
│   ├── Http/Controllers/
│   │   ├── Api/AppVersionController.php      # API pública de versões
│   │   └── Admin/AppVersionController.php    # CRUD admin (futuro)
│   └── Models/
│       └── AppVersion.php                    # Model de versões
├── database/
│   ├── migrations/
│   │   └── xxxx_create_app_versions_table.php
│   └── seeders/
│       └── AppVersionSeeder.php              # Seed inicial
├── routes/
│   └── api.php                               # Rota /api/mobile/version
└── storage/
    └── app/public/releases/                  # APKs para download
        └── winconnect_mobile-X.X.X.apk
```

### Endpoints da API

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/api/mobile/version` | Retorna info da versão mais recente |

**Resposta:**
```json
{
  "success": true,
  "data": {
    "version": "2.0.0",
    "build_number": 1,
    "download_url": "http://192.168.1.25/storage/releases/winconnect_mobile-2.0.0.apk",
    "release_notes": "- Sistema de atualização automática\n- Melhorias de performance",
    "is_mandatory": false,
    "min_supported_version": "1.0.0",
    "file_size": 77400000,
    "checksum": "sha256hash..."
  }
}
```

---

## 📲 Fluxo de Download Inicial

### Primeira Instalação (usuário novo)

1. **Usuário acessa o site** WinConnect no navegador
2. **Clica em "Baixar App"** na página de downloads
3. **Baixa o APK** diretamente do servidor
4. **Instala manualmente** (permitir "fontes desconhecidas")
5. **Abre o app** → Sistema de atualização automática já está ativo

### Atualizações Subsequentes

O app verifica automaticamente ao iniciar:

1. **Code Push (Shorebird)**: Aplica patches Dart instantaneamente
2. **OTA Update**: Se há nova versão de APK, mostra diálogo para atualizar

---

## 🔄 Como Publicar Atualizações

### Atualização de CÓDIGO (Shorebird Patch)

> Use quando: Mudou apenas código Dart (UI, lógica, correções)

```powershell
# No Windows (PowerShell)
cd "c:\Users\BS TECH\Sistemas\winconnect_mobile"
$env:Path = "$env:USERPROFILE\.shorebird\bin;$env:Path"

# Criar patch para a release atual
shorebird patch android --release-version=2.0.0+1
```

**O que acontece:**
- Shorebird compila apenas as mudanças
- Faz upload do patch (~1-5MB)
- Usuários recebem atualização em ~5 segundos ao abrir o app

---

### Atualização COMPLETA (Novo APK + Nova Release)

> Use quando: Mudou plugins, permissões, assets nativos, ou versão major

#### Passo 1: Atualizar versão no pubspec.yaml

```yaml
version: 2.1.0+2  # Incrementar versão
```

#### Passo 2: Criar nova release Shorebird

```powershell
cd "c:\Users\BS TECH\Sistemas\winconnect_mobile"
$env:Path = "$env:USERPROFILE\.shorebird\bin;$env:Path"

# Gerar novo release com APK
shorebird release android --artifact apk
```

#### Passo 3: Fazer upload do APK para o servidor

```powershell
# Usar o script Python existente
python ssh_upload.py build/app/outputs/flutter-apk/app-release.apk /var/www/winconnect/storage/app/public/releases/winconnect_mobile-2.1.0.apk
```

**Ou via SCP manual:**
```bash
scp build/app/outputs/flutter-apk/app-release.apk bstech@192.168.1.25:/var/www/winconnect/storage/app/public/releases/winconnect_mobile-2.1.0.apk
```

#### Passo 4: Atualizar versão no banco de dados

Acesse o servidor e execute:
```bash
ssh bstech@192.168.1.25
cd /var/www/winconnect

# Via Tinker
php artisan tinker

# Dentro do Tinker:
\App\Models\AppVersion::create([
    'version' => '2.1.0',
    'build_number' => 2,
    'download_url' => 'http://192.168.1.25/storage/releases/winconnect_mobile-2.1.0.apk',
    'release_notes' => "- Novidades da versão 2.1.0\n- Correções de bugs",
    'is_mandatory' => false,
    'min_supported_version' => '1.0.0',
    'file_size' => 77400000,
    'is_active' => true
]);

# Desativar versões antigas
\App\Models\AppVersion::where('version', '!=', '2.1.0')->update(['is_active' => false]);
```

---

## 🐦 Comandos Shorebird

### Comandos Essenciais

```powershell
# Configurar PATH do Shorebird (sempre fazer antes)
$env:Path = "$env:USERPROFILE\.shorebird\bin;$env:Path"

# Ver status da conta
shorebird doctor

# Listar releases
shorebird releases list

# Listar patches de uma release
shorebird patches list --release-version=2.0.0+1

# Criar nova release (gera APK e registra no Shorebird)
shorebird release android --artifact apk

# Criar patch (atualização de código apenas)
shorebird patch android --release-version=2.0.0+1

# Reverter um patch (se deu problema)
shorebird patches delete --release-version=2.0.0+1 --patch-number=1
```

### Informações da Conta Shorebird

- **App ID**: `800d4fa2-5956-4ed5-8018-6e2797744d6b`
- **Conta**: `bstech.solutions@outlook.com`
- **Console**: https://console.shorebird.dev

---

## 📁 Estrutura de Arquivos Flutter

### Arquivos de Atualização

```
lib/
├── core/
│   ├── models/
│   │   └── app_update_info.dart       # Model de info de atualização
│   └── services/
│       └── app_update_service.dart    # Serviço de verificação/download
└── shared/
    ├── providers/
    │   └── app_update_provider.dart   # Provider Riverpod
    └── widgets/
        ├── update_dialog.dart         # Diálogo de atualização
        └── update_checker.dart        # Widget wrapper que verifica

android/
├── app/src/main/
│   ├── AndroidManifest.xml            # Permissões configuradas
│   └── res/xml/
│       ├── filepaths.xml              # Paths para OTA Update
│       └── network_security_config.xml # Config de rede
```

### Arquivos de Configuração

```
# Raiz do projeto
shorebird.yaml                         # Config Shorebird
pubspec.yaml                           # Dependências (ota_update, shorebird)
ATUALIZACAO_AUTOMATICA.md              # Esta documentação!
```

---

## 🔧 Troubleshooting

### Erro: "desugar_jdk_libs version"

**Problema:** Build falha pedindo versão 2.1.4 do desugar_jdk_libs

**Solução:** Já corrigido em `android/app/build.gradle.kts`:
```kotlin
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

### Erro: "Git long paths"

**Problema:** Aviso sobre caminhos longos do Git

**Solução:**
```powershell
git config --system core.longpaths true
```

### App não encontra atualizações

1. Verificar se API está respondendo: `curl http://192.168.1.25/api/mobile/version`
2. Verificar storage link: `php artisan storage:link`
3. Verificar permissões do arquivo APK no servidor

### Shorebird patch não funciona

1. Verificar se a versão no app é a mesma da release
2. Verificar se o patch foi criado para a release correta
3. Testar em device físico (emulador pode ter problemas)

---

## 📊 Checklist de Deploy

### Deploy Inicial (primeira vez)

- [ ] Executar migrations no servidor: `php artisan migrate`
- [ ] Criar storage link: `php artisan storage:link`
- [ ] Criar pasta releases: `mkdir -p storage/app/public/releases`
- [ ] Executar seeder: `php artisan db:seed --class=AppVersionSeeder`
- [ ] Upload do primeiro APK
- [ ] Testar endpoint: `curl http://192.168.1.25/api/mobile/version`

### Deploy de Atualização

- [ ] Incrementar versão no `pubspec.yaml`
- [ ] Rodar `shorebird release android --artifact apk`
- [ ] Upload APK para servidor
- [ ] Inserir nova versão no banco
- [ ] Testar download em device

---

## 🔐 Credenciais e Acessos

### Servidor
- **IP**: 192.168.1.25
- **Usuário SSH**: bstech (ou conforme seu acesso)
- **Path do projeto**: /var/www/winconnect

### Shorebird
- **Console**: https://console.shorebird.dev
- **Email**: bstech.solutions@outlook.com
- **App ID**: 800d4fa2-5956-4ed5-8018-6e2797744d6b

---

## 📝 Notas Importantes

1. **Shorebird é gratuito** para até 5.000 patches/mês
2. **OTA Update** requer que usuário permita "instalar apps desconhecidos"
3. **Versão mínima** do Android suportada: API 21 (Android 5.0)
4. **APKs** devem ser assinados com a mesma keystore sempre
5. **Patches** só funcionam em APKs gerados pelo Shorebird (não pelo Flutter padrão)

---

*Documentação criada para referência da equipe BS Tech Solutions*
