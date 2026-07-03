class ApiConstants {
  static const String rootUrl = "https://api.nyutji.com";
  static const String baseUrl = "$rootUrl/api/v1";
  static const String login = "/login";
  static const String createOrder = "/orders";
  static const String withdraw = "/withdraw/request";

  static String profilePhotoUrl(dynamic rawUrl) {
    if (rawUrl == null) return "";
    final url = rawUrl.toString().trim();
    if (url.isEmpty) return "";
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return "$rootUrl$url";
    if (url.startsWith('uploads/')) return "$rootUrl/$url";
    return "$rootUrl/uploads/profiles/$url";
  }
}
