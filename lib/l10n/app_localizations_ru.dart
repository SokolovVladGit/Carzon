// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Carzon';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonSignIn => 'Войти';

  @override
  String get commonSignOut => 'Выйти';

  @override
  String get commonRequired => 'Обязательно';

  @override
  String get commonComingSoon => 'Скоро';

  @override
  String get commonKilometersShort => 'км';

  @override
  String routeNotFound(String uri) {
    return 'Страница не найдена: $uri';
  }

  @override
  String get listingsAppBarTitle => 'Carzon';

  @override
  String get listingsTooltipSell => 'Подать объявление';

  @override
  String get listingsTooltipMyListings => 'Мои объявления';

  @override
  String get listingsTooltipFavorites => 'Избранное';

  @override
  String get listingsTooltipProfile => 'Профиль';

  @override
  String get catalogTitle => 'Каталог авто';

  @override
  String get catalogSubtitle =>
      'Подберите автомобиль в Приднестровье и Молдове';

  @override
  String get regionFilterLabel => 'Регион';

  @override
  String get navListings => 'Поиск';

  @override
  String get navFavorites => 'Избранное';

  @override
  String get navSell => 'Подать';

  @override
  String get navMyListings => 'Мои';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navMenu => 'Меню';

  @override
  String get menuTitle => 'Меню';

  @override
  String get menuAccount => 'Аккаунт';

  @override
  String get listingsLoadFailed => 'Не удалось загрузить объявления.';

  @override
  String get listingsEmpty => 'Подходящих объявлений не найдено.';

  @override
  String get listingsSearchHint => 'Поиск объявлений';

  @override
  String get listingsSearchClearTooltip => 'Очистить поиск';

  @override
  String get listingsFiltersTooltip => 'Фильтры';

  @override
  String get catalogBrowseFilterBellTooltip => 'Оповещения по этому фильтру';

  @override
  String get catalogBrowseFilterBellFilterChipSemantics =>
      'Активны оповещения по сохранённому фильтру, совпадающему с текущими условиями поиска';

  @override
  String get catalogBrowseFilterBellTooBroad =>
      'Уточните фильтр (поиск, марка, параметры или регион), затем сохраните оповещение — базовый каталог без условий слишком широкий.';

  @override
  String get catalogBrowseFilterAlertTooBroadInlineTitle =>
      'Уточните фильтр, чтобы сохранить оповещение.';

  @override
  String get catalogBrowseFilterAlertTooBroadInlineBody =>
      'Базовый каталог без условий слишком широкий.';

  @override
  String get catalogBrowseFilterBellEnabledSnack =>
      'Оповещения по этому фильтру включены.';

  @override
  String get catalogBrowseFilterBellDisabledSnack =>
      'Оповещения по фильтру выключены.';

  @override
  String get catalogBrowseFilterBellSavedDeliveryUnavailableTooltip =>
      'Оповещение сохранено. Нажмите, чтобы удалить.';

  @override
  String get catalogBrowseFilterBellInactiveTooltip =>
      'Включить оповещения по этому фильтру.';

  @override
  String get catalogBrowseFilterBellActiveTooltip =>
      'Оповещения включены. Нажмите, чтобы выключить.';

  @override
  String get listingsEmptyTitle => 'Объявления не найдены';

  @override
  String get listingsEmptyBody =>
      'В этом разделе пока нет активных объявлений.';

  @override
  String get listingsEmptyFilteredBody =>
      'Попробуйте изменить поиск или фильтры.';

  @override
  String get listingsEmptyBodyTypeFilterNote =>
      'Объявления без указанного типа кузова не показываются в фильтрах по кузову. Продавец может добавить тип при редактировании объявления.';

  @override
  String get listingsEmptyResetFilters => 'Сбросить фильтры';

  @override
  String get listingsBodyChipAll => 'Все';

  @override
  String get listingBodyTypeSedan => 'Седан';

  @override
  String get listingBodyTypeHatchback => 'Хэтчбек';

  @override
  String get listingBodyTypeWagon => 'Универсал';

  @override
  String get listingBodyTypeSuv => 'SUV';

  @override
  String get listingBodyTypeCoupe => 'Купе';

  @override
  String get listingBodyTypeConvertible => 'Кабриолет';

  @override
  String get listingBodyTypeMinivan => 'Минивэн';

  @override
  String get listingBodyTypePickup => 'Пикап';

  @override
  String get listingBodyTypeVan => 'Фургон';

  @override
  String get listingBodyTypeOther => 'Другое';

  @override
  String get listingBodyTypeNotSpecified => 'Не указано';

  @override
  String get listingBodyTypeSectionTitle => 'Тип кузова';

  @override
  String get listingBodyTypeSectionSubtitle =>
      'Для фильтров по типу кузова. Если не подходит — «Другое».';

  @override
  String get regionTransnistria => 'Приднестровье';

  @override
  String get regionMoldova => 'Молдова';

  @override
  String get regionBoth => 'Все';

  @override
  String get filtersTitle => 'Фильтры';

  @override
  String get filtersDismissTooltip => 'Закрыть фильтры';

  @override
  String get filtersHeaderEyebrow => 'CARZON · ПОИСК';

  @override
  String get filtersSubtitle => 'Подберите параметры поиска';

  @override
  String get filterMake => 'Марка';

  @override
  String get filterMakeHint => 'напр. Volkswagen';

  @override
  String get brandFilterAllSemantics => 'Все марки';

  @override
  String brandFilterBrandSemantics(String brand) {
    return 'Марка: $brand';
  }

  @override
  String get filterMinYear => 'Год от';

  @override
  String get filterMaxYear => 'Год до';

  @override
  String get filterYearRangeInverted =>
      'Год «от» не может быть больше года «до».';

  @override
  String get filterYearManufactureSection => 'Год выпуска';

  @override
  String get filterYearFromShort => 'От';

  @override
  String get filterYearToShort => 'До';

  @override
  String get filterYearAny => 'Любой';

  @override
  String get filterMustBeNumber => 'Нужно число.';

  @override
  String get filterMustBeMaxYear => 'Должно быть ≤ максимального года.';

  @override
  String get filterMustBeMinYear => 'Должно быть ≥ минимального года.';

  @override
  String get filterType => 'Тип';

  @override
  String get typeAny => 'Любой';

  @override
  String get typeSale => 'Продажа';

  @override
  String get typeExchange => 'Обмен';

  @override
  String get typeBoth => 'Продажа или обмен';

  @override
  String get filterClear => 'Сбросить';

  @override
  String get filterApply => 'Применить';

  @override
  String get filterShowCars => 'Показать авто';

  @override
  String filterSummaryPriceUpTo(String amount) {
    return 'до $amount';
  }

  @override
  String filterSummaryPriceFrom(String amount) {
    return 'от $amount';
  }

  @override
  String filterSummaryPriceRangePlain(String min, String max) {
    return '$min–$max';
  }

  @override
  String filterSummaryPriceRangeWithSymbol(
    String symbol,
    String min,
    String max,
  ) {
    return '$symbol$min–$symbol$max';
  }

  @override
  String filterSummaryMileageUpTo(String amount) {
    return 'до $amount км';
  }

  @override
  String get filterSummaryAllListingsInRegionPm =>
      'Все объявления в Приднестровье';

  @override
  String get filterModel => 'Модель';

  @override
  String get filterModelHint => 'напр. Golf';

  @override
  String get filterPriceFrom => 'Цена от';

  @override
  String get filterPriceTo => 'Цена до';

  @override
  String get filterPriceBudgetHint => 'Укажите бюджет и валюту объявления.';

  @override
  String get filterPriceCurrencyLabel => 'Валюта объявления';

  @override
  String get filterPriceCurrencyAny => 'Любая';

  @override
  String get filterPriceCurrencyUsd => '\$';

  @override
  String get filterPriceCurrencyEur => '€';

  @override
  String get filterPriceChipPrefix => 'Цена';

  @override
  String get filterPriceCurrencyActiveUsd => 'Валюта: \$';

  @override
  String get filterPriceCurrencyActiveEur => 'Валюта: €';

  @override
  String get filterMaxMileage => 'Пробег до (км)';

  @override
  String get filterCity => 'Город';

  @override
  String get filterCityHint => 'напр. Тирасполь';

  @override
  String get filterSortLabel => 'Сортировка';

  @override
  String get filterSortNewestFirst => 'Сначала новые';

  @override
  String get filterSortPriceLowHigh => 'Цена: по возрастанию';

  @override
  String get filterSortPriceHighLow => 'Цена: по убыванию';

  @override
  String get filterSortNewestYear => 'Сначала новый год';

  @override
  String get filterSortLowestMileage => 'Сначала меньший пробег';

  @override
  String get filterMustBeMaxPrice => 'Должно быть ≤ максимальной цены.';

  @override
  String get filterMustBeMinPrice => 'Должно быть ≥ минимальной цены.';

  @override
  String get filtersSummaryDefaultTitle => 'Настройте подбор автомобиля';

  @override
  String get filtersSummaryDefaultHints => 'Марка · бюджет · кузов · регион';

  @override
  String get filtersSectionMakeModel => 'Марка и модель';

  @override
  String get filtersSectionBudget => 'Бюджет';

  @override
  String get filtersSectionYearMileageCaption => 'Год и пробег';

  @override
  String get filtersSectionVehicle => 'Автомобиль';

  @override
  String get filtersSectionLocation => 'Локация';

  @override
  String get filtersSectionBodyAndDeal => 'Кузов и сделка';

  @override
  String get listingDetailsTitle => 'Объявление';

  @override
  String get listingDetailsLoadFailed => 'Не удалось загрузить объявление.';

  @override
  String get userErrorNetworkCheckConnection =>
      'Проверьте подключение к интернету и попробуйте ещё раз.';

  @override
  String get userErrorGenericTryAgain =>
      'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get userErrorEmailAlreadyRegistered =>
      'Аккаунт с таким email уже существует.';

  @override
  String get userErrorWeakPassword =>
      'Пароль слишком простой. Попробуйте более надёжный пароль.';

  @override
  String get userErrorInsufficientPermission =>
      'Недостаточно прав для этого действия.';

  @override
  String get listingUnavailableOrDeleted =>
      'Объявление недоступно или было удалено.';

  @override
  String get userErrorUploadPhotoTryAgain =>
      'Не удалось загрузить фото. Попробуйте ещё раз.';

  @override
  String get listingDetailsSpecs => 'Характеристики';

  @override
  String get listingFieldMake => 'Марка';

  @override
  String get listingFieldModel => 'Модель';

  @override
  String get listingFieldYear => 'Год';

  @override
  String get listingFieldMileage => 'Пробег';

  @override
  String get listingFieldType => 'Тип';

  @override
  String get listingFieldCity => 'Город';

  @override
  String get listingFieldRegion => 'Регион';

  @override
  String get listingFieldBodyType => 'Кузов';

  @override
  String get listingFieldPosted => 'Опубликовано';

  @override
  String get listingFuelType => 'Топливо';

  @override
  String get listingEngineDisplacement => 'Объём двигателя';

  @override
  String get listingEnginePower => 'Мощность';

  @override
  String get listingDrivetrain => 'Привод';

  @override
  String get listingRegistration => 'Регистрация';

  @override
  String get listingDescription => 'Описание';

  @override
  String get listingEngineDisplacementHint => 'Литры, напр. 2.0';

  @override
  String get listingEnginePowerHint => 'Мощность в л.с.';

  @override
  String get listingRegistrationHint => 'Где оформлена регистрация';

  @override
  String get listingEngineDisplacementLitersSuffix => 'л';

  @override
  String get listingEngineDisplacementCcSuffix => 'см³';

  @override
  String get listingEnginePowerHpSuffix => 'л.с.';

  @override
  String get listingFuelTypePetrol => 'Бензин';

  @override
  String get listingFuelTypeDiesel => 'Дизель';

  @override
  String get listingFuelTypeHybrid => 'Гибрид';

  @override
  String get listingFuelTypeElectric => 'Электро';

  @override
  String get listingFuelTypeLpg => 'Газ (LPG)';

  @override
  String get listingFuelTypeCng => 'Метан (CNG)';

  @override
  String get listingFuelTypeOther => 'Другое';

  @override
  String get listingDrivetrainFwd => 'Передний';

  @override
  String get listingDrivetrainRwd => 'Задний';

  @override
  String get listingDrivetrainAwd => 'Полный (AWD)';

  @override
  String get listingDrivetrainFourWheel => '4×4';

  @override
  String get listingDetailsDescriptionSection => 'Описание';

  @override
  String get createListingSectionSpecsSubtitle =>
      'По желанию — помогают в поиске и фильтрах.';

  @override
  String get createListingSectionDescription => 'Описание';

  @override
  String get createListingSectionDescriptionSubtitle =>
      'Состояние, комплектация, сервис — своими словами.';

  @override
  String get createListingDescriptionLabel => 'Текст объявления';

  @override
  String get createListingDescriptionHint =>
      'Расскажите о машине своими словами…';

  @override
  String get editListingDescriptionLabel => 'Описание объявления';

  @override
  String get validationEngineDisplacementPositive =>
      'Укажите объём больше нуля (литры).';

  @override
  String get validationEnginePowerPositive =>
      'Укажите мощность больше нуля (л.с.).';

  @override
  String get validationRegistrationTooLong =>
      'Слишком длинное поле регистрации (макс. 200 символов).';

  @override
  String get contactSellerSection => 'Связаться с продавцом';

  @override
  String get contactShowPhone => 'Показать телефон';

  @override
  String get contactCopyPhone => 'Скопировать';

  @override
  String get contactPhoneCopied => 'Номер скопирован';

  @override
  String get contactPublicNotice =>
      'Контакты продавца видны в активных объявлениях.';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String contactTelegramLabel(String username) {
    return 'Telegram @$username';
  }

  @override
  String get contactWhatsapp => 'WhatsApp';

  @override
  String get contactActionFailed => 'Не удалось открыть действие.';

  @override
  String get chatLabel => 'Чат';

  @override
  String get chatNotAvailable => 'Чат пока недоступен.';

  @override
  String get messagingTitle => 'Сообщения';

  @override
  String get messagingSignInRequired => 'Войдите, чтобы написать продавцу.';

  @override
  String get messagingCannotMessageSelf =>
      'Нельзя написать самому себе по своему объявлению.';

  @override
  String get messagingUnavailableNoSeller =>
      'Чат для этого объявления недоступен.';

  @override
  String get messagingLoadFailed => 'Не удалось загрузить переписки.';

  @override
  String get messagingSendFailed =>
      'Не удалось отправить сообщение. Попробуйте ещё раз.';

  @override
  String get messagingNetworkError =>
      'Проверьте подключение к интернету и попробуйте ещё раз.';

  @override
  String get messagingServerError =>
      'Не удалось выполнить действие. Попробуйте ещё раз.';

  @override
  String get messagingConversationNotFound =>
      'Переписка не найдена или у вас нет доступа.';

  @override
  String get messagingInvalidMessage => 'Проверьте текст сообщения.';

  @override
  String get messagingEmptyTitle => 'Пока нет переписок';

  @override
  String get messagingEmptyBody =>
      'Напишите продавцу с экрана объявления — диалог появится здесь.';

  @override
  String get messagingNoPreview => 'Нет сообщений';

  @override
  String get messagingThreadEmptyBody =>
      'Начните переписку: задайте вопрос по объявлению или договоритесь о просмотре.';

  @override
  String get messagingThreadTitle => 'Чат';

  @override
  String get messagingThreadViewListingHint => 'Открыть объявление';

  @override
  String get messagingComposerHint => 'Сообщение…';

  @override
  String get messagingSend => 'Отправить';

  @override
  String get messagingDateToday => 'Сегодня';

  @override
  String get messagingDateYesterday => 'Вчера';

  @override
  String get messagingMessageCopied => 'Сообщение скопировано';

  @override
  String get messagingQuickReplyHint =>
      'Быстрые ответы — нажмите, чтобы вставить в поле ввода';

  @override
  String get messagingQuickReplyStillAvailable =>
      'Здравствуйте, объявление актуально?';

  @override
  String get messagingQuickReplyWhereToView =>
      'Где можно посмотреть автомобиль?';

  @override
  String get messagingQuickReplyNegotiable => 'Возможен торг?';

  @override
  String get messagingQuickReplyWhenCall => 'Когда удобно созвониться?';

  @override
  String messagingListingFallback(String shortId) {
    return 'Объявление $shortId';
  }

  @override
  String get phoneNotProvided => 'Телефон не указан';

  @override
  String get reportListing => 'Пожаловаться на объявление';

  @override
  String get reportListingDescription =>
      'Заметили подозрительную, неверную или недопустимую информацию? Сообщите нам.';

  @override
  String get reportListingMailFailed =>
      'Не удалось открыть почтовое приложение.';

  @override
  String get formatTypeSale => 'Продажа';

  @override
  String get formatTypeExchange => 'Обмен';

  @override
  String get formatTypeBoth => 'Продажа или обмен';

  @override
  String get statusActive => 'Активно';

  @override
  String get statusHidden => 'Скрыто';

  @override
  String get statusSold => 'Продано';

  @override
  String get statusArchived => 'В архиве';

  @override
  String get publicContactNotice =>
      'Ваш телефон и выбранные способы связи будут видны в активных объявлениях. Указывайте только те контакты, которыми готовы поделиться публично.';

  @override
  String get createListingTitle => 'Подать объявление';

  @override
  String get createListingComposeEyebrow => 'Новое объявление · Carzon';

  @override
  String get createListingComposeHeadline => 'Создайте объявление';

  @override
  String get createListingComposeSubtitle =>
      'Подготовьте карточку автомобиля: фото, характеристики и аккуратные контакты — чтобы покупатель сразу увидел главное.';

  @override
  String get createListingSectionPhotosLead => 'Фото и заголовок';

  @override
  String get createListingSectionPhotosLeadSubtitle =>
      'Обложка каталога и необязательный заголовок.';

  @override
  String get createListingSectionVehicle => 'Об автомобиле';

  @override
  String get createListingSectionVehicleSubtitle =>
      'Город, марка, модель, год и характеристики.';

  @override
  String get createListingSectionDeal => 'Сделка и рынок';

  @override
  String get createListingSectionDealSubtitle => 'Тип сделки и регион показа.';

  @override
  String get createListingSectionPrice => 'Цена и пробег';

  @override
  String get createListingSectionPriceSubtitle => 'Валюта и фактические цифры.';

  @override
  String get createListingSectionPublish => 'Контакты и публикация';

  @override
  String get createListingSectionPublishSubtitle =>
      'Контакты будут видны в активном объявлении.';

  @override
  String get createListingPublishKicker => 'Финальный шаг';

  @override
  String get createListingSignInRequired => 'Войдите, чтобы подать объявление.';

  @override
  String get fieldTitle => 'Заголовок';

  @override
  String get fieldTitleOptional => 'Заголовок (необязательно)';

  @override
  String get listingTitleFallbackDefault => 'Объявление о продаже автомобиля';

  @override
  String get fieldMake => 'Марка';

  @override
  String get fieldModel => 'Модель';

  @override
  String get fieldYear => 'Год';

  @override
  String get fieldPriceEur => 'Цена (EUR)';

  @override
  String get createListingMediaTitle => 'Фото объявления';

  @override
  String get createListingMediaSubtitle =>
      'Первое фото станет главным на карточке.';

  @override
  String get createListingMediaHeroEmptyHint =>
      'Нажмите, чтобы добавить фото объявления. До девяти снимков — по одному из галереи.';

  @override
  String get createListingMediaCoverHint => 'Обложка каталога';

  @override
  String get createListingHeroEmptyTitle => 'Добавьте фотографии автомобиля';

  @override
  String get createListingHeroEmptyDetail =>
      'До девяти снимков из галереи. Начните с удачного ракурса.';

  @override
  String get createListingAddPhoto => 'Добавить фото';

  @override
  String get createListingAddMorePhotos => 'Ещё фото';

  @override
  String createListingMaxPhotos(int count) {
    return 'Можно не больше $count фотографий.';
  }

  @override
  String get createListingRemovePhoto => 'Удалить фото';

  @override
  String get createListingCoverBadge => 'Обложка';

  @override
  String get createListingPriceAmount => 'Цена — сумма';

  @override
  String get createListingCurrency => 'Валюта';

  @override
  String get currencyCodeEur => 'EUR';

  @override
  String get currencyCodeUsd => 'USD';

  @override
  String get createListingBrandLabel => 'Марка';

  @override
  String get createListingChooseBrand => 'Выберите марку';

  @override
  String get createListingBrandOther => 'Другая';

  @override
  String get createListingCustomBrandHint => 'Укажите марку';

  @override
  String get createListingYearLabel => 'Год выпуска';

  @override
  String get createListingChooseYear => 'Выберите год';

  @override
  String get createListingPhotosUploadFailed =>
      'Не удалось загрузить фото. Попробуйте ещё раз.';

  @override
  String get commonDone => 'Готово';

  @override
  String get createListingSearchBrandsHint => 'Поиск марки';

  @override
  String get fieldMileageKm => 'Пробег (км)';

  @override
  String get fieldType => 'Тип';

  @override
  String get fieldRegion => 'Регион';

  @override
  String get fieldCity => 'Город';

  @override
  String get fieldPhone => 'Номер телефона';

  @override
  String get fieldPhoneHint => '+373 ...';

  @override
  String get fieldTelegram => 'Ник в Telegram (необязательно)';

  @override
  String get fieldTelegramHint => '@username';

  @override
  String get whatsappToggle => 'WhatsApp доступен по этому номеру';

  @override
  String get regionRequired => 'Выберите регион.';

  @override
  String get validationRequired => 'Обязательно';

  @override
  String validationYearRange(int maxYear) {
    return '1900–$maxYear';
  }

  @override
  String get validationPositive => 'Должно быть > 0';

  @override
  String get validationNonNegative => 'Должно быть ≥ 0';

  @override
  String get coverPhotoOptional => 'Обложка (необязательно)';

  @override
  String get coverRemoveTooltip => 'Удалить фото';

  @override
  String get coverAddPhoto => 'Добавить фото';

  @override
  String get publishListing => 'Опубликовать';

  @override
  String get listingCreated => 'Объявление создано.';

  @override
  String get listingCreateFailed => 'Не удалось создать объявление.';

  @override
  String get imageLoadFailed =>
      'Не удалось загрузить изображение. Попробуйте ещё раз.';

  @override
  String get coverUploadFailedRetry =>
      'Не удалось загрузить фото обложки. Попробуйте ещё раз.';

  @override
  String get listingCreateFailedRetry =>
      'Не удалось создать объявление. Попробуйте ещё раз.';

  @override
  String get imagePickerLoadFailed =>
      'Не удалось выбрать фото. Попробуйте другое изображение.';

  @override
  String get listingCreateSessionExpired =>
      'Сессия истекла или доступ запрещён. Войдите снова и повторите попытку.';

  @override
  String get listingCreateServiceUnavailable =>
      'Сервис временно недоступен. Попробуйте позже.';

  @override
  String get listingCreateVinInvalidServer =>
      'VIN-код некорректен. Проверьте 17 символов или оставьте поле пустым.';

  @override
  String get listingCreateRpcNotReady =>
      'Сервер ещё не готов принять новые данные объявления. Попробуйте позже или обновите приложение.';

  @override
  String get listingCreatePermissionDenied =>
      'Нет прав для создания объявления. Войдите в аккаунт ещё раз.';

  @override
  String get listingCreateCheckConstraint =>
      'Некоторые данные объявления имеют некорректный формат. Проверьте поля и попробуйте снова.';

  @override
  String get editListingTitle => 'Редактировать объявление';

  @override
  String get editListingLoadFailed =>
      'Не удалось загрузить объявление. Попробуйте ещё раз.';

  @override
  String get listingUpdated => 'Объявление обновлено.';

  @override
  String get listingUpdateFailedRetry =>
      'Не удалось обновить объявление. Попробуйте ещё раз.';

  @override
  String get notAllowedEdit =>
      'У вас нет прав на редактирование этого объявления.';

  @override
  String get checkDetailsAndRetry =>
      'Проверьте данные объявления и попробуйте ещё раз.';

  @override
  String get coverUpdateFailedRetry =>
      'Не удалось обновить фото обложки. Попробуйте ещё раз.';

  @override
  String get coverPhotoLabel => 'Обложка';

  @override
  String get coverChangePhoto => 'Изменить фото';

  @override
  String get coverCancelChange => 'Отменить изменение';

  @override
  String get coverCancelRemoval => 'Отменить удаление';

  @override
  String get coverReplacePhoto => 'Заменить фото';

  @override
  String get coverRemovePhoto => 'Удалить фото';

  @override
  String get coverWillBeRemovedNotice =>
      'Фото обложки будет удалено после сохранения.';

  @override
  String get coverWillBeReplacedNotice =>
      'Новое фото будет загружено после сохранения.';

  @override
  String get coverPlaceholderWillBeRemoved => 'Обложка будет удалена';

  @override
  String get saveChanges => 'Сохранить';

  @override
  String get editListingGalleryReadOnlyHint =>
      'Галерея не загрузилась. Фото ниже только для справки; изменить их сейчас нельзя — сохранятся текст и другие поля объявления.';

  @override
  String get editListingGalleryReplaceFailed =>
      'Не удалось обновить фотографии. Попробуйте ещё раз.';

  @override
  String get myListingsTitle => 'Мои объявления';

  @override
  String get myListingsSignInRequired =>
      'Войдите, чтобы увидеть свои объявления.';

  @override
  String get myListingsLoadFailed => 'Не удалось загрузить ваши объявления.';

  @override
  String get myListingsEmpty => 'Вы ещё не опубликовали ни одного объявления.';

  @override
  String get myListingsEmptyTitle => 'У вас пока нет объявлений';

  @override
  String get myListingsEmptyBody =>
      'Подайте первое объявление — оно появится здесь после публикации.';

  @override
  String get myListingsSellCta => 'Подать объявление';

  @override
  String get myListingActionsTooltip => 'Действия с объявлением';

  @override
  String get actionEdit => 'Редактировать';

  @override
  String get actionReactivate => 'Активировать';

  @override
  String get actionMarkSold => 'Отметить как проданное';

  @override
  String get actionHide => 'Скрыть';

  @override
  String get actionArchive => 'В архив';

  @override
  String get actionDeletePermanently => 'Удалить навсегда';

  @override
  String get deleteDialogTitle => 'Удалить объявление?';

  @override
  String get deleteDialogBody =>
      'Объявление будет безвозвратно удалено из Carzon. Оно перестанет показываться пользователям и исчезнет у всех, кто добавил его в избранное.';

  @override
  String get notAllowedUpdateStatus =>
      'У вас нет прав на обновление этого объявления.';

  @override
  String get statusNotSupported => 'Этот статус объявления не поддерживается.';

  @override
  String get updateStatusFailedRetry =>
      'Не удалось обновить статус объявления. Попробуйте ещё раз.';

  @override
  String get notAllowedDelete => 'У вас нет прав на удаление этого объявления.';

  @override
  String get listingNotFound => 'Это объявление больше не существует.';

  @override
  String get deleteListingFailedRetry =>
      'Не удалось удалить объявление. Попробуйте ещё раз.';

  @override
  String get favoritesTitle => 'Избранное';

  @override
  String get favoritesSignInRequired =>
      'Войдите, чтобы увидеть избранные объявления.';

  @override
  String get favoritesLoadFailed => 'Не удалось загрузить избранное.';

  @override
  String get favoritesEmpty => 'Пока ничего не добавлено в избранное.';

  @override
  String get favoritesEmptyTitle => 'В избранном пока пусто';

  @override
  String get favoritesEmptyBody =>
      'Добавляйте объявления в избранное, чтобы быстро вернуться к ним позже.';

  @override
  String get favoritesEmptyBrowse => 'Смотреть объявления';

  @override
  String get favoriteAdd => 'В избранное';

  @override
  String get favoriteRemove => 'Убрать из избранного';

  @override
  String get favoriteSignInRequired => 'Войдите, чтобы добавлять в избранное.';

  @override
  String get favoriteToggleFailed =>
      'Не удалось обновить избранное. Попробуйте ещё раз.';

  @override
  String get profileTitle => 'Аккаунт';

  @override
  String get profileSignInRequired => 'Войдите, чтобы управлять аккаунтом.';

  @override
  String get profileSignedInFallback => 'Вы вошли в систему';

  @override
  String get profileSignOutFailedRetry =>
      'Не удалось выйти. Попробуйте ещё раз.';

  @override
  String get profileMyListings => 'Мои объявления';

  @override
  String get profileFavorites => 'Избранное';

  @override
  String get profileCreateListing => 'Подать объявление';

  @override
  String get profileLegal => 'Условия и конфиденциальность';

  @override
  String get profileSignOut => 'Выйти';

  @override
  String get accountAvatarOpenProfileTooltip => 'Аккаунт и настройки';

  @override
  String get profileActivitySectionTitle => 'Активность';

  @override
  String get profileMessagesUnreadStatus => 'Есть непрочитанные сообщения';

  @override
  String get profileMessagesNoUnreadStatus => 'Новых сообщений нет';

  @override
  String get profileMessagesUnreadCountOverflow => '99+';

  @override
  String get profilePublicSellerProfileSectionTitle =>
      'Публичный профиль продавца';

  @override
  String get profilePublicSellerProfileSectionSubtitle =>
      'Покупатели видят это в ваших объявлениях и на странице продавца.';

  @override
  String get profilePublicSellerBuyerPreviewCaption =>
      'Так вас видят покупатели';

  @override
  String get profileSettingsSectionTitle => 'Настройки';

  @override
  String get profileDarkThemeTitle => 'Тёмная тема';

  @override
  String get profileDarkThemeSubtitle =>
      'Переключает интерфейс приложения на тёмный режим.';

  @override
  String get profileLanguageTitle => 'Язык приложения';

  @override
  String get profileLanguageCurrentRussian => 'Русский';

  @override
  String get profileLanguageCurrentRomanian => 'Română';

  @override
  String get profileLanguageOptionRussian => 'Русский';

  @override
  String get profileLanguageOptionRomanian => 'Română';

  @override
  String get profileNotificationsTitle => 'Уведомления';

  @override
  String get profileNotificationsSubtitle =>
      'Push, сообщения и статус доставки (тестирование).';

  @override
  String get notificationSettingsTitle => 'Уведомления';

  @override
  String get notificationSettingsSignInRequired =>
      'Войдите, чтобы настроить уведомления.';

  @override
  String get notificationSettingsLoadFailed =>
      'Не удалось загрузить настройки уведомлений.';

  @override
  String get notificationSettingsSaveFailed =>
      'Не удалось сохранить. Попробуйте ещё раз.';

  @override
  String get notificationSettingsOsPermissionDenied =>
      'Разрешение уведомлений не получено. Включите его в настройках системы, если нужны push.';

  @override
  String get notificationSettingsPushUnavailableInBuild =>
      'Push в этой сборке недоступен (PUSH_NOTIFICATIONS_ENABLED).';

  @override
  String get notificationSettingsPushBuildDisabledBanner =>
      'В этой сборке push-уведомления выключены на уровне конфигурации. Переключатели ниже недоступны.';

  @override
  String get notificationSettingsGlobalTitle => 'Уведомления в приложении';

  @override
  String get notificationSettingsGlobalSubtitle =>
      'Общий переключатель. При включении система может запросить разрешение на уведомления.';

  @override
  String get notificationSettingsMessagesTitle => 'Сообщения';

  @override
  String get notificationSettingsMessagesSubtitle =>
      'Push о новых сообщениях в чатах (когда доставка будет доступна).';

  @override
  String get notificationSettingsMessagesNeedsGlobal =>
      'Сначала включите «Уведомления в приложении».';

  @override
  String get notificationSettingsFilterAlertsTitle => 'Оповещения по фильтру';

  @override
  String get notificationSettingsFilterAlertsSubtitle =>
      'Разрешите уведомления, чтобы получать push при новых объявлениях по сохранённому фильтру. Доставка на устройстве всё ещё проверяется.';

  @override
  String get notificationSettingsFilterAlertsNeedsGlobal =>
      'Сначала включите «Уведомления в приложении».';

  @override
  String get notificationSettingsDeliveryDisclaimer =>
      'Функция реализована на сервере и в приложении; финальная доставка на устройство всё ещё проверяется.';

  @override
  String get notificationSettingsOsStatusAuthorized =>
      'Система: уведомления разрешены.';

  @override
  String get notificationSettingsOsStatusProvisional =>
      'Система: временные (provisional) уведомления.';

  @override
  String get notificationSettingsOsStatusDenied =>
      'Система: уведомления отклонены.';

  @override
  String get notificationSettingsOsStatusNotDetermined =>
      'Система: разрешение ещё не запрашивалось или неизвестно.';

  @override
  String get profileListingAlertsTitle => 'Оповещения по фильтру';

  @override
  String get profileListingAlertsSubtitle =>
      'Один фильтр для будущих уведомлений по новым авто.';

  @override
  String get filterAlertEditorEyebrow => 'CARZON · ОПОВЕЩЕНИЯ';

  @override
  String get filterAlertEditorTitle => 'Фильтр оповещений';

  @override
  String get filterAlertEditorSubtitle => 'Выберите параметры авто';

  @override
  String get filterAlertSaveFilterAction => 'Сохранить фильтр';

  @override
  String get filterAlertProfileRowSubtitle =>
      'Просмотрите сохранённый фильтр и управляйте доставкой оповещений.';

  @override
  String get filterAlertSavedSuccess => 'Фильтр сохранён';

  @override
  String get filterAlertUpdatedSuccess => 'Фильтр обновлён';

  @override
  String get filterAlertSaveFailed => 'Не удалось сохранить фильтр';

  @override
  String get filterAlertLoadFailed => 'Не удалось загрузить настройки.';

  @override
  String get filterAlertSignInRequired =>
      'Войдите, чтобы настроить фильтр для оповещений.';

  @override
  String get filterAlertApplyBlockedValidation =>
      'Исправьте ошибки в фильтре, затем сохраните снова.';

  @override
  String get filterAlertResetPersistedSuccess =>
      'Фильтр для оповещений сброшен';

  @override
  String get filterAlertResetFailed =>
      'Не удалось сбросить фильтр для оповещений.';

  @override
  String get filterAlertNotificationsToggleTitle =>
      'Уведомления о новых объявлениях';

  @override
  String get filterAlertNotificationsToggleSubtitle =>
      'По сохранённому фильтру. Доставка на устройство всё ещё проверяется.';

  @override
  String get filterAlertNotificationsNeedsSavedFilter =>
      'Сначала сохраните фильтр кнопкой ниже.';

  @override
  String get filterAlertNotificationsPushDisabled =>
      'В этой сборке push недоступен (PUSH_NOTIFICATIONS_ENABLED).';

  @override
  String get filterAlertManagementHeaderEyebrow => 'CARZON · ОПОВЕЩЕНИЯ';

  @override
  String get filterAlertManagementSubtitle =>
      'Управляйте сохранённым фильтром и доставкой оповещений. Уведомления настраиваются в фильтрах каталога.';

  @override
  String get filterAlertManagementDeliveryOnLabel =>
      'Доставка оповещений включена';

  @override
  String get filterAlertManagementDeliveryOffLabel =>
      'Доставка оповещений выключена';

  @override
  String get filterAlertManagementCriteriaSectionTitle => 'Параметры фильтра';

  @override
  String get filterAlertManagementEditAction => 'Изменить в каталоге';

  @override
  String get filterAlertManagementDisableAction => 'Выключить оповещения';

  @override
  String get filterAlertManagementClearAction => 'Удалить сохранённый фильтр';

  @override
  String get filterAlertManagementClearConfirmTitle =>
      'Удалить сохранённый фильтр?';

  @override
  String get filterAlertManagementClearConfirmBody =>
      'Параметры фильтра будут стёрты. Доставка push также выключится. Действие можно повторить из каталога.';

  @override
  String get filterAlertManagementClearConfirmCta => 'Удалить';

  @override
  String get filterAlertManagementEmptyTitle =>
      'Сохранённого оповещения пока нет';

  @override
  String get filterAlertManagementEmptyBody =>
      'Создавайте оповещения в фильтрах каталога: задайте параметры поиска и нажмите колокольчик.';

  @override
  String get filterAlertManagementGoToCatalog => 'Перейти в каталог';

  @override
  String get filterAlertManagementDeliveryDisabledSnack =>
      'Оповещения по фильтру выключены.';

  @override
  String get filterAlertManagementClearedSnack => 'Сохранённый фильтр удалён.';

  @override
  String get filterAlertSummarySearchLabel => 'Поиск';

  @override
  String get filterAlertSummaryMileageLabel => 'Пробег';

  @override
  String get profilePublicSellerNameTitle => 'Публичное имя продавца';

  @override
  String get profilePublicSellerNameDescription =>
      'Это имя будут видеть покупатели в ваших объявлениях и в профиле продавца.';

  @override
  String get profilePublicSellerNameFieldLabel => 'Имя для покупателей';

  @override
  String get profilePublicSellerNameFieldHint =>
      'Например: Анна или «Авто-Плюс Тирасполь»';

  @override
  String get profilePublicSellerNameSave => 'Сохранить';

  @override
  String get profilePublicSellerNameSaved => 'Имя сохранено';

  @override
  String get profilePublicSellerNameSaveFailed =>
      'Не удалось сохранить имя. Попробуйте ещё раз.';

  @override
  String get profilePublicSellerNameTooLong =>
      'Слишком длинное имя (максимум 80 символов).';

  @override
  String get profilePublicSellerNameLooksLikeEmail =>
      'Укажите имя, а не адрес email.';

  @override
  String get profilePublicSellerNameLoadFailed =>
      'Не удалось загрузить настройки имени продавца.';

  @override
  String get profilePublicSellerAvatarTitle => 'Фото продавца';

  @override
  String get profilePublicSellerAvatarDescription =>
      'Эту фотографию будут видеть покупатели рядом с вашим именем в объявлениях и в профиле продавца.';

  @override
  String get profilePublicSellerAvatarChangePhoto => 'Выбрать фото';

  @override
  String get profilePublicSellerAvatarRemovePhoto => 'Удалить фото';

  @override
  String get profilePublicSellerAvatarUpdated => 'Фото обновлено';

  @override
  String get profilePublicSellerAvatarRemoved => 'Фото удалено';

  @override
  String get profilePublicSellerAvatarUploadFailed =>
      'Не удалось загрузить фото. Попробуйте ещё раз.';

  @override
  String get profilePublicSellerAvatarRemoveFailed =>
      'Не удалось удалить фото. Попробуйте ещё раз.';

  @override
  String get profilePublicSellerAvatarUnsupportedType =>
      'Поддерживаются только JPEG, PNG или WebP.';

  @override
  String get signInTitle => 'Вход';

  @override
  String get signInSubmit => 'Войти';

  @override
  String get signInError => 'Ошибка входа';

  @override
  String get signInInvalidCredentials => 'Неверный email или пароль.';

  @override
  String get signInFailedRetry => 'Не удалось войти. Попробуйте ещё раз.';

  @override
  String get signUpFailedRetry =>
      'Не удалось создать аккаунт. Попробуйте ещё раз.';

  @override
  String get signOutFailedRetry => 'Не удалось выйти. Попробуйте ещё раз.';

  @override
  String get authFieldEmail => 'Email';

  @override
  String get authFieldPassword => 'Пароль';

  @override
  String get authFieldConfirmPassword => 'Подтвердите пароль';

  @override
  String get validationEmailRequired => 'Введите email';

  @override
  String get validationEmailInvalid => 'Введите корректный email';

  @override
  String get validationPasswordRequired => 'Введите пароль';

  @override
  String get validationPasswordMin => 'Минимум 6 символов';

  @override
  String get validationConfirmPassword => 'Подтвердите пароль';

  @override
  String get validationPasswordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get signInForgotPassword => 'Забыли пароль?';

  @override
  String get signInCreateAccount => 'Создать аккаунт';

  @override
  String get legalLink => 'Условия и конфиденциальность';

  @override
  String get signUpTitle => 'Создать аккаунт';

  @override
  String get signUpSubmit => 'Создать аккаунт';

  @override
  String get signUpError => 'Ошибка регистрации';

  @override
  String get signUpHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get signUpConfirmEmail =>
      'Проверьте почту, чтобы подтвердить аккаунт.';

  @override
  String get forgotPasswordTitle => 'Восстановление пароля';

  @override
  String get forgotPasswordIntro =>
      'Введите email аккаунта — мы пришлём инструкции по сбросу пароля.';

  @override
  String get forgotPasswordSubmit => 'Отправить письмо';

  @override
  String get forgotPasswordSuccess =>
      'Если аккаунт с такой почтой существует, мы отправили инструкции по сбросу пароля.';

  @override
  String get forgotPasswordFailedRetry =>
      'Не удалось отправить письмо. Попробуйте ещё раз.';

  @override
  String get forgotPasswordEmailEmpty => 'Введите email.';

  @override
  String get backToSignIn => 'Вернуться ко входу';

  @override
  String get resetPasswordTitle => 'Новый пароль';

  @override
  String get resetPasswordNoSession =>
      'Откройте ссылку для сброса из письма, чтобы продолжить.';

  @override
  String get resetPasswordIntro => 'Выберите новый пароль для своего аккаунта.';

  @override
  String get resetPasswordNew => 'Новый пароль';

  @override
  String get resetPasswordConfirmNew => 'Подтвердите новый пароль';

  @override
  String get resetPasswordSuccess => 'Пароль обновлён. Теперь вы можете войти.';

  @override
  String get resetPasswordFailedRetry =>
      'Не удалось обновить пароль. Попробуйте ещё раз.';

  @override
  String get resetPasswordSubmit => 'Обновить пароль';

  @override
  String get resetPasswordValidationNew => 'Введите новый пароль.';

  @override
  String resetPasswordValidationMin(int min) {
    return 'Пароль должен содержать не менее $min символов.';
  }

  @override
  String get resetPasswordValidationMismatch => 'Пароли не совпадают.';

  @override
  String get phoneRequired => 'Введите номер телефона.';

  @override
  String get phoneInvalidChars => 'Разрешены только цифры, пробелы, + ( ) -.';

  @override
  String get phoneInvalid => 'Введите корректный номер телефона.';

  @override
  String get telegramInvalid => '5–32 символа: буквы, цифры или подчёркивания.';

  @override
  String get reportSubjectPrefix => 'Жалоба на объявление Carzon';

  @override
  String get reportBodyIntro =>
      'Хочу пожаловаться на следующее объявление Carzon:';

  @override
  String get reportBodyFieldTitle => 'Заголовок';

  @override
  String get reportBodyFieldListingId => 'ID объявления';

  @override
  String get reportBodyFieldMmy => 'Марка / Модель / Год';

  @override
  String get reportBodyFieldCity => 'Город';

  @override
  String get reportBodyFieldRegion => 'Регион';

  @override
  String get reportBodyPrompt =>
      'Опишите, что подозрительно, неверно или недопустимо в этом объявлении:';

  @override
  String get legalTitle => 'Условия и конфиденциальность';

  @override
  String get legalDisclaimer =>
      'Это ознакомительная версия условий и уведомления о конфиденциальности. Документ описывает, как сейчас работает Carzon, и не заменяет юридически выверенные условия. Пользуйтесь им как информационным материалом на ранней стадии продукта.';

  @override
  String get legalSectionAboutHeading => 'О Carzon';

  @override
  String get legalSectionAboutP1 =>
      'Carzon — это площадка для объявлений о продаже и обмене автомобилей в Молдове и Приднестровье. Сервис помогает владельцам размещать объявления, а покупателям — находить машины и связываться с продавцами.';

  @override
  String get legalSectionAboutP2 =>
      'Carzon не продаёт автомобили самостоятельно. Каждое объявление создаётся и принадлежит конкретному пользователю.';

  @override
  String get legalSectionListingsHeading => 'Объявления на площадке';

  @override
  String get legalSectionListingsP1 =>
      'После публикации объявление становится активным и может отображаться другим пользователям Carzon в общей ленте и на странице объявления.';

  @override
  String get legalSectionListingsP2 =>
      'Вы отвечаете за точность данных, которые публикуете: марка, модель, год, цена, пробег, регион, фотографии и контактная информация.';

  @override
  String get legalSectionListingsP3 =>
      'Свои объявления вы можете скрыть, отметить как проданные, повторно активировать или отправить в архив в разделе «Мои объявления».';

  @override
  String get legalSectionContactHeading => 'Публичные контакты продавца';

  @override
  String get legalSectionContactP1 =>
      'Пока ваше объявление активно, указанные для него контакты могут быть видны любым пользователям Carzon, в том числе без входа в аккаунт.';

  @override
  String get legalSectionContactP2 =>
      'Это может быть номер телефона, ник в Telegram (если указан) и отметка о том, что по номеру доступен WhatsApp.';

  @override
  String get legalSectionContactP3 =>
      'Указывайте только те контакты, которыми готовы поделиться публично для продажи или обмена автомобиля. Вы можете изменить или удалить их, отредактировав объявление или скрыв его, отправив в архив либо отметив как проданное.';

  @override
  String get legalSectionPhotosHeading =>
      'Фотографии и изображения в объявлениях';

  @override
  String get legalSectionPhotosP1 =>
      'Фотографии, прикреплённые к объявлению, хранятся в публичном хранилище изображений и могут быть видны всем, пока объявление активно.';

  @override
  String get legalSectionPhotosP2 =>
      'Загружайте только те фотографии, которыми имеете право делиться. Не публикуйте личные документы, номерные знаки, которые не хотите показывать, и изображения людей, которые не давали на это согласия.';

  @override
  String get legalSectionAccountHeading => 'Аккаунт и вход';

  @override
  String get legalSectionAccountP1 =>
      'Для публикации объявлений, добавления в избранное и работы с разделом «Мои объявления» нужен аккаунт. Аккаунты управляются по email и паролю.';

  @override
  String get legalSectionAccountP2 =>
      'Вы отвечаете за сохранность своего пароля и за любые действия, выполненные из вашего аккаунта. Если вы подозреваете, что кто-то получил доступ к вашему аккаунту, выйдите из него и смените пароль.';

  @override
  String get legalSectionFavoritesHeading => 'Избранное';

  @override
  String get legalSectionFavoritesP1 =>
      'Избранное видно только вам. Другие пользователи не знают, какие объявления вы добавили в избранное.';

  @override
  String get legalSectionSafetyHeading => 'Безопасность и ответственность';

  @override
  String get legalSectionSafetyP1 =>
      'На данный момент Carzon не проводит платежи внутри приложения, не предоставляет эскроу, не инспектирует автомобили, не гарантирует сделки и не проверяет право собственности. Все сделки происходят напрямую между покупателем и продавцом вне платформы.';

  @override
  String get legalSectionSafetyP2 =>
      'Перед покупкой, продажей или обменом проверяйте документы, состояние автомобиля и личность второй стороны. Встречайтесь в безопасном месте и не переводите деньги заранее, опираясь только на объявление.';

  @override
  String get legalSectionSafetyP3 =>
      'Carzon не является стороной соглашений между покупателем и продавцом и не отвечает за результат сделок, оформленных через платформу.';

  @override
  String get legalSectionContactUsHeading => 'Обратная связь';

  @override
  String get legalSectionContactUsP1 =>
      'Эти условия и уведомление о конфиденциальности могут обновляться по мере развития Carzon. Продолжая пользоваться приложением после обновления, вы принимаете новую версию документа.';

  @override
  String get legalSectionContactUsP2 =>
      'Вопросы по этому документу и по содержимому платформы можно задать команде Carzon через канал поддержки, указанный на странице приложения в магазине.';

  @override
  String get sellerSectionTitle => 'Продавец';

  @override
  String get sellerViewProfile => 'Смотреть профиль';

  @override
  String get sellerProfileTitle => 'Профиль продавца';

  @override
  String get sellerFallbackName => 'Продавец';

  @override
  String get sellerUnavailableTitle => 'Профиль продавца недоступен';

  @override
  String get sellerUnavailableMessage => 'Этот профиль скрыт или недоступен.';

  @override
  String get sellerListingsSectionTitle => 'Объявления продавца';

  @override
  String get sellerNoActiveListingsTitle => 'Нет активных объявлений';

  @override
  String get sellerNoActiveListingsMessage =>
      'У продавца сейчас нет активных объявлений в каталоге.';

  @override
  String get sellerMonthGenitiveJanuary => 'января';

  @override
  String get sellerMonthGenitiveFebruary => 'февраля';

  @override
  String get sellerMonthGenitiveMarch => 'марта';

  @override
  String get sellerMonthGenitiveApril => 'апреля';

  @override
  String get sellerMonthGenitiveMay => 'мая';

  @override
  String get sellerMonthGenitiveJune => 'июня';

  @override
  String get sellerMonthGenitiveJuly => 'июля';

  @override
  String get sellerMonthGenitiveAugust => 'августа';

  @override
  String get sellerMonthGenitiveSeptember => 'сентября';

  @override
  String get sellerMonthGenitiveOctober => 'октября';

  @override
  String get sellerMonthGenitiveNovember => 'ноября';

  @override
  String get sellerMonthGenitiveDecember => 'декабря';

  @override
  String sellerMemberSince(String monthYear) {
    return 'На Carzon с $monthYear';
  }

  @override
  String sellerActiveListingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активных объявлений',
      many: '$count активных объявлений',
      few: '$count активных объявления',
      one: '$count активное объявление',
    );
    return '$_temp0';
  }

  @override
  String get sellerTypePrivate => 'Частный продавец';

  @override
  String get sellerTypeDealer => 'Дилер';

  @override
  String get sellerProfileLoadFailed =>
      'Не удалось загрузить профиль продавца.';

  @override
  String get sellerListingsLoadFailed => 'Не удалось загрузить объявления.';

  @override
  String get sellerLoadMore => 'Показать ещё';

  @override
  String get listingVinFieldLabel => 'VIN-код';

  @override
  String get listingVinFieldHelper =>
      'Необязательно. VIN помогает добавить к объявлению базовую информацию об автомобиле и повышает доверие покупателей. Полный VIN публично не показывается.';

  @override
  String get validationVinInvalid =>
      'Введите корректный VIN из 17 символов или оставьте поле пустым.';

  @override
  String get listingVinBadgeIndicated => 'VIN указан';

  @override
  String get listingVinReportOpenHint => 'Открыть отчёт по VIN';

  @override
  String get listingVinNotProvidedTitle => 'VIN-код не указан';

  @override
  String get listingVinNotProvidedHint => 'Продавец не добавил VIN';

  @override
  String get menuCompare => 'Сравнение';

  @override
  String get compareTitle => 'Сравнение';

  @override
  String get compareVehiclesTitle => 'Сравнение автомобилей';

  @override
  String get compareEmptyBody =>
      'Добавьте 2–3 автомобиля, чтобы сравнить цену, пробег, характеристики и VIN-статус.';

  @override
  String get compareGoToListings => 'Перейти к объявлениям';

  @override
  String get compareAddOneMoreTitle => 'Добавьте ещё один автомобиль';

  @override
  String get compareAddOneMoreBody =>
      'Для сравнения нужно минимум два автомобиля. Добавьте ещё одно объявление из каталога.';

  @override
  String get compareClear => 'Очистить сравнение';

  @override
  String get compareMaxReachedMessage =>
      'Можно сравнить не более 3 автомобилей';

  @override
  String get compareTrayMaxLimitTitle => 'Максимум 3 автомобиля';

  @override
  String get compareTrayMaxLimitHint =>
      'Удалите одно авто, чтобы добавить другое';

  @override
  String get compareAddedMessage => 'Добавлено к сравнению';

  @override
  String get compareRemovedMessage => 'Удалено из сравнения';

  @override
  String get compareAddTooltip => 'Добавить к сравнению';

  @override
  String get compareRemoveTooltip => 'Убрать из сравнения';

  @override
  String get compareTrayOneVehicle => '1 авто в сравнении';

  @override
  String compareTrayVehicleCount(int count) {
    return '$count авто в сравнении';
  }

  @override
  String get compareTrayAddOneMore => 'Добавьте ещё одно';

  @override
  String get compareTrayOpen => 'Сравнить';

  @override
  String compareVehicleCountShort(int count) {
    return '$count авто';
  }

  @override
  String get compareShowOnlyDifferences => 'Показать только отличия';

  @override
  String get compareNoDifferences => 'Отличий по выбранным полям нет';

  @override
  String get compareRemoveVehicle => 'Убрать из сравнения';

  @override
  String get compareUnavailableListing => 'Объявление недоступно';

  @override
  String get compareInactiveListing => 'Снято с публикации';

  @override
  String get compareSectionPriceBasics => 'Цена и базовое';

  @override
  String get compareSectionVehicle => 'Автомобиль';

  @override
  String get compareSectionSpecs => 'Характеристики';

  @override
  String get compareSectionTrustData => 'Доверие / данные';

  @override
  String get compareRowPrice => 'Цена';

  @override
  String get compareRowYear => 'Год';

  @override
  String get compareRowMileage => 'Пробег';

  @override
  String get compareRowCityRegion => 'Город / регион';

  @override
  String get compareRowStatus => 'Статус объявления';

  @override
  String get compareRowMake => 'Марка';

  @override
  String get compareRowModel => 'Модель';

  @override
  String get compareRowBody => 'Кузов';

  @override
  String get compareRowVehicleType => 'Тип транспорта';

  @override
  String get compareRowRegistration => 'Регистрация';

  @override
  String get compareRowFuel => 'Топливо';

  @override
  String get compareRowEngine => 'Двигатель';

  @override
  String get compareRowPower => 'Мощность';

  @override
  String get compareRowTransmission => 'Коробка';

  @override
  String get compareRowDrivetrain => 'Привод';

  @override
  String get compareRowDisplacement => 'Объём';

  @override
  String get compareRowVin => 'VIN';

  @override
  String get compareRowPhotos => 'Фото';

  @override
  String get compareRowPublishedAt => 'Дата публикации';

  @override
  String get compareVinProvided => 'VIN указан';

  @override
  String get compareVinNotProvided => 'VIN не указан';

  @override
  String get compareValueMissing => '—';

  @override
  String get listingVinReportLoadingCta => 'Загружаем отчёт по VIN…';

  @override
  String get listingVinReportPendingCta => 'Отчёт по VIN готовится';

  @override
  String get listingVinReportNoDataCta => 'Данные по VIN не найдены';

  @override
  String get listingVinReportUnavailableCta => 'Отчёт по VIN недоступен';

  @override
  String get listingVinReportPendingTitle => 'Отчёт по VIN пока готовится';

  @override
  String get listingVinReportPendingBody =>
      'VIN добавлен продавцом. Данные расшифровки появятся после обработки.';

  @override
  String get listingVinReportNoDataTitle => 'Данные по VIN не найдены';

  @override
  String get listingVinReportNoDataBody =>
      'VIN добавлен продавцом, но сейчас нет доступной публичной расшифровки по этому VIN.';

  @override
  String get listingVinReportNoDataNote =>
      'Это не означает проверку истории автомобиля.';

  @override
  String get listingVinReportUnavailableTitle =>
      'Не удалось получить отчёт по VIN';

  @override
  String get listingVinReportUnavailableBody =>
      'VIN добавлен продавцом, но сейчас отчёт недоступен. Попробуйте позже.';

  @override
  String get listingVinTrustSheetTitle => 'Проверка по VIN';

  @override
  String get listingVinTrustSheetIntro =>
      'Продавец добавил VIN-код к объявлению. Полный VIN не показывается публично.';

  @override
  String get listingVinTrustSheetSectionVinProvidedLabel => 'VIN указан';

  @override
  String get listingVinTrustSheetSectionVinProvidedBody =>
      'VIN добавлен продавцом.';

  @override
  String get listingVinTrustSheetSectionFormatLabel => 'Формат VIN';

  @override
  String get listingVinTrustSheetSectionFormatBody =>
      'Формат VIN выглядит корректно: 17 символов без недопустимых букв.';

  @override
  String get listingVinTrustSheetSectionPrivacyLabel => 'Конфиденциальность';

  @override
  String get listingVinTrustSheetSectionPrivacyBody =>
      'Полный VIN доступен только продавцу и не отображается публично в объявлении.';

  @override
  String get listingVinTrustSheetFutureTitle => 'Что появится позже';

  @override
  String get listingVinTrustSheetFutureItemVehicleData =>
      'Данные автомобиля по VIN';

  @override
  String get listingVinTrustSheetFutureItemDamageHistory =>
      'История повреждений';

  @override
  String get listingVinTrustSheetFutureItemRegistrationInsurance =>
      'Регистрационные и страховые проверки';

  @override
  String get listingVinTrustSheetFutureItemListingCompare =>
      'Сравнение данных VIN с объявлением';

  @override
  String get listingVinTrustSheetFooterNote =>
      'Сейчас это базовая проверка формата. Расширенная проверка по официальным и партнёрским источникам будет добавлена позже.';

  @override
  String get listingVinTrustSheetGotIt => 'Понятно';

  @override
  String get listingBuyerVinReportTitle => 'Отчёт по VIN';

  @override
  String get listingBuyerVinReportLoading => 'Загрузка отчёта…';

  @override
  String get listingBuyerVinReportLoadError =>
      'Не удалось загрузить отчёт. Попробуйте позже.';

  @override
  String get listingBuyerVinReportVinAddedBySeller => 'VIN добавлен продавцом.';

  @override
  String get listingBuyerVinReportFullVinPrivate =>
      'Полный VIN не показывается публично.';

  @override
  String get listingBuyerVinReportPublicDataUnavailable =>
      'Публичные данные по VIN пока недоступны.';

  @override
  String get listingBuyerVinReportFormatOnlyExplanation =>
      'Сейчас отображается только факт, что продавец указал VIN и его формат выглядит корректно.';

  @override
  String get listingBuyerVinReportSourcesSectionTitle => 'Данные из источников';

  @override
  String get listingBuyerVinReportSourceHeading => 'Источник';

  @override
  String get listingBuyerVinReportUpdatedLabel => 'Дата обновления';

  @override
  String get listingBuyerVinReportLimitationsHeading => 'Ограничения';

  @override
  String get listingBuyerVinReportClose => 'Понятно';

  @override
  String get listingBuyerVinReportBasicDecodeCatalogLine =>
      'Сейчас показана только базовая расшифровка VIN по открытому каталогу NHTSA vPIC.';

  @override
  String get listingBuyerVinReportBasicDecodeNotOfficialLine =>
      'Это не официальная проверка регистрации, владельца, истории ДТП, страховки или пробега.';

  @override
  String get listingBuyerVinReportNhtsaCatalogSourceLine =>
      'Источник: открытый каталог NHTSA vPIC.';

  @override
  String get listingBuyerVinReportNotVerifiedSectionTitle =>
      'Что этот отчёт пока не проверяет';

  @override
  String get listingBuyerVinReportLimitationRegistrationMdPmr =>
      'Регистрацию автомобиля в Молдове или ПМР';

  @override
  String get listingBuyerVinReportLimitationOwner => 'Владельца автомобиля';

  @override
  String get listingBuyerVinReportLimitationAccidentHistory =>
      'Историю ДТП и повреждений';

  @override
  String get listingBuyerVinReportLimitationInsurance => 'Страховку';

  @override
  String get listingBuyerVinReportLimitationMileage => 'Пробег';

  @override
  String get listingBuyerVinReportLimitationLegalEncumbrances =>
      'Юридические ограничения';

  @override
  String get listingBuyerVinReportLimitationUnknownFallback =>
      'Некоторые проверки пока недоступны.';

  @override
  String get listingBuyerVinReportCompareHint =>
      'Данные по VIN можно сравнить с объявлением.';

  @override
  String get listingBuyerVinReportCompareMatch =>
      'Базовые данные по VIN совпадают с объявлением.';

  @override
  String get listingBuyerVinReportCompareMismatch =>
      'Есть расхождения между данными по VIN и объявлением. Проверьте документы и автомобиль перед покупкой.';

  @override
  String get listingBuyerVinReportDecodedEngineLabel => 'Двигатель';

  @override
  String get listingBuyerVinReportDecodedTransmissionLabel => 'Трансмиссия';

  @override
  String get listingBuyerVinReportNhtsaManufacturerLabel => 'Производитель';

  @override
  String get listingBuyerVinReportNhtsaPlantCountryLabel => 'Страна сборки';

  @override
  String get listingBuyerVinReportNhtsaPlantCityLabel => 'Город сборки';

  @override
  String get listingBuyerVinReportNhtsaPlantCompanyLabel => 'Завод';

  @override
  String get listingBuyerVinReportNhtsaVehicleTypeLabel => 'Тип ТС';

  @override
  String get listingBuyerVinReportNhtsaTrimLabel => 'Комплектация';

  @override
  String get listingBuyerVinReportNhtsaSeriesLabel => 'Серия';

  @override
  String get listingBuyerVinReportNhtsaDriveTypeLabel => 'Привод';

  @override
  String get listingBuyerVinReportNhtsaDoorsLabel => 'Дверей';

  @override
  String get listingBuyerVinReportNhtsaDisplacementLabel => 'Объём';

  @override
  String get listingBuyerVinReportNhtsaCylindersLabel => 'Цилиндров';

  @override
  String get listingBuyerVinReportNhtsaGvwrLabel => 'Класс полной массы';

  @override
  String get listingBuyerVinReportNhtsaCatalogDecodeCaution =>
      'Каталог вернул неполные данные по VIN — используйте сведения как ориентир, а не как подтверждение.';

  @override
  String get listingBuyerVinReportNhtsaGroupCoreIdentity => 'Основное';

  @override
  String get listingBuyerVinReportNhtsaGroupVehicleSpecs => 'Характеристики';

  @override
  String get listingBuyerVinReportNhtsaGroupOrigin => 'Сборка';

  @override
  String get listingBuyerVinReportManualSourcesSectionTitle =>
      'Дополнительные проверки';

  @override
  String get listingBuyerVinReportManualSourcesIntro =>
      'Carzon пока не получает эти данные автоматически. Ниже — источники, которые можно проверить отдельно.';

  @override
  String get listingBuyerVinReportManualStatusExternalCheck =>
      'Внешняя проверка';

  @override
  String get listingBuyerVinReportManualStatusSellerDocument =>
      'Документ от продавца';

  @override
  String get listingBuyerVinReportManualStatusFuture => 'Будущий источник';

  @override
  String get listingBuyerVinReportManualMdRcaTitle =>
      'История повреждений в Молдове';

  @override
  String get listingBuyerVinReportManualMdRcaBody =>
      'Данные о повреждениях можно проверить на официальном портале RCA/BNM по VIN. Carzon не получает эти данные автоматически.';

  @override
  String get listingBuyerVinReportManualMdRcaLimitation =>
      'Результат внешней проверки не отображается в этом отчёте.';

  @override
  String get listingBuyerVinReportManualMdAspTitle =>
      'Документы и регистрационные данные';

  @override
  String get listingBuyerVinReportManualMdAspBody =>
      'Продавец может предоставить документ ASP / выписку из Государственного регистра транспорта. Перед покупкой сверяйте оригинал документа.';

  @override
  String get listingBuyerVinReportManualMdAspLimitation =>
      'Carzon не проверяет подлинность документов автоматически.';

  @override
  String get listingBuyerVinReportManualPmrCustomsTitle =>
      'Таможенное оформление в ПМР';

  @override
  String get listingBuyerVinReportManualPmrCustomsBody =>
      'Сведения о таможенном оформлении можно проверять через официальный источник ГТК ПМР. Автоматическая проверка в Carzon пока не выполняется.';

  @override
  String get listingBuyerVinReportManualPmrCustomsLimitation =>
      'Данные таможни не включены в этот отчёт.';

  @override
  String get listingBuyerVinReportManualCommercialTitle =>
      'Расширенный отчёт по истории';

  @override
  String get listingBuyerVinReportManualCommercialBody =>
      'Коммерческие отчёты могут содержать дополнительные данные по истории автомобиля, если источник покрывает этот рынок. Интеграция будет оцениваться отдельно.';

  @override
  String get listingBuyerVinReportManualCommercialLimitation =>
      'Коммерческие источники пока не подключены к Carzon.';

  @override
  String get editListingVinReportSectionTitle => 'Статус VIN';

  @override
  String get editListingVinReportNoVinBody =>
      'VIN не указан. После сохранения VIN здесь появится статус обработки.';

  @override
  String get editListingVinReportPendingBody =>
      'VIN добавлен. Проверка базовой информации выполняется.';

  @override
  String get editListingVinReportDecodedBody =>
      'Базовая информация по VIN обработана.';

  @override
  String get editListingVinReportFailedBody =>
      'Не удалось обработать базовую информацию по VIN. VIN всё равно сохранён.';

  @override
  String get editListingVinReportUnavailableBody =>
      'VIN сохранён. Расширенный статус пока недоступен.';

  @override
  String get editListingVinReportLimitationNote =>
      'Это не официальная проверка регистрации, владельца, истории ДТП, страховки или пробега.';

  @override
  String get editListingVinReportPrivacyNote =>
      'Полный VIN не показывается публично.';

  @override
  String get editListingVinReportBasicInfoHeading => 'Базовая информация';

  @override
  String get editListingVinReportDecodedMakeLabel => 'Марка';

  @override
  String get editListingVinReportDecodedModelLabel => 'Модель';

  @override
  String get editListingVinReportDecodedYearLabel => 'Год';

  @override
  String get editListingVinReportDecodedBodyLabel => 'Кузов';

  @override
  String get editListingVinReportDecodedFuelLabel => 'Топливо';

  @override
  String get editListingVinReportSourceLine =>
      'Источник: базовая расшифровка NHTSA vPIC.';

  @override
  String get notificationMessageTitle => 'Новое сообщение';

  @override
  String get notificationMessageBody => 'Вам написали по объявлению в Carzon.';

  @override
  String get notificationFilterAlertTitle => 'Новое объявление';

  @override
  String get notificationFilterAlertBody =>
      'Есть объявление по вашему сохранённому фильтру. Откройте, чтобы посмотреть.';

  @override
  String get notificationAndroidChannelMessagesName => 'Carzon — сообщения';

  @override
  String get notificationAndroidChannelMessagesDescription =>
      'Уведомления о новых сообщениях в чате';

  @override
  String get notificationAndroidChannelFilterName =>
      'Carzon — оповещения по фильтру';

  @override
  String get notificationAndroidChannelFilterDescription =>
      'Уведомления о новых объявлениях по сохранённому фильтру';
}
