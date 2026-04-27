import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('ru')];

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

  /// No description provided for @listingsLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить объявления.'**
  String get listingsLoadFailed;

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

  /// No description provided for @listingsFiltersTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get listingsFiltersTooltip;

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

  /// No description provided for @listingsEmptyResetFilters.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить фильтры'**
  String get listingsEmptyResetFilters;

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

  /// No description provided for @filterMinYear.
  ///
  /// In ru, this message translates to:
  /// **'Мин. год'**
  String get filterMinYear;

  /// No description provided for @filterMaxYear.
  ///
  /// In ru, this message translates to:
  /// **'Макс. год'**
  String get filterMaxYear;

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

  /// No description provided for @listingFieldPosted.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовано'**
  String get listingFieldPosted;

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
  /// **'Регион'**
  String get fieldRegion;

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
  /// **'Не удалось загрузить изображение: {error}'**
  String imageLoadFailed(String error);

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

  /// No description provided for @signInTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get signInTitle;

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
      <String>['ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
