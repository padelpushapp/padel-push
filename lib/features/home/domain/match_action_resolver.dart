enum MatchAction {
  join,
  request,
  waiting,
  confirmed,
  manage,
  none,
}

MatchAction resolveMatchAction({
  required String? myStatus,
  required bool isCreator,
  required int joinedCount,
  required int neededPlayers,
}) {
  if (isCreator) return MatchAction.manage;

  if (myStatus == null) {
    return joinedCount < neededPlayers
        ? MatchAction.join
        : MatchAction.waiting;
  }

  switch (myStatus) {
    case 'requested':
      return MatchAction.request;
    case 'waiting':
      return MatchAction.waiting;
    case 'joined':
      return MatchAction.confirmed;
    default:
      return MatchAction.none;
  }
}
