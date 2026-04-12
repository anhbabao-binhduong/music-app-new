import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() {
  test('debug get_chart_trends rpc', () async {
    HttpOverrides.global = null;
    await Supabase.initialize(
      url: 'https://pdbkojvgjrvnzqmerwmz.supabase.co',
      anonKey: 'ey...', // I don't know the anon key!
    );
    final _supabase = Supabase.instance.client;
    final res = await _supabase.rpc('get_chart_trends', params: {
      'days_ago': 1,
      'song_id_list': ['155', '153', '154'],
    });
    print(res);
  });
}
