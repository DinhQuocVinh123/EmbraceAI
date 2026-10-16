import '../models/breathing_cue.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../models/session_answers.dart';
import '../models/session_audio.dart';
import '../models/session_scene.dart';
import '../state/auth_store.dart';
import '../state/settings_store.dart';
import 'app_localizations.dart';

// Nhãn hiển thị của các giá trị trong mô hình dữ liệu. Giá trị lưu xuống vẫn
// là mã (điểm, tên enum), không phụ thuộc ngôn ngữ; chỉ chữ hiện ra mới dịch.

extension MoodText on Mood {
  String label(AppLocalizations l) => switch (this) {
    Mood.awful => l.moodAwful,
    Mood.low => l.moodLow,
    Mood.neutral => l.moodNeutral,
    Mood.good => l.moodGood,
    Mood.great => l.moodGreat,
  };
}

extension CheckInFeelingText on CheckInFeeling {
  String label(AppLocalizations l) => switch (this) {
    CheckInFeeling.calm => l.feelingCalm,
    CheckInFeeling.stressed => l.feelingStressed,
    CheckInFeeling.tired => l.feelingTired,
    CheckInFeeling.upset => l.feelingUpset,
    CheckInFeeling.distracted => l.feelingDistracted,
  };

  /// Câu hỏi đo mức độ của cảm xúc này, trước buổi tập.
  String scaleTitle(AppLocalizations l) => switch (this) {
    CheckInFeeling.calm => l.checkInCalmScaleTitle,
    CheckInFeeling.stressed => l.checkInStressedScaleTitle,
    CheckInFeeling.tired => l.checkInTiredScaleTitle,
    CheckInFeeling.upset => l.checkInUpsetScaleTitle,
    CheckInFeeling.distracted => l.checkInDistractedScaleTitle,
  };

  String scaleLow(AppLocalizations l) => switch (this) {
    CheckInFeeling.calm => l.checkInCalmScaleLow,
    CheckInFeeling.stressed => l.checkInStressedScaleLow,
    CheckInFeeling.tired => l.checkInTiredScaleLow,
    CheckInFeeling.upset => l.checkInUpsetScaleLow,
    CheckInFeeling.distracted => l.checkInDistractedScaleLow,
  };

  String scaleHigh(AppLocalizations l) => switch (this) {
    CheckInFeeling.calm => l.checkInCalmScaleHigh,
    CheckInFeeling.stressed => l.checkInStressedScaleHigh,
    CheckInFeeling.tired => l.checkInTiredScaleHigh,
    CheckInFeeling.upset => l.checkInUpsetScaleHigh,
    CheckInFeeling.distracted => l.checkInDistractedScaleHigh,
  };

  /// Câu hỏi lại cùng thang đó sau buổi tập.
  String afterTitle(AppLocalizations l) => switch (this) {
    CheckInFeeling.calm => l.checkInCalmAfterTitle,
    CheckInFeeling.stressed => l.checkInStressedAfterTitle,
    CheckInFeeling.tired => l.checkInTiredAfterTitle,
    CheckInFeeling.upset => l.checkInUpsetAfterTitle,
    CheckInFeeling.distracted => l.checkInDistractedAfterTitle,
  };

  /// Tên ngắn của thang, viết hoa đầu câu: dòng nhật ký "Căng thẳng: 8 → 4".
  String scaleName(AppLocalizations l) => switch (this) {
    CheckInFeeling.calm => l.checkInCalmName,
    CheckInFeeling.stressed => l.checkInStressedName,
    CheckInFeeling.tired => l.checkInTiredName,
    CheckInFeeling.upset => l.checkInUpsetName,
    CheckInFeeling.distracted => l.checkInDistractedName,
  };

