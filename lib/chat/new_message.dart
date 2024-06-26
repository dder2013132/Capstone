import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled1/user_info.dart';
import 'package:flutter/foundation.dart';


class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _controller = TextEditingController();
  late UserInfo userInfo; // UserInfo 객체를 선언
  String userEmail = ''; // 이메일 초기화
  String username = ''; // 사용자 이름 초기화
  var _userEnterMessage = '';

  @override
  void initState() {
    super.initState();
    userInfo = UserInfo(); // UserInfo 초기화
    userEmail = userInfo.userEmail ?? ''; // 이메일 설정
    username = userEmail.split('@')[0];// 사용자 이름 설정
  }

  void _sendMessage() async {
    FocusScope.of(context).unfocus();
    FirebaseFirestore.instance.collection('chatting').add({
      'text' : _userEnterMessage,
      'time' : Timestamp.now(),
      'userID' : userEmail,
      'userName' : username
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              maxLines: null,
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Send a message...'),
              onChanged: (value) {
                setState(() {
                  _userEnterMessage = value;
                });
              },
            ),
          ),
          IconButton(
            onPressed: _userEnterMessage.trim().isEmpty ? null : _sendMessage,
            icon: const Icon(Icons.send),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}