import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(CupertinoApp(
    debugShowCheckedModeBanner: false,
    home: TelegramSenderPage(),
  ));
}

class MessageTask {
  String text;
  int count;
  double delay;

  MessageTask({required this.text, required this.count, required this.delay});
}

class TelegramSenderPage extends StatefulWidget {
  @override
  _TelegramSenderPageState createState() => _TelegramSenderPageState();
}

class _TelegramSenderPageState extends State<TelegramSenderPage> {
  final tokenController = TextEditingController();
  final chatController = TextEditingController();
  final messageController = TextEditingController();
  final countController = TextEditingController(text: "1");
  final delayController = TextEditingController(text: "1");

  List<MessageTask> queue = [];
  List<String> logs = [];
  bool runningQueue = false;
  double progressValue = 0.0;

  void log(String text) {
    setState(() {
      final now = DateTime.now();
      final timestamp =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      logs.insert(0, "[$timestamp] $text");
      if (logs.length > 500) logs.removeLast();
    });
  }

  void addToQueue() {
    final text = messageController.text.trim();
    int count = int.tryParse(countController.text.trim()) ?? 1;
    double delay = double.tryParse(delayController.text.trim()) ?? 1;

    if (text.isEmpty) {
      log("消息不能为空！");
      return;
    }

    setState(() {
      queue.add(MessageTask(text: text, count: count, delay: delay));
      messageController.clear();
    });

    log("已加入队列: $text (count=$count, delay=${delay}s)");
  }
  void clearQueue() {
    setState(() {
      queue.clear();
    });
    log("已清空发送队列");
  }
  Future<void> runQueue() async {
    final token = tokenController.text.trim();
    final chat = chatController.text.trim();

    if (token.isEmpty || chat.isEmpty) {
      log("Bot Token 或 Chat ID 不能为空！");
      return;
    }

    if (queue.isEmpty) {
      log("队列为空，请先添加消息");
      return;
    }

    runningQueue = true;
    log("开始执行队列 (${queue.length} 条消息)");

    int totalTasks = queue.fold(0, (sum, t) => sum + t.count);
    int sentCount = 0;

    while (runningQueue && queue.isNotEmpty) {
      MessageTask task = queue.first;

      for (int i = 0; i < task.count; i++) {
        if (!runningQueue) break;

        try {
          final response = await http.post(
            Uri.parse("https://api.telegram.org/bot$token/sendMessage"),
            body: {"chat_id": chat, "text": task.text},
          );
          if (response.statusCode == 200) {
            log("发送成功: ${task.text} (${i + 1}/${task.count})");
          } else {
            log("发送失败: ${task.text} (${i + 1}/${task.count})");
          }
        } catch (e) {
          log("发送异常: $e");
        }

        await Future.delayed(Duration(seconds: task.delay.toInt()));
        sentCount++;
        setState(() {
          progressValue = sentCount / totalTasks;
        });
      }

      setState(() {
        queue.removeAt(0);
      });
    }

    runningQueue = false;
    setState(() {
      progressValue = 0.0;
    });
    log("队列发送完成");
  }

  void stopQueue() {
    runningQueue = false;
    log("已停止队列发送");
    setState(() {
      progressValue = 0.0;
    });
  }

  Widget buildInputField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14, color: CupertinoColors.inactiveGray)),
          SizedBox(height: 4),
          CupertinoTextField(
            controller: controller,
            padding: EdgeInsets.all(12),
            maxLines: maxLines,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProgressBar() {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey4,
        borderRadius: BorderRadius.circular(5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progressValue.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Telegram Bot 消息发送器"),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              buildInputField("Bot Token(您的机器人 Token)", tokenController),
              buildInputField(
                  "Chat ID(接收消息的聊天 ID)", chatController),
              buildInputField("消息内容", messageController, maxLines: 3),
              Row(
                children: [
                  Expanded(child: buildInputField("发送次数", countController)),
                  SizedBox(width: 12),
                  Expanded(child: buildInputField("间隔(秒)", delayController)),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: CupertinoButton.filled(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text("加入队列", style: TextStyle(fontSize: 14)),
                        onPressed: addToQueue,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: CupertinoButton.filled(
                        color: CupertinoColors.systemGrey,
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text("清空队列", style: TextStyle(fontSize: 14)),
                        onPressed: queue.isNotEmpty ? clearQueue : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: CupertinoButton.filled(
                        color: CupertinoColors.activeGreen,
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text("开始发送", style: TextStyle(fontSize: 14)),
                        onPressed: runningQueue ? null : runQueue,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: CupertinoButton.filled(
                        color: CupertinoColors.destructiveRed,
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text("停止发送", style: TextStyle(fontSize: 14)),
                        onPressed: runningQueue ? stopQueue : null,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (runningQueue) buildProgressBar(),
              SizedBox(height: 16),
              // 日志区
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("日志:",
                      style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.inactiveGray)),
                  SizedBox(height: 4),
                  Container(
                    height: 400,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(12)),
                    child: ListView.builder(
                      reverse: false,
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return Text(
                          logs[index],
                          style: TextStyle(
                              fontSize: 14, color: CupertinoColors.white),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "© 2026-present SunMutian - Email: sunmutian88@gmail.com",
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.inactiveGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}