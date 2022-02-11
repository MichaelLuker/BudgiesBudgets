// Return a 3 character string for the month code
String monthString(int n) {
  switch (n) {
    case 1:
      return "Jan";
    case 2:
      return "Feb";
    case 3:
      return "Mar";
    case 4:
      return "Apr";
    case 5:
      return "May";
    case 6:
      return "Jun";
    case 7:
      return "Jul";
    case 8:
      return "Aug";
    case 9:
      return "Sep";
    case 10:
      return "Oct";
    case 11:
      return "Nov";
    case 12:
      return "Dec";
    default:
      return "Unknown";
  }
}

// Returns a string of the date time in the format MMM DD YYYY like Feb 09 2022
String formatDate(DateTime d) {
  return "${monthString(d.month)} ${(d.day < 10) ? "0" + d.day.toString() : d.day} ${d.year}";
}
