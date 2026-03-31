# PushLab - Guia de Início Rápido

## 🚀 Primeiros Passos

### Instalação
1. Clone o repositório
2. Abra `PushLab.xcodeproj` no Xcode
3. Build e execute (⌘R)

## 📱 Testando Cada Tipo de Push

### 1. Expo Notifications (React Native)

**Pré-requisitos:**
- Token do tipo `ExponentPushToken[...]`

**Passos:**
1. Abra a aba Expo (⌘1)
2. Cole seu ExponentPushToken
3. Preencha título e corpo
4. Clique "Send Push" (⌘↵)

**Exemplo de Token:**
```
ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]
```

**Dica:** Use o botão "Save Token" para reutilizar tokens frequentemente usados.

---

### 2. APNs (iOS Nativo)

**Pré-requisitos:**
- Device token (64 caracteres hex)
- Arquivo .p8 key do Apple Developer Portal
- Team ID (encontre em developer.apple.com)
- Key ID (do certificado .p8)
- Bundle ID do seu app

**Passos:**
1. Abra a aba APNs (⌘3)
2. Cole o device token
3. Preencha Bundle ID, Team ID, Key ID
4. Clique "Load .p8 Key" e selecione seu arquivo
5. Selecione "Sandbox" ou "Production"
6. Preencha título, corpo, etc.
7. Envie (⌘↵)

**Como obter um .p8 key:**
1. Acesse [Apple Developer](https://developer.apple.com/account/resources/authkeys/list)
2. Create a new key
3. Habilite "Apple Push Notifications service (APNs)"
4. Baixe o arquivo .p8
5. Anote o Key ID

---

### 3. Live Activity (iOS 16.1+)

**Pré-requisitos:**
- Activity token (obtido do seu app iOS)
- Mesmos requisitos do APNs (.p8, Team ID, etc.)

**Passos:**
1. Abra a aba Live Activity (⌘2)
2. Cole o activity token
3. Configure APNs (igual ao APNs nativo)
4. Selecione evento: "Update" ou "End"
5. Adicione content state (key-value pairs)
6. Envie (⌘↵)

**Exemplo de Content State:**
```
score: 42
team: Warriors
```

---

### 4. FCM (Android / Cross-platform)

**Pré-requisitos:**
- FCM registration token
- Server key ou OAuth token (do Firebase Console)

**Passos:**
1. Abra a aba FCM (⌘4)
2. Cole o FCM registration token
3. Adicione o server key
4. Preencha título e corpo
5. Configure Android settings (channel, priority, etc.)
6. Envie (⌘↵)

**Como obter Server Key:**
1. Acesse [Firebase Console](https://console.firebase.google.com)
2. Selecione seu projeto
3. Project Settings > Cloud Messaging
4. Copie o Server key

---

## 💡 Dicas Úteis

### Salvar Tokens
- Clique em "Save Token" em qualquer aba
- Dê um nome descritivo (ex: "iPhone 17 Pro - Dev")
- Tokens aparecem na seção "Saved Tokens"
- Use a seta para aplicar rapidamente

### Atalhos de Teclado
- `⌘1` - Expo
- `⌘2` - Live Activity
- `⌘3` - APNs
- `⌘4` - FCM
- `⌘↵` - Enviar push

### Visualizar Resposta
- A resposta da API aparece automaticamente após o envio
- Clique "Copy Response" para copiar o JSON
- Expanda/colapsar com a seta

### Gerar cURL
- Útil para debugging ou scripts
- Clique "Generate cURL" para ver o comando completo
- Copie e execute no Terminal

### Custom Data
- Adicione dados arbitrários ao payload
- Clique no "+" para adicionar key-value pairs
- Útil para deep linking e dados customizados

---

## 🔍 Troubleshooting

### "Invalid device token"
- Verifique se o token está correto (sem espaços)
- APNs tokens são 64 caracteres hex
- Expo tokens começam com `ExponentPushToken[`

### "HTTP 403 Forbidden" (APNs)
- Verifique Team ID, Key ID e Bundle ID
- Confirme que o arquivo .p8 está correto
- Certifique-se de que o certificado tem permissão para APNs

### "Invalid registration token" (FCM)
- Token pode ter expirado
- Certifique-se de usar o token mais recente do dispositivo

### "JWT token error" (APNs)
- A implementação atual usa um placeholder JWT
- Para produção, implemente ES256 signing com CryptoKit

---

## 🎯 Casos de Uso Comuns

### Desenvolvimento Local
1. Rode seu app iOS/Android
2. Copie o push token do console
3. Cole no PushLab
4. Salve com label "Development Device"
5. Teste rapidamente durante dev

### Testes de Qualidade
1. Salve múltiplos tokens (iPhone, iPad, Simulador)
2. Use custom data para testar deep linking
3. Gere cURL para automação de testes

### Debugging de Payload
1. Configure seu payload no PushLab
2. Clique "Generate cURL"
3. Analise o JSON completo
4. Ajuste e teste novamente

---

## 📚 Próximos Passos

Explore os recursos avançados:
- Android Specific settings (FCM)
- Background pushes (APNs)
- Priority levels (Expo)
- Live Activity Dynamic Island updates

Para mais informações, consulte o [README.md](README.md) completo.

---

**Desenvolvido com ❤️ usando SwiftUI**
