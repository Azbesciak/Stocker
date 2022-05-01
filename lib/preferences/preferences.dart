abstract class Preferences {
  const Preferences();

  Future<bool> save(String key, dynamic value);

  Future<T?> get<T>(String key);
}
