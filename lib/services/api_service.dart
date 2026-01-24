class ApiService {
  Future<String> fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    return "API Data";
  }
}
