# Smart Sleep

Base inicial em Flutter de um despertador inteligente para Galaxy Watch (Wear OS).

Nesta versão o usuário escolhe uma janela de despertar e confirma o alarme. Sensores, análise de sono e integração nativa ainda não estão implementados.

## Como executar

1. Instale o [Flutter SDK](https://docs.flutter.dev/get-started/install) e coloque-o no PATH.
2. Na pasta do projeto, gere as pastas nativas (Android/iOS) se ainda não existirem:

```bash
flutter create . --project-name smart_sleep --org com.smartsleep
```

3. Rode o app:

```bash
flutter pub get
flutter run
```
