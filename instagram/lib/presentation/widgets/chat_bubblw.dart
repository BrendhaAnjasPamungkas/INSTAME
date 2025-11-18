import 'package:flutter/material.dart';
import 'package:instagram/presentation/widgets/main_widget.dart'; // Pakai W.text

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe; // True = Pesan Saya (Kanan), False = Pesan Dia (Kiri)

  const ChatBubble({Key? key, required this.text, required this.isMe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[800], // Biru utk kita, Abu utk dia
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
          ),
        ),
        child: W.text(
          data: text,
          color: Colors.white,
          fontSize: 15,
        ),
      ),
    );
  }
}