import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Follow the phone's language setting.
  ///
  /// In en, this message translates to:
  /// **'Same as my phone'**
  String get languagePhone;

  /// No description provided for @languageButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageButtonTooltip;

  /// No description provided for @languageVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'The guide\'s voice, the captions and the rest of the app follow the language you choose.'**
  String get languageVoiceNote;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @homeSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get homeSignOut;

  /// Button that starts a free journal entry. The privacy text refers to it by this name.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get homeNewEntry;

  /// No description provided for @homeTabSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get homeTabSession;

  /// No description provided for @homeTabJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get homeTabJournal;

  /// No description provided for @homeTabInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get homeTabInsights;

  /// No description provided for @homeFinalReady.
  ///
  /// In en, this message translates to:
  /// **'Final questionnaire is ready'**
  String get homeFinalReady;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'A quiet moment'**
  String get welcomeTitle;

  /// No description provided for @welcomeIntro.
  ///
  /// In en, this message translates to:
  /// **'A guided relaxation for the time around appointments and test results. All you need to do is sit still and follow along.'**
  String get welcomeIntro;

  /// No description provided for @welcomeSessionSaved.
  ///
  /// In en, this message translates to:
  /// **'Session saved to your journal'**
  String get welcomeSessionSaved;

  /// Line written into the journal entry of a session.
  ///
  /// In en, this message translates to:
  /// **'Question for the team: {question}'**
  String journalLineQuestion(String question);

  /// No description provided for @journalLineStress.
  ///
  /// In en, this message translates to:
  /// **'Stress: {before} → {after}'**
  String journalLineStress(int before, int after);

  /// No description provided for @welcomeAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask EmbraceAI (preview)'**
  String get welcomeAskTitle;

  /// No description provided for @welcomeAskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questions about the exercises or the app'**
  String get welcomeAskSubtitle;

  /// No description provided for @welcomeBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get welcomeBegin;

  /// No description provided for @welcomeStopAnyTime.
  ///
  /// In en, this message translates to:
  /// **'You can stop at any time.'**
  String get welcomeStopAnyTime;

  /// No description provided for @welcomeEasierTitle.
  ///
  /// In en, this message translates to:
  /// **'Easier to see'**
  String get welcomeEasierTitle;

  /// No description provided for @welcomeEasierBody.
  ///
  /// In en, this message translates to:
  /// **'If small text is hard to read, or the picture looks hazy, turn this on.'**
  String get welcomeEasierBody;

  /// No description provided for @welcomeEasierOn.
  ///
  /// In en, this message translates to:
  /// **'Easier view is on'**
  String get welcomeEasierOn;

  /// No description provided for @welcomeEasierTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on easier view'**
  String get welcomeEasierTurnOn;

  /// No description provided for @welcomeExpectTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose 3 or 5 to 6 minutes'**
  String get welcomeExpectTimeTitle;

  /// No description provided for @welcomeExpectTimeBody.
  ///
  /// In en, this message translates to:
  /// **'A little time for yourself'**
  String get welcomeExpectTimeBody;

  /// No description provided for @welcomeExpectFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Before and after'**
  String get welcomeExpectFlowTitle;

  /// No description provided for @welcomeExpectFlowBody.
  ///
  /// In en, this message translates to:
  /// **'A check-in, uninterrupted practice, then time to reflect'**
  String get welcomeExpectFlowBody;

  /// No description provided for @welcomeExpectHeadphonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Headphones help'**
  String get welcomeExpectHeadphonesTitle;

  /// No description provided for @welcomeExpectHeadphonesBody.
  ///
  /// In en, this message translates to:
  /// **'But are not required'**
  String get welcomeExpectHeadphonesBody;

  /// No description provided for @welcomeExpectStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop any time'**
  String get welcomeExpectStopTitle;

  /// No description provided for @welcomeExpectStopBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is lost'**
  String get welcomeExpectStopBody;

  /// No description provided for @welcomeSceneTitle.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get welcomeSceneTitle;

  /// No description provided for @welcomeSceneBody.
  ///
  /// In en, this message translates to:
  /// **'Choose what you would like to look at. The practice itself is the same.'**
  String get welcomeSceneBody;

  /// No description provided for @welcomeSoundDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound and display'**
  String get welcomeSoundDisplayTitle;

  /// No description provided for @welcomeTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get welcomeTextSize;

  /// No description provided for @percentValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String percentValue(int percent);

  /// No description provided for @welcomeShowCaptions.
  ///
  /// In en, this message translates to:
  /// **'Show captions'**
  String get welcomeShowCaptions;

  /// No description provided for @welcomeShowCaptionsBody.
  ///
  /// In en, this message translates to:
  /// **'Writes out what is being said, at the size you chose'**
  String get welcomeShowCaptionsBody;

  /// No description provided for @welcomeReduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get welcomeReduceMotion;

  /// No description provided for @welcomeReduceMotionBody.
  ///
  /// In en, this message translates to:
  /// **'Removes non-essential fades and page movement'**
  String get welcomeReduceMotionBody;

  /// No description provided for @durationMinSec.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} sec'**
  String durationMinSec(int minutes, int seconds);

  /// No description provided for @welcomeDurations.
  ///
  /// In en, this message translates to:
  /// **'Short {short} · Full {full} with grounding or {breathing} with breathing'**
  String welcomeDurations(String short, String full, String breathing);

  /// No description provided for @welcomeSummaryVoiceOn.
  ///
  /// In en, this message translates to:
  /// **'Voice on'**
  String get welcomeSummaryVoiceOn;

  /// No description provided for @welcomeSummaryVoiceOff.
  ///
  /// In en, this message translates to:
  /// **'Voice off'**
  String get welcomeSummaryVoiceOff;

  /// No description provided for @welcomeSummaryText.
  ///
  /// In en, this message translates to:
  /// **'Text {percent}%'**
  String welcomeSummaryText(int percent);

  /// No description provided for @welcomeSummaryCaptionsOn.
  ///
  /// In en, this message translates to:
  /// **'Captions on'**
  String get welcomeSummaryCaptionsOn;

  /// No description provided for @welcomeSummaryCaptionsOff.
  ///
  /// In en, this message translates to:
  /// **'Captions off'**
  String get welcomeSummaryCaptionsOff;

  /// No description provided for @sceneCountryside.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese countryside'**
  String get sceneCountryside;

  /// No description provided for @sceneCountrysideDescription.
  ///
  /// In en, this message translates to:
  /// **'Sunrise courtyards, still water and a quiet village lane'**
  String get sceneCountrysideDescription;

  /// No description provided for @sceneBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach, dawn to night'**
  String get sceneBeach;

  /// No description provided for @sceneBeachDescription.
  ///
  /// In en, this message translates to:
  /// **'Open horizon, slow waves, the light changing through the day'**
  String get sceneBeachDescription;

  /// No description provided for @soundMatchVideo.
  ///
  /// In en, this message translates to:
  /// **'Match video'**
  String get soundMatchVideo;

  /// No description provided for @soundMatchVideoDescription.
  ///
  /// In en, this message translates to:
  /// **'Countryside music or ocean waves chosen with the picture'**
  String get soundMatchVideoDescription;

  /// No description provided for @soundNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get soundNone;

  /// No description provided for @soundNoneDescription.
  ///
  /// In en, this message translates to:
  /// **'Narration without a background sound'**
  String get soundNoneDescription;

  /// No description provided for @soundCountryside.
  ///
  /// In en, this message translates to:
  /// **'Countryside'**
  String get soundCountryside;

  /// No description provided for @soundCountrysideDescription.
  ///
  /// In en, this message translates to:
  /// **'Soft instrumental countryside ambience'**
  String get soundCountrysideDescription;

  /// No description provided for @soundOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean waves'**
  String get soundOcean;

  /// No description provided for @soundOceanDescription.
  ///
  /// In en, this message translates to:
  /// **'Slow waves and a light sea breeze'**
  String get soundOceanDescription;

  /// No description provided for @soundRain.
  ///
  /// In en, this message translates to:
  /// **'Gentle rain'**
  String get soundRain;

  /// No description provided for @soundRainDescription.
  ///
  /// In en, this message translates to:
  /// **'Steady rain without thunder'**
  String get soundRainDescription;

  /// No description provided for @levelQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get levelQuiet;

  /// No description provided for @levelQuietDescription.
  ///
  /// In en, this message translates to:
  /// **'Soft volume'**
  String get levelQuietDescription;

  /// No description provided for @levelNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get levelNormal;

  /// No description provided for @levelNormalDescription.
  ///
  /// In en, this message translates to:
  /// **'Comfortable volume'**
  String get levelNormalDescription;

  /// No description provided for @levelLouder.
  ///
  /// In en, this message translates to:
  /// **'Louder'**
  String get levelLouder;

  /// No description provided for @levelLouderDescription.
  ///
  /// In en, this message translates to:
  /// **'Full volume'**
  String get levelLouderDescription;

  /// No description provided for @moodAwful.
  ///
  /// In en, this message translates to:
  /// **'Really hard'**
  String get moodAwful;

  /// No description provided for @moodLow.
  ///
  /// In en, this message translates to:
  /// **'Not great'**
  String get moodLow;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get moodNeutral;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Quite good'**
  String get moodGood;

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'Really good'**
  String get moodGreat;

  /// No description provided for @feelingCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get feelingCalm;

  /// No description provided for @feelingStressed.
  ///
  /// In en, this message translates to:
  /// **'Stressed'**
  String get feelingStressed;

  /// No description provided for @feelingTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get feelingTired;

  /// No description provided for @feelingUpset.
  ///
  /// In en, this message translates to:
  /// **'Upset'**
  String get feelingUpset;

  /// No description provided for @feelingDistracted.
  ///
  /// In en, this message translates to:
  /// **'Distracted'**
  String get feelingDistracted;

  /// No description provided for @safetyYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, I can sit quietly'**
  String get safetyYes;

  /// No description provided for @safetyUnsure.
  ///
  /// In en, this message translates to:
  /// **'I\'m not sure'**
  String get safetyUnsure;

  /// No description provided for @safetyNo.
  ///
  /// In en, this message translates to:
  /// **'Not right now'**
  String get safetyNo;

  /// No description provided for @practiceGrounding.
  ///
  /// In en, this message translates to:
  /// **'Grounding'**
  String get practiceGrounding;

  /// No description provided for @practiceGroundingDescription.
  ///
  /// In en, this message translates to:
  /// **'Notice the support beneath you, then follow your breath'**
  String get practiceGroundingDescription;

  /// No description provided for @practiceBreathing.
  ///
  /// In en, this message translates to:
  /// **'Follow the breath'**
  String get practiceBreathing;

  /// No description provided for @practiceBreathingDescription.
  ///
  /// In en, this message translates to:
  /// **'Go straight to the breathing practice'**
  String get practiceBreathingDescription;

  /// No description provided for @lengthShort.
  ///
  /// In en, this message translates to:
  /// **'Short practice'**
  String get lengthShort;

  /// No description provided for @lengthShortDescription.
  ///
  /// In en, this message translates to:
  /// **'About 3 minutes'**
  String get lengthShortDescription;

  /// No description provided for @lengthFull.
  ///
  /// In en, this message translates to:
  /// **'Full practice'**
  String get lengthFull;

  /// No description provided for @lengthFullDescription.
  ///
  /// In en, this message translates to:
  /// **'About 5 to 6 minutes'**
  String get lengthFullDescription;

  /// No description provided for @breatheIn.
  ///
  /// In en, this message translates to:
  /// **'Breathe in'**
  String get breatheIn;

  /// No description provided for @breatheOut.
  ///
  /// In en, this message translates to:
  /// **'Breathe out'**
  String get breatheOut;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @promptSkipQuestion.
  ///
  /// In en, this message translates to:
  /// **'Skip this question'**
  String get promptSkipQuestion;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Medical disclaimer'**
  String get disclaimerTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Please read this before every practice.'**
  String get disclaimerSubtitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'This is not a medical intervention. If you experience any discomfort, please stop immediately and seek help from your medical team.'**
  String get disclaimerBody;

  /// No description provided for @disclaimerAccept.
  ///
  /// In en, this message translates to:
  /// **'I understand, continue'**
  String get disclaimerAccept;

  /// No description provided for @disclaimerLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave session'**
  String get disclaimerLeave;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Are you feeling comfortable enough to continue?'**
  String get safetyTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'This practice needs you somewhere safe. Please do not do it while driving or operating machinery.'**
  String get safetyBody;

  /// No description provided for @checkInFeelingTitle.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling right now?'**
  String get checkInFeelingTitle;

  /// No description provided for @checkInStressTitle.
  ///
  /// In en, this message translates to:
  /// **'How stressed do you feel right now?'**
  String get checkInStressTitle;

  /// No description provided for @checkInStressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'0 is completely at ease, 10 is the most stressed.'**
  String get checkInStressSubtitle;

  /// No description provided for @checkInSlowerTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s take this a little slower'**
  String get checkInSlowerTitle;

  /// No description provided for @checkInChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to practise?'**
  String get checkInChooseTitle;

  /// No description provided for @checkInSlowerBody.
  ///
  /// In en, this message translates to:
  /// **'You are carrying a lot right now. Grounding often settles things faster.'**
  String get checkInSlowerBody;

  /// No description provided for @checkInLengthTitle.
  ///
  /// In en, this message translates to:
  /// **'How much time would you like?'**
  String get checkInLengthTitle;

  /// No description provided for @checkInLengthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Both options end with time to reflect.'**
  String get checkInLengthSubtitle;

  /// No description provided for @questionTitle.
  ///
  /// In en, this message translates to:
  /// **'Is there one question you would like answered?'**
  String get questionTitle;

  /// No description provided for @questionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write it down here to take to your next appointment.'**
  String get questionSubtitle;

  /// No description provided for @questionLabel.
  ///
  /// In en, this message translates to:
  /// **'Question for your care team'**
  String get questionLabel;

  /// No description provided for @questionHint.
  ///
  /// In en, this message translates to:
  /// **'For example: how will this affect my daily life?'**
  String get questionHint;

  /// No description provided for @questionSave.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get questionSave;

  /// No description provided for @feedbackMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you feel now?'**
  String get feedbackMoodTitle;

  /// No description provided for @feedbackMoodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the answer that feels closest. There is no right answer.'**
  String get feedbackMoodSubtitle;

  /// No description provided for @feedbackStressTitle.
  ///
  /// In en, this message translates to:
  /// **'And where is your stress now?'**
  String get feedbackStressTitle;

  /// No description provided for @feedbackStressStarted.
  ///
  /// In en, this message translates to:
  /// **'You started at {value}.'**
  String feedbackStressStarted(int value);

  /// No description provided for @feedbackNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'What did you notice during the practice?'**
  String get feedbackNoticeTitle;

  /// No description provided for @feedbackNoticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One sentence is plenty. There is no right answer.'**
  String get feedbackNoticeSubtitle;

  /// No description provided for @feedbackNoticeLabel.
  ///
  /// In en, this message translates to:
  /// **'What you noticed'**
  String get feedbackNoticeLabel;

  /// No description provided for @feedbackNoticeHint.
  ///
  /// In en, this message translates to:
  /// **'For example: my shoulders softened, my breathing slowed towards the end.'**
  String get feedbackNoticeHint;

  /// No description provided for @stressLevel.
  ///
  /// In en, this message translates to:
  /// **'Stress level'**
  String get stressLevel;

  /// No description provided for @stressOutOfTen.
  ///
  /// In en, this message translates to:
  /// **'{value} out of 10'**
  String stressOutOfTen(int value);

  /// No description provided for @stressScaleLow.
  ///
  /// In en, this message translates to:
  /// **'0 · at ease'**
  String get stressScaleLow;

  /// No description provided for @stressScaleHigh.
  ///
  /// In en, this message translates to:
  /// **'10 · very stressed'**
  String get stressScaleHigh;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @helpClose.
  ///
  /// In en, this message translates to:
  /// **'Close help'**
  String get helpClose;

  /// No description provided for @helpBody.
  ///
  /// In en, this message translates to:
  /// **'Take your time. Find a comfortable position and let your breathing stay natural. You can leave the practice whenever you need to.'**
  String get helpBody;

  /// No description provided for @helpEasierView.
  ///
  /// In en, this message translates to:
  /// **'Easier view'**
  String get helpEasierView;

  /// No description provided for @helpBrighterPicture.
  ///
  /// In en, this message translates to:
  /// **'Brighter picture'**
  String get helpBrighterPicture;

  /// No description provided for @helpReturn.
  ///
  /// In en, this message translates to:
  /// **'Return to practice'**
  String get helpReturn;

  /// No description provided for @helpEnd.
  ///
  /// In en, this message translates to:
  /// **'End practice'**
  String get helpEnd;

  /// No description provided for @soundGuidedVoice.
  ///
  /// In en, this message translates to:
  /// **'Guided voice'**
  String get soundGuidedVoice;

  /// No description provided for @soundGuidedVoiceBody.
  ///
  /// In en, this message translates to:
  /// **'Spoken narration during the practice'**
  String get soundGuidedVoiceBody;

  /// No description provided for @soundVoiceVolume.
  ///
  /// In en, this message translates to:
  /// **'Voice volume'**
  String get soundVoiceVolume;

  /// No description provided for @soundBackground.
  ///
  /// In en, this message translates to:
  /// **'Background sound'**
  String get soundBackground;

  /// No description provided for @soundBackgroundBody.
  ///
  /// In en, this message translates to:
  /// **'Plays separately from the guided voice'**
  String get soundBackgroundBody;

  /// No description provided for @soundStopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop preview'**
  String get soundStopPreview;

  /// No description provided for @soundPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview sound'**
  String get soundPreview;

  /// No description provided for @soundBackgroundVolume.
  ///
  /// In en, this message translates to:
  /// **'Background volume'**
  String get soundBackgroundVolume;

  /// No description provided for @soundLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get soundLow;

  /// No description provided for @soundMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get soundMedium;

  /// No description provided for @soundHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get soundHigh;

  /// No description provided for @soundPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Sound preview could not be played.'**
  String get soundPreviewFailed;

  /// No description provided for @reflectAnother.
  ///
  /// In en, this message translates to:
  /// **'Another question'**
  String get reflectAnother;

  /// No description provided for @reflectAwful1.
  ///
  /// In en, this message translates to:
  /// **'What feels heaviest right now? Try naming it.'**
  String get reflectAwful1;

  /// No description provided for @reflectAwful2.
  ///
  /// In en, this message translates to:
  /// **'If a friend were in this situation, what would you say to them?'**
  String get reflectAwful2;

  /// No description provided for @reflectAwful3.
  ///
  /// In en, this message translates to:
  /// **'Is there one small thing you could do now to lighten it a little?'**
  String get reflectAwful3;

  /// No description provided for @reflectLow1.
  ///
  /// In en, this message translates to:
  /// **'What happened today that took something out of you?'**
  String get reflectLow1;

  /// No description provided for @reflectLow2.
  ///
  /// In en, this message translates to:
  /// **'What is your body telling you — tired, hungry, short on sleep?'**
  String get reflectLow2;

  /// No description provided for @reflectLow3.
  ///
  /// In en, this message translates to:
  /// **'Is there anything you are expecting of yourself that could wait?'**
  String get reflectLow3;

  /// No description provided for @reflectNeutral1.
  ///
  /// In en, this message translates to:
  /// **'What small detail of today is worth remembering?'**
  String get reflectNeutral1;

  /// No description provided for @reflectNeutral2.
  ///
  /// In en, this message translates to:
  /// **'Where did most of your time go today?'**
  String get reflectNeutral2;

  /// No description provided for @reflectNeutral3.
  ///
  /// In en, this message translates to:
  /// **'If tomorrow were just like today, what would you change?'**
  String get reflectNeutral3;

  /// No description provided for @reflectGood1.
  ///
  /// In en, this message translates to:
  /// **'What went smoothly today?'**
  String get reflectGood1;

  /// No description provided for @reflectGood2.
  ///
  /// In en, this message translates to:
  /// **'Who helped make today feel easier?'**
  String get reflectGood2;

  /// No description provided for @reflectGood3.
  ///
  /// In en, this message translates to:
  /// **'Which of your habits is actually working for you?'**
  String get reflectGood3;

  /// No description provided for @reflectGreat1.
  ///
  /// In en, this message translates to:
  /// **'Which moment made the day?'**
  String get reflectGreat1;

  /// No description provided for @reflectGreat2.
  ///
  /// In en, this message translates to:
  /// **'What would you like to keep from today for the harder days?'**
  String get reflectGreat2;

  /// No description provided for @reflectGreat3.
  ///
  /// In en, this message translates to:
  /// **'What did you manage that surprised even you?'**
  String get reflectGreat3;

  /// No description provided for @tagAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get tagAppointment;

  /// No description provided for @tagFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get tagFamily;

  /// No description provided for @tagFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get tagFriends;

  /// No description provided for @tagHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get tagHealth;

  /// No description provided for @tagWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get tagWork;

  /// No description provided for @tagRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get tagRest;

  /// No description provided for @tagExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get tagExercise;

  /// No description provided for @tagAlone.
  ///
  /// In en, this message translates to:
  /// **'Alone'**
  String get tagAlone;

  /// No description provided for @tagSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get tagSession;

  /// No description provided for @tagSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get tagSynced;

  /// No description provided for @closingStressDown.
  ///
  /// In en, this message translates to:
  /// **'Your stress went from {before} down to {after}.'**
  String closingStressDown(int before, int after);

  /// No description provided for @closingStressEased.
  ///
  /// In en, this message translates to:
  /// **'Your stress eased a little, from {before} to {after}.'**
  String closingStressEased(int before, int after);

  /// No description provided for @closingStressSame.
  ///
  /// In en, this message translates to:
  /// **'Your stress stayed at {value}. That happens — one session does not always shift things right away.'**
  String closingStressSame(int value);

  /// No description provided for @closingStressUp.
  ///
  /// In en, this message translates to:
  /// **'You feel more tense than when you started. Thank you for being honest about that.'**
  String get closingStressUp;

  /// No description provided for @closingNextBodyScan.
  ///
  /// In en, this message translates to:
  /// **'Next time, a short body scan may suit you.'**
  String get closingNextBodyScan;

  /// No description provided for @closingNextGrounding.
  ///
  /// In en, this message translates to:
  /// **'Next time, try adding the grounding part at the start and see whether it helps you settle.'**
  String get closingNextGrounding;

  /// No description provided for @closingQuestionSaved.
  ///
  /// In en, this message translates to:
  /// **'The question you wrote down has been saved for your next appointment.'**
  String get closingQuestionSaved;

  /// No description provided for @closingThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for making time for this practice.'**
  String get closingThanks;

  /// No description provided for @sessionBeforeTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you begin'**
  String get sessionBeforeTitle;

  /// No description provided for @sessionAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'After your practice'**
  String get sessionAfterTitle;

  /// No description provided for @sessionStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop the session?'**
  String get sessionStopTitle;

  /// No description provided for @sessionStopBody.
  ///
  /// In en, this message translates to:
  /// **'You can come back to it any time.'**
  String get sessionStopBody;

  /// No description provided for @sessionKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get sessionKeepGoing;

  /// No description provided for @sessionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get sessionStop;

  /// No description provided for @sessionSummaryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question for your appointment'**
  String get sessionSummaryQuestion;

  /// No description provided for @sessionSaveToJournal.
  ///
  /// In en, this message translates to:
  /// **'Save to journal'**
  String get sessionSaveToJournal;

  /// No description provided for @sessionSkipSaving.
  ///
  /// In en, this message translates to:
  /// **'Skip saving'**
  String get sessionSkipSaving;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Either way, the research team receives the session time and your mood rating, never what you write.'**
  String get sessionPrivacyNote;

  /// No description provided for @sessionVideoError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the session video'**
  String get sessionVideoError;

  /// No description provided for @sessionCaptionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Caption: {text}'**
  String sessionCaptionSemantics(String text);

  /// No description provided for @sessionPartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Part {number} of {total}. {title}'**
  String sessionPartSemantics(int number, int total, String title);

  /// No description provided for @sessionPartLabel.
  ///
  /// In en, this message translates to:
  /// **'Part {number} of {total} · {title}'**
  String sessionPartLabel(int number, int total, String title);

  /// No description provided for @timeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String timeMinutes(int count);

  /// No description provided for @timeSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second} other{{count} seconds}}'**
  String timeSeconds(int count);

  /// No description provided for @sessionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get sessionPause;

  /// No description provided for @sessionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get sessionResume;

  /// No description provided for @sessionProgress.
  ///
  /// In en, this message translates to:
  /// **'Session progress'**
  String get sessionProgress;

  /// No description provided for @sessionProgressValue.
  ///
  /// In en, this message translates to:
  /// **'{position} of {total}'**
  String sessionProgressValue(String position, String total);

  /// No description provided for @sessionBreathingGuide.
  ///
  /// In en, this message translates to:
  /// **'Breathing guide: {cue}'**
  String sessionBreathingGuide(String cue);

  /// No description provided for @journalErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not open your journal'**
  String get journalErrorTitle;

  /// No description provided for @journalEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get journalEmptyTitle;

  /// No description provided for @journalEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Write a line about today. One sentence is enough — this is for looking back, not for writing well.'**
  String get journalEmptyBody;

  /// No description provided for @journalEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Write the first line'**
  String get journalEmptyAction;

  /// No description provided for @journalTodayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have 1 journal entry today.} other{You have {count} journal entries today.}}'**
  String journalTodayCount(int count);

  /// No description provided for @journalHowToday.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get journalHowToday;

  /// No description provided for @journalStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} days in a row'**
  String journalStreak(int count);

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayYesterday;

  /// No description provided for @insightsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get insightsEmptyTitle;

  /// No description provided for @insightsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Come back after a few days — a trend only means something once there is a little history.'**
  String get insightsEmptyBody;

  /// No description provided for @insightsDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get insightsDays;

  /// No description provided for @insightsStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get insightsStreak;

  /// No description provided for @insightsEntries.
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get insightsEntries;

  /// No description provided for @insightsWritten.
  ///
  /// In en, this message translates to:
  /// **'Written so far'**
  String get insightsWritten;

  /// No description provided for @insightsAverage.
  ///
  /// In en, this message translates to:
  /// **'30-day average'**
  String get insightsAverage;

  /// No description provided for @insightsTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood over 14 days'**
  String get insightsTrendTitle;

  /// No description provided for @insightsTrendBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the chart to read a single day. Days with no entry are left blank.'**
  String get insightsTrendBody;

  /// No description provided for @insightsDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Where you usually sit'**
  String get insightsDistributionTitle;

  /// No description provided for @insightsTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mentioned most'**
  String get insightsTagsTitle;

  /// No description provided for @editorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editorEditTitle;

  /// No description provided for @editorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'How was today?'**
  String get editorNewTitle;

  /// No description provided for @editorDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get editorDelete;

  /// No description provided for @editorNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Journal note'**
  String get editorNoteLabel;

  /// No description provided for @editorNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Write a few lines… (you can leave this empty)'**
  String get editorNoteHint;

  /// No description provided for @editorRelatedTo.
  ///
  /// In en, this message translates to:
  /// **'Related to'**
  String get editorRelatedTo;

  /// No description provided for @editorSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editorSaveChanges;

  /// No description provided for @editorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String editorSaveFailed(String error);

  /// No description provided for @editorDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard what you wrote?'**
  String get editorDiscardTitle;

  /// No description provided for @editorDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Anything unsaved will be lost.'**
  String get editorDiscardBody;

  /// No description provided for @editorKeepWriting.
  ///
  /// In en, this message translates to:
  /// **'Keep writing'**
  String get editorKeepWriting;

  /// No description provided for @editorDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editorDiscard;

  /// No description provided for @editorDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get editorDeleteTitle;

  /// No description provided for @editorDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get editorDeleteBody;

  /// No description provided for @editorChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get editorChange;

  /// No description provided for @entryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get entryEdit;

  /// No description provided for @moodNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Mood not recorded'**
  String get moodNotRecorded;

  /// No description provided for @entryMoodOnly.
  ///
  /// In en, this message translates to:
  /// **'That day you only logged a mood, with nothing written.'**
  String get entryMoodOnly;

  /// No description provided for @entryLastEdited.
  ///
  /// In en, this message translates to:
  /// **'Last edited {date}'**
  String entryLastEdited(String date);

  /// No description provided for @entryRemoteSession.
  ///
  /// In en, this message translates to:
  /// **'Session completed on another device.'**
  String get entryRemoteSession;

  /// No description provided for @entryTags.
  ///
  /// In en, this message translates to:
  /// **'Tags: {tags}'**
  String entryTags(String tags);

  /// No description provided for @chartLabel.
  ///
  /// In en, this message translates to:
  /// **'Mood trend chart'**
  String get chartLabel;

  /// No description provided for @chartHint.
  ///
  /// In en, this message translates to:
  /// **'Use left and right arrows, or adjust, to read each day.'**
  String get chartHint;

  /// No description provided for @chartNoDays.
  ///
  /// In en, this message translates to:
  /// **'No recorded days'**
  String get chartNoDays;

  /// No description provided for @chartDayValue.
  ///
  /// In en, this message translates to:
  /// **'{date}, {value} out of 5'**
  String chartDayValue(String date, String value);

  /// No description provided for @distributionRow.
  ///
  /// In en, this message translates to:
  /// **'{mood}: {count} times, {percent} percent'**
  String distributionRow(String mood, int count, int percent);

  /// No description provided for @askTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask EmbraceAI'**
  String get askTitle;

  /// No description provided for @askIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about the exercises or the app'**
  String get askIntroTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Answers come only from the study materials. For anything about your health, medicines or test results, please ask your care team. Please don\'t include your name or other personal details.'**
  String get askIntroBody;

  /// No description provided for @askTryAsking.
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get askTryAsking;

  /// Example question chip; tapping it sends the question as written.
  ///
  /// In en, this message translates to:
  /// **'How long does a session take?'**
  String get askExampleLength;

  /// No description provided for @askExampleCaptions.
  ///
  /// In en, this message translates to:
  /// **'How do I turn on captions?'**
  String get askExampleCaptions;

  /// No description provided for @askExampleJournal.
  ///
  /// In en, this message translates to:
  /// **'Who can see my journal?'**
  String get askExampleJournal;

  /// No description provided for @askYouAsked.
  ///
  /// In en, this message translates to:
  /// **'You asked: {text}'**
  String askYouAsked(String text);

  /// No description provided for @askLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking this up…'**
  String get askLooking;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'A question for your care team'**
  String get askMedicalTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'This is a question for your doctor or care team. You can save it to ask at your next appointment.'**
  String get askMedicalBody;

  /// No description provided for @askOutOfScope.
  ///
  /// In en, this message translates to:
  /// **'I can only help with the relaxation exercises and using the app.'**
  String get askOutOfScope;

  /// No description provided for @askNotFound.
  ///
  /// In en, this message translates to:
  /// **'There\'s no information about this yet. You could ask the research team.'**
  String get askNotFound;

  /// No description provided for @askBusy.
  ///
  /// In en, this message translates to:
  /// **'Ask EmbraceAI is busy right now. Please try again in a moment.'**
  String get askBusy;

  /// No description provided for @askError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get askError;

  /// No description provided for @askAlsoAsked.
  ///
  /// In en, this message translates to:
  /// **'You also asked about something else. Please ask that part on its own.'**
  String get askAlsoAsked;

  /// No description provided for @askSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your journal'**
  String get askSaved;

  /// No description provided for @askSaveForAppointment.
  ///
  /// In en, this message translates to:
  /// **'Save for my appointment'**
  String get askSaveForAppointment;

  /// No description provided for @askSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get askSources;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'AI-generated from study materials. Not medical advice.'**
  String get askAiLabel;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'If this is an emergency, get help now'**
  String get askEmergencyTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Call your local emergency number straight away. If you feel unwell but it is not an emergency, contact your care team. Stop any exercise you are doing.'**
  String get askEmergencyBody;

  /// No description provided for @askHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get askHint;

  /// No description provided for @askSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get askSend;

  /// Journal note saved from a medical question in Ask EmbraceAI.
  ///
  /// In en, this message translates to:
  /// **'Question for my appointment: {question}'**
  String askAppointmentNote(String question);

  /// No description provided for @authLinkExpired.
  ///
  /// In en, this message translates to:
  /// **'This sign-in link has expired or has already been used. Sign in with your Participant ID and access key, or ask the research team for a new link.'**
  String get authLinkExpired;

  /// No description provided for @authAccountNotActive.
  ///
  /// In en, this message translates to:
  /// **'This account is not active for EmbraceAI.'**
  String get authAccountNotActive;

  /// No description provided for @authQrSignedOutOther.
  ///
  /// In en, this message translates to:
  /// **'This QR code is for {participant}. A different saved account was signed out. Scan the QR code again to continue safely.'**
  String authQrSignedOutOther(String participant);

  /// No description provided for @authServiceUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The access service could not be reached.'**
  String get authServiceUnreachable;

  /// No description provided for @authServiceUnreachableRetry.
  ///
  /// In en, this message translates to:
  /// **'The access service could not be reached. Please try again.'**
  String get authServiceUnreachableRetry;

  /// No description provided for @authCheckDetails.
  ///
  /// In en, this message translates to:
  /// **'Check the Participant ID and access key, then try again.'**
  String get authCheckDetails;

  /// No description provided for @authPageForOther.
  ///
  /// In en, this message translates to:
  /// **'This page was opened for {participant}. Use that Participant ID or open the main app address again.'**
  String authPageForOther(String participant);

  /// No description provided for @authInvalidDetails.
  ///
  /// In en, this message translates to:
  /// **'The access details are invalid.'**
  String get authInvalidDetails;

  /// No description provided for @authParticipantInactive.
  ///
  /// In en, this message translates to:
  /// **'This participant account is expired or inactive.'**
  String get authParticipantInactive;

  /// No description provided for @authQrOtherNotOpened.
  ///
  /// In en, this message translates to:
  /// **'This QR code is for {participant}. The other account was not opened.'**
  String authQrOtherNotOpened(String participant);

  /// No description provided for @authNoStaffAccess.
  ///
  /// In en, this message translates to:
  /// **'This account does not have staff portal access.'**
  String get authNoStaffAccess;

  /// No description provided for @authTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment before trying again.'**
  String get authTooManyAttempts;

  /// No description provided for @authSuspended.
  ///
  /// In en, this message translates to:
  /// **'This account has been suspended.'**
  String get authSuspended;

  /// No description provided for @authNotVerified.
  ///
  /// In en, this message translates to:
  /// **'The credentials could not be verified.'**
  String get authNotVerified;

  /// No description provided for @authThisParticipant.
  ///
  /// In en, this message translates to:
  /// **'this participant'**
  String get authThisParticipant;

  /// No description provided for @loginIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter the access details provided by your research team.'**
  String get loginIntro;

  /// No description provided for @loginIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Participant ID'**
  String get loginIdLabel;

  /// No description provided for @loginIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter your Participant ID'**
  String get loginIdMissing;

  /// No description provided for @loginKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Access key'**
  String get loginKeyLabel;

  /// No description provided for @loginShowKey.
  ///
  /// In en, this message translates to:
  /// **'Show access key'**
  String get loginShowKey;

  /// No description provided for @loginHideKey.
  ///
  /// In en, this message translates to:
  /// **'Hide access key'**
  String get loginHideKey;

  /// No description provided for @loginKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter your access key'**
  String get loginKeyMissing;

  /// No description provided for @loginChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking access...'**
  String get loginChecking;

  /// No description provided for @loginPrivacy.
  ///
  /// In en, this message translates to:
  /// **'EmbraceAI does not ask for your name, personal email, phone number, or medical record number.'**
  String get loginPrivacy;

  /// No description provided for @gateStaffElsewhereTitle.
  ///
  /// In en, this message translates to:
  /// **'The staff portal has its own address'**
  String get gateStaffElsewhereTitle;

  /// No description provided for @gateStaffElsewhereBody.
  ///
  /// In en, this message translates to:
  /// **'Staff accounts sign in at the address below.'**
  String get gateStaffElsewhereBody;

  /// No description provided for @gateStaffPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'This is the staff portal'**
  String get gateStaffPortalTitle;

  /// No description provided for @gateParticipantsElsewhereBody.
  ///
  /// In en, this message translates to:
  /// **'Participants sign in to EmbraceAI at the address below.'**
  String get gateParticipantsElsewhereBody;

  /// No description provided for @gateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking access'**
  String get gateChecking;

  /// No description provided for @studyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your study information could not be loaded. Check your connection and try again.'**
  String get studyLoadFailed;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Study information and consent'**
  String get consentAppBar;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Before you take part'**
  String get consentTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Please read this information carefully. Taking part is voluntary, and choosing not to take part will not affect your healthcare.'**
  String get consentIntro;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get consentPurposeTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'This prototype provides an AI-guided relaxation exercise and asks about your experience so the research team can evaluate and improve it.'**
  String get consentPurposeBody;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Your choice'**
  String get consentChoiceTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'You may stop a session at any time, leave optional questions unanswered, or contact the research team member who gave you access if you wish to withdraw.'**
  String get consentChoiceBody;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Medical safety'**
  String get consentSafetyTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Information collected'**
  String get consentDataTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Your responses are linked to your study-issued Participant ID. The app collects the approved demographic and health form, session activity, mood ratings and study questionnaires. It does not ask for your name, personal email, phone number or medical record number.'**
  String get consentDataBody;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Please confirm each statement'**
  String get consentConfirmEach;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'I have read and understood the information above.'**
  String get consentRead;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'I understand that taking part is voluntary and that I may stop at any time.'**
  String get consentVoluntary;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'I understand that this relaxation exercise is not medical treatment.'**
  String get consentNotTreatment;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'I consent to the research team collecting and using the information described above for this study.'**
  String get consentDataUse;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'I consent and continue'**
  String get consentAccept;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Exit without consenting'**
  String get consentExit;

  /// No description provided for @consentVersion.
  ///
  /// In en, this message translates to:
  /// **'Consent record version: {version}'**
  String consentVersion(String version);

  /// No description provided for @consentSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving your consent...'**
  String get consentSaving;

  /// No description provided for @consentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your consent could not be recorded. Try again.'**
  String get consentSaveFailed;

  /// No description provided for @consentStudyAccess.
  ///
  /// In en, this message translates to:
  /// **'Study access'**
  String get consentStudyAccess;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Consent has been withdrawn'**
  String get consentWithdrawnTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'This study account cannot be used. Contact the research team member who provided your access if you believe this is incorrect.'**
  String get consentWithdrawnBody;

  /// No description provided for @demoAppBar.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get demoAppBar;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Age in years'**
  String get demoQuestionAge;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get demoQuestionGender;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Ethnic background'**
  String get demoQuestionEthnicity;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Country of birth'**
  String get demoQuestionCountry;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Relationship status'**
  String get demoQuestionRelationship;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Cardiovascular diagnosis'**
  String get demoQuestionDiagnosis;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Other health conditions / comorbidities'**
  String get demoQuestionComorbidities;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get optionPreferNotToSay;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Asian'**
  String get ethnicityAsian;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Indigenous'**
  String get ethnicityIndigenous;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Latin American'**
  String get ethnicityLatinAmerican;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Middle Eastern'**
  String get ethnicityMiddleEastern;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get ethnicityWhite;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Mixed / multiple backgrounds'**
  String get ethnicityMixed;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get ethnicityOther;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Single, including separated, divorced, or widowed'**
  String get relationshipSingle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'In a relationship / partnered, including married'**
  String get relationshipPartnered;

  /// No description provided for @demoReviewAnswers.
  ///
  /// In en, this message translates to:
  /// **'Review answers'**
  String get demoReviewAnswers;

  /// No description provided for @demoQuestionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {number} of {total}'**
  String demoQuestionOf(int number, int total);

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Participant information'**
  String get demoIntroTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Please complete this once before beginning the program. Your record uses only your study-issued Participant ID.'**
  String get demoIntroBody;

  /// No description provided for @demoHealthInfo.
  ///
  /// In en, this message translates to:
  /// **'Health information'**
  String get demoHealthInfo;

  /// No description provided for @demoPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get demoPersonalInfo;

  /// No description provided for @demoPleaseSpecify.
  ///
  /// In en, this message translates to:
  /// **'Please specify'**
  String get demoPleaseSpecify;

  /// No description provided for @demoOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get demoOptional;

  /// No description provided for @demoOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'This question is optional.'**
  String get demoOptionalNote;

  /// No description provided for @demoCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your answers'**
  String get demoCheckTitle;

  /// No description provided for @demoCheckBody.
  ///
  /// In en, this message translates to:
  /// **'You can change any answer before saving.'**
  String get demoCheckBody;

  /// No description provided for @demoNotAnswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get demoNotAnswered;

  /// No description provided for @demoOtherValue.
  ///
  /// In en, this message translates to:
  /// **'Other: {value}'**
  String demoOtherValue(String value);

  /// No description provided for @demoEnterAge.
  ///
  /// In en, this message translates to:
  /// **'Enter age in years.'**
  String get demoEnterAge;

  /// No description provided for @demoValidAge.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid age.'**
  String get demoValidAge;

  /// No description provided for @demoSelectOption.
  ///
  /// In en, this message translates to:
  /// **'Select an option.'**
  String get demoSelectOption;

  /// No description provided for @demoDescribeBackground.
  ///
  /// In en, this message translates to:
  /// **'Please describe your background.'**
  String get demoDescribeBackground;

  /// No description provided for @demoSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select a country.'**
  String get demoSelectCountry;

  /// No description provided for @demoRequired.
  ///
  /// In en, this message translates to:
  /// **'This answer is required.'**
  String get demoRequired;

  /// No description provided for @demoSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your information could not be saved. Try again.'**
  String get demoSaveFailed;

  /// No description provided for @demoCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Search or select a country'**
  String get demoCountryHint;

  /// No description provided for @changeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Change {label}'**
  String changeSemantics(String label);

  /// No description provided for @finalAppBar.
  ///
  /// In en, this message translates to:
  /// **'Final questionnaire'**
  String get finalAppBar;

  /// No description provided for @finalSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get finalSubmit;

  /// No description provided for @finalDoLater.
  ///
  /// In en, this message translates to:
  /// **'Do this later'**
  String get finalDoLater;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Emotional well-being'**
  String get finalSectionWellbeing;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Your experience'**
  String get finalSectionExperience;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'In your own words'**
  String get finalSectionOwnWords;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants. GAD-7 instruction. Replace the Vietnamese with the validated Vietnamese GAD-7 wording.
  ///
  /// In en, this message translates to:
  /// **'Over the last 2 weeks, how often have you been bothered by the following problems?'**
  String get gadStem;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants. GAD-7 item. Use the validated Vietnamese wording.
  ///
  /// In en, this message translates to:
  /// **'Feeling nervous, anxious, or on edge'**
  String get gad1;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants. GAD-7 item. Use the validated Vietnamese wording.
  ///
  /// In en, this message translates to:
  /// **'Difficulty controlling worrying'**
  String get gad2;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants. GAD-7 item. Use the validated Vietnamese wording.
  ///
  /// In en, this message translates to:
  /// **'Worrying too much about different things'**
  String get gad3;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants. GAD-7 item. Use the validated Vietnamese wording.
  ///
  /// In en, this message translates to:
  /// **'Difficulty relaxing'**
  String get gad4;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants. GAD-7 item. Use the validated Vietnamese wording.
  ///
  /// In en, this message translates to:
  /// **'Restlessness / difficulty sitting still'**
  String get gad5;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants. GAD-7 item. Use the validated Vietnamese wording.
  ///
  /// In en, this message translates to:
  /// **'Becoming easily annoyed or irritable'**
  String get gad6;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants. GAD-7 item. Use the validated Vietnamese wording.
  ///
  /// In en, this message translates to:
  /// **'Feeling afraid as if something awful might happen'**
  String get gad7;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Not at all'**
  String get gadNotAtAll;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Several days'**
  String get gadSeveralDays;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'More than half the days'**
  String get gadMoreThanHalf;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Nearly every day'**
  String get gadNearlyEveryDay;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'How would you rate your overall emotional well-being right now?'**
  String get wellbeingQuestion;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Very poor'**
  String get wellbeingVeryPoor;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get wellbeingPoor;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get wellbeingFair;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get wellbeingGood;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get wellbeingVeryGood;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Please indicate how much you agree or disagree.'**
  String get premStem;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'The instructions were easy to understand.'**
  String get prem1;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'I felt comfortable using the system.'**
  String get prem2;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'The experience was calming and relaxing.'**
  String get prem3;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'The system was easy to interact with.'**
  String get prem4;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'I felt safe during the experience.'**
  String get prem5;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'The experience was helpful for my well-being.'**
  String get prem6;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'I would be willing to use this system again.'**
  String get prem7;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Overall, I am satisfied with the experience.'**
  String get prem8;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Strongly disagree'**
  String get premStronglyDisagree;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Disagree'**
  String get premDisagree;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get premNeutral;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get premAgree;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Strongly agree'**
  String get premStronglyAgree;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'What did you like most about the experience?'**
  String get open1;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'What did you find difficult or uncomfortable, if anything?'**
  String get open2;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'How could the system be improved?'**
  String get open3;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Would you use this system again? Please explain why or why not.'**
  String get open4;

  /// No description provided for @finalClearAnswer.
  ///
  /// In en, this message translates to:
  /// **'Clear answer'**
  String get finalClearAnswer;

  /// No description provided for @finalOpenIntro.
  ///
  /// In en, this message translates to:
  /// **'You may leave this blank. Please do not include your name or contact details.'**
  String get finalOpenIntro;

  /// No description provided for @finalOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Your answer (optional)'**
  String get finalOpenHint;

  /// No description provided for @finalReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review and submit'**
  String get finalReviewTitle;

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'Your answers will be linked only to your study-issued Participant ID. You can go back and change them before submitting.'**
  String get finalReviewBody;

  /// No description provided for @finalReviewAnxiety.
  ///
  /// In en, this message translates to:
  /// **'Anxiety questions'**
  String get finalReviewAnxiety;

  /// No description provided for @finalAnsweredOf.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} answered'**
  String finalAnsweredOf(int count, int total);

  /// No description provided for @finalOutOfFive.
  ///
  /// In en, this message translates to:
  /// **'{value} of 5'**
  String finalOutOfFive(int value);

  /// No description provided for @finalReviewExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience questions'**
  String get finalReviewExperience;

  /// No description provided for @finalReviewWritten.
  ///
  /// In en, this message translates to:
  /// **'Written feedback'**
  String get finalReviewWritten;

  /// No description provided for @finalScreeningTotals.
  ///
  /// In en, this message translates to:
  /// **'Recorded screening totals'**
  String get finalScreeningTotals;

  /// No description provided for @finalGadTotals.
  ///
  /// In en, this message translates to:
  /// **'GAD-2: {gad2}/6  |  GAD-7: {gad7}/21'**
  String finalGadTotals(int gad2, int gad7);

  /// No description provided for @finalGadIncomplete.
  ///
  /// In en, this message translates to:
  /// **'GAD-2: {gad2}/6  |  GAD-7 incomplete'**
  String finalGadIncomplete(int gad2);

  /// RESEARCH TEXT: the Vietnamese is a draft that the study team must approve before use with participants.
  ///
  /// In en, this message translates to:
  /// **'These are screening scores, not a diagnosis.'**
  String get finalScreeningNote;

  /// No description provided for @finalSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your answers could not be saved. Try again.'**
  String get finalSaveFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