  /// Tên thang giữa câu: "Your {measure} went from 8 to 4."
  String measure(AppLocalizations l) => switch (this) {
    CheckInFeeling.calm => l.checkInCalmMeasure,
    CheckInFeeling.stressed => l.checkInStressedMeasure,
    CheckInFeeling.tired => l.checkInTiredMeasure,
    CheckInFeeling.upset => l.checkInUpsetMeasure,
    CheckInFeeling.distracted => l.checkInDistractedMeasure,
  };

  /// Lời đi kèm bài gợi ý khi cảm xúc mạnh; null khi nhánh không gợi ý.
  String? strongTitle(AppLocalizations l) => switch (this) {
    CheckInFeeling.calm => null,
    CheckInFeeling.tired => l.checkInGentleTitle,
    _ => l.checkInSlowerTitle,
  };

  String? strongBody(AppLocalizations l) => switch (this) {
    CheckInFeeling.calm => null,
    CheckInFeeling.stressed => l.checkInStressedStrongBody,
    CheckInFeeling.tired => l.checkInTiredStrongBody,
    CheckInFeeling.upset => l.checkInUpsetStrongBody,
    CheckInFeeling.distracted => l.checkInDistractedStrongBody,
  };
}

extension SessionSceneText on SessionScene {
  String label(AppLocalizations l) => switch (this) {
    SessionScene.countryside => l.sceneCountryside,
    SessionScene.beach => l.sceneBeach,
  };

  String description(AppLocalizations l) => switch (this) {
    SessionScene.countryside => l.sceneCountrysideDescription,
    SessionScene.beach => l.sceneBeachDescription,
  };
}

extension BackgroundSoundText on BackgroundSound {
  String label(AppLocalizations l) => switch (this) {
    BackgroundSound.matchScene => l.soundMatchVideo,
    BackgroundSound.none => l.soundNone,
    BackgroundSound.countryside => l.soundCountryside,
    BackgroundSound.ocean => l.soundOcean,
    BackgroundSound.rain => l.soundRain,
  };

  String description(AppLocalizations l) => switch (this) {
    BackgroundSound.matchScene => l.soundMatchVideoDescription,
    BackgroundSound.none => l.soundNoneDescription,
    BackgroundSound.countryside => l.soundCountrysideDescription,
    BackgroundSound.ocean => l.soundOceanDescription,
    BackgroundSound.rain => l.soundRainDescription,
  };
}

extension SoundLevelText on SoundLevel {
  String label(AppLocalizations l) => switch (this) {
    SoundLevel.quiet => l.levelQuiet,
    SoundLevel.normal => l.levelNormal,
    SoundLevel.louder => l.levelLouder,
  };

  String description(AppLocalizations l) => switch (this) {
    SoundLevel.quiet => l.levelQuietDescription,
    SoundLevel.normal => l.levelNormalDescription,
    SoundLevel.louder => l.levelLouderDescription,
  };
}

extension SafetyAnswerText on SafetyAnswer {
  String label(AppLocalizations l) => switch (this) {
    SafetyAnswer.yes => l.safetyYes,
    SafetyAnswer.unsure => l.safetyUnsure,
    SafetyAnswer.no => l.safetyNo,
  };
}

extension PracticeChoiceText on PracticeChoice {
  String label(AppLocalizations l) => switch (this) {
    PracticeChoice.grounding => l.practiceGrounding,
    PracticeChoice.breathing => l.practiceBreathing,
  };

  String description(AppLocalizations l) => switch (this) {
    PracticeChoice.grounding => l.practiceGroundingDescription,
    PracticeChoice.breathing => l.practiceBreathingDescription,
  };
}

extension PracticeLengthText on PracticeLength {
  String label(AppLocalizations l) => switch (this) {
    PracticeLength.short => l.lengthShort,
    PracticeLength.full => l.lengthFull,
  };

  String description(AppLocalizations l) => switch (this) {
    PracticeLength.short => l.lengthShortDescription,
    PracticeLength.full => l.lengthFullDescription,
  };
}

extension BreathingCueText on BreathingCue {
  String label(AppLocalizations l) => switch (phase) {
    BreathingPhase.inhale => l.breatheIn,
    BreathingPhase.exhale => l.breatheOut,
  };
}

