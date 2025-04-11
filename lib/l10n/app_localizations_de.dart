// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get dashboard => 'CBS-Dashboard';

  @override
  String get temperature => 'Temperatur';

  @override
  String get humidity => 'Luftfeuchtigkeit';

  @override
  String get light => 'Licht';

  @override
  String get window => 'Fenster';

  @override
  String get selectBuilding => 'Gebäude wählen';

  @override
  String get selectFloor => 'Etage wählen';

  @override
  String get selectRoom => 'Raum wählen';

  @override
  String get selectDateRange => 'Zeitraum wählen';

  @override
  String get noData => 'Keine Daten verfügbar';

  @override
  String get pleaseSelectFilter => 'Bitte Filter auswählen';

  @override
  String get weatherLoading => 'Lade...';

  @override
  String get weatherError => 'Fehler';

  @override
  String get weatherOffline => 'Offline';

  @override
  String get logout => 'Abmelden';

  @override
  String get close => 'Schließen';

  @override
  String get currentAlerts => 'Aktuelle Warnungen';

  @override
  String get noCriticalValues => 'Keine kritischen Werte.';

  @override
  String get room => 'Raum';

  @override
  String get building => 'Gebäude';

  @override
  String get floor => 'Etage';

  @override
  String get roomPlan => 'Raumplan';

  @override
  String get updatedAt => 'Aktualisiert';

  @override
  String get changeLanguage => 'Sprache wechseln';

  @override
  String get login => 'Login';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get loginErrorTitle => 'Login fehlgeschlagen';

  @override
  String loginError(Object message) {
    return 'Fehler beim Login: $message';
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
  String get alarmTitleTemperature => 'Temperatur kritisch';

  @override
  String get alarmTitleHumidity => 'Luftfeuchtigkeit kritisch';

  @override
  String alarmMessageValue(String value) {
    return 'Wert: $value';
  }
}
