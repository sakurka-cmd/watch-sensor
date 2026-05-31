# WatchSensor — Apple Watch complication для esp32-sensor-monitor

watchOS-приложение, отображающее температуру, давление и влажность
с домашней метеостанции [esp32-sensor-monitor](https://github.com/sakurka-cmd/esp32-sensor-monitor)
прямо на циферблате Apple Watch.

---

## Что умеет

| Элемент | Описание |
|---|---|
| **Приложение** | Полный экран с температурой (крупно), давлением и влажностью |
| **Complication** | Виджет на циферблате — показывает температуру |
| **Настройки** | Смена URL сервера прямо на часах (редко нужно) |
| **Обновление** | Приложение — по кнопке; complication — каждые ~15 мин автоматически |

---

## Архитектура

```
┌──────────────────────┐
│  ESP32 (датчики)      │
│  BMP280 + AHT20       │
│  WiFi → HTTP POST     │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Flask server (:5000) │
│  GET /api/latest      │  ← этот endpoint использует watchOS
│  → JSON:              │
│  { temperature: 21.5, │
│    pressure: 740.4,   │
│    humidity: 55.3,     │
│    timestamp: "..." }  │
└──────────┬───────────┘
           │
     WiFi (локальная сеть)
           │
           ▼
┌──────────────────────────────────┐
│  Apple Watch                    │
│  ┌───────────┐ ┌──────────────┐ │
│  │ Приложение │ │ Complication │ │
│  │ (ContentView)│ │ (WidgetKit)  │ │
│  │ GET /api/latest при        │ │
│  │ открытии / по кнопке       │ │
│  │              │ │ GET /api/latest │ │
│  │              │ │ раз в 15 мин   │ │
│  └─────────────┘ └──────────────┘ │
│  Общие настройки через App Group  │
└──────────────────────────────────┘
```

---

## Требования

- **Mac** с Xcode 15+ (Apple Silicon или Intel)
- **Apple Developer Account** — бесплатный достаточно для установки на свои устройства
- **iPhone + Apple Watch** (парные, watchOS 10+)
- **Работающий Flask-сервер** esp32-sensor-monitor в той же WiFi-сети

---

## Установка за 10 минут

### Шаг 1. Создать проект в Xcode

1. Запусти **Xcode → File → New → Project**
2. Выбери **watchOS → Watch App → Next**
3. Укажи:
   - Product Name: **WatchSensor**
   - Team: выбери свой Apple ID
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Uncheck «Include Tests»
4. Сохрани проект

### Шаг 2. Добавить Widget Extension (для complications)

1. **File → New → Target**
2. Выбери **watchOS → Widget Extension → Next**
3. Product Name: **WatchSensorWidget**
4. Uncheck «Include Configuration App Intent»
5. **Activate** когда Xcode предложит активировать схему

### Шаг 3. Настроить App Group (общие настройки между приложением и виджетом)

1. В Xcode открой **WatchSensor** target → **Signing & Capabilities**
2. Нажми **+ Capability** → добавь **App Groups**
3. Создай группу: `group.com.sakurka.watchsensor`
4. Повтори то же самое для **WatchSensorWidget** target → **Signing & Capabilities** → **+ Capability** → **App Groups**
5. Выбери ту же группу `group.com.sakurka.watchsensor`

### Шаг 4. Скопировать файлы из репозитория

**Приложение (target WatchSensor)** — замени файлы в Xcode:
| Файл из репозитория | Что делает |
|---|---|
| `WatchSensorApp/WatchSensorApp.swift` | @main, точка входа приложения |
| `WatchSensorApp/ContentView.swift` | Основной экран (температура, давление, влажность) |
| `WatchSensorApp/SettingsView.swift` | Экран настройки URL сервера |
| `WatchSensorApp/SensorData.swift` | Codable-модели для JSON |
| `WatchSensorApp/SensorAPI.swift` | HTTP-клиент для Flask API |

**Widget Extension (target WatchSensorWidget)** — замени файлы:
| Файл из репозитория | Что делает |
|---|---|
| `WatchSensorWidget/WatchSensorWidgetBundle.swift` | @main для Widget Bundle |
| `WatchSensorWidget/SensorWidget.swift` | Определение виджета + views для каждого типа complication |
| `WatchSensorWidget/SensorProvider.swift` | TimelineProvider (загрузка данных, расписание обновлений) |

Важно: файлы `SensorData.swift` и `SensorAPI.swift` нужно **добавить в оба target**
(в Xcode: File Inspector → Target Membership → галочки на WatchSensor и WatchSensorWidget).

### Шаг 5. Настроить App Transport Security (HTTP разрешён)

По умолчанию watchOS блокирует HTTP-запросы. Для локального сервера нужно разрешить:

**Способ A — через Info.plist (рекомендуется):**

Для **каждого** target (WatchSensor и WatchSensorWidget) открой Info.plist и добавь:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>192.168.0.3</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

> Замени `192.168.0.3` на реальный IP твоего сервера.
> Если IP может меняться, используй `NSAllowsArbitraryLoads: true` (менее безопасно, но проще).

**Способ B — через Xcode UI:**

1. Target → Info → Custom iOS Target Properties
2. Добавь ключ `App Transport Security Settings` (Dictionary)
3. Внутри → `Allow Arbitrary Loads` = `YES`

### Шаг 6. Сборка и запуск

1. Выбери схему **WatchSensor Watch App**
2. Выбери устройство: **[название твоих] Apple Watch**
3. **Cmd+R** — сборка и запуск
4. При первом запуске на iPhone появится запрос доверия разработчику:
   Settings → General → VPN & Device Management → доверь свой сертификат

### Шаг 7. Добавить complication на циферблат

1. На Apple Watch (или в приложении Watch на iPhone)
2. **Force Touch** на циферблат → **Изменить**
3. Прокрути до **Complications**
4. Выбери позицию (например, нижний угол)
5. Выбери **WatchSensor → Датчик**
6. Выбери стиль:
   - **Circular Small** — маленький кружок с температурой
   - **Corner** — gauge с температурой
   - **Graphic Circular** — большой круг с иконкой термометра
   - **Graphic Corner** — температура + влажность

---

## Типы complications

| Тип complication | Что показывает | Где на циферблате |
|---|---|---|
| **Circular Small** | `21°` (текст) | Маленький кружок |
| **Corner** | Gauge + `21.5°C` | Угол циферблата |
| **Graphic Circular** | 🌡 + `21.5°` (большой круг) | Центр или верхняя позиция |
| **Graphic Corner** | `21.5°C` + `55%` | Угол (два значения) |

---

## Настройка URL сервера

По умолчанию приложение подключается к `http://192.168.0.3:5000`.
Чтобы сменить адрес:

1. Открой приложение на Apple Watch
2. Нажми шестерёнку ⚙ в верхнем левом углу
3. Введи новый URL (например `http://192.168.1.100:5000`)
4. Нажми «Сохранить»

> Настройка сохраняется в App Group (общая между приложением и complication),
> поэтому complication тоже начнёт использовать новый URL.

---

## Ограничения

| | Описание |
|---|---|
| **Частота обновления** | watchOS обновляет complication минимум раз в 15 минут. Система может увеличить интервал для экономии батареи. |
| **Только локальная сеть** | HTTP-соединение работает только в домашнем WiFi. Для обновления вне дома нужен VPN или проброс порта (Cloudflare Tunnel / Tailscale). |
| **Нет истории** | Приложение показывает только текущие значения. Графики — в веб-дашборде Flask. |

---

## Структура файлов

```
WatchSensor/
├── WatchSensorApp/                 ← Target: WatchSensor (приложение)
│   ├── WatchSensorApp.swift        ←   @main entry point
│   ├── ContentView.swift           ←   Основной экран UI
│   ├── SettingsView.swift          ←   Настройки URL сервера
│   ├── SensorData.swift            ←   Модели API-ответов (shared)
│   └── SensorAPI.swift             ←   HTTP-клиент (shared)
├── WatchSensorWidget/              ← Target: WatchSensorWidget (complication)
│   ├── WatchSensorWidgetBundle.swift ←  @main Widget Bundle
│   ├── SensorWidget.swift          ←   Виджет + views для каждого типа
│   └── SensorProvider.swift        ←   TimelineProvider (обновление данных)
└── README.md
```

---

## Зависимости

Нет внешних зависимостей. Только стандартные фреймворки Apple:
- `SwiftUI`
- `WidgetKit`
- `Foundation` (URLSession, JSONDecoder)
