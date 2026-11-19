const int _secondsPerMinute = 60;
const int _secondsPerHour = 3600;
const int _secondsPerDay = 86400;
const int _secondsPerMonth = 2592000;
const int _secondsPerYear = 31536000;

String intervalLabel(int seconds) {
  if (seconds < _secondsPerMinute) {
    return '$seconds s';
  }

  if (seconds < _secondsPerHour) {
    return '${seconds ~/ _secondsPerMinute} min';
  }

  if (seconds < _secondsPerDay) {
    return '${seconds ~/ _secondsPerHour} h';
  }

  if (seconds < _secondsPerMonth) {
    return '${seconds ~/ _secondsPerDay} days';
  }

  if (seconds < _secondsPerYear) {
    return '${seconds ~/ _secondsPerMonth} mo';
  }

  return '${seconds ~/ _secondsPerYear} y';
}
