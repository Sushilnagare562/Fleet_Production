import 'package:flutter/material.dart';

import 'strings_en.dart';
import 'strings_gu.dart';
import 'strings_hi.dart';
import 'strings_mr.dart';
import 'strings_ta.dart';

/// Centralized, key-based localization.
///
/// Design choices:
///  * Translations live in per-language `Map<String,String>` files (compiled in,
///    so there is NO codegen / `flutter gen-l10n` step to run and switching is
///    instant at runtime).
///  * Every lookup falls back to English if a key is missing for the active
///    language, and finally to the key itself only as a last-resort dev signal
///    — the app never shows `null`, blank, or a raw key to a user for any key
///    that exists in [enStrings] (which is the complete master set).
///  * Callers use ergonomic getters (`context.l10n.startTrip`) rather than raw
///    string keys, so typos are compile errors.
///
/// Adding a language later (e.g. Kannada) is: add `strings_kn.dart`, register it
/// in [_byLanguage] and [supportedLocales], and add the native name to
/// [languageNames]. No screen changes required.
class AppLocalizations {
  final Locale locale;
  final Map<String, String> _strings;

  AppLocalizations(this.locale) : _strings = _byLanguage[locale.languageCode] ?? enStrings;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('gu'),
    Locale('ta'),
  ];

  /// Native display names, shown untranslated in the language picker.
  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'mr': 'मराठी',
    'gu': 'ગુજરાતી',
    'ta': 'தமிழ்',
  };

  /// English subtitle under each native name in the picker (helps admins).
  static const Map<String, String> languageEnglishNames = {
    'en': 'English',
    'hi': 'Hindi',
    'mr': 'Marathi',
    'gu': 'Gujarati',
    'ta': 'Tamil',
  };

  static const Map<String, Map<String, String>> _byLanguage = {
    'en': enStrings,
    'hi': hiStrings,
    'mr': mrStrings,
    'gu': guStrings,
    'ta': taStrings,
  };

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// Raw key lookup with English fallback. Prefer the typed getters below.
  String tr(String key) => _strings[key] ?? enStrings[key] ?? key;

  /// Maps a backend trip-status ENUM VALUE to a localized label.
  /// The enum value itself is never translated or altered.
  String tripStatus(String status) {
    switch (status) {
      case 'ASSIGNED':
        return statusAssigned;
      case 'IN_PROGRESS':
        return statusInProgress;
      case 'COMPLETED':
        return statusCompleted;
      case 'CANCELLED':
        return statusCancelled;
      default:
        return status.replaceAll('_', ' ');
    }
  }

  /// Maps an expense CATEGORY enum value to a localized label. Enum unchanged.
  String expenseCategory(String category) {
    switch (category) {
      case 'FUEL':
        return catFuel;
      case 'TOLL':
        return catToll;
      case 'FOOD':
        return catFood;
      case 'MAINTENANCE':
        return catMaintenance;
      default:
        return catOther;
    }
  }

  /// Maps an earning PAYMENT-STATUS enum value to a localized label.
  String earningStatus(String status) => status == 'PAID' ? paid : pending;

  /// Maps a vehicle TYPE enum value to a localized label. Enum unchanged.
  String vehicleType(String type) {
    switch (type) {
      case 'TRUCK':
        return vtTruck;
      case 'VAN':
        return vtVan;
      case 'BIKE':
        return vtBike;
      case 'CAR':
        return vtCar;
      default:
        return vtOther;
    }
  }

  /// Maps a vehicle STATUS enum value to a localized label. Enum unchanged.
  String vehicleStatus(String status) {
    switch (status) {
      case 'ACTIVE':
        return vsActive;
      case 'MAINTENANCE':
        return vsMaintenance;
      default:
        return vsInactive;
    }
  }

  // ---- Common ----
  String get appName => tr('appName');
  String get ok => tr('ok');
  String get cancel => tr('cancel');
  String get save => tr('save');
  String get delete => tr('delete');
  String get edit => tr('edit');
  String get retry => tr('retry');
  String get tryAgain => tr('tryAgain');
  String get search => tr('search');
  String get filter => tr('filter');
  String get close => tr('close');
  String get confirm => tr('confirm');
  String get yes => tr('yes');
  String get no => tr('no');
  String get add => tr('add');
  String get submit => tr('submit');
  String get next => tr('next');
  String get back => tr('back');
  String get done => tr('done');
  String get seeAll => tr('seeAll');
  String get refresh => tr('refresh');
  String get loading => tr('loading');

  // ---- Generic states ----
  String get somethingWentWrong => tr('somethingWentWrong');
  String get noData => tr('noData');
  String get noResults => tr('noResults');
  String get noInternet => tr('noInternet');

  // ---- Navigation (driver) ----
  String get navTrips => tr('navTrips');
  String get navExpenses => tr('navExpenses');
  String get navEarnings => tr('navEarnings');
  String get navProfile => tr('navProfile');

  // ---- Navigation (admin) ----
  String get navDashboard => tr('navDashboard');
  String get navDrivers => tr('navDrivers');
  String get navFleet => tr('navFleet');
  String get navApprovals => tr('navApprovals');
  String get navReports => tr('navReports');
  String get navLiveTracking => tr('navLiveTracking');
  String get navRouteOptimization => tr('navRouteOptimization');

  // ---- Auth ----
  String get login => tr('login');
  String get logout => tr('logout');
  String get register => tr('register');
  String get signIn => tr('signIn');
  String get createAccount => tr('createAccount');
  String get email => tr('email');
  String get mobileNumber => tr('mobileNumber');
  String get emailOrMobile => tr('emailOrMobile');
  String get password => tr('password');
  String get currentPassword => tr('currentPassword');
  String get newPassword => tr('newPassword');
  String get confirmPassword => tr('confirmPassword');
  String get forgotPassword => tr('forgotPassword');
  String get resetPassword => tr('resetPassword');
  String get changePassword => tr('changePassword');
  String get dontHaveAccount => tr('dontHaveAccount');
  String get alreadyHaveAccount => tr('alreadyHaveAccount');
  String get sendCode => tr('sendCode');
  String get verify => tr('verify');
  String get otp => tr('otp');
  String get loginFailed => tr('loginFailed');

  // ---- Profile / settings ----
  String get profile => tr('profile');
  String get myProfile => tr('myProfile');
  String get account => tr('account');
  String get accountDetails => tr('accountDetails');
  String get username => tr('username');
  String get emailAddress => tr('emailAddress');
  String get settings => tr('settings');
  String get appearance => tr('appearance');
  String get theme => tr('theme');
  String get language => tr('language');
  String get security => tr('security');
  String get application => tr('application');
  String get editProfile => tr('editProfile');
  String get selectLanguage => tr('selectLanguage');
  String get selectTheme => tr('selectTheme');
  String get themeLight => tr('themeLight');
  String get themeDark => tr('themeDark');
  String get themeSystem => tr('themeSystem');
  String get themeLightSubtitle => tr('themeLightSubtitle');
  String get themeDarkSubtitle => tr('themeDarkSubtitle');
  String get themeSystemSubtitle => tr('themeSystemSubtitle');
  String get profilePhotoUpdated => tr('profilePhotoUpdated');
  String get couldNotUpdatePhoto => tr('couldNotUpdatePhoto');
  String get couldNotReadImage => tr('couldNotReadImage');

  // ---- Trips ----
  String get trips => tr('trips');
  String get myTrips => tr('myTrips');
  String get activeTrip => tr('activeTrip');
  String get tripDetails => tr('tripDetails');
  String get origin => tr('origin');
  String get destination => tr('destination');
  String get vehicle => tr('vehicle');
  String get driver => tr('driver');
  String get scheduled => tr('scheduled');
  String get distance => tr('distance');
  String get notes => tr('notes');
  String get startTrip => tr('startTrip');
  String get completeTrip => tr('completeTrip');
  String get dockIn => tr('dockIn');
  String get dockOut => tr('dockOut');
  String get dockedIn => tr('dockedIn');
  String get dockedOut => tr('dockedOut');
  String get dockInFirst => tr('dockInFirst');
  String get dockAllStopsFirst => tr('dockAllStopsFirst');
  String get noTrips => tr('noTrips');

  // ---- Trip status ----
  String get statusAssigned => tr('statusAssigned');
  String get statusInProgress => tr('statusInProgress');
  String get statusCompleted => tr('statusCompleted');
  String get statusCancelled => tr('statusCancelled');

  // ---- Expenses / earnings ----
  String get expenses => tr('expenses');
  String get addExpense => tr('addExpense');
  String get amount => tr('amount');
  String get category => tr('category');
  String get date => tr('date');
  String get status => tr('status');
  String get noExpenses => tr('noExpenses');
  String get earnings => tr('earnings');
  String get totalEarnings => tr('totalEarnings');
  String get noEarnings => tr('noEarnings');

  // ---- Reports ----
  String get reports => tr('reports');
  String get reportType => tr('reportType');
  String get dateRange => tr('dateRange');
  String get generate => tr('generate');
  String get download => tr('download');

  // ---- Phase 2 (screens migration) ----
  String get welcomeBack => tr('welcomeBack');
  String get signInToContinue => tr('signInToContinue');
  String get createYourAccount => tr('createYourAccount');
  String get signUpToStart => tr('signUpToStart');
  String get fullName => tr('fullName');
  String get phoneNumber => tr('phoneNumber');
  String get companyTransport => tr('companyTransport');
  String get companyNameHint => tr('companyNameHint');
  String get emailOrMobileHint => tr('emailOrMobileHint');
  String get forgotPasswordTitle => tr('forgotPasswordTitle');
  String get resetYourPassword => tr('resetYourPassword');
  String get enterVerifyCode => tr('enterVerifyCode');
  String get verificationCode => tr('verificationCode');
  String get sendVerifyCode => tr('sendVerifyCode');
  String get temporaryPassword => tr('temporaryPassword');
  String get confirmNewPassword => tr('confirmNewPassword');
  String get updatePassword => tr('updatePassword');
  String get passwordRule => tr('passwordRule');
  String get passwordsDoNotMatch => tr('passwordsDoNotMatch');
  String get role => tr('role');
  String get company => tr('company');
  String get addProfilePic => tr('addProfilePic');
  String get route => tr('route');
  String get scheduledStart => tr('scheduledStart');
  String get scheduledEnd => tr('scheduledEnd');
  String get pickup => tr('pickup');
  String get delivery => tr('delivery');
  String get waypoint => tr('waypoint');
  String get additionalStops => tr('additionalStops');
  String get suggestedVisitOrder => tr('suggestedVisitOrder');
  String get dock => tr('dock');
  String get eventRecorded => tr('eventRecorded');
  String get couldNotRecordEvent => tr('couldNotRecordEvent');
  String get couldNotUpdateStatus => tr('couldNotUpdateStatus');
  String get noTripsAssignOne => tr('noTripsAssignOne');
  String get addEarning => tr('addEarning');
  String get saveEarning => tr('saveEarning');
  String get saveExpense => tr('saveExpense');
  String get baseAmount => tr('baseAmount');
  String get bonus => tr('bonus');
  String get deduction => tr('deduction');
  String get totalPayout => tr('totalPayout');
  String get totalEarned => tr('totalEarned');
  String get noExpensesLogged => tr('noExpensesLogged');
  String get noExpensesSubmitted => tr('noExpensesSubmitted');
  String get noEarningsRecorded => tr('noEarningsRecorded');
  String get awaitingReview => tr('awaitingReview');
  String get approve => tr('approve');
  String get reject => tr('reject');
  String get markPaid => tr('markPaid');
  String get paid => tr('paid');
  String get pending => tr('pending');
  String get approvals => tr('approvals');
  String get description => tr('description');
  String get remarks => tr('remarks');
  String get notesOptional => tr('notesOptional');
  String get couldNotSaveExpense => tr('couldNotSaveExpense');
  String get assignToDriverOpt => tr('assignToDriverOpt');
  String get fleetDashboard => tr('fleetDashboard');
  String get totalTrips => tr('totalTrips');
  String get liveTrips => tr('liveTrips');
  String get unassigned => tr('unassigned');
  String get thisMonth => tr('thisMonth');
  String get allTrips => tr('allTrips');
  String get addDriver => tr('addDriver');
  String get noDriversYet => tr('noDriversYet');
  String get deleteDriver => tr('deleteDriver');
  String get deleteDriverConfirm => tr('deleteDriverConfirm');
  String get markAsActive => tr('markAsActive');
  String get markAsOnLeave => tr('markAsOnLeave');
  String get active => tr('active');
  String get onLeave => tr('onLeave');
  String get licenseNumberOpt => tr('licenseNumberOpt');
  String get addVehicle => tr('addVehicle');
  String get noVehiclesYet => tr('noVehiclesYet');
  String get couldNotAddVehicle => tr('couldNotAddVehicle');
  String get vehicleNumber => tr('vehicleNumber');
  String get vehicleNumberOpt => tr('vehicleNumberOpt');
  String get modelOpt => tr('modelOpt');
  String get capacityOpt => tr('capacityOpt');
  String get addGpsDevice => tr('addGpsDevice');
  String get deviceId => tr('deviceId');
  String get type => tr('type');
  String get assignTrip => tr('assignTrip');
  String get selectDriver => tr('selectDriver');
  String get selectVehicle => tr('selectVehicle');
  String get pleaseSelectDriver => tr('pleaseSelectDriver');
  String get pleaseSelectVehicle => tr('pleaseSelectVehicle');
  String get originPickup => tr('originPickup');
  String get destinationDelivery => tr('destinationDelivery');
  String get addStop => tr('addStop');
  String get stopType => tr('stopType');
  String get locationName => tr('locationName');
  String get distanceOpt => tr('distanceOpt');
  String get enterOriginDestFirst => tr('enterOriginDestFirst');
  String get optimizeRoute => tr('optimizeRoute');
  String get tripStatusTitle => tr('tripStatusTitle');
  String get history => tr('history');
  String get chooseTimePeriod => tr('chooseTimePeriod');
  String get generateReport => tr('generateReport');
  String get liveFleetTracking => tr('liveFleetTracking');
  String get seeEveryTruck => tr('seeEveryTruck');
  String get recenter => tr('recenter');
  String get locating => tr('locating');
  String get gettingLocation => tr('gettingLocation');
  String get noLiveTrips => tr('noLiveTrips');
  String get pickLocation => tr('pickLocation');
  String get useThisLocation => tr('useThisLocation');
  String get pickAMapLocation => tr('pickAMapLocation');
  String get couldNotOpenMaps => tr('couldNotOpenMaps');
  String get amountLabel => tr('amountLabel');
  String get categoryLabel => tr('categoryLabel');
  String get typeToSearch => tr('typeToSearch');
  String get chooseCategory => tr('chooseCategory');
  String get pendingValue => tr('pendingValue');

  // ---- Phase 2b (extra keys) ----
  String get noActiveTrips => tr('noActiveTrips');
  String get noTripHistory => tr('noTripHistory');
  String get locationUnavailable => tr('locationUnavailable');
  String get couldNotLoadTrip => tr('couldNotLoadTrip');
  String get inVisitOrder => tr('inVisitOrder');
  String get navigate => tr('navigate');
  String get fieldRequired => tr('fieldRequired');
  String get enterValidAmount => tr('enterValidAmount');
  String get tripsWord => tr('tripsWord');
  String get baseWord => tr('baseWord');
  String get bonusWord => tr('bonusWord');
  String get deductionWord => tr('deductionWord');
  String get enterCurrentPassword => tr('enterCurrentPassword');
  String get couldNotChangePassword => tr('couldNotChangePassword');
  String get catFuel => tr('catFuel');
  String get catToll => tr('catToll');
  String get catFood => tr('catFood');
  String get catMaintenance => tr('catMaintenance');
  String get catOther => tr('catOther');
  String get vtTruck => tr('vtTruck');
  String get vtVan => tr('vtVan');
  String get vtBike => tr('vtBike');
  String get vtCar => tr('vtCar');
  String get vtOther => tr('vtOther');
  String get vsActive => tr('vsActive');
  String get vsMaintenance => tr('vsMaintenance');
  String get vsInactive => tr('vsInactive');
  String get appTagline => tr('appTagline');
  String get signInSubtitleLong => tr('signInSubtitleLong');
  String get registrationFailed => tr('registrationFailed');
  String get setUpYourCompany => tr('setUpYourCompany');
  String get accountSetupMinute => tr('accountSetupMinute');
  String get sectionCompany => tr('sectionCompany');
  String get sectionYourRole => tr('sectionYourRole');
  String get sectionYourDetails => tr('sectionYourDetails');
  String get enterCompanyName => tr('enterCompanyName');
  String get enterFullName => tr('enterFullName');
  String get roleAdmin => tr('roleAdmin');
  String get roleDriver => tr('roleDriver');
  String get roleEmployee => tr('roleEmployee');
  String get roleAdminSub => tr('roleAdminSub');
  String get roleDriverSub => tr('roleDriverSub');
  String get roleEmployeeSub => tr('roleEmployeeSub');
  String get couldNotSendCode => tr('couldNotSendCode');
  String get forgotSubtitle => tr('forgotSubtitle');
  String get couldNotResetPassword => tr('couldNotResetPassword');
  String get couldNotResendCode => tr('couldNotResendCode');
  String get codeSentEmail => tr('codeSentEmail');
  String get codeSentMobile => tr('codeSentMobile');
  String get sending => tr('sending');
  String get resendCode => tr('resendCode');

  // ---- Admin screens (batch 2) ----
  String get couldNotAddDriver => tr('couldNotAddDriver');
  String get couldNotDeleteDriver => tr('couldNotDeleteDriver');
  String get couldNotSaveEarning => tr('couldNotSaveEarning');
  String get couldNotUpdateDriverStatus => tr('couldNotUpdateDriverStatus');
  String get driverDeleteExplain => tr('driverDeleteExplain');
  String get enterDriverName => tr('enterDriverName');
  String get loadingDrivers => tr('loadingDrivers');
  String get noTripsInStatus => tr('noTripsInStatus');
  String get tapCardHint => tr('tapCardHint');
  String get totalLower => tr('totalLower');
  String get wasDeleted => tr('wasDeleted');

  // ---- Admin/map/reports (batch 3) ----
  String get addWaypointsHint => tr('addWaypointsHint');
  String get adminExpenseApprovedNote => tr('adminExpenseApprovedNote');
  String get capacityWord => tr('capacityWord');
  String get change => tr('change');
  String get couldNotAssignTrip => tr('couldNotAssignTrip');
  String get couldNotGetLocation => tr('couldNotGetLocation');
  String get couldNotOptimize => tr('couldNotOptimize');
  String get devIdle => tr('devIdle');
  String get devOffline => tr('devOffline');
  String get devParked => tr('devParked');
  String get devRunning => tr('devRunning');
  String get deviceIdHint => tr('deviceIdHint');
  String get enterDeviceIdVehicle => tr('enterDeviceIdVehicle');
  String get expApproved => tr('expApproved');
  String get expPending => tr('expPending');
  String get expRejected => tr('expRejected');
  String get fuel => tr('fuel');
  String get gpsRegisteredNoLoc => tr('gpsRegisteredNoLoc');
  String get lastGeneratedOn => tr('lastGeneratedOn');
  String get live => tr('live');
  String get locationPermissionOff => tr('locationPermissionOff');
  String get locationPinned => tr('locationPinned');
  String get locationPinnedTapChange => tr('locationPinnedTapChange');
  String get mapLocationOptionalNote => tr('mapLocationOptionalNote');
  String get minDrive => tr('minDrive');
  String get noActiveVehicles => tr('noActiveVehicles');
  String get noActiveVehiclesHint => tr('noActiveVehiclesHint');
  String get noDriversAvailable => tr('noDriversAvailable');
  String get noGpsDevices => tr('noGpsDevices');
  String get noLocationPinned => tr('noLocationPinned');
  String get noLocationPinnedYet => tr('noLocationPinnedYet');
  String get noReportsMatch => tr('noReportsMatch');
  String get noReportsYet => tr('noReportsYet');
  String get notGeneratedYet => tr('notGeneratedYet');
  String get online => tr('online');
  String get openLabel => tr('openLabel');
  String get optimizing => tr('optimizing');
  String get paidOut => tr('paidOut');
  String get pendingPayout => tr('pendingPayout');
  String get perMonthly => tr('perMonthly');
  String get perWeekly => tr('perWeekly');
  String get perYearly => tr('perYearly');
  String get pickOnMap => tr('pickOnMap');
  String get pinnedOnMap => tr('pinnedOnMap');
  String get reconnecting => tr('reconnecting');
  String get reportDownloaded => tr('reportDownloaded');
  String get reportGenerated => tr('reportGenerated');
  String get reportWord => tr('reportWord');
  String get rptEarningsDesc => tr('rptEarningsDesc');
  String get rptEarningsLabel => tr('rptEarningsLabel');
  String get rptExpensesDesc => tr('rptExpensesDesc');
  String get rptExpensesLabel => tr('rptExpensesLabel');
  String get rptTripsDesc => tr('rptTripsDesc');
  String get rptTripsLabel => tr('rptTripsLabel');
  String get rptVehiclesDesc => tr('rptVehiclesDesc');
  String get rptVehiclesLabel => tr('rptVehiclesLabel');
  String get savedToDownloads => tr('savedToDownloads');
  String get searchDriverHint => tr('searchDriverHint');
  String get searchVehicleHint => tr('searchVehicleHint');
  String get shareLabel => tr('shareLabel');
  String get snapshot => tr('snapshot');
  String get speed => tr('speed');
  String get tabRecentReports => tr('tabRecentReports');
  String get tabReportsList => tr('tabReportsList');
  String get tapPlusLinkGps => tr('tapPlusLinkGps');
  String get tapToSet => tr('tapToSet');
  String get totalWord => tr('totalWord');
  String get unlinkDevice => tr('unlinkDevice');
  String get updated => tr('updated');
  String get useAddEarningHint => tr('useAddEarningHint');
  String get useAddExpenseHint => tr('useAddExpenseHint');
  String get waitingGps => tr('waitingGps');

  /// Localized report TYPE label (maps ReportType.name; enum unchanged).
  String reportTypeLabel(String name) {
    switch (name) {
      case 'trips':
        return rptTripsLabel;
      case 'expenses':
        return rptExpensesLabel;
      case 'earnings':
        return rptEarningsLabel;
      default:
        return rptVehiclesLabel;
    }
  }

  /// Localized report TYPE description (maps ReportType.name).
  String reportTypeDesc(String name) {
    switch (name) {
      case 'trips':
        return rptTripsDesc;
      case 'expenses':
        return rptExpensesDesc;
      case 'earnings':
        return rptEarningsDesc;
      default:
        return rptVehiclesDesc;
    }
  }

  /// Localized report PERIOD label (maps ReportPeriod.name).
  String reportPeriodLabel(String name) {
    switch (name) {
      case 'weekly':
        return perWeekly;
      case 'monthly':
        return perMonthly;
      default:
        return perYearly;
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  /// Localized strings for the active locale. Usage: `context.l10n.startTrip`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}