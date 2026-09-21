# Smart Sleep

Base inicial em Flutter de um despertador inteligente para Galaxy Watch (Wear OS).

Nesta versão o usuário escolhe uma janela de despertar e confirma o alarme. Já existe
a ponte Flutter ↔ Kotlin (Platform Channel), mas sensores, análise de sono e alarmes
reais ainda não estão implementados.

## Estrutura

- `lib/features/alarm/` — telas de seleção e confirmação da janela de despertar.
- `lib/services/native/native_bridge.dart` — único ponto que fala com a camada nativa.
- `android/app/src/main/kotlin/com/smartsleep/smart_sleep/MainActivity.kt` — lado Kotlin do canal.

## Ponte Flutter ↔ Kotlin

- Canal: `com.example.sleepalarm/native`
- Método: `getNativeStatus` → retorna `Native Android layer connected`

A tela inicial tem um botão temporário **"Testar conexão nativa"** que existe apenas
para comprovar que os dois lados se comunicam. Ele sai quando a integração real com
os sensores entrar.

## Como executar

1. Instale o [Flutter SDK](https://docs.flutter.dev/get-started/install) e coloque-o no PATH.
2. Rode o app em um dispositivo ou emulador Wear OS:

```bash
flutter pub get
flutter run
```

A pasta `android/` já existe no repositório. O `local.properties` e o Gradle wrapper
são gerados automaticamente pelo Flutter na primeira execução.

## Testes

```bash
flutter analyze
flutter test
```

Os testes de `test/native_bridge_test.dart` usam um `MethodChannel` simulado, então
rodam sem relógio conectado.
