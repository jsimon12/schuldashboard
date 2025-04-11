import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @dashboard.
  ///
  /// In de, this message translates to:
  /// **'CBS-Dashboard'**
  String get dashboard;

  /// No description provided for @temperature.
  ///
  /// In de, this message translates to:
  /// **'Temperatur'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In de, this message translates to:
  /// **'Luftfeuchtigkeit'**
  String get humidity;

  /// No description provided for @light.
  ///
  /// In de, this message translates to:
  /// **'Licht'**
  String get light;

  /// No description provided for @window.
  ///
  /// In de, this message translates to:
  /// **'Fenster'**
  String get window;

  /// No description provided for @selectBuilding.
  ///
  /// In de, this message translates to:
  /// **'Gebäude wählen'**
  String get selectBuilding;

  /// No description provided for @selectFloor.
  ///
  /// In de, this message translates to:
  /// **'Etage wählen'**
  String get selectFloor;

  /// No description provided for @selectRoom.
  ///
  /// In de, this message translates to:
  /// **'Raum wählen'**
  String get selectRoom;

  /// No description provided for @selectDateRange.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum wählen'**
  String get selectDateRange;

  /// No description provided for @noData.
  ///
  /// In de, this message translates to:
  /// **'Keine Daten verfügbar'**
  String get noData;

  /// No description provided for @pleaseSelectFilter.
  ///
  /// In de, this message translates to:
  /// **'Bitte Filter auswählen'**
  String get pleaseSelectFilter;

  /// No description provided for @weatherLoading.
  ///
  /// In de, this message translates to:
  /// **'Lade...'**
  String get weatherLoading;

  /// No description provided for @weatherError.
  ///
  /// In de, this message translates to:
  /// **'Fehler'**
  String get weatherError;

  /// No description provided for @weatherOffline.
  ///
  /// In de, this message translates to:
  /// **'Offline'**
  String get weatherOffline;

  /// No description provided for @logout.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get logout;

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @currentAlerts.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Warnungen'**
  String get currentAlerts;

  /// No description provided for @noCriticalValues.
  ///
  /// In de, this message translates to:
  /// **'Keine kritischen Werte.'**
  String get noCriticalValues;

  /// No description provided for @room.
  ///
  /// In de, this message translates to:
  /// **'Raum'**
  String get room;

  /// No description provided for @building.
  ///
  /// In de, this message translates to:
  /// **'Gebäude'**
  String get building;

  /// No description provided for @floor.
  ///
  /// In de, this message translates to:
  /// **'Etage'**
  String get floor;

  /// No description provided for @roomPlan.
  ///
  /// In de, this message translates to:
  /// **'Raumplan'**
  String get roomPlan;

  /// No description provided for @updatedAt.
  ///
  /// In de, this message translates to:
  /// **'Aktualisiert'**
  String get updatedAt;

  /// No description provided for @changeLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache wechseln'**
  String get changeLanguage;

  /// No description provided for @login.
  ///
  /// In de, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get password;

  /// No description provided for @loginErrorTitle.
  ///
  /// In de, this message translates to:
  /// **'Login fehlgeschlagen'**
  String get loginErrorTitle;

  /// No description provided for @loginError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Login: {message}'**
  String loginError(Object message);

  /// Topic-Anzeige mit Wert
  ///
  /// In de, this message translates to:
  /// **'Topic: {value}'**
  String topic(Object value);

  /// No description provided for @dateRange.
  ///
  /// In de, this message translates to:
  /// **'{start} – {end}'**
  String dateRange(Object start, Object end);

  /// No description provided for @alarmTitleTemperature.
  ///
  /// In de, this message translates to:
  /// **'Temperatur kritisch'**
  String get alarmTitleTemperature;

  /// No description provided for @alarmTitleHumidity.
  ///
  /// In de, this message translates to:
  /// **'Luftfeuchtigkeit kritisch'**
  String get alarmTitleHumidity;

  /// No description provided for @alarmMessageValue.
  ///
  /// In de, this message translates to:
  /// **'Wert: {value}'**
  String alarmMessageValue(String value);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
