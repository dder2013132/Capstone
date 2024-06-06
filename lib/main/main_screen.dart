import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled1/shop_screen.dart';
import 'package:untitled1/Plan/calendar_screen.dart';
import 'package:untitled1/Plan/_plan.dart';
import 'package:untitled1/main/log_out.dart';
import 'package:untitled1/chat/chat_room.dart';
import 'package:untitled1/character/main_character.dart';
import '../character/store_image.dart';
import 'package:untitled1/level_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.characterImage, this.backgroundImage});

  final String? characterImage;
  final String? backgroundImage;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late String _currentCharacterImage;
  late String _currentBackgroundImage;
  final _authentication = FirebaseAuth.instance;
  User? loggedUser;
  int _exp = 0;
  int _points = 0;
  int _level = 0;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    _currentCharacterImage = widget.characterImage ?? StoreImage.characterImage;
    _currentBackgroundImage = widget.backgroundImage ?? StoreImage.backgroundImage;
    fetchUserData();
  }

  void getCurrentUser() {
    try {
      final user = _authentication.currentUser;
      if (user != null) {
        loggedUser = user;
        debugPrint('Current user: ${loggedUser!.email}');
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
    }
  }

  Future<void> fetchUserData() async {
    if (loggedUser != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(loggedUser!.uid).get();
      if (doc.exists) {
        debugPrint('User data: ${doc.data()}');
        setState(() {
          _exp = doc['exp'];
          _points = doc['points'];
          _level = LevelManager.calculateLevel(_exp);
        });
      } else {
        debugPrint('No such document!');
      }
    }
  }

  void updateExp(int exp) async {
    setState(() {
      _exp = exp;
    });
    int newLevel = LevelManager.calculateLevel(_exp);
    if (newLevel != _level) {
      setState(() {
        _level = newLevel;
      });
      await FirebaseFirestore.instance.collection('users').doc(loggedUser!.uid).update({
        'level': _level,
        'exp': _exp,
      });
    } else {
      await FirebaseFirestore.instance.collection('users').doc(loggedUser!.uid).update({
        'exp': _exp,
      });
    }
    fetchUserData(); // 업데이트 후 데이터를 다시 가져와서 확인
  }

  Future<List<Plan>> getPlansFromFirestore() async {
    final userEmail = loggedUser?.email;
    if (userEmail != null) {
      final querySnapshot = await FirebaseFirestore.instance.collection(userEmail).get();
      return querySnapshot.docs.map((doc) => Plan.fromJson(doc.data())).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    double progress = LevelManager.getProgressToNextLevel(_exp);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            children: <Widget>[
              Container(
                width: screenWidth * 0.9,
                height: screenHeight * 0.9,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_currentBackgroundImage),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Center(
                      child: Image.asset(
                        _currentCharacterImage,
                        height: screenHeight * 0.3,
                        width: screenWidth * 0.5,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Exp: $_exp',
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    Text(
                      'Points: $_points',
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    Text(
                      'Level: $_level',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[500],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
