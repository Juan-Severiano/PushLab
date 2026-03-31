# TODO - PushLab

## ✅ MVP Completo (P1)

- [x] Estrutura base do projeto
- [x] Models (SavedToken, Payloads)
- [x] Services (KeychainService, PushService)
- [x] ViewModels para todas as abas
- [x] Views dos 4 módulos principais
- [x] Components compartilhados (TokenRow, ResponsePanel, CURLModal)
- [x] Sistema de tabs com atalhos de teclado
- [x] Salvamento de tokens com SwiftData
- [x] Response viewer com JSON expandível
- [x] cURL export
- [x] Custom data key-value pairs
- [x] Documentação (README, QUICKSTART, PAYLOAD_EXAMPLES)

---

## 🚧 P2 - v1.1 (Próxima Sprint)

### Menu Bar App
- [ ] Converter de WindowGroup para MenuBarExtra
- [ ] Configurar NSStatusItem
- [ ] Implementar popover ao clicar no ícone
- [ ] Criar ícone customizado para menu bar

### Floating Window (Pinned)
- [ ] Implementar NSPanel
- [ ] Configurar `.nonactivatingPanel` behavior
- [ ] Adicionar toggle Pin/Unpin
- [ ] Frosted glass background
- [ ] Level `.floating` para ficar sempre visível

### Launch at Login
- [ ] Implementar SMAppService (macOS 13+)
- [ ] Adicionar toggle em Settings
- [ ] Configurar Login Item
- [ ] Testar em sistemas com e sem permissão

### Advanced Settings
- [ ] Seção colapsável "Advanced" em cada aba
- [ ] iOS Specific (APNs): thread-id, category, mutable-content
- [ ] Android Specific (FCM): TTL, collapse key, notification count
- [ ] Expo: ttl, expiration, mutableContent

### Histórico de Envios
- [ ] Model `PushHistory` com SwiftData
- [ ] Persistir envios bem-sucedidos
- [ ] View de histórico com filtros
- [ ] Ação "Re-send" a partir do histórico

---

## 🎯 P3 - v2.0 (Futuro)

### UI/UX
- [ ] Sistema de temas (Light/Dark/Auto)
- [ ] Temas customizados (cores accent)
- [ ] Animações de transição entre abas
- [ ] Feedback visual melhorado

### Templates
- [ ] Sistema de templates de payload
- [ ] Templates pré-configurados (welcome, alert, update, etc.)
- [ ] Criar/salvar templates customizados
- [ ] Importar/exportar templates como JSON

### Import/Export
- [ ] Exportar tokens salvos como JSON/CSV
- [ ] Importar tokens de arquivo
- [ ] Backup/restore de configurações
- [ ] Compartilhar configuração entre devices

### Workspaces
- [ ] Múltiplos workspaces (Dev, Staging, Prod)
- [ ] Switching rápido entre workspaces
- [ ] Configurações por workspace
- [ ] Sincronização via iCloud (opcional)

### Xcode Integration
- [ ] Scheme launch support
- [ ] Deep link para abrir PushLab com payload pré-preenchido
- [ ] URL scheme: `pushlab://expo?token=...&title=...`

### Batch Operations
- [ ] Enviar para múltiplos tokens simultaneamente
- [ ] Progress indicator para batch sends
- [ ] Relatório de sucesso/falha por token

---

## 🔧 Melhorias Técnicas

### APNs JWT Signing (CRÍTICO)
- [ ] Implementar ES256 signing com CryptoKit
- [ ] Carregar e parsear chave .p8 corretamente
- [ ] Gerar JWT válido com timestamp
- [ ] Cache de JWT (válido por 60min)
- [ ] Auto-renovação de JWT expirado

### FCM API v1
- [ ] Integração completa com OAuth2
- [ ] Service Account JSON upload
- [ ] Auto-refresh de access token
- [ ] Suporte a FCM v1 features completas

### Error Handling
- [ ] Error types específicos por serviço
- [ ] Mensagens de erro user-friendly
- [ ] Retry logic para falhas de rede
- [ ] Validação de campos antes de enviar

### Testing
- [ ] Unit tests para ViewModels
- [ ] Unit tests para Services
- [ ] Mock responses para desenvolvimento
- [ ] UI tests básicos
- [ ] Integration tests com APIs reais (sandbox)

### Performance
- [ ] Lazy loading de views pesadas
- [ ] Debounce em text fields
- [ ] Async loading de tokens salvos
- [ ] Cache de responses recentes

---

## 🎨 Features Opcionais

### Notificações
- [ ] Notificação local quando push é enviado
- [ ] Sound feedback opcional
- [ ] Badge count no dock icon

### Clipboard
- [ ] Auto-detect de token copiado
- [ ] Sugestão para salvar token detectado
- [ ] Parse de JSON de payload completo

### Shortcuts
- [ ] Mais keyboard shortcuts
- [ ] Customização de shortcuts
- [ ] Quick actions menu

### Developer Tools
- [ ] JSON validator com syntax highlighting
- [ ] Payload size calculator
- [ ] Token validator/parser
- [ ] Network inspector (request/response details)

### Analytics
- [ ] Contador de pushes enviados
- [ ] Success rate tracking
- [ ] Charts de uso por tipo de push
- [ ] Export de analytics

---

## 🐛 Bugs Conhecidos

_Nenhum bug conhecido no momento_

---

## 📝 Documentação Pendente

- [ ] Video tutorial/demo
- [ ] Screenshots para README
- [ ] API documentation
- [ ] Contributing guidelines
- [ ] Changelog

---

## 🚀 Distribuição

### Mac App Store
- [ ] Configurar sandbox entitlements
- [ ] Network client entitlement
- [ ] File access (NSOpenPanel only)
- [ ] App Store screenshots
- [ ] Privacy policy
- [ ] App Store listing

### Direct Distribution
- [ ] Code signing
- [ ] Notarization
- [ ] DMG creation
- [ ] Sparkle framework (auto-update)
- [ ] Release notes

---

## 💡 Ideias Futuras

- [ ] Plugin system para custom providers
- [ ] REST API mock server integrado
- [ ] Device simulator para testar recebimento
- [ ] Integration com Postman
- [ ] CLI tool companion
- [ ] iOS companion app (visualizar pushes recebidos)
- [ ] Browser extension para copiar tokens
- [ ] Slack/Discord integration (enviar push via bot)
- [ ] Scheduled pushes (cron-like)

---

**Última atualização:** 31/03/2026
**Versão atual:** 1.0.0 (MVP)
**Próxima versão:** 1.1.0 (P2)
