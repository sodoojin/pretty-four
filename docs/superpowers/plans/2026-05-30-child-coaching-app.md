# 아이 훈육 코칭 앱 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 부모가 아이와의 대화를 녹음하면 AI가 연령별 훈육 코칭을 제공하는 Flutter 앱 MVP 구현

**Architecture:** Flutter 앱 → Supabase(Auth + Storage + Edge Functions + PostgreSQL) → OpenAI Whisper(STT) + Anthropic Claude(분석/코칭)

**Tech Stack:** Flutter/Dart, Supabase, flutter_riverpod, go_router, record, OpenAI Whisper API, Anthropic Claude API

---

## 파일 구조

```
pretty_four/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── age_calculator.dart       # 생년월일 → 개월수, 코칭 컨텍스트
│   │   ├── router.dart               # go_router 라우팅
│   │   └── supabase_client.dart      # Supabase 클라이언트 싱글톤
│   ├── models/
│   │   ├── child.dart
│   │   ├── session.dart
│   │   ├── feedback_item.dart
│   │   ├── conversation_summary.dart
│   │   └── analysis_result.dart
│   ├── services/
│   │   ├── auth_service.dart         # 이메일/구글/카카오 로그인
│   │   ├── child_service.dart        # 아이 프로필 CRUD
│   │   ├── recording_service.dart    # 오디오 녹음
│   │   ├── analysis_service.dart     # 업로드 + Edge Function 호출
│   │   └── session_service.dart      # 세션/결과 조회
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── profile_setup_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── recording/
│   │   │   └── recording_screen.dart
│   │   ├── processing/
│   │   │   └── processing_screen.dart
│   │   ├── result/
│   │   │   └── result_screen.dart
│   │   └── history/
│   │       └── history_screen.dart
│   └── widgets/
│       ├── waveform_widget.dart
│       ├── session_card.dart
│       ├── summary_card.dart
│       └── feedback_list_item.dart
├── supabase/
│   ├── migrations/
│   │   └── 001_initial_schema.sql
│   └── functions/
│       └── analyze-conversation/
│           └── index.ts
├── test/
│   ├── core/
│   │   └── age_calculator_test.dart
│   └── models/
│       └── analysis_result_test.dart
└── pubspec.yaml
```

---

## Task 1: Flutter 프로젝트 초기화

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart` (빈 진입점)

- [ ] **Step 1: Flutter 프로젝트 생성**

```bash
cd /Users/sodoojin/ai-work/pretty-four
flutter create pretty_four --org com.prettyfour --platforms ios,android
```

- [ ] **Step 2: pubspec.yaml 의존성 교체**

`pretty_four/pubspec.yaml`의 `dependencies` 섹션을 아래로 교체:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.3.4
  go_router: ^13.2.0
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  record: ^5.1.1
  permission_handler: ^11.3.1
  path_provider: ^2.1.3
  intl: ^0.19.0
  flutter_dotenv: ^5.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.8
  riverpod_generator: ^2.4.0
```

- [ ] **Step 3: 의존성 설치**

```bash
cd pretty_four && flutter pub get
```

Expected: 패키지 다운로드 완료, 에러 없음

- [ ] **Step 4: .env 파일 생성**

`pretty_four/.env` 파일 생성:

```
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

`pretty_four/.gitignore`에 `.env` 추가:

```
.env
```

- [ ] **Step 5: assets 등록 (pubspec.yaml)**

`flutter:` 섹션 아래에 추가:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

- [ ] **Step 6: Android 마이크 권한 추가**

`pretty_four/android/app/src/main/AndroidManifest.xml`에서 `<manifest>` 태그 안에 추가:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

- [ ] **Step 7: iOS 마이크 권한 추가**

`pretty_four/ios/Runner/Info.plist`에서 `</dict>` 바로 위에 추가:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>아이와의 대화를 녹음하기 위해 마이크가 필요합니다.</string>
```

- [ ] **Step 8: 커밋**

```bash
cd pretty_four
git add .
git commit -m "chore: Flutter 프로젝트 초기화 및 의존성 설정"
```

---

## Task 2: Supabase 설정 + DB 마이그레이션

**Files:**
- Create: `supabase/migrations/001_initial_schema.sql`

- [ ] **Step 1: Supabase 프로젝트 생성 (수동)**

1. https://supabase.com 접속 → New Project 생성
2. Project URL과 anon key를 `.env` 파일에 입력
3. Dashboard → Storage → New Bucket: `recordings` (private)

- [ ] **Step 2: 마이그레이션 파일 생성**

`supabase/migrations/001_initial_schema.sql`:

```sql
-- 아이 프로필
create table public.children (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  birth_date date not null,
  created_at timestamptz default now() not null
);

-- 분석 세션
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references public.children(id) on delete cascade not null,
  recorded_at timestamptz default now() not null,
  duration_sec integer not null,
  status text not null default 'processing'
    check (status in ('processing', 'completed', 'failed'))
);

-- 분석 결과
create table public.analysis_results (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references public.sessions(id) on delete cascade not null unique,
  summary jsonb not null,
  feedbacks jsonb not null default '[]',
  raw_transcript text,
  child_age_months integer not null,
  created_at timestamptz default now() not null
);

-- RLS 활성화
alter table public.children enable row level security;
alter table public.sessions enable row level security;
alter table public.analysis_results enable row level security;

-- children 정책: 본인 데이터만
create policy "children_owner" on public.children
  for all using (auth.uid() = user_id);

-- sessions 정책: children을 통해 본인 데이터만
create policy "sessions_owner" on public.sessions
  for all using (
    exists (
      select 1 from public.children
      where children.id = sessions.child_id
        and children.user_id = auth.uid()
    )
  );

-- analysis_results 정책: sessions를 통해 본인 데이터만
create policy "results_owner" on public.analysis_results
  for all using (
    exists (
      select 1 from public.sessions
      join public.children on children.id = sessions.child_id
      where sessions.id = analysis_results.session_id
        and children.user_id = auth.uid()
    )
  );

-- Storage RLS: recordings 버킷
create policy "recordings_owner_upload" on storage.objects
  for insert with check (
    bucket_id = 'recordings' and auth.uid() is not null
  );

create policy "recordings_owner_select" on storage.objects
  for select using (
    bucket_id = 'recordings' and auth.uid() is not null
  );

create policy "recordings_service_delete" on storage.objects
  for delete using (bucket_id = 'recordings');
```

