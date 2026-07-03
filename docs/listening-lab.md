# Listening Lab

Listening Lab provides four one-shot practice modes: Listen & Choose, Missing
Words, Dictation, and Shadowing.

## Request flow

1. The learner chooses a proficiency level, challenge type, accent, and speed.
2. The existing secure AI gateway generates validated structured JSON.
3. Device TTS reads `textToSpeak`; accent and speed never require another AI
   request.
4. Listen & Choose and Missing Words are checked locally.
5. Dictation and the Shadowing transcript use the secure AI gateway for
   structured feedback.

Prompts are versioned in `ListeningLabPromptBuilder`. Gemini credentials remain
behind the existing endpoint and are never included in Flutter code.

## Assessment boundary

Shadowing currently uses native speech-to-text and compares its transcript with
the expected sentence. This can identify missing, extra, or mismatched words,
but it cannot reliably score phonemes, stress, intonation, pauses, or actual
pronunciation quality. A future audio-capable backend can add those measurements
without changing the challenge domain model.

## Reliability and platform setup

- The learner can replay audio without another AI request.
- Answers remain in the UI when evaluation fails so they can retry.
- AI JSON is validated and retried once when malformed.
- Android already declares recording and speech/TTS service access.
- iOS already includes microphone and speech-recognition usage descriptions.
