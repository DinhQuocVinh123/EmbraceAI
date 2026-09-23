# EmbraceAI — prototype specification

Prepared for the 24 September review. Covers what the working prototype does
today, what it does not do yet, and the decisions the group needs to make.

**21 September update:** the current [session flow](session-flow.md) moves
questions before and after uninterrupted practice and adds Help. Its timings
and behavior supersede the earlier in-video interruption model below.

---

## 1. What exists

A working mobile application, not a mock-up. It runs on Android and in a mobile
web browser from a single codebase, and plays the existing 8-minute guided
relaxation video with an interaction layer drawn on top of it. The user picks
one of two settings before starting; both run the same script.

| | |
|---|---|
| Platforms | Android (APK) and mobile web, one Flutter codebase |
| Video | Two settings, each 8:00 with narration-only audio: the countryside from the subtitle-free Full HD source (1920x1080, uncropped) and a beach rendered for this app (1280x720) |
| Language | English throughout |
| Narration | Synthesised English voice, aligned to the 36 caption timings and kept separate from selectable ambience |
| Background sound | Match video, none, countryside, ocean waves or generated gentle rain; independent volume |
| Data | Stored on the device only. No network calls, no account, no server |
| Automated tests | 176, covering session logic, audio synchronisation, accessibility, timings, colour contrast and screen rendering |
| Download size | Android universal release APK: 138.3 MB |
| Software cost | Zero. Flutter, FFmpeg and the tooling used are free and open source |

---

## 2. Session structure

The video is a single continuous file. The application follows playback position
and pauses at four points to ask a question. Timings were measured directly from
the video rather than estimated.

| Beat | Section | Start | End | Interaction |
|---|---|---|---|---|
| 1 | Arrival and orientation | 0:00 | 0:45 | — |
| 2 | Safety check | 0:45 | 1:05 | **Yes / I'm not sure / Not right now** |
| 3 | Check-in | 1:05 | 1:35 | **Feeling + 0–10 stress + practice choice** |
| 4 | Grounding | 1:35 | 2:35 | — (skippable) |
| 5 | Comfortable breathing | 2:35 | 3:35 | — |
| 6 | Present-moment awareness | 3:35 | 4:35 | — |
| 7 | Body awareness | 4:35 | 5:35 | — (skippable) |
| 8 | Self-compassion | 5:35 | 6:20 | — |
| 9 | Healthcare preparation | 6:20 | 7:05 | **Open question for the care team** |
| 10 | Closing | 7:05 | 7:40 | — |
| 11 | After-session feedback | 7:40 | 8:00 | **Feeling + 0–10 stress + open reflection** |

Every question can be skipped. The session can be stopped at any moment from a
button that is always on screen.

---

## 3. The interaction model

Implemented exactly as Prof. Annie Chang described it.

| Step | In the application |
|---|---|
| Check-in | "How are you feeling right now?" — Calm / Stressed / Tired / Upset / Distracted, then a 0–10 stress scale. These are states for tailoring, not scores. |
| Tailoring | At 7 or above the wording changes to "Let's take this a little slower". The user chooses **Grounding** or **Follow the breath** |
| Practice | The choice changes playback. "Follow the breath" skips the grounding section and jumps straight to the breathing practice |
| Reflection | Five-level post-practice mood (Really hard to Really good), stress after practice, then "What did you notice during the practice?" |
| Follow-up | "Your stress went from 8 down to 4. Next time, a short body scan may suit you." |

Two points worth stating plainly:

- **This is not a chatbot placed beside the video.** The answers change which
  part of the video plays.
- **No AI model is used.** The tailoring and the closing message are produced by
  explicit rules that run offline. Nothing the user writes leaves the device.
  This keeps the component in the role Prof. Chang described — guided practice,
  reflection and adherence support — and away from anything resembling clinical
  advice. A model can be substituted later behind the same interface.

---

## 4. Accessibility

Built in from the start rather than added afterwards, as requested.

| Measure | Detail |
|---|---|
| One-tap assisted view | A single button raises text size and improves picture clarity together |
| Text size | Five steps, 100 % to 200 %, applied across the whole application |
| Picture clarity | Contrast and brightness are corrected during playback, which addresses the hazy frames without needing a second video file |
| Large captions | The video's small burned-in subtitles are covered and redrawn at the chosen size; a fixed caption rail prevents the video from moving as lines appear and disappear |
| Screen readers | Interactive elements carry labels; the caption area announces changes as they appear |
| Touch targets | Minimum 52–56 px, above the 48 px guideline |
| Stop control | Always visible; every question offers "Skip this question" |

A WCAG 2.2 colour-contrast audit has been carried out: 58 of 58 measured pairs
pass, and the thresholds are enforced by tests so a future colour change cannot
quietly break them. The full report is in `docs/wcag-audit.md`; guidance for
users with low vision is in `docs/low-vision-guide.md`.

