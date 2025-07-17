# Supabase Chat App

## 프로젝트 개요
*   Flutter 기반의 실시간 채팅 애플리케이션입니다.
*   Supabase를 백엔드로 사용하여 데이터베이스, 실시간 기능, 스토리지 등을 활용합니다.
*   사용자 프로필 관리, 채팅방 생성/참여, 메시지 전송(텍스트, 이미지), 메시지 검색 등의 기능을 제공합니다.

## 주요 기능

### 1. 사용자 및 프로필 관리 (Frontend & Backend)
*   **닉네임 설정:** 앱 첫 실행 시 또는 닉네임 미설정 시 닉네임 설정을 유도합니다.
*   **프로필 편집:** 닉네임, 상태 메시지, 아바타 이미지를 변경할 수 있습니다.
*   **아바타 업로드:** 갤러리에서 이미지 선택 후 Supabase Storage에 업로드합니다.
*   **사용자 접속 상태:** 앱 생명주기에 따라 온라인/오프라인 상태 및 마지막 접속 시간을 자동으로 업데이트합니다.
*   **로컬 사용자 ID:** `uuid`와 `shared_preferences`를 이용하여 로컬 사용자 ID를 관리합니다.
*   **프로필 캐싱:** API 호출 최적화를 위해 프로필 정보를 캐싱합니다.

### 2. 채팅방 기능 (Frontend & Backend)
*   **채팅방 목록:** Supabase DB에서 실시간으로 채팅방 목록을 조회합니다.
*   **채팅방 생성:** 새로운 채팅방을 생성하고 DB에 저장합니다.
*   **채팅방 삭제:** 채팅방 삭제 기능을 제공합니다.
*   **채팅방 입장:** 선택한 채팅방으로 이동합니다.

### 3. 메시징 기능 (Frontend & Backend)
*   **실시간 메시지:** Supabase Realtime을 통해 메시지를 실시간으로 송수신합니다.
*   **텍스트 메시지 전송:** 일반 텍스트 메시지를 전송합니다.
*   **이미지 메시지 전송:** 이미지 선택 후 Supabase Storage에 업로드 및 메시지로 전송합니다.
*   **메시지 기록:** 초기 메시지 로드 및 무한 스크롤을 통한 이전 메시지 로드를 지원합니다.
*   **메시지 읽음 처리:** 메시지 수신 시 자동으로 읽음 처리합니다.
*   **메시지 소프트 삭제:** 메시지 `is_deleted` 플래그를 통한 논리적 삭제를 지원합니다.
*   **메시지 검색:** 채팅방 내 메시지 내용을 검색할 수 있습니다.
*   **이모지 입력:** 이모지 선택기를 지원합니다.
*   **키보드 단축키:** 검색(Ctrl/Cmd + F), 줄바꿈(Shift/Ctrl + Enter)을 지원합니다.

### 4. 기타 기능
*   **Flutter 프레임워크 기반:** Flutter를 사용하여 크로스 플랫폼 애플리케이션을 개발했습니다.
*   **Provider를 통한 상태 관리:** `provider` 패키지를 사용하여 효율적인 상태 관리를 구현했습니다.
*   **Go-Router를 이용한 라우팅:** `go_router`를 사용하여 선언적 라우팅 및 화면 전환을 관리합니다.
*   **테마 기능 (라이트/다크 모드):** 사용자의 테마 선호도를 `shared_preferences`에 저장하여 라이트 모드와 다크 모드 간 전환을 지원합니다.
*   **로컬 알림:** Windows 플랫폼에 특화된 로컬 알림 기능을 제공합니다.
*   **전역 에러 핸들링:** Flutter 에러에 대한 전역 핸들링을 구현하고, 사용자에게 스낵바 형태로 친화적인 에러 메시지를 표시합니다.
*   **날짜 형식화:** 한국어(`ko`) 로케일에 맞춰 날짜 형식을 초기화합니다.
*   **환경 변수 관리:** `flutter_dotenv`를 사용하여 환경 변수를 로드합니다.
*   **커스텀 토스트 메시지:** 다양한 상황에 대한 커스텀 토스트 메시지를 표시합니다.
*   **일관된 UI 상수:** `UIConstants`를 사용하여 패딩, 폰트 크기 등 UI 요소에 대한 일관된 값을 유지합니다.

## 기술 스택
*   **Frontend:** Flutter (Dart)
*   **Backend:** Supabase (PostgreSQL Database, Realtime, Storage)
*   **상태 관리:** Provider
*   **라우팅:** go_router
*   **로컬 저장소:** shared_preferences
*   **이미지 선택:** image_picker
*   **이모지:** emoji_picker_flutter
*   **로컬 알림:** flutter_local_notifications
*   **환경 변수:** flutter_dotenv
*   **UUID 생성:** uuid

