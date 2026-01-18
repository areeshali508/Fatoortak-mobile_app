import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../controllers/auth_controller.dart';
import '../controllers/customer_controller.dart';
import '../controllers/invoice_controller.dart';
import '../controllers/product_controller.dart';

class AppProviders {
  static final List<SingleChildWidget> providers = <SingleChildWidget>[
    ChangeNotifierProvider<AuthController>(
      create: (_) => AuthController(),
    ),
    ChangeNotifierProvider<ProductController>(
      create: (_) => ProductController(),
    ),
    ChangeNotifierProvider<InvoiceController>(
      create: (_) => InvoiceController(),
    ),
    ChangeNotifierProvider<CustomerController>(
      create: (_) => CustomerController(),
    ),
  ];
}
