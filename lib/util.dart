class Util {
  static String getDatabasePath(String? uid) {
    DateTime now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);

    final dateString = date.toString().split(' ')[0];
    return "users/${uid ?? ''}/$dateString";
  }
}
