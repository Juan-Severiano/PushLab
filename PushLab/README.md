# PushLab

**PushLab** é um aplicativo nativo macOS desenvolvido em SwiftUI para testar e enviar push notifications durante o desenvolvimento. Clone do QuickPush Tool.

## 📋 Visão Geral

PushLab permite que desenvolvedores mobile testem push notifications via:
- **Expo** - Notificações para apps React Native/Expo
- **Live Activity** - Atualizações de Live Activities (iOS)
- **APNs** - Apple Push Notification service
- **FCM** - Firebase Cloud Messaging

## ✨ Features Implementadas (MVP - P1)

### Módulos Principais
- ✅ **Expo Notification** - Envio via API do Expo (exp.host)
- ✅ **Live Activity** - Start, Update e End de Live Activities
- ✅ **APNs Nativo** - Envio direto via Apple Push Notification service
- ✅ **FCM Nativo** - Firebase Cloud Messaging

### Features Transversais
- ✅ **Saved Tokens** - Salvar e reutilizar tokens com labels customizadas
- ✅ **Response Viewer** - Painel de resposta mostrando status HTTP e JSON
- ✅ **cURL Export** - Gerar comando cURL completo do payload
- ✅ **Keyboard Shortcuts** - ⌘+Enter para enviar, ⌘1-4 para navegar entre abas
- ✅ **Custom Data** - Adicionar key-value pairs arbitrários ao payload

## 🏗️ Arquitetura

```
PushLab/
├── Models/
│   ├── SavedToken.swift         # Modelo de tokens salvos
│   └── PushPayload.swift        # Modelos de payload (Expo, APNs, FCM, LiveActivity)
├── Services/
│   ├── KeychainService.swift    # Gerenciamento de credenciais sensíveis
│   └── PushService.swift        # HTTP client para APIs de push
├── ViewModels/
│   ├── ExpoViewModel.swift
│   ├── APNsViewModel.swift
│   ├── LiveActivityViewModel.swift
│   └── FCMViewModel.swift
├── Modules/
│   ├── ExpoView.swift
│   ├── APNsView.swift
│   ├── LiveActivityView.swift
│   └── FCMView.swift
├── Components/
│   ├── TokenRow.swift           # Componente de token salvo
│   ├── ResponsePanel.swift      # Painel de resposta
│   └── CURLModal.swift          # Modal de cURL
├── ContentView.swift            # View principal com tabs
└── PushLabApp.swift             # Entry point
```

## 🛠️ Stack Técnica

- **Framework**: SwiftUI
- **Persistência**: SwiftData (tokens) + Keychain (credenciais sensíveis)
- **Network**: URLSession com async/await
- **Pattern**: MVVM com @Observable
- **Target**: macOS 13+ (Ventura)

## ⌨️ Atalhos de Teclado

- `⌘1` - Aba Expo Notification
- `⌘2` - Aba Live Activity
- `⌘3` - Aba APNs
- `⌘4` - Aba FCM
- `⌘↵` - Enviar push notification

## 🚀 Como Usar

### Expo Notification
1. Cole o(s) ExponentPushToken(s) no campo de tokens
2. Preencha título, corpo e prioridade
3. (Opcional) Adicione custom data com key-value pairs
4. Clique em "Send Push" ou pressione ⌘↵

### APNs
1. Cole o device token
2. Configure Bundle ID, Team ID, Key ID
3. Carregue o arquivo .p8 key
4. Selecione ambiente (Sandbox/Production)
5. Preencha o conteúdo da notificação
6. Envie com ⌘↵

### Live Activity
1. Cole o activity token
2. Configure APNs (Bundle ID, Team ID, Key ID, .p8)
3. Escolha o evento (Update/End)
4. Adicione content state key-value pairs
5. Envie com ⌘↵

### FCM
1. Cole o FCM registration token
2. Adicione o server key/OAuth token
3. Configure título, corpo e settings Android
4. Adicione custom data se necessário
5. Envie com ⌘↵

## 📝 Salvando Tokens

Em qualquer aba:
1. Preencha o campo de token
2. Clique em "Save Token"
3. Digite um label (ex: "iPhone 17 Pro")
4. Use o ícone de seta para aplicar o token salvo

## 🔒 Segurança

- Tokens salvos são armazenados via SwiftData
- Credenciais sensíveis (.p8 keys, access tokens) podem ser armazenadas no Keychain
- Arquivos .p8 são carregados via NSOpenPanel (sandbox-safe)

## 🎯 Roadmap

### P2 - v1.1 (Próxima versão)
- [ ] Floating pinned window (NSPanel)
- [ ] Launch at Login (SMAppService)
- [ ] Advanced settings por plataforma
- [ ] Histórico de envios

### P3 - v2.0
- [ ] Temas
- [ ] Export/import de tokens
- [ ] Templates de payload
- [ ] Múltiplos workspaces

## ⚠️ Notas Técnicas

### APNs JWT Signing
A implementação atual do JWT para APNs é um placeholder. Para produção, é necessário implementar ES256 signing usando CryptoKit:

```swift
import CryptoKit

// Carregar a chave .p8
let p8Key = try P256.Signing.PrivateKey(pemRepresentation: p8KeyString)

// Gerar JWT com ES256
let header = ["alg": "ES256", "kid": keyId]
let claims = ["iss": teamId, "iat": timestamp]
// ... signing logic
```

### FCM API v1
O app usa a nova FCM HTTP v1 API. A URL precisa incluir o project ID correto:
```
https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send
```

## 📄 Licença

Projeto desenvolvido como clone do QuickPush Tool para fins de aprendizado.

---

Desenvolvido com ❤️ usando SwiftUI
