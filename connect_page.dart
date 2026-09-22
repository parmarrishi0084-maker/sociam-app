import 'package:flutter/material.dart';
class ConnectPage extends StatelessWidget {
  const ConnectPage({super.key});
  @override Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Text('Connect', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      ListTile(leading: Icon(Icons.people), title: Text('Friends')),
      ListTile(leading: Icon(Icons.person_add), title: Text('Following')),
      ListTile(leading: Icon(Icons.chat), title: Text('Messages')),
      ListTile(leading: Icon(Icons.notifications), title: Text('Notifications')),
    ],
  );
}
