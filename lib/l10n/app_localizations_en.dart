// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageTitle => 'Language';

  @override
  String get languagePhone => 'Same as my phone';

  @override
  String get languageButtonTooltip => 'Language';

  @override
  String get languageVoiceNote =>
      'The guide\'s voice, the captions and the rest of the app follow the language you choose.';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonDone => 'Done';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonClose => 'Close';

  @override
  String get homeSignOut => 'Sign out';

  @override
  String get homeNewEntry => 'New entry';

  @override
  String get homeTabSession => 'Session';

  @override
  String get homeTabJournal => 'Journal';

  @override
  String get homeTabInsights => 'Insights';

  @override
  String get homeFinalReady => 'Final questionnaire is ready';

  @override
  String get welcomeTitle => 'A quiet moment';

  @override
  String get welcomeIntro =>
      'A guided relaxation for the time around appointments and test results. All you need to do is sit still and follow along.';

  @override
  String get welcomeSessionSaved => 'Session saved to your journal';

  @override
  String journalLineQuestion(String question) {
    return 'Question for the team: $question';
  }

  @override
  String journalLineStress(int before, int after) {
    return 'Stress: $before → $after';
  }

  @override
  String get welcomeAskTitle => 'Ask EmbraceAI (preview)';

  @override
  String get welcomeAskSubtitle => 'Questions about the exercises or the app';

  @override
  String get welcomeBegin => 'Begin';

  @override
  String get welcomeStopAnyTime => 'You can stop at any time.';

  @override
  String get welcomeEasierTitle => 'Easier to see';

  @override
  String get welcomeEasierBody =>
      'If small text is hard to read, or the picture looks hazy, turn this on.';

  @override
  String get welcomeEasierOn => 'Easier view is on';

  @override
  String get welcomeEasierTurnOn => 'Turn on easier view';

  @override
  String get welcomeExpectTimeTitle => 'Choose 3 or 5 to 6 minutes';

  @override
  String get welcomeExpectTimeBody => 'A little time for yourself';

  @override
  String get welcomeExpectFlowTitle => 'Before and after';

  @override
  String get welcomeExpectFlowBody =>
      'A check-in, uninterrupted practice, then time to reflect';

  @override
  String get welcomeExpectHeadphonesTitle => 'Headphones help';

  @override
  String get welcomeExpectHeadphonesBody => 'But are not required';

  @override
  String get welcomeExpectStopTitle => 'Stop any time';

  @override
  String get welcomeExpectStopBody => 'Nothing is lost';

  @override
  String get welcomeSceneTitle => 'Setting';

  @override
  String get welcomeSceneBody =>
      'Choose what you would like to look at. The practice itself is the same.';

  @override
  String get welcomeSoundDisplayTitle => 'Sound and display';

  @override
  String get welcomeTextSize => 'Text size';

  @override
  String percentValue(int percent) {
    return '$percent%';
  }

  @override
  String get welcomeShowCaptions => 'Show captions';

  @override
  String get welcomeShowCaptionsBody =>
      'Writes out what is being said, at the size you chose';

  @override
  String get welcomeReduceMotion => 'Reduce motion';

  @override
  String get welcomeReduceMotionBody =>
      'Removes non-essential fades and page movement';

  @override
  String durationMinSec(int minutes, int seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String welcomeDurations(String short, String full, String breathing) {
    return 'Short $short · Full $full with grounding or $breathing with breathing';
  }

  @override
  String get welcomeSummaryVoiceOn => 'Voice on';

  @override
  String get welcomeSummaryVoiceOff => 'Voice off';

  @override
  String welcomeSummaryText(int percent) {
    return 'Text $percent%';
  }

  @override
  String get welcomeSummaryCaptionsOn => 'Captions on';

  @override
  String get welcomeSummaryCaptionsOff => 'Captions off';

  @override
  String get sceneCountryside => 'Vietnamese countryside';

  @override
  String get sceneCountrysideDescription =>
      'Sunrise courtyards, still water and a quiet village lane';

  @override
  String get sceneBeach => 'Beach, dawn to night';

  @override
  String get sceneBeachDescription =>
      'Open horizon, slow waves, the light changing through the day';

  @override
  String get soundMatchVideo => 'Match video';

  @override
  String get soundMatchVideoDescription =>
      'Countryside music or ocean waves chosen with the picture';

  @override
  String get soundNone => 'None';

  @override
  String get soundNoneDescription => 'Narration without a background sound';

  @override
  String get soundCountryside => 'Countryside';

  @override
  String get soundCountrysideDescription =>
      'Soft instrumental countryside ambience';

  @override
  String get soundOcean => 'Ocean waves';

  @override
  String get soundOceanDescription => 'Slow waves and a light sea breeze';

  @override
  String get soundRain => 'Gentle rain';

  @override
  String get soundRainDescription => 'Steady rain without thunder';

  @override
  String get levelQuiet => 'Quiet';

  @override
  String get levelQuietDescription => 'Soft volume';

  @override
  String get levelNormal => 'Normal';

  @override
  String get levelNormalDescription => 'Comfortable volume';

  @override
  String get levelLouder => 'Louder';

  @override
  String get levelLouderDescription => 'Full volume';

  @override
  String get moodAwful => 'Really hard';

  @override
  String get moodLow => 'Not great';

  @override
  String get moodNeutral => 'Okay';

  @override
  String get moodGood => 'Quite good';

  @override
  String get moodGreat => 'Really good';

  @override
  String get feelingCalm => 'Calm';

  @override
  String get feelingStressed => 'Stressed';

  @override
  String get feelingTired => 'Tired';

  @override
  String get feelingUpset => 'Upset';

  @override
  String get feelingDistracted => 'Distracted';

  @override
  String get safetyYes => 'Yes, I can sit quietly';

  @override
  String get safetyUnsure => 'I\'m not sure';

  @override
  String get safetyNo => 'Not right now';

  @override
  String get practiceGrounding => 'Grounding';

  @override
  String get practiceGroundingDescription =>
      'Notice the support beneath you, then follow your breath';

  @override
  String get practiceBreathing => 'Follow the breath';

  @override
  String get practiceBreathingDescription =>
      'Go straight to the breathing practice';

  @override
  String get lengthShort => 'Short practice';

  @override
  String get lengthShortDescription => 'About 3 minutes';

  @override
  String get lengthFull => 'Full practice';

  @override
  String get lengthFullDescription => 'About 5 to 6 minutes';

  @override
  String get breatheIn => 'Breathe in';

  @override
  String get breatheOut => 'Breathe out';

  @override
  String get commonContinue => 'Continue';

  @override
  String get promptSkipQuestion => 'Skip this question';

  @override
  String get disclaimerTitle => 'Medical disclaimer';

  @override
  String get disclaimerSubtitle => 'Please read this before every practice.';

  @override
  String get disclaimerBody =>
      'This is not a medical intervention. If you experience any discomfort, please stop immediately and seek help from your medical team.';

  @override
  String get disclaimerAccept => 'I understand, continue';

  @override
  String get disclaimerLeave => 'Leave session';

  @override
  String get safetyTitle => 'Are you feeling comfortable enough to continue?';

  @override
  String get safetyBody =>
      'This practice needs you somewhere safe. Please do not do it while driving or operating machinery.';

  @override
  String get checkInFeelingTitle => 'How are you feeling right now?';

  @override
  String get checkInStressTitle => 'How stressed do you feel right now?';

  @override
  String get checkInStressSubtitle =>
      '0 is completely at ease, 10 is the most stressed.';

  @override
  String get checkInSlowerTitle => 'Let\'s take this a little slower';

  @override
  String get checkInChooseTitle => 'What would you like to practise?';

  @override
  String get checkInSlowerBody =>
      'You are carrying a lot right now. Grounding often settles things faster.';

  @override
  String get checkInLengthTitle => 'How much time would you like?';

  @override
  String get checkInLengthSubtitle => 'Both options end with time to reflect.';

  @override
  String get questionTitle => 'Is there one question you would like answered?';

  @override
  String get questionSubtitle =>
      'Write it down here to take to your next appointment.';

  @override
  String get questionLabel => 'Question for your care team';

  @override
  String get questionHint => 'For example: how will this affect my daily life?';

  @override
  String get questionSave => 'Save and continue';

  @override
  String get feedbackMoodTitle => 'How do you feel now?';

  @override
  String get feedbackMoodSubtitle =>
      'Choose the answer that feels closest. There is no right answer.';

  @override
  String get feedbackStressTitle => 'And where is your stress now?';

  @override
  String feedbackStressStarted(int value) {
    return 'You started at $value.';
  }

  @override
  String get feedbackNoticeTitle => 'What did you notice during the practice?';

  @override
  String get feedbackNoticeSubtitle =>
      'One sentence is plenty. There is no right answer.';

  @override
  String get feedbackNoticeLabel => 'What you noticed';

  @override
  String get feedbackNoticeHint =>
      'For example: my shoulders softened, my breathing slowed towards the end.';

  @override
  String get stressLevel => 'Stress level';

  @override
  String stressOutOfTen(int value) {
    return '$value out of 10';
  }

  @override
  String get stressScaleLow => '0 · at ease';

  @override
  String get stressScaleHigh => '10 · very stressed';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpClose => 'Close help';

  @override
  String get helpBody =>
      'Take your time. Find a comfortable position and let your breathing stay natural. You can leave the practice whenever you need to.';

  @override
  String get helpEasierView => 'Easier view';

  @override
  String get helpBrighterPicture => 'Brighter picture';

  @override
  String get helpReturn => 'Return to practice';

  @override
  String get helpEnd => 'End practice';

  @override
  String get soundGuidedVoice => 'Guided voice';

  @override
  String get soundGuidedVoiceBody => 'Spoken narration during the practice';

  @override
  String get soundVoiceVolume => 'Voice volume';

  @override
  String get soundBackground => 'Background sound';

  @override
  String get soundBackgroundBody => 'Plays separately from the guided voice';

  @override
  String get soundStopPreview => 'Stop preview';

  @override
  String get soundPreview => 'Preview sound';

  @override
  String get soundBackgroundVolume => 'Background volume';

  @override
  String get soundLow => 'Low';

  @override
  String get soundMedium => 'Medium';

  @override
  String get soundHigh => 'High';

  @override
  String get soundPreviewFailed => 'Sound preview could not be played.';

  @override
  String get reflectAnother => 'Another question';

  @override
  String get reflectAwful1 => 'What feels heaviest right now? Try naming it.';

  @override
  String get reflectAwful2 =>
      'If a friend were in this situation, what would you say to them?';

  @override
  String get reflectAwful3 =>
      'Is there one small thing you could do now to lighten it a little?';

  @override
  String get reflectLow1 =>
      'What happened today that took something out of you?';

  @override
  String get reflectLow2 =>
      'What is your body telling you — tired, hungry, short on sleep?';

  @override
  String get reflectLow3 =>
      'Is there anything you are expecting of yourself that could wait?';

  @override
  String get reflectNeutral1 =>
      'What small detail of today is worth remembering?';

  @override
  String get reflectNeutral2 => 'Where did most of your time go today?';

  @override
  String get reflectNeutral3 =>
      'If tomorrow were just like today, what would you change?';

  @override
  String get reflectGood1 => 'What went smoothly today?';

  @override
  String get reflectGood2 => 'Who helped make today feel easier?';

  @override
  String get reflectGood3 =>
      'Which of your habits is actually working for you?';

  @override
  String get reflectGreat1 => 'Which moment made the day?';

  @override
  String get reflectGreat2 =>
      'What would you like to keep from today for the harder days?';

  @override
  String get reflectGreat3 => 'What did you manage that surprised even you?';

  @override
  String get tagAppointment => 'Appointment';

  @override
  String get tagFamily => 'Family';

  @override
  String get tagFriends => 'Friends';

  @override
  String get tagHealth => 'Health';

  @override
  String get tagWork => 'Work';

  @override
  String get tagRest => 'Rest';

  @override
  String get tagExercise => 'Exercise';

  @override
  String get tagAlone => 'Alone';

  @override
  String get tagSession => 'Session';

  @override
  String get tagSynced => 'Synced';

  @override
  String closingStressDown(int before, int after) {
    return 'Your stress went from $before down to $after.';
  }

  @override
  String closingStressEased(int before, int after) {
    return 'Your stress eased a little, from $before to $after.';
  }

  @override
  String closingStressSame(int value) {
    return 'Your stress stayed at $value. That happens — one session does not always shift things right away.';
  }

  @override
  String get closingStressUp =>
      'You feel more tense than when you started. Thank you for being honest about that.';

  @override
  String get closingNextBodyScan =>
      'Next time, a short body scan may suit you.';

  @override
  String get closingNextGrounding =>
      'Next time, try adding the grounding part at the start and see whether it helps you settle.';

  @override
  String get closingQuestionSaved =>
      'The question you wrote down has been saved for your next appointment.';

  @override
  String get closingThanks => 'Thank you for making time for this practice.';

  @override
  String get sessionBeforeTitle => 'Before you begin';

  @override
  String get sessionAfterTitle => 'After your practice';

  @override
  String get sessionStopTitle => 'Stop the session?';

  @override
  String get sessionStopBody => 'You can come back to it any time.';

  @override
  String get sessionKeepGoing => 'Keep going';

  @override
  String get sessionStop => 'Stop';

  @override
  String get sessionSummaryQuestion => 'Question for your appointment';

  @override
  String get sessionSaveToJournal => 'Save to journal';

  @override
  String get sessionSkipSaving => 'Skip saving';

  @override
  String get sessionPrivacyNote =>
      'Either way, the research team receives the session time and your mood rating, never what you write.';

  @override
  String get sessionVideoError => 'Could not open the session video';

  @override
  String sessionCaptionSemantics(String text) {
    return 'Caption: $text';
  }

  @override
  String sessionPartSemantics(int number, int total, String title) {
    return 'Part $number of $total. $title';
  }

  @override
  String sessionPartLabel(int number, int total, String title) {
    return 'Part $number of $total · $title';
  }

  @override
  String timeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String timeSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String get sessionPause => 'Pause';

  @override
  String get sessionResume => 'Resume';

  @override
  String get sessionProgress => 'Session progress';

  @override
  String sessionProgressValue(String position, String total) {
    return '$position of $total';
  }

  @override
  String sessionBreathingGuide(String cue) {
    return 'Breathing guide: $cue';
  }

  @override
  String get journalErrorTitle => 'Could not open your journal';

  @override
  String get journalEmptyTitle => 'Nothing here yet';

  @override
  String get journalEmptyBody =>
      'Write a line about today. One sentence is enough — this is for looking back, not for writing well.';

  @override
  String get journalEmptyAction => 'Write the first line';

  @override
  String journalTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count journal entries today.',
      one: 'You have 1 journal entry today.',
    );
    return '$_temp0';
  }

  @override
  String get journalHowToday => 'How are you feeling today?';

  @override
  String journalStreak(int count) {
    return '$count days in a row';
  }

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get dayToday => 'Today';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String get insightsEmptyTitle => 'Nothing to show yet';

  @override
  String get insightsEmptyBody =>
      'Come back after a few days — a trend only means something once there is a little history.';

  @override
  String get insightsDays => 'days';

  @override
  String get insightsStreak => 'Current streak';

  @override
  String get insightsEntries => 'entries';

  @override
  String get insightsWritten => 'Written so far';

  @override
  String get insightsAverage => '30-day average';

  @override
  String get insightsTrendTitle => 'Mood over 14 days';

  @override
  String get insightsTrendBody =>
      'Tap the chart to read a single day. Days with no entry are left blank.';

  @override
  String get insightsDistributionTitle => 'Where you usually sit';

  @override
  String get insightsTagsTitle => 'Mentioned most';

  @override
  String get editorEditTitle => 'Edit entry';

  @override
  String get editorNewTitle => 'How was today?';

  @override
  String get editorDelete => 'Delete';

  @override
  String get editorNoteLabel => 'Journal note';

  @override
  String get editorNoteHint => 'Write a few lines… (you can leave this empty)';

  @override
  String get editorRelatedTo => 'Related to';

  @override
  String get editorSaveChanges => 'Save changes';

  @override
  String editorSaveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String get editorDiscardTitle => 'Discard what you wrote?';

  @override
  String get editorDiscardBody => 'Anything unsaved will be lost.';

  @override
  String get editorKeepWriting => 'Keep writing';

  @override
  String get editorDiscard => 'Discard';

  @override
  String get editorDeleteTitle => 'Delete this entry?';

  @override
  String get editorDeleteBody => 'This cannot be undone.';

  @override
  String get editorChange => 'Change';

  @override
  String get entryEdit => 'Edit';

  @override
  String get moodNotRecorded => 'Mood not recorded';

  @override
  String get entryMoodOnly =>
      'That day you only logged a mood, with nothing written.';

  @override
  String entryLastEdited(String date) {
    return 'Last edited $date';
  }

  @override
  String get entryRemoteSession => 'Session completed on another device.';

  @override
  String entryTags(String tags) {
    return 'Tags: $tags';
  }

  @override
  String get chartLabel => 'Mood trend chart';

  @override
  String get chartHint =>
      'Use left and right arrows, or adjust, to read each day.';

  @override
  String get chartNoDays => 'No recorded days';

  @override
  String chartDayValue(String date, String value) {
    return '$date, $value out of 5';
  }

  @override
  String distributionRow(String mood, int count, int percent) {
    return '$mood: $count times, $percent percent';
  }

  @override
  String get askTitle => 'Ask EmbraceAI';

  @override
  String get askIntroTitle => 'Ask about the exercises or the app';

  @override
  String get askIntroBody =>
      'Answers come only from the study materials. For anything about your health, medicines or test results, please ask your care team. Please don\'t include your name or other personal details.';

  @override
  String get askTryAsking => 'Try asking';

  @override
  String get askExampleLength => 'How long does a session take?';

  @override
  String get askExampleCaptions => 'How do I turn on captions?';

  @override
  String get askExampleJournal => 'Who can see my journal?';

  @override
  String askYouAsked(String text) {
    return 'You asked: $text';
  }

  @override
  String get askLooking => 'Looking this up…';

  @override
  String get askMedicalTitle => 'A question for your care team';

  @override
  String get askMedicalBody =>
      'This is a question for your doctor or care team. You can save it to ask at your next appointment.';

  @override
  String get askOutOfScope =>
      'I can only help with the relaxation exercises and using the app.';

  @override
  String get askNotFound =>
      'There\'s no information about this yet. You could ask the research team.';

  @override
  String get askBusy =>
      'Ask EmbraceAI is busy right now. Please try again in a moment.';

  @override
  String get askError => 'Something went wrong. Please try again.';

  @override
  String get askAlsoAsked =>
      'You also asked about something else. Please ask that part on its own.';

  @override
  String get askSaved => 'Saved to your journal';

  @override
  String get askSaveForAppointment => 'Save for my appointment';

  @override
  String get askSources => 'Sources';

  @override
  String get askAiLabel =>
      'AI-generated from study materials. Not medical advice.';

  @override
  String get askEmergencyTitle => 'If this is an emergency, get help now';

  @override
  String get askEmergencyBody =>
      'Call your local emergency number straight away. If you feel unwell but it is not an emergency, contact your care team. Stop any exercise you are doing.';

  @override
  String get askHint => 'Ask a question';

  @override
  String get askSend => 'Send';

  @override
  String askAppointmentNote(String question) {
    return 'Question for my appointment: $question';
  }

  @override
  String get authLinkExpired =>
      'This sign-in link has expired or has already been used. Sign in with your Participant ID and access key, or ask the research team for a new link.';

  @override
  String get authAccountNotActive =>
      'This account is not active for EmbraceAI.';

  @override
  String authQrSignedOutOther(String participant) {
    return 'This QR code is for $participant. A different saved account was signed out. Scan the QR code again to continue safely.';
  }

  @override
  String get authServiceUnreachable =>
      'The access service could not be reached.';

  @override
  String get authServiceUnreachableRetry =>
      'The access service could not be reached. Please try again.';

  @override
  String get authCheckDetails =>
      'Check the Participant ID and access key, then try again.';

  @override
  String authPageForOther(String participant) {
    return 'This page was opened for $participant. Use that Participant ID or open the main app address again.';
  }

  @override
  String get authInvalidDetails => 'The access details are invalid.';

  @override
  String get authParticipantInactive =>
      'This participant account is expired or inactive.';

  @override
  String authQrOtherNotOpened(String participant) {
    return 'This QR code is for $participant. The other account was not opened.';
  }

  @override
  String get authNoStaffAccess =>
      'This account does not have staff portal access.';

  @override
  String get authTooManyAttempts =>
      'Too many attempts. Wait a moment before trying again.';

  @override
  String get authSuspended => 'This account has been suspended.';

  @override
  String get authNotVerified => 'The credentials could not be verified.';

  @override
  String get authThisParticipant => 'this participant';

  @override
  String get loginIntro =>
      'Enter the access details provided by your research team.';

  @override
  String get loginIdLabel => 'Participant ID';

  @override
  String get loginIdMissing => 'Enter your Participant ID';

  @override
  String get loginKeyLabel => 'Access key';

  @override
  String get loginShowKey => 'Show access key';

  @override
  String get loginHideKey => 'Hide access key';

  @override
  String get loginKeyMissing => 'Enter your access key';

  @override
  String get loginChecking => 'Checking access...';

  @override
  String get loginPrivacy =>
      'EmbraceAI does not ask for your name, personal email, phone number, or medical record number.';

  @override
  String get gateStaffElsewhereTitle => 'The staff portal has its own address';

  @override
  String get gateStaffElsewhereBody =>
      'Staff accounts sign in at the address below.';

  @override
  String get gateStaffPortalTitle => 'This is the staff portal';

  @override
  String get gateParticipantsElsewhereBody =>
      'Participants sign in to EmbraceAI at the address below.';

  @override
  String get gateChecking => 'Checking access';

  @override
  String get studyLoadFailed =>
      'Your study information could not be loaded. Check your connection and try again.';

  @override
  String get consentAppBar => 'Study information and consent';

  @override
  String get consentTitle => 'Before you take part';

  @override
  String get consentIntro =>
      'Please read this information carefully. Taking part is voluntary, and choosing not to take part will not affect your healthcare.';

  @override
  String get consentPurposeTitle => 'Purpose';

  @override
  String get consentPurposeBody =>
      'This prototype provides an AI-guided relaxation exercise and asks about your experience so the research team can evaluate and improve it.';

  @override
  String get consentChoiceTitle => 'Your choice';

  @override
  String get consentChoiceBody =>
      'You may stop a session at any time, leave optional questions unanswered, or contact the research team member who gave you access if you wish to withdraw.';

  @override
  String get consentSafetyTitle => 'Medical safety';

  @override
  String get consentDataTitle => 'Information collected';

  @override
  String get consentDataBody =>
      'Your responses are linked to your study-issued Participant ID. The app collects the approved demographic and health form, session activity, mood ratings and study questionnaires. It does not ask for your name, personal email, phone number or medical record number.';

  @override
  String get consentConfirmEach => 'Please confirm each statement';

  @override
  String get consentRead => 'I have read and understood the information above.';

  @override
  String get consentVoluntary =>
      'I understand that taking part is voluntary and that I may stop at any time.';

  @override
  String get consentNotTreatment =>
      'I understand that this relaxation exercise is not medical treatment.';

  @override
  String get consentDataUse =>
      'I consent to the research team collecting and using the information described above for this study.';

  @override
  String get consentAccept => 'I consent and continue';

  @override
  String get consentExit => 'Exit without consenting';

  @override
  String consentVersion(String version) {
    return 'Consent record version: $version';
  }

  @override
  String get consentSaving => 'Saving your consent...';

  @override
  String get consentSaveFailed =>
      'Your consent could not be recorded. Try again.';

  @override
  String get consentStudyAccess => 'Study access';

  @override
  String get consentWithdrawnTitle => 'Consent has been withdrawn';

  @override
  String get consentWithdrawnBody =>
      'This study account cannot be used. Contact the research team member who provided your access if you believe this is incorrect.';

  @override
  String get demoAppBar => 'About you';

  @override
  String get demoQuestionAge => 'Age in years';

  @override
  String get demoQuestionGender => 'Gender';

  @override
  String get demoQuestionEthnicity => 'Ethnic background';

  @override
  String get demoQuestionCountry => 'Country of birth';

  @override
  String get demoQuestionRelationship => 'Relationship status';

  @override
  String get demoQuestionDiagnosis => 'Cardiovascular diagnosis';

  @override
  String get demoQuestionComorbidities =>
      'Other health conditions / comorbidities';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderMale => 'Male';

  @override
  String get optionPreferNotToSay => 'Prefer not to say';

  @override
  String get ethnicityAsian => 'Asian';

  @override
  String get ethnicityIndigenous => 'Indigenous';

  @override
  String get ethnicityLatinAmerican => 'Latin American';

  @override
  String get ethnicityMiddleEastern => 'Middle Eastern';

  @override
  String get ethnicityWhite => 'White';

  @override
  String get ethnicityMixed => 'Mixed / multiple backgrounds';

  @override
  String get ethnicityOther => 'Other';

  @override
  String get relationshipSingle =>
      'Single, including separated, divorced, or widowed';

  @override
  String get relationshipPartnered =>
      'In a relationship / partnered, including married';

  @override
  String get demoReviewAnswers => 'Review answers';

  @override
  String demoQuestionOf(int number, int total) {
    return 'Question $number of $total';
  }

  @override
  String get demoIntroTitle => 'Participant information';

  @override
  String get demoIntroBody =>
      'Please complete this once before beginning the program. Your record uses only your study-issued Participant ID.';

  @override
  String get demoHealthInfo => 'Health information';

  @override
  String get demoPersonalInfo => 'Personal information';

  @override
  String get demoPleaseSpecify => 'Please specify';

  @override
  String get demoOptional => 'Optional';

  @override
  String get demoOptionalNote => 'This question is optional.';

  @override
  String get demoCheckTitle => 'Check your answers';

  @override
  String get demoCheckBody => 'You can change any answer before saving.';

  @override
  String get demoNotAnswered => 'Not answered';

  @override
  String demoOtherValue(String value) {
    return 'Other: $value';
  }

  @override
  String get demoEnterAge => 'Enter age in years.';

  @override
  String get demoValidAge => 'Enter a valid age.';

  @override
  String get demoSelectOption => 'Select an option.';

  @override
  String get demoDescribeBackground => 'Please describe your background.';

  @override
  String get demoSelectCountry => 'Select a country.';

  @override
  String get demoRequired => 'This answer is required.';

  @override
  String get demoSaveFailed =>
      'Your information could not be saved. Try again.';

  @override
  String get demoCountryHint => 'Search or select a country';

  @override
  String changeSemantics(String label) {
    return 'Change $label';
  }

  @override
  String get finalAppBar => 'Final questionnaire';

  @override
  String get finalSubmit => 'Submit';

  @override
  String get finalDoLater => 'Do this later';

  @override
  String get finalSectionWellbeing => 'Emotional well-being';

  @override
  String get finalSectionExperience => 'Your experience';

  @override
  String get finalSectionOwnWords => 'In your own words';

  @override
  String get gadStem =>
      'Over the last 2 weeks, how often have you been bothered by the following problems?';

  @override
  String get gad1 => 'Feeling nervous, anxious, or on edge';

  @override
  String get gad2 => 'Difficulty controlling worrying';

  @override
  String get gad3 => 'Worrying too much about different things';

  @override
  String get gad4 => 'Difficulty relaxing';

  @override
  String get gad5 => 'Restlessness / difficulty sitting still';

  @override
  String get gad6 => 'Becoming easily annoyed or irritable';

  @override
  String get gad7 => 'Feeling afraid as if something awful might happen';

  @override
  String get gadNotAtAll => 'Not at all';

  @override
  String get gadSeveralDays => 'Several days';

  @override
  String get gadMoreThanHalf => 'More than half the days';

  @override
  String get gadNearlyEveryDay => 'Nearly every day';

  @override
  String get wellbeingQuestion =>
      'How would you rate your overall emotional well-being right now?';

  @override
  String get wellbeingVeryPoor => 'Very poor';

  @override
  String get wellbeingPoor => 'Poor';

  @override
  String get wellbeingFair => 'Fair';

  @override
  String get wellbeingGood => 'Good';

  @override
  String get wellbeingVeryGood => 'Very good';

  @override
  String get premStem => 'Please indicate how much you agree or disagree.';

  @override
  String get prem1 => 'The instructions were easy to understand.';

  @override
  String get prem2 => 'I felt comfortable using the system.';

  @override
  String get prem3 => 'The experience was calming and relaxing.';

  @override
  String get prem4 => 'The system was easy to interact with.';

  @override
  String get prem5 => 'I felt safe during the experience.';

  @override
  String get prem6 => 'The experience was helpful for my well-being.';

  @override
  String get prem7 => 'I would be willing to use this system again.';

  @override
  String get prem8 => 'Overall, I am satisfied with the experience.';

  @override
  String get premStronglyDisagree => 'Strongly disagree';

  @override
  String get premDisagree => 'Disagree';

  @override
  String get premNeutral => 'Neutral';

  @override
  String get premAgree => 'Agree';

  @override
  String get premStronglyAgree => 'Strongly agree';

  @override
  String get open1 => 'What did you like most about the experience?';

  @override
  String get open2 =>
      'What did you find difficult or uncomfortable, if anything?';

  @override
  String get open3 => 'How could the system be improved?';

  @override
  String get open4 =>
      'Would you use this system again? Please explain why or why not.';

  @override
  String get finalClearAnswer => 'Clear answer';

  @override
  String get finalOpenIntro =>
      'You may leave this blank. Please do not include your name or contact details.';

  @override
  String get finalOpenHint => 'Your answer (optional)';

  @override
  String get finalReviewTitle => 'Review and submit';

  @override
  String get finalReviewBody =>
      'Your answers will be linked only to your study-issued Participant ID. You can go back and change them before submitting.';

  @override
  String get finalReviewAnxiety => 'Anxiety questions';

  @override
  String finalAnsweredOf(int count, int total) {
    return '$count of $total answered';
  }

  @override
  String finalOutOfFive(int value) {
    return '$value of 5';
  }

  @override
  String get finalReviewExperience => 'Experience questions';

  @override
  String get finalReviewWritten => 'Written feedback';

  @override
  String get finalScreeningTotals => 'Recorded screening totals';

  @override
  String finalGadTotals(int gad2, int gad7) {
    return 'GAD-2: $gad2/6  |  GAD-7: $gad7/21';
  }

  @override
  String finalGadIncomplete(int gad2) {
    return 'GAD-2: $gad2/6  |  GAD-7 incomplete';
  }

  @override
  String get finalScreeningNote =>
      'These are screening scores, not a diagnosis.';

  @override
  String get finalSaveFailed => 'Your answers could not be saved. Try again.';
}