It found real defects rather than confirming the design. Five mood colours were
failing in the light theme, the worst at 1.28:1 against a 3:1 requirement. More
seriously, captions are positioned against the screen rather than the video
frame, so on a short, wide window they fall on the picture itself — measured
across all 14,400 frames, the worst case gave white text 1.81:1. Captions now
sit on a backing plate that guarantees 6.2:1 whatever is behind them.

Not yet done: keyboard and screen-reader navigation, and SC 2.4.11 on the
question sheet.

---

## 5. Status against the feedback

### Addressed

| Feedback | Source |
|---|---|
| Make the questions an interactive component with choices during the video | Dr. Annie |
| A launch page explaining the activity before it starts | Dr. Ramis |
| Larger text | Dr. Hue |
| Clearer, brighter images on request | Dr. Hue |
| One button for a clearer, larger version | Accessibility |
| Ability to stop at any time | Accessibility |
| Check-in → tailoring → practice → reflection → follow-up | Prof. Chang |
| Open-ended questions in the experience | Next steps |
| Alternative backgrounds to choose from | Dr. Tuan, Dr. Silas |
| Whether a Vietnamese rural setting suits a general audience | Dr. Tuan, Dr. Silas |
| Sharper imagery | Dr. Hue |
| Alternative background sounds | Dr. Annie |
| Colour contrast measured against WCAG 2.2 | Accessibility |
| Welcome / Configuration / Meditation / Questionnaire pages | Next steps |
| Software and licensing costs | Jo |
| A spoken voice guiding the practice | Prof. Chang's model assumes a guided session |

### Not addressed yet

| Item | What is blocking it |
|---|---|
| A validated questionnaire instrument | No instrument has been chosen yet — see section 8 |
| A human-recorded voice | A synthesised voice exists now; whether to replace it with a clinician reading the script is a decision for the group — see section 8 |
| Tailoring driven by a trained model | Deliberately deferred. Tailoring is currently rule-based and runs offline |
| Keyboard and screen-reader navigation audit | Colour contrast is done; this is the larger remaining accessibility task |
| Where this sits in the patient journey | A clinical decision for the group |

---

## 6. The second setting

The panel raised two separate concerns that turned out to have one answer.
Dr. Tuan and Dr. Silas questioned whether a Vietnamese rural setting would feel
familiar to a general audience. Dr. Hue asked for sharper, brighter images. The
source video could not satisfy either — it has one fixed setting, and its frames
are genuinely hazy, so playback correction can raise contrast but cannot add
detail that was never recorded.

So a second setting was built rather than filmed: a beach that moves from
pre-dawn through to night across the same 8 minutes. It is rendered from code,
which has three consequences that matter here.

| | Countryside | Beach |
|---|---|---|
| Origin | Existing footage | Rendered for this app |
| Sharpness | Soft; correction helps but is limited | Exact, at any resolution |
| Frame shape | 2.56:1 after cropping | 16:9 |
| Burned-in English captions | Had them; now cropped away | Never had any |
| Watermark | Removed by processing, ~96.5% | Never had one |
| File size | 34 MB | 15 MB |
| Sound | Ambient music from the source file | Surf generated from code |
| Cost | — | Zero |

The beach also has its own sound. Rather than licensing a recording, the surf
is generated from code: a distant bed, individual waves that swell, break and
retreat, and a faint wind, with the whole thing rising and settling across the
eight minutes to follow the light. It is matched in loudness to the countryside
track, so the two settings sit at the same level and the voice ducking behaves
identically in both.

Both settings use the same script, the same eleven beats, the same timings and
the same interaction layer. Choosing a setting changes the picture and nothing
else, so no clinical content is duplicated or can drift between them. The choice
is offered on the launch page and remembered for next time.

If the group wants further settings, each new one is now a rendering job rather
than a shoot.

---

## 7. Narration

There was no spoken voice. There is one now, and how it was made matters,
because it constrains what can be changed later.

### 7.1 The source video was silent, and that was the opening

The audio track was analysed against the 36 caption timings. If a voice were
reading the captions, energy in the speech band would rise whenever a caption
appears. It did not:

The audio track was analysed against the 36 caption timings. If a voice were
reading the captions, energy in the speech band would rise whenever a caption
appears. It does not:

| Measure | Result |
|---|---|
| Speech band (300–3400 Hz) during captions vs. between them | **−1.16 dB** |
| Same measure with the caption mask shifted 40 s (control) | −0.41 dB |
| Caption segments showing a speech-energy rise | **2 of 40** |
| Consonant band (1500–7000 Hz) during captions | −4 to −6 dB |

The audio was ambient music only, and the captions carried the entire script.
That was fortunate: with nothing spoken, the wording could be corrected without
re-recording anything, which made the change in section 7.3 possible at once.

### 7.2 The voice that exists now

