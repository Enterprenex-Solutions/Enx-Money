import 'config/env.dart';
import 'main.dart' as app;

/// Flavor 1: ENX Money Merchant Application
/// Target Package: com.enxmoney.merchant
/// Production API Gateway: https://api.enxmoney.enterprenex.solutions/api/v1
void main() async {
  Env.setFlavor(AppFlavor.merchant);
  app.main();
}
