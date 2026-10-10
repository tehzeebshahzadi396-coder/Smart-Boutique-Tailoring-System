import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/customer.dart';
import 'providers/customer_provider.dart';
import 'providers/order_provider.dart';
import 'screens/billing/billing_screen.dart';
import 'screens/billing/invoice_screen.dart';
import 'screens/calculator/fabric_calculator_screen.dart';
import 'screens/home/app_shell.dart';
import 'screens/measurements/customer_detail_screen.dart';
import 'screens/measurements/customer_search_screen.dart';
import 'screens/measurements/measurement_form_screen.dart';
import 'screens/orders/create_order_screen.dart';
import 'screens/orders/order_tracking_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'utils/app_constants.dart';
import 'utils/app_theme.dart';
import 'utils/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  configureAppUrlStrategy();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final CustomerProvider customerProvider = CustomerProvider(prefs);
  final OrderProvider orderProvider = OrderProvider(prefs);
  await Future.wait([
    customerProvider.loadCustomers(),
    orderProvider.loadOrders(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: customerProvider),
        ChangeNotifierProvider.value(value: orderProvider),
      ],
      child: const SmartBoutiqueApp(),
    ),
  );
}

class SmartBoutiqueApp extends StatelessWidget {
  const SmartBoutiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppShell.routeName,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppShell.routeName:
            return MaterialPageRoute(builder: (_) => const AppShell());
          case CustomerSearchScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const CustomerSearchScreen(),
            );
          case MeasurementFormScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => MeasurementFormScreen(
                customerId: settings.arguments as String?,
              ),
            );
          case CustomerDetailScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(
                customerId: settings.arguments as String,
              ),
            );
          case FabricCalculatorScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const FabricCalculatorScreen(),
            );
          case OrdersScreen.routeName:
            return MaterialPageRoute(builder: (_) => const OrdersScreen());
          case CreateOrderScreen.routeName:
            final Object? args = settings.arguments;
            final Customer? customer = args is Customer
                ? args
                : args is String
                ? context.read<CustomerProvider>().findById(args)
                : null;
            return MaterialPageRoute(
              builder: (_) => customer == null
                  ? const Scaffold(
                      body: Center(child: Text('Customer profile not found.')),
                    )
                  : CreateOrderScreen(customer: customer),
            );
          case OrderTrackingScreen.routeName:
            return MaterialPageRoute(
              builder: (_) =>
                  OrderTrackingScreen(orderId: settings.arguments as String),
            );
          case BillingScreen.routeName:
            return MaterialPageRoute(
              builder: (_) =>
                  BillingScreen(orderId: settings.arguments as String?),
            );
          case InvoiceScreen.routeName:
            return MaterialPageRoute(
              builder: (_) =>
                  InvoiceScreen(orderId: settings.arguments as String),
            );
          default:
            return MaterialPageRoute(builder: (_) => const AppShell());
        }
      },
    );
  }
}
