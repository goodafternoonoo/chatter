# Copilot Instructions for my_chat_app

이 문서는 AI 코딩 에이전트가 `my_chat_app` Flutter 프로젝트에서 즉시 생산적으로 작업할 수 있도록 핵심 구조, 워크플로우, 관례를 안내합니다.

## 필수사항

-   **AI 언어**: 모든 응답은 한국어로 작성합니다.

## 아키텍처 및 주요 컴포넌트

-   **Flutter 기반 멀티플랫폼 앱**: 모바일, 웹, 데스크톱 지원.
-   **Supabase**: 인증, 실시간 메시징, 데이터 저장의 백엔드로 사용.
-   **lib/main.dart**: 앱 진입점, Supabase 초기화 및 라우팅 설정.
-   **lib/screens/**: 주요 UI 화면(예: `chat_page.dart`는 채팅 인터페이스).
-   **lib/models/**: 데이터 모델 정의(예: `message.dart`).
-   **lib/services/**: 외부 API, 데이터베이스, 인증 등 비즈니스 로직 분리.
-   **lib/providers/**: 상태 관리(Provider 패턴 활용).
-   **lib/constants/**: 앱 전역 상수 및 UI 상수 분리.
-   **lib/utils/**: 유틸리티 함수 모음.

## 데이터 흐름 및 통신

-   **실시간 메시지**: Supabase Realtime을 통해 메시지 송수신.
-   **상태 관리**: Provider 패턴으로 화면 간 상태 공유.
-   **환경 변수**: `flutter_dotenv`로 `.env` 파일에서 로드(예: Supabase 키).

## 개발 워크플로우

-   **빌드/실행**: `flutter run` (기본), 플랫폼별 빌드는 `flutter build <platform>`
-   **의존성 설치**: `flutter pub get`
-   **테스트**: `flutter test` (테스트는 `test/` 디렉토리)
-   **환경 변수**: `.env` 파일에 Supabase URL/키 등 민감 정보 저장, Git에 커밋 금지

## 프로젝트 관례 및 패턴

-   **파일/폴더 네이밍**: 소문자+스네이크케이스, 역할별 폴더 분리
-   **상태 관리**: Provider 사용, 각 화면별 Provider 분리 권장
-   **메시지 모델**: `lib/models/message.dart` 참고, Supabase DB 구조와 일치
-   **UI 상수**: `lib/constants/ui_constants.dart`에 정의
-   **글로벌 상수**: `lib/constants/app_constants.dart`에 정의
-   **국제화**: `intl` 패키지로 다국어 지원 준비

## 외부 연동 및 의존성

-   **Supabase**: 인증/DB/실시간, `supabase_flutter` 패키지 사용
-   **로컬 저장소**: `shared_preferences`로 세션/설정 저장
-   **UUID**: 메시지 등 고유 ID 생성에 사용

## 예시 코드 패턴

-   Supabase 초기화: `main.dart` 참고
-   메시지 모델: `models/message.dart` 참고
-   Provider 사용: `providers/` 폴더 참고

---

이 문서는 실제 코드베이스 구조와 워크플로우에 기반해 작성되었습니다. 추가로 명확히 해야 할 부분이나 누락된 정보가 있다면 알려주세요.
