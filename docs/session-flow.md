# Session flow, 21 September 2026

This is the current flow for the 24 September prototype. It supersedes the
in-video question timing described in the earlier prototype specification.

1. Welcome: choose scenery, sound level, text size, clearer picture, captions
   and reduced motion.
2. Before playback: safety check, a five-state check-in (Calm, Stressed,
   Tired, Upset or Distracted), stress rating, practice choice and a short
   (3:20) or full (5:05-6:05) duration choice. The state supports tailoring;
   it is not converted into a mood score.
3. Practice: play without automatic question prompts. Help and Stop remain
   available. The user can pause at any time.
4. After playback (or an early stop): a five-level mood rating from Really
   hard (1) to Really good (5), stress rating and reflection. This
   post-practice mood is saved to Journal and used by Insights.
5. Optional question to take to the care team.
6. Summary: save to the journal or leave without saving.

Each question stage can be skipped. Declining the safety check never starts
playback. Finishing playback does not skip feedback. Opening Help pauses the
video; closing it restores the previous playing/paused state. Help includes
view settings and an option to end practice and proceed to feedback.

Skipping the post-practice mood leaves it unrecorded. It is not silently
converted to Okay and is excluded from mood averages, charts and distribution.

## Accessibility

The app never reduces the system text size: it uses the larger of the Android
setting and the in-app 100–200% choice. At 200%, practice controls and question
flows remain visible or scrollable. Reduced motion disables app transitions and
animated state changes, and also follows the operating-system preference.

With motion enabled, meaningful state changes use restrained 160-280 ms fades,
short vertical transitions or selection emphasis. This covers tabs, pages,
dialogs, Help, question steps, choices, captions and playback state. Enabling
Reduce motion in the app or Remove animations in Android changes all of these
to zero-duration updates while preserving the same content and controls.

When captions are enabled, the practice screen reserves a fixed caption rail.
The video therefore stays in the same position while captions appear, change or
temporarily disappear. At larger text sizes, long captions scroll inside that
rail without covering the playback controls.

Screen-reader semantics identify headings, selected options, changing
captions, session progress and journal/chart summaries. During practice,
keyboard users can press Space to pause or resume, F1 for Help and Escape to
stop. Automated tests cover these contracts; manual TalkBack, VoiceOver,
hardware-switch and low-vision user testing remain release tasks.

## Sound controls

The welcome screen and in-session Help provide separate controls for the
guided voice and background sound. The voice can be switched off and has
Quiet, Normal and Louder levels. Background options are Match video, None,
Countryside, Ocean waves and Gentle rain, with Low, Medium and High levels.
All choices are saved. Selecting a background sound plays an eight-second
preview, which can also be replayed or stopped with the preview button. Changes
made from Help do not change the practice play/pause state.

Narration is embedded by itself in each video so that it remains locked to the
picture and captions. Ambience runs in a second player and follows every play,
pause and source-range seek. Each full-length ambience track is pre-ducked at
narration timings. Countryside and Ocean use the existing sources; Gentle rain
is generated deterministically by `tools/voice/make_rain_ambient.py` without an
external recording.

The packaged ambience is raised by 12 dB before the user volume setting is
applied. Measured mean levels are now -30.0 to -28.8 dB, with the highest peak
at -8.4 dB. Voice, ambience and preview players all allow audio mixing so one
player cannot take audio focus away from another.

## Media and timing

The source videos remain eight minutes long. Both picture and recorded audio
skip the question ranges, so obsolete spoken questions do not play in the
middle of practice. Captions retain source timestamps; progress and part
numbers count only the segments actually played.

The countryside deployment asset remains 1920x1080 and uses H.264 CRF 26 to
fit constrained test devices. Both deployment videos contain narration only;
the uncompressed narration and ambience sources remain outside the application
repo.

| Source range | Treatment |
|---|---|
| 0:00-0:45 | Arrival |
| 0:45-1:35 | Skip safety/check-in footage and narration |
| 1:35-2:35 | Grounding; skip when breathing-first is chosen |
| 2:35-6:20 | Breathing, awareness and self-compassion |
| 6:20-7:05 | Skip care-team question footage and narration |
| 7:05-7:40 | Closing |
| 7:40-8:00 | Do not play; show the interactive feedback screen |

The two short plans are deliberately the same length:

| Practice | Short sequence | Time |
|---|---|---|
| Grounding | Arrival, grounding, breathing, closing | 3:20 |
| Breathing | Arrival, breathing, present awareness, closing | 3:20 |

The full plans remain 6:05 with grounding and 5:05 breathing-first.
Preparation and reflection are untimed. Source-range transitions use the
player's seek API; there are no automatic question pauses during practice, but
a seek may briefly buffer on a slower device. These are duration variants of
the prototype, not validated clinical exercise protocols.

The controller and widget tests cover preparation, all four practice/duration
playlists, source caption alignment, completion, optional feedback, early
stopping, Help pause restoration, saved answers and large-text interaction.
Tailoring remains rule-based; no conversational AI was added by this change.
