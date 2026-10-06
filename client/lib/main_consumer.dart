import 'config/env.dart';
import 'main.dart' as app;

/// Flavor 2: ENX Money Consumer Application
/// Target Package: com.enxmoney.consumer
/// Production API Gateway: https://api.enxmoney.enterprenex.solutions/api/v1
void main() async {
  Env.setFlavor(AppFlavor.consumer);
  app.main();
}
