library; // ✅ Переименовал library в "default"

import 'package:firebase_data_connect/firebase_data_connect.dart';


class DefaultConnector {
  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'default',
    'myproject', // ✅ Убрали лишнюю запятую
  );

  final FirebaseDataConnect dataConnect; // ✅ Объявили переменную

  DefaultConnector({required this.dataConnect}); // ✅ Теперь всё правильно

  static DefaultConnector get instance => DefaultConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
          connectorConfig: connectorConfig,
          sdkType: CallerSDKType.generated,
        ),
      );
}
