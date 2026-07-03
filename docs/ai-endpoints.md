# AI endpoints

## Tiny Lesson

`POST https://learn-english.hellorabbanii.workers.dev/`

Request body:

```json
{
  "message": "<generated prompt>",
  "temperature": 0.5
}
```

Tiny Lesson sends temperature `0.5` for more consistent educational output.
Slang Hang sends temperature `0.7` for more varied, natural conversations.

The Flutter client builds the prompt outside the presentation layer, sends it
through `TinyLessonRemoteDataSource`, and accepts either a direct lesson JSON
object or a JSON response envelope containing the lesson. The response is
rejected unless it contains exactly 12 vocabulary items, 10 phrases, all
required string fields, and empty English transliteration fields. These counts
are centralized in `TinyLessonRequirements` and reused by the prompt and parser.

Before sending a request, the user must select one proficiency level
(`Beginner`, `Intermediate`, or `C1/C2`) and enter a usage context or theme.
Both values are inserted into the versioned prompt. No generated lesson UI is
shown until the backend returns a valid response.

Prompt contract `v2` returns only `title`, `vocabulary`, and `phrases` at the
top level. The previous lesson `description` field is no longer requested or
parsed by the client.

No Gemini API key is stored or used by Flutter. Gemini credentials, model
selection, rate limiting, abuse controls, and AI usage logging belong in the
Worker. Firebase ID-token verification should be added to the Worker and the
client request once authentication is introduced to this app.

## Slang Hang

Slang Hang uses the same POST endpoint and `{ "message": prompt }` request
body. Prompt contract `v3` returns a scene title, Indonesian context and domain, exactly
two speakers, and 8–12 dialogue turns. Each dialogue may include notes for
natural expressions, including Indonesian meaning, usage explanation,
formality, and a neutral English alternative.

The client validates speaker identifiers, dialogue count, required fields, and
that every note term appears verbatim in its associated English message.

Scene context is optional. An empty context activates random-scene mode, where
Gemini chooses a believable setting, two characters, their relationship, and
the conversational topic. A non-empty context activates user-provided mode and
is treated only as the topic and setting.

During the current Slang Hang session, the client keeps up to five recent scene
summaries. Random-mode prompts include these summaries as exclusions and require
the next scene to differ in at least three dimensions: setting, relationship,
central action, conversational goal, and life domain. Superficial variants such
as canceling lunch versus canceling dinner are treated as duplicates.

## Role Playing

Role Playing is a separate interactive flow and does not reuse Slang Hang's
completed-dialogue contract. It performs three logical AI operations:

1. `scenario-v4` creates the setting, two selectable roles, conversation goal,
   success criteria, suggested expressions, and an opening for either role.
2. `response-v3` receives the current transcript and returns exactly one reply
   for the AI-controlled character, criteria progress, and 2–3 contextual reply
   suggestions for the learner. It never writes those suggestions into the
   transcript. Completion is accepted by the client only after every criterion
   is met and the learner has sent at least four messages.
3. `evaluation-v2` runs after the learner ends or completes the conversation and
   returns grammar, vocabulary, naturalness, and task-completion feedback.

The current Worker exposes one generic prompt gateway, so these operations all
POST to `https://learn-english.hellorabbanii.workers.dev/`. When the backend is
split, map them to `/ai/roleplay/scenario`, `/ai/roleplay/respond`, and
`/ai/roleplay/evaluate`; Firebase ID-token verification, rate limiting, model
selection, prompt ownership, and usage logging remain backend responsibilities.

The AI transport uses conditional native and browser implementations. Flutter
web no longer imports or executes `dart:io` networking, while Android and other
native targets continue using `HttpClient`. The Worker must allow the deployed
web origin through CORS.

The first “Butuh ide?” options are generated with the scenario and are specific
to the role selected by the learner. Every subsequent AI turn replaces them
with fresh suggestions based on the latest AI reply. Selecting an option only
copies it into the composer, so the learner can edit it before sending.

## Thought Partner

Thought Partner uses the shared AI gateway for three operations: starting a
session from an optional learner thought, producing one reflective response and
one follow-up question per turn, and creating the final insight. Its versioned
contracts return structured JSON for the session opening, language nudge,
running thought summary, suggested replies, topic-specific vocabulary, and an
elegant rewrite of one exact learner message.

User-entered thoughts and transcripts are marked as untrusted prompt data. The
feature owns its domain entities and does not depend on Role Playing chat
entities. It also avoids diagnosis and definitive professional advice. If the
gateway is split later, map these operations to `/ai/thought-partner/start`,
`/ai/thought-partner/respond`, and `/ai/thought-partner/insight`. Authentication,
rate limiting, prompt ownership, model selection, and usage logging remain
backend responsibilities.
