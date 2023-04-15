import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:neuralterm/utils/consts_util.dart';
import 'package:neuralterm/utils/poe_util.dart';

void main() async {
  // loading env variables
  await dotenv.load();

  // setting formkey and cookie
  PoeUtil.setAuth('Quora-Formkey', dotenv.env['QUORA_FORMKEY']);
  PoeUtil.setAuth('Cookie', dotenv.env['COOKIE']);

  // loading chat
  final int chatId = await PoeUtil.loadChatIdMap(ConstsUtil.bot);

  // sending message
  await PoeUtil.clearContext(chatId);
  const String message = 'hi';
  await PoeUtil.sendMessage(message, ConstsUtil.bot, chatId);

  // getting reply
  final String reply = await PoeUtil.getLatestMessage(ConstsUtil.bot);
  print(reply);
}