The narration is generated from the application's own script file, not typed
out again somewhere else. There is one copy of the words, so the voice cannot
drift from the text on screen.

Each of the 36 lines is spoken separately and placed at the second its caption
appears, rather than read straight through in the hope of landing in the right
places. Every line fits: the tightest gap is 4.6 seconds against 3.5 seconds of
speech, so no line had to be rushed. Narration is the only audio embedded in
the videos. The selected ambience plays separately and is pre-ducked at these
same timings, so it steps back while the voice speaks and returns afterward.

Checked rather than assumed: speech-band energy runs **18.6 dB** higher while a
caption is on screen than between captions. A control that shifts the caption
timings by 7 seconds gives −1.8 dB, so the alignment is real and not an artefact
of the measurement. The voice occupies 23% of the eight minutes; the rest is
deliberate silence.

The engine is `piper` — MIT licensed, open models, running offline on a local
machine at no cost. A better-sounding alternative was tested and rejected:
`edge-tts` reaches a Microsoft endpoint that carries no clear commercial
licence, which is acceptable for a demonstration but not for software given to
patients.

This also settled a conflict that existed for a while: the countryside picture
carried the old grounding wording burned into it, while the voice read the
corrected wording. Section 7.4 explains how that was resolved.

### 7.3 The grounding wording assumed Western seating

The original review noted a "feet image" concern. The feet image had already
been removed from this version of the video; every frame was checked and there
is no human figure anywhere in the file.

The wording was the remaining problem:

> "If it feels comfortable, place both feet on the floor."
> "Notice the chair supporting your body."

The setting is a traditional Vietnamese house, where people sit on a raised
wooden platform or a mat. No chair appears in any of the eight minutes.

**This has been corrected in the application.** The application covers the
video's burned-in subtitles and draws its own text, so the wording now reads:

| Was | Now |
|---|---|
| If it feels comfortable, place both feet on the floor. | If it feels comfortable, let your body settle where you are. |
| Notice the support beneath your feet. | Notice the surface beneath you. |
| Notice the chair supporting your body. | Notice what is holding your weight right now. |

The replacement works for a chair, a platform, a mat or a bed.

### 7.4 The burned-in text is gone

The countryside video carried two things painted into the picture: a "Beat N"
production label in the top-left corner, and the English subtitles along the
bottom — including, between 1:36 and 2:06, the old grounding wording that no
longer matched the voice.

The application had been hiding them under two dark gradients. That was the
wrong trade. It dimmed the top and bottom of every frame, so the picture looked
as though a spotlight were pointed at its middle, and the covered text still
showed faintly through, colliding with the caption the application draws itself.

The bands were measured across all 480 sampled seconds — the label occupies
rows 25 to 65, the subtitle plate rows 576 to 663 — and cropped away. What
remains is 1280x500, a 2.56:1 frame that is clean and at full brightness.

Counter-intuitively this shows *more* picture, not less. The old gradients ate
everything above 18% and below 66% of the frame, leaving roughly 48% visible.
The crop keeps 69%.

With both settings now clean, the scrim machinery has been removed from the
application rather than left switched off, and captions sit directly beneath
the picture instead of being pinned to the bottom of the screen.

## 8. Decisions needed

1. **Grounding wording** — approve or amend the replacement above.
2. **The voice** — keep the synthesised voice, or record a clinician reading
   the same script. For a relaxation exercise offered to someone waiting on
   test results, a human voice carries reassurance no synthesiser matches, and
   the script is only eight minutes to read. The synthesised version is not
   wasted either way: it lets the group hear the pacing and the wording before
   anyone books a recording. Changing voice is one command and does not touch
   the application.
3. **Questionnaire** — which instrument, and which items are worth keeping. The
   prototype currently asks a 0–10 stress rating before and after, a
   categorical state before practice, a five-level mood after practice, and two
   open questions.
4. **Interface modality** — the prototype is mixed: a spoken voice with
   on-screen text and touch input. Voice input has not been built. Confirm this
   is the intended direction.
5. **Point in the patient journey** — at diagnosis, between follow-ups, or on
   demand. This affects reminders and session length.
6. **Backgrounds** — two settings exist. Whether to produce more, and how many.

---

## 9. Known limitations

- The narration is synthesised, not spoken by a person. It regenerates from the
  application's script in one command, so changing the wording is cheap; changing
  it to a human voice means a recording session.
- Voice and ambience can now be switched and adjusted independently. Their
  relative levels still need user testing on target phones and with hearing
  aids before they should be treated as clinically validated defaults.
- Cropping the countryside video to remove its burned-in text cost the top and
  bottom of the frame. The result is a 2.56:1 strip: clean and bright, but
  shorter on a phone held upright than the beach setting's 16:9.
- The full script was recovered from the video by optical character recognition
  and checked by hand. If an authoritative script exists, it should replace it.
- Session data stays on the device. There is no export, no synchronisation and
  no clinician view.
