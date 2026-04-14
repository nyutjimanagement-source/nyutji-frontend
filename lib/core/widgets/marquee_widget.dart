import 'package:flutter/material.dart';

class MarqueeWidget extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double scrollSpeed; // pixels per frame roughly

  const MarqueeWidget({
    Key? key,
    required this.text,
    this.style = const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
    this.scrollSpeed = 1.0,
  }) : super(key: key);

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    if (!_scrollController.hasClients) return;
    
    while (mounted) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      await _scrollController.animateTo(
        maxScrollExtent,
        duration: Duration(milliseconds: (maxScrollExtent * 20 / widget.scrollSpeed).toInt()),
        curve: Curves.linear,
      );
      if (mounted) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          Text("${widget.text}      ", style: widget.style),
          Text("${widget.text}      ", style: widget.style),
          Text("${widget.text}      ", style: widget.style),
          Text("${widget.text}      ", style: widget.style),
        ],
      ),
    );
  }
}
