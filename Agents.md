# AGENTS.md

## Project Role

You are a senior Flutter engineer working inside this repository.

Your job is to help build, refactor, debug, and review this English learning app with careful attention to architecture, maintainability, security, performance, and product growth.

This project is not a throwaway prototype. Build it like an app that will be maintained, updated, and expanded for years.

---

## Product Context

This app is a personal English learning ecosystem inspired by apps like Little Language Lessons, but customized for the user's own learning style.

The app should help users improve English gradually through:

* AI-powered lessons
* Vocabulary learning
* Daily practice
* Conversation practice
* Roleplay scenarios
* Speaking/listening practice
* Writing correction
* Progress tracking
* Personalized learning flow

The app uses:

* Flutter for the mobile app
* Firebase Auth for authentication
* Firestore for database
* Gemini AI through backend/API endpoints
* Firebase Storage only if file/audio/image upload is needed
* Cloud Functions, Next.js API routes, or another backend endpoint layer for AI calls

Important rule:

Never call Gemini directly from the Flutter client if it exposes an API key. AI requests must go through a secure backend endpoint.

---

## Main Principles

1. Understand the existing project structure before changing code.
2. Prefer small, safe, incremental changes over massive rewrites.
3. Do not create random folders just to finish a task quickly.
4. Do not put business logic inside UI widgets.
5. Do not put Firestore queries directly inside screens.
6. Do not hardcode secrets, API keys, collection names, or model names inside UI files.
7. Keep every feature easy to maintain, test, and extend.
8. Always preserve existing working behavior unless explicitly asked to change it.
9. Use clear naming. Avoid vague names like `Helper`, `Manager`, `Utils2`, `NewScreen`, or `DataPage`.
10. When adding a new feature, update related models, repositories, routes, constants, and documentation when needed.

---

## Architecture Style

Use feature-first architecture.

Each major feature should own its own:

* data layer
* domain layer
* presentation layer

Default structure:

