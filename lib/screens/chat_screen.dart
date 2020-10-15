import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatter/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
User loggedUser;
final listViewController = ScrollController();

class ChatScreen extends StatefulWidget {
  static const id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final textEditingController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String messageText;

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedUser = user;
        print(loggedUser.email);
      }
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('Chatter'),
        backgroundColor: Colors.blueGrey[700],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Material(
                    shape: CircleBorder(),
                    color: Colors.white,
                    child: Center(
                      child: Ink(
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: CircleBorder(),
                        ),
                        child: IconButton(
                          iconSize: 35,
                          icon: Icon(Icons.emoji_emotions_outlined),
                          color: Colors.black,
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      style: TextStyle(fontSize: 18),
                      controller: textEditingController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      if (messageText != '') {
                        try {
                          _firestore.collection('messages').add({
                            'text': messageText,
                            'sender': loggedUser.email,
                            'time': DateTime.now().millisecondsSinceEpoch,
                          });
                          textEditingController.clear();
                        } catch (e) {
                          print(e);
                        }
                        listViewController.animateTo(
                          listViewController.position.minScrollExtent,
                          duration: Duration(seconds: 2),
                          curve: Curves.fastOutSlowIn,
                        );
                      }
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('messages')
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
        var currentUser = loggedUser.email;
        final messages = snapshot.data.docs;
        List<MessageBubble> messageWidgets = [];
        for (var message in messages) {
          final messageText = message.data()['text'];
          final String messageSender = message.data()['sender'];
          final messageTime = message.data()['time'];
          var date = DateTime.fromMillisecondsSinceEpoch(messageTime);
          var formattedDate = DateFormat.yMMMd().add_jm().format(date);

          final messageWidget = MessageBubble(
            text: messageText,
            sender: messageSender.substring(0, messageSender.indexOf('@')),
            time: formattedDate,
            isMe: currentUser == messageSender,
          );
          messageWidgets.add(messageWidget);
        }
        return Expanded(
          child: ListView(
            controller: listViewController,
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            children: messageWidgets,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.text, this.sender, this.time, this.isMe});
  final String text;
  final String sender;
  final String time;
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: isMeName(isMe, sender),
        ),
        Material(
          borderRadius: isMe
              ? BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  bottomLeft: Radius.circular(15.0),
                  bottomRight: Radius.circular(15.0),
                )
              : BorderRadius.only(
                  topRight: Radius.circular(15.0),
                  bottomLeft: Radius.circular(15.0),
                  bottomRight: Radius.circular(15.0),
                ),
          elevation: 5.0,
          color: isMe ? Colors.blueGrey[400] : Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black54,
                      fontSize: 15.0,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 10.0,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Text isMeName(bool isMe, String name) {
  if (!isMe) {
    return Text(
      name,
      style: TextStyle(
        color: Colors.black54,
        fontSize: 12.0,
      ),
    );
  }
  return null;
}