- [ ] **Step 3: Supabase 대시보드에서 SQL 실행**

Supabase Dashboard → SQL Editor → `001_initial_schema.sql` 내용 붙여넣기 → Run

Expected: 에러 없이 테이블 3개 생성 확인 (Database → Tables)

- [ ] **Step 4: 커밋**

```bash
git add supabase/
git commit -m "chore: Supabase DB 스키마 및 RLS 정책 설정"
```

---

## Task 3: 데이터 모델 + AgeCalculator (TDD)

**Files:**
- Create: `lib/core/age_calculator.dart`
- Create: `lib/models/feedback_item.dart`
- Create: `lib/models/conversation_summary.dart`
- Create: `lib/models/child.dart`
- Create: `lib/models/session.dart`
- Create: `lib/models/analysis_result.dart`
- Create: `test/core/age_calculator_test.dart`
- Create: `test/models/analysis_result_test.dart`

- [ ] **Step 1: AgeCalculator 테스트 작성**

`test/core/age_calculator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_four/core/age_calculator.dart';

void main() {
  group('AgeCalculator.toMonths', () {
    test('정확한 개월수 계산', () {
      final birthDate = DateTime(2022, 1, 1);
      final now = DateTime(2026, 5, 1);
      expect(AgeCalculator.toMonths(birthDate, now), 52);
    });

    test('같은 달이면 0개월', () {
      final birthDate = DateTime(2026, 5, 15);
      final now = DateTime(2026, 5, 30);
      expect(AgeCalculator.toMonths(birthDate, now), 0);
    });
  });

  group('AgeCalculator.getCoachingContext', () {
    test('24개월 → 언어 발달 초기 컨텍스트 반환', () {
      final context = AgeCalculator.getCoachingContext(24);
      expect(context, contains('단순하고 일관된 지시'));
    });

    test('60개월 → 자율성 발달 컨텍스트 반환', () {
      final context = AgeCalculator.getCoachingContext(60);
      expect(context, contains('선택지'));
    });

    test('96개월 → 논리적 설명 컨텍스트 반환', () {
      final context = AgeCalculator.getCoachingContext(96);
      expect(context, contains('논리적'));
    });

    test('144개월 → 자율성 존중 컨텍스트 반환', () {
      final context = AgeCalculator.getCoachingContext(144);
      expect(context, contains('자율성'));
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
cd pretty_four && flutter test test/core/age_calculator_test.dart
```

Expected: FAIL (age_calculator.dart 없음)

- [ ] **Step 3: AgeCalculator 구현**

`lib/core/age_calculator.dart`:

```dart
class AgeCalculator {
  static int toMonths(DateTime birthDate, [DateTime? now]) {
    final reference = now ?? DateTime.now();
    return (reference.year - birthDate.year) * 12 +
        (reference.month - birthDate.month);
  }

  static String getCoachingContext(int months) {
    if (months < 48) {
      return '이 나이(만 ${months ~/ 12}세)는 언어 발달 초기로, 단순하고 일관된 지시가 효과적입니다. '
          '짧은 문장을 사용하고 즉각적인 피드백을 주세요.';
    } else if (months < 84) {
      return '이 나이(만 ${months ~/ 12}세)는 규칙 이해와 자율성이 발달하는 시기입니다. '
          '선택지를 제공하고 규칙의 이유를 간단히 설명해주세요.';
    } else if (months < 132) {
      return '이 나이(만 ${months ~/ 12}세)는 논리적 사고가 발달하는 시기입니다. '
          '논리적 설명과 감정 공감을 우선시하세요.';
    } else {
      return '이 나이(만 ${months ~/ 12}세)는 자율성이 중요한 시기입니다. '
          '협상과 타협을 통해 자율성을 존중해주세요.';
    }
  }
}
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```bash
flutter test test/core/age_calculator_test.dart
```

Expected: All tests passed

- [ ] **Step 5: AnalysisResult 모델 테스트 작성**

`test/models/analysis_result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_four/models/analysis_result.dart';
import 'package:pretty_four/models/feedback_item.dart';
import 'package:pretty_four/models/conversation_summary.dart';

void main() {
  group('FeedbackItem.fromJson', () {
    test('JSON에서 올바르게 파싱', () {
      final json = {
        'timestamp_sec': 42,
        'original': '하지 말라고 했잖아!',
        'suggestion': '지금 힘들구나. 같이 해결해볼까?',
        'reason': '감정 반영 후 대안 제시가 효과적입니다.',
      };
      final item = FeedbackItem.fromJson(json);
      expect(item.timestampSec, 42);
      expect(item.original, '하지 말라고 했잖아!');
      expect(item.suggestion, '지금 힘들구나. 같이 해결해볼까?');
    });
  });

  group('ConversationSummary.fromJson', () {
    test('JSON에서 올바르게 파싱', () {
      final json = {
        'tone': '지시적',
        'patterns': ['명령형 발화 다수', '칭찬 부족'],
        'improvements': ['감정 반영 먼저', '선택지 제공'],
      };
      final summary = ConversationSummary.fromJson(json);
      expect(summary.tone, '지시적');
      expect(summary.patterns.length, 2);
      expect(summary.improvements, contains('감정 반영 먼저'));
    });
  });

  group('AnalysisResult.fromJson', () {
    test('전체 DB 행에서 올바르게 파싱', () {
      final row = {
        'id': 'test-id',
        'session_id': 'session-id',
        'summary': {
          'tone': '협력적',
          'patterns': ['칭찬 적절'],
          'improvements': [],
        },
        'feedbacks': [
          {
            'timestamp_sec': 10,
            'original': '잘했어',
            'suggestion': '정말 잘했어, 네가 노력했구나!',
            'reason': '구체적 칭찬이 더 효과적입니다.',
          }
        ],
        'raw_transcript': '10초: 잘했어',
        'child_age_months': 52,
        'created_at': '2026-05-30T10:00:00Z',
      };
      final result = AnalysisResult.fromJson(row);
      expect(result.feedbacks.length, 1);
      expect(result.childAgeMonths, 52);
      expect(result.summary.tone, '협력적');
    });
  });
}
```

- [ ] **Step 6: 테스트 실행 → 실패 확인**

```bash
flutter test test/models/analysis_result_test.dart
```

Expected: FAIL (모델 파일 없음)

- [ ] **Step 7: 모델 파일 구현**

`lib/models/feedback_item.dart`:

```dart
class FeedbackItem {
  final int timestampSec;
  final String original;
  final String suggestion;
  final String reason;

  const FeedbackItem({
    required this.timestampSec,
    required this.original,
    required this.suggestion,
    required this.reason,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) => FeedbackItem(
        timestampSec: json['timestamp_sec'] as int,
        original: json['original'] as String,
        suggestion: json['suggestion'] as String,
        reason: json['reason'] as String,
      );

  Map<String, dynamic> toJson() => {
        'timestamp_sec': timestampSec,
        'original': original,
        'suggestion': suggestion,
        'reason': reason,
      };
}
```

`lib/models/conversation_summary.dart`:

```dart
class ConversationSummary {
  final String tone;
  final List<String> patterns;
  final List<String> improvements;

  const ConversationSummary({
    required this.tone,
    required this.patterns,
    required this.improvements,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        tone: json['tone'] as String,
        patterns: List<String>.from(json['patterns'] as List),
        improvements: List<String>.from(json['improvements'] as List),
      );

  Map<String, dynamic> toJson() => {
        'tone': tone,
        'patterns': patterns,
        'improvements': improvements,
      };
}
```

`lib/models/child.dart`:

```dart
class Child {
  final String id;
  final String userId;
  final String name;
  final DateTime birthDate;
  final DateTime createdAt;

  const Child({
    required this.id,
    required this.userId,
    required this.name,
    required this.birthDate,
    required this.createdAt,
  });

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        birthDate: DateTime.parse(json['birth_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
```

`lib/models/session.dart`:

```dart
class Session {
  final String id;
  final String childId;
  final DateTime recordedAt;
  final int durationSec;
  final String status;

  const Session({
    required this.id,
    required this.childId,
    required this.recordedAt,
    required this.durationSec,
    required this.status,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        childId: json['child_id'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        durationSec: json['duration_sec'] as int,
        status: json['status'] as String,
      );

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing';
}
```

`lib/models/analysis_result.dart`:

```dart
import 'feedback_item.dart';
import 'conversation_summary.dart';

class AnalysisResult {
  final String id;
  final String sessionId;
  final ConversationSummary summary;
  final List<FeedbackItem> feedbacks;
  final String? rawTranscript;
  final int childAgeMonths;
  final DateTime createdAt;

  const AnalysisResult({
    required this.id,
    required this.sessionId,
    required this.summary,
    required this.feedbacks,
    this.rawTranscript,
    required this.childAgeMonths,
    required this.createdAt,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        summary: ConversationSummary.fromJson(
            json['summary'] as Map<String, dynamic>),
        feedbacks: (json['feedbacks'] as List)
            .map((e) => FeedbackItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        rawTranscript: json['raw_transcript'] as String?,
        childAgeMonths: json['child_age_months'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
```

- [ ] **Step 8: 테스트 실행 → 통과 확인**

```bash
flutter test test/
```

Expected: All 6 tests passed

- [ ] **Step 9: 커밋**

```bash
git add lib/core/age_calculator.dart lib/models/ test/
git commit -m "feat: 데이터 모델 및 AgeCalculator 구현"
```

---

## Task 4: Supabase 클라이언트 + 라우터 + 앱 진입점

**Files:**
- Create: `lib/core/supabase_client.dart`
- Create: `lib/core/router.dart`
- Modify: `lib/main.dart`
- Create: `lib/app.dart`

- [ ] **Step 1: supabase_client.dart 작성**

`lib/core/supabase_client.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get supabaseClient => Supabase.instance.client;
```

- [ ] **Step 2: router.dart 작성**

`lib/core/router.dart`:

```dart
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/recording/recording_screen.dart';
import '../screens/processing/processing_screen.dart';
import '../screens/result/result_screen.dart';
import '../screens/history/history_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isLoginRoute = state.matchedLocation == '/login';
    if (!isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && isLoginRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
        path: '/profile-setup',
        builder: (_, __) => const ProfileSetupScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/recording', builder: (_, __) => const RecordingScreen()),
    GoRoute(
      path: '/processing/:sessionId',
      builder: (_, state) =>
          ProcessingScreen(sessionId: state.pathParameters['sessionId']!),
    ),
    GoRoute(
      path: '/result/:sessionId',
      builder: (_, state) =>
          ResultScreen(sessionId: state.pathParameters['sessionId']!),
    ),
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
  ],
);
```

- [ ] **Step 3: 빈 화면 파일 생성 (라우터 컴파일용)**

각 파일을 아래 패턴으로 생성 (7개):

`lib/screens/auth/login_screen.dart`:
```dart
import 'package:flutter/material.dart';
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Login')));
}
```

`lib/screens/auth/profile_setup_screen.dart`:
```dart
import 'package:flutter/material.dart';
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Profile Setup')));
}
```

`lib/screens/home/home_screen.dart`:
```dart
import 'package:flutter/material.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home')));
}
```

`lib/screens/recording/recording_screen.dart`:
```dart
import 'package:flutter/material.dart';
class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Recording')));
}
```

`lib/screens/processing/processing_screen.dart`:
```dart
import 'package:flutter/material.dart';
class ProcessingScreen extends StatelessWidget {
  final String sessionId;
  const ProcessingScreen({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Processing')));
}
```

`lib/screens/result/result_screen.dart`:
```dart
import 'package:flutter/material.dart';
class ResultScreen extends StatelessWidget {
  final String sessionId;
  const ResultScreen({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Result')));
}
```

`lib/screens/history/history_screen.dart`:
```dart
import 'package:flutter/material.dart';
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('History')));
}
```

- [ ] **Step 4: main.dart 작성**

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const App());
}
```

- [ ] **Step 5: app.dart 작성**

`lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: '육아 코칭',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B9DFC)),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
```

- [ ] **Step 6: 빌드 확인**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 7: 커밋**

```bash
git add lib/
git commit -m "feat: Supabase 클라이언트, 라우터, 앱 진입점 설정"
```

---

## Task 5: Auth 서비스 + 로그인 화면

**Files:**
- Create: `lib/services/auth_service.dart`
- Modify: `lib/screens/auth/login_screen.dart`

- [ ] **Step 1: auth_service.dart 작성**

`lib/services/auth_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AuthService {
  final _client = supabaseClient;

  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.prettyfour://login-callback',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String? get currentUserId => _client.auth.currentUser?.id;
  bool get isLoggedIn => _client.auth.currentSession != null;
}
```

- [ ] **Step 2: 로그인 화면 구현**

`lib/screens/auth/login_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _signInWithEmail() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithEmail(_emailCtrl.text.trim(), _pwCtrl.text);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    setState(() => _loading = true);
    try {
      await _auth.signUpWithEmail(_emailCtrl.text.trim(), _pwCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 인증 메일을 확인해주세요.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('육아 코칭',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('아이와의 대화를 분석해드려요',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 48),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pwCtrl,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _signInWithEmail,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('로그인'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _loading ? null : _signUpWithEmail,
                child: const Text('이메일로 회원가입'),
              ),
              const SizedBox(height: 16),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('또는'),
                ),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loading ? null : _auth.signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('구글로 시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 3: Google OAuth Deep Link 설정 (Android)**

`android/app/src/main/AndroidManifest.xml`의 `<activity>` 태그 안에 추가:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="io.supabase.prettyfour" android:host="login-callback" />
</intent-filter>
```

- [ ] **Step 4: 빌드 및 시뮬레이터 확인**

```bash
flutter run
```

Expected: 로그인 화면이 표시됨, 이메일/비밀번호 입력 필드 및 구글 버튼 확인

- [ ] **Step 5: 커밋**

```bash
git add lib/services/auth_service.dart lib/screens/auth/login_screen.dart android/
git commit -m "feat: 이메일/구글 로그인 화면 구현"
```

---

## Task 6: 아이 프로필 서비스 + 등록 화면

**Files:**
- Create: `lib/services/child_service.dart`
- Modify: `lib/screens/auth/profile_setup_screen.dart`

- [ ] **Step 1: child_service.dart 작성**

`lib/services/child_service.dart`:

```dart
import '../core/supabase_client.dart';
import '../models/child.dart';

class ChildService {
  final _client = supabaseClient;

  Future<Child> createChild(String name, DateTime birthDate) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client.from('children').insert({
      'user_id': userId,
      'name': name,
      'birth_date': birthDate.toIso8601String().split('T')[0],
    }).select().single();
    return Child.fromJson(data);
  }

  Future<Child?> getCurrentChild() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final data = await _client
        .from('children')
        .select()
        .eq('user_id', userId)
        .order('created_at')
        .limit(1)
        .maybeSingle();
    return data != null ? Child.fromJson(data) : null;
  }
}
```

- [ ] **Step 2: 프로필 등록 화면 구현**

`lib/screens/auth/profile_setup_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/child_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _childService = ChildService();
  final _nameCtrl = TextEditingController();
  DateTime? _birthDate;
  bool _loading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름과 생년월일을 입력해주세요.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _childService.createChild(_nameCtrl.text.trim(), _birthDate!);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('아이 정보 입력')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('아이에 대해 알려주세요',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '아이 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _pickDate,
              child: Text(_birthDate == null
                  ? '생년월일 선택'
                  : DateFormat('yyyy년 M월 d일').format(_birthDate!)),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 3: 로그인 후 아이 프로필 확인 로직 추가**

`lib/core/router.dart`의 redirect 함수를 아래로 교체:

```dart
redirect: (context, state) async {
  final session = Supabase.instance.client.auth.currentSession;
  final isLoggedIn = session != null;
  final loc = state.matchedLocation;

  if (!isLoggedIn) {
    return loc == '/login' ? null : '/login';
  }

  if (loc == '/login' || loc == '/profile-setup') {
    final child = await ChildService().getCurrentChild();
    if (child == null) return '/profile-setup';
    if (loc == '/profile-setup') return '/home';
    return '/home';
  }

  return null;
},
```

`lib/core/router.dart` 상단에 import 추가:

```dart
import '../services/child_service.dart';
```

- [ ] **Step 4: 커밋**

```bash
git add lib/services/child_service.dart lib/screens/auth/profile_setup_screen.dart lib/core/router.dart
git commit -m "feat: 아이 프로필 등록 화면 및 서비스 구현"
```

---

## Task 7: 녹음 서비스 + 녹음 화면

**Files:**
- Create: `lib/services/recording_service.dart`
- Create: `lib/widgets/waveform_widget.dart`
- Modify: `lib/screens/recording/recording_screen.dart`

- [ ] **Step 1: recording_service.dart 작성**

`lib/services/recording_service.dart`:

```dart
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class RecordingService {
  final _recorder = AudioRecorder();
  DateTime? _startTime;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> start(String sessionId) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$sessionId.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
    _startTime = DateTime.now();
    return path;
  }

  Future<String?> stop() async => await _recorder.stop();

  Future<void> pause() async => await _recorder.pause();
  Future<void> resume() async => await _recorder.resume();

  Stream<Amplitude> get amplitudeStream =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  int get elapsedSeconds =>
      _startTime == null ? 0 : DateTime.now().difference(_startTime!).inSeconds;

  Future<bool> get isRecording => _recorder.isRecording();

  void dispose() => _recorder.dispose();
}
```

- [ ] **Step 2: waveform_widget.dart 작성**

`lib/widgets/waveform_widget.dart`:

```dart
import 'package:flutter/material.dart';

class WaveformWidget extends StatelessWidget {
  final List<double> amplitudes;
  final Color color;

  const WaveformWidget({
    super.key,
    required this.amplitudes,
    this.color = const Color(0xFF6B9DFC),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformPainter(amplitudes: amplitudes, color: color),
      child: const SizedBox(height: 80, width: double.infinity),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _WaveformPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    if (amplitudes.isEmpty) return;

    final barWidth = size.width / amplitudes.length;
    for (int i = 0; i < amplitudes.length; i++) {
      final barHeight = amplitudes[i] * size.height;
      final x = i * barWidth + barWidth / 2;
      canvas.drawLine(
        Offset(x, size.height / 2 - barHeight / 2),
        Offset(x, size.height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.amplitudes != amplitudes;
}
```

- [ ] **Step 3: recording_screen.dart 구현**

`lib/screens/recording/recording_screen.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../../services/recording_service.dart';
import '../../widgets/waveform_widget.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});
  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final _service = RecordingService();
  final _amplitudes = <double>[];
  late final StreamSubscription<Amplitude> _ampSub;
  Timer? _timer;
  bool _isRecording = false;
  bool _isPaused = false;
  int _seconds = 0;
  String? _sessionId;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _ampSub = _service.amplitudeStream.listen((amp) {
      if (_isRecording && !_isPaused) {
        setState(() {
          final normalized = ((amp.current + 60) / 60).clamp(0.05, 1.0);
          _amplitudes.add(normalized);
          if (_amplitudes.length > 60) _amplitudes.removeAt(0);
        });
      }
    });
  }

  Future<void> _startRecording() async {
    final granted = await _service.requestPermission();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마이크 권한이 필요합니다.')),
      );
      return;
    }
    _sessionId = const Uuid().v4();
    _audioPath = await _service.start(_sessionId!);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) setState(() => _seconds++);
    });
    setState(() => _isRecording = true);
  }

