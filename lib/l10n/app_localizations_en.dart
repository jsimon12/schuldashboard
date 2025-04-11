// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dashboard => 'CBS-Dashboard';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get light => 'Light';

  @override
  String get window => 'Window';

  @override
  String get selectBuilding => 'Select building';

  @override
  String get selectFloor => 'Select floor';

  @override
  String get selectRoom => 'Select room';

  @override
  String get selectDateRange => 'Select date range';

  @override
  String get noData => 'No data available';

  @override
  String get pleaseSelectFilter => 'Please select filter';

  @override
  String get weatherLoading => 'Loading...';

  @override
  String get weatherError => 'Error';

  @override
  String get weatherOffline => 'Offline';

  @override
  String get logout => 'Logout';

  @override
  String get close => 'Close';

  @override
  String get currentAlerts => 'Current Alerts';

  @override
  String get noCriticalValues => 'No critical values.';

  @override
  String get room => 'Room';

  @override
  String get building => 'Building';

  @override
  String get floor => 'Floor';

  @override
  String get roomPlan => 'Room plan';

  @override
  String get updatedAt => 'Updated';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginErrorTitle => 'Login failed';

  @override
  String loginError(Object message) {
    return 'Login error: $message';
  }

  @override
  String topic(Object value) {
    return 'Topic: $value';
  }

  @override
  String dateRange(Object start, Object end) {
    return '$start – $end';
  }

  @override
  String get alarmTitleTemperature => 'Temperature critical';

  @override
  String get alarmTitleHumidity => 'Humidity critical';

  @override
  String alarmMessageValue(String value) {
    return 'Value: $value';
  }
}
