# Release macOS

O projeto possui dois workflows no GitHub Actions:

- `CI`: compila o scheme compartilhado `PushLab` sem assinatura em `macos-26` para pushes e pull requests.
- `Release DMG`: workflow manual que assina, notariza e publica `dist/PushLab.dmg` como GitHub Release.

## Secrets necessários

Configure estes secrets no repositório antes de executar `Release DMG`:

| Secret | Valor |
| --- | --- |
| `APPLE_TEAM_ID` | Team ID do Apple Developer (`JX5SC3F52Q` neste projeto) |
| `DEVELOPER_ID_APPLICATION` | Nome exato, por exemplo `Developer ID Application: Nome (TEAMID)` |
| `BUILD_CERTIFICATE_BASE64` | Conteúdo base64 do `.p12` exportado do certificado pareado |
| `P12_PASSWORD` | Senha do `.p12` |
| `APPLE_API_KEY_ID` | Key ID da API do App Store Connect |
| `APPLE_API_ISSUER_ID` | Issuer ID da API do App Store Connect |
| `APPLE_API_KEY_BASE64` | Conteúdo base64 do `AuthKey_*.p8` |

O `.p12` deve conter o certificado e a chave privada pareados. Antes de subir o secret, valide o arquivo localmente:

```bash
openssl pkcs12 -in developer_id.p12 -nodes -passin pass:'SENHA' -legacy 2>&1 > /tmp/check.pem
grep -c "BEGIN CERTIFICATE\|BEGIN PRIVATE KEY" /tmp/check.pem
```

O resultado esperado é `2`.

## Criar uma release

Em Actions → `Release DMG` → `Run workflow`, informe uma tag como `v1.0.0` e escolha se ela será prerelease. O workflow cria a tag/release e publica o DMG depois que a Apple concluir a notarização.
