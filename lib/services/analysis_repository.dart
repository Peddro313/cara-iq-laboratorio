import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis.dart';

/// Simple local storage for analyses.
/// Later this will be replaced / synced with Supabase.
class AnalysisRepository {
  static const _key = 'cara_iq_analyses';

  Future<List<AnalysisResult>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => AnalysisResult.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<AnalysisResult?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AnalysisResult analysis) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAll();

    // Replace if exists, otherwise add
    final index = all.indexWhere((a) => a.id == analysis.id);
    if (index >= 0) {
      all[index] = analysis;
    } else {
      all.insert(0, analysis);
    }

    final encoded = all.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAll();
    all.removeWhere((a) => a.id == id);
    final encoded = all.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
