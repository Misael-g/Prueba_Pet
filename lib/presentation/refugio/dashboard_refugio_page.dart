import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRefugioPage extends StatelessWidget {
  const DashboardRefugioPage({super.key});

  Future<Map<String, int>> getDashboardStats() async {
    final client = Supabase.instance.client;

    final mascotas = await client.from('mascotas').select();
    final solicitudes = await client
        .from('solicitudes_adopcion')
        .select()
        .eq('estado', 'pendiente');

    final adoptadas = (mascotas as List).where((m) => m['estado'] == 'adoptado').length;

    return {
      'mascotas': mascotas.length,
      'pendientes': (solicitudes as List).length,
      'adoptadas': adoptadas,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Refugio')),
      body: FutureBuilder(
        future: getDashboardStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data as Map<String, int>;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CardStat('Mascotas', stats['mascotas']!),
              _CardStat('Pendientes', stats['pendientes']!),
              _CardStat('Adoptadas', stats['adoptadas']!),
            ],
          );
        },
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String title;
  final int value;

  const _CardStat(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value.toString(),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title),
          ],
        ),
      ),
    );
  }
}