  Future<void> _togglePause() async {
    if (_isPaused) {
      await _service.resume();
    } else {
      await _service.pause();
    }
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _stopAndAnalyze() async {
    _timer?.cancel();
    await _service.stop();
    if (mounted && _sessionId != null) {
      context.go(
        '/processing/$_sessionId',
        extra: {'audioPath': _audioPath, 'durationSec': _seconds},
      );
    }
  }

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('대화 녹음')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_formatTime(_seconds),
                style: const TextStyle(
                    fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            WaveformWidget(amplitudes: _amplitudes),
            const SizedBox(height: 48),
            if (!_isRecording)
              FilledButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.mic),
                label: const Text('녹음 시작'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 56)),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(_isPaused ? '계속' : '일시정지'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _stopAndAnalyze,
                    icon: const Icon(Icons.stop),
                    label: const Text('분석 시작'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ampSub.cancel();
    _timer?.cancel();
    _service.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 4: uuid 패키지 추가**

`pubspec.yaml` dependencies에 추가:
```yaml
uuid: ^4.4.0
```

```bash
flutter pub get
```

- [ ] **Step 5: 시뮬레이터에서 녹음 화면 확인**

```bash
flutter run
```

Expected: 홈에서 녹음 화면으로 이동 시 파형과 녹음 버튼이 표시됨

- [ ] **Step 6: 커밋**

```bash
git add lib/services/recording_service.dart lib/widgets/waveform_widget.dart lib/screens/recording/ pubspec.yaml pubspec.lock
git commit -m "feat: 오디오 녹음 서비스 및 파형 시각화 녹음 화면 구현"
```

---

## Task 8: Supabase Edge Function (AI 파이프라인)

**Files:**
- Create: `supabase/functions/analyze-conversation/index.ts`

- [ ] **Step 1: Supabase CLI 설치 확인**

```bash
supabase --version
```

Expected: `1.x.x` 이상. 없으면: `brew install supabase/tap/supabase`

- [ ] **Step 2: 로컬 Supabase 초기화**

```bash
supabase init
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

`YOUR_PROJECT_REF`는 Supabase Dashboard URL에서 확인: `https://supabase.com/dashboard/project/YOUR_PROJECT_REF`

- [ ] **Step 3: Edge Function 생성**

```bash
supabase functions new analyze-conversation
```

- [ ] **Step 4: index.ts 작성**

`supabase/functions/analyze-conversation/index.ts`:

```typescript
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Anthropic from 'https://esm.sh/@anthropic-ai/sdk@0.24.3'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

Deno.serve(async (req) => {
  try {
    const { session_id } = await req.json()

    // 1. 세션 + 아이 정보 조회
    const { data: session, error: sessionErr } = await supabase
      .from('sessions')
      .select('*, children(birth_date)')
      .eq('id', session_id)
      .single()
    if (sessionErr) throw sessionErr

    // 2. Storage에서 오디오 다운로드
    const { data: audioData, error: storageErr } = await supabase.storage
      .from('recordings')
      .download(`${session_id}.m4a`)
    if (storageErr) throw storageErr

    // 3. Whisper STT
    const formData = new FormData()
    formData.append('file', new File([audioData], 'audio.m4a', { type: 'audio/m4a' }))
    formData.append('model', 'whisper-1')
    formData.append('response_format', 'verbose_json')
    formData.append('timestamp_granularities[]', 'segment')

    const whisperRes = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${Deno.env.get('OPENAI_API_KEY')}` },
      body: formData,
    })
    if (!whisperRes.ok) throw new Error(`Whisper error: ${await whisperRes.text()}`)
    const whisperData = await whisperRes.json()

