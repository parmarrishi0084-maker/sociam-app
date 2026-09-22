import 'package:flutter/material.dart';
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});
  @override Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Discover', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      for (final item in ['Trending','Near You','Creators','Communities','Local','Cars','Food','Business','Sports','Music'])
        Card(child: ListTile(
          leading: const Icon(Icons.explore_outlined),
          title: Text(item),
          trailing: const Icon(Icons.chevron_right),
        )),
    ],
  );
}
