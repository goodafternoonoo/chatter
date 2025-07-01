# 내 채팅 앱

Flutter로 구축된 현대적인 채팅 애플리케이션으로, 강력한 백엔드 서비스를 위해 Supabase를 활용합니다. 이 애플리케이션은 실시간 업데이트 및 안전한 사용자 인증을 통해 원활한 메시징 경험을 제공합니다.

## 기능

-   **사용자 인증:** Supabase Auth로 구동되는 안전한 회원가입 및 로그인.
-   **실시간 메시징:** Supabase Realtime을 사용한 즉각적인 메시지 전송 및 표시.
-   **메시지 기록:** Supabase Database에서 채팅 메시지를 저장하고 검색.
-   **환경 변수 관리:** `flutter_dotenv`를 사용하여 API 키 및 민감한 정보를 안전하게 처리.
-   **로컬 데이터 저장:** `shared_preferences`로 사용자 기본 설정 및 세션 데이터를 효율적으로 관리.
-   **고유 ID 생성:** 메시지 및 기타 엔티티에 대한 고유 식별자를 생성하기 위해 `uuid` 활용.
-   **국제화:** `intl`을 통한 다국어 지원 준비.

## 사용된 기술

-   **Flutter:** 모바일, 웹, 데스크톱용 네이티브 컴파일 애플리케이션을 단일 코드베이스에서 구축하기 위한 UI 툴킷.
-   **Supabase:** PostgreSQL 데이터베이스, 인증, 인스턴트 API, 실시간 구독 및 스토리지를 제공하는 오픈 소스 Firebase 대체.
-   `supabase_flutter`: Supabase용 Flutter 클라이언트.
-   `flutter_dotenv`: `.env` 파일에서 환경 변수를 로드합니다.
-   `shared_preferences`: Flutter 앱을 위한 간단한 데이터 저장.
-   `uuid`: RFC4122 (v1, v3, v4, v5) UUID를 생성합니다.
-   `intl`: Flutter 앱을 위한 국제화 및 지역화.

## 시작하기

### 전제 조건

-   Flutter SDK 설치.
-   데이터베이스 및 인증이 구성된 Supabase 프로젝트 설정.

### 설치

1.  **저장소 복제:**

    ```bash
    git clone https://github.com/your-username/my_chat_app.git
    cd my_chat_app
    ```

2.  **종속성 설치:**

    ```bash
    flutter pub get
    ```

3.  **환경 변수 구성:**
    프로젝트 루트(pubspec.yaml 옆)에 `.env` 파일을 생성하고 Supabase 프로젝트 URL 및 익명 키를 추가합니다.

    ```
    SUPABASE_URL=YOUR_SUPABASE_URL
    SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
    ```

    `YOUR_SUPABASE_URL` 및 `YOUR_SUPABASE_ANON_KEY`를 실제 Supabase 프로젝트 자격 증명으로 바꿉니다.

### 애플리케이션 실행

연결된 장치 또는 에뮬레이터에서 앱을 실행하려면:

```bash
flutter run
```

## 프로젝트 구조

-   `lib/main.dart`: Flutter 애플리케이션의 진입점.
-   `lib/chat_page.dart`: 주요 채팅 인터페이스를 포함합니다.
-   `lib/chat_message.dart`: 개별 채팅 메시지의 구조 및 표시를 정의합니다.
-   `pubspec.yaml`: 프로젝트 종속성 및 메타데이터.
-   `.env`: 환경 변수 (Git에 의해 무시됨).

## 기여

기여를 환영합니다! Pull Request를 자유롭게 제출해주세요.

## 라이선스

이 프로젝트는 MIT 라이선스에 따라 라이선스가 부여됩니다. 자세한 내용은 `LICENSE` 파일을 참조하십시오.
