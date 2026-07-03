# Speaking Challenge

Speaking Challenge is a one-shot practice flow:

1. The learner selects a level and one of four challenge types.
2. The existing secure AI gateway generates a structured challenge.
3. `speech_to_text` transcribes one English response on the device.
4. The learner may correct obvious transcription mistakes.
5. The transcript is sent through the AI gateway for structured evaluation.

Supported types are One-Minute Monologue, Read Aloud, Story Retelling, and
Describe the Scene.

## Assessment boundary

The app evaluates transcript evidence: grammar, vocabulary, coherence, textual
reading accuracy, and task completion. Native speech recognition does not
provide reliable phoneme, pronunciation, intonation, pause, or audio-quality
assessment. Product copy and prompts must not present transcript-based scores
as pronunciation scores.

## Platform configuration

- Android requires `RECORD_AUDIO` and a speech recognition service.
- iOS requires microphone and speech recognition usage descriptions.
- Recognition uses `en_US` when available and otherwise falls back to another
  installed English locale.

The recognizer may stop after a pause or according to device-specific limits.
The transcript remains editable so learners do not lose their response when the
native recognizer makes an obvious mistake.
