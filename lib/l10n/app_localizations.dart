import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ro'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'Carzon'**
  String get appName;

  /// No description provided for @commonRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get commonDelete;

  /// No description provided for @commonSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get commonSignIn;

  /// No description provided for @commonSignOut.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get commonSignOut;

  /// No description provided for @commonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Обязательно'**
  String get commonRequired;

  /// No description provided for @commonComingSoon.
  ///
  /// In ru, this message translates to:
  /// **'Скоро'**
  String get commonComingSoon;

  /// No description provided for @commonKilometersShort.
  ///
  /// In ru, this message translates to:
  /// **'км'**
  String get commonKilometersShort;

  /// No description provided for @routeNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Страница не найдена: {uri}'**
  String routeNotFound(String uri);

  /// No description provided for @listingsAppBarTitle.
  ///
  /// In ru, this message translates to:
  /// **'Carzon'**
  String get listingsAppBarTitle;

  /// No description provided for @listingsTooltipSell.
  ///
  /// In ru, this message translates to:
  /// **'Подать объявление'**
  String get listingsTooltipSell;

  /// No description provided for @listingsTooltipMyListings.
  ///
  /// In ru, this message translates to:
  /// **'Мои объявления'**
  String get listingsTooltipMyListings;

  /// No description provided for @listingsTooltipFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get listingsTooltipFavorites;

  /// No description provided for @listingsTooltipProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get listingsTooltipProfile;

  /// No description provided for @catalogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Каталог авто'**
  String get catalogTitle;

  /// No description provided for @catalogSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Подберите автомобиль в Приднестровье и Молдове'**
  String get catalogSubtitle;

  /// No description provided for @regionFilterLabel.
  ///
  /// In ru, this message translates to:
  /// **'Регион'**
  String get regionFilterLabel;

  /// No description provided for @navListings.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get navListings;

  /// No description provided for @navFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get navFavorites;

  /// No description provided for @navSell.
  ///
  /// In ru, this message translates to:
  /// **'Подать'**
  String get navSell;

  /// No description provided for @navMyListings.
  ///
  /// In ru, this message translates to:
  /// **'Мои'**
  String get navMyListings;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navProfile;

  /// No description provided for @navMenu.
  ///
  /// In ru, this message translates to:
  /// **'Меню'**
  String get navMenu;

  /// No description provided for @menuTitle.
  ///
  /// In ru, this message translates to:
  /// **'Меню'**
  String get menuTitle;

  /// No description provided for @menuAccount.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get menuAccount;

  /// No description provided for @menuSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get menuSettings;

  /// No description provided for @listingsLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить объявления.'**
  String get listingsLoadFailed;

  /// No description provided for @listingsLoadMoreFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить ещё объявления.'**
  String get listingsLoadMoreFailed;

  /// No description provided for @listingsLoadingMore.
  ///
  /// In ru, this message translates to:
  /// **'Загружаем ещё объявления…'**
  String get listingsLoadingMore;

  /// No description provided for @listingsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Подходящих объявлений не найдено.'**
  String get listingsEmpty;

  /// No description provided for @listingsSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск объявлений'**
  String get listingsSearchHint;

  /// No description provided for @listingsSearchClearTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Очистить поиск'**
  String get listingsSearchClearTooltip;

  /// No description provided for @listingsDiscoveryFilterRemoveTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Убрать фильтр'**
  String get listingsDiscoveryFilterRemoveTooltip;

  /// No description provided for @listingsFiltersTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get listingsFiltersTooltip;

  /// No description provided for @catalogBrowseFilterBellTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Оповещения по этому фильтру'**
  String get catalogBrowseFilterBellTooltip;

  /// No description provided for @catalogBrowseFilterBellFilterChipSemantics.
  ///
  /// In ru, this message translates to:
  /// **'Активны оповещения по сохранённому фильтру, совпадающему с текущими условиями поиска'**
  String get catalogBrowseFilterBellFilterChipSemantics;

  /// No description provided for @catalogBrowseFilterBellTooBroad.
  ///
  /// In ru, this message translates to:
  /// **'Уточните фильтр (поиск, марка, параметры или регион), затем сохраните оповещение — базовый каталог без условий слишком широкий.'**
  String get catalogBrowseFilterBellTooBroad;

  /// No description provided for @catalogBrowseFilterAlertTooBroadInlineTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уточните фильтр, чтобы сохранить оповещение.'**
  String get catalogBrowseFilterAlertTooBroadInlineTitle;

  /// No description provided for @catalogBrowseFilterAlertTooBroadInlineBody.
  ///
  /// In ru, this message translates to:
  /// **'Базовый каталог без условий слишком широкий.'**
  String get catalogBrowseFilterAlertTooBroadInlineBody;

  /// No description provided for @catalogBrowseFilterBellEnabledSnack.
  ///
  /// In ru, this message translates to:
  /// **'Оповещения по этому фильтру включены.'**
  String get catalogBrowseFilterBellEnabledSnack;

  /// No description provided for @catalogBrowseFilterBellDisabledSnack.
  ///
  /// In ru, this message translates to:
  /// **'Оповещения по фильтру выключены.'**
  String get catalogBrowseFilterBellDisabledSnack;

  /// Tooltip + a11y label for the in-sheet bell when the current draft matches a saved alert row but delivery is not fully enabled. Concise, product-friendly copy that hints at tap-to-remove (toggle-off) semantics. Replaces the previous technical 'push disabled in this build' inline banner — the bell colour + tooltip are now the only saved/off surface.
  ///
  /// In ru, this message translates to:
  /// **'Оповещение сохранено. Нажмите, чтобы удалить.'**
  String get catalogBrowseFilterBellSavedDeliveryUnavailableTooltip;

  /// Tooltip + a11y label for the in-sheet bell when no saved alert matches the current draft. Tap creates/saves the alert (and, where push is enabled, attempts to enable delivery).
  ///
  /// In ru, this message translates to:
  /// **'Включить оповещения по этому фильтру.'**
  String get catalogBrowseFilterBellInactiveTooltip;

  /// Tooltip + a11y label for the in-sheet bell when delivery is fully enabled for the matching saved alert. Tap clears the saved alert (which also disables delivery on the row).
  ///
  /// In ru, this message translates to:
  /// **'Оповещения включены. Нажмите, чтобы выключить.'**
  String get catalogBrowseFilterBellActiveTooltip;

  /// No description provided for @listingsEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Объявления не найдены'**
  String get listingsEmptyTitle;

  /// No description provided for @listingsEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'В этом разделе пока нет активных объявлений.'**
  String get listingsEmptyBody;

  /// No description provided for @listingsEmptyFilteredBody.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте изменить поиск или фильтры.'**
  String get listingsEmptyFilteredBody;

  /// No description provided for @listingsEmptyBodyTypeFilterNote.
  ///
  /// In ru, this message translates to:
  /// **'Объявления без указанного типа кузова не показываются в фильтрах по кузову. Продавец может добавить тип при редактировании объявления.'**
  String get listingsEmptyBodyTypeFilterNote;

  /// No description provided for @listingsEmptyResetFilters.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить фильтры'**
  String get listingsEmptyResetFilters;

  /// No description provided for @listingsBodyChipAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get listingsBodyChipAll;

  /// No description provided for @listingBodyTypeSedan.
  ///
  /// In ru, this message translates to:
  /// **'Седан'**
  String get listingBodyTypeSedan;

  /// No description provided for @listingBodyTypeHatchback.
  ///
  /// In ru, this message translates to:
  /// **'Хэтчбек'**
  String get listingBodyTypeHatchback;

  /// No description provided for @listingBodyTypeWagon.
  ///
  /// In ru, this message translates to:
  /// **'Универсал'**
  String get listingBodyTypeWagon;

  /// No description provided for @listingBodyTypeSuv.
  ///
  /// In ru, this message translates to:
  /// **'SUV'**
  String get listingBodyTypeSuv;

  /// No description provided for @listingBodyTypeCoupe.
  ///
  /// In ru, this message translates to:
  /// **'Купе'**
  String get listingBodyTypeCoupe;

  /// No description provided for @listingBodyTypeConvertible.
  ///
  /// In ru, this message translates to:
  /// **'Кабриолет'**
  String get listingBodyTypeConvertible;

  /// No description provided for @listingBodyTypeMinivan.
  ///
  /// In ru, this message translates to:
  /// **'Минивэн'**
  String get listingBodyTypeMinivan;

  /// No description provided for @listingBodyTypePickup.
  ///
  /// In ru, this message translates to:
  /// **'Пикап'**
  String get listingBodyTypePickup;

  /// No description provided for @listingBodyTypeVan.
  ///
  /// In ru, this message translates to:
  /// **'Фургон'**
  String get listingBodyTypeVan;

  /// No description provided for @listingBodyTypeOther.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get listingBodyTypeOther;

  /// No description provided for @listingBodyTypeNotSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Не указано'**
  String get listingBodyTypeNotSpecified;

  /// No description provided for @listingBodyTypeSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тип кузова'**
  String get listingBodyTypeSectionTitle;

  /// No description provided for @listingBodyTypeSectionSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Для фильтров по типу кузова. Если не подходит — «Другое».'**
  String get listingBodyTypeSectionSubtitle;

  /// No description provided for @regionTransnistria.
  ///
  /// In ru, this message translates to:
  /// **'Приднестровье'**
  String get regionTransnistria;

  /// No description provided for @regionMoldova.
  ///
  /// In ru, this message translates to:
  /// **'Молдова'**
  String get regionMoldova;

  /// No description provided for @regionBoth.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get regionBoth;

  /// No description provided for @filtersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get filtersTitle;

  /// No description provided for @filtersDismissTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть фильтры'**
  String get filtersDismissTooltip;

  /// No description provided for @filtersHeaderEyebrow.
  ///
  /// In ru, this message translates to:
  /// **'CARZON · ПОИСК'**
  String get filtersHeaderEyebrow;

  /// No description provided for @filtersSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Подберите параметры поиска'**
  String get filtersSubtitle;

  /// No description provided for @filterMake.
  ///
  /// In ru, this message translates to:
  /// **'Марка'**
  String get filterMake;

  /// No description provided for @filterMakeHint.
  ///
  /// In ru, this message translates to:
  /// **'напр. Volkswagen'**
  String get filterMakeHint;

  /// No description provided for @brandFilterAllSemantics.
  ///
  /// In ru, this message translates to:
  /// **'Все марки'**
  String get brandFilterAllSemantics;

  /// No description provided for @brandFilterBrandSemantics.
  ///
  /// In ru, this message translates to:
  /// **'Марка: {brand}'**
  String brandFilterBrandSemantics(String brand);

  /// No description provided for @filterMinYear.
  ///
  /// In ru, this message translates to:
  /// **'Год от'**
  String get filterMinYear;

  /// No description provided for @filterMaxYear.
  ///
  /// In ru, this message translates to:
  /// **'Год до'**
  String get filterMaxYear;

  /// No description provided for @filterYearRangeInverted.
  ///
  /// In ru, this message translates to:
  /// **'Год «от» не может быть больше года «до».'**
  String get filterYearRangeInverted;

  /// No description provided for @filterYearManufactureSection.
  ///
  /// In ru, this message translates to:
  /// **'Год выпуска'**
  String get filterYearManufactureSection;

  /// No description provided for @filterYearFromShort.
  ///
  /// In ru, this message translates to:
  /// **'От'**
  String get filterYearFromShort;

  /// No description provided for @filterYearToShort.
  ///
  /// In ru, this message translates to:
  /// **'До'**
  String get filterYearToShort;

  /// No description provided for @filterYearAny.
  ///
  /// In ru, this message translates to:
  /// **'Любой'**
  String get filterYearAny;

  /// No description provided for @filterMustBeNumber.
  ///
  /// In ru, this message translates to:
  /// **'Нужно число.'**
  String get filterMustBeNumber;

  /// No description provided for @filterMustBeMaxYear.
  ///
  /// In ru, this message translates to:
  /// **'Должно быть ≤ максимального года.'**
  String get filterMustBeMaxYear;

  /// No description provided for @filterMustBeMinYear.
  ///
  /// In ru, this message translates to:
  /// **'Должно быть ≥ минимального года.'**
  String get filterMustBeMinYear;

  /// No description provided for @filterType.
  ///
  /// In ru, this message translates to:
  /// **'Тип'**
  String get filterType;

  /// No description provided for @typeAny.
  ///
  /// In ru, this message translates to:
  /// **'Любой'**
  String get typeAny;

  /// No description provided for @typeSale.
  ///
  /// In ru, this message translates to:
  /// **'Продажа'**
  String get typeSale;

  /// No description provided for @typeExchange.
  ///
  /// In ru, this message translates to:
  /// **'Обмен'**
  String get typeExchange;

  /// No description provided for @typeBoth.
  ///
  /// In ru, this message translates to:
  /// **'Продажа или обмен'**
  String get typeBoth;

  /// No description provided for @filterClear.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get filterClear;

  /// No description provided for @filterApply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get filterApply;

  /// No description provided for @filterShowCars.
  ///
  /// In ru, this message translates to:
  /// **'Показать авто'**
  String get filterShowCars;

  /// No description provided for @filterSummaryPriceUpTo.
  ///
  /// In ru, this message translates to:
  /// **'до {amount}'**
  String filterSummaryPriceUpTo(String amount);

  /// No description provided for @filterSummaryPriceFrom.
  ///
  /// In ru, this message translates to:
  /// **'от {amount}'**
  String filterSummaryPriceFrom(String amount);

  /// No description provided for @filterSummaryPriceRangePlain.
  ///
  /// In ru, this message translates to:
  /// **'{min}–{max}'**
  String filterSummaryPriceRangePlain(String min, String max);

  /// No description provided for @filterSummaryPriceRangeWithSymbol.
  ///
  /// In ru, this message translates to:
  /// **'{symbol}{min}–{symbol}{max}'**
  String filterSummaryPriceRangeWithSymbol(
    String symbol,
    String min,
    String max,
  );

  /// No description provided for @filterSummaryMileageUpTo.
  ///
  /// In ru, this message translates to:
  /// **'до {amount} км'**
  String filterSummaryMileageUpTo(String amount);

  /// No description provided for @filterSummaryAllListingsInRegionPm.
  ///
  /// In ru, this message translates to:
  /// **'Все объявления в Приднестровье'**
  String get filterSummaryAllListingsInRegionPm;

  /// No description provided for @filterModel.
  ///
  /// In ru, this message translates to:
  /// **'Модель'**
  String get filterModel;

  /// No description provided for @filterModelHint.
  ///
  /// In ru, this message translates to:
  /// **'напр. Golf'**
  String get filterModelHint;

  /// No description provided for @filterPriceFrom.
  ///
  /// In ru, this message translates to:
  /// **'Цена от'**
  String get filterPriceFrom;

  /// No description provided for @filterPriceTo.
  ///
  /// In ru, this message translates to:
  /// **'Цена до'**
  String get filterPriceTo;

  /// No description provided for @filterPriceBudgetHint.
  ///
  /// In ru, this message translates to:
  /// **'Укажите бюджет и валюту объявления.'**
  String get filterPriceBudgetHint;

  /// No description provided for @filterPriceCurrencyLabel.
  ///
  /// In ru, this message translates to:
  /// **'Валюта объявления'**
  String get filterPriceCurrencyLabel;

  /// No description provided for @filterPriceCurrencyAny.
  ///
  /// In ru, this message translates to:
  /// **'Любая'**
  String get filterPriceCurrencyAny;

  /// No description provided for @filterPriceCurrencyUsd.
  ///
  /// In ru, this message translates to:
  /// **'\$'**
  String get filterPriceCurrencyUsd;

  /// No description provided for @filterPriceCurrencyEur.
  ///
  /// In ru, this message translates to:
  /// **'€'**
  String get filterPriceCurrencyEur;

  /// No description provided for @filterPriceChipPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get filterPriceChipPrefix;

  /// No description provided for @filterPriceCurrencyActiveUsd.
  ///
  /// In ru, this message translates to:
  /// **'Валюта: \$'**
  String get filterPriceCurrencyActiveUsd;

  /// No description provided for @filterPriceCurrencyActiveEur.
  ///
  /// In ru, this message translates to:
  /// **'Валюта: €'**
  String get filterPriceCurrencyActiveEur;

  /// No description provided for @filterMaxMileage.
  ///
  /// In ru, this message translates to:
  /// **'Пробег до (км)'**
  String get filterMaxMileage;

  /// No description provided for @filterCity.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get filterCity;

  /// No description provided for @filterCityHint.
  ///
  /// In ru, this message translates to:
  /// **'напр. Тирасполь'**
  String get filterCityHint;

  /// No description provided for @filterSortLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get filterSortLabel;

  /// No description provided for @filterSortNewestFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала новые'**
  String get filterSortNewestFirst;

  /// No description provided for @filterSortPriceLowHigh.
  ///
  /// In ru, this message translates to:
  /// **'Цена: по возрастанию'**
  String get filterSortPriceLowHigh;

  /// No description provided for @filterSortPriceHighLow.
  ///
  /// In ru, this message translates to:
  /// **'Цена: по убыванию'**
  String get filterSortPriceHighLow;

  /// No description provided for @filterSortNewestYear.
  ///
  /// In ru, this message translates to:
  /// **'Сначала новый год'**
  String get filterSortNewestYear;

  /// No description provided for @filterSortLowestMileage.
  ///
  /// In ru, this message translates to:
  /// **'Сначала меньший пробег'**
  String get filterSortLowestMileage;

  /// No description provided for @filterMustBeMaxPrice.
  ///
  /// In ru, this message translates to:
  /// **'Должно быть ≤ максимальной цены.'**
  String get filterMustBeMaxPrice;

  /// No description provided for @filterMustBeMinPrice.
  ///
  /// In ru, this message translates to:
  /// **'Должно быть ≥ минимальной цены.'**
  String get filterMustBeMinPrice;

  /// No description provided for @filtersSummaryDefaultTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройте подбор автомобиля'**
  String get filtersSummaryDefaultTitle;

  /// No description provided for @filtersSummaryDefaultHints.
  ///
  /// In ru, this message translates to:
  /// **'Марка · бюджет · кузов · регион'**
  String get filtersSummaryDefaultHints;

  /// No description provided for @filtersSectionMakeModel.
  ///
  /// In ru, this message translates to:
  /// **'Марка и модель'**
  String get filtersSectionMakeModel;

  /// No description provided for @filtersSectionBudget.
  ///
  /// In ru, this message translates to:
  /// **'Бюджет'**
  String get filtersSectionBudget;

  /// No description provided for @filtersSectionYearMileageCaption.
  ///
  /// In ru, this message translates to:
  /// **'Год и пробег'**
  String get filtersSectionYearMileageCaption;

  /// No description provided for @filtersSectionVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Автомобиль'**
  String get filtersSectionVehicle;

  /// No description provided for @filtersSectionLocation.
  ///
  /// In ru, this message translates to:
  /// **'Локация'**
  String get filtersSectionLocation;

  /// No description provided for @filtersSectionBodyAndDeal.
  ///
  /// In ru, this message translates to:
  /// **'Кузов и сделка'**
  String get filtersSectionBodyAndDeal;

  /// No description provided for @listingDetailsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Объявление'**
  String get listingDetailsTitle;

  /// No description provided for @listingDetailsLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить объявление.'**
  String get listingDetailsLoadFailed;

  /// No description provided for @userErrorNetworkCheckConnection.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте подключение к интернету и попробуйте ещё раз.'**
  String get userErrorNetworkCheckConnection;

  /// No description provided for @userErrorGenericTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так. Попробуйте ещё раз.'**
  String get userErrorGenericTryAgain;

  /// No description provided for @userErrorEmailAlreadyRegistered.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт с таким email уже существует.'**
  String get userErrorEmailAlreadyRegistered;

  /// No description provided for @userErrorWeakPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль слишком простой. Попробуйте более надёжный пароль.'**
  String get userErrorWeakPassword;

  /// No description provided for @userErrorInsufficientPermission.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточно прав для этого действия.'**
  String get userErrorInsufficientPermission;

  /// No description provided for @listingUnavailableOrDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Объявление недоступно или было удалено.'**
  String get listingUnavailableOrDeleted;

  /// No description provided for @userErrorUploadPhotoTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить фото. Попробуйте ещё раз.'**
  String get userErrorUploadPhotoTryAgain;

  /// No description provided for @listingDetailsSpecs.
  ///
  /// In ru, this message translates to:
  /// **'Характеристики'**
  String get listingDetailsSpecs;

  /// No description provided for @listingFieldMake.
  ///
  /// In ru, this message translates to:
  /// **'Марка'**
  String get listingFieldMake;

  /// No description provided for @listingFieldModel.
  ///
  /// In ru, this message translates to:
  /// **'Модель'**
  String get listingFieldModel;

  /// No description provided for @listingFieldYear.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get listingFieldYear;

  /// No description provided for @listingFieldMileage.
  ///
  /// In ru, this message translates to:
  /// **'Пробег'**
  String get listingFieldMileage;

  /// No description provided for @listingFieldType.
  ///
  /// In ru, this message translates to:
  /// **'Тип'**
  String get listingFieldType;

  /// No description provided for @listingFieldCity.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get listingFieldCity;

  /// No description provided for @listingFieldRegion.
  ///
  /// In ru, this message translates to:
  /// **'Регион'**
  String get listingFieldRegion;

  /// No description provided for @listingFieldBodyType.
  ///
  /// In ru, this message translates to:
  /// **'Кузов'**
  String get listingFieldBodyType;

  /// No description provided for @listingFieldPosted.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовано'**
  String get listingFieldPosted;

  /// No description provided for @listingDetailsMetadataAddedOn.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено {date}'**
  String listingDetailsMetadataAddedOn(String date);

  /// No description provided for @listingDetailsMetadataViews.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} просмотр} few{{count} просмотра} many{{count} просмотров} other{{count} просмотров}}'**
  String listingDetailsMetadataViews(int count);

  /// No description provided for @listingDetailsMetadataViewsToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня +{count}'**
  String listingDetailsMetadataViewsToday(int count);

  /// No description provided for @listingFuelType.
  ///
  /// In ru, this message translates to:
  /// **'Топливо'**
  String get listingFuelType;

  /// No description provided for @listingEngineDisplacement.
  ///
  /// In ru, this message translates to:
  /// **'Объём двигателя'**
  String get listingEngineDisplacement;

  /// No description provided for @listingEnginePower.
  ///
  /// In ru, this message translates to:
  /// **'Мощность'**
  String get listingEnginePower;

  /// No description provided for @listingDrivetrain.
  ///
  /// In ru, this message translates to:
  /// **'Привод'**
  String get listingDrivetrain;

  /// No description provided for @listingRegistration.
  ///
  /// In ru, this message translates to:
  /// **'Место регистрации авто'**
  String get listingRegistration;

  /// No description provided for @listingDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get listingDescription;

  /// No description provided for @listingEngineDisplacementHint.
  ///
  /// In ru, this message translates to:
  /// **'Литры, напр. 2.0'**
  String get listingEngineDisplacementHint;

  /// No description provided for @listingEnginePowerHint.
  ///
  /// In ru, this message translates to:
  /// **'Мощность в л.с.'**
  String get listingEnginePowerHint;

  /// No description provided for @listingRegistrationHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: Тирасполь, Кишинёв'**
  String get listingRegistrationHint;

  /// No description provided for @listingRegistrationHelper.
  ///
  /// In ru, this message translates to:
  /// **'По документам автомобиля. Не влияет на регион показа объявления.'**
  String get listingRegistrationHelper;

  /// No description provided for @listingEngineDisplacementLitersSuffix.
  ///
  /// In ru, this message translates to:
  /// **'л'**
  String get listingEngineDisplacementLitersSuffix;

  /// No description provided for @listingEngineDisplacementCcSuffix.
  ///
  /// In ru, this message translates to:
  /// **'см³'**
  String get listingEngineDisplacementCcSuffix;

  /// No description provided for @listingEnginePowerHpSuffix.
  ///
  /// In ru, this message translates to:
  /// **'л.с.'**
  String get listingEnginePowerHpSuffix;

  /// No description provided for @listingFuelTypePetrol.
  ///
  /// In ru, this message translates to:
  /// **'Бензин'**
  String get listingFuelTypePetrol;

  /// No description provided for @listingFuelTypeDiesel.
  ///
  /// In ru, this message translates to:
  /// **'Дизель'**
  String get listingFuelTypeDiesel;

  /// No description provided for @listingFuelTypeHybrid.
  ///
  /// In ru, this message translates to:
  /// **'Гибрид'**
  String get listingFuelTypeHybrid;

  /// No description provided for @listingFuelTypeElectric.
  ///
  /// In ru, this message translates to:
  /// **'Электро'**
  String get listingFuelTypeElectric;

  /// No description provided for @listingFuelTypeLpg.
  ///
  /// In ru, this message translates to:
  /// **'Газ (LPG)'**
  String get listingFuelTypeLpg;

  /// No description provided for @listingFuelTypeCng.
  ///
  /// In ru, this message translates to:
  /// **'Метан (CNG)'**
  String get listingFuelTypeCng;

  /// No description provided for @listingFuelTypeOther.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get listingFuelTypeOther;

  /// No description provided for @listingDrivetrainFwd.
  ///
  /// In ru, this message translates to:
  /// **'Передний'**
  String get listingDrivetrainFwd;

  /// No description provided for @listingDrivetrainRwd.
  ///
  /// In ru, this message translates to:
  /// **'Задний'**
  String get listingDrivetrainRwd;

  /// No description provided for @listingDrivetrainAwd.
  ///
  /// In ru, this message translates to:
  /// **'Полный (AWD)'**
  String get listingDrivetrainAwd;

  /// No description provided for @listingDrivetrainFourWheel.
  ///
  /// In ru, this message translates to:
  /// **'4×4'**
  String get listingDrivetrainFourWheel;

  /// No description provided for @listingTransmission.
  ///
  /// In ru, this message translates to:
  /// **'Коробка передач'**
  String get listingTransmission;

  /// No description provided for @listingTransmissionManual.
  ///
  /// In ru, this message translates to:
  /// **'Механика'**
  String get listingTransmissionManual;

  /// No description provided for @listingTransmissionAutomatic.
  ///
  /// In ru, this message translates to:
  /// **'Автомат'**
  String get listingTransmissionAutomatic;

  /// No description provided for @listingTransmissionCvt.
  ///
  /// In ru, this message translates to:
  /// **'Вариатор'**
  String get listingTransmissionCvt;

  /// No description provided for @listingTransmissionRobotic.
  ///
  /// In ru, this message translates to:
  /// **'Робот'**
  String get listingTransmissionRobotic;

  /// No description provided for @listingTransmissionDualClutch.
  ///
  /// In ru, this message translates to:
  /// **'Робот DCT'**
  String get listingTransmissionDualClutch;

  /// No description provided for @listingTransmissionOther.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get listingTransmissionOther;

  /// No description provided for @listingDetailsDescriptionSection.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get listingDetailsDescriptionSection;

  /// No description provided for @createListingSectionSpecsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'По желанию — помогают в поиске и фильтрах.'**
  String get createListingSectionSpecsSubtitle;

  /// No description provided for @createListingSectionDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get createListingSectionDescription;

  /// No description provided for @createListingSectionDescriptionSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Состояние, комплектация, сервис — своими словами.'**
  String get createListingSectionDescriptionSubtitle;

  /// No description provided for @createListingDescriptionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Текст объявления'**
  String get createListingDescriptionLabel;

  /// No description provided for @createListingDescriptionHint.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите о машине своими словами…'**
  String get createListingDescriptionHint;

  /// No description provided for @editListingDescriptionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Описание объявления'**
  String get editListingDescriptionLabel;

  /// No description provided for @validationEngineDisplacementPositive.
  ///
  /// In ru, this message translates to:
  /// **'Укажите объём больше нуля (литры).'**
  String get validationEngineDisplacementPositive;

  /// No description provided for @validationEnginePowerPositive.
  ///
  /// In ru, this message translates to:
  /// **'Укажите мощность больше нуля (л.с.).'**
  String get validationEnginePowerPositive;

  /// No description provided for @validationRegistrationTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Слишком длинное поле регистрации (макс. 200 символов).'**
  String get validationRegistrationTooLong;

  /// No description provided for @contactSellerSection.
  ///
  /// In ru, this message translates to:
  /// **'Связаться с продавцом'**
  String get contactSellerSection;

  /// No description provided for @contactShowPhone.
  ///
  /// In ru, this message translates to:
  /// **'Показать телефон'**
  String get contactShowPhone;

  /// No description provided for @contactCopyPhone.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать'**
  String get contactCopyPhone;

  /// No description provided for @contactPhoneCopied.
  ///
  /// In ru, this message translates to:
  /// **'Номер скопирован'**
  String get contactPhoneCopied;

  /// No description provided for @contactPublicNotice.
  ///
  /// In ru, this message translates to:
  /// **'Контакты продавца видны в активных объявлениях.'**
  String get contactPublicNotice;

  /// No description provided for @contactTelegram.
  ///
  /// In ru, this message translates to:
  /// **'Telegram'**
  String get contactTelegram;

  /// No description provided for @contactTelegramLabel.
  ///
  /// In ru, this message translates to:
  /// **'Telegram @{username}'**
  String contactTelegramLabel(String username);

  /// No description provided for @contactWhatsapp.
  ///
  /// In ru, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsapp;

  /// No description provided for @contactActionFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть действие.'**
  String get contactActionFailed;

  /// No description provided for @chatLabel.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get chatLabel;

  /// No description provided for @chatNotAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Чат пока недоступен.'**
  String get chatNotAvailable;

  /// No description provided for @messagingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения'**
  String get messagingTitle;

  /// No description provided for @messagingSignInRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы написать продавцу.'**
  String get messagingSignInRequired;

  /// No description provided for @messagingCannotMessageSelf.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя написать самому себе по своему объявлению.'**
  String get messagingCannotMessageSelf;

  /// No description provided for @messagingUnavailableNoSeller.
  ///
  /// In ru, this message translates to:
  /// **'Чат для этого объявления недоступен.'**
  String get messagingUnavailableNoSeller;

  /// No description provided for @messagingLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить переписки.'**
  String get messagingLoadFailed;

  /// No description provided for @messagingSendFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить сообщение. Попробуйте ещё раз.'**
  String get messagingSendFailed;

  /// No description provided for @messagingNetworkError.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте подключение к интернету и попробуйте ещё раз.'**
  String get messagingNetworkError;

  /// No description provided for @messagingServerError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить действие. Попробуйте ещё раз.'**
  String get messagingServerError;

  /// No description provided for @messagingConversationNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Переписка не найдена или у вас нет доступа.'**
  String get messagingConversationNotFound;

  /// No description provided for @messagingInvalidMessage.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте текст сообщения.'**
  String get messagingInvalidMessage;

  /// No description provided for @messagingEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет переписок'**
  String get messagingEmptyTitle;

  /// No description provided for @messagingEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Напишите продавцу с экрана объявления — диалог появится здесь.'**
  String get messagingEmptyBody;

  /// No description provided for @messagingNoPreview.
  ///
  /// In ru, this message translates to:
  /// **'Нет сообщений'**
  String get messagingNoPreview;

  /// No description provided for @messagingThreadEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Начните переписку: задайте вопрос по объявлению или договоритесь о просмотре.'**
  String get messagingThreadEmptyBody;

  /// No description provided for @messagingSupportThreadEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Напишите в поддержку Carzon'**
  String get messagingSupportThreadEmptyTitle;

  /// No description provided for @messagingSupportThreadEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Опишите вопрос, и мы ответим вам в этом чате.'**
  String get messagingSupportThreadEmptyBody;

  /// No description provided for @messagingThreadTitle.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get messagingThreadTitle;

  /// No description provided for @messagingThreadViewListingHint.
  ///
  /// In ru, this message translates to:
  /// **'Открыть объявление'**
  String get messagingThreadViewListingHint;

  /// No description provided for @messagingComposerHint.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение…'**
  String get messagingComposerHint;

  /// No description provided for @messagingSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get messagingSend;

  /// No description provided for @messagingAttachImage.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить фото'**
  String get messagingAttachImage;

  /// No description provided for @messagingAttachmentSourceTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить фото'**
  String get messagingAttachmentSourceTitle;

  /// No description provided for @messagingAttachmentGallery.
  ///
  /// In ru, this message translates to:
  /// **'Галерея'**
  String get messagingAttachmentGallery;

  /// No description provided for @messagingAttachmentCamera.
  ///
  /// In ru, this message translates to:
  /// **'Камера'**
  String get messagingAttachmentCamera;

  /// No description provided for @messagingAttachmentRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get messagingAttachmentRemove;

  /// No description provided for @messagingAttachmentUnsupportedType.
  ///
  /// In ru, this message translates to:
  /// **'Поддерживаются только JPEG и PNG.'**
  String get messagingAttachmentUnsupportedType;

  /// No description provided for @messagingAttachmentTooLarge.
  ///
  /// In ru, this message translates to:
  /// **'Изображение должно быть не больше 10 МБ.'**
  String get messagingAttachmentTooLarge;

  /// No description provided for @messagingAttachmentLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить изображение.'**
  String get messagingAttachmentLoadFailed;

  /// No description provided for @messagingAttachmentPhotoPreview.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get messagingAttachmentPhotoPreview;

  /// No description provided for @messagingCameraInitializing.
  ///
  /// In ru, this message translates to:
  /// **'Подключение камеры…'**
  String get messagingCameraInitializing;

  /// No description provided for @messagingCameraPermissionDenied.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к камере. Разрешите доступ в настройках устройства.'**
  String get messagingCameraPermissionDenied;

  /// No description provided for @messagingCameraUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Камера недоступна на этом устройстве.'**
  String get messagingCameraUnavailable;

  /// No description provided for @messagingCameraCaptureFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сделать снимок. Попробуйте ещё раз.'**
  String get messagingCameraCaptureFailed;

  /// No description provided for @messagingDateToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get messagingDateToday;

  /// No description provided for @messagingDateYesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get messagingDateYesterday;

  /// No description provided for @messagingMessageCopied.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение скопировано'**
  String get messagingMessageCopied;

  /// No description provided for @messagingQuickReplyHint.
  ///
  /// In ru, this message translates to:
  /// **'Быстрые ответы — нажмите, чтобы вставить в поле ввода'**
  String get messagingQuickReplyHint;

  /// No description provided for @messagingQuickReplyStillAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Здравствуйте, объявление актуально?'**
  String get messagingQuickReplyStillAvailable;

  /// No description provided for @messagingQuickReplyWhereToView.
  ///
  /// In ru, this message translates to:
  /// **'Где можно посмотреть автомобиль?'**
  String get messagingQuickReplyWhereToView;

  /// No description provided for @messagingQuickReplyNegotiable.
  ///
  /// In ru, this message translates to:
  /// **'Возможен торг?'**
  String get messagingQuickReplyNegotiable;

  /// No description provided for @messagingQuickReplyWhenCall.
  ///
  /// In ru, this message translates to:
  /// **'Когда удобно созвониться?'**
  String get messagingQuickReplyWhenCall;

  /// No description provided for @messagingListingFallback.
  ///
  /// In ru, this message translates to:
  /// **'Объявление {shortId}'**
  String messagingListingFallback(String shortId);

  /// No description provided for @phoneNotProvided.
  ///
  /// In ru, this message translates to:
  /// **'Телефон не указан'**
  String get phoneNotProvided;

  /// No description provided for @reportListing.
  ///
  /// In ru, this message translates to:
  /// **'Пожаловаться на объявление'**
  String get reportListing;

  /// No description provided for @reportListingDescription.
  ///
  /// In ru, this message translates to:
  /// **'Заметили подозрительную, неверную или недопустимую информацию? Сообщите нам.'**
  String get reportListingDescription;

  /// No description provided for @reportListingMailFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть почтовое приложение.'**
  String get reportListingMailFailed;

  /// No description provided for @formatTypeSale.
  ///
  /// In ru, this message translates to:
  /// **'Продажа'**
  String get formatTypeSale;

  /// No description provided for @formatTypeExchange.
  ///
  /// In ru, this message translates to:
  /// **'Обмен'**
  String get formatTypeExchange;

  /// No description provided for @formatTypeBoth.
  ///
  /// In ru, this message translates to:
  /// **'Продажа или обмен'**
  String get formatTypeBoth;

  /// No description provided for @statusActive.
  ///
  /// In ru, this message translates to:
  /// **'Активно'**
  String get statusActive;

  /// No description provided for @statusHidden.
  ///
  /// In ru, this message translates to:
  /// **'Скрыто'**
  String get statusHidden;

  /// No description provided for @statusSold.
  ///
  /// In ru, this message translates to:
  /// **'Продано'**
  String get statusSold;

  /// No description provided for @statusArchived.
  ///
  /// In ru, this message translates to:
  /// **'В архиве'**
  String get statusArchived;

  /// No description provided for @publicContactNotice.
  ///
  /// In ru, this message translates to:
  /// **'Ваш телефон и выбранные способы связи будут видны в активных объявлениях. Указывайте только те контакты, которыми готовы поделиться публично.'**
  String get publicContactNotice;

  /// No description provided for @createListingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подать объявление'**
  String get createListingTitle;

  /// No description provided for @createListingComposeEyebrow.
  ///
  /// In ru, this message translates to:
  /// **'Новое объявление · Carzon'**
  String get createListingComposeEyebrow;

  /// No description provided for @createListingComposeHeadline.
  ///
  /// In ru, this message translates to:
  /// **'Создайте объявление'**
  String get createListingComposeHeadline;

  /// No description provided for @createListingComposeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Подготовьте карточку автомобиля: фото, характеристики и аккуратные контакты — чтобы покупатель сразу увидел главное.'**
  String get createListingComposeSubtitle;

  /// No description provided for @createListingSectionPhotosLead.
  ///
  /// In ru, this message translates to:
  /// **'Фото и заголовок'**
  String get createListingSectionPhotosLead;

  /// No description provided for @createListingSectionPhotosLeadSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Обложка каталога и необязательный заголовок.'**
  String get createListingSectionPhotosLeadSubtitle;

  /// No description provided for @createListingSectionVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Об автомобиле'**
  String get createListingSectionVehicle;

  /// No description provided for @createListingSectionVehicleSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Город, марка, модель, год и характеристики.'**
  String get createListingSectionVehicleSubtitle;

  /// No description provided for @createListingSectionDeal.
  ///
  /// In ru, this message translates to:
  /// **'Сделка и рынок'**
  String get createListingSectionDeal;

  /// No description provided for @createListingSectionDealSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Тип сделки и регион, где объявление будет видно.'**
  String get createListingSectionDealSubtitle;

  /// No description provided for @createListingSectionPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена и пробег'**
  String get createListingSectionPrice;

  /// No description provided for @createListingSectionPriceSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Валюта и фактические цифры.'**
  String get createListingSectionPriceSubtitle;

  /// No description provided for @createListingSectionPublish.
  ///
  /// In ru, this message translates to:
  /// **'Контакты и публикация'**
  String get createListingSectionPublish;

  /// No description provided for @createListingSectionPublishSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Контакты будут видны в активном объявлении.'**
  String get createListingSectionPublishSubtitle;

  /// No description provided for @createListingPublishKicker.
  ///
  /// In ru, this message translates to:
  /// **'Финальный шаг'**
  String get createListingPublishKicker;

  /// No description provided for @createListingSignInRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы подать объявление.'**
  String get createListingSignInRequired;

  /// No description provided for @fieldTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заголовок'**
  String get fieldTitle;

  /// No description provided for @fieldTitleOptional.
  ///
  /// In ru, this message translates to:
  /// **'Заголовок (необязательно)'**
  String get fieldTitleOptional;

  /// No description provided for @listingTitleFallbackDefault.
  ///
  /// In ru, this message translates to:
  /// **'Объявление о продаже автомобиля'**
  String get listingTitleFallbackDefault;

  /// No description provided for @fieldMake.
  ///
  /// In ru, this message translates to:
  /// **'Марка'**
  String get fieldMake;

  /// No description provided for @fieldModel.
  ///
  /// In ru, this message translates to:
  /// **'Модель'**
  String get fieldModel;

  /// No description provided for @fieldYear.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get fieldYear;

  /// No description provided for @fieldPriceEur.
  ///
  /// In ru, this message translates to:
  /// **'Цена (EUR)'**
  String get fieldPriceEur;

  /// No description provided for @createListingMediaTitle.
  ///
  /// In ru, this message translates to:
  /// **'Фото объявления'**
  String get createListingMediaTitle;

  /// No description provided for @createListingMediaSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Первое фото станет главным на карточке.'**
  String get createListingMediaSubtitle;

  /// No description provided for @createListingMediaHeroEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы добавить фото объявления. До девяти снимков — по одному из галереи.'**
  String get createListingMediaHeroEmptyHint;

  /// No description provided for @createListingMediaCoverHint.
  ///
  /// In ru, this message translates to:
  /// **'Обложка каталога'**
  String get createListingMediaCoverHint;

  /// No description provided for @createListingHeroEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте фотографии автомобиля'**
  String get createListingHeroEmptyTitle;

  /// No description provided for @createListingHeroEmptyDetail.
  ///
  /// In ru, this message translates to:
  /// **'До девяти снимков из галереи. Начните с удачного ракурса.'**
  String get createListingHeroEmptyDetail;

  /// No description provided for @createListingAddPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Добавить фото'**
  String get createListingAddPhoto;

  /// No description provided for @createListingAddMorePhotos.
  ///
  /// In ru, this message translates to:
  /// **'Ещё фото'**
  String get createListingAddMorePhotos;

  /// No description provided for @createListingMaxPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Можно не больше {count} фотографий.'**
  String createListingMaxPhotos(int count);

  /// No description provided for @createListingRemovePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get createListingRemovePhoto;

  /// No description provided for @createListingCoverBadge.
  ///
  /// In ru, this message translates to:
  /// **'Обложка'**
  String get createListingCoverBadge;

  /// No description provided for @createListingPriceAmount.
  ///
  /// In ru, this message translates to:
  /// **'Цена — сумма'**
  String get createListingPriceAmount;

  /// No description provided for @createListingCurrency.
  ///
  /// In ru, this message translates to:
  /// **'Валюта'**
  String get createListingCurrency;

  /// No description provided for @currencyCodeEur.
  ///
  /// In ru, this message translates to:
  /// **'EUR'**
  String get currencyCodeEur;

  /// No description provided for @currencyCodeUsd.
  ///
  /// In ru, this message translates to:
  /// **'USD'**
  String get currencyCodeUsd;

  /// No description provided for @createListingBrandLabel.
  ///
  /// In ru, this message translates to:
  /// **'Марка'**
  String get createListingBrandLabel;

  /// No description provided for @createListingChooseBrand.
  ///
  /// In ru, this message translates to:
  /// **'Выберите марку'**
  String get createListingChooseBrand;

  /// No description provided for @createListingBrandOther.
  ///
  /// In ru, this message translates to:
  /// **'Другая'**
  String get createListingBrandOther;

  /// No description provided for @createListingCustomBrandHint.
  ///
  /// In ru, this message translates to:
  /// **'Укажите марку'**
  String get createListingCustomBrandHint;

  /// No description provided for @createListingYearLabel.
  ///
  /// In ru, this message translates to:
  /// **'Год выпуска'**
  String get createListingYearLabel;

  /// No description provided for @createListingChooseYear.
  ///
  /// In ru, this message translates to:
  /// **'Выберите год'**
  String get createListingChooseYear;

  /// No description provided for @createListingPhotosUploadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить фото. Попробуйте ещё раз.'**
  String get createListingPhotosUploadFailed;

  /// No description provided for @commonDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get commonDone;

  /// No description provided for @createListingSearchBrandsHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск марки'**
  String get createListingSearchBrandsHint;

  /// No description provided for @fieldMileageKm.
  ///
  /// In ru, this message translates to:
  /// **'Пробег (км)'**
  String get fieldMileageKm;

  /// No description provided for @fieldType.
  ///
  /// In ru, this message translates to:
  /// **'Тип'**
  String get fieldType;

  /// No description provided for @fieldRegion.
  ///
  /// In ru, this message translates to:
  /// **'Регион показа'**
  String get fieldRegion;

  /// No description provided for @fieldRegionHelper.
  ///
  /// In ru, this message translates to:
  /// **'Где будет показываться объявление.'**
  String get fieldRegionHelper;

  /// No description provided for @fieldCity.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get fieldCity;

  /// No description provided for @fieldPhone.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона'**
  String get fieldPhone;

  /// No description provided for @fieldPhoneHint.
  ///
  /// In ru, this message translates to:
  /// **'+373 ...'**
  String get fieldPhoneHint;

  /// No description provided for @fieldTelegram.
  ///
  /// In ru, this message translates to:
  /// **'Ник в Telegram (необязательно)'**
  String get fieldTelegram;

  /// No description provided for @fieldTelegramHint.
  ///
  /// In ru, this message translates to:
  /// **'@username'**
  String get fieldTelegramHint;

  /// No description provided for @whatsappToggle.
  ///
  /// In ru, this message translates to:
  /// **'WhatsApp доступен по этому номеру'**
  String get whatsappToggle;

  /// No description provided for @regionRequired.
  ///
  /// In ru, this message translates to:
  /// **'Выберите регион.'**
  String get regionRequired;

  /// No description provided for @validationRequired.
  ///
  /// In ru, this message translates to:
  /// **'Обязательно'**
  String get validationRequired;

  /// No description provided for @validationYearRange.
  ///
  /// In ru, this message translates to:
  /// **'1900–{maxYear}'**
  String validationYearRange(int maxYear);

  /// No description provided for @validationPositive.
  ///
  /// In ru, this message translates to:
  /// **'Должно быть > 0'**
  String get validationPositive;

  /// No description provided for @validationNonNegative.
  ///
  /// In ru, this message translates to:
  /// **'Должно быть ≥ 0'**
  String get validationNonNegative;

  /// No description provided for @coverPhotoOptional.
  ///
  /// In ru, this message translates to:
  /// **'Обложка (необязательно)'**
  String get coverPhotoOptional;

  /// No description provided for @coverRemoveTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get coverRemoveTooltip;

  /// No description provided for @coverAddPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Добавить фото'**
  String get coverAddPhoto;

  /// No description provided for @publishListing.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать'**
  String get publishListing;

  /// No description provided for @listingCreated.
  ///
  /// In ru, this message translates to:
  /// **'Объявление создано.'**
  String get listingCreated;

  /// No description provided for @listingCreateFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать объявление.'**
  String get listingCreateFailed;

  /// No description provided for @imageLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить изображение. Попробуйте ещё раз.'**
  String get imageLoadFailed;

  /// No description provided for @coverUploadFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить фото обложки. Попробуйте ещё раз.'**
  String get coverUploadFailedRetry;

  /// No description provided for @listingCreateFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать объявление. Попробуйте ещё раз.'**
  String get listingCreateFailedRetry;

  /// No description provided for @imagePickerLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выбрать фото. Попробуйте другое изображение.'**
  String get imagePickerLoadFailed;

  /// No description provided for @listingCreateSessionExpired.
  ///
  /// In ru, this message translates to:
  /// **'Сессия истекла или доступ запрещён. Войдите снова и повторите попытку.'**
  String get listingCreateSessionExpired;

  /// No description provided for @listingCreateServiceUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Сервис временно недоступен. Попробуйте позже.'**
  String get listingCreateServiceUnavailable;

  /// No description provided for @listingCreateVinInvalidServer.
  ///
  /// In ru, this message translates to:
  /// **'VIN-код некорректен. Проверьте 17 символов или оставьте поле пустым.'**
  String get listingCreateVinInvalidServer;

  /// No description provided for @listingCreateRpcNotReady.
  ///
  /// In ru, this message translates to:
  /// **'Сервер ещё не готов принять новые данные объявления. Попробуйте позже или обновите приложение.'**
  String get listingCreateRpcNotReady;

  /// No description provided for @listingCreatePermissionDenied.
  ///
  /// In ru, this message translates to:
  /// **'Нет прав для создания объявления. Войдите в аккаунт ещё раз.'**
  String get listingCreatePermissionDenied;

  /// No description provided for @listingCreateCheckConstraint.
  ///
  /// In ru, this message translates to:
  /// **'Некоторые данные объявления имеют некорректный формат. Проверьте поля и попробуйте снова.'**
  String get listingCreateCheckConstraint;

  /// No description provided for @editListingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать объявление'**
  String get editListingTitle;

  /// No description provided for @editListingLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить объявление. Попробуйте ещё раз.'**
  String get editListingLoadFailed;

  /// No description provided for @listingUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Объявление обновлено.'**
  String get listingUpdated;

  /// No description provided for @listingUpdateFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить объявление. Попробуйте ещё раз.'**
  String get listingUpdateFailedRetry;

  /// No description provided for @notAllowedEdit.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет прав на редактирование этого объявления.'**
  String get notAllowedEdit;

  /// No description provided for @checkDetailsAndRetry.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте данные объявления и попробуйте ещё раз.'**
  String get checkDetailsAndRetry;

  /// No description provided for @coverUpdateFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить фото обложки. Попробуйте ещё раз.'**
  String get coverUpdateFailedRetry;

  /// No description provided for @coverPhotoLabel.
  ///
  /// In ru, this message translates to:
  /// **'Обложка'**
  String get coverPhotoLabel;

  /// No description provided for @coverChangePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Изменить фото'**
  String get coverChangePhoto;

  /// No description provided for @coverCancelChange.
  ///
  /// In ru, this message translates to:
  /// **'Отменить изменение'**
  String get coverCancelChange;

  /// No description provided for @coverCancelRemoval.
  ///
  /// In ru, this message translates to:
  /// **'Отменить удаление'**
  String get coverCancelRemoval;

  /// No description provided for @coverReplacePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Заменить фото'**
  String get coverReplacePhoto;

  /// No description provided for @coverRemovePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get coverRemovePhoto;

  /// No description provided for @coverWillBeRemovedNotice.
  ///
  /// In ru, this message translates to:
  /// **'Фото обложки будет удалено после сохранения.'**
  String get coverWillBeRemovedNotice;

  /// No description provided for @coverWillBeReplacedNotice.
  ///
  /// In ru, this message translates to:
  /// **'Новое фото будет загружено после сохранения.'**
  String get coverWillBeReplacedNotice;

  /// No description provided for @coverPlaceholderWillBeRemoved.
  ///
  /// In ru, this message translates to:
  /// **'Обложка будет удалена'**
  String get coverPlaceholderWillBeRemoved;

  /// No description provided for @saveChanges.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get saveChanges;

  /// No description provided for @editListingGalleryReadOnlyHint.
  ///
  /// In ru, this message translates to:
  /// **'Галерея не загрузилась. Фото ниже только для справки; изменить их сейчас нельзя — сохранятся текст и другие поля объявления.'**
  String get editListingGalleryReadOnlyHint;

  /// No description provided for @editListingGalleryReplaceFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить фотографии. Попробуйте ещё раз.'**
  String get editListingGalleryReplaceFailed;

  /// No description provided for @myListingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои объявления'**
  String get myListingsTitle;

  /// No description provided for @myListingsSignInRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы увидеть свои объявления.'**
  String get myListingsSignInRequired;

  /// No description provided for @myListingsLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить ваши объявления.'**
  String get myListingsLoadFailed;

  /// No description provided for @myListingsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Вы ещё не опубликовали ни одного объявления.'**
  String get myListingsEmpty;

  /// No description provided for @myListingsEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'У вас пока нет объявлений'**
  String get myListingsEmptyTitle;

  /// No description provided for @myListingsEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Подайте первое объявление — оно появится здесь после публикации.'**
  String get myListingsEmptyBody;

  /// No description provided for @myListingsSellCta.
  ///
  /// In ru, this message translates to:
  /// **'Подать объявление'**
  String get myListingsSellCta;

  /// No description provided for @myListingActionsTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Действия с объявлением'**
  String get myListingActionsTooltip;

  /// No description provided for @actionEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get actionEdit;

  /// No description provided for @actionReactivate.
  ///
  /// In ru, this message translates to:
  /// **'Активировать'**
  String get actionReactivate;

  /// No description provided for @actionMarkSold.
  ///
  /// In ru, this message translates to:
  /// **'Отметить как проданное'**
  String get actionMarkSold;

  /// No description provided for @actionHide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get actionHide;

  /// No description provided for @actionArchive.
  ///
  /// In ru, this message translates to:
  /// **'В архив'**
  String get actionArchive;

  /// No description provided for @actionDeletePermanently.
  ///
  /// In ru, this message translates to:
  /// **'Удалить навсегда'**
  String get actionDeletePermanently;

  /// No description provided for @deleteDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить объявление?'**
  String get deleteDialogTitle;

  /// No description provided for @deleteDialogBody.
  ///
  /// In ru, this message translates to:
  /// **'Объявление будет безвозвратно удалено из Carzon. Оно перестанет показываться пользователям и исчезнет у всех, кто добавил его в избранное.'**
  String get deleteDialogBody;

  /// No description provided for @notAllowedUpdateStatus.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет прав на обновление этого объявления.'**
  String get notAllowedUpdateStatus;

  /// No description provided for @statusNotSupported.
  ///
  /// In ru, this message translates to:
  /// **'Этот статус объявления не поддерживается.'**
  String get statusNotSupported;

  /// No description provided for @updateStatusFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить статус объявления. Попробуйте ещё раз.'**
  String get updateStatusFailedRetry;

  /// No description provided for @notAllowedDelete.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет прав на удаление этого объявления.'**
  String get notAllowedDelete;

  /// No description provided for @listingNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Это объявление больше не существует.'**
  String get listingNotFound;

  /// No description provided for @deleteListingFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить объявление. Попробуйте ещё раз.'**
  String get deleteListingFailedRetry;

  /// No description provided for @favoritesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get favoritesTitle;

  /// No description provided for @favoritesSignInRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы увидеть избранные объявления.'**
  String get favoritesSignInRequired;

  /// No description provided for @favoritesLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить избранное.'**
  String get favoritesLoadFailed;

  /// No description provided for @favoritesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока ничего не добавлено в избранное.'**
  String get favoritesEmpty;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'В избранном пока пусто'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Добавляйте объявления в избранное, чтобы быстро вернуться к ним позже.'**
  String get favoritesEmptyBody;

  /// No description provided for @favoritesEmptyBrowse.
  ///
  /// In ru, this message translates to:
  /// **'Смотреть объявления'**
  String get favoritesEmptyBrowse;

  /// No description provided for @favoriteAdd.
  ///
  /// In ru, this message translates to:
  /// **'В избранное'**
  String get favoriteAdd;

  /// No description provided for @favoriteRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из избранного'**
  String get favoriteRemove;

  /// No description provided for @favoriteSignInRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы добавлять в избранное.'**
  String get favoriteSignInRequired;

  /// No description provided for @favoriteToggleFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить избранное. Попробуйте ещё раз.'**
  String get favoriteToggleFailed;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get profileTitle;

  /// No description provided for @profileSignInRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы управлять аккаунтом.'**
  String get profileSignInRequired;

  /// No description provided for @profileSignedInFallback.
  ///
  /// In ru, this message translates to:
  /// **'Вы вошли в систему'**
  String get profileSignedInFallback;

  /// No description provided for @profileSignOutFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выйти. Попробуйте ещё раз.'**
  String get profileSignOutFailedRetry;

  /// No description provided for @profileMyListings.
  ///
  /// In ru, this message translates to:
  /// **'Мои объявления'**
  String get profileMyListings;

  /// No description provided for @profileFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get profileFavorites;

  /// No description provided for @profileCreateListing.
  ///
  /// In ru, this message translates to:
  /// **'Подать объявление'**
  String get profileCreateListing;

  /// No description provided for @profileLegal.
  ///
  /// In ru, this message translates to:
  /// **'Условия и конфиденциальность'**
  String get profileLegal;

  /// No description provided for @profileSignOut.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get profileSignOut;

  /// No description provided for @accountAvatarOpenProfileTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт и настройки'**
  String get accountAvatarOpenProfileTooltip;

  /// No description provided for @profileActivitySectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Активность'**
  String get profileActivitySectionTitle;

  /// No description provided for @profileMessagesUnreadStatus.
  ///
  /// In ru, this message translates to:
  /// **'Есть непрочитанные сообщения'**
  String get profileMessagesUnreadStatus;

  /// No description provided for @profileMessagesNoUnreadStatus.
  ///
  /// In ru, this message translates to:
  /// **'Новых сообщений нет'**
  String get profileMessagesNoUnreadStatus;

  /// No description provided for @profileMessagesUnreadCountOverflow.
  ///
  /// In ru, this message translates to:
  /// **'99+'**
  String get profileMessagesUnreadCountOverflow;

  /// No description provided for @profilePublicSellerProfileSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Публичный профиль продавца'**
  String get profilePublicSellerProfileSectionTitle;

  /// No description provided for @profilePublicSellerProfileSectionSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Покупатели видят это в ваших объявлениях и на странице продавца.'**
  String get profilePublicSellerProfileSectionSubtitle;

  /// No description provided for @profilePublicSellerBuyerPreviewCaption.
  ///
  /// In ru, this message translates to:
  /// **'Так вас видят покупатели'**
  String get profilePublicSellerBuyerPreviewCaption;

  /// No description provided for @profileSettingsSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get profileSettingsSectionTitle;

  /// No description provided for @profileOpenSettingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки приложения'**
  String get profileOpenSettingsTitle;

  /// No description provided for @profileOpenSettingsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Язык, тема, уведомления и другое'**
  String get profileOpenSettingsSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsIntro.
  ///
  /// In ru, this message translates to:
  /// **'Управляйте аккаунтом, интерфейсом и уведомлениями в одном месте.'**
  String get settingsIntro;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In ru, this message translates to:
  /// **'Предпочтения'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionPrivacySafety.
  ///
  /// In ru, this message translates to:
  /// **'Конфиденциальность и безопасность'**
  String get settingsSectionPrivacySafety;

  /// No description provided for @settingsSectionSupportLegal.
  ///
  /// In ru, this message translates to:
  /// **'Поддержка и правовая информация'**
  String get settingsSectionSupportLegal;

  /// No description provided for @settingsAccountProfileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль аккаунта'**
  String get settingsAccountProfileTitle;

  /// No description provided for @settingsAccountProfileSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Имя, email и публичный профиль продавца'**
  String get settingsAccountProfileSubtitle;

  /// No description provided for @settingsSignInForAccountSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы управлять паролем и уведомлениями'**
  String get settingsSignInForAccountSubtitle;

  /// No description provided for @settingsPrivacyLegalLinkTitle.
  ///
  /// In ru, this message translates to:
  /// **'Условия и безопасность'**
  String get settingsPrivacyLegalLinkTitle;

  /// No description provided for @settingsPrivacyLegalLinkSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Правовая информация и рекомендации по безопасным сделкам'**
  String get settingsPrivacyLegalLinkSubtitle;

  /// No description provided for @settingsLegalLinkSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Условия использования и политика конфиденциальности'**
  String get settingsLegalLinkSubtitle;

  /// No description provided for @settingsRequestDataTitle.
  ///
  /// In ru, this message translates to:
  /// **'Запросить мои данные'**
  String get settingsRequestDataTitle;

  /// No description provided for @settingsRequestDataSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Связаться с поддержкой по вопросам персональных данных'**
  String get settingsRequestDataSubtitle;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Безвозвратно удалить аккаунт и связанные данные'**
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @settingsSignOutSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта на этом устройстве'**
  String get settingsSignOutSubtitle;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAboutAppName.
  ///
  /// In ru, this message translates to:
  /// **'Carzon'**
  String get settingsAboutAppName;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version} (сборка {build})'**
  String settingsAboutVersion(String version, String build);

  /// No description provided for @settingsAboutVersionLoading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка версии…'**
  String get settingsAboutVersionLoading;

  /// No description provided for @settingsAboutVersionUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Версия недоступна'**
  String get settingsAboutVersionUnavailable;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удаление аккаунта'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarningTitle.
  ///
  /// In ru, this message translates to:
  /// **'Это действие необратимо'**
  String get deleteAccountWarningTitle;

  /// No description provided for @deleteAccountWarningBody.
  ///
  /// In ru, this message translates to:
  /// **'Ваш аккаунт и доступ к приложению будут удалены.\n\n• Активные объявления исчезнут с публичной витрины\n• Избранное, фильтры-оповещения, профиль продавца и настройки push будут удалены\n• Переписки и история сообщений могут быть удалены\n\nПосле подтверждения восстановить аккаунт будет невозможно.'**
  String get deleteAccountWarningBody;

  /// No description provided for @deleteAccountConfirmationKeyword.
  ///
  /// In ru, this message translates to:
  /// **'УДАЛИТЬ'**
  String get deleteAccountConfirmationKeyword;

  /// No description provided for @deleteAccountConfirmationPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы подтвердить, введите «{keyword}»'**
  String deleteAccountConfirmationPrompt(String keyword);

  /// No description provided for @deleteAccountSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт навсегда'**
  String get deleteAccountSubmit;

  /// No description provided for @deleteAccountErrorGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить аккаунт. Попробуйте снова или обратитесь в поддержку.'**
  String get deleteAccountErrorGeneric;

  /// No description provided for @deleteAccountErrorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Нет соединения. Проверьте интернет и попробуйте снова.'**
  String get deleteAccountErrorNetwork;

  /// No description provided for @deleteAccountErrorSession.
  ///
  /// In ru, this message translates to:
  /// **'Сессия истекла. Войдите снова и повторите удаление.'**
  String get deleteAccountErrorSession;

  /// No description provided for @profileChangePasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Изменить пароль'**
  String get profileChangePasswordTitle;

  /// No description provided for @profileChangePasswordSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Обновите пароль для входа в аккаунт.'**
  String get profileChangePasswordSubtitle;

  /// No description provided for @profileDarkThemeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная тема'**
  String get profileDarkThemeTitle;

  /// No description provided for @profileDarkThemeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Переключает интерфейс приложения на тёмный режим.'**
  String get profileDarkThemeSubtitle;

  /// No description provided for @profileLanguageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Язык приложения'**
  String get profileLanguageTitle;

  /// No description provided for @profileLanguageCurrentRussian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get profileLanguageCurrentRussian;

  /// No description provided for @profileLanguageCurrentRomanian.
  ///
  /// In ru, this message translates to:
  /// **'Română'**
  String get profileLanguageCurrentRomanian;

  /// No description provided for @profileLanguageOptionRussian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get profileLanguageOptionRussian;

  /// No description provided for @profileLanguageOptionRomanian.
  ///
  /// In ru, this message translates to:
  /// **'Română'**
  String get profileLanguageOptionRomanian;

  /// No description provided for @profileNotificationsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get profileNotificationsTitle;

  /// No description provided for @profileNotificationsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Push, сообщения и статус доставки (тестирование).'**
  String get profileNotificationsSubtitle;

  /// No description provided for @contactSupport.
  ///
  /// In ru, this message translates to:
  /// **'Связаться с поддержкой'**
  String get contactSupport;

  /// No description provided for @contactSupportSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Напишите нам по вопросам приложения'**
  String get contactSupportSubtitle;

  /// No description provided for @supportConversationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поддержка Carzon'**
  String get supportConversationTitle;

  /// No description provided for @contactSupportOpenFailure.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть чат с поддержкой. Попробуйте позже.'**
  String get contactSupportOpenFailure;

  /// No description provided for @contactSupportSelfFailure.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт поддержки не может открыть этот чат.'**
  String get contactSupportSelfFailure;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsPageIntro.
  ///
  /// In ru, this message translates to:
  /// **'Настройте push на этом устройстве: сообщения в чатах и оповещения по сохранённому фильтру.'**
  String get notificationSettingsPageIntro;

  /// No description provided for @notificationSettingsSignInRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы настроить уведомления.'**
  String get notificationSettingsSignInRequired;

  /// No description provided for @notificationSettingsLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить настройки уведомлений.'**
  String get notificationSettingsLoadFailed;

  /// No description provided for @notificationSettingsSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить. Попробуйте ещё раз.'**
  String get notificationSettingsSaveFailed;

  /// No description provided for @notificationSettingsOsPermissionDenied.
  ///
  /// In ru, this message translates to:
  /// **'Разрешение уведомлений не получено. Включите его в настройках системы, если нужны push.'**
  String get notificationSettingsOsPermissionDenied;

  /// No description provided for @notificationSettingsPushUnavailableInBuild.
  ///
  /// In ru, this message translates to:
  /// **'Push-уведомления недоступны в этой сборке.'**
  String get notificationSettingsPushUnavailableInBuild;

  /// No description provided for @notificationSettingsPushBuildDisabledBanner.
  ///
  /// In ru, this message translates to:
  /// **'Push-уведомления недоступны в этой сборке.'**
  String get notificationSettingsPushBuildDisabledBanner;

  /// No description provided for @notificationSettingsPushBuildDisabledHint.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы протестировать push, используйте сборку с включёнными уведомлениями.'**
  String get notificationSettingsPushBuildDisabledHint;

  /// No description provided for @notificationSettingsMasterOffHint.
  ///
  /// In ru, this message translates to:
  /// **'Включите «Push на этом устройстве», чтобы настроить типы уведомлений ниже.'**
  String get notificationSettingsMasterOffHint;

  /// No description provided for @notificationSettingsStatusCardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Разрешение устройства'**
  String get notificationSettingsStatusCardTitle;

  /// No description provided for @notificationSettingsOsPillAllowed.
  ///
  /// In ru, this message translates to:
  /// **'Разрешены'**
  String get notificationSettingsOsPillAllowed;

  /// No description provided for @notificationSettingsOsPillProvisional.
  ///
  /// In ru, this message translates to:
  /// **'Временные'**
  String get notificationSettingsOsPillProvisional;

  /// No description provided for @notificationSettingsOsPillDenied.
  ///
  /// In ru, this message translates to:
  /// **'Отклонены'**
  String get notificationSettingsOsPillDenied;

  /// No description provided for @notificationSettingsOsPillNotDetermined.
  ///
  /// In ru, this message translates to:
  /// **'Не запрошены'**
  String get notificationSettingsOsPillNotDetermined;

  /// No description provided for @notificationSettingsOsPillUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Недоступны'**
  String get notificationSettingsOsPillUnavailable;

  /// No description provided for @notificationSettingsOsDescriptionAuthorized.
  ///
  /// In ru, this message translates to:
  /// **'Система разрешает показывать уведомления. Push можно включить ниже.'**
  String get notificationSettingsOsDescriptionAuthorized;

  /// No description provided for @notificationSettingsOsDescriptionProvisional.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления разрешены в ограниченном режиме. При необходимости подтвердите полный доступ в настройках системы.'**
  String get notificationSettingsOsDescriptionProvisional;

  /// No description provided for @notificationSettingsOsDescriptionDenied.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления отключены в системе. Включите их в настройках телефона, затем вернитесь сюда.'**
  String get notificationSettingsOsDescriptionDenied;

  /// No description provided for @notificationSettingsOsDescriptionNotDetermined.
  ///
  /// In ru, this message translates to:
  /// **'Разрешение ещё не запрашивалось. Оно будет запрошено, когда вы включите push ниже.'**
  String get notificationSettingsOsDescriptionNotDetermined;

  /// No description provided for @notificationSettingsOsDescriptionUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'В этой сборке push недоступен, поэтому статус разрешения устройства не применяется.'**
  String get notificationSettingsOsDescriptionUnavailable;

  /// No description provided for @notificationSettingsGlobalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Push на этом устройстве'**
  String get notificationSettingsGlobalTitle;

  /// No description provided for @notificationSettingsGlobalSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Включает доставку push на этом устройстве. При выключении отключаются сообщения и оповещения по фильтру.'**
  String get notificationSettingsGlobalSubtitle;

  /// No description provided for @notificationSettingsMessagesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения'**
  String get notificationSettingsMessagesTitle;

  /// No description provided for @notificationSettingsMessagesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Push о новых сообщениях в чатах по объявлениям.'**
  String get notificationSettingsMessagesSubtitle;

  /// No description provided for @notificationSettingsMessagesNeedsGlobal.
  ///
  /// In ru, this message translates to:
  /// **'Сначала включите «Push на этом устройстве».'**
  String get notificationSettingsMessagesNeedsGlobal;

  /// No description provided for @notificationSettingsFilterAlertsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оповещения по фильтру'**
  String get notificationSettingsFilterAlertsTitle;

  /// No description provided for @notificationSettingsFilterAlertsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Push при новых объявлениях, подходящих под сохранённый фильтр.'**
  String get notificationSettingsFilterAlertsSubtitle;

  /// No description provided for @notificationSettingsFilterAlertsNeedsGlobal.
  ///
  /// In ru, this message translates to:
  /// **'Сначала включите «Push на этом устройстве».'**
  String get notificationSettingsFilterAlertsNeedsGlobal;

  /// No description provided for @notificationSettingsFilterAlertsSavedFilterNote.
  ///
  /// In ru, this message translates to:
  /// **'Нужен сохранённый фильтр и включённые оповещения на экране управления фильтром.'**
  String get notificationSettingsFilterAlertsSavedFilterNote;

  /// No description provided for @notificationSettingsFilterAlertsOpenCta.
  ///
  /// In ru, this message translates to:
  /// **'Открыть оповещения по фильтру'**
  String get notificationSettingsFilterAlertsOpenCta;

  /// No description provided for @notificationSettingsDeliveryCardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Статус доставки'**
  String get notificationSettingsDeliveryCardTitle;

  /// No description provided for @notificationSettingsDeliveryDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Функция реализована на сервере и в приложении; финальная доставка на устройствах ещё проверяется.'**
  String get notificationSettingsDeliveryDisclaimer;

  /// No description provided for @notificationSettingsOsStatusAuthorized.
  ///
  /// In ru, this message translates to:
  /// **'Система: уведомления разрешены.'**
  String get notificationSettingsOsStatusAuthorized;

  /// No description provided for @notificationSettingsOsStatusProvisional.
  ///
  /// In ru, this message translates to:
  /// **'Система: временные (provisional) уведомления.'**
  String get notificationSettingsOsStatusProvisional;

  /// No description provided for @notificationSettingsOsStatusDenied.
  ///
  /// In ru, this message translates to:
  /// **'Система: уведомления отклонены.'**
  String get notificationSettingsOsStatusDenied;

  /// No description provided for @notificationSettingsOsStatusNotDetermined.
  ///
  /// In ru, this message translates to:
  /// **'Система: разрешение ещё не запрашивалось или неизвестно.'**
  String get notificationSettingsOsStatusNotDetermined;

  /// No description provided for @profileListingAlertsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оповещения по фильтру'**
  String get profileListingAlertsTitle;

  /// No description provided for @profileListingAlertsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Один фильтр для будущих уведомлений по новым авто.'**
  String get profileListingAlertsSubtitle;

  /// No description provided for @filterAlertEditorEyebrow.
  ///
  /// In ru, this message translates to:
  /// **'CARZON · ОПОВЕЩЕНИЯ'**
  String get filterAlertEditorEyebrow;

  /// No description provided for @filterAlertEditorTitle.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр оповещений'**
  String get filterAlertEditorTitle;

  /// No description provided for @filterAlertEditorSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите параметры авто'**
  String get filterAlertEditorSubtitle;

  /// No description provided for @filterAlertSaveFilterAction.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить фильтр'**
  String get filterAlertSaveFilterAction;

  /// No description provided for @filterAlertProfileRowSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Просмотрите сохранённый фильтр и управляйте доставкой оповещений.'**
  String get filterAlertProfileRowSubtitle;

  /// No description provided for @filterAlertSavedSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр сохранён'**
  String get filterAlertSavedSuccess;

  /// No description provided for @filterAlertUpdatedSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр обновлён'**
  String get filterAlertUpdatedSuccess;

  /// No description provided for @filterAlertSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить фильтр'**
  String get filterAlertSaveFailed;

  /// No description provided for @filterAlertLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить настройки.'**
  String get filterAlertLoadFailed;

  /// No description provided for @filterAlertSignInRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы настроить фильтр для оповещений.'**
  String get filterAlertSignInRequired;

  /// No description provided for @filterAlertApplyBlockedValidation.
  ///
  /// In ru, this message translates to:
  /// **'Исправьте ошибки в фильтре, затем сохраните снова.'**
  String get filterAlertApplyBlockedValidation;

  /// No description provided for @filterAlertResetPersistedSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр для оповещений сброшен'**
  String get filterAlertResetPersistedSuccess;

  /// No description provided for @filterAlertResetFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сбросить фильтр для оповещений.'**
  String get filterAlertResetFailed;

  /// No description provided for @filterAlertNotificationsToggleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления о новых объявлениях'**
  String get filterAlertNotificationsToggleTitle;

  /// No description provided for @filterAlertNotificationsToggleSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'По сохранённому фильтру. Доставка на устройство всё ещё проверяется.'**
  String get filterAlertNotificationsToggleSubtitle;

  /// No description provided for @filterAlertNotificationsNeedsSavedFilter.
  ///
  /// In ru, this message translates to:
  /// **'Сначала сохраните фильтр кнопкой ниже.'**
  String get filterAlertNotificationsNeedsSavedFilter;

  /// No description provided for @filterAlertNotificationsPushDisabled.
  ///
  /// In ru, this message translates to:
  /// **'В этой сборке push недоступен (PUSH_NOTIFICATIONS_ENABLED).'**
  String get filterAlertNotificationsPushDisabled;

  /// No description provided for @filterAlertManagementHeaderEyebrow.
  ///
  /// In ru, this message translates to:
  /// **'CARZON · ОПОВЕЩЕНИЯ'**
  String get filterAlertManagementHeaderEyebrow;

  /// No description provided for @filterAlertManagementSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Управляйте сохранённым фильтром и доставкой оповещений. Уведомления настраиваются в фильтрах каталога.'**
  String get filterAlertManagementSubtitle;

  /// No description provided for @filterAlertManagementDeliveryOnLabel.
  ///
  /// In ru, this message translates to:
  /// **'Доставка оповещений включена'**
  String get filterAlertManagementDeliveryOnLabel;

  /// No description provided for @filterAlertManagementDeliveryOffLabel.
  ///
  /// In ru, this message translates to:
  /// **'Доставка оповещений выключена'**
  String get filterAlertManagementDeliveryOffLabel;

  /// No description provided for @filterAlertManagementCriteriaSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Параметры фильтра'**
  String get filterAlertManagementCriteriaSectionTitle;

  /// No description provided for @filterAlertManagementEditAction.
  ///
  /// In ru, this message translates to:
  /// **'Изменить в каталоге'**
  String get filterAlertManagementEditAction;

  /// No description provided for @filterAlertManagementDisableAction.
  ///
  /// In ru, this message translates to:
  /// **'Выключить оповещения'**
  String get filterAlertManagementDisableAction;

  /// No description provided for @filterAlertManagementClearAction.
  ///
  /// In ru, this message translates to:
  /// **'Удалить сохранённый фильтр'**
  String get filterAlertManagementClearAction;

  /// No description provided for @filterAlertManagementClearConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить сохранённый фильтр?'**
  String get filterAlertManagementClearConfirmTitle;

  /// No description provided for @filterAlertManagementClearConfirmBody.
  ///
  /// In ru, this message translates to:
  /// **'Параметры фильтра будут стёрты. Доставка push также выключится. Действие можно повторить из каталога.'**
  String get filterAlertManagementClearConfirmBody;

  /// No description provided for @filterAlertManagementClearConfirmCta.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get filterAlertManagementClearConfirmCta;

  /// No description provided for @filterAlertManagementEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённого оповещения пока нет'**
  String get filterAlertManagementEmptyTitle;

  /// No description provided for @filterAlertManagementEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Создавайте оповещения в фильтрах каталога: задайте параметры поиска и нажмите колокольчик.'**
  String get filterAlertManagementEmptyBody;

  /// No description provided for @filterAlertManagementGoToCatalog.
  ///
  /// In ru, this message translates to:
  /// **'Перейти в каталог'**
  String get filterAlertManagementGoToCatalog;

  /// No description provided for @filterAlertManagementDeliveryDisabledSnack.
  ///
  /// In ru, this message translates to:
  /// **'Оповещения по фильтру выключены.'**
  String get filterAlertManagementDeliveryDisabledSnack;

  /// No description provided for @filterAlertManagementClearedSnack.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённый фильтр удалён.'**
  String get filterAlertManagementClearedSnack;

  /// No description provided for @filterAlertSummarySearchLabel.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get filterAlertSummarySearchLabel;

  /// No description provided for @filterAlertSummaryMileageLabel.
  ///
  /// In ru, this message translates to:
  /// **'Пробег'**
  String get filterAlertSummaryMileageLabel;

  /// No description provided for @profilePublicSellerNameTitle.
  ///
  /// In ru, this message translates to:
  /// **'Публичное имя продавца'**
  String get profilePublicSellerNameTitle;

  /// No description provided for @profilePublicSellerNameDescription.
  ///
  /// In ru, this message translates to:
  /// **'Это имя будут видеть покупатели в ваших объявлениях и в профиле продавца.'**
  String get profilePublicSellerNameDescription;

  /// No description provided for @profilePublicSellerNameFieldLabel.
  ///
  /// In ru, this message translates to:
  /// **'Имя для покупателей'**
  String get profilePublicSellerNameFieldLabel;

  /// No description provided for @profilePublicSellerNameFieldHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: Анна или «Авто-Плюс Тирасполь»'**
  String get profilePublicSellerNameFieldHint;

  /// No description provided for @profilePublicSellerNameSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get profilePublicSellerNameSave;

  /// No description provided for @profilePublicSellerNameSaved.
  ///
  /// In ru, this message translates to:
  /// **'Имя сохранено'**
  String get profilePublicSellerNameSaved;

  /// No description provided for @profilePublicSellerNameSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить имя. Попробуйте ещё раз.'**
  String get profilePublicSellerNameSaveFailed;

  /// No description provided for @profilePublicSellerNameTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Слишком длинное имя (максимум 80 символов).'**
  String get profilePublicSellerNameTooLong;

  /// No description provided for @profilePublicSellerNameLooksLikeEmail.
  ///
  /// In ru, this message translates to:
  /// **'Укажите имя, а не адрес email.'**
  String get profilePublicSellerNameLooksLikeEmail;

  /// No description provided for @profilePublicSellerNameLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить настройки имени продавца.'**
  String get profilePublicSellerNameLoadFailed;

  /// No description provided for @profilePublicSellerAvatarTitle.
  ///
  /// In ru, this message translates to:
  /// **'Фото продавца'**
  String get profilePublicSellerAvatarTitle;

  /// No description provided for @profilePublicSellerAvatarDescription.
  ///
  /// In ru, this message translates to:
  /// **'Эту фотографию будут видеть покупатели рядом с вашим именем в объявлениях и в профиле продавца.'**
  String get profilePublicSellerAvatarDescription;

  /// No description provided for @profilePublicSellerAvatarChangePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать фото'**
  String get profilePublicSellerAvatarChangePhoto;

  /// No description provided for @profilePublicSellerAvatarRemovePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get profilePublicSellerAvatarRemovePhoto;

  /// No description provided for @profilePublicSellerAvatarUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Фото обновлено'**
  String get profilePublicSellerAvatarUpdated;

  /// No description provided for @profilePublicSellerAvatarRemoved.
  ///
  /// In ru, this message translates to:
  /// **'Фото удалено'**
  String get profilePublicSellerAvatarRemoved;

  /// No description provided for @profilePublicSellerAvatarUploadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить фото. Попробуйте ещё раз.'**
  String get profilePublicSellerAvatarUploadFailed;

  /// No description provided for @profilePublicSellerAvatarRemoveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить фото. Попробуйте ещё раз.'**
  String get profilePublicSellerAvatarRemoveFailed;

  /// No description provided for @profilePublicSellerAvatarUnsupportedType.
  ///
  /// In ru, this message translates to:
  /// **'Поддерживаются только JPEG, PNG или WebP.'**
  String get profilePublicSellerAvatarUnsupportedType;

  /// No description provided for @signInTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get signInTitle;

  /// No description provided for @signInEyebrow.
  ///
  /// In ru, this message translates to:
  /// **'CARZON · ВХОД'**
  String get signInEyebrow;

  /// No description provided for @signInSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы управлять объявлениями и сообщениями'**
  String get signInSubtitle;

  /// No description provided for @signInSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get signInSubmit;

  /// No description provided for @signInError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка входа'**
  String get signInError;

  /// No description provided for @signInInvalidCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Неверный email или пароль.'**
  String get signInInvalidCredentials;

  /// No description provided for @signInFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти. Попробуйте ещё раз.'**
  String get signInFailedRetry;

  /// No description provided for @signUpFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать аккаунт. Попробуйте ещё раз.'**
  String get signUpFailedRetry;

  /// No description provided for @signOutFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выйти. Попробуйте ещё раз.'**
  String get signOutFailedRetry;

  /// No description provided for @authFieldEmail.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get authFieldEmail;

  /// No description provided for @authFieldPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get authFieldPassword;

  /// No description provided for @authFieldConfirmPassword.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите пароль'**
  String get authFieldConfirmPassword;

  /// No description provided for @validationEmailRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите email'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный email'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMin.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 6 символов'**
  String get validationPasswordMin;

  /// No description provided for @validationConfirmPassword.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите пароль'**
  String get validationConfirmPassword;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @signInForgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get signInForgotPassword;

  /// No description provided for @signInCreateAccount.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get signInCreateAccount;

  /// No description provided for @legalLink.
  ///
  /// In ru, this message translates to:
  /// **'Условия и конфиденциальность'**
  String get legalLink;

  /// No description provided for @signUpTitle.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get signUpTitle;

  /// No description provided for @signUpSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get signUpSubmit;

  /// No description provided for @signUpError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка регистрации'**
  String get signUpError;

  /// No description provided for @signUpHaveAccount.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт? Войти'**
  String get signUpHaveAccount;

  /// No description provided for @signUpConfirmEmail.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте почту, чтобы подтвердить аккаунт.'**
  String get signUpConfirmEmail;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Восстановление пароля'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordIntro.
  ///
  /// In ru, this message translates to:
  /// **'Введите email аккаунта — мы пришлём инструкции по сбросу пароля.'**
  String get forgotPasswordIntro;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Отправить письмо'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Если аккаунт с такой почтой существует, мы отправили инструкции по сбросу пароля.'**
  String get forgotPasswordSuccess;

  /// No description provided for @forgotPasswordFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить письмо. Попробуйте ещё раз.'**
  String get forgotPasswordFailedRetry;

  /// No description provided for @forgotPasswordEmailEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Введите email.'**
  String get forgotPasswordEmailEmpty;

  /// No description provided for @backToSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться ко входу'**
  String get backToSignIn;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordNoSession.
  ///
  /// In ru, this message translates to:
  /// **'Откройте ссылку для сброса из письма, чтобы продолжить.'**
  String get resetPasswordNoSession;

  /// No description provided for @resetPasswordIntro.
  ///
  /// In ru, this message translates to:
  /// **'Выберите новый пароль для своего аккаунта.'**
  String get resetPasswordIntro;

  /// No description provided for @resetPasswordNew.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get resetPasswordNew;

  /// No description provided for @resetPasswordConfirmNew.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите новый пароль'**
  String get resetPasswordConfirmNew;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Пароль обновлён. Теперь вы можете войти.'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить пароль. Попробуйте ещё раз.'**
  String get resetPasswordFailedRetry;

  /// No description provided for @resetPasswordSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Обновить пароль'**
  String get resetPasswordSubmit;

  /// No description provided for @resetPasswordValidationNew.
  ///
  /// In ru, this message translates to:
  /// **'Введите новый пароль.'**
  String get resetPasswordValidationNew;

  /// No description provided for @resetPasswordValidationMin.
  ///
  /// In ru, this message translates to:
  /// **'Пароль должен содержать не менее {min} символов.'**
  String resetPasswordValidationMin(int min);

  /// No description provided for @resetPasswordValidationMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают.'**
  String get resetPasswordValidationMismatch;

  /// No description provided for @changePasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Изменить пароль'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordIntro.
  ///
  /// In ru, this message translates to:
  /// **'Введите текущий пароль и выберите новый.'**
  String get changePasswordIntro;

  /// No description provided for @changePasswordCurrentPassword.
  ///
  /// In ru, this message translates to:
  /// **'Текущий пароль'**
  String get changePasswordCurrentPassword;

  /// No description provided for @changePasswordNewPassword.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get changePasswordNewPassword;

  /// No description provided for @changePasswordConfirmPassword.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите новый пароль'**
  String get changePasswordConfirmPassword;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить пароль'**
  String get changePasswordSubmit;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Пароль обновлён.'**
  String get changePasswordSuccess;

  /// No description provided for @changePasswordCurrentInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Текущий пароль неверный.'**
  String get changePasswordCurrentInvalid;

  /// No description provided for @changePasswordFailedRetry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить пароль. Попробуйте ещё раз.'**
  String get changePasswordFailedRetry;

  /// No description provided for @changePasswordSecurityNote.
  ///
  /// In ru, this message translates to:
  /// **'Используйте надёжный пароль, который вы не применяете в других сервисах.'**
  String get changePasswordSecurityNote;

  /// No description provided for @phoneRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона.'**
  String get phoneRequired;

  /// No description provided for @phoneInvalidChars.
  ///
  /// In ru, this message translates to:
  /// **'Разрешены только цифры, пробелы, + ( ) -.'**
  String get phoneInvalidChars;

  /// No description provided for @phoneInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный номер телефона.'**
  String get phoneInvalid;

  /// No description provided for @telegramInvalid.
  ///
  /// In ru, this message translates to:
  /// **'5–32 символа: буквы, цифры или подчёркивания.'**
  String get telegramInvalid;

  /// No description provided for @reportSubjectPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба на объявление Carzon'**
  String get reportSubjectPrefix;

  /// No description provided for @reportBodyIntro.
  ///
  /// In ru, this message translates to:
  /// **'Хочу пожаловаться на следующее объявление Carzon:'**
  String get reportBodyIntro;

  /// No description provided for @reportBodyFieldTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заголовок'**
  String get reportBodyFieldTitle;

  /// No description provided for @reportBodyFieldListingId.
  ///
  /// In ru, this message translates to:
  /// **'ID объявления'**
  String get reportBodyFieldListingId;

  /// No description provided for @reportBodyFieldMmy.
  ///
  /// In ru, this message translates to:
  /// **'Марка / Модель / Год'**
  String get reportBodyFieldMmy;

  /// No description provided for @reportBodyFieldCity.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get reportBodyFieldCity;

  /// No description provided for @reportBodyFieldRegion.
  ///
  /// In ru, this message translates to:
  /// **'Регион'**
  String get reportBodyFieldRegion;

  /// No description provided for @reportBodyPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Опишите, что подозрительно, неверно или недопустимо в этом объявлении:'**
  String get reportBodyPrompt;

  /// No description provided for @legalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Условия и конфиденциальность'**
  String get legalTitle;

  /// No description provided for @legalDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Это ознакомительная версия условий и уведомления о конфиденциальности. Документ описывает, как сейчас работает Carzon, и не заменяет юридически выверенные условия. Пользуйтесь им как информационным материалом на ранней стадии продукта.'**
  String get legalDisclaimer;

  /// No description provided for @legalSectionAboutHeading.
  ///
  /// In ru, this message translates to:
  /// **'О Carzon'**
  String get legalSectionAboutHeading;

  /// No description provided for @legalSectionAboutP1.
  ///
  /// In ru, this message translates to:
  /// **'Carzon — это площадка для объявлений о продаже и обмене автомобилей в Молдове и Приднестровье. Сервис помогает владельцам размещать объявления, а покупателям — находить машины и связываться с продавцами.'**
  String get legalSectionAboutP1;

  /// No description provided for @legalSectionAboutP2.
  ///
  /// In ru, this message translates to:
  /// **'Carzon не продаёт автомобили самостоятельно. Каждое объявление создаётся и принадлежит конкретному пользователю.'**
  String get legalSectionAboutP2;

  /// No description provided for @legalSectionListingsHeading.
  ///
  /// In ru, this message translates to:
  /// **'Объявления на площадке'**
  String get legalSectionListingsHeading;

  /// No description provided for @legalSectionListingsP1.
  ///
  /// In ru, this message translates to:
  /// **'После публикации объявление становится активным и может отображаться другим пользователям Carzon в общей ленте и на странице объявления.'**
  String get legalSectionListingsP1;

  /// No description provided for @legalSectionListingsP2.
  ///
  /// In ru, this message translates to:
  /// **'Вы отвечаете за точность данных, которые публикуете: марка, модель, год, цена, пробег, регион, фотографии и контактная информация.'**
  String get legalSectionListingsP2;

  /// No description provided for @legalSectionListingsP3.
  ///
  /// In ru, this message translates to:
  /// **'Свои объявления вы можете скрыть, отметить как проданные, повторно активировать или отправить в архив в разделе «Мои объявления».'**
  String get legalSectionListingsP3;

  /// No description provided for @legalSectionContactHeading.
  ///
  /// In ru, this message translates to:
  /// **'Публичные контакты продавца'**
  String get legalSectionContactHeading;

  /// No description provided for @legalSectionContactP1.
  ///
  /// In ru, this message translates to:
  /// **'Пока ваше объявление активно, указанные для него контакты могут быть видны любым пользователям Carzon, в том числе без входа в аккаунт.'**
  String get legalSectionContactP1;

  /// No description provided for @legalSectionContactP2.
  ///
  /// In ru, this message translates to:
  /// **'Это может быть номер телефона, ник в Telegram (если указан) и отметка о том, что по номеру доступен WhatsApp.'**
  String get legalSectionContactP2;

  /// No description provided for @legalSectionContactP3.
  ///
  /// In ru, this message translates to:
  /// **'Указывайте только те контакты, которыми готовы поделиться публично для продажи или обмена автомобиля. Вы можете изменить или удалить их, отредактировав объявление или скрыв его, отправив в архив либо отметив как проданное.'**
  String get legalSectionContactP3;

  /// No description provided for @legalSectionPhotosHeading.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии и изображения в объявлениях'**
  String get legalSectionPhotosHeading;

  /// No description provided for @legalSectionPhotosP1.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии, прикреплённые к объявлению, хранятся в публичном хранилище изображений и могут быть видны всем, пока объявление активно.'**
  String get legalSectionPhotosP1;

  /// No description provided for @legalSectionPhotosP2.
  ///
  /// In ru, this message translates to:
  /// **'Загружайте только те фотографии, которыми имеете право делиться. Не публикуйте личные документы, номерные знаки, которые не хотите показывать, и изображения людей, которые не давали на это согласия.'**
  String get legalSectionPhotosP2;

  /// No description provided for @legalSectionAccountHeading.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт и вход'**
  String get legalSectionAccountHeading;

  /// No description provided for @legalSectionAccountP1.
  ///
  /// In ru, this message translates to:
  /// **'Для публикации объявлений, добавления в избранное и работы с разделом «Мои объявления» нужен аккаунт. Аккаунты управляются по email и паролю.'**
  String get legalSectionAccountP1;

  /// No description provided for @legalSectionAccountP2.
  ///
  /// In ru, this message translates to:
  /// **'Вы отвечаете за сохранность своего пароля и за любые действия, выполненные из вашего аккаунта. Если вы подозреваете, что кто-то получил доступ к вашему аккаунту, выйдите из него и смените пароль.'**
  String get legalSectionAccountP2;

  /// No description provided for @legalSectionFavoritesHeading.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get legalSectionFavoritesHeading;

  /// No description provided for @legalSectionFavoritesP1.
  ///
  /// In ru, this message translates to:
  /// **'Избранное видно только вам. Другие пользователи не знают, какие объявления вы добавили в избранное.'**
  String get legalSectionFavoritesP1;

  /// No description provided for @legalSectionSafetyHeading.
  ///
  /// In ru, this message translates to:
  /// **'Безопасность и ответственность'**
  String get legalSectionSafetyHeading;

  /// No description provided for @legalSectionSafetyP1.
  ///
  /// In ru, this message translates to:
  /// **'На данный момент Carzon не проводит платежи внутри приложения, не предоставляет эскроу, не инспектирует автомобили, не гарантирует сделки и не проверяет право собственности. Все сделки происходят напрямую между покупателем и продавцом вне платформы.'**
  String get legalSectionSafetyP1;

  /// No description provided for @legalSectionSafetyP2.
  ///
  /// In ru, this message translates to:
  /// **'Перед покупкой, продажей или обменом проверяйте документы, состояние автомобиля и личность второй стороны. Встречайтесь в безопасном месте и не переводите деньги заранее, опираясь только на объявление.'**
  String get legalSectionSafetyP2;

  /// No description provided for @legalSectionSafetyP3.
  ///
  /// In ru, this message translates to:
  /// **'Carzon не является стороной соглашений между покупателем и продавцом и не отвечает за результат сделок, оформленных через платформу.'**
  String get legalSectionSafetyP3;

  /// No description provided for @legalSectionContactUsHeading.
  ///
  /// In ru, this message translates to:
  /// **'Обратная связь'**
  String get legalSectionContactUsHeading;

  /// No description provided for @legalSectionContactUsP1.
  ///
  /// In ru, this message translates to:
  /// **'Эти условия и уведомление о конфиденциальности могут обновляться по мере развития Carzon. Продолжая пользоваться приложением после обновления, вы принимаете новую версию документа.'**
  String get legalSectionContactUsP1;

  /// No description provided for @legalSectionContactUsP2.
  ///
  /// In ru, this message translates to:
  /// **'Вопросы по этому документу и по содержимому платформы можно задать команде Carzon через канал поддержки, указанный на странице приложения в магазине.'**
  String get legalSectionContactUsP2;

  /// No description provided for @sellerSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Продавец'**
  String get sellerSectionTitle;

  /// No description provided for @sellerViewProfile.
  ///
  /// In ru, this message translates to:
  /// **'Смотреть профиль'**
  String get sellerViewProfile;

  /// No description provided for @sellerProfileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль продавца'**
  String get sellerProfileTitle;

  /// No description provided for @sellerFallbackName.
  ///
  /// In ru, this message translates to:
  /// **'Продавец'**
  String get sellerFallbackName;

  /// No description provided for @sellerUnavailableTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль продавца недоступен'**
  String get sellerUnavailableTitle;

  /// No description provided for @sellerUnavailableMessage.
  ///
  /// In ru, this message translates to:
  /// **'Этот профиль скрыт или недоступен.'**
  String get sellerUnavailableMessage;

  /// No description provided for @sellerListingsSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Объявления продавца'**
  String get sellerListingsSectionTitle;

  /// No description provided for @sellerNoActiveListingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нет активных объявлений'**
  String get sellerNoActiveListingsTitle;

  /// No description provided for @sellerNoActiveListingsMessage.
  ///
  /// In ru, this message translates to:
  /// **'У продавца сейчас нет активных объявлений в каталоге.'**
  String get sellerNoActiveListingsMessage;

  /// No description provided for @sellerMonthGenitiveJanuary.
  ///
  /// In ru, this message translates to:
  /// **'января'**
  String get sellerMonthGenitiveJanuary;

  /// No description provided for @sellerMonthGenitiveFebruary.
  ///
  /// In ru, this message translates to:
  /// **'февраля'**
  String get sellerMonthGenitiveFebruary;

  /// No description provided for @sellerMonthGenitiveMarch.
  ///
  /// In ru, this message translates to:
  /// **'марта'**
  String get sellerMonthGenitiveMarch;

  /// No description provided for @sellerMonthGenitiveApril.
  ///
  /// In ru, this message translates to:
  /// **'апреля'**
  String get sellerMonthGenitiveApril;

  /// No description provided for @sellerMonthGenitiveMay.
  ///
  /// In ru, this message translates to:
  /// **'мая'**
  String get sellerMonthGenitiveMay;

  /// No description provided for @sellerMonthGenitiveJune.
  ///
  /// In ru, this message translates to:
  /// **'июня'**
  String get sellerMonthGenitiveJune;

  /// No description provided for @sellerMonthGenitiveJuly.
  ///
  /// In ru, this message translates to:
  /// **'июля'**
  String get sellerMonthGenitiveJuly;

  /// No description provided for @sellerMonthGenitiveAugust.
  ///
  /// In ru, this message translates to:
  /// **'августа'**
  String get sellerMonthGenitiveAugust;

  /// No description provided for @sellerMonthGenitiveSeptember.
  ///
  /// In ru, this message translates to:
  /// **'сентября'**
  String get sellerMonthGenitiveSeptember;

  /// No description provided for @sellerMonthGenitiveOctober.
  ///
  /// In ru, this message translates to:
  /// **'октября'**
  String get sellerMonthGenitiveOctober;

  /// No description provided for @sellerMonthGenitiveNovember.
  ///
  /// In ru, this message translates to:
  /// **'ноября'**
  String get sellerMonthGenitiveNovember;

  /// No description provided for @sellerMonthGenitiveDecember.
  ///
  /// In ru, this message translates to:
  /// **'декабря'**
  String get sellerMonthGenitiveDecember;

  /// No description provided for @sellerMemberSince.
  ///
  /// In ru, this message translates to:
  /// **'На Carzon с {monthYear}'**
  String sellerMemberSince(String monthYear);

  /// No description provided for @sellerActiveListingsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} активное объявление} few{{count} активных объявления} many{{count} активных объявлений} other{{count} активных объявлений}}'**
  String sellerActiveListingsCount(int count);

  /// No description provided for @sellerTypePrivate.
  ///
  /// In ru, this message translates to:
  /// **'Частный продавец'**
  String get sellerTypePrivate;

  /// No description provided for @sellerTypeDealer.
  ///
  /// In ru, this message translates to:
  /// **'Дилер'**
  String get sellerTypeDealer;

  /// No description provided for @sellerProfileLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить профиль продавца.'**
  String get sellerProfileLoadFailed;

  /// No description provided for @sellerListingsLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить объявления.'**
  String get sellerListingsLoadFailed;

  /// No description provided for @sellerLoadMore.
  ///
  /// In ru, this message translates to:
  /// **'Показать ещё'**
  String get sellerLoadMore;

  /// No description provided for @listingVinFieldLabel.
  ///
  /// In ru, this message translates to:
  /// **'VIN-код'**
  String get listingVinFieldLabel;

  /// No description provided for @listingVinFieldHelper.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно. VIN помогает добавить к объявлению базовую информацию об автомобиле и повышает доверие покупателей. Полный VIN публично не показывается.'**
  String get listingVinFieldHelper;

  /// No description provided for @validationVinInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный VIN из 17 символов или оставьте поле пустым.'**
  String get validationVinInvalid;

  /// No description provided for @listingVinBadgeIndicated.
  ///
  /// In ru, this message translates to:
  /// **'VIN указан'**
  String get listingVinBadgeIndicated;

  /// No description provided for @listingVinReportOpenHint.
  ///
  /// In ru, this message translates to:
  /// **'Открыть отчёт по VIN'**
  String get listingVinReportOpenHint;

  /// No description provided for @listingVinNotProvidedTitle.
  ///
  /// In ru, this message translates to:
  /// **'VIN-код не указан'**
  String get listingVinNotProvidedTitle;

  /// No description provided for @listingVinNotProvidedHint.
  ///
  /// In ru, this message translates to:
  /// **'Продавец не добавил VIN'**
  String get listingVinNotProvidedHint;

  /// No description provided for @menuCompare.
  ///
  /// In ru, this message translates to:
  /// **'Сравнение'**
  String get menuCompare;

  /// No description provided for @compareTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сравнение'**
  String get compareTitle;

  /// No description provided for @compareVehiclesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сравнение автомобилей'**
  String get compareVehiclesTitle;

  /// No description provided for @compareEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте 2–3 автомобиля, чтобы сравнить цену, пробег, характеристики и VIN-статус.'**
  String get compareEmptyBody;

  /// No description provided for @compareGoToListings.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к объявлениям'**
  String get compareGoToListings;

  /// No description provided for @compareAddOneMoreTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте ещё один автомобиль'**
  String get compareAddOneMoreTitle;

  /// No description provided for @compareAddOneMoreBody.
  ///
  /// In ru, this message translates to:
  /// **'Для сравнения нужно минимум два автомобиля. Добавьте ещё одно объявление из каталога.'**
  String get compareAddOneMoreBody;

  /// No description provided for @compareClear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить сравнение'**
  String get compareClear;

  /// No description provided for @compareMaxReachedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Можно сравнить не более 3 автомобилей'**
  String get compareMaxReachedMessage;

  /// No description provided for @compareTrayMaxLimitTitle.
  ///
  /// In ru, this message translates to:
  /// **'Максимум 3 автомобиля'**
  String get compareTrayMaxLimitTitle;

  /// No description provided for @compareTrayMaxLimitHint.
  ///
  /// In ru, this message translates to:
  /// **'Удалите одно авто, чтобы добавить другое'**
  String get compareTrayMaxLimitHint;

  /// No description provided for @compareAddedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено к сравнению'**
  String get compareAddedMessage;

  /// No description provided for @compareRemovedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Удалено из сравнения'**
  String get compareRemovedMessage;

  /// No description provided for @compareAddTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Добавить к сравнению'**
  String get compareAddTooltip;

  /// No description provided for @compareRemoveTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из сравнения'**
  String get compareRemoveTooltip;

  /// No description provided for @compareTrayOneVehicle.
  ///
  /// In ru, this message translates to:
  /// **'1 авто в сравнении'**
  String get compareTrayOneVehicle;

  /// No description provided for @compareTrayVehicleCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} авто в сравнении'**
  String compareTrayVehicleCount(int count);

  /// No description provided for @compareTrayAddOneMore.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте ещё одно'**
  String get compareTrayAddOneMore;

  /// No description provided for @compareTrayOpen.
  ///
  /// In ru, this message translates to:
  /// **'Сравнить'**
  String get compareTrayOpen;

  /// No description provided for @compareVehicleCountShort.
  ///
  /// In ru, this message translates to:
  /// **'{count} авто'**
  String compareVehicleCountShort(int count);

  /// No description provided for @compareShowOnlyDifferences.
  ///
  /// In ru, this message translates to:
  /// **'Показать только отличия'**
  String get compareShowOnlyDifferences;

  /// No description provided for @compareNoDifferences.
  ///
  /// In ru, this message translates to:
  /// **'Отличий по выбранным полям нет'**
  String get compareNoDifferences;

  /// No description provided for @compareRemoveVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из сравнения'**
  String get compareRemoveVehicle;

  /// No description provided for @compareUnavailableListing.
  ///
  /// In ru, this message translates to:
  /// **'Объявление недоступно'**
  String get compareUnavailableListing;

  /// No description provided for @compareInactiveListing.
  ///
  /// In ru, this message translates to:
  /// **'Снято с публикации'**
  String get compareInactiveListing;

  /// No description provided for @compareSectionPriceBasics.
  ///
  /// In ru, this message translates to:
  /// **'Цена и базовое'**
  String get compareSectionPriceBasics;

  /// No description provided for @compareSectionVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Автомобиль'**
  String get compareSectionVehicle;

  /// No description provided for @compareSectionSpecs.
  ///
  /// In ru, this message translates to:
  /// **'Характеристики'**
  String get compareSectionSpecs;

  /// No description provided for @compareSectionTrustData.
  ///
  /// In ru, this message translates to:
  /// **'Доверие / данные'**
  String get compareSectionTrustData;

  /// No description provided for @compareRowPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get compareRowPrice;

  /// No description provided for @compareRowYear.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get compareRowYear;

  /// No description provided for @compareRowMileage.
  ///
  /// In ru, this message translates to:
  /// **'Пробег'**
  String get compareRowMileage;

  /// No description provided for @compareRowCityRegion.
  ///
  /// In ru, this message translates to:
  /// **'Город / регион'**
  String get compareRowCityRegion;

  /// No description provided for @compareRowStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус объявления'**
  String get compareRowStatus;

  /// No description provided for @compareRowMake.
  ///
  /// In ru, this message translates to:
  /// **'Марка'**
  String get compareRowMake;

  /// No description provided for @compareRowModel.
  ///
  /// In ru, this message translates to:
  /// **'Модель'**
  String get compareRowModel;

  /// No description provided for @compareRowBody.
  ///
  /// In ru, this message translates to:
  /// **'Кузов'**
  String get compareRowBody;

  /// No description provided for @compareRowVehicleType.
  ///
  /// In ru, this message translates to:
  /// **'Тип транспорта'**
  String get compareRowVehicleType;

  /// No description provided for @compareRowRegistration.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get compareRowRegistration;

  /// No description provided for @compareRowFuel.
  ///
  /// In ru, this message translates to:
  /// **'Топливо'**
  String get compareRowFuel;

  /// No description provided for @compareRowEngine.
  ///
  /// In ru, this message translates to:
  /// **'Двигатель'**
  String get compareRowEngine;

  /// No description provided for @compareRowPower.
  ///
  /// In ru, this message translates to:
  /// **'Мощность'**
  String get compareRowPower;

  /// No description provided for @compareRowTransmission.
  ///
  /// In ru, this message translates to:
  /// **'Коробка'**
  String get compareRowTransmission;

  /// No description provided for @compareRowDrivetrain.
  ///
  /// In ru, this message translates to:
  /// **'Привод'**
  String get compareRowDrivetrain;

  /// No description provided for @compareRowDisplacement.
  ///
  /// In ru, this message translates to:
  /// **'Объём'**
  String get compareRowDisplacement;

  /// No description provided for @compareRowVin.
  ///
  /// In ru, this message translates to:
  /// **'VIN'**
  String get compareRowVin;

  /// No description provided for @compareRowPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get compareRowPhotos;

  /// No description provided for @compareRowPublishedAt.
  ///
  /// In ru, this message translates to:
  /// **'Дата публикации'**
  String get compareRowPublishedAt;

  /// No description provided for @compareVinProvided.
  ///
  /// In ru, this message translates to:
  /// **'VIN указан'**
  String get compareVinProvided;

  /// No description provided for @compareVinNotProvided.
  ///
  /// In ru, this message translates to:
  /// **'VIN не указан'**
  String get compareVinNotProvided;

  /// No description provided for @compareValueMissing.
  ///
  /// In ru, this message translates to:
  /// **'—'**
  String get compareValueMissing;

  /// No description provided for @listingVinReportLoadingCta.
  ///
  /// In ru, this message translates to:
  /// **'Загружаем отчёт по VIN…'**
  String get listingVinReportLoadingCta;

  /// No description provided for @listingVinReportPendingCta.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт по VIN готовится'**
  String get listingVinReportPendingCta;

  /// No description provided for @listingVinReportNoDataCta.
  ///
  /// In ru, this message translates to:
  /// **'Данные по VIN не найдены'**
  String get listingVinReportNoDataCta;

  /// No description provided for @listingVinReportUnavailableCta.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт по VIN недоступен'**
  String get listingVinReportUnavailableCta;

  /// No description provided for @listingVinReportPendingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт по VIN пока готовится'**
  String get listingVinReportPendingTitle;

  /// No description provided for @listingVinReportPendingBody.
  ///
  /// In ru, this message translates to:
  /// **'Обычно это занимает несколько минут. Данные появятся автоматически после проверки.'**
  String get listingVinReportPendingBody;

  /// No description provided for @listingVinReportNoDataTitle.
  ///
  /// In ru, this message translates to:
  /// **'Данные по VIN не найдены'**
  String get listingVinReportNoDataTitle;

  /// No description provided for @listingVinReportNoDataBody.
  ///
  /// In ru, this message translates to:
  /// **'VIN добавлен продавцом, но сейчас нет доступной публичной расшифровки по этому VIN.'**
  String get listingVinReportNoDataBody;

  /// No description provided for @listingVinReportNoDataNote.
  ///
  /// In ru, this message translates to:
  /// **'Это не означает проверку истории автомобиля.'**
  String get listingVinReportNoDataNote;

  /// No description provided for @listingVinReportUnavailableTitle.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить отчёт по VIN'**
  String get listingVinReportUnavailableTitle;

  /// No description provided for @listingVinReportUnavailableBody.
  ///
  /// In ru, this message translates to:
  /// **'VIN добавлен продавцом, но сейчас отчёт недоступен. Попробуйте позже.'**
  String get listingVinReportUnavailableBody;

  /// No description provided for @listingVinTrustSheetTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверка по VIN'**
  String get listingVinTrustSheetTitle;

  /// No description provided for @listingVinTrustSheetIntro.
  ///
  /// In ru, this message translates to:
  /// **'Продавец добавил VIN-код к объявлению. Полный VIN не показывается публично.'**
  String get listingVinTrustSheetIntro;

  /// No description provided for @listingVinTrustSheetSectionVinProvidedLabel.
  ///
  /// In ru, this message translates to:
  /// **'VIN указан'**
  String get listingVinTrustSheetSectionVinProvidedLabel;

  /// No description provided for @listingVinTrustSheetSectionVinProvidedBody.
  ///
  /// In ru, this message translates to:
  /// **'VIN добавлен продавцом.'**
  String get listingVinTrustSheetSectionVinProvidedBody;

  /// No description provided for @listingVinTrustSheetSectionFormatLabel.
  ///
  /// In ru, this message translates to:
  /// **'Формат VIN'**
  String get listingVinTrustSheetSectionFormatLabel;

  /// No description provided for @listingVinTrustSheetSectionFormatBody.
  ///
  /// In ru, this message translates to:
  /// **'Формат VIN выглядит корректно: 17 символов без недопустимых букв.'**
  String get listingVinTrustSheetSectionFormatBody;

  /// No description provided for @listingVinTrustSheetSectionPrivacyLabel.
  ///
  /// In ru, this message translates to:
  /// **'Конфиденциальность'**
  String get listingVinTrustSheetSectionPrivacyLabel;

  /// No description provided for @listingVinTrustSheetSectionPrivacyBody.
  ///
  /// In ru, this message translates to:
  /// **'Полный VIN доступен только продавцу и не отображается публично в объявлении.'**
  String get listingVinTrustSheetSectionPrivacyBody;

  /// No description provided for @listingVinTrustSheetFutureTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что появится позже'**
  String get listingVinTrustSheetFutureTitle;

  /// No description provided for @listingVinTrustSheetFutureItemVehicleData.
  ///
  /// In ru, this message translates to:
  /// **'Данные автомобиля по VIN'**
  String get listingVinTrustSheetFutureItemVehicleData;

  /// No description provided for @listingVinTrustSheetFutureItemDamageHistory.
  ///
  /// In ru, this message translates to:
  /// **'История повреждений'**
  String get listingVinTrustSheetFutureItemDamageHistory;

  /// No description provided for @listingVinTrustSheetFutureItemRegistrationInsurance.
  ///
  /// In ru, this message translates to:
  /// **'Регистрационные и страховые проверки'**
  String get listingVinTrustSheetFutureItemRegistrationInsurance;

  /// No description provided for @listingVinTrustSheetFutureItemListingCompare.
  ///
  /// In ru, this message translates to:
  /// **'Сравнение данных VIN с объявлением'**
  String get listingVinTrustSheetFutureItemListingCompare;

  /// No description provided for @listingVinTrustSheetFooterNote.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас это базовая проверка формата. Расширенная проверка по официальным и партнёрским источникам будет добавлена позже.'**
  String get listingVinTrustSheetFooterNote;

  /// No description provided for @listingVinTrustSheetGotIt.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get listingVinTrustSheetGotIt;

  /// No description provided for @listingBuyerVinReportTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт по VIN'**
  String get listingBuyerVinReportTitle;

  /// No description provided for @listingBuyerVinReportLoading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка отчёта…'**
  String get listingBuyerVinReportLoading;

  /// No description provided for @listingBuyerVinReportLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить отчёт. Попробуйте позже.'**
  String get listingBuyerVinReportLoadError;

  /// No description provided for @listingBuyerVinReportVinAddedBySeller.
  ///
  /// In ru, this message translates to:
  /// **'VIN добавлен продавцом.'**
  String get listingBuyerVinReportVinAddedBySeller;

  /// No description provided for @listingBuyerVinReportFullVinPrivate.
  ///
  /// In ru, this message translates to:
  /// **'Полный VIN не показывается публично.'**
  String get listingBuyerVinReportFullVinPrivate;

  /// No description provided for @listingBuyerVinReportPublicDataUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Публичные данные по VIN пока недоступны.'**
  String get listingBuyerVinReportPublicDataUnavailable;

  /// No description provided for @listingBuyerVinReportFormatOnlyExplanation.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас отображается только факт, что продавец указал VIN и его формат выглядит корректно.'**
  String get listingBuyerVinReportFormatOnlyExplanation;

  /// No description provided for @listingBuyerVinReportSourcesSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Данные из источников'**
  String get listingBuyerVinReportSourcesSectionTitle;

  /// No description provided for @listingBuyerVinReportSourceHeading.
  ///
  /// In ru, this message translates to:
  /// **'Источник'**
  String get listingBuyerVinReportSourceHeading;

  /// No description provided for @listingBuyerVinReportUpdatedLabel.
  ///
  /// In ru, this message translates to:
  /// **'Дата обновления'**
  String get listingBuyerVinReportUpdatedLabel;

  /// No description provided for @listingBuyerVinReportLimitationsHeading.
  ///
  /// In ru, this message translates to:
  /// **'Ограничения'**
  String get listingBuyerVinReportLimitationsHeading;

  /// No description provided for @listingBuyerVinReportClose.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get listingBuyerVinReportClose;

  /// No description provided for @listingBuyerVinReportBasicDecodeCatalogLine.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас показана только базовая расшифровка VIN по открытому каталогу NHTSA vPIC.'**
  String get listingBuyerVinReportBasicDecodeCatalogLine;

  /// No description provided for @listingBuyerVinReportBasicDecodeNotOfficialLine.
  ///
  /// In ru, this message translates to:
  /// **'Базовая расшифровка VIN, не юридическая или историческая проверка.'**
  String get listingBuyerVinReportBasicDecodeNotOfficialLine;

  /// No description provided for @listingBuyerVinReportNhtsaCatalogSourceLine.
  ///
  /// In ru, this message translates to:
  /// **'Источник: открытый каталог NHTSA vPIC.'**
  String get listingBuyerVinReportNhtsaCatalogSourceLine;

  /// No description provided for @listingBuyerVinReportNotVerifiedSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что Carzon пока не проверяет'**
  String get listingBuyerVinReportNotVerifiedSectionTitle;

  /// No description provided for @listingBuyerVinReportLimitationRegistrationMdPmr.
  ///
  /// In ru, this message translates to:
  /// **'Регистрацию'**
  String get listingBuyerVinReportLimitationRegistrationMdPmr;

  /// No description provided for @listingBuyerVinReportLimitationOwner.
  ///
  /// In ru, this message translates to:
  /// **'Владельца'**
  String get listingBuyerVinReportLimitationOwner;

  /// No description provided for @listingBuyerVinReportLimitationAccidentHistory.
  ///
  /// In ru, this message translates to:
  /// **'ДТП и повреждения'**
  String get listingBuyerVinReportLimitationAccidentHistory;

  /// No description provided for @listingBuyerVinReportLimitationInsurance.
  ///
  /// In ru, this message translates to:
  /// **'Страховку'**
  String get listingBuyerVinReportLimitationInsurance;

  /// No description provided for @listingBuyerVinReportLimitationMileage.
  ///
  /// In ru, this message translates to:
  /// **'Пробег'**
  String get listingBuyerVinReportLimitationMileage;

  /// No description provided for @listingBuyerVinReportLimitationLegalEncumbrances.
  ///
  /// In ru, this message translates to:
  /// **'Юридические ограничения'**
  String get listingBuyerVinReportLimitationLegalEncumbrances;

  /// No description provided for @listingBuyerVinReportLimitationUnknownFallback.
  ///
  /// In ru, this message translates to:
  /// **'Некоторые проверки пока недоступны.'**
  String get listingBuyerVinReportLimitationUnknownFallback;

  /// No description provided for @listingBuyerVinReportCompareHint.
  ///
  /// In ru, this message translates to:
  /// **'Данные по VIN можно сравнить с объявлением.'**
  String get listingBuyerVinReportCompareHint;

  /// No description provided for @listingBuyerVinReportCompareMatch.
  ///
  /// In ru, this message translates to:
  /// **'Базовые данные по VIN совпадают с объявлением.'**
  String get listingBuyerVinReportCompareMatch;

  /// No description provided for @listingBuyerVinReportCompareMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Данные по VIN не совпадают с объявлением.'**
  String get listingBuyerVinReportCompareMismatch;

  /// No description provided for @listingBuyerVinReportDecodedEngineLabel.
  ///
  /// In ru, this message translates to:
  /// **'Двигатель'**
  String get listingBuyerVinReportDecodedEngineLabel;

  /// No description provided for @listingBuyerVinReportDecodedTransmissionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Трансмиссия'**
  String get listingBuyerVinReportDecodedTransmissionLabel;

  /// No description provided for @listingBuyerVinReportNhtsaManufacturerLabel.
  ///
  /// In ru, this message translates to:
  /// **'Производитель'**
  String get listingBuyerVinReportNhtsaManufacturerLabel;

  /// No description provided for @listingBuyerVinReportNhtsaPlantCountryLabel.
  ///
  /// In ru, this message translates to:
  /// **'Страна сборки'**
  String get listingBuyerVinReportNhtsaPlantCountryLabel;

  /// No description provided for @listingBuyerVinReportNhtsaPlantCityLabel.
  ///
  /// In ru, this message translates to:
  /// **'Город сборки'**
  String get listingBuyerVinReportNhtsaPlantCityLabel;

  /// No description provided for @listingBuyerVinReportNhtsaPlantCompanyLabel.
  ///
  /// In ru, this message translates to:
  /// **'Завод'**
  String get listingBuyerVinReportNhtsaPlantCompanyLabel;

  /// No description provided for @listingBuyerVinReportNhtsaVehicleTypeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Тип ТС'**
  String get listingBuyerVinReportNhtsaVehicleTypeLabel;

  /// No description provided for @listingBuyerVinReportNhtsaTrimLabel.
  ///
  /// In ru, this message translates to:
  /// **'Комплектация'**
  String get listingBuyerVinReportNhtsaTrimLabel;

  /// No description provided for @listingBuyerVinReportNhtsaSeriesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Серия'**
  String get listingBuyerVinReportNhtsaSeriesLabel;

  /// No description provided for @listingBuyerVinReportNhtsaDriveTypeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Привод'**
  String get listingBuyerVinReportNhtsaDriveTypeLabel;

  /// No description provided for @listingBuyerVinReportNhtsaDoorsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Дверей'**
  String get listingBuyerVinReportNhtsaDoorsLabel;

  /// No description provided for @listingBuyerVinReportNhtsaDisplacementLabel.
  ///
  /// In ru, this message translates to:
  /// **'Объём'**
  String get listingBuyerVinReportNhtsaDisplacementLabel;

  /// No description provided for @listingBuyerVinReportNhtsaCylindersLabel.
  ///
  /// In ru, this message translates to:
  /// **'Цилиндров'**
  String get listingBuyerVinReportNhtsaCylindersLabel;

  /// No description provided for @listingBuyerVinReportNhtsaGvwrLabel.
  ///
  /// In ru, this message translates to:
  /// **'Класс полной массы'**
  String get listingBuyerVinReportNhtsaGvwrLabel;

  /// No description provided for @listingBuyerVinReportNhtsaCatalogDecodeCaution.
  ///
  /// In ru, this message translates to:
  /// **'Каталог вернул неполные данные по VIN — используйте сведения как ориентир, а не как подтверждение.'**
  String get listingBuyerVinReportNhtsaCatalogDecodeCaution;

  /// No description provided for @listingBuyerVinReportNhtsaGroupCoreIdentity.
  ///
  /// In ru, this message translates to:
  /// **'Основное'**
  String get listingBuyerVinReportNhtsaGroupCoreIdentity;

  /// No description provided for @listingBuyerVinReportNhtsaGroupVehicleSpecs.
  ///
  /// In ru, this message translates to:
  /// **'Характеристики'**
  String get listingBuyerVinReportNhtsaGroupVehicleSpecs;

  /// No description provided for @listingBuyerVinReportNhtsaGroupOrigin.
  ///
  /// In ru, this message translates to:
  /// **'Сборка'**
  String get listingBuyerVinReportNhtsaGroupOrigin;

  /// No description provided for @listingBuyerVinReportManualSourcesSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Дополнительные проверки'**
  String get listingBuyerVinReportManualSourcesSectionTitle;

  /// No description provided for @listingBuyerVinReportManualSourcesIntro.
  ///
  /// In ru, this message translates to:
  /// **'Источники для отдельной проверки.'**
  String get listingBuyerVinReportManualSourcesIntro;

  /// No description provided for @listingBuyerVinReportManualStatusExternalCheck.
  ///
  /// In ru, this message translates to:
  /// **'Внешняя проверка'**
  String get listingBuyerVinReportManualStatusExternalCheck;

  /// No description provided for @listingBuyerVinReportManualStatusSellerDocument.
  ///
  /// In ru, this message translates to:
  /// **'Документ от продавца'**
  String get listingBuyerVinReportManualStatusSellerDocument;

  /// No description provided for @listingBuyerVinReportManualStatusFuture.
  ///
  /// In ru, this message translates to:
  /// **'Будущий источник'**
  String get listingBuyerVinReportManualStatusFuture;

  /// No description provided for @listingBuyerVinReportManualMdRcaTitle.
  ///
  /// In ru, this message translates to:
  /// **'История повреждений в Молдове'**
  String get listingBuyerVinReportManualMdRcaTitle;

  /// No description provided for @listingBuyerVinReportManualMdRcaBody.
  ///
  /// In ru, this message translates to:
  /// **'Данные о повреждениях можно проверить на официальном портале RCA/BNM по VIN. Carzon не получает эти данные автоматически.'**
  String get listingBuyerVinReportManualMdRcaBody;

  /// No description provided for @listingBuyerVinReportManualMdRcaLimitation.
  ///
  /// In ru, this message translates to:
  /// **'Результат внешней проверки не отображается в этом отчёте.'**
  String get listingBuyerVinReportManualMdRcaLimitation;

  /// No description provided for @listingBuyerVinReportManualMdAspTitle.
  ///
  /// In ru, this message translates to:
  /// **'Документы и регистрационные данные'**
  String get listingBuyerVinReportManualMdAspTitle;

  /// No description provided for @listingBuyerVinReportManualMdAspBody.
  ///
  /// In ru, this message translates to:
  /// **'Продавец может предоставить документ ASP / выписку из Государственного регистра транспорта. Перед покупкой сверяйте оригинал документа.'**
  String get listingBuyerVinReportManualMdAspBody;

  /// No description provided for @listingBuyerVinReportManualMdAspLimitation.
  ///
  /// In ru, this message translates to:
  /// **'Carzon не проверяет подлинность документов автоматически.'**
  String get listingBuyerVinReportManualMdAspLimitation;

  /// No description provided for @listingBuyerVinReportManualPmrCustomsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Таможенное оформление в ПМР'**
  String get listingBuyerVinReportManualPmrCustomsTitle;

  /// No description provided for @listingBuyerVinReportManualPmrCustomsBody.
  ///
  /// In ru, this message translates to:
  /// **'Сведения о таможенном оформлении можно проверять через официальный источник ГТК ПМР. Автоматическая проверка в Carzon пока не выполняется.'**
  String get listingBuyerVinReportManualPmrCustomsBody;

  /// No description provided for @listingBuyerVinReportManualPmrCustomsLimitation.
  ///
  /// In ru, this message translates to:
  /// **'Данные таможни не включены в этот отчёт.'**
  String get listingBuyerVinReportManualPmrCustomsLimitation;

  /// No description provided for @listingBuyerVinReportManualCommercialTitle.
  ///
  /// In ru, this message translates to:
  /// **'Расширенный отчёт по истории'**
  String get listingBuyerVinReportManualCommercialTitle;

  /// No description provided for @listingBuyerVinReportManualCommercialBody.
  ///
  /// In ru, this message translates to:
  /// **'Коммерческие отчёты могут содержать дополнительные данные по истории автомобиля, если источник покрывает этот рынок. Интеграция будет оцениваться отдельно.'**
  String get listingBuyerVinReportManualCommercialBody;

  /// No description provided for @listingBuyerVinReportManualCommercialLimitation.
  ///
  /// In ru, this message translates to:
  /// **'Коммерческие источники пока не подключены к Carzon.'**
  String get listingBuyerVinReportManualCommercialLimitation;

  /// No description provided for @editListingVinReportSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Статус VIN'**
  String get editListingVinReportSectionTitle;

  /// No description provided for @editListingVinReportNoVinBody.
  ///
  /// In ru, this message translates to:
  /// **'VIN не указан. После сохранения VIN здесь появится статус обработки.'**
  String get editListingVinReportNoVinBody;

  /// No description provided for @editListingVinReportPendingBody.
  ///
  /// In ru, this message translates to:
  /// **'VIN добавлен. Проверка базовой информации выполняется.'**
  String get editListingVinReportPendingBody;

  /// No description provided for @editListingVinReportDecodedBody.
  ///
  /// In ru, this message translates to:
  /// **'Базовая информация по VIN обработана.'**
  String get editListingVinReportDecodedBody;

  /// No description provided for @editListingVinReportFailedBody.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обработать базовую информацию по VIN. VIN всё равно сохранён.'**
  String get editListingVinReportFailedBody;

  /// No description provided for @editListingVinReportUnavailableBody.
  ///
  /// In ru, this message translates to:
  /// **'VIN сохранён. Расширенный статус пока недоступен.'**
  String get editListingVinReportUnavailableBody;

  /// No description provided for @editListingVinReportLimitationNote.
  ///
  /// In ru, this message translates to:
  /// **'Это не официальная проверка регистрации, владельца, истории ДТП, страховки или пробега.'**
  String get editListingVinReportLimitationNote;

  /// No description provided for @editListingVinReportPrivacyNote.
  ///
  /// In ru, this message translates to:
  /// **'Полный VIN не показывается публично.'**
  String get editListingVinReportPrivacyNote;

  /// No description provided for @editListingVinReportBasicInfoHeading.
  ///
  /// In ru, this message translates to:
  /// **'Базовая информация'**
  String get editListingVinReportBasicInfoHeading;

  /// No description provided for @editListingVinReportDecodedMakeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Марка'**
  String get editListingVinReportDecodedMakeLabel;

  /// No description provided for @editListingVinReportDecodedModelLabel.
  ///
  /// In ru, this message translates to:
  /// **'Модель'**
  String get editListingVinReportDecodedModelLabel;

  /// No description provided for @editListingVinReportDecodedYearLabel.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get editListingVinReportDecodedYearLabel;

  /// No description provided for @editListingVinReportDecodedBodyLabel.
  ///
  /// In ru, this message translates to:
  /// **'Кузов'**
  String get editListingVinReportDecodedBodyLabel;

  /// No description provided for @editListingVinReportDecodedFuelLabel.
  ///
  /// In ru, this message translates to:
  /// **'Топливо'**
  String get editListingVinReportDecodedFuelLabel;

  /// No description provided for @editListingVinReportSourceLine.
  ///
  /// In ru, this message translates to:
  /// **'Источник: базовая расшифровка NHTSA vPIC.'**
  String get editListingVinReportSourceLine;

  /// No description provided for @listingModelPassportSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Официальные данные модели'**
  String get listingModelPassportSectionTitle;

  /// No description provided for @listingModelPassportFuelEconomyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Расход по источнику'**
  String get listingModelPassportFuelEconomyTitle;

  /// No description provided for @listingModelPassportCombinedConsumption.
  ///
  /// In ru, this message translates to:
  /// **'Расход смешанный'**
  String get listingModelPassportCombinedConsumption;

  /// No description provided for @listingModelPassportCityConsumption.
  ///
  /// In ru, this message translates to:
  /// **'Расход в городе'**
  String get listingModelPassportCityConsumption;

  /// No description provided for @listingModelPassportHighwayConsumption.
  ///
  /// In ru, this message translates to:
  /// **'Расход на трассе'**
  String get listingModelPassportHighwayConsumption;

  /// No description provided for @listingModelPassportFuelType.
  ///
  /// In ru, this message translates to:
  /// **'Топливо по источнику'**
  String get listingModelPassportFuelType;

  /// No description provided for @listingModelPassportCo2Emissions.
  ///
  /// In ru, this message translates to:
  /// **'Выбросы CO₂'**
  String get listingModelPassportCo2Emissions;

  /// No description provided for @listingModelPassportSource.
  ///
  /// In ru, this message translates to:
  /// **'Источник'**
  String get listingModelPassportSource;

  /// No description provided for @listingModelPassportLastUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Обновлено:'**
  String get listingModelPassportLastUpdated;

  /// No description provided for @listingModelPassportLoading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка данных модели…'**
  String get listingModelPassportLoading;

  /// No description provided for @listingModelPassportPendingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Официальные данные модели загружаются'**
  String get listingModelPassportPendingTitle;

  /// No description provided for @listingModelPassportPendingBody.
  ///
  /// In ru, this message translates to:
  /// **'Обычно это занимает до 30 минут после публикации. Данные появятся автоматически, если официальный источник найдёт информацию по этой модели.'**
  String get listingModelPassportPendingBody;

  /// No description provided for @listingModelPassportLimitationsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ограничения'**
  String get listingModelPassportLimitationsTitle;

  /// No description provided for @listingModelPassportSourceEpa.
  ///
  /// In ru, this message translates to:
  /// **'EPA · FuelEconomy.gov'**
  String get listingModelPassportSourceEpa;

  /// No description provided for @listingModelPassportUnitLPer100km.
  ///
  /// In ru, this message translates to:
  /// **'л/100 км'**
  String get listingModelPassportUnitLPer100km;

  /// No description provided for @listingModelPassportUnitGPerKm.
  ///
  /// In ru, this message translates to:
  /// **'г/км'**
  String get listingModelPassportUnitGPerKm;

  /// No description provided for @listingModelPassportLimitationUsMarketOnly.
  ///
  /// In ru, this message translates to:
  /// **'Данные относятся к рынку США и могут не совпадать с вашим регионом.'**
  String get listingModelPassportLimitationUsMarketOnly;

  /// No description provided for @listingModelPassportLimitationTrimEngineMarket.
  ///
  /// In ru, this message translates to:
  /// **'Показатели могут отличаться в зависимости от двигателя, комплектации, рынка и точной конфигурации.'**
  String get listingModelPassportLimitationTrimEngineMarket;

  /// No description provided for @listingModelPassportLimitationModelLevel.
  ///
  /// In ru, this message translates to:
  /// **'Данные на уровне модели, а не конкретного автомобиля из объявления.'**
  String get listingModelPassportLimitationModelLevel;

  /// No description provided for @listingModelPassportLimitationSourceUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Часть данных источника сейчас недоступна.'**
  String get listingModelPassportLimitationSourceUnavailable;

  /// No description provided for @listingModelPassportLimitationOpenData.
  ///
  /// In ru, this message translates to:
  /// **'Открытые данные источника не проверялись Carzon и могут содержать неточности.'**
  String get listingModelPassportLimitationOpenData;

  /// No description provided for @listingModelPassportLimitationNotHistory.
  ///
  /// In ru, this message translates to:
  /// **'Это не история автомобиля, регистрации, ДТП или пробега.'**
  String get listingModelPassportLimitationNotHistory;

  /// No description provided for @listingModelPassportLimitationNotRecall.
  ///
  /// In ru, this message translates to:
  /// **'Это не данные об отзывах или кампаниях безопасности.'**
  String get listingModelPassportLimitationNotRecall;

  /// No description provided for @listingModelPassportLimitationMultipleConfigurations.
  ///
  /// In ru, this message translates to:
  /// **'Для модели возможны несколько конфигураций — показаны усреднённые или типовые значения.'**
  String get listingModelPassportLimitationMultipleConfigurations;

  /// No description provided for @listingModelPassportLimitationBasicCatalogOnly.
  ///
  /// In ru, this message translates to:
  /// **'Справочные каталожные данные без привязки к конкретному экземпляру.'**
  String get listingModelPassportLimitationBasicCatalogOnly;

  /// No description provided for @listingModelPassportLimitationGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Данные носят справочный характер и могут не совпадать с конкретным автомобилем.'**
  String get listingModelPassportLimitationGeneric;

  /// No description provided for @listingModelPassportFuelRegularGasoline.
  ///
  /// In ru, this message translates to:
  /// **'Бензин обычный'**
  String get listingModelPassportFuelRegularGasoline;

  /// No description provided for @listingModelPassportFuelPremiumGasoline.
  ///
  /// In ru, this message translates to:
  /// **'Бензин премиум'**
  String get listingModelPassportFuelPremiumGasoline;

  /// No description provided for @listingModelPassportFuelMidgradeGasoline.
  ///
  /// In ru, this message translates to:
  /// **'Бензин средний'**
  String get listingModelPassportFuelMidgradeGasoline;

  /// No description provided for @listingModelPassportFuelDiesel.
  ///
  /// In ru, this message translates to:
  /// **'Дизель'**
  String get listingModelPassportFuelDiesel;

  /// No description provided for @listingModelPassportFuelElectricity.
  ///
  /// In ru, this message translates to:
  /// **'Электричество'**
  String get listingModelPassportFuelElectricity;

  /// No description provided for @listingModelPassportFuelHybrid.
  ///
  /// In ru, this message translates to:
  /// **'Гибрид'**
  String get listingModelPassportFuelHybrid;

  /// No description provided for @listingModelPassportFuelPlugInHybrid.
  ///
  /// In ru, this message translates to:
  /// **'Подключаемый гибрид'**
  String get listingModelPassportFuelPlugInHybrid;

  /// No description provided for @listingModelPassportFuelTypeGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Топливо по данным источника'**
  String get listingModelPassportFuelTypeGeneric;

  /// No description provided for @listingRecallTitle.
  ///
  /// In ru, this message translates to:
  /// **'Кампании отзыва'**
  String get listingRecallTitle;

  /// No description provided for @listingRecallPendingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверяем кампании безопасности'**
  String get listingRecallPendingTitle;

  /// No description provided for @listingRecallPendingBody.
  ///
  /// In ru, this message translates to:
  /// **'Проверка выполняется по марке, модели и году. Обычно это занимает до 30 минут после публикации.'**
  String get listingRecallPendingBody;

  /// No description provided for @listingRecallPendingLimitationNote.
  ///
  /// In ru, this message translates to:
  /// **'Это не VIN-проверка. Для точного статуса проверяйте VIN у официального дилера, производителя или NHTSA.'**
  String get listingRecallPendingLimitationNote;

  /// No description provided for @listingRecallSourceBadge.
  ///
  /// In ru, this message translates to:
  /// **'NHTSA'**
  String get listingRecallSourceBadge;

  /// No description provided for @listingRecallCampaignsFound.
  ///
  /// In ru, this message translates to:
  /// **'Проверка по модели и году выпуска'**
  String get listingRecallCampaignsFound;

  /// No description provided for @listingRecallCampaignCount.
  ///
  /// In ru, this message translates to:
  /// **'Кампаний'**
  String get listingRecallCampaignCount;

  /// No description provided for @listingRecallCampaignCountStat.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} кампания найдена} few{{count} кампании найдено} many{{count} кампаний найдено} other{{count} кампаний найдено}}'**
  String listingRecallCampaignCountStat(int count);

  /// No description provided for @listingRecallLastUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Обновлено:'**
  String get listingRecallLastUpdated;

  /// No description provided for @listingRecallComponent.
  ///
  /// In ru, this message translates to:
  /// **'Компонент'**
  String get listingRecallComponent;

  /// No description provided for @listingRecallSourceComponent.
  ///
  /// In ru, this message translates to:
  /// **'Компонент (источник)'**
  String get listingRecallSourceComponent;

  /// No description provided for @listingRecallComponentSuspensionFront.
  ///
  /// In ru, this message translates to:
  /// **'Подвеска · передняя часть'**
  String get listingRecallComponentSuspensionFront;

  /// No description provided for @listingRecallComponentSeatBeltsRear.
  ///
  /// In ru, this message translates to:
  /// **'Ремни безопасности · задний ряд'**
  String get listingRecallComponentSeatBeltsRear;

  /// No description provided for @listingRecallComponentEquipmentManual.
  ///
  /// In ru, this message translates to:
  /// **'Оборудование · руководство/сервис'**
  String get listingRecallComponentEquipmentManual;

  /// No description provided for @listingRecallComponentBackOverPreventionDisplay.
  ///
  /// In ru, this message translates to:
  /// **'Камера/обзор назад · дисплей'**
  String get listingRecallComponentBackOverPreventionDisplay;

  /// No description provided for @listingRecallComponentElectricalPropulsionBattery.
  ///
  /// In ru, this message translates to:
  /// **'Электросистема · тяговая батарея'**
  String get listingRecallComponentElectricalPropulsionBattery;

  /// No description provided for @listingRecallComponentServiceBrakesAirSupply.
  ///
  /// In ru, this message translates to:
  /// **'Тормозная система · магистрали'**
  String get listingRecallComponentServiceBrakesAirSupply;

  /// No description provided for @listingRecallComponentAirbagsFrontal.
  ///
  /// In ru, this message translates to:
  /// **'Подушки безопасности · передние'**
  String get listingRecallComponentAirbagsFrontal;

  /// No description provided for @listingRecallCampaignNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер кампании'**
  String get listingRecallCampaignNumber;

  /// No description provided for @listingRecallManufacturer.
  ///
  /// In ru, this message translates to:
  /// **'Производитель'**
  String get listingRecallManufacturer;

  /// No description provided for @listingRecallSummary.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get listingRecallSummary;

  /// No description provided for @listingRecallConsequence.
  ///
  /// In ru, this message translates to:
  /// **'Риск'**
  String get listingRecallConsequence;

  /// No description provided for @listingRecallRemedy.
  ///
  /// In ru, this message translates to:
  /// **'Решение'**
  String get listingRecallRemedy;

  /// No description provided for @listingRecallNotes.
  ///
  /// In ru, this message translates to:
  /// **'Примечания'**
  String get listingRecallNotes;

  /// No description provided for @listingRecallReportReceivedDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата получения отчёта'**
  String get listingRecallReportReceivedDate;

  /// No description provided for @listingRecallParkIt.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендация не эксплуатировать'**
  String get listingRecallParkIt;

  /// No description provided for @listingRecallParkOutside.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендация не парковать в помещении'**
  String get listingRecallParkOutside;

  /// No description provided for @listingRecallOverTheAirUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Обновление по воздуху (OTA)'**
  String get listingRecallOverTheAirUpdate;

  /// No description provided for @listingRecallFlagYes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get listingRecallFlagYes;

  /// No description provided for @listingRecallLimitationsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ограничения'**
  String get listingRecallLimitationsTitle;

  /// No description provided for @listingRecallLimitationUsMarketDataOnly.
  ///
  /// In ru, this message translates to:
  /// **'Данные относятся к рынку США и могут не совпадать с вашим регионом.'**
  String get listingRecallLimitationUsMarketDataOnly;

  /// No description provided for @listingRecallLimitationModelLevelNotExactVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Данные на уровне модели и года, а не конкретного автомобиля из объявления.'**
  String get listingRecallLimitationModelLevelNotExactVehicle;

  /// No description provided for @listingRecallLimitationNotVinVerifiedRecallStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус отзыва не проверялся по VIN — данные справочные.'**
  String get listingRecallLimitationNotVinVerifiedRecallStatus;

  /// No description provided for @listingRecallLimitationMayDifferByTrimEngineMarket.
  ///
  /// In ru, this message translates to:
  /// **'Кампании могут отличаться в зависимости от комплектации, двигателя и рынка.'**
  String get listingRecallLimitationMayDifferByTrimEngineMarket;

  /// No description provided for @listingRecallLimitationVerifyWithOfficialDealerOrNhtsa.
  ///
  /// In ru, this message translates to:
  /// **'Уточните статус отзыва у официального дилера, производителя или на сайте NHTSA.'**
  String get listingRecallLimitationVerifyWithOfficialDealerOrNhtsa;

  /// No description provided for @listingRecallLimitationMultipleCampaignsListed.
  ///
  /// In ru, this message translates to:
  /// **'Показаны не все кампании — список может быть неполным.'**
  String get listingRecallLimitationMultipleCampaignsListed;

  /// No description provided for @listingRecallLimitationGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Данные носят справочный характер и могут не совпадать с конкретным автомобилем.'**
  String get listingRecallLimitationGeneric;

  /// No description provided for @listingRecallShowDetails.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get listingRecallShowDetails;

  /// No description provided for @listingRecallHideDetails.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get listingRecallHideDetails;

  /// No description provided for @listingRecallShowAllCampaigns.
  ///
  /// In ru, this message translates to:
  /// **'Показать все {count} кампаний'**
  String listingRecallShowAllCampaigns(int count);

  /// No description provided for @listingRecallChipParkIt.
  ///
  /// In ru, this message translates to:
  /// **'Не эксплуатировать'**
  String get listingRecallChipParkIt;

  /// No description provided for @listingRecallChipParkOutside.
  ///
  /// In ru, this message translates to:
  /// **'Не парковать в помещении'**
  String get listingRecallChipParkOutside;

  /// No description provided for @listingRecallChipOverTheAirUpdate.
  ///
  /// In ru, this message translates to:
  /// **'OTA'**
  String get listingRecallChipOverTheAirUpdate;

  /// No description provided for @notificationMessageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новое сообщение'**
  String get notificationMessageTitle;

  /// No description provided for @notificationMessageBody.
  ///
  /// In ru, this message translates to:
  /// **'Вам написали по объявлению в Carzon.'**
  String get notificationMessageBody;

  /// No description provided for @notificationFilterAlertTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новое объявление'**
  String get notificationFilterAlertTitle;

  /// No description provided for @notificationFilterAlertBody.
  ///
  /// In ru, this message translates to:
  /// **'Есть объявление по вашему сохранённому фильтру. Откройте, чтобы посмотреть.'**
  String get notificationFilterAlertBody;

  /// No description provided for @notificationAndroidChannelMessagesName.
  ///
  /// In ru, this message translates to:
  /// **'Carzon — сообщения'**
  String get notificationAndroidChannelMessagesName;

  /// No description provided for @notificationAndroidChannelMessagesDescription.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления о новых сообщениях в чате'**
  String get notificationAndroidChannelMessagesDescription;

  /// No description provided for @notificationAndroidChannelFilterName.
  ///
  /// In ru, this message translates to:
  /// **'Carzon — оповещения по фильтру'**
  String get notificationAndroidChannelFilterName;

  /// No description provided for @notificationAndroidChannelFilterDescription.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления о новых объявлениях по сохранённому фильтру'**
  String get notificationAndroidChannelFilterDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ro', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
