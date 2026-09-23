# Using the session with low vision

This note is for anyone who finds small text or dim pictures hard to read, and
for the clinician or family member helping them set the app up the first time.

Nothing here is required. The session works without changing a single setting.
But five minutes spent on the launch page usually makes the eight minutes that
follow a good deal easier.

---

## Start here: one button

On the launch page, under **Easier to see**, there is a single button:
**Turn on easier view**.

Pressing it does two things at once — it raises the text size to 150% and it
brightens and sharpens the picture. For most people that is the whole of the
setup. The button then reads *Easier view is on*, and pressing it again puts
everything back.

Whatever you choose is remembered. You will not have to set it again next time.

---

## If you want to go further

### Text size

Below the button there are five sizes, from 100% to 200%. Tap the one that
suits you. The change applies everywhere in the app straight away — the
questions, the journal, the captions during the session — so you can judge it
from the launch page itself before you begin.

200% is genuinely large. Some text will wrap onto more lines, which is
intended; nothing is cut off or hidden.

### Captions

This is switched on already, and it follows the text size you chose, so the
words are as large as you need them.

Neither video has any text of its own any more, so nothing is competing for
space: the picture is just the picture, and the words sit beneath it.

Turning captions off leaves only the spoken voice. That is a reasonable choice
if reading is tiring.

### Reduce motion

Turn on **Reduce motion** if screen transitions or changing interface elements
are uncomfortable. The setting removes the app's page and content animations
and is remembered for the next visit. The app also respects Android's own
reduced-motion preference.

### Choosing the picture

Two settings are offered and they are not equally easy to see:

- **Beach, dawn to night** — drawn for this app, so it is exactly sharp at any
  size, with large areas of plain sky and water. It also fills more of the
  screen.
- **Vietnamese countryside** — filmed footage. Softer, with more detail
  competing for attention, and a wider, shorter frame.

If detail is hard to make out, start with the beach. The spoken words and the
practice itself are identical in both.

---

## Your phone's own settings still work

The app compares the text size set in Android's display settings with the size
chosen in the app and uses whichever is larger. It will never make text smaller
than the size requested by the phone.

Screen magnification, colour inversion and high-contrast text also work
normally. The app does not override them.

---

## With a screen reader or keyboard

The app exposes headings, selected choices, captions, progress and controls to
assistive technology. Automated tests cover this semantic structure and the
keyboard flow. Three things are worth knowing:

- Each caption is announced as it appears, without you needing to move focus.
  You can follow the whole session by listening.
- **Stop** is always the last control in the top bar, in the same place
  throughout.
- Every question offers **Skip this question**. Skipping is a normal choice,
  not an error, and nothing is lost by using it.

With a keyboard, press **Space** to pause or resume, **F1** to open Help and
**Escape** to open the stop confirmation. On-device testing with TalkBack,
VoiceOver and hardware switch controls is still required before a clinical
release.

---

## During the session

There is a spoken voice, so you do not have to read anything to follow along.
The captions repeat what is being said; they are there if you want them, not
because you need them.

Headphones help but are not required.

You can stop at any moment. Press **Stop** in the top corner. What you have
answered so far is kept, and nothing is treated as a failure.

If a question appears and you would rather not answer it, skip it. The session
continues either way.

---

## What is not solved yet

Said plainly, so nobody is caught out:

- **Audio choices are not a hearing-accessibility assessment.** Voice and
  background sound can be selected and adjusted separately, but the levels
  still need testing with hearing-aid users and on target devices.
- **Screen-reader and switch access still need on-device user testing.** The
  automated checks cannot replace testing with people who use these tools.

---

## For the clinician setting this up

If you are handing the device to someone:

1. Press **Turn on easier view** before you hand it over. It is one tap and it
   covers most needs.
2. Choose the **beach** setting if the person has said that detail is hard to
   make out.
3. Leave captions on.
4. Show them where **Stop** is. Knowing they can leave matters more than any
   display setting — this is offered to people who are often already anxious,
   and being unable to find the way out makes that worse.

The measured basis for the colour choices is in
[`wcag-audit.md`](wcag-audit.md).
