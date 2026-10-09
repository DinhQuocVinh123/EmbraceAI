## Participant app: signing in

Participants sign in in one of two ways. Both lead to the same account.

With the one-time link or QR code. Tap the link in the invitation, or scan the QR code with the phone camera. The app opens and signs in automatically. Each link works only once. If it has expired or was already used, the app says so and suggests signing in with the ID and key instead.

With the Participant ID and access key.

- Open embrace-ai-prototype-2026.web.app.
- Enter the Participant ID, for example EA-AKFR-D82N.
- Enter the access key, for example ABCD-EFGH-IJKL-MNPQ. The eye icon shows the key while typing.
- Tap Continue.
The dashes and letter case do not matter. The app stays signed in on that device until the participant signs out with the icon at the top right. Accounts stop working on the expiry date set by the research team.

## Participant app: first visit

On the first sign-in, participants complete two steps before they reach the programme. Both are done once.

1. Study information and consent. The screen explains the purpose, the participant's choices, the medical safety note and the information collected. The participant ticks four statements, then taps I consent and continue:

- I have read and understood the information above.
- I understand that taking part is voluntary and that I may stop at any time.
- I understand that this relaxation exercise is not medical treatment.
- I consent to the research team collecting and using the information described above for this study.
Exit without consenting signs the participant out; nothing is recorded. If staff later mark consent as withdrawn, the account shows a notice and can no longer be used.

2. About you (Appendix A). A single form with personal and health information:

- Item: Age in years; How it is answered: Number
- Item: Gender; How it is answered: Female, Male, Prefer not to say
- Item: Ethnic background; How it is answered: List, including Other (please specify) and Prefer not to say
- Item: Country of birth; How it is answered: Searchable list of countries
- Item: Relationship status; How it is answered: Single, In a relationship or partnered, Prefer not to say
- Item: Cardiovascular diagnosis; How it is answered: Free text, up to 500 characters
- Item: Other health conditions or comorbidities; How it is answered: Free text, optional

Tap Save and continue to finish. The participant then reaches the home screen.

## Participant app: a guided session

A session takes about 5 to 10 minutes including the questions. It starts from the Session tab of the home screen.

Before starting, the participant can choose:

- Setting: Vietnamese countryside, or a beach from dawn to night. The practice is the same in both.
- Guided voice: on or off, with a voice volume.
- Background sound: Match video, None, Countryside, Ocean waves or Gentle rain, with a volume and a Preview sound button.
Then tap Begin. The session runs in this order:

- Medical disclaimer. Shown before every practice. Tap I understand, continue, or Leave session.
- Safety check: "Are you feeling comfortable enough to continue?" Choosing Not right now ends the session without starting the practice.
- Check-in:
- How are you feeling right now? Calm, Stressed, Tired, Upset or Distracted.
- How stressed do you feel right now? A slider from 0 to 10.
- What would you like to practise? Grounding or Follow the breath. At a stress level of 7 or more, the app suggests Grounding.
- How much time would you like? Short practice (about 3 minutes) or Full practice (about 5 to 6 minutes).
- The practice. A narrated video with captions. The top bar shows which part is playing and a progress bar; the number of parts depends on the practice and length chosen. During the breathing part a guide shows when to breathe in and out. Pause, Help and Stop are always available.
- After the practice: how the participant feels now (five levels), their stress level again (0 to 10, next to the starting value), and an optional sentence on what they noticed.
- A question for the care team (optional): something to take to the next appointment.
- Summary. Save to journal keeps the session in the journal; Skip saving does not. Either way, the session is counted for the study.
Help during a session offers: Easier view, Text size, Brighter picture, Show captions and Reduce motion. End practice stops early and goes to the questions.

## Participant app: journal and insights

Journal tab. Entries are grouped by day, newest first, with a streak badge such as "2 days in a row". Saved sessions appear with a Session tag.

To add an entry, tap New entry:

