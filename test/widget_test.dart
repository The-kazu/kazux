import 'package:flutter_test/flutter_test.dart';
import 'package:kazux/main.dart';

void main() {
  testWidgets('Kazux abre a tela inicial', (tester) async {
    await tester.pumpWidget(const KazuxApp());
    expect(find.text('Kazux'), findsWidgets);
  });
}
