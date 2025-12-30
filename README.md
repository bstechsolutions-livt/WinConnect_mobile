# 🚀 WinConnect Mobile

> Um aplicativo Flutter moderno construído com as melhores práticas e stack atualizada para 2025

## 📱 Sobre o Projeto

WinConnect Mobile é um aplicativo Flutter que utiliza uma arquitetura moderna e performática, similar ao conceito de Laravel + Inertia + Vue + Tailwind, mas adaptada para o ecossistema Flutter.

## 🛠️ Stack Tecnológica

### 🏗️ **Arquitetura & Padrões**
- **Clean Architecture** com feature-based organization
- **SOLID Principles**
- **Separation of Concerns**

### 📦 **Principais Dependências**

| Categoria | Package | Versão | Descrição |
|-----------|---------|--------|-----------|
| **🎮 State Management** | `flutter_riverpod` | ^2.4.9 | Gerenciamento de estado reativo |
| **🧭 Navigation** | `go_router` | ^13.0.0 | Navegação declarativa |
| **🏗️ Code Generation** | `freezed` | ^2.4.6 | Data classes imutáveis |
| **💾 Local Storage** | `hive` | ^2.2.3 | Banco de dados local rápido |
| **🌐 HTTP Client** | `dio` | ^5.4.0 | Cliente HTTP avançado |
| **🎨 UI Framework** | `flex_color_scheme` | ^7.3.1 | Theming avançado |
| **✨ Animations** | `flutter_animate` | ^4.4.0 | Animações declarativas |
| **🪝 React-like Hooks** | `flutter_hooks` | ^0.20.3 | Composição de widgets |

## 📁 Estrutura do Projeto

```
lib/
├── 🏗️ core/                 # Configurações base
│   ├── constants/          # Constantes da aplicação
│   ├── router/            # Configuração de rotas
│   └── theme/             # Temas e estilos
├── 🎯 features/            # Módulos por funcionalidade
│   ├── auth/              # Autenticação
│   │   ├── data/         # Camada de dados
│   │   ├── domain/       # Regras de negócio
│   │   └── presentation/ # Interface do usuário
│   └── home/             # Tela inicial
├── 🔄 shared/             # Componentes reutilizáveis
│   ├── models/           # Modelos de dados
│   ├── providers/        # Providers globais
│   ├── utils/           # Utilitários
│   └── widgets/         # Widgets compartilhados
└── 📱 main.dart          # Entry point
```

## 🚀 Como Executar

### ⚙️ **Pré-requisitos**
- Flutter SDK 3.10.4+
- Dart SDK 3.10.0+

### 🏃‍♂️ **Executando o Projeto**

1. **Clone o repositório**
   ```bash
   git clone https://github.com/bstechsolutions-livt/WinConnect_mobile.git
   cd winconnect_mobile
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Gere o código automaticamente**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Execute o app**
   ```bash
   flutter run
   ```

## ⚡ **Scripts Úteis**

```bash
# 🔄 Gerar código automaticamente (watch mode)
dart run build_runner watch --delete-conflicting-outputs

# 🔍 Análise de código
flutter analyze

# 🧪 Executar testes
flutter test

# 📦 Build para produção
flutter build apk --release          # Android
flutter build web --release          # Web
flutter build windows --release      # Windows
```

## 🎯 **Features Implementadas**

### ✅ **Já Funcionando**
- [x] 🎨 **Theming System** - Light/Dark mode automático
- [x] 🧭 **Navigation** - Go Router com rotas declarativas
- [x] 🎮 **State Management** - Riverpod com providers
- [x] 🏗️ **Code Generation** - Freezed para data classes
- [x] ✨ **Animations** - Flutter Animate integrado
- [x] 📱 **Responsive Design** - Adaptável a diferentes telas
- [x] 🔧 **Developer Experience** - Hot reload + code generation

### 🔄 **Em Desenvolvimento**
- [ ] 🔐 **Authentication System**
- [ ] 💾 **Local Database Setup**
- [ ] 🌐 **API Integration**
- [ ] 🧪 **Unit & Integration Tests**
- [ ] 📊 **Error Handling & Logging**

## 🎨 **Design System**

### 🎨 **Cores**
- **Primary**: Blue (#2196F3)
- **Secondary**: Teal (#03DAC6)
- **Suporte**: Material 3 Design System

### 📐 **Breakpoints**
- **Mobile**: < 600px
- **Tablet**: 600px - 1024px
- **Desktop**: > 1024px

## 🚧 **Próximos Passos**

1. **🔐 Sistema de Autenticação**
   - Login/Register
   - JWT Token handling
   - Biometric authentication

2. **💾 Persistência de Dados**
   - Setup Hive database
   - Offline support
   - Data synchronization

3. **🌐 API Integration**
   - REST API client
   - Error handling
   - Loading states

4. **🧪 Testing Strategy**
   - Unit tests
   - Widget tests
   - Integration tests

## 🏆 **Vantagens desta Stack**

### ⚡ **Performance**
- Code generation reduz boilerplate
- Riverpod otimiza re-renders
- Hive oferece acesso ultra-rápido aos dados

### 🛠️ **Developer Experience**
- Hot reload instantâneo
- Type safety completo
- Debugging avançado
- Estrutura escalável

### 📱 **User Experience**
- Animações fluidas nativas
- Theming consistente
- Navegação intuitiva
- Responsive design

## 📄 **Licença**

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

**Desenvolvido com ❤️ usando Flutter e as melhores práticas de 2025**