## 데이터베이스 스키마 및 연관 관계

Supabase PostgreSQL 데이터베이스는 `public` 스키마 내에 다음 세 가지 주요 테이블을 포함합니다.

### `profiles` 테이블
*   **목적:** 사용자 프로필 정보를 저장합니다.
*   **컬럼:**
    *   `id` (UUID, PK): 사용자 고유 ID. (Frontend: `Profile.id`, `ProfileProvider._localUserId`와 매핑)
    *   `nickname` (TEXT, UNIQUE): 사용자 닉네임. (Frontend: `Profile.nickname`, `ProfileProvider.currentNickname`과 매핑)
    *   `avatar_url` (TEXT): 아바타 이미지 URL. (Frontend: `Profile.avatarUrl`, Supabase Storage `avatars` 버킷과 연동)
    *   `status_message` (TEXT): 상태 메시지. (Frontend: `Profile.statusMessage`)
    *   `created_at` (TIMESTAMPTZ): 프로필 생성 시간.
    *   `last_seen` (TIMESTAMPTZ): 마지막 활동 시간. (Frontend: `Profile.lastSeen`, 앱 생명주기에 따라 업데이트)
    *   `is_online` (BOOLEAN): 온라인 상태 여부. (Frontend: `Profile.isOnline`, 앱 생명주기에 따라 업데이트)
*   **연관 관계:** `messages` 테이블의 `local_user_id` 컬럼이 이 테이블의 `id`를 참조합니다. (1:N 관계: 한 프로필은 여러 메시지를 보낼 수 있음)

### `rooms` 테이블
*   **목적:** 채팅방 정보를 저장합니다.
*   **컬럼:**
    *   `id` (UUID, PK): 채팅방 고유 ID. (Frontend: `Room.id`와 매핑)
    *   `name` (TEXT): 채팅방 이름. (Frontend: `Room.name`)
    *   `created_at` (TIMESTAMPTZ): 채팅방 생성 시간.
    *   `last_read_at` (TIMESTAMPTZ): 마지막으로 읽은 시간 (nullable).
    *   `user_id` (UUID): 채팅방을 생성한 사용자 ID (nullable).
*   **연관 관계:** `messages` 테이블의 `room_id` 컬럼이 이 테이블의 `id`를 참조합니다. (1:N 관계: 한 채팅방은 여러 메시지를 포함할 수 있음)

### `messages` 테이블
*   **목적:** 채팅 메시지를 저장합니다.
*   **컬럼:**
    *   `id` (UUID, PK): 메시지 고유 ID. (Frontend: `Message.id`와 매핑)
    *   `content` (TEXT): 메시지 내용. (Frontend: `Message.content`)
    *   `created_at` (TIMESTAMPTZ): 메시지 생성 시간. (Frontend: `Message.createdAt`)
    *   `room_id` (UUID, FK): 메시지가 속한 채팅방 ID. (`rooms` 테이블의 `id` 참조)
    *   `read_by` (UUID[]): 메시지를 읽은 사용자 ID 목록. (Frontend: `Message.readBy`)
    *   `image_url` (TEXT): 이미지 메시지의 경우 이미지 URL. (Frontend: `Message.imageUrl`, Supabase Storage `chat-images` 버킷과 연동)
    *   `local_user_id` (UUID, FK): 메시지를 보낸 사용자 ID. (`profiles` 테이블의 `id` 참조)
    *   `is_deleted` (BOOLEAN): 메시지 삭제 여부 (논리적 삭제). (Frontend: `Message.isDeleted`)
*   **연관 관계:** `rooms` 테이블과 `profiles` 테이블을 참조합니다.

## Supabase Storage 버킷
*   `avatars`: 사용자 프로필 아바타 이미지를 저장합니다.
*   `chat-images`: 채팅 메시지에 포함된 이미지를 저장합니다.

## 작동 방식 (주요 흐름)

1.  **앱 시작 및 초기화:**
    *   `main.dart`에서 Flutter 바인딩 초기화, 환경 변수 로드, Supabase 클라이언트 초기화, 날짜 형식화, 알림 서비스 초기화.
    *   `MultiProvider`를 통해 `ThemeModeProvider`, `ProfileProvider`, `ChatProvider`, `RoomProvider` 인스턴스 생성 및 주입.