    const transcript = whisperData.segments
      .map((s: { start: number; text: string }) => `${Math.floor(s.start)}초: ${s.text.trim()}`)
      .join('\n')

    // 4. 연령 계산
    const birthDate = new Date(session.children.birth_date)
    const now = new Date()
    const ageMonths =
      (now.getFullYear() - birthDate.getFullYear()) * 12 +
      (now.getMonth() - birthDate.getMonth())

    // 5. Claude 분석
    const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY') })

    const claudeRes = await anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 4096,
      messages: [
        {
          role: 'user',
          content: `당신은 아동 발달 전문가이자 육아 코칭 전문가입니다.

아이 나이: 만 ${Math.floor(ageMonths / 12)}세 ${ageMonths % 12}개월 (총 ${ageMonths}개월)
발달 단계 지침: ${getCoachingContext(ageMonths)}

아래는 부모와 아이의 대화 전사 내용입니다:
---
${transcript}
---

다음 JSON 형식으로만 응답하세요 (설명 없이 JSON만):
{
  "summary": {
    "tone": "전반적인 대화 분위기 한 단어 (예: 지시적, 협력적, 갈등적)",
    "patterns": ["발견된 패턴1", "발견된 패턴2"],
    "improvements": ["개선 제안1", "개선 제안2"]
  },
  "feedbacks": [
    {
      "timestamp_sec": 타임스탬프_정수,
      "original": "실제 발화 내용",
      "suggestion": "더 효과적인 대안 표현",
      "reason": "이렇게 말하면 좋은 이유 (1~2문장)"
    }
  ]
}`,
        },
      ],
    })

    const analysisText =
      claudeRes.content[0].type === 'text' ? claudeRes.content[0].text : ''
    const analysis = JSON.parse(analysisText)

    // 6. DB 저장
    const { error: insertErr } = await supabase.from('analysis_results').insert({
      session_id,
      summary: analysis.summary,
      feedbacks: analysis.feedbacks,
      raw_transcript: transcript,
      child_age_months: ageMonths,
    })
    if (insertErr) throw insertErr

    // 7. 세션 상태 업데이트
    await supabase.from('sessions').update({ status: 'completed' }).eq('id', session_id)

    // 8. 오디오 파일 삭제
    await supabase.storage.from('recordings').remove([`${session_id}.m4a`])

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error(err)
    const errorMessage = err instanceof Error ? err.message : String(err)
    // 실패 시 세션 상태를 failed로 업데이트
    const body = await req.clone().json().catch(() => ({}))
    if (body.session_id) {
      await supabase
        .from('sessions')
        .update({ status: 'failed' })
        .eq('id', body.session_id)
    }
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

