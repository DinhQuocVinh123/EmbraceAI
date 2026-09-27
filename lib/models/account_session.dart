enum AccountRole { participant, researcher, coordinator, admin }

class AccountSession {
  const AccountSession({
    required this.uid,
    required this.role,
    this.participantCode,
  });

  final String uid;
  final AccountRole role;
  final String? participantCode;

  bool get isStaff => role != AccountRole.participant;
}