extension SessionAnswersText on SessionAnswers {
  /// Câu phản hồi app đưa ra ở cuối buổi.
  ///
  /// Sinh bằng luật, chạy ngoại tuyến, không gọi model nào. Đúng như
  /// Prof. Chang mô tả: nhắc lại điều người dùng vừa nói rồi gợi ý bước kế —
  /// vai trò hỗ trợ thực hành, không phải nhà trị liệu.
  String closingMessage(AppLocalizations l) {
    final parts = <String>[];
    final change = improvement;
    final scale = feeling ?? CheckInFeeling.stressed;
    if (change != null) {
      final measure = scale.measure(l);
      if (change >= 3) {
        parts.add(l.closingLevelBetter(measure, levelBefore!, levelAfter!));
      } else if (change > 0) {
        parts.add(
          l.closingLevelBetterLittle(measure, levelBefore!, levelAfter!),
        );
      } else if (change == 0) {
        parts.add(l.closingLevelSame(measure, levelBefore!));
      } else {
        parts.add(l.closingLevelWorse);
      }
    }
    if (practice == PracticeChoice.grounding) {
      parts.add(l.closingNextBodyScan);
    } else if (practice == PracticeChoice.breathing) {
      parts.add(l.closingNextGrounding);
    }
    if (question != null && question!.trim().isNotEmpty) {
      parts.add(l.closingQuestionSaved);
    }
    if (parts.isEmpty) parts.add(l.closingThanks);
    return parts.join(' ');
  }
}

/// Tên hiển thị của một nhãn nhật ký. Nhãn được lưu bằng tiếng Anh như một mã
/// ("Session", "Appointment"); nhãn người dùng tự đặt thì hiện nguyên văn.
String tagLabel(AppLocalizations l, String tag) => switch (tag) {
  'Appointment' => l.tagAppointment,
  'Family' => l.tagFamily,
  'Friends' => l.tagFriends,
  'Health' => l.tagHealth,
  'Work' => l.tagWork,
  'Rest' => l.tagRest,
  'Exercise' => l.tagExercise,
  'Alone' => l.tagAlone,
  'Session' => l.tagSession,
  'Synced' => l.tagSynced,
  _ => tag,
};

/// Ghi chú hiển thị của một dòng nhật ký. Dòng tóm tắt buổi tập làm trên máy
/// khác không có ghi chú thật, nên hiện câu theo ngôn ngữ đang dùng.
String entryNote(AppLocalizations l, JournalEntry entry) =>
    entry.isRemoteSummary ? l.entryRemoteSession : entry.note;

/// Câu báo lỗi đăng nhập theo ngôn ngữ đang dùng.
String authErrorText(AppLocalizations l, AuthError error) {
  final participant = error.participant ?? l.authThisParticipant;
  return switch (error.kind) {
    AuthErrorKind.linkExpired => l.authLinkExpired,
    AuthErrorKind.accountNotActive => l.authAccountNotActive,
    AuthErrorKind.qrSignedOutOther => l.authQrSignedOutOther(participant),
    AuthErrorKind.serviceUnreachable => l.authServiceUnreachable,
    AuthErrorKind.serviceUnreachableRetry => l.authServiceUnreachableRetry,
    AuthErrorKind.checkDetails => l.authCheckDetails,
    AuthErrorKind.pageForOther => l.authPageForOther(participant),
    AuthErrorKind.invalidDetails => l.authInvalidDetails,
    AuthErrorKind.participantInactive => l.authParticipantInactive,
    AuthErrorKind.qrOtherNotOpened => l.authQrOtherNotOpened(participant),
    AuthErrorKind.noStaffAccess => l.authNoStaffAccess,
    AuthErrorKind.tooManyAttempts => l.authTooManyAttempts,
    AuthErrorKind.suspended => l.authSuspended,
    AuthErrorKind.notVerified => l.authNotVerified,
  };
}