function getCoachingContext(ageMonths: number): string {
  if (ageMonths < 48)
    return '단순하고 일관된 지시, 짧은 문장, 즉각적 피드백을 강조하세요.'
  if (ageMonths < 84)
    return '선택지 제공과 규칙의 이유 설명을 강조하세요.'
  if (ageMonths < 132)
    return '논리적 설명과 감정 공감을 강조하세요.'
  return '협상과 타협을 통한 자율성 존중을 강조하세요.'
}
```

- [ ] **Step 5: Edge Function Secrets 설정**

```bash
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
```

- [ ] **Step 6: Edge Function 배포**

```bash
supabase functions deploy analyze-conversation
```

Expected: `Deployed Functions analyze-conversation`

- [ ] **Step 7: 배포 확인 (curl 테스트)**

Supabase Dashboard → Edge Functions → analyze-conversation에서 함수 URL 확인 후:

```bash
curl -X POST 'https://YOUR_PROJECT.supabase.co/functions/v1/analyze-conversation' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"session_id": "00000000-0000-0000-0000-000000000000"}'
```

Expected: `{"error":"..."}` (세션 없어서 에러 - 함수 자체는 실행됨)

- [ ] **Step 8: 커밋**

```bash
git add supabase/
git commit -m "feat: AI 분석 파이프라인 Edge Function 구현 및 배포"
```

---

## Task 9: Analysis 서비스 + 분석 중 화면

**Files:**
- Create: `lib/services/analysis_service.dart`
- Create: `lib/services/session_service.dart`
- Modify: `lib/screens/processing/processing_screen.dart`

- [ ] **Step 1: analysis_service.dart 작성**

`lib/services/analysis_service.dart`:

```dart
import 'dart:io';
import '../core/supabase_client.dart';
import '../models/session.dart';
import '../models/analysis_result.dart';

class AnalysisService {
  final _client = supabaseClient;

  Future<Session> createSession(String childId, int durationSec) async {
    final data = await _client.from('sessions').insert({
      'child_id': childId,
      'recorded_at': DateTime.now().toIso8601String(),
      'duration_sec': durationSec,
      'status': 'processing',
    }).select().single();
    return Session.fromJson(data);
  }

  Future<void> uploadAndTriggerAnalysis(
      String sessionId, String audioPath) async {
    final file = File(audioPath);
    await _client.storage
        .from('recordings')
        .upload('$sessionId.m4a', file);

    await _client.functions.invoke(
      'analyze-conversation',
      body: {'session_id': sessionId},
    );
  }

  Future<Session> pollSession(String sessionId) async {
    final data = await _client
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .single();
    return Session.fromJson(data);
  }

  Future<AnalysisResult?> getResult(String sessionId) async {
    final data = await _client
        .from('analysis_results')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();
    return data != null ? AnalysisResult.fromJson(data) : null;
  }
}
```

- [ ] **Step 2: session_service.dart 작성**

`lib/services/session_service.dart`:

```dart
import '../core/supabase_client.dart';
import '../models/session.dart';
import '../models/analysis_result.dart';

class SessionService {
  final _client = supabaseClient;

  Future<List<Session>> getRecentSessions(String childId,
      {int limit = 20}) async {
    final rows = await _client
        .from('sessions')
        .select()
        .eq('child_id', childId)
        .eq('status', 'completed')
        .order('recorded_at', ascending: false)
        .limit(limit);
    return rows.map<Session>(Session.fromJson).toList();
  }

  Future<AnalysisResult?> getResultForSession(String sessionId) async {
    final data = await _client
        .from('analysis_results')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();
    return data != null ? AnalysisResult.fromJson(data) : null;
  }
}
```

- [ ] **Step 3: processing_screen.dart 구현**

`lib/screens/processing/processing_screen.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/analysis_service.dart';
import '../../services/child_service.dart';

class ProcessingScreen extends StatefulWidget {
  final String sessionId;
  const ProcessingScreen({super.key, required this.sessionId});
  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final _analysisService = AnalysisService();
  final _childService = ChildService();
  Timer? _pollTimer;
  int _elapsedSeconds = 0;
  Timer? _clockTimer;
  String _statusMessage = '대화를 분석하고 있어요...';

  static const _messages = [
    '대화를 분석하고 있어요...',
    '음성을 텍스트로 변환하고 있어요...',
    '훈육 패턴을 파악하고 있어요...',
    '코칭 내용을 준비하고 있어요...',
    '거의 다 됐어요!',
  ];