- Choose a mood: Really hard, Not great, Okay, Quite good or Really good.
- Optionally answer the writing prompt shown under the moods; the refresh icon offers another question.
- Write a note, or leave it empty to record only the mood.
- Optionally tag it: Appointment, Family, Friends, Health, Work, Rest, Exercise or Alone.
- Change the date and time if the entry is about earlier, then tap Save.
Tap an entry to read, edit or delete it.

Insights tab. Shows the current streak, the number of entries, the 30-day average mood out of 5, a 14-day mood chart (tap a day to read it) and how often each mood was chosen.

Sessions saved to the journal, with their note, also appear when the participant signs in on another device. Entries written with New entry stay only in the browser where they were written: they do not appear on another phone or browser, and clearing the browser's data removes them. Participants should use one phone and one browser for the study.

## Participant app: final questionnaire

The final questionnaire (Appendices B to D) appears only after staff open it in the staff portal. It then shows on the participant's next visit.

- Step: 1; Appendix: B; Questions: Seven anxiety items (GAD-7) over the last 2 weeks, then overall emotional well-being; Answers: 0 Not at all to 3 Nearly every day; well-being from Very poor to Very good
- Step: 2; Appendix: C; Questions: Eight statements about the experience; Answers: Strongly disagree to Strongly agree
- Step: 3; Appendix: D; Questions: Four open questions; Answers: Free text
- Step: 4; Questions: Review of all answers, with the GAD-2 and GAD-7 totals; Answers: Submit

Every question is optional. Save and next saves a draft at each step, so the participant can close the app and continue later. On the first step, Do this later returns to the home screen, which then shows a reminder with an Open button. The totals on the review step are labelled as screening scores, not a diagnosis.

## Privacy and data

Participants are known to EmbraceAI only by a random Participant ID. The app does not ask for names, contact details, dates of birth or medical record numbers.

- Information: Account: Participant ID, study ID, group, status, expiry; Where it is kept: Study database (Supabase); Who can see it: Staff
- Information: Consent record, with its version and time; Where it is kept: Study database; Who can see it: Staff
- Information: Appendix A answers; Where it is kept: Study database; Who can see it: Staff
- Information: Appendices B to D answers, including free text; Where it is kept: Study database; Who can see it: Staff
- Information: Every completed session: date, time and mood after the session; Where it is kept: Study database; Who can see it: Staff
- Information: Notes of sessions saved to the journal: the reflection, the question for the care team, stress before and after; Where it is kept: Study database; Who can see it: The participant, on any device; not shown in the staff portal
- Information: Journal entries written with New entry; Where it is kept: Only the participant's browser; Who can see it: The participant

The web hosting (Firebase) serves the app files only and stores no study data.

Two points for everyone using the prototype:

- Do not enter identifying details in any free-text field, in either the app or the portal.
- Answers are not monitored in real time. A high anxiety score or a worrying free-text answer does not alert anyone. The app tells participants it is not a medical intervention and to contact their medical team if they feel unwell.

## Troubleshooting

- What you see: "This sign-in link has expired or has already been used"; What to do: Sign in with the Participant ID and access key, or ask staff to reissue access.
- What you see: The participant has lost the access key; What to do: Staff use Reissue sign-in QR; it issues a new key.
- What you see: "This account is not active for EmbraceAI"; What to do: The account is suspended, completed or past its expiry date. Staff can check its status.
- What you see: "The staff portal has its own address"; What to do: A staff account was opened on the participant app. Sign out and use the staff portal address.
- What you see: "This is the staff portal"; What to do: A participant account was opened on the staff portal. Sign out and use the participant app address.
- What you see: "Your study information could not be loaded"; What to do: Check the internet connection, then reload the page.
- What you see: The page looks out of date or blank; What to do: Reload with Ctrl+F5 (Windows) or Cmd+Shift+R (Mac), or close and reopen the tab.
- What you see: The video takes a while to start; What to do: Each session video is large (about 200 MB, full HD). Use Wi-Fi where possible.
- What you see: No voice or background sound; What to do: Check that the guided voice is on and the volumes are up, and that an iPhone is not on silent. Use Chrome if sound still does not play.
