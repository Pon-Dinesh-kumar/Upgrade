import 'package:flutter_test/flutter_test.dart';
import 'package:upgrade/features/upgrade_ai/domain/ai_models.dart';

void main() {
  group('AI Response Parsing Tests', () {
    test('parseAIResponse correctly extracts JSON from markdown', () {
      const raw = '''
Some conversational text before.
```json
{
  "reply": "I have prepared the changes for your review.",
  "proposedActions": [
    {
      "id": "action_1",
      "type": "createHabit",
      "reason": "To help you drink more water",
      "payload": {"name": "Drink Water", "frequency": "daily"}
    }
  ]
}
```
Some text after.
''';
      final response = parseAIResponse(raw);
      expect(response.reply, "I have prepared the changes for your review.");
      expect(response.proposedActions.length, 1);
      expect(response.proposedActions.first.id, "action_1");
      expect(response.proposedActions.first.type, AIToolActionType.createHabit);
    });

    test('parseAIResponse handles multiple code blocks and picks the right one', () {
      const raw = '''
```json
{"irrelevant": true}
```
Middle text.
```json
{
  "reply": "Valid response",
  "proposedActions": []
}
```
''';
      final response = parseAIResponse(raw);
      expect(response.reply, "Valid response");
      expect(response.proposedActions, isEmpty);
    });

    test('parseAIResponse fallback to raw text when no JSON found', () {
      const raw = 'Just a normal chat message without JSON.';
      final response = parseAIResponse(raw);
      expect(response.reply, raw);
      expect(response.proposedActions, isEmpty);
    });

    test('parseAIResponse handles proposedActions as a single object', () {
      const raw = '''
{
  "reply": "Single action",
  "proposedActions": {
    "id": "action_2",
    "type": "createUpgrade",
    "reason": "Reason",
    "payload": {}
  }
}
''';
      final response = parseAIResponse(raw);
      expect(response.reply, "Single action");
      expect(response.proposedActions.length, 1);
      expect(response.proposedActions.first.type, AIToolActionType.createUpgrade);
    });
  });
}