  @override
  void initState() {
    super.initState();
    _startUploadAndAnalyze();
    _startPolling();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds++;
        final idx = (_elapsedSeconds ~/ 8).clamp(0, _messages.length - 1);
        _statusMessage = _messages[idx];
      });
    });
  }

  Future<void> _startUploadAndAnalyze() async {
    final extra = ModalRoute.of(context)?.settings.arguments as Map?;
    final audioPath = extra?['audioPath'] as String?;
    final durationSec = extra?['durationSec'] as int? ?? 0;

    if (audioPath == null) return;

    final child = await _childService.getCurrentChild();
    if (child == null) return;

    final session = await _analysisService.createSession(child.id, durationSec);
    await _analysisService.uploadAndTriggerAnalysis(session.id, audioPath);
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final session = await _analysisService.pollSession(widget.sessionId);
      if (session.isCompleted && mounted) {
        _pollTimer?.cancel();
        context.go('/result/${widget.sessionId}');
      } else if (session.isFailed && mounted) {
        _pollTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('분석에 실패했어요. 다시 시도해주세요.')),
        );
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 32),
              Text(_statusMessage,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('${_elapsedSeconds}초 경과',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 4: 커밋**

```bash
git add lib/services/analysis_service.dart lib/services/session_service.dart lib/screens/processing/
git commit -m "feat: 분석 서비스 및 처리 중 화면 구현"
```

---

## Task 10: 결과 화면

**Files:**
- Create: `lib/widgets/summary_card.dart`
- Create: `lib/widgets/feedback_list_item.dart`
- Modify: `lib/screens/result/result_screen.dart`

- [ ] **Step 1: summary_card.dart 작성**

`lib/widgets/summary_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/conversation_summary.dart';

class SummaryCard extends StatelessWidget {
  final ConversationSummary summary;
  const SummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.analytics_outlined),
              const SizedBox(width: 8),
              Text('대화 요약',
                  style: Theme.of(context).textTheme.titleMedium),
            ]),
            const Divider(),
            _buildRow('대화 분위기', summary.tone),
            const SizedBox(height: 8),
            _buildChipSection('발견된 패턴', summary.patterns,
                Colors.orange.shade100),
            const SizedBox(height: 8),
            _buildChipSection('개선 포인트', summary.improvements,
                Colors.green.shade100),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  Widget _buildChipSection(
      String label, List<String> items, Color chipColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: items
              .map((e) => Chip(
                    label: Text(e, style: const TextStyle(fontSize: 12)),
                    backgroundColor: chipColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
              .toList(),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: feedback_list_item.dart 작성**

`lib/widgets/feedback_list_item.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/feedback_item.dart';

class FeedbackListItem extends StatelessWidget {
  final FeedbackItem item;
  const FeedbackListItem({super.key, required this.item});

  String _formatTimestamp(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatTimestamp(item.timestampSec),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.original)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.suggestion)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(item.reason,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: result_screen.dart 구현**

`lib/screens/result/result_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/analysis_result.dart';
import '../../services/analysis_service.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/feedback_list_item.dart';

class ResultScreen extends StatefulWidget {
  final String sessionId;
  const ResultScreen({super.key, required this.sessionId});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _service = AnalysisService();
  AnalysisResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    try {
      final result = await _service.getResult(widget.sessionId);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 결과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('오류: $_error'))
              : _result == null
                  ? const Center(child: Text('결과를 불러올 수 없어요.'))
                  : _buildResult(_result!),
    );
  }

  Widget _buildResult(AnalysisResult result) {
    final ageYears = result.childAgeMonths ~/ 12;
    final ageMonthsRem = result.childAgeMonths % 12;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '분석 일시: ${DateFormat('yyyy.MM.dd HH:mm').format(result.createdAt.toLocal())}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        Text(
          '아이 나이: 만 ${ageYears}세 ${ageMonthsRem}개월',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 16),
        SummaryCard(summary: result.summary),
        const SizedBox(height: 24),
        if (result.feedbacks.isNotEmpty) ...[
          Text('구체적 피드백 (${result.feedbacks.length}건)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...result.feedbacks.map((f) => FeedbackListItem(item: f)),
        ] else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('특별히 개선할 발화가 없었어요. 잘하고 계세요!'),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: 커밋**

```bash
git add lib/widgets/summary_card.dart lib/widgets/feedback_list_item.dart lib/screens/result/
git commit -m "feat: 분석 결과 화면 구현"
```

---

## Task 11: 홈 화면 + 히스토리 화면

**Files:**
- Create: `lib/widgets/session_card.dart`
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/screens/history/history_screen.dart`

- [ ] **Step 1: session_card.dart 작성**

`lib/widgets/session_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;

  const SessionCard({super.key, required this.session, required this.onTap});

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return m > 0 ? '${m}분 ${s}초' : '${s}초';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.mic)),
        title: Text(
          DateFormat('M월 d일 HH:mm').format(session.recordedAt.toLocal()),
        ),
        subtitle: Text('녹음 시간: ${_formatDuration(session.durationSec)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
```

- [ ] **Step 2: home_screen.dart 구현**

`lib/screens/home/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/child_service.dart';
import '../../services/session_service.dart';
import '../../models/child.dart';
import '../../models/session.dart';
import '../../widgets/session_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _childService = ChildService();
  final _sessionService = SessionService();
  Child? _child;
  List<Session> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final child = await _childService.getCurrentChild();
    if (child == null) return;
    final sessions = await _sessionService.getRecentSessions(child.id, limit: 5);
    setState(() {
      _child = child;
      _sessions = sessions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_child != null ? '${_child!.name}와의 대화' : '육아 코칭'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/history'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/recording'),
                    icon: const Icon(Icons.mic),
                    label: const Text('대화 녹음 시작'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56)),
                  ),
                  const SizedBox(height: 24),
                  if (_sessions.isNotEmpty) ...[
                    Text('최근 분석 기록',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._sessions.map(
                      (s) => SessionCard(
                        session: s,
                        onTap: () => context.go('/result/${s.id}'),
                      ),
                    ),
                  ] else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Text('아직 분석 기록이 없어요.\n첫 대화를 녹음해보세요!',
                            textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
```

- [ ] **Step 3: history_screen.dart 구현**

`lib/screens/history/history_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/child_service.dart';
import '../../services/session_service.dart';
import '../../models/session.dart';
import '../../widgets/session_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _childService = ChildService();
  final _sessionService = SessionService();
  List<Session> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final child = await _childService.getCurrentChild();
    if (child == null) return;
    final sessions = await _sessionService.getRecentSessions(child.id, limit: 100);
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('전체 기록')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text('아직 분석 기록이 없어요.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) => SessionCard(
                    session: _sessions[i],
                    onTap: () => context.go('/result/${_sessions[i].id}'),
                  ),
                ),
    );
  }
}
```

- [ ] **Step 4: 전체 빌드 + 시뮬레이터 확인**

```bash
flutter run
```

Expected:
- 로그인 → 프로필 등록 → 홈 화면 순서로 이동
- 홈에서 "대화 녹음 시작" 버튼 → 녹음 화면
- 홈 우상단 히스토리 버튼 → 히스토리 화면

- [ ] **Step 5: 커밋**

```bash
git add lib/widgets/session_card.dart lib/screens/home/ lib/screens/history/
git commit -m "feat: 홈 화면 및 히스토리 화면 구현"
```

---

## Task 12: 카카오 로그인 연동

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/services/auth_service.dart`
- Modify: `lib/screens/auth/login_screen.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Create: `supabase/functions/kakao-auth/index.ts`

- [ ] **Step 1: Kakao 개발자 앱 등록 (수동)**

1. https://developers.kakao.com → 애플리케이션 추가
2. 앱 키 → Native 앱 키 메모
3. 플랫폼 → Android: 패키지명 `com.prettyfour.pretty_four`, 키 해시 등록
4. 플랫폼 → iOS: 번들 ID `com.prettyfour.prettyFour` 등록
5. 카카오 로그인 → 활성화 → Redirect URI: `https://YOUR_PROJECT.supabase.co/functions/v1/kakao-auth`

- [ ] **Step 2: kakao_flutter_sdk 추가**

`pubspec.yaml` dependencies에 추가:
```yaml
kakao_flutter_sdk_user: ^1.9.5
```

```bash
flutter pub get
```

- [ ] **Step 3: Android Kakao 설정**

`android/app/src/main/AndroidManifest.xml`의 `<application>` 안에 추가:

```xml
<activity
  android:name="com.kakao.sdk.flutter.AuthCodeCustomTabsActivity"
  android:exported="true">
  <intent-filter android:label="flutter_web_auth">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="kakao${YOUR_KAKAO_NATIVE_APP_KEY}" android:host="oauth" />
  </intent-filter>
</activity>
```

- [ ] **Step 4: iOS Kakao 설정**

`ios/Runner/Info.plist`에 추가:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>storykompassauth</string>
  <string>kakaolink</string>
  <string>kakaotalk</string>
</array>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>kakao${YOUR_KAKAO_NATIVE_APP_KEY}</string>
    </array>
  </dict>
</array>
```

- [ ] **Step 5: Kakao Auth Edge Function 작성**

`supabase/functions/kakao-auth/index.ts`:

```typescript
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

Deno.serve(async (req) => {
  const { kakao_access_token } = await req.json()

  // 카카오 사용자 정보 조회
  const userRes = await fetch('https://kapi.kakao.com/v2/user/me', {
    headers: { Authorization: `Bearer ${kakao_access_token}` },
  })
  if (!userRes.ok) {
    return new Response(JSON.stringify({ error: 'Invalid Kakao token' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }
  const kakaoUser = await userRes.json()
  const email = kakaoUser.kakao_account?.email
  const kakaoId = String(kakaoUser.id)

  if (!email) {
    return new Response(
      JSON.stringify({ error: 'Kakao 이메일 동의가 필요합니다.' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } },
    )
  }

  // Supabase 사용자 조회 또는 생성
  const { data: existingUsers } = await supabase.auth.admin.listUsers()
  const existing = existingUsers?.users?.find((u) => u.email === email)

  let userId: string
  if (existing) {
    userId = existing.id
  } else {
    const { data: newUser, error } = await supabase.auth.admin.createUser({
      email,
      email_confirm: true,
      user_metadata: { provider: 'kakao', kakao_id: kakaoId },
    })
    if (error) throw error
    userId = newUser.user!.id
  }

  // 단기 세션 토큰 생성
  const { data: link, error: linkErr } =
    await supabase.auth.admin.generateLink({
      type: 'magiclink',
      email,
    })
  if (linkErr) throw linkErr

  return new Response(
    JSON.stringify({ access_token: link.properties?.hashed_token }),
    { headers: { 'Content-Type': 'application/json' } },
  )
})
```

- [ ] **Step 6: Kakao Auth Function 배포**

```bash
supabase functions deploy kakao-auth
```

- [ ] **Step 7: auth_service.dart에 카카오 로그인 추가**

`lib/main.dart`의 `Supabase.initialize` 위에 KakaoSdk 초기화 추가:

```dart
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

// Supabase.initialize 전에:
KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!);
```

`.env`에 추가:
```
KAKAO_NATIVE_APP_KEY=YOUR_KAKAO_NATIVE_APP_KEY
```

`lib/services/auth_service.dart`에 메서드 추가:

```dart
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

// 기존 클래스 내부에 추가:
Future<void> signInWithKakao() async {
  final token = await UserApi.instance.loginWithKakaoAccount();

  final res = await _client.functions.invoke(
    'kakao-auth',
    body: {'kakao_access_token': token.accessToken},
  );

  final accessToken = res.data?['access_token'] as String?;
  if (accessToken == null) throw Exception('카카오 로그인 실패');

  await _client.auth.verifyOTP(
    type: OtpType.magiclink,
    token: accessToken,
  );
}
```

- [ ] **Step 8: 로그인 화면에 카카오 버튼 추가**

`lib/screens/auth/login_screen.dart`의 구글 버튼 위에 추가:

```dart
OutlinedButton.icon(
  onPressed: _loading ? null : () async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithKakao();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카카오 로그인 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  },
  icon: const Icon(Icons.chat_bubble, color: Color(0xFF3A1D1D)),
  label: const Text('카카오로 시작하기',
      style: TextStyle(color: Color(0xFF3A1D1D))),
  style: OutlinedButton.styleFrom(
    backgroundColor: const Color(0xFFFEE500),
    side: BorderSide.none,
  ),
),
```

- [ ] **Step 9: 최종 빌드 확인**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 10: 커밋**

```bash
git add .
git commit -m "feat: 카카오 로그인 연동"
```

---

## Task 13: 전체 E2E 흐름 수동 테스트

- [ ] **Step 1: 실기기/시뮬레이터에서 전체 흐름 실행**

```bash
flutter run --release
```

다음 시나리오를 순서대로 테스트:

1. 이메일 회원가입 → 이메일 인증 → 로그인
2. 아이 프로필 등록 (이름, 생년월일)
3. 홈 화면 확인
4. 녹음 화면 → 30초 이상 실제 대화 녹음 → 분석 시작
5. 분석 중 화면에서 상태 메시지 변경 확인
6. 결과 화면에서 요약 + 피드백 확인
7. 홈으로 돌아가서 기록 목록 확인
8. 히스토리 화면 확인

- [ ] **Step 2: 에러 케이스 확인**

- 마이크 권한 거부 시 안내 메시지 표시
- 네트워크 없이 업로드 시도 → 에러 메시지

- [ ] **Step 3: 최종 커밋**

```bash
git add .
git commit -m "chore: MVP 전체 구현 완료"
```