2.  **스플래시 화면 및 사용자 인증/프로필 설정:**
    *   `SplashScreen`에서 `ProfileProvider`를 통해 로컬 사용자 ID 및 닉네임 확인.
    *   닉네임이 없거나 기본값인 경우 `NicknameScreen`으로 이동하여 닉네임 설정 유도.
    *   닉네임이 설정되어 있으면 `RoomListScreen`으로 이동.
3.  **채팅방 목록:**
    *   `RoomListScreen`에서 `RoomProvider`를 통해 Supabase `rooms` 테이블의 실시간 스트림을 구독하여 채팅방 목록 표시.
    *   사용자는 새로운 채팅방을 생성하거나 기존 채팅방을 삭제할 수 있음.
    *   프로필 관리 화면으로 이동 가능.
4.  **채팅방 입장:**
    *   `RoomListScreen`에서 채팅방 선택 시 `ChatPage`로 이동.
    *   `ChatPage`에서 `ChatProvider`를 통해 해당 `room_id`의 `messages` 테이블 실시간 스트림 구독.
    *   초기 메시지 로드 및 스크롤 시 이전 메시지 로드 (무한 스크롤).
5.  **메시지 전송:**
    *   `MessageInput` 위젯을 통해 텍스트 또는 이미지 입력.
    *   `ChatProvider`의 `sendMessage` 또는 `uploadImage` 호출.
    *   `ChatRepository`를 통해 Supabase `messages` 테이블에 데이터 삽입 또는 Supabase Storage에 이미지 업로드.
6.  **메시지 수신 및 표시:**
    *   Supabase Realtime을 통해 새로운 메시지 수신 시 `ChatProvider`가 메시지 목록 업데이트.
    *   `MessageList` 위젯이 업데이트된 메시지 목록을 표시.
    *   새 메시지 도착 시 알림 표시 (앱이 백그라운드일 경우).
    *   메시지 발신자의 프로필 정보(`profiles` 테이블)를 `ProfileProvider`를 통해 가져와 표시.
7.  **메시지 검색:**
    *   `ChatPage`에서 검색 필드 토글 후 `SearchField`에 검색어 입력.
    *   `ChatProvider`의 `searchMessages` 호출.
    *   `ChatRepository`를 통해 Supabase `messages` 테이블에서 검색어에 해당하는 메시지 조회.
    *   검색 결과는 `MessageList`에 별도로 표시.
8.  **프로필 관리:**
    *   `ProfileScreen`에서 `ProfileProvider`를 통해 현재 사용자 프로필 정보 로드.
    *   `ProfileForm`과 `ProfileAvatar` 위젯을 통해 정보 수정 및 아바타 변경.
    *   `ProfileRepository`를 통해 Supabase `profiles` 테이블에 프로필 정보 `upsert` 및 Supabase Storage에 아바타 업로드.

## 설치 및 실행 (간략)
1.  **환경 설정:** Flutter SDK, Supabase CLI 설치.
2.  **Supabase 프로젝트 설정:** 새로운 Supabase 프로젝트 생성 후, `profiles`, `rooms`, `messages` 테이블 스키마 설정 및 RLS(Row Level Security) 정책 적용. Storage 버킷(`avatars`, `chat-images`) 생성.
3.  **환경 변수 설정:** `.env` 파일에 Supabase URL 및 Anon Key 설정.
4.  **종속성 설치:** `flutter pub get` 실행.
5.  **앱 실행:** `flutter run` 실행.

## 향후 개선 사항 (예시)
*   **사용자 인증:** 현재 로컬 사용자 ID 기반이지만, Supabase Auth를 이용한 실제 사용자 인증(이메일/비밀번호, 소셜 로그인) 추가.
*   **채팅방 참여자 관리:** 채팅방에 참여하는 사용자 목록 표시 및 관리 기능.
*   **푸시 알림:** Firebase Cloud Messaging (FCM) 등을 이용한 크로스 플랫폼 푸시 알림 구현.
*   **메시지 수정:** 전송된 메시지를 수정하는 기능.
*   **읽지 않은 메시지 카운트:** 각 채팅방별 읽지 않은 메시지 수 표시.
*   **사용자 상태 표시:** 채팅방 내에서 각 사용자의 온라인/오프라인 상태를 시각적으로 표시.
*   **그룹 채팅:** 여러 사용자가 참여하는 그룹 채팅 기능 강화.
*   **파일 전송:** 이미지 외 다양한 파일 형식(문서, 비디오 등) 전송 기능.
*   **이모지 반응:** 메시지에 이모지로 반응하는 기능.
*   **다국어 지원:** `intl` 패키지를 활용한 다국어 지원 확장.