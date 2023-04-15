import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class PoeUtil {
  static final Uri url =
      Uri(scheme: 'https', host: 'www.quora.com', path: '/poe_api/gql_POST');

  static final Map<String, String> headers = {
    'Host': 'www.quora.com',
    'Accept': '*/*',
    'apollographql-client-version': '1.1.6-65',
    'Accept-Language': 'en-US,en;q=0.9',
    'User-Agent': 'Poe 1.1.6 rv:65 env:prod (iPhone14,2; iOS 16.2; en_US)',
    'apollographql-client-name': 'com.quora.app.Experts-apollo-ios',
    'Connection': 'keep-alive',
    'Content-Type': 'application/json',
  };

  static void setAuth(key, value) {
    headers[key] = value;
  }

  static Future<int> loadChatIdMap(bot) async {
    final String data = jsonEncode({
      'operationName': 'ChatViewQuery',
      'query':
          'query ChatViewQuery(\$bot: String!) {\n  chatOfBot(bot: \$bot) {\n    __typename\n    ...ChatFragment\n  }\n}\nfragment ChatFragment on Chat {\n  __typename\n  id\n  chatId\n  defaultBotNickname\n  shouldShowDisclaimer\n}',
      'variables': {'bot': bot}
    });
    final Response response =
        await http.post(url, headers: headers, body: data);
    return jsonDecode(utf8.decoder.convert(response.bodyBytes))['data']
        ['chatOfBot']['chatId'];
  }

  static Future<void> sendMessage(message, bot, chatId) async {
    final String data = jsonEncode({
      'operationName': 'AddHumanMessageMutation',
      'query':
          'mutation AddHumanMessageMutation(\$chatId: BigInt!, \$bot: String!, \$query: String!, \$source: MessageSource, \$withChatBreak: Boolean! = false) {\n  messageCreate(\n    chatId: \$chatId\n    bot: \$bot\n    query: \$query\n    source: \$source\n    withChatBreak: \$withChatBreak\n  ) {\n    __typename\n    message {\n      __typename\n      ...MessageFragment\n      chat {\n        __typename\n        id\n        shouldShowDisclaimer\n      }\n    }\n    chatBreak {\n      __typename\n      ...MessageFragment\n    }\n  }\n}\nfragment MessageFragment on Message {\n  id\n  __typename\n  messageId\n  text\n  linkifiedText\n  authorNickname\n  state\n  vote\n  voteReason\n  creationTime\n  suggestedReplies\n}',
      'variables': {
        'bot': bot,
        'chatId': chatId,
        'query': message,
        'source': null,
        'withChatBreak': false,
      }
    });

    await http.post(url, headers: headers, body: data);
  }

  static Future<void> clearContext(chatId) async {
    final String data = jsonEncode({
      'operationName': 'AddMessageBreakMutation',
      'query':
          'mutation AddMessageBreakMutation($chatId: BigInt!) {\n  messageBreakCreate(chatId: $chatId) {\n    __typename\n    message {\n      __typename\n      ...MessageFragment\n    }\n  }\n}\nfragment MessageFragment on Message {\n  id\n  __typename\n  messageId\n  text\n  linkifiedText\n  authorNickname\n  state\n  vote\n  voteReason\n  creationTime\n  suggestedReplies\n}',
      'variables': {'chatId': chatId}
    });

    await http.post(url, headers: headers, body: data);
  }

  static Future<String> getLatestMessage(bot) async {
    final String data = jsonEncode({
      'operationName': 'ChatPaginationQuery',
      'query':
          'query ChatPaginationQuery(\$bot: String!, \$before: String, \$last: Int! = 10) {\n  chatOfBot(bot: \$bot) {\n    id\n    __typename\n    messagesConnection(before: \$before, last: \$last) {\n      __typename\n      pageInfo {\n        __typename\n        hasPreviousPage\n      }\n      edges {\n        __typename\n        node {\n          __typename\n          ...MessageFragment\n        }\n      }\n    }\n  }\n}\nfragment MessageFragment on Message {\n  id\n  __typename\n  messageId\n  text\n  linkifiedText\n  authorNickname\n  state\n  vote\n  voteReason\n  creationTime\n}',
      'variables': {'before': null, 'bot': bot, 'last': 1}
    });

    String text = '';
    String authorNickname = '';
    String state = 'incomplete';

    while (true) {
      final Response response =
          await http.post(url, headers: headers, body: data);
      final Map<String, dynamic> responseJson =
          jsonDecode(utf8.decoder.convert(response.bodyBytes));

      text = responseJson['data']['chatOfBot']['messagesConnection']['edges']
          .last['node']['text'];
      state = responseJson['data']['chatOfBot']['messagesConnection']['edges']
          .last['node']['state'];
      authorNickname = responseJson['data']['chatOfBot']['messagesConnection']
              ['edges']
          .last['node']['authorNickname'];

      if (authorNickname == bot && state == 'complete') {
        break;
      }
    }

    return text;
  }
}