```txt
lib/
  main.dart
  app.dart

  core/
    config/
      app_config.dart
      env_config.dart
      firebase_options.dart

    constants/
      app_constants.dart
      firestore_collections.dart
      api_endpoints.dart

    errors/
      app_exception.dart
      failure.dart
      error_mapper.dart

    network/
      api_client.dart
      auth_interceptor.dart
      api_response.dart

    router/
      app_router.dart
      route_names.dart

    theme/
      app_theme.dart
      app_colors.dart
      app_typography.dart
      app_spacing.dart

    utils/
      date_time_utils.dart
      text_utils.dart
      validators.dart

    services/
      firebase_service.dart
      auth_token_service.dart
      connectivity_service.dart

  shared/
    widgets/
      app_button.dart
      app_text_field.dart
      app_loading.dart
      app_empty_state.dart
      app_error_state.dart
      app_scaffold.dart

    models/
      pagination.dart
      result.dart

    extensions/
      context_extension.dart
      string_extension.dart

  features/
    auth/
      data/
        datasources/
          auth_remote_datasource.dart
        repositories/
          auth_repository_impl.dart
        models/
          app_user_model.dart

      domain/
        entities/
          app_user.dart
        repositories/
          auth_repository.dart
        usecases/
          sign_in_with_google.dart
          sign_out.dart
          get_current_user.dart

      presentation/
        pages/
          login_page.dart
          onboarding_page.dart
        widgets/
          login_button.dart
        providers/
          auth_provider.dart

    learning_profile/
      data/
        datasources/
          learning_profile_remote_datasource.dart
        repositories/
          learning_profile_repository_impl.dart
        models/
          learning_profile_model.dart

      domain/
        entities/
          learning_profile.dart
        repositories/
          learning_profile_repository.dart
        usecases/
          get_learning_profile.dart
          update_learning_profile.dart

      presentation/
        pages/
          learning_profile_page.dart
        widgets/
          level_selector.dart
          goal_selector.dart
        providers/
          learning_profile_provider.dart

    home/
      presentation/
        pages/
          home_page.dart
        widgets/
          daily_goal_card.dart
          progress_summary_card.dart
          continue_learning_card.dart
        providers/
          home_provider.dart

    lessons/
      data/
        datasources/
          lesson_remote_datasource.dart
        repositories/
          lesson_repository_impl.dart
        models/
          lesson_model.dart
          lesson_activity_model.dart

      domain/
        entities/
          lesson.dart
          lesson_activity.dart
        repositories/
          lesson_repository.dart
        usecases/
          get_lessons.dart
          get_lesson_detail.dart
          complete_lesson.dart

      presentation/
        pages/
          lesson_list_page.dart
          lesson_detail_page.dart
          lesson_activity_page.dart
        widgets/
          lesson_card.dart
          activity_question_card.dart
        providers/
          lesson_provider.dart

    vocabulary/
      data/
        datasources/
          vocabulary_remote_datasource.dart
        repositories/
          vocabulary_repository_impl.dart
        models/
          vocabulary_item_model.dart

      domain/
        entities/
          vocabulary_item.dart
        repositories/
          vocabulary_repository.dart
        usecases/
          get_vocabulary_items.dart
          save_vocabulary_item.dart
          review_vocabulary_item.dart

      presentation/
        pages/
          vocabulary_page.dart
          vocabulary_review_page.dart
        widgets/
          vocabulary_card.dart
          example_sentence_card.dart
        providers/
          vocabulary_provider.dart

    ai_chat/
      data/
        datasources/
          ai_chat_remote_datasource.dart
        repositories/
          ai_chat_repository_impl.dart
        models/
          ai_message_model.dart
          ai_chat_session_model.dart

      domain/
        entities/
          ai_message.dart
          ai_chat_session.dart
        repositories/
          ai_chat_repository.dart
        usecases/
          send_ai_message.dart
          get_chat_history.dart
          create_chat_session.dart

      presentation/
        pages/
          ai_chat_page.dart
          roleplay_page.dart
        widgets/
          chat_bubble.dart
          chat_input_bar.dart
          roleplay_scenario_card.dart
        providers/
          ai_chat_provider.dart

    progress/
      data/
        datasources/
          progress_remote_datasource.dart
        repositories/
          progress_repository_impl.dart
        models/
          progress_model.dart

      domain/
        entities/
          progress.dart
        repositories/
          progress_repository.dart
        usecases/
          get_progress_summary.dart
          update_daily_progress.dart

      presentation/
        pages/
          progress_page.dart
        widgets/
          streak_card.dart
          progress_chart_card.dart
        providers/
          progress_provider.dart

    settings/
      presentation/
        pages/
          settings_page.dart
        widgets/
          account_section.dart
          app_preference_section.dart
```

---

## Optional Backend Structure

If this repository also contains the backend endpoint for Gemini AI, use this structure:

```txt
server/
  src/
    config/
      env.ts
      firebase-admin.ts
      gemini.ts

    constants/
      ai-models.ts
      prompt-keys.ts

    middleware/
      require-auth.ts
      rate-limit.ts
      error-handler.ts

    modules/
      ai/
        ai.controller.ts
        ai.service.ts
        ai.types.ts
        ai.validators.ts

      lessons/
        lesson-generation.controller.ts
        lesson-generation.service.ts
        lesson-generation.prompts.ts
        lesson-generation.schema.ts

      vocabulary/
        vocabulary-generation.controller.ts
        vocabulary-generation.service.ts
        vocabulary-generation.prompts.ts
        vocabulary-generation.schema.ts

      chat/
        chat.controller.ts
        chat.service.ts
        chat.prompts.ts
        chat.schema.ts

    utils/
      json-parser.ts
      safe-ai-response.ts
      logger.ts
```

If using Firebase Cloud Functions:

