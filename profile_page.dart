import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  Map<String,dynamic>? profile;
  bool loading = true;
  @override void initState(){super.initState(); load();}
  Future<void> load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if(uid == null){setState(()=>loading=false);return;}
    try {
      final data = await Supabase.instance.client.from('profiles')
        .select('username,full_name,bio,avatar_url,is_creator,is_business')
        .eq('id',uid).maybeSingle();
      if(mounted)setState(()=>profile=data);
    } finally { if(mounted)setState(()=>loading=false); }
  }
  @override Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    if(loading)return const Center(child:CircularProgressIndicator());
    return ListView(padding:const EdgeInsets.all(20),children:[
      const CircleAvatar(radius:44,child:Icon(Icons.person,size:42)),
      const SizedBox(height:12),
      Text(profile?['full_name']?.toString().isNotEmpty==true
        ? profile!['full_name'] : email,
        style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      Text('@${profile?['username'] ?? 'user'}'),
      const SizedBox(height:8),
      Text(profile?['bio'] ?? ''),
      const SizedBox(height:20),
      OutlinedButton(onPressed:()=>Supabase.instance.client.auth.signOut(),child:const Text('Log out')),
    ]);
  }
}
