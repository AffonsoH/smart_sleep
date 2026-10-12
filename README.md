# Smart Sleep

Despertador inteligente para Galaxy Watch (Wear OS), em Flutter com camada
nativa em Kotlin.

Você escolhe uma janela, por exemplo 06:30 → 07:00. Durante a janela o app
observa o movimento do pulso pelo acelerômetro e toca o alarme no primeiro
minuto em que detecta movimento — o palpite de sono mais leve. Se isso não
acontecer, o alarme toca no fim da janela, sem exceção.

## Estado atual

| Parte | Situação |
|---|---|
| Seleção da janela e validação | Implementado |
| Ponte Flutter ↔ Kotlin | Implementado e testado no relógio |
| Agendamento no AlarmManager | Implementado, **falta testar no relógio** |
| Serviço em primeiro plano + acelerômetro | Implementado, **falta testar no relógio** |
| Heurística de movimento | Implementada com limiar **não calibrado** |
| Alarme (notificação, tela cheia, vibração) | Implementado, **falta testar no relógio** |
| Frequência cardíaca / Samsung Health | Não implementado |
| Religar o alarme após reiniciar o relógio | Não implementado |

Tudo que está marcado como "falta testar" foi escrito e revisado de forma
estática, mas nunca compilado nem executado — veja [Limitações](#limitações-conhecidas).

## Como o despertar é decidido

O desenho separa o que **precisa** funcionar do que é **otimização**:

- **Garantia:** no início, o app agenda `AlarmManager.setAlarmClock` para o
  fim da janela. É a única categoria de alarme que o Android nunca adia e que
  tira o aparelho do Doze. Ela funciona mesmo que o serviço seja morto, que o
  app seja fechado ou que o acelerômetro não exista.
- **Otimização:** um serviço em primeiro plano liga o acelerômetro no início
  da janela, agrega o movimento em janelas de 1 minuto e, no primeiro minuto
  acima do limiar, toca mais cedo e cancela o alarme do fim.

O cálculo por amostra, em `SleepMonitorService`:

1. `magnitude = √(x² + y² + z²)`
2. uma média móvel (`GRAVITY_ALPHA = 0.05`) estima a gravidade;
3. `movimento = |magnitude − gravidade|`, descartando o que for menor que
   `NOISE_FLOOR = 0.15 m/s²`;
4. soma do movimento no minuto ≥ `ACTIVITY_THRESHOLD = 12.0` → desperta.

**O limiar de 12.0 é um chute inicial, não um valor calibrado.** Cada minuto é
enviado ao app pelo EventChannel e aparece na tela durante o monitoramento;
use uma noite real para ajustar a constante em `SleepMonitorService.kt`.

Isto não é detecção de fases do sono. É um detector de movimento, que é o que
um acelerômetro sozinho permite afirmar.

## Arquitetura

```
lib/
  app/app.dart                                  MaterialApp
  features/alarm/presentation/pages/
    alarm_gate.dart                             estado do alarme e roteamento
    home_page.dart                              configuração e monitoramento
    time_editor_page.dart                       seletor de horário do relógio
    confirmation_page.dart                      confirmação da janela
    alarm_ringing_page.dart                     tela do alarme tocando
  features/alarm/data/models/alarm_settings.dart  janela e próxima ocorrência
  services/native/native_bridge.dart            único ponto que fala com o nativo

android/app/src/main/kotlin/com/smartsleep/smart_sleep/
  AlarmContract.kt          nomes de canais, ações e chaves
  MainActivity.kt           MethodChannel e EventChannel
  SleepAlarmScheduler.kt    AlarmManager (início e fim da janela)
  SleepAlarmReceiver.kt     recebe os dois instantes agendados
  SleepMonitorService.kt    serviço em primeiro plano, acelerômetro, heurística
  AlarmNotifier.kt          canais de notificação, alarme e vibração
  SleepPrefs.kt             estado em disco, sobrevive à morte do processo
  SleepEventBridge.kt       eventos do nativo para o Flutter
```

A UI nunca usa `MethodChannel` direto: tudo passa por `NativeBridge`. O estado
verdadeiro mora no lado nativo, porque serviço e alarme continuam rodando com
o app fechado; o Flutter lê esse estado ao abrir e ao voltar do segundo plano.

Canais: `com.example.sleepalarm/native` (métodos) e
`com.example.sleepalarm/events` (eventos).

## Permissões

| Permissão | Para quê | Concedida |
|---|---|---|
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_HEALTH` + `FOREGROUND_SERVICE_SPECIAL_USE` | serviço que observa o movimento | instalação |
| `ACTIVITY_RECOGNITION` | permite o serviço subir como tipo `health` no Android 14+; sem ela ele sobe como `specialUse` | em tempo de execução |
| `WAKE_LOCK` | manter a CPU acordada durante a amostragem | instalação |
| `USE_EXACT_ALARM` | alarme exato que atravessa o Doze | instalação |
| `VIBRATE` | vibração do alarme | instalação |
| `POST_NOTIFICATIONS` | mostrar o alarme na tela | em tempo de execução (Android 13+) |
| `USE_FULL_SCREEN_INTENT` | abrir o alarme por cima da tela bloqueada | instalação |

Ler o acelerômetro **não** exige permissão. O app pede as duas de execução na
primeira vez em que elas faltam, e continua funcionando sem elas, com aviso na
tela.

## Como instalar e testar

Requer **Flutter stable 3.47 ou mais recente** (a pasta `android/` segue o
template dessa versão: Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0).

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug      # APK em build/app/outputs/flutter-apk/app-debug.apk
flutter run                    # com o relógio pareado por ADB
```

Roteiro de teste no relógio, do mais rápido ao mais lento:

1. **Fluxo de configuração:** abrir o app, tocar nos cartões de horário,
   mudar início e fim, confirmar. Nenhuma tela vermelha, nenhuma faixa
   amarela de overflow.
2. **Agendamento:** definir a janela para daqui a ~3 minutos (início) e ~5
   minutos (fim) e tocar em "Iniciar alarme". A notificação permanente deve
   aparecer e a tela deve mostrar a janela armada.
3. **Monitoramento:** no início da janela a tela passa a mostrar "Observando
   o movimento do pulso" e a barra de movimento começa a se mover. Mexer o
   pulso deve fazer o valor subir.
4. **Despertar por movimento:** mexer o braço com firmeza durante a janela.
   O alarme deve vibrar e abrir a tela "Hora de acordar".
5. **Despertar garantido:** repetir deixando o relógio parado na mesa, com a
   tela apagada, e conferir se o alarme toca no fim da janela.
6. **Com o app fechado:** repetir o item 5 fechando o app depois de armar.

## Limitações conhecidas

- **Nada foi compilado nem executado.** O ambiente onde este código foi
  escrito não tem Flutter, Dart nem Android SDK, e os hosts para instalá-los
  estão bloqueados. Foram feitas apenas checagens estáticas: XML válido,
  referências cruzadas do Kotlin, consistência dos canais e APIs conferidas
  contra a documentação oficial. Erros de compilação são plausíveis.
- **O limiar de movimento não é calibrado** (veja acima).
- **Sem frequência cardíaca.** O acelerômetro sozinho não distingue fases do
  sono. A arquitetura aceita uma segunda fonte depois: basta somar outro
  sensor no `SleepMonitorService` e combinar no mesmo agregado por minuto.
- **O alarme não sobrevive a reiniciar o relógio.** Falta tratar
  `ACTION_BOOT_COMPLETED` para reagendar.
- **Consumo de bateria durante a janela:** a amostragem usa um wake lock
  parcial, necessário porque o acelerômetro comum para de entregar eventos
  com a CPU dormindo. O custo fica limitado à duração da janela.
- **Serviço em background no Android 12+:** quando o serviço precisa subir a
  partir do alarme do fim da janela, o sistema pode recusar. Por isso o
  alarme é postado como notificação antes de tentar o serviço, e o canal de
  alarme já vibra sozinho.
- **Sem persistência de histórico.** Os valores de movimento são exibidos ao
  vivo e descartados.
