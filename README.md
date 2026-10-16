# 🌾 SSAL (쌀) - 오프라인 퍼스트 게임 자산 및 거래 관리 앱

안드로이드 스마트폰에서 단독으로 실행되는 **오프라인 퍼스트(Offline-First)** 방식의 게임 자산, 거래소 수수료 계산 및 환전 관리 앱입니다.  
서버 없이 스마트폰 기기 내부의 **SQLite 로컬 데이터베이스**를 활용하여 네트워크 연결 없이도 안전하고 빠르게 데이터를 저장·관리합니다.

---

## 📱 핵심 기능 명세 및 구현 매핑

| 번호 | 요구사항 | 구현 위치 및 설명 |
|---|---|---|
| **1** | **게임(대그룹) 관리** | `lib/screens/game_server_screen.dart`<br>• 여러 게임 추가, 이름/메모 수정, 삭제 기능 (연관 데이터 CASCADE 연동) |
| **2** | **서버(중그룹) 관리** | `lib/screens/game_server_screen.dart`<br>• 각 게임 하위에 여러 개의 서버 등록, 수정, 삭제 |
| **3** | **거래소 수수료 설정** | `lib/screens/game_server_screen.dart`<br>• 서버별 거래소 수수료율(%) 직접 입력 및 저장 (예: 5.0%, 10.0% 등) |
| **4** | **캐릭터 및 계정 관리** | `lib/screens/character_manage_screen.dart`<br>• 서버별 캐릭터명, 연동 계정 정보(구글, 카카오 등), 메모 등록 및 관리 |
| **5** | **캐릭터별 보유 재화 관리** | `lib/screens/character_manage_screen.dart`<br>• 다이아, 골드, 쌀 등 커스텀 재화 등록, 수량 실시간 수정 (+1,000 / +10,000 등 퀵 증감 버튼) |
| **6** | **거래소 아이템 등록 & 수수료 자동 계산** | `lib/screens/market_calculator_screen.dart`<br>• 캐릭터별 아이템 등록 (가격, 수량)<br>• **해당 서버의 수수료율 자동 로드 ➔ 우측에 실수령액 실시간 자동 계산 표시**<br>• 로컬 저장 및 '판매중'/'판매완료' 상태 전환 |
| **7** | **환전 및 출금 수수료 관리** | `lib/screens/exchange_screen.dart`<br>• 판매 재화 수량 및 환율 입력 ➔ 기본 환전 총액 계산<br>• **'출금 수수료' 체크박스 기능**: 체크 시 최종 금액에서 추가 차감(-1,000원 등 조정 가능)<br>• 최종 실수령 KRW 금액 산출 및 로컬 히스토리 저장 |
| **앱바** | **SSAL 로고 및 타이틀** | `lib/widgets/ssal_app_bar.dart`<br>• 골드 쌀알 로고 엠블럼과 'SSAL' 타이틀 명시 |

---

## 🏗 프로젝트 디렉토리 구조

```plaintext
SSAL/
├── android/                   # 안드로이드 빌드 설정 (AndroidManifest, Gradle)
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/com/example/ssal/MainActivity.kt
│   ├── build.gradle
│   └── settings.gradle
├── lib/
│   ├── main.dart              # 앱 진입점 및 Provider 초기화
│   ├── theme/
│   │   └── app_theme.dart     # 다크 & 골드 프리미엄 게이밍 테마
│   ├── models/                # 데이터 모델 (JSON/Map 변환, 계산 로직)
│   │   ├── game_model.dart
│   │   ├── server_model.dart
│   │   ├── character_model.dart
│   │   ├── currency_model.dart
│   │   ├── market_item_model.dart
│   │   └── exchange_record_model.dart
│   ├── database/
│   │   └── db_helper.dart     # SQLite 데이터베이스 (테이블 생성, 외래키 CASCADE, CRUD, 샘플 시딩)
│   ├── providers/
│   │   └── ssal_provider.dart # ChangeNotifier 기반 전역 상태 관리
│   ├── screens/               # 5대 화면
│   │   ├── dashboard_screen.dart          # 홈 개요 및 바텀 네비게이션
│   │   ├── game_server_screen.dart        # 게임 및 서버(수수료율) 관리
│   │   ├── character_manage_screen.dart   # 캐릭터 및 재화 관리
│   │   ├── market_calculator_screen.dart  # 거래소 아이템 등록 & 실수령액 계산
│   │   └── exchange_screen.dart           # 환전 및 출금 수수료 계산/히스토리
│   └── widgets/
│       └── ssal_app_bar.dart  # 브랜딩 앱바
├── pubspec.yaml               # 의존성 설정 (sqflite, provider, intl 등)
└── README.md                  # 설명서
```

---

## 🗄 로컬 데이터베이스 (SQLite) 구조

- **`games`**: `id` (PK), `name`, `memo`, `created_at`
- **`servers`**: `id` (PK), `game_id` (FK ➔ games), `name`, `fee_rate` (수수료율 %), `memo`, `created_at`
- **`characters`**: `id` (PK), `server_id` (FK ➔ servers), `name`, `account_info` (연동 계정), `note`, `created_at`
- **`currencies`**: `id` (PK), `character_id` (FK ➔ characters), `name` (재화명), `amount` (수량), `updated_at`
- **`market_items`**: `id` (PK), `character_id` (FK ➔ characters), `item_name`, `price`, `quantity`, `fee_rate`, `net_amount` (실수령액), `status`, `created_at`
- **`exchange_records`**: `id` (PK), `character_id`, `character_name`, `server_name`, `currency_name`, `currency_amount`, `exchange_rate`, `gross_amount`, `fee_rate`, `fee_amount`, `is_withdraw_fee_applied` (출금수수료 0/1), `withdraw_fee` (금액), `net_krw_amount`, `memo`, `created_at`

---

## 🚀 로컬 실행 및 APK 빌드 방법

### 1. Flutter 환경 준비
Flutter SDK가 설치되어 있지 않다면 [Flutter 공식 홈페이지](https://flutter.dev)에서 SDK를 다운로드하여 PATH에 등록합니다.

```bash
flutter doctor
```

### 2. 패키지 설치
프로젝트 루트 디렉토리에서 패키지를 다운로드합니다:
```bash
flutter pub get
```

### 3. 디버그 및 로컬 테스트 실행
스마트폰을 USB로 연결하거나 안드로이드 에뮬레이터가 켜진 상태에서:
```bash
flutter run
```

### 4. 📦 단독 실행형 안드로이드 APK 파일 빌드
인터넷 없이 스마트폰에 바로 설치 가능한 릴리즈 APK를 생성합니다:
```bash
flutter build apk --release
```

- 빌드가 완료되면 아래 경로에 APK 파일이 생성됩니다:
  ```plaintext
  build/app/outputs/flutter-apk/app-release.apk
  ```
- 이 APK 파일을 스마트폰으로 복사(USB 또는 카카오톡 나에게 보내기 등)한 후 터치하여 설치하시면 단독으로 즉시 사용할 수 있습니다.
