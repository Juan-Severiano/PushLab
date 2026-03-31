# Contributing to PushLab

Obrigado pelo interesse em contribuir com o PushLab! 🎉

## Como Contribuir

### Reportar Bugs

Se você encontrou um bug, por favor abra uma issue com:
- Descrição clara do problema
- Passos para reproduzir
- Comportamento esperado vs atual
- Screenshots (se aplicável)
- Versão do macOS e do Xcode

### Sugerir Features

Para sugerir novas features:
- Verifique se já não existe uma issue similar
- Descreva claramente o problema que a feature resolveria
- Explique como você gostaria que funcionasse
- Considere se é uma feature P2 ou P3 (veja TODO.md)

### Pull Requests

1. **Fork o repositório**
2. **Crie uma branch** para sua feature (`git checkout -b feature/MinhaFeature`)
3. **Faça commit** das suas mudanças (`git commit -m 'Add: Minha feature incrível'`)
4. **Push** para a branch (`git push origin feature/MinhaFeature`)
5. **Abra um Pull Request**

### Convenções de Código

#### Swift Style Guide
- Siga o [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use 4 espaços para indentação
- Máximo de 120 caracteres por linha
- Use nomes descritivos para variáveis e funções

#### Estrutura de Commits
```
Type: Breve descrição (max 50 chars)

Descrição detalhada do que foi mudado e por quê.
Use o corpo do commit para explicar "o quê" e "por quê", não "como".

Fixes #123
```

**Types:**
- `Add:` - Nova feature
- `Fix:` - Bug fix
- `Refactor:` - Refatoração de código
- `Docs:` - Mudanças na documentação
- `Style:` - Formatação, sem mudança de código
- `Test:` - Adição/correção de testes
- `Chore:` - Manutenção/tarefas

#### Exemplo
```
Add: Support for APNs HTTP/2 push priority

Implementa suporte ao header apns-priority, permitindo
controlar a prioridade de entrega das notificações APNs.

- Adiciona campo de prioridade no APNsViewModel
- Atualiza PushService para enviar header correto
- Adiciona testes para validação de prioridade

Fixes #42
```

### Estrutura de Arquivos

Ao adicionar novos arquivos, siga a estrutura:

```
PushLab/
├── Models/          # Structs e Models de dados
├── Services/        # Lógica de negócio e APIs
├── ViewModels/      # ViewModels (MVVM)
├── Modules/         # Views das abas principais
├── Components/      # Componentes reutilizáveis
├── Views/           # Views auxiliares (Settings, etc)
├── Extensions/      # Extensions de tipos Swift/SwiftUI
└── Shared/          # Código compartilhado (AppSettings, etc)
```

### Testes

- Adicione unit tests para novos ViewModels
- Adicione testes para Services que fazem chamadas de API
- Use mocks para testar sem depender de APIs reais

Exemplo de teste:
```swift
import Testing

@Suite("Expo ViewModel Tests")
struct ExpoViewModelTests {
    
    @Test("Should validate Expo token format")
    func validateExpoToken() {
        let viewModel = ExpoViewModel()
        viewModel.tokens = "ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]"
        
        #expect(!viewModel.tokens.isEmpty)
        #expect(viewModel.tokens.isValidExpoToken)
    }
}
```

### Documentação

- Documente funções públicas com comentários
- Atualize o README.md se necessário
- Adicione exemplos ao PAYLOAD_EXAMPLES.md se aplicável

Exemplo de documentação:
```swift
/// Envia uma notificação via Expo Push API
/// 
/// - Parameters:
///   - payload: O payload da notificação contendo tokens e conteúdo
///   - accessToken: Token de acesso opcional para autenticação
/// 
/// - Returns: Tupla com a resposta decodificada e o JSON raw
/// 
/// - Throws: `PushServiceError` se houver erro na requisição
func sendExpoNotification(
    payload: ExpoNotificationPayload,
    accessToken: String? = nil
) async throws -> (response: ExpoResponse, rawJSON: String) {
    // Implementation
}
```

### Prioridades

Consulte o [TODO.md](TODO.md) para ver as prioridades:
- **P1**: MVP (já implementado)
- **P2**: Features da v1.1 (próxima)
- **P3**: Features da v2.0 (futuro)

Contribuições em features P2 são mais urgentes.

## Desenvolvimento

### Setup do Ambiente

1. Clone o repositório:
```bash
git clone https://github.com/franciscojuan/pushlab.git
cd pushlab
```

2. Abra no Xcode:
```bash
open PushLab.xcodeproj
```

3. Build e execute:
- Pressione `⌘R` ou clique no botão Run

### Testando

1. Execute os testes:
```bash
⌘U
```

2. Teste manual:
- Use tokens de teste (veja QUICKSTART.md)
- Teste em diferentes versões do macOS se possível

## Dúvidas?

Se tiver dúvidas:
- Abra uma issue com a tag `question`
- Consulte a documentação no README.md
- Veja exemplos de código existente

## Código de Conduta

- Seja respeitoso com outros contribuidores
- Aceite críticas construtivas
- Foque no que é melhor para o projeto
- Seja paciente e ajude outros quando possível

## Agradecimentos

Muito obrigado por contribuir com o PushLab! Toda ajuda é bem-vinda. 🙌

---

**Happy coding! 🚀**
