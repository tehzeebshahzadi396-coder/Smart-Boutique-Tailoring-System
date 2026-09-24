import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_boutique/main.dart';
import 'package:smart_boutique/providers/customer_provider.dart';
import 'package:smart_boutique/providers/order_provider.dart';

void main() {
  testWidgets('dashboard loads with navigation destinations', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final CustomerProvider customers = CustomerProvider(prefs);
    final OrderProvider orders = OrderProvider(prefs);
    await customers.loadCustomers();
    await orders.loadOrders();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: customers),
          ChangeNotifierProvider.value(value: orders),
        ],
        child: const SmartBoutiqueApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Customers'), findsWidgets);
  });
}