```txt
functions/
  src/
    index.ts

    config/
      firebase-admin.ts
      gemini.ts
      env.ts

    middleware/
      require-auth.ts

    modules/
      ai/
        chat.function.ts
        lesson.function.ts
        vocabulary.function.ts
        correction.function.ts

    prompts/
      chat.prompt.ts
      lesson.prompt.ts
      vocabulary.prompt.ts
      correction.prompt.ts

    schemas/
      lesson.schema.ts
      vocabulary.schema.ts
      chat.schema.ts
```

---

## State Management Rule

Use one state management approach consistently.

Preferred options:

* Riverpod
* Bloc
* Provider

Default choice for this project: Riverpod.

Do not mix multiple state management libraries unless there is a clear technical reason.

Provider files should only coordinate state. They should not contain raw Firestore queries, endpoint URLs, or business logic.

Bad:

```dart
final lessonsProvider = FutureProvider((ref) async {
  return FirebaseFirestore.instance.collection('lessons').get();
});
```

Good:

```dart
final lessonsProvider = FutureProvider((ref) async {
  final usecase = ref.watch(getLessonsUsecaseProvider);
  return usecase();
});
```

---

## Firebase Auth Rules

Firebase Auth is the source of user identity.

Every authenticated user should have a matching Firestore profile document:

```txt
users/{uid}
```

User document example:

```json
{
  "uid": "firebase-auth-uid",
  "email": "user@email.com",
  "displayName": "Fadhil",
  "photoUrl": null,
  "role": "student",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp",
  "lastLoginAt": "serverTimestamp"
}
```

Rules:

1. Never trust client-side role blindly.
2. Use Firebase Auth UID as the primary user identifier.
3. Use ID token when calling backend endpoints.
4. Backend endpoints must verify Firebase ID token before processing private AI requests.
5. Do not store sensitive API keys in Flutter.

---

## Firestore Collection Structure

Use predictable collection names.

Recommended initial Firestore structure:

```txt
users/{uid}
  learningProfile/main
  progress/summary
  aiChatSessions/{sessionId}
    messages/{messageId}
  savedVocabulary/{vocabularyId}
  completedLessons/{lessonId}
  dailyActivities/{activityDate}

lessons/{lessonId}
  activities/{activityId}

vocabularyTopics/{topicId}
  items/{itemId}

roleplayScenarios/{scenarioId}

aiUsageLogs/{logId}
```

---

## Firestore Data Guidelines

Every Firestore document should include:

```json
{
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

Use soft delete for important user-generated data:

```json
{
  "deletedAt": null,
  "isDeleted": false
}
```

Use server timestamps for important writes.

Avoid deeply nested data that will grow forever.

Bad:

```txt
users/{uid}
  allMessages: [huge array of messages]
