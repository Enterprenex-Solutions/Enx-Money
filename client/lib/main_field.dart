import 'config/env.dart';
import 'main.dart' as app;

/// Flavor 3: ENX Money Field Application
/// Target Package: com.enxmoney.field
/// Production API Gateway: https://api.enxmoney.enterprenex.solutions/api/v1
void main() async {
  Env.setFlavor(AppFlavor.field);
  app.main();
}