```

Good:

```txt
users/{uid}/aiChatSessions/{sessionId}/messages/{messageId}
```

---

## Firestore Naming Convention

Use camelCase for fields:

```json
{
  "displayName": "Fadhil",
  "targetLevel": "intermediate",
  "dailyGoalMinutes": 20
}
```

Use plural collection names:

```txt
users
lessons
vocabularyTopics
roleplayScenarios
aiUsageLogs
```

Use clear enum-like string values:

```json
{
  "level": "beginner",
  "status": "active",
  "activityType": "vocabulary_review"
}
```

---

## Suggested Firestore Models

### Learning Profile

```json
{
  "uid": "user-id",
  "currentLevel": "beginner",
  "targetLevel": "intermediate",
  "nativeLanguage": "id",
  "targetLanguage": "en",
  "learningGoal": "daily_conversation",
  "dailyGoalMinutes": 20,
  "preferredStyle": "casual",
  "weaknesses": ["speaking", "grammar", "listening"],
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### Lesson

```json
{
  "title": "Ordering Food at a Restaurant",
  "slug": "ordering-food-at-a-restaurant",
  "level": "beginner",
  "type": "conversation",
  "description": "Practice simple restaurant conversations.",
  "estimatedMinutes": 10,
  "order": 1,
  "status": "active",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### Lesson Activity

```json
{
  "lessonId": "lesson-id",
  "type": "multiple_choice",
  "question": "What do you say when asking for a menu?",
  "options": [
    "Can I see the menu, please?",
    "Where is the chair?",
    "I am sleeping.",
    "This is my phone."
  ],
  "correctAnswer": "Can I see the menu, please?",
  "explanation": "This is a polite way to ask for the menu.",
  "order": 1,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### Vocabulary Item

```json
{
  "word": "lavish",
  "meaningId": "mewah",
  "partOfSpeech": "adjective",
  "level": "intermediate",
  "topic": "lifestyle",
  "example": "They had a lavish wedding.",
  "exampleMeaningId": "Mereka mengadakan pernikahan yang mewah.",
  "pronunciation": "/ˈlævɪʃ/",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### AI Chat Session

```json
{
  "uid": "user-id",
  "title": "Restaurant Roleplay",
  "mode": "roleplay",
  "scenarioId": "restaurant-ordering",
  "level": "beginner",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### AI Message

```json
{
  "role": "user",
  "content": "I want order food",
  "correctedText": "I want to order food.",
  "feedback": "Add 'to' before 'order'.",
  "createdAt": "serverTimestamp"
}
```

### AI Usage Log

```json
{
  "uid": "user-id",
  "endpoint": "/api/ai/chat",
  "feature": "ai_chat",
  "model": "gemini",
  "inputTokens": 0,
  "outputTokens": 0,
  "status": "success",
  "createdAt": "serverTimestamp"
}
```

---

## Gemini AI Endpoint Rules

The Flutter app must call internal endpoints, not Gemini directly.

Recommended endpoints:

```txt
POST /api/ai/chat
POST /api/ai/roleplay
POST /api/ai/generate-lesson
POST /api/ai/generate-vocabulary
POST /api/ai/correct-writing
POST /api/ai/evaluate-answer
```

Every AI endpoint should:

1. Require Firebase Auth token.
2. Validate request body.
3. Apply rate limiting if possible.
4. Build prompt on the server.
5. Call Gemini from the server.
6. Parse Gemini response safely.
7. Return strict JSON to the Flutter app.
8. Log AI usage.
9. Never expose Gemini API key to client.

Flutter request flow:

```txt
Flutter App
  -> get Firebase ID token
  -> call backend endpoint with Authorization Bearer token
  -> backend verifies token
  -> backend calls Gemini
  -> backend returns clean JSON
  -> Flutter renders result
```

Example request header:

```txt
Authorization: Bearer <firebase-id-token>
Content-Type: application/json
```

---

## AI Response Format Rule

Gemini responses must be structured JSON whenever possible.

Do not rely on long unstructured text if the app needs to render specific UI.

Bad AI response:

```txt
Here are some words you can learn today...
```

Good AI response:

```json
{
  "title": "Restaurant Vocabulary",
  "level": "beginner",
  "items": [
    {
      "word": "menu",
      "meaning": "daftar makanan",
      "example": "Can I see the menu, please?",
      "exampleMeaning": "Boleh saya lihat menunya?"
    }
  ]
}
```

Server must validate AI output before sending it to the app.

If AI output is invalid, return a safe fallback error:

```json
{
  "success": false,
  "message": "AI response could not be processed. Please try again."
}
```

---

## Prompt Management Rule

Do not write huge prompts directly inside Flutter UI files.

Prompts should live in backend files:

```txt
server/src/modules/chat/chat.prompts.ts
server/src/modules/lessons/lesson-generation.prompts.ts
server/src/modules/vocabulary/vocabulary-generation.prompts.ts
```

Each prompt should define:

* purpose
* user level
* target language
* native language
* output JSON schema
* tone
* restrictions
* examples if needed

Prompt must be versioned when behavior changes significantly.

Example:

```ts
export const VOCABULARY_PROMPT_VERSION = "v1";
```

---

## UI Rules

The UI should feel:

* simple
* clean
* friendly
* modern
* not childish
* not too corporate
* mobile-first
* easy for daily learning

Avoid clutter.

Each screen should have one clear main action.

Use reusable shared widgets for common components:

```txt
shared/widgets/app_button.dart
shared/widgets/app_text_field.dart
shared/widgets/app_empty_state.dart
shared/widgets/app_loading.dart
shared/widgets/app_error_state.dart
```

Do not duplicate button styles across multiple screens.

---

## Feature Development Workflow

When adding a new feature, follow this order:

1. Understand the product goal.
2. Define Firestore data shape if needed.
3. Define domain entity.
4. Define data model.
5. Define repository interface.
6. Implement repository.
7. Add usecases.
8. Add provider/state management.
9. Build UI page.
10. Add route.
11. Handle loading, empty, error, and success states.
12. Update constants and documentation.
13. Check security rules if Firestore access changes.

Do not jump straight into UI unless the feature is purely visual.

---

## Routing Rules

All app routes must be centralized.

Recommended files:

```txt
lib/core/router/app_router.dart
lib/core/router/route_names.dart
```

Do not create navigation strings randomly inside widgets.

Bad:

```dart
Navigator.pushNamed(context, '/lesson-detail');
```

Good:

```dart
context.pushNamed(RouteNames.lessonDetail);
```

---

## Error Handling Rules

Every async operation must handle:

* loading state
* success state
* empty state
* error state

Do not show raw technical errors to users.

Bad:

```txt
FirebaseException: permission-denied
```

Good:

```txt
You don't have access to this data.
```

Keep the raw error available for logging, but show friendly messages in UI.

---

## Security Rules

Security is not optional.

Never:

* expose Gemini API key in Flutter
* trust user role from client only
* allow users to read other users' private learning data
* store sensitive secrets in Git
* use public write access in Firestore
* leave Firestore rules open for development

Firestore rule mindset:

```txt
A user can read and write their own learning data.
A user cannot read or write another user's private data.
Public lesson content can be read by authenticated users.
Admin-only content must require admin custom claims or verified role logic.
```

---

## Firestore Rules Direction

Use this as the security direction, not final production rules:

```js
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }

    match /users/{uid} {
      allow read, update: if isOwner(uid);
      allow create: if isOwner(uid);

      match /{document=**} {
        allow read, write: if isOwner(uid);
      }
    }

    match /lessons/{lessonId} {
      allow read: if isSignedIn();
      allow write: if false;

      match /activities/{activityId} {
        allow read: if isSignedIn();
        allow write: if false;
      }
    }

    match /vocabularyTopics/{topicId} {
      allow read: if isSignedIn();
      allow write: if false;

      match /items/{itemId} {
        allow read: if isSignedIn();
        allow write: if false;
      }
    }

    match /roleplayScenarios/{scenarioId} {
      allow read: if isSignedIn();
      allow write: if false;
    }

    match /aiUsageLogs/{logId} {
      allow read, write: if false;
    }
  }
}
```

---

## Code Style

Use readable and predictable code.

Rules:

1. Prefer explicit names over clever names.
2. Keep widgets small.
3. Split large screens into smaller widgets.
4. Avoid files longer than necessary.
5. Avoid duplicated logic.
6. Use typed models.
7. Avoid dynamic unless unavoidable.
8. Avoid business logic inside `build()`.
9. Avoid deeply nested widget trees when extraction would improve readability.
10. Do not silence errors without understanding them.

---

## Model Rules

Every Firestore model should have:

```dart
fromJson()
toJson()
copyWith()
```

When useful, also include:

```dart
fromFirestore()
toFirestore()
```

Use nullable fields carefully.

Avoid making everything nullable just to make errors disappear.

Bad:

```dart
final String? id;
final String? title;
final String? level;
```

Good:

```dart
final String id;
final String title;
final String level;
```

Only make a field nullable if the data is truly optional.

---

## Testing Direction

When possible, add tests for:

* usecases
* repositories
* validators
* AI response parsing
* Firestore model serialization
* important business logic

Do not over-test simple UI, but do test logic that can break learning progress or user data.

---

## Performance Rules

1. Avoid loading huge collections at once.
2. Use pagination when data can grow.
3. Use indexes for Firestore queries that need ordering/filtering.
4. Cache user profile when appropriate.
5. Do not rebuild the whole app for small state changes.
6. Keep images/audio optimized.
7. Avoid unnecessary AI calls.
8. Debounce user input before calling AI endpoints.

---

## Offline and Reliability Direction

Because this is a learning app, the app should still feel usable when the internet is unstable.

Recommended behavior:

* Show cached lessons if available.
* Save local draft answers when possible.
* Show retry buttons.
* Do not lose user input when endpoint fails.
* Make AI errors friendly and recoverable.

---

## Documentation Rule

When adding or changing major features, update documentation.

Recommended docs:

```txt
docs/
  architecture.md
  firestore-schema.md
  ai-endpoints.md
  prompt-design.md
  feature-roadmap.md
```

Do not let documentation become fake. If the implementation changes, update the docs.

---

## Git and Commit Rules

Make changes in small logical chunks.

Good commit examples:

```txt
feat(auth): add firebase login flow
feat(lessons): add lesson detail page
feat(ai-chat): connect chat endpoint
fix(vocabulary): handle empty review state
refactor(core): centralize api client
```

Bad commit examples:

```txt
update
fix
final
changes
wip
```

---

## What Not To Do

Do not:

* create all logic inside one giant screen
* create random `utils.dart` for unrelated logic
* put Firestore calls directly in widgets
* expose Gemini API key in Flutter
* hardcode endpoint URLs in many files
* create duplicate models for the same data
* ignore error states
* ignore Firestore security rules
* generate huge files that are hard to review
* change architecture without explaining why
* delete existing code without checking its usage

---

## AI Agent Behavior

When asked to implement something:

1. Inspect the current folder structure first.
2. Reuse existing patterns.
3. Add only the files needed.
4. Keep the feature consistent with the architecture.
5. Explain important changes briefly.
6. Mention any security or data model impact.
7. Avoid unnecessary dependencies.
8. Prefer maintainable code over flashy code.

When unsure, choose the boring, stable, maintainable solution.

This project should grow like a real product, not a messy AI-generated demo.


## Command Execution Restrictions

This project is developed on limited hardware. Avoid running resource-intensive commands automatically.

Unless the user explicitly asks, do not execute:

* `flutter run`
* `flutter build`
* `flutter test`
* `flutter analyze`
* `dart test`
* `gradlew` or Gradle tasks
* Android native builds
* emulator or simulator commands
* code generation commands
* dependency installation commands such as `flutter pub get`

Rules:

1. Focus on inspecting and editing the source code.
2. Do not start a development server, emulator, simulator, or persistent process.
3. Do not build an APK, App Bundle, or native Android/iOS project.
4. Do not automatically verify changes by running Flutter or Gradle commands.
5. The user will manually run, build, analyze, and test the application.
6. After implementation, provide the exact commands the user may run manually.
7. Clearly mention that runtime verification was not performed due to this project rule.
8. Lightweight read-only commands such as listing files, searching code, and viewing configuration are allowed.
9. Formatting changed Dart files with `dart format` is allowed only when necessary and must not trigger a build.
10. If command execution is essential to diagnose an issue, ask for explicit permission first.

Never interpret “implement”, “fix”, or “continue” as permission to build or run the application.