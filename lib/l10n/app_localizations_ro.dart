// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appName => 'Carzon';

  @override
  String get commonRetry => 'Repeta';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonCancel => 'Anula';

  @override
  String get commonDelete => 'Şterge';

  @override
  String get commonSignIn => 'Log in';

  @override
  String get commonSignOut => 'Deconectați-vă';

  @override
  String get commonRequired => 'Neapărat';

  @override
  String get commonComingSoon => 'Curând';

  @override
  String get commonKilometersShort => 'km';

  @override
  String routeNotFound(String uri) {
    return 'Pagina nu a fost găsită: $uri';
  }

  @override
  String get listingsAppBarTitle => 'Carzon';

  @override
  String get listingsTooltipSell => 'Postați un anunț';

  @override
  String get listingsTooltipMyListings => 'Reclamele mele';

  @override
  String get listingsTooltipFavorites => 'Favorite';

  @override
  String get listingsTooltipProfile => 'Profil';

  @override
  String get catalogTitle => 'Catalog auto';

  @override
  String get catalogSubtitle => 'Găsiți o mașină în Transnistria și Moldova';

  @override
  String get regionFilterLabel => 'Regiune';

  @override
  String get navListings => 'Căutare';

  @override
  String get navFavorites => 'Favorite';

  @override
  String get navSell => 'Trimiteți';

  @override
  String get navMyListings => 'Mele';

  @override
  String get navProfile => 'Profil';

  @override
  String get navMenu => 'Meniu';

  @override
  String get menuTitle => 'Meniu';

  @override
  String get menuAccount => 'Cont';

  @override
  String get menuSettings => 'Setări';

  @override
  String get listingsLoadFailed => 'Nu s-au încărcat anunțurile.';

  @override
  String get listingsLoadMoreFailed => 'Nu s-au încărcat mai multe anunțuri.';

  @override
  String get listingsLoadingMore => 'Se încarcă mai multe anunțuri…';

  @override
  String get listingsEmpty => 'Nu s-au găsit reclame adecvate.';

  @override
  String get listingsSearchHint => 'Căutați anunțuri';

  @override
  String get listingsSearchClearTooltip => 'Ștergeți căutarea';

  @override
  String get listingsDiscoveryFilterRemoveTooltip => 'Elimină filtrul';

  @override
  String get listingsFiltersTooltip => 'Filtre';

  @override
  String get catalogBrowseFilterBellTooltip => 'Alerte pentru acest filtru';

  @override
  String get catalogBrowseFilterBellFilterChipSemantics =>
      'Alertele sunt active pentru un filtru salvat care corespunde condițiilor curente de căutare';

  @override
  String get catalogBrowseFilterBellTooBroad =>
      'Rafinați filtrul (căutare, marcă, parametri sau regiune), apoi salvați alerta - catalogul de bază fără condiții este prea larg.';

  @override
  String get catalogBrowseFilterAlertTooBroadInlineTitle =>
      'Rafinați filtrul pentru a salva alerta.';

  @override
  String get catalogBrowseFilterAlertTooBroadInlineBody =>
      'Catalogul de bază fără condiții este prea larg.';

  @override
  String get catalogBrowseFilterBellEnabledSnack =>
      'Alertele pentru acest filtru sunt activate.';

  @override
  String get catalogBrowseFilterBellDisabledSnack =>
      'Alertele de filtrare sunt dezactivate.';

  @override
  String get catalogBrowseFilterBellSavedDeliveryUnavailableTooltip =>
      'Alerta a fost salvată. Faceți clic pentru a șterge.';

  @override
  String get catalogBrowseFilterBellInactiveTooltip =>
      'Activați alertele pentru acest filtru.';

  @override
  String get catalogBrowseFilterBellActiveTooltip =>
      'Alertele sunt activate. Faceți clic pentru a dezactiva.';

  @override
  String get listingsEmptyTitle => 'Nu s-au găsit reclame';

  @override
  String get listingsEmptyBody =>
      'Nu există încă reclame active în această secțiune.';

  @override
  String get listingsEmptyFilteredBody =>
      'Încercați să vă schimbați căutarea sau filtrele.';

  @override
  String get listingsEmptyBodyTypeFilterNote =>
      'Anunțurile fără tipul de corp specificat nu sunt afișate în filtrele de tip de corp. Vânzătorul poate adăuga un tip atunci când editează anunțul.';

  @override
  String get listingsEmptyResetFilters => 'Resetați filtrele';

  @override
  String get listingsBodyChipAll => 'Toate';

  @override
  String get listingBodyTypeSedan => 'Sedan';

  @override
  String get listingBodyTypeHatchback => 'Hatchback';

  @override
  String get listingBodyTypeWagon => 'break';

  @override
  String get listingBodyTypeSuv => 'SUV';

  @override
  String get listingBodyTypeCoupe => 'Coupe';

  @override
  String get listingBodyTypeConvertible => 'Cabriolet';

  @override
  String get listingBodyTypeMinivan => 'Minivan';

  @override
  String get listingBodyTypePickup => 'Ridicare';

  @override
  String get listingBodyTypeVan => 'Van';

  @override
  String get listingBodyTypeOther => 'Alte';

  @override
  String get listingBodyTypeNotSpecified => 'Nu este specificat';

  @override
  String get listingBodyTypeSectionTitle => 'Tipul corpului';

  @override
  String get listingBodyTypeSectionSubtitle =>
      'Pentru filtre după tipul corpului. Dacă nu se potrivește - „Altele”.';

  @override
  String get regionTransnistria => 'Transnistria';

  @override
  String get regionMoldova => 'Moldova';

  @override
  String get regionBoth => 'Toate';

  @override
  String get filtersTitle => 'Filtre';

  @override
  String get filtersDismissTooltip => 'Închide filtrele';

  @override
  String get filtersHeaderEyebrow => 'CARZON · CAUTARE';

  @override
  String get filtersSubtitle => 'Selectați parametrii de căutare';

  @override
  String get filterMake => 'Marca';

  @override
  String get filterMakeHint => 'ex. Volkswagen';

  @override
  String get brandFilterAllSemantics => 'Toate mărcile';

  @override
  String brandFilterBrandSemantics(String brand) {
    return 'Marca: $brand';
  }

  @override
  String get filterMinYear => 'An de la';

  @override
  String get filterMaxYear => 'Cu un an înainte';

  @override
  String get filterYearRangeInverted =>
      'Anul „de la” nu poate fi mai mare decât anul „înainte”.';

  @override
  String get filterYearManufactureSection => 'Anul emiterii';

  @override
  String get filterYearFromShort => 'Din';

  @override
  String get filterYearToShort => 'La';

  @override
  String get filterYearAny => 'Orice';

  @override
  String get filterMustBeNumber => 'Am nevoie de un număr.';

  @override
  String get filterMustBeMaxYear => 'Trebuie să fie ≤ anul maxim.';

  @override
  String get filterMustBeMinYear => 'Trebuie să fie ≥ minim an.';

  @override
  String get filterType => 'Tip';

  @override
  String get typeAny => 'Orice';

  @override
  String get typeSale => 'Vânzare';

  @override
  String get typeExchange => 'Schimb';

  @override
  String get typeBoth => 'Vânzare sau schimb';

  @override
  String get filterClear => 'Resetați';

  @override
  String get filterApply => 'Aplicați';

  @override
  String get filterShowCars => 'Arată mașina';

  @override
  String filterSummaryPriceUpTo(String amount) {
    return 'până la $amount';
  }

  @override
  String filterSummaryPriceFrom(String amount) {
    return 'de la $amount';
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
    return 'până la $amount km';
  }

  @override
  String get filterSummaryAllListingsInRegionPm =>
      'Toate reclamele din Transnistria';

  @override
  String get filterModel => 'Model';

  @override
  String get filterModelHint => 'ex. Golf';

  @override
  String get filterPriceFrom => 'Pret de la';

  @override
  String get filterPriceTo => 'Pret pana la';

  @override
  String get filterPriceBudgetHint =>
      'Specificați bugetul și moneda anunțului.';

  @override
  String get filterPriceCurrencyLabel => 'Moneda anunțului';

  @override
  String get filterPriceCurrencyAny => 'Orice';

  @override
  String get filterPriceCurrencyUsd => 'USD';

  @override
  String get filterPriceCurrencyEur => 'EUR';

  @override
  String get filterPriceChipPrefix => 'Preţ';

  @override
  String get filterPriceCurrencyActiveUsd => 'Moneda: \$';

  @override
  String get filterPriceCurrencyActiveEur => 'Moneda: €';

  @override
  String get filterMaxMileage => 'Kilometraj până la (km)';

  @override
  String get filterCity => 'Oraş';

  @override
  String get filterCityHint => 'ex. Tiraspol';

  @override
  String get filterSortLabel => 'Triere';

  @override
  String get filterSortNewestFirst => 'Cele noi mai întâi';

  @override
  String get filterSortPriceLowHigh => 'Preț: crescător';

  @override
  String get filterSortPriceHighLow => 'Pret: descendent';

  @override
  String get filterSortNewestYear => 'Anul Nou mai întâi';

  @override
  String get filterSortLowestMileage => 'Reduceți mai întâi kilometrajul';

  @override
  String get filterMustBeMaxPrice => 'Trebuie să fie ≤ prețul maxim.';

  @override
  String get filterMustBeMinPrice => 'Trebuie să fie ≥ prețul minim.';

  @override
  String get filtersSummaryDefaultTitle =>
      'Configurați selecția dvs. de mașină';

  @override
  String get filtersSummaryDefaultHints => 'Faceți · buget · corp · regiune';

  @override
  String get filtersSectionMakeModel => 'Marca și modelul';

  @override
  String get filtersSectionBudget => 'Buget';

  @override
  String get filtersSectionYearMileageCaption => 'Anul și kilometrajul';

  @override
  String get filtersSectionVehicle => 'Auto';

  @override
  String get filtersSectionLocation => 'Locaţie';

  @override
  String get filtersSectionBodyAndDeal => 'Corp și afacere';

  @override
  String get listingDetailsTitle => 'Anunţ';

  @override
  String get listingDetailsLoadFailed => 'Anunțul nu a putut fi încărcat.';

  @override
  String get userErrorNetworkCheckConnection =>
      'Verificați-vă conexiunea la internet și încercați din nou.';

  @override
  String get userErrorGenericTryAgain => 'Ceva a mers prost. Încearcă din nou.';

  @override
  String get userErrorEmailAlreadyRegistered =>
      'Există deja un cont cu aceeași e-mail.';

  @override
  String get userErrorWeakPassword =>
      'Parola este prea simplă. Încercați o parolă mai puternică.';

  @override
  String get userErrorInsufficientPermission =>
      'Drepturi insuficiente pentru această acțiune.';

  @override
  String get listingUnavailableOrDeleted =>
      'Anunțul este indisponibil sau a fost eliminat.';

  @override
  String get userErrorUploadPhotoTryAgain =>
      'Nu s-a putut încărca fotografia. Încearcă din nou.';

  @override
  String get listingDetailsSpecs => 'Caracteristici';

  @override
  String get listingFieldMake => 'Marca';

  @override
  String get listingFieldModel => 'Model';

  @override
  String get listingFieldYear => 'An';

  @override
  String get listingFieldMileage => 'Kilometraj';

  @override
  String get listingFieldType => 'Tip';

  @override
  String get listingFieldCity => 'Oraş';

  @override
  String get listingFieldRegion => 'Regiune';

  @override
  String get listingFieldBodyType => 'Corp';

  @override
  String get listingFieldPosted => 'Publicat';

  @override
  String listingDetailsMetadataAddedOn(String date) {
    return 'Adăugat pe $date';
  }

  @override
  String listingDetailsMetadataViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de vizualizări',
      few: '$count vizualizări',
      one: '$count vizualizare',
    );
    return '$_temp0';
  }

  @override
  String listingDetailsMetadataViewsToday(int count) {
    return 'Astăzi +$count';
  }

  @override
  String get listingFuelType => 'Combustibil';

  @override
  String get listingEngineDisplacement => 'Capacitatea motorului';

  @override
  String get listingEnginePower => 'Putere';

  @override
  String get listingDrivetrain => 'Conduce';

  @override
  String get listingRegistration => 'Locul înmatriculării auto';

  @override
  String get listingDescription => 'Descriere';

  @override
  String get listingEngineDisplacementHint => 'Litri, de ex. 2.0';

  @override
  String get listingEnginePowerHint => 'Putere in CP';

  @override
  String get listingRegistrationHint => 'Ex.: Tiraspol, Chișinău';

  @override
  String get listingRegistrationHelper =>
      'Conform documentelor mașinii. Nu influențează regiunea de afișare a anunțului.';

  @override
  String get listingEngineDisplacementLitersSuffix => 'l';

  @override
  String get listingEngineDisplacementCcSuffix => 'cm³';

  @override
  String get listingEnginePowerHpSuffix => 'hp';

  @override
  String get listingFuelTypePetrol => 'Benzină';

  @override
  String get listingFuelTypeDiesel => 'Diesel';

  @override
  String get listingFuelTypeHybrid => 'Hibrid';

  @override
  String get listingFuelTypeElectric => 'Electro';

  @override
  String get listingFuelTypeLpg => 'Gaz (GPL)';

  @override
  String get listingFuelTypeCng => 'Metan (CNG)';

  @override
  String get listingFuelTypeOther => 'Alte';

  @override
  String get listingDrivetrainFwd => 'Faţă';

  @override
  String get listingDrivetrainRwd => 'Spate';

  @override
  String get listingDrivetrainAwd => 'Complet (AWD)';

  @override
  String get listingDrivetrainFourWheel => '4x4';

  @override
  String get listingTransmission => 'Cutie de viteze';

  @override
  String get listingTransmissionManual => 'Manuală';

  @override
  String get listingTransmissionAutomatic => 'Automată';

  @override
  String get listingTransmissionCvt => 'CVT';

  @override
  String get listingTransmissionRobotic => 'Robotizată';

  @override
  String get listingTransmissionDualClutch => 'Dublu ambreiaj';

  @override
  String get listingTransmissionOther => 'Altă';

  @override
  String get listingDetailsDescriptionSection => 'Descriere';

  @override
  String get createListingSectionSpecsSubtitle =>
      'Dacă doriți, vă pot ajuta cu căutări și filtre.';

  @override
  String get createListingSectionDescription => 'Descriere';

  @override
  String get createListingSectionDescriptionSubtitle =>
      'Stare, echipament, service - în propriile cuvinte.';

  @override
  String get createListingDescriptionLabel => 'Text publicitar';

  @override
  String get createListingDescriptionHint =>
      'Povestește-ne despre mașină cu propriile tale cuvinte...';

  @override
  String get editListingDescriptionLabel => 'Descrierea anunțului';

  @override
  String get validationEngineDisplacementPositive =>
      'Introduceți volumul mai mare decât zero (litri).';

  @override
  String get validationEnginePowerPositive =>
      'Introduceți putere mai mare decât zero (CP).';

  @override
  String get validationRegistrationTooLong =>
      'Câmpul de înregistrare este prea lung (max. 200 de caractere).';

  @override
  String get contactSellerSection => 'Contactați vânzătorul';

  @override
  String get contactShowPhone => 'Arată telefonul';

  @override
  String get contactCopyPhone => 'Copie';

  @override
  String get contactPhoneCopied => 'Număr copiat';

  @override
  String get contactPublicNotice =>
      'Persoanele de contact ale vânzătorului sunt vizibile în reclamele active.';

  @override
  String get contactTelegram => 'Telegramă';

  @override
  String contactTelegramLabel(String username) {
    return 'Telegram @$username';
  }

  @override
  String get contactWhatsapp => 'whatsapp';

  @override
  String get contactActionFailed => 'Acțiunea nu a fost deschisă.';

  @override
  String get chatLabel => 'Chat';

  @override
  String get chatNotAvailable => 'Chatul nu este încă disponibil.';

  @override
  String get messagingTitle => 'Mesaje';

  @override
  String get messagingSignInRequired =>
      'Conectați-vă pentru a scrie vânzătorului.';

  @override
  String get messagingCannotMessageSelf =>
      'Nu vă puteți scrie pe baza anunțului dvs.';

  @override
  String get messagingUnavailableNoSeller =>
      'Chatul nu este disponibil pentru această listă.';

  @override
  String get messagingLoadFailed => 'Nu s-a putut încărca corespondența.';

  @override
  String get messagingSendFailed =>
      'Trimiterea mesajului a eșuat. Încearcă din nou.';

  @override
  String get messagingNetworkError =>
      'Verificați-vă conexiunea la internet și încercați din nou.';

  @override
  String get messagingServerError => 'Acțiunea a eșuat. Încearcă din nou.';

  @override
  String get messagingConversationNotFound =>
      'Corespondența nu a fost găsită sau nu aveți acces.';

  @override
  String get messagingInvalidMessage => 'Verificați textul mesajului.';

  @override
  String get messagingEmptyTitle => 'Nicio corespondență încă';

  @override
  String get messagingEmptyBody =>
      'Scrieți vânzătorului din ecranul de anunțuri - dialogul va apărea aici.';

  @override
  String get messagingNoPreview => 'Fără mesaje';

  @override
  String get messagingThreadEmptyBody =>
      'Începeți o corespondență: puneți o întrebare despre anunț sau aranjați o vizionare.';

  @override
  String get messagingSupportThreadEmptyTitle => 'Scrieți asistenței Carzon';

  @override
  String get messagingSupportThreadEmptyBody =>
      'Descrieți întrebarea, iar noi vă vom răspunde în acest chat.';

  @override
  String get messagingThreadTitle => 'Chat';

  @override
  String get messagingThreadViewListingHint => 'Deschide anunțul';

  @override
  String get messagingComposerHint => 'Mesaj…';

  @override
  String get messagingSend => 'Trimite';

  @override
  String get messagingAttachImage => 'Atașează fotografie';

  @override
  String get messagingAttachmentSourceTitle => 'Adaugă fotografie';

  @override
  String get messagingAttachmentGallery => 'Galerie';

  @override
  String get messagingAttachmentCamera => 'Cameră';

  @override
  String get messagingAttachmentRemove => 'Elimină';

  @override
  String get messagingAttachmentUnsupportedType =>
      'Sunt acceptate doar JPEG și PNG.';

  @override
  String get messagingAttachmentTooLarge =>
      'Imaginea trebuie să fie de maximum 10 MB.';

  @override
  String get messagingAttachmentLoadFailed => 'Nu s-a putut încărca imaginea.';

  @override
  String get messagingAttachmentPhotoPreview => 'Fotografie';

  @override
  String get messagingCameraInitializing => 'Se conectează camera…';

  @override
  String get messagingCameraPermissionDenied =>
      'Accesul la cameră este refuzat. Permiteți accesul în setările dispozitivului.';

  @override
  String get messagingCameraUnavailable =>
      'Camera nu este disponibilă pe acest dispozitiv.';

  @override
  String get messagingCameraCaptureFailed =>
      'Nu s-a putut face fotografia. Încercați din nou.';

  @override
  String get messagingDateToday => 'Astăzi';

  @override
  String get messagingDateYesterday => 'Ieri';

  @override
  String get messagingMessageCopied => 'Mesaj copiat';

  @override
  String get messagingQuickReplyHint =>
      'Răspunsuri rapide - faceți clic pentru a lipi în câmpul de introducere';

  @override
  String get messagingQuickReplyStillAvailable =>
      'Buna ziua, anunțul mai este valabil?';

  @override
  String get messagingQuickReplyWhereToView => 'Unde pot vedea masina?';

  @override
  String get messagingQuickReplyNegotiable => 'Negociabil?';

  @override
  String get messagingQuickReplyWhenCall =>
      'Când este cel mai bun moment pentru a suna?';

  @override
  String messagingListingFallback(String shortId) {
    return 'Anunț $shortId';
  }

  @override
  String get phoneNotProvided => 'Numărul de telefon nu este specificat';

  @override
  String get reportListing => 'Plângeți-vă de un anunț';

  @override
  String get reportListingDescription =>
      'Ați observat informații suspecte, incorecte sau inadecvate? Anunțați-ne.';

  @override
  String get reportListingMailFailed =>
      'Aplicația de e-mail nu a putut fi deschisă.';

  @override
  String get formatTypeSale => 'Vânzare';

  @override
  String get formatTypeExchange => 'Schimb';

  @override
  String get formatTypeBoth => 'Vânzare sau schimb';

  @override
  String get statusActive => 'Activ';

  @override
  String get statusHidden => 'Ascuns';

  @override
  String get statusSold => 'Vândut';

  @override
  String get statusArchived => 'În arhivă';

  @override
  String get publicContactNotice =>
      'Numărul dvs. de telefon și metodele de comunicare selectate vor fi vizibile în reclamele active. Indicați numai acele contacte pe care sunteți dispus să le partajați public.';

  @override
  String get createListingTitle => 'Postați un anunț';

  @override
  String get createListingComposeEyebrow => 'Anunț nou Carzon';

  @override
  String get createListingComposeHeadline => 'Creați un anunț';

  @override
  String get createListingComposeSubtitle =>
      'Pregătiți un card de mașină: fotografii, caracteristici și contacte îngrijite - astfel încât cumpărătorul să vadă imediat principalul lucru.';

  @override
  String get createListingSectionPhotosLead => 'Fotografie și antet';

  @override
  String get createListingSectionPhotosLeadSubtitle =>
      'Coperta catalogului și titlu opțional.';

  @override
  String get createListingSectionVehicle => 'Despre masina';

  @override
  String get createListingSectionVehicleSubtitle =>
      'Oraș, marcă, model, an și specificații.';

  @override
  String get createListingSectionDeal => 'Comerț și piață';

  @override
  String get createListingSectionDealSubtitle =>
      'Tipul ofertei și regiunea unde anunțul va fi vizibil.';

  @override
  String get createListingSectionPrice => 'Preț și kilometraj';

  @override
  String get createListingSectionPriceSubtitle => 'Moneda și cifrele reale.';

  @override
  String get createListingSectionPublish => 'Contacte și publicare';

  @override
  String get createListingSectionPublishSubtitle =>
      'Persoanele de contact vor fi vizibile în anunțul activ.';

  @override
  String get createListingPublishKicker => 'Pasul final';

  @override
  String get createListingSignInRequired =>
      'Conectați-vă pentru a posta un anunț.';

  @override
  String get fieldTitle => 'Titlu';

  @override
  String get fieldTitleOptional => 'Titlu (opțional)';

  @override
  String get listingTitleFallbackDefault => 'Anunț de vânzare mașină';

  @override
  String get fieldMake => 'Marca';

  @override
  String get fieldModel => 'Model';

  @override
  String get fieldYear => 'An';

  @override
  String get fieldPriceEur => 'Preț (EUR)';

  @override
  String get createListingMediaTitle => 'Anunț foto';

  @override
  String get createListingMediaSubtitle =>
      'Prima fotografie va deveni cea principală de pe card.';

  @override
  String get createListingMediaHeroEmptyHint =>
      'Faceți clic pentru a adăuga o fotografie a anunțului dvs. Până la nouă fotografii, câte una din galerie.';

  @override
  String get createListingMediaCoverHint => 'Coperta catalogului';

  @override
  String get createListingHeroEmptyTitle => 'Adăugați fotografii cu mașină';

  @override
  String get createListingHeroEmptyDetail =>
      'Până la nouă imagini din galerie. Începeți cu un unghi bun.';

  @override
  String get createListingAddPhoto => 'Adăugați o fotografie';

  @override
  String get createListingAddMorePhotos => 'Mai multe fotografii';

  @override
  String createListingMaxPhotos(int count) {
    return 'Nu sunt permise mai mult de $count fotografii.';
  }

  @override
  String get createListingRemovePhoto => 'Șterge fotografia';

  @override
  String get createListingCoverBadge => 'Acoperi';

  @override
  String get createListingPriceAmount => 'Pret - suma';

  @override
  String get createListingCurrency => 'Valută';

  @override
  String get currencyCodeEur => 'EURO';

  @override
  String get currencyCodeUsd => 'USD';

  @override
  String get createListingBrandLabel => 'Marca';

  @override
  String get createListingChooseBrand => 'Selectați marca';

  @override
  String get createListingBrandOther => 'Alte';

  @override
  String get createListingCustomBrandHint => 'Specificați marca';

  @override
  String get createListingYearLabel => 'Anul emiterii';

  @override
  String get createListingChooseYear => 'Selectați anul';

  @override
  String get createListingPhotosUploadFailed =>
      'Nu s-a putut încărca fotografia. Încearcă din nou.';

  @override
  String get commonDone => 'Gata';

  @override
  String get createListingSearchBrandsHint => 'Căutare de mărci';

  @override
  String get fieldMileageKm => 'Kilometraj (km)';

  @override
  String get fieldType => 'Tip';

  @override
  String get fieldRegion => 'Regiune de afișare';

  @override
  String get fieldRegionHelper =>
      'Unde va fi vizibil anunțul pentru cumpărători.';

  @override
  String get fieldCity => 'Oraş';

  @override
  String get fieldPhone => 'Număr de telefon';

  @override
  String get fieldPhoneHint => '+373...';

  @override
  String get fieldTelegram => 'Pseudonim în Telegram (opțional)';

  @override
  String get fieldTelegramHint => '@nume utilizator';

  @override
  String get whatsappToggle => 'WhatsApp este disponibil la acest număr';

  @override
  String get regionRequired => 'Selectați regiunea dvs.';

  @override
  String get validationRequired => 'Neapărat';

  @override
  String validationYearRange(int maxYear) {
    return '1900–$maxYear';
  }

  @override
  String get validationPositive => 'Trebuie să fie > 0';

  @override
  String get validationNonNegative => 'Trebuie să fie ≥ 0';

  @override
  String get coverPhotoOptional => 'capac (optional)';

  @override
  String get coverRemoveTooltip => 'Șterge fotografia';

  @override
  String get coverAddPhoto => 'Adăugați o fotografie';

  @override
  String get publishListing => 'Publica';

  @override
  String get listingCreated => 'Anunțul a fost creat.';

  @override
  String get listingCreateFailed => 'Anunțul nu a fost creat.';

  @override
  String get imageLoadFailed =>
      'Nu s-a putut încărca imaginea. Încearcă din nou.';

  @override
  String get coverUploadFailedRetry =>
      'Nu s-a încărcat fotografia de copertă. Încearcă din nou.';

  @override
  String get listingCreateFailedRetry =>
      'Anunțul nu a fost creat. Încearcă din nou.';

  @override
  String get imagePickerLoadFailed =>
      'Nu s-a putut selecta fotografia. Încercați o altă imagine.';

  @override
  String get listingCreateSessionExpired =>
      'Sesiunea a expirat sau accesul este refuzat. Conectați-vă din nou și încercați din nou.';

  @override
  String get listingCreateServiceUnavailable =>
      'Serviciul este temporar indisponibil. Vă rugăm să încercați din nou mai târziu.';

  @override
  String get listingCreateVinInvalidServer =>
      'Codul VIN este incorect. Bifați 17 caractere sau lăsați câmpul necompletat.';

  @override
  String get listingCreateRpcNotReady =>
      'Serverul nu este încă pregătit să accepte noi date publicitare. Încercați din nou mai târziu sau actualizați aplicația.';

  @override
  String get listingCreatePermissionDenied =>
      'Nu aveți permisiunea de a crea un anunț. Conectați-vă din nou la contul dvs.';

  @override
  String get listingCreateCheckConstraint =>
      'Unele date publicitare sunt formatate incorect. Verificați câmpurile și încercați din nou.';

  @override
  String get editListingTitle => 'Editați anunțul';

  @override
  String get editListingLoadFailed =>
      'Anunțul nu a putut fi încărcat. Încearcă din nou.';

  @override
  String get listingUpdated => 'Anunțul a fost actualizat.';

  @override
  String get listingUpdateFailedRetry =>
      'Anunțul nu a fost actualizat. Încearcă din nou.';

  @override
  String get notAllowedEdit => 'Nu aveți permisiunea de a edita acest anunț.';

  @override
  String get checkDetailsAndRetry =>
      'Vă rugăm să verificați detaliile anunțului și să încercați din nou.';

  @override
  String get coverUpdateFailedRetry =>
      'Nu s-a putut actualiza fotografia de copertă. Încearcă din nou.';

  @override
  String get coverPhotoLabel => 'Acoperi';

  @override
  String get coverChangePhoto => 'Schimbați fotografia';

  @override
  String get coverCancelChange => 'Anulați modificarea';

  @override
  String get coverCancelRemoval => 'Anulați ștergerea';

  @override
  String get coverReplacePhoto => 'Înlocuiește fotografia';

  @override
  String get coverRemovePhoto => 'Șterge fotografia';

  @override
  String get coverWillBeRemovedNotice =>
      'Fotografia de copertă va fi ștearsă după salvare.';

  @override
  String get coverWillBeReplacedNotice =>
      'Noua fotografie va fi încărcată după salvare.';

  @override
  String get coverPlaceholderWillBeRemoved => 'Capacul va fi îndepărtat';

  @override
  String get saveChanges => 'Salva';

  @override
  String get editListingGalleryReadOnlyHint =>
      'Galeria nu s-a încărcat. Fotografia de mai jos este doar pentru referință; Nu le puteți modifica acum - textul și alte câmpuri ale anunțului vor fi păstrate.';

  @override
  String get editListingGalleryReplaceFailed =>
      'Nu s-au actualizat fotografiile. Încearcă din nou.';

  @override
  String get myListingsTitle => 'Reclamele mele';

  @override
  String get myListingsSignInRequired =>
      'Conectați-vă pentru a vă vedea înregistrările.';

  @override
  String get myListingsLoadFailed => 'Nu s-au încărcat anunțurile dvs.';

  @override
  String get myListingsEmpty => 'Nu ați publicat încă niciun reclam.';

  @override
  String get myListingsEmptyTitle => 'Încă nu aveți reclame';

  @override
  String get myListingsEmptyBody =>
      'Trimiteți primul dvs. anunț - acesta va apărea aici după publicare.';

  @override
  String get myListingsSellCta => 'Postați un anunț';

  @override
  String get myListingActionsTooltip => 'Acțiuni cu anunțul';

  @override
  String get actionEdit => 'Edita';

  @override
  String get actionReactivate => 'Activa';

  @override
  String get actionMarkSold => 'Marcați ca vândut';

  @override
  String get actionHide => 'Ascunde';

  @override
  String get actionArchive => 'Spre arhiva';

  @override
  String get actionDeletePermanently => 'Ștergeți definitiv';

  @override
  String get deleteDialogTitle => 'Ștergeți anunțul?';

  @override
  String get deleteDialogBody =>
      'Anunțul va fi eliminat definitiv din Carzon. Nu va mai fi afișat utilizatorilor și va dispărea de la toți cei care l-au adăugat la favorite.';

  @override
  String get notAllowedUpdateStatus =>
      'Nu aveți permisiunea de a actualiza această înregistrare.';

  @override
  String get statusNotSupported => 'Această stare de anunț nu este acceptată.';

  @override
  String get updateStatusFailedRetry =>
      'Nu s-a putut actualiza starea anunțului. Încearcă din nou.';

  @override
  String get notAllowedDelete => 'Nu aveți dreptul de a elimina acest anunț.';

  @override
  String get listingNotFound => 'Acest anunț nu mai există.';

  @override
  String get deleteListingFailedRetry =>
      'Anunțul nu a putut fi șters. Încearcă din nou.';

  @override
  String get favoritesTitle => 'Favorite';

  @override
  String get favoritesSignInRequired =>
      'Conectați-vă pentru a vedea înregistrările recomandate.';

  @override
  String get favoritesLoadFailed => 'Favoritele nu au putut fi încărcate.';

  @override
  String get favoritesEmpty => 'Nimic nu a fost adăugat încă la favorite.';

  @override
  String get favoritesEmptyTitle => 'Favoritele sunt încă goale';

  @override
  String get favoritesEmptyBody =>
      'Adăugați înregistrări la favorite, astfel încât să puteți reveni rapid la ele mai târziu.';

  @override
  String get favoritesEmptyBrowse => 'Vizualizați reclame';

  @override
  String get favoriteAdd => 'Adăugați la favorite';

  @override
  String get favoriteRemove => 'Eliminați din favorite';

  @override
  String get favoriteSignInRequired =>
      'Conectați-vă pentru a adăuga la favorite.';

  @override
  String get favoriteToggleFailed =>
      'Nu s-au actualizat favoritele. Încearcă din nou.';

  @override
  String get profileTitle => 'Cont';

  @override
  String get profileSignInRequired =>
      'Conectați-vă pentru a vă gestiona contul.';

  @override
  String get profileSignedInFallback => 'Sunteți autentificat';

  @override
  String get profileSignOutFailedRetry => 'Ieșirea eșuată. Încearcă din nou.';

  @override
  String get profileMyListings => 'Reclamele mele';

  @override
  String get profileFavorites => 'Favorite';

  @override
  String get profileCreateListing => 'Postați un anunț';

  @override
  String get profileLegal => 'Termeni și confidențialitate';

  @override
  String get profileSignOut => 'Deconectați-vă';

  @override
  String get accountAvatarOpenProfileTooltip => 'Cont și setări';

  @override
  String get profileActivitySectionTitle => 'Activitate';

  @override
  String get profileMessagesUnreadStatus => 'Sunt mesaje necitite';

  @override
  String get profileMessagesNoUnreadStatus => 'Fără mesaje noi';

  @override
  String get profileMessagesUnreadCountOverflow => '99+';

  @override
  String get profilePublicSellerProfileSectionTitle =>
      'Profilul public al vânzătorului';

  @override
  String get profilePublicSellerProfileSectionSubtitle =>
      'Cumpărătorii văd acest lucru în listările dvs. și pe pagina vânzătorului.';

  @override
  String get profilePublicSellerBuyerPreviewCaption =>
      'Așa vă văd cumpărătorii';

  @override
  String get profileSettingsSectionTitle => 'Setări';

  @override
  String get profileOpenSettingsTitle => 'Setările aplicației';

  @override
  String get profileOpenSettingsSubtitle => 'Limbă, temă, notificări și altele';

  @override
  String get settingsTitle => 'Setări';

  @override
  String get settingsIntro =>
      'Gestionați contul, interfața și notificările într-un singur loc.';

  @override
  String get settingsSectionAccount => 'Cont';

  @override
  String get settingsSectionPreferences => 'Preferințe';

  @override
  String get settingsSectionNotifications => 'Notificări';

  @override
  String get settingsSectionPrivacySafety => 'Confidențialitate și siguranță';

  @override
  String get settingsSectionSupportLegal => 'Asistență și informații legale';

  @override
  String get settingsAccountProfileTitle => 'Profilul contului';

  @override
  String get settingsAccountProfileSubtitle =>
      'Nume, email și profilul public al vânzătorului';

  @override
  String get settingsSignInForAccountSubtitle =>
      'Conectați-vă pentru a gestiona parola și notificările';

  @override
  String get settingsPrivacyLegalLinkTitle => 'Termeni și siguranță';

  @override
  String get settingsPrivacyLegalLinkSubtitle =>
      'Informații legale și recomandări pentru tranzacții sigure';

  @override
  String get settingsLegalLinkSubtitle =>
      'Termeni de utilizare și politica de confidențialitate';

  @override
  String get settingsRequestDataTitle => 'Solicită datele mele';

  @override
  String get settingsRequestDataSubtitle =>
      'Contactează suportul pentru întrebări despre datele personale';

  @override
  String get settingsDeleteAccountTitle => 'Șterge contul';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Elimină definitiv contul și datele asociate';

  @override
  String get deleteAccountTitle => 'Ștergere cont';

  @override
  String get deleteAccountWarningTitle => 'Această acțiune este ireversibilă';

  @override
  String get deleteAccountWarningBody =>
      'Contul și accesul la aplicație vor fi eliminate.\n\n• Anunțurile active vor dispărea de pe vitrina publică\n• Favoritele, alertele de filtre, profilul vânzătorului și setările push vor fi șterse\n• Conversațiile și istoricul mesajelor pot fi șterse\n\nDupă confirmare, contul nu poate fi recuperat.';

  @override
  String get deleteAccountConfirmationKeyword => 'ȘTERGE';

  @override
  String deleteAccountConfirmationPrompt(String keyword) {
    return 'Pentru confirmare, tastați «$keyword»';
  }

  @override
  String get deleteAccountSubmit => 'Șterge contul definitiv';

  @override
  String get deleteAccountErrorGeneric =>
      'Nu s-a putut șterge contul. Încercați din nou sau contactați suportul.';

  @override
  String get deleteAccountErrorNetwork =>
      'Fără conexiune. Verificați internetul și încercați din nou.';

  @override
  String get deleteAccountErrorSession =>
      'Sesiunea a expirat. Autentificați-vă din nou și repetați ștergerea.';

  @override
  String get profileChangePasswordTitle => 'Schimbă parola';

  @override
  String get profileChangePasswordSubtitle =>
      'Actualizează parola pentru autentificarea în cont.';

  @override
  String get profileDarkThemeTitle => 'Tema întunecată';

  @override
  String get profileDarkThemeSubtitle =>
      'Comută interfața aplicației în modul întunecat.';

  @override
  String get profileLanguageTitle => 'Limba aplicației';

  @override
  String get profileLanguageCurrentRussian => 'rusă';

  @override
  String get profileLanguageCurrentRomanian => 'Română';

  @override
  String get profileLanguageOptionRussian => 'Русский';

  @override
  String get profileLanguageOptionRomanian => 'Română';

  @override
  String get profileNotificationsTitle => 'Notificări';

  @override
  String get profileNotificationsSubtitle =>
      'Push, mesaje și starea livrării (testare).';

  @override
  String get contactSupport => 'Contactați asistența';

  @override
  String get contactSupportSubtitle =>
      'Scrieți-ne despre întrebări legate de aplicație';

  @override
  String get supportConversationTitle => 'Asistență Carzon';

  @override
  String get contactSupportOpenFailure =>
      'Nu s-a putut deschide chatul cu asistența. Încercați mai târziu.';

  @override
  String get contactSupportSelfFailure =>
      'Contul de asistență nu poate deschide acest chat.';

  @override
  String get notificationSettingsTitle => 'Notificări';

  @override
  String get notificationSettingsPageIntro =>
      'Configurați push pe acest dispozitiv: mesaje în chat și alerte pentru filtrul salvat.';

  @override
  String get notificationSettingsSignInRequired =>
      'Conectați-vă pentru a configura notificările.';

  @override
  String get notificationSettingsLoadFailed =>
      'Nu s-au încărcat setările de notificare.';

  @override
  String get notificationSettingsSaveFailed =>
      'Salvare eșuată. Încearcă din nou.';

  @override
  String get notificationSettingsOsPermissionDenied =>
      'Permisiunea de notificare nu a fost acordată. Activați-o în setările sistemului dacă aveți nevoie de push.';

  @override
  String get notificationSettingsPushUnavailableInBuild =>
      'Notificările push nu sunt disponibile în această versiune.';

  @override
  String get notificationSettingsPushBuildDisabledBanner =>
      'Notificările push nu sunt disponibile în această versiune.';

  @override
  String get notificationSettingsPushBuildDisabledHint =>
      'Pentru a testa push, folosiți o versiune cu notificările activate.';

  @override
  String get notificationSettingsMasterOffHint =>
      'Activați „Push pe acest dispozitiv” pentru a configura tipurile de notificări de mai jos.';

  @override
  String get notificationSettingsStatusCardTitle =>
      'Permisiunea dispozitivului';

  @override
  String get notificationSettingsOsPillAllowed => 'Permise';

  @override
  String get notificationSettingsOsPillProvisional => 'Provizorii';

  @override
  String get notificationSettingsOsPillDenied => 'Respinse';

  @override
  String get notificationSettingsOsPillNotDetermined => 'Nesolicitate';

  @override
  String get notificationSettingsOsPillUnavailable => 'Indisponibile';

  @override
  String get notificationSettingsOsDescriptionAuthorized =>
      'Sistemul permite afișarea notificărilor. Puteți activa push mai jos.';

  @override
  String get notificationSettingsOsDescriptionProvisional =>
      'Notificările sunt permise în mod limitat. Confirmați accesul complet în setările sistemului, dacă e nevoie.';

  @override
  String get notificationSettingsOsDescriptionDenied =>
      'Notificările sunt dezactivate în sistem. Activați-le în setările telefonului, apoi reveniți aici.';

  @override
  String get notificationSettingsOsDescriptionNotDetermined =>
      'Permisiunea nu a fost încă solicitată. Va fi cerută când activați push mai jos.';

  @override
  String get notificationSettingsOsDescriptionUnavailable =>
      'În această versiune push nu este disponibil; statusul permisiunii nu se aplică.';

  @override
  String get notificationSettingsGlobalTitle => 'Push pe acest dispozitiv';

  @override
  String get notificationSettingsGlobalSubtitle =>
      'Activează livrarea push pe acest dispozitiv. La dezactivare, mesajele și alertele de filtru se opresc.';

  @override
  String get notificationSettingsMessagesTitle => 'Mesaje';

  @override
  String get notificationSettingsMessagesSubtitle =>
      'Push pentru mesaje noi în chat-urile anunțurilor.';

  @override
  String get notificationSettingsMessagesNeedsGlobal =>
      'Mai întâi activați „Push pe acest dispozitiv”.';

  @override
  String get notificationSettingsFilterAlertsTitle => 'Alerte după filtru';

  @override
  String get notificationSettingsFilterAlertsSubtitle =>
      'Push când apar anunțuri noi care se potrivesc filtrului salvat.';

  @override
  String get notificationSettingsFilterAlertsNeedsGlobal =>
      'Mai întâi activați „Push pe acest dispozitiv”.';

  @override
  String get notificationSettingsFilterAlertsSavedFilterNote =>
      'Este nevoie de un filtru salvat și alerte activate pe ecranul de gestionare a filtrului.';

  @override
  String get notificationSettingsFilterAlertsOpenCta =>
      'Deschide alertele după filtru';

  @override
  String get notificationSettingsDeliveryCardTitle => 'Starea livrării';

  @override
  String get notificationSettingsDeliveryDisclaimer =>
      'Funcția este implementată pe server și în aplicație; livrarea finală pe dispozitive este încă în curs de verificare.';

  @override
  String get notificationSettingsOsStatusAuthorized =>
      'Sistem: notificările sunt permise.';

  @override
  String get notificationSettingsOsStatusProvisional =>
      'Sistem: notificări temporare (provizorii).';

  @override
  String get notificationSettingsOsStatusDenied =>
      'Sistem: notificări respinse.';

  @override
  String get notificationSettingsOsStatusNotDetermined =>
      'Sistem: permisiunea nu a fost încă solicitată sau este necunoscută.';

  @override
  String get profileListingAlertsTitle => 'Filtrați alertele';

  @override
  String get profileListingAlertsSubtitle =>
      'Un filtru pentru notificări viitoare despre mașini noi.';

  @override
  String get filterAlertEditorEyebrow => 'CARZON · ALERTE';

  @override
  String get filterAlertEditorTitle => 'Filtru de alertă';

  @override
  String get filterAlertEditorSubtitle => 'Selectați opțiunile automate';

  @override
  String get filterAlertSaveFilterAction => 'Salvați filtrul';

  @override
  String get filterAlertProfileRowSubtitle =>
      'Vizualizați filtrul salvat și gestionați livrarea alertelor.';

  @override
  String get filterAlertSavedSuccess => 'Filtrul salvat';

  @override
  String get filterAlertUpdatedSuccess => 'Filtrul actualizat';

  @override
  String get filterAlertSaveFailed => 'Nu s-a salvat filtrul';

  @override
  String get filterAlertLoadFailed => 'Nu s-au încărcat setările.';

  @override
  String get filterAlertSignInRequired =>
      'Conectați-vă pentru a configura un filtru de alerte.';

  @override
  String get filterAlertApplyBlockedValidation =>
      'Corectați erorile din filtru, apoi salvați din nou.';

  @override
  String get filterAlertResetPersistedSuccess =>
      'Resetarea filtrului de alertă';

  @override
  String get filterAlertResetFailed => 'Nu s-a resetat filtrul de alertă.';

  @override
  String get filterAlertNotificationsToggleTitle =>
      'Notificări despre noi înregistrări';

  @override
  String get filterAlertNotificationsToggleSubtitle =>
      'Bazat pe un filtru salvat. Livrarea pe dispozitiv este încă în curs de verificare.';

  @override
  String get filterAlertNotificationsNeedsSavedFilter =>
      'Mai întâi, salvați filtrul folosind butonul de mai jos.';

  @override
  String get filterAlertNotificationsPushDisabled =>
      'Push nu este disponibil în această versiune (PUSH_NOTIFICATIONS_ENABLED).';

  @override
  String get filterAlertManagementHeaderEyebrow => 'CARZON · ALERTE';

  @override
  String get filterAlertManagementSubtitle =>
      'Gestionați filtrul salvat și livrarea alertelor. Notificările sunt configurate în filtre de catalog.';

  @override
  String get filterAlertManagementDeliveryOnLabel =>
      'Livrarea alertelor a fost activată';

  @override
  String get filterAlertManagementDeliveryOffLabel =>
      'Livrarea alertelor este dezactivată';

  @override
  String get filterAlertManagementCriteriaSectionTitle => 'Opțiuni de filtrare';

  @override
  String get filterAlertManagementEditAction => 'Schimbarea catalogului';

  @override
  String get filterAlertManagementDisableAction => 'Dezactivați notificările';

  @override
  String get filterAlertManagementClearAction => 'Ștergeți filtrul salvat';

  @override
  String get filterAlertManagementClearConfirmTitle =>
      'Ștergeți un filtru salvat?';

  @override
  String get filterAlertManagementClearConfirmBody =>
      'Setările filtrului vor fi șterse. Livrarea push va fi, de asemenea, dezactivată. Acțiunea poate fi repetată din director.';

  @override
  String get filterAlertManagementClearConfirmCta => 'Şterge';

  @override
  String get filterAlertManagementEmptyTitle =>
      'Nu există încă o alertă salvată';

  @override
  String get filterAlertManagementEmptyBody =>
      'Creați alerte în filtrele de catalog: setați parametrii de căutare și faceți clic pe clopoțel.';

  @override
  String get filterAlertManagementGoToCatalog => 'Mergi la catalog';

  @override
  String get filterAlertManagementDeliveryDisabledSnack =>
      'Alertele de filtrare sunt dezactivate.';

  @override
  String get filterAlertManagementClearedSnack =>
      'Filtrul salvat a fost șters.';

  @override
  String get filterAlertSummarySearchLabel => 'Căutare';

  @override
  String get filterAlertSummaryMileageLabel => 'Kilometraj';

  @override
  String get profilePublicSellerNameTitle => 'Numele public al vânzătorului';

  @override
  String get profilePublicSellerNameDescription =>
      'Cumpărătorii vor vedea acest nume în înregistrările dvs. și în profilul vânzătorului.';

  @override
  String get profilePublicSellerNameFieldLabel => 'Nume pentru cumpărători';

  @override
  String get profilePublicSellerNameFieldHint =>
      'De exemplu: Anna sau „Auto-Plus Tiraspol”';

  @override
  String get profilePublicSellerNameSave => 'Salva';

  @override
  String get profilePublicSellerNameSaved => 'Nume salvat';

  @override
  String get profilePublicSellerNameSaveFailed =>
      'Nu s-a salvat numele. Încearcă din nou.';

  @override
  String get profilePublicSellerNameTooLong =>
      'Numele este prea lung (maximum 80 de caractere).';

  @override
  String get profilePublicSellerNameLooksLikeEmail =>
      'Vă rugăm să introduceți numele, nu adresa de e-mail.';

  @override
  String get profilePublicSellerNameLoadFailed =>
      'Nu s-au încărcat setările pentru numele comerciantului.';

  @override
  String get profilePublicSellerAvatarTitle => 'Poza vânzătorului';

  @override
  String get profilePublicSellerAvatarDescription =>
      'Cumpărătorii vor vedea această fotografie lângă numele dvs. în listări și în profilul vânzătorului.';

  @override
  String get profilePublicSellerAvatarChangePhoto => 'Selectați fotografia';

  @override
  String get profilePublicSellerAvatarRemovePhoto => 'Șterge fotografia';

  @override
  String get profilePublicSellerAvatarUpdated => 'Fotografie actualizată';

  @override
  String get profilePublicSellerAvatarRemoved => 'Fotografia a fost eliminată';

  @override
  String get profilePublicSellerAvatarUploadFailed =>
      'Nu s-a putut încărca fotografia. Încearcă din nou.';

  @override
  String get profilePublicSellerAvatarRemoveFailed =>
      'Nu s-a șters fotografia. Încearcă din nou.';

  @override
  String get profilePublicSellerAvatarUnsupportedType =>
      'Sunt acceptate numai JPEG, PNG sau WebP.';

  @override
  String get signInTitle => 'Intrare';

  @override
  String get signInEyebrow => 'CARZON · CONECTARE';

  @override
  String get signInSubtitle =>
      'Conectați-vă pentru a gestiona anunțurile și mesajele';

  @override
  String get signInSubmit => 'Log in';

  @override
  String get signInError => 'Eroare de conectare';

  @override
  String get signInInvalidCredentials => 'E-mail sau parolă nevalidă.';

  @override
  String get signInFailedRetry => 'Nu s-a putut conecta. Încearcă din nou.';

  @override
  String get signUpFailedRetry => 'Nu s-a putut crea contul. Încearcă din nou.';

  @override
  String get signOutFailedRetry => 'Ieșirea eșuată. Încearcă din nou.';

  @override
  String get authFieldEmail => 'E-mail';

  @override
  String get authFieldPassword => 'Parolă';

  @override
  String get authFieldConfirmPassword => 'Confirmați-vă parola';

  @override
  String get validationEmailRequired => 'Introdu e-mail';

  @override
  String get validationEmailInvalid => 'Introduceți un e-mail corect';

  @override
  String get validationPasswordRequired => 'Introduceți parola';

  @override
  String get validationPasswordMin => 'Minim 6 caractere';

  @override
  String get validationConfirmPassword => 'Confirmați-vă parola';

  @override
  String get validationPasswordsDoNotMatch => 'Parolele nu se potrivesc';

  @override
  String get signInForgotPassword => 'Ați uitat parola?';

  @override
  String get signInCreateAccount => 'Creați un cont';

  @override
  String get legalLink => 'Termeni și confidențialitate';

  @override
  String get signUpTitle => 'Creați un cont';

  @override
  String get signUpSubmit => 'Creați un cont';

  @override
  String get signUpError => 'Eroare de înregistrare';

  @override
  String get signUpHaveAccount => 'Aveți deja un cont? Log in';

  @override
  String get signUpConfirmEmail =>
      'Verificați e-mailul pentru a vă confirma contul.';

  @override
  String get forgotPasswordTitle => 'Recuperarea parolei';

  @override
  String get forgotPasswordIntro =>
      'Introduceți e-mailul contului și vă vom trimite instrucțiuni despre cum să vă resetați parola.';

  @override
  String get forgotPasswordSubmit => 'Trimite o scrisoare';

  @override
  String get forgotPasswordSuccess =>
      'Dacă există un cont cu un astfel de e-mail, am trimis instrucțiuni despre cum să vă resetați parola.';

  @override
  String get forgotPasswordFailedRetry =>
      'Trimiterea e-mailului a eșuat. Încearcă din nou.';

  @override
  String get forgotPasswordEmailEmpty => 'Introduceți adresa dvs. de e-mail.';

  @override
  String get backToSignIn => 'Întoarcere la intrare';

  @override
  String get resetPasswordTitle => 'Parolă Nouă';

  @override
  String get resetPasswordNoSession =>
      'Deschideți linkul de resetare din e-mail pentru a continua.';

  @override
  String get resetPasswordIntro => 'Alegeți o nouă parolă pentru contul dvs.';

  @override
  String get resetPasswordNew => 'Parolă Nouă';

  @override
  String get resetPasswordConfirmNew => 'Confirmați noua parolă';

  @override
  String get resetPasswordSuccess =>
      'Parola a fost actualizată. Acum vă puteți autentifica.';

  @override
  String get resetPasswordFailedRetry =>
      'Nu s-a putut actualiza parola. Încearcă din nou.';

  @override
  String get resetPasswordSubmit => 'Actualizați parola';

  @override
  String get resetPasswordValidationNew => 'Introduceți o nouă parolă.';

  @override
  String resetPasswordValidationMin(int min) {
    return 'Parola trebuie să conțină cel puțin $min caractere.';
  }

  @override
  String get resetPasswordValidationMismatch => 'Parolele nu se potrivesc.';

  @override
  String get changePasswordTitle => 'Schimbă parola';

  @override
  String get changePasswordIntro => 'Introdu parola actuală și alege una nouă.';

  @override
  String get changePasswordCurrentPassword => 'Parola actuală';

  @override
  String get changePasswordNewPassword => 'Parola nouă';

  @override
  String get changePasswordConfirmPassword => 'Confirmă parola nouă';

  @override
  String get changePasswordSubmit => 'Salvează parola';

  @override
  String get changePasswordSuccess => 'Parola a fost actualizată.';

  @override
  String get changePasswordCurrentInvalid => 'Parola actuală este incorectă.';

  @override
  String get changePasswordFailedRetry =>
      'Nu s-a putut schimba parola. Încearcă din nou.';

  @override
  String get changePasswordSecurityNote =>
      'Folosește o parolă sigură, pe care nu o utilizezi în alte servicii.';

  @override
  String get phoneRequired => 'Introduceți numărul dvs. de telefon.';

  @override
  String get phoneInvalidChars => 'Sunt permise doar numere, spații, + ( ) -.';

  @override
  String get phoneInvalid =>
      'Vă rugăm să introduceți un număr de telefon valid.';

  @override
  String get telegramInvalid =>
      '5–32 de caractere: litere, cifre sau caractere de subliniere.';

  @override
  String get reportSubjectPrefix => 'Plângere despre anunțul Carzon';

  @override
  String get reportBodyIntro =>
      'Aș dori să mă plâng de următorul anunț Carzon:';

  @override
  String get reportBodyFieldTitle => 'Titlu';

  @override
  String get reportBodyFieldListingId => 'ID anunț';

  @override
  String get reportBodyFieldMmy => 'Marca/Modelul/Anul';

  @override
  String get reportBodyFieldCity => 'Oraş';

  @override
  String get reportBodyFieldRegion => 'Regiune';

  @override
  String get reportBodyPrompt =>
      'Descrieți ce este suspect, incorect sau nepotrivit în legătură cu acest anunț:';

  @override
  String get legalTitle => 'Termeni și confidențialitate';

  @override
  String get legalDisclaimer =>
      'Aceasta este o previzualizare a termenilor și a notificării de confidențialitate. Documentul descrie modul în care Carzon operează în prezent și nu înlocuiește condițiile verificate legal. Utilizați-l ca material informativ într-un stadiu incipient al produsului.';

  @override
  String get legalSectionAboutHeading => 'Despre Carzon';

  @override
  String get legalSectionAboutP1 =>
      'Carzon este o platformă de reclame despre vânzarea și schimbul de mașini în Moldova și Transnistria. Serviciul îi ajută pe proprietari să posteze anunțuri, iar cumpărătorii să găsească mașini și să contacteze vânzătorii.';

  @override
  String get legalSectionAboutP2 =>
      'Carzon nu vinde mașini în sine. Fiecare anunț este creat și deținut de un anumit utilizator.';

  @override
  String get legalSectionListingsHeading => 'Anunturi pe site';

  @override
  String get legalSectionListingsP1 =>
      'După publicare, anunțul devine activ și poate fi afișat altor utilizatori Carzon în feedul general și pe pagina de anunțuri.';

  @override
  String get legalSectionListingsP2 =>
      'Sunteți responsabil pentru acuratețea informațiilor pe care le publicați: marcă, model, an, preț, kilometraj, regiune, fotografii și informații de contact.';

  @override
  String get legalSectionListingsP3 =>
      'Puteți să vă ascundeți anunțurile, să le marcați ca vândute, să le reactivați sau să le arhivați în secțiunea „Anunțurile mele”.';

  @override
  String get legalSectionContactHeading =>
      'Contactele publice ale vânzătorului';

  @override
  String get legalSectionContactP1 =>
      'În timp ce anunțul dvs. este activ, persoanele de contact specificate pentru acesta pot fi vizibile pentru orice utilizator Carzon, inclusiv pentru cei care nu se conectează la contul dvs.';

  @override
  String get legalSectionContactP2 =>
      'Acesta poate fi un număr de telefon, porecla Telegram (dacă este specificat) și o notă că WhatsApp este disponibil după număr.';

  @override
  String get legalSectionContactP3 =>
      'Indicați numai acele contacte pe care sunteți dispus să le împărtășiți public pentru vânzarea sau schimbul unei mașini. Le puteți modifica sau șterge modificând anunțul sau ascunzindu-l, arhivându-l sau marcându-l ca vândut.';

  @override
  String get legalSectionPhotosHeading => 'Fotografii și imagini în reclame';

  @override
  String get legalSectionPhotosP1 =>
      'Fotografiile atașate unui anunț sunt stocate într-un magazin public de imagini și pot fi văzute de toată lumea în timp ce anunțul este activ.';

  @override
  String get legalSectionPhotosP2 =>
      'Încarcă doar fotografiile pe care ai permisiunea de a le partaja. Nu postați documente personale, plăcuțe de înmatriculare pe care nu doriți să le afișați sau imagini cu persoane cu care nu sunteți de acord.';

  @override
  String get legalSectionAccountHeading => 'Cont și autentificare';

  @override
  String get legalSectionAccountP1 =>
      'Pentru a publica reclame, a adăuga la favorite și a lucra cu secțiunea „Reclamele mele”, aveți nevoie de un cont. Conturile sunt gestionate prin e-mail și parolă.';

  @override
  String get legalSectionAccountP2 =>
      'Sunteți responsabil pentru menținerea securității parolei și pentru orice activitate desfășurată în contul dvs. Dacă bănuiți că cineva a obținut acces la contul dvs., deconectați-vă și schimbați-vă parola.';

  @override
  String get legalSectionFavoritesHeading => 'Favorite';

  @override
  String get legalSectionFavoritesP1 =>
      'Favoritele tale sunt vizibile doar pentru tine. Alți utilizatori nu știu ce înregistrări ați preferat.';

  @override
  String get legalSectionSafetyHeading => 'Siguranță și responsabilitate';

  @override
  String get legalSectionSafetyP1 =>
      'În acest moment, Carzon nu procesează plăți în aplicație, nu oferă escrow, nu inspectează vehicule, nu garantează tranzacții sau nu verifică proprietatea. Toate tranzacțiile au loc direct între cumpărător și vânzător în afara platformei.';

  @override
  String get legalSectionSafetyP2 =>
      'Înainte de a cumpăra, vinde sau schimba, verificați documentele, starea mașinii și identitatea celeilalte părți. Întâlniți-vă într-un loc sigur și nu transferați bani în avans doar pe baza reclamei.';

  @override
  String get legalSectionSafetyP3 =>
      'Carzon nu este parte la acordurile dintre cumpărător și vânzător și nu este responsabil pentru rezultatul tranzacțiilor efectuate prin intermediul platformei.';

  @override
  String get legalSectionContactUsHeading => 'Feedback';

  @override
  String get legalSectionContactUsP1 =>
      'Acești termeni și notificarea de confidențialitate pot fi actualizate pe măsură ce Carzon se dezvoltă. Continuând să utilizați aplicația după actualizare, acceptați noua versiune a documentului.';

  @override
  String get legalSectionContactUsP2 =>
      'Întrebările despre acest document și conținutul platformei pot fi direcționate către echipa Carzon prin canalul de asistență afișat pe pagina aplicației din magazin.';

  @override
  String get sellerSectionTitle => 'Vânzător';

  @override
  String get sellerViewProfile => 'Vezi profilul';

  @override
  String get sellerProfileTitle => 'Profilul vânzătorului';

  @override
  String get sellerFallbackName => 'Vânzător';

  @override
  String get sellerUnavailableTitle =>
      'Profilul vânzătorului nu este disponibil';

  @override
  String get sellerUnavailableMessage =>
      'Acest profil este ascuns sau inaccesibil.';

  @override
  String get sellerListingsSectionTitle => 'Reclamele vânzătorului';

  @override
  String get sellerNoActiveListingsTitle => 'Nu există reclame active';

  @override
  String get sellerNoActiveListingsMessage =>
      'Vânzătorul nu are în prezent nicio listă activă în catalog.';

  @override
  String get sellerMonthGenitiveJanuary => 'ianuarie';

  @override
  String get sellerMonthGenitiveFebruary => 'februarie';

  @override
  String get sellerMonthGenitiveMarch => 'Martha';

  @override
  String get sellerMonthGenitiveApril => 'aprilie';

  @override
  String get sellerMonthGenitiveMay => 'mai';

  @override
  String get sellerMonthGenitiveJune => 'iunie';

  @override
  String get sellerMonthGenitiveJuly => 'iulie';

  @override
  String get sellerMonthGenitiveAugust => 'august';

  @override
  String get sellerMonthGenitiveSeptember => 'septembrie';

  @override
  String get sellerMonthGenitiveOctober => 'octombrie';

  @override
  String get sellerMonthGenitiveNovember => 'noiembrie';

  @override
  String get sellerMonthGenitiveDecember => 'decembrie';

  @override
  String sellerMemberSince(String monthYear) {
    return 'Pe Carzon din $monthYear';
  }

  @override
  String sellerActiveListingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anunțuri active',
      few: '$count anunțuri active',
      one: '$count anunț activ',
    );
    return '$_temp0';
  }

  @override
  String get sellerTypePrivate => 'Vânzător privat';

  @override
  String get sellerTypeDealer => 'Dealer';

  @override
  String get sellerProfileLoadFailed =>
      'Nu s-a încărcat profilul vânzătorului.';

  @override
  String get sellerListingsLoadFailed => 'Nu s-au încărcat anunțurile.';

  @override
  String get sellerLoadMore => 'Arată mai multe';

  @override
  String get listingVinFieldLabel => 'Cod VIN';

  @override
  String get listingVinFieldHelper =>
      'Opțional. VIN ajută la adăugarea informațiilor de bază despre vehicul într-un anunț și crește încrederea cumpărătorului. Numărul VIN complet nu este afișat public.';

  @override
  String get validationVinInvalid =>
      'Introduceți VIN-ul corect de 17 caractere sau lăsați câmpul necompletat.';

  @override
  String get listingVinBadgeIndicated => 'VIN listat';

  @override
  String get listingVinReportOpenHint => 'Raport deschis de către VIN';

  @override
  String get listingVinNotProvidedTitle => 'VIN nu este specificat';

  @override
  String get listingVinNotProvidedHint => 'Vânzătorul nu a adăugat VIN';

  @override
  String get menuCompare => 'Comparaţie';

  @override
  String get compareTitle => 'Comparaţie';

  @override
  String get compareVehiclesTitle => 'Comparație de mașini';

  @override
  String get compareEmptyBody =>
      'Adăugați 2-3 vehicule pentru a compara prețul, kilometrajul, caracteristicile și starea VIN.';

  @override
  String get compareGoToListings => 'Mergi la reclame';

  @override
  String get compareAddOneMoreTitle => 'Adăugați o altă mașină';

  @override
  String get compareAddOneMoreBody =>
      'Ai nevoie de cel puțin două mașini pentru comparație. Adăugați un alt anunț din catalog.';

  @override
  String get compareClear => 'Comparație clară';

  @override
  String get compareMaxReachedMessage => 'Puteți compara până la 3 mașini';

  @override
  String get compareTrayMaxLimitTitle => 'Maxim 3 masini';

  @override
  String get compareTrayMaxLimitHint =>
      'Scoateți o mașină pentru a adăuga alta';

  @override
  String get compareAddedMessage => 'Adăugat la comparație';

  @override
  String get compareRemovedMessage => 'Eliminat din comparație';

  @override
  String get compareAddTooltip => 'Adăugați la comparație';

  @override
  String get compareRemoveTooltip => 'Eliminați din comparație';

  @override
  String get compareTrayOneVehicle => '1 masina in comparatie';

  @override
  String compareTrayVehicleCount(int count) {
    return '$count mașini în comparație';
  }

  @override
  String get compareTrayAddOneMore => 'Adăugați încă unul';

  @override
  String get compareTrayOpen => 'Comparaţie';

  @override
  String compareVehicleCountShort(int count) {
    return '$count auto';
  }

  @override
  String get compareShowOnlyDifferences => 'Arată doar diferențele';

  @override
  String get compareNoDifferences =>
      'Nu există diferențe în câmpurile selectate';

  @override
  String get compareRemoveVehicle => 'Eliminați din comparație';

  @override
  String get compareUnavailableListing => 'Anunț indisponibil';

  @override
  String get compareInactiveListing => 'Eliminat din publicare';

  @override
  String get compareSectionPriceBasics => 'Pret si de baza';

  @override
  String get compareSectionVehicle => 'Auto';

  @override
  String get compareSectionSpecs => 'Caracteristici';

  @override
  String get compareSectionTrustData => 'Încredere/date';

  @override
  String get compareRowPrice => 'Preţ';

  @override
  String get compareRowYear => 'An';

  @override
  String get compareRowMileage => 'Kilometraj';

  @override
  String get compareRowCityRegion => 'Oraș/Regiune';

  @override
  String get compareRowStatus => 'Starea anunțului';

  @override
  String get compareRowMake => 'Marca';

  @override
  String get compareRowModel => 'Model';

  @override
  String get compareRowBody => 'Corp';

  @override
  String get compareRowVehicleType => 'Tipul de transport';

  @override
  String get compareRowRegistration => 'Înregistrare';

  @override
  String get compareRowFuel => 'Combustibil';

  @override
  String get compareRowEngine => 'Motor';

  @override
  String get compareRowPower => 'Putere';

  @override
  String get compareRowTransmission => 'Cutie';

  @override
  String get compareRowDrivetrain => 'Conduce';

  @override
  String get compareRowDisplacement => 'Volum';

  @override
  String get compareRowVin => 'VIN';

  @override
  String get compareRowPhotos => 'Fotografie';

  @override
  String get compareRowPublishedAt => 'Data publicării';

  @override
  String get compareVinProvided => 'VIN listat';

  @override
  String get compareVinNotProvided => 'VIN nu este specificat';

  @override
  String get compareValueMissing => '—';

  @override
  String get listingVinReportLoadingCta => 'Se încarcă raportul VIN...';

  @override
  String get listingVinReportPendingCta =>
      'Raportul VIN este în curs de pregătire';

  @override
  String get listingVinReportNoDataCta => 'Datele VIN nu au fost găsite';

  @override
  String get listingVinReportUnavailableCta =>
      'Raportul VIN nu este disponibil';

  @override
  String get listingVinReportPendingTitle =>
      'Raportul VIN este încă în curs de pregătire';

  @override
  String get listingVinReportPendingBody =>
      'De obicei durează câteva minute. Datele vor apărea automat după verificare.';

  @override
  String get listingVinReportNoDataTitle => 'Datele VIN nu au fost găsite';

  @override
  String get listingVinReportNoDataBody =>
      'VIN-ul a fost adăugat de vânzător, dar în prezent nu există o transcriere publică disponibilă pentru acest VIN.';

  @override
  String get listingVinReportNoDataNote =>
      'Aceasta nu înseamnă verificarea istoricului vehiculului.';

  @override
  String get listingVinReportUnavailableTitle => 'Nu s-a obținut raportul VIN';

  @override
  String get listingVinReportUnavailableBody =>
      'VIN-ul a fost adăugat de vânzător, dar raportul este momentan indisponibil. Vă rugăm să încercați din nou mai târziu.';

  @override
  String get listingVinTrustSheetTitle => 'Informații VIN';

  @override
  String get listingVinTrustSheetIntro =>
      'Vânzătorul a adăugat un VIN pe listă. Numărul VIN complet nu este afișat public.';

  @override
  String get listingVinTrustSheetSectionVinProvidedLabel => 'VIN listat';

  @override
  String get listingVinTrustSheetSectionVinProvidedBody =>
      'VIN adăugat de vânzător.';

  @override
  String get listingVinTrustSheetSectionFormatLabel => 'Format VIN';

  @override
  String get listingVinTrustSheetSectionFormatBody =>
      'Formatul VIN pare corect: 17 caractere fără litere nevalide.';

  @override
  String get listingVinTrustSheetSectionPrivacyLabel => 'Confidențialitate';

  @override
  String get listingVinTrustSheetSectionPrivacyBody =>
      'Numărul VIN complet este disponibil numai vânzătorului și nu este afișat public în anunț.';

  @override
  String get listingVinTrustSheetFutureTitle => 'Ce urmează mai târziu';

  @override
  String get listingVinTrustSheetFutureItemVehicleData =>
      'Date despre vehicul prin VIN';

  @override
  String get listingVinTrustSheetFutureItemDamageHistory =>
      'Istoricul daunelor';

  @override
  String get listingVinTrustSheetFutureItemRegistrationInsurance =>
      'Verificari de inregistrare si asigurare';

  @override
  String get listingVinTrustSheetFutureItemListingCompare =>
      'Comparați datele VIN cu anunțul';

  @override
  String get listingVinTrustSheetFooterNote =>
      'Momentan este doar o verificare de bază a formatului. Verificări extinse din surse oficiale și partenere vor fi adăugate ulterior.';

  @override
  String get listingVinTrustSheetGotIt => 'Este clar';

  @override
  String get listingBuyerVinReportTitle => 'Raport VIN';

  @override
  String get listingBuyerVinReportLoading => 'Se încarcă raportul...';

  @override
  String get listingBuyerVinReportLoadError =>
      'Nu s-a încărcat raportul. Vă rugăm să încercați din nou mai târziu.';

  @override
  String get listingBuyerVinReportVinAddedBySeller =>
      'VIN adăugat de vânzător.';

  @override
  String get listingBuyerVinReportFullVinPrivate =>
      'Numărul VIN complet nu este afișat public.';

  @override
  String get listingBuyerVinReportPublicDataUnavailable =>
      'Datele VIN publice nu sunt încă disponibile.';

  @override
  String get listingBuyerVinReportFormatOnlyExplanation =>
      'Acum este afișat doar faptul că vânzătorul a indicat VIN-ul și formatul acestuia pare corect.';

  @override
  String get listingBuyerVinReportSourcesSectionTitle => 'Date din surse';

  @override
  String get listingBuyerVinReportSourceHeading => 'Sursă';

  @override
  String get listingBuyerVinReportUpdatedLabel => 'Data actualizării';

  @override
  String get listingBuyerVinReportLimitationsHeading => 'Restricții';

  @override
  String get listingBuyerVinReportClose => 'Este clar';

  @override
  String get listingBuyerVinReportBasicDecodeCatalogLine =>
      'Momentan este afișată doar decodarea de bază VIN din catalogul deschis NHTSA vPIC.';

  @override
  String get listingBuyerVinReportBasicDecodeNotOfficialLine =>
      'Decodare VIN de bază, nu verificare juridică sau istorică.';

  @override
  String get listingBuyerVinReportNhtsaCatalogSourceLine =>
      'Sursă: catalog deschis NHTSA vPIC.';

  @override
  String get listingBuyerVinReportNotVerifiedSectionTitle =>
      'Ce nu verifică încă Carzon';

  @override
  String get listingBuyerVinReportLimitationRegistrationMdPmr =>
      'Înmatricularea';

  @override
  String get listingBuyerVinReportLimitationOwner => 'Proprietarul';

  @override
  String get listingBuyerVinReportLimitationAccidentHistory =>
      'Accidente și daune';

  @override
  String get listingBuyerVinReportLimitationInsurance => 'Asigurare';

  @override
  String get listingBuyerVinReportLimitationMileage => 'Kilometraj';

  @override
  String get listingBuyerVinReportLimitationLegalEncumbrances =>
      'Restricții legale';

  @override
  String get listingBuyerVinReportLimitationUnknownFallback =>
      'Unele cecuri nu sunt încă disponibile.';

  @override
  String get listingBuyerVinReportCompareHint =>
      'Datele VIN pot fi comparate cu anunțul.';

  @override
  String get listingBuyerVinReportCompareMatch =>
      'Informațiile de bază VIN se potrivesc cu anunțul.';

  @override
  String get listingBuyerVinReportCompareMismatch =>
      'Datele VIN nu coincid cu anunțul.';

  @override
  String get listingBuyerVinReportDecodedEngineLabel => 'Motor';

  @override
  String get listingBuyerVinReportDecodedTransmissionLabel => 'Transmitere';

  @override
  String get listingBuyerVinReportNhtsaManufacturerLabel => 'Producător';

  @override
  String get listingBuyerVinReportNhtsaPlantCountryLabel => 'Țara de asamblare';

  @override
  String get listingBuyerVinReportNhtsaPlantCityLabel => 'Orașul Adunării';

  @override
  String get listingBuyerVinReportNhtsaPlantCompanyLabel => 'Fabrică';

  @override
  String get listingBuyerVinReportNhtsaVehicleTypeLabel => 'Tipul vehiculului';

  @override
  String get listingBuyerVinReportNhtsaTrimLabel => 'Echipamente';

  @override
  String get listingBuyerVinReportNhtsaSeriesLabel => 'Serie';

  @override
  String get listingBuyerVinReportNhtsaDriveTypeLabel => 'Conduce';

  @override
  String get listingBuyerVinReportNhtsaDoorsLabel => 'Ușile';

  @override
  String get listingBuyerVinReportNhtsaDisplacementLabel => 'Volum';

  @override
  String get listingBuyerVinReportNhtsaCylindersLabel => 'Cilindri';

  @override
  String get listingBuyerVinReportNhtsaGvwrLabel => 'Clasa de greutate brută';

  @override
  String get listingBuyerVinReportNhtsaCatalogDecodeCaution =>
      'Catalogul a returnat date incomplete pentru VIN — folosiți informațiile ca orientare, nu ca confirmare.';

  @override
  String get listingBuyerVinReportNhtsaGroupCoreIdentity => 'Bazele';

  @override
  String get listingBuyerVinReportNhtsaGroupVehicleSpecs => 'Caracteristici';

  @override
  String get listingBuyerVinReportNhtsaGroupOrigin => 'Asamblare';

  @override
  String get listingBuyerVinReportManualSourcesSectionTitle =>
      'Verificări suplimentare';

  @override
  String get listingBuyerVinReportManualSourcesIntro =>
      'Surse pentru verificare separată.';

  @override
  String get listingBuyerVinReportManualStatusExternalCheck =>
      'Verificare externă';

  @override
  String get listingBuyerVinReportManualStatusSellerDocument =>
      'Document de la vânzător';

  @override
  String get listingBuyerVinReportManualStatusFuture => 'Sursa viitoare';

  @override
  String get listingBuyerVinReportManualMdRcaTitle =>
      'Istoricul pagubelor în Moldova';

  @override
  String get listingBuyerVinReportManualMdRcaBody =>
      'Datele despre daune pot fi verificate pe portalul oficial RCA/BNM după VIN. Carzon nu primește aceste date automat.';

  @override
  String get listingBuyerVinReportManualMdRcaLimitation =>
      'Rezultatul evaluării externe nu este prezentat în acest raport.';

  @override
  String get listingBuyerVinReportManualMdAspTitle =>
      'Documente și date de înregistrare';

  @override
  String get listingBuyerVinReportManualMdAspBody =>
      'Vânzătorul poate furniza un document ASP/extras din Registrul de Stat al Transporturilor. Vă rugăm să verificați documentul original înainte de a cumpăra.';

  @override
  String get listingBuyerVinReportManualMdAspLimitation =>
      'Carzon nu verifică automat autenticitatea documentelor.';

  @override
  String get listingBuyerVinReportManualPmrCustomsTitle => 'Vămuirea în PMR';

  @override
  String get listingBuyerVinReportManualPmrCustomsBody =>
      'Informațiile despre vămuire pot fi verificate prin sursa oficială a Comitetului Vamal de Stat al PMR. Verificarea automată nu este încă efectuată în Carzon.';

  @override
  String get listingBuyerVinReportManualPmrCustomsLimitation =>
      'Datele vamale nu sunt incluse în acest raport.';

  @override
  String get listingBuyerVinReportManualCommercialTitle =>
      'Raport de istorie extins';

  @override
  String get listingBuyerVinReportManualCommercialBody =>
      'Rapoartele comerciale pot furniza informații suplimentare despre istoricul vehiculului dacă sursa acoperă piața respectivă. Integrarea va fi evaluată separat.';

  @override
  String get listingBuyerVinReportManualCommercialLimitation =>
      'Sursele comerciale nu sunt încă conectate la Carzon.';

  @override
  String get editListingVinReportSectionTitle => 'Stare VIN';

  @override
  String get editListingVinReportNoVinBody =>
      'VIN nu este specificat. După salvarea VIN-ului, starea procesării va apărea aici.';

  @override
  String get editListingVinReportPendingBody =>
      'VIN adăugat. Informațiile de bază sunt verificate.';

  @override
  String get editListingVinReportDecodedBody =>
      'Informațiile de bază VIN au fost procesate.';

  @override
  String get editListingVinReportFailedBody =>
      'Nu s-au procesat informațiile de bază VIN. VIN-ul este încă salvat.';

  @override
  String get editListingVinReportUnavailableBody =>
      'VIN salvat. Starea avansată nu este încă disponibilă.';

  @override
  String get editListingVinReportLimitationNote =>
      'Nu este o verificare oficială a înmatriculării, proprietarului, istoricului de accidente, asigurării sau kilometrajului.';

  @override
  String get editListingVinReportPrivacyNote =>
      'Numărul VIN complet nu este afișat public.';

  @override
  String get editListingVinReportBasicInfoHeading => 'Informații de bază';

  @override
  String get editListingVinReportDecodedMakeLabel => 'Marca';

  @override
  String get editListingVinReportDecodedModelLabel => 'Model';

  @override
  String get editListingVinReportDecodedYearLabel => 'An';

  @override
  String get editListingVinReportDecodedBodyLabel => 'Corp';

  @override
  String get editListingVinReportDecodedFuelLabel => 'Combustibil';

  @override
  String get editListingVinReportSourceLine =>
      'Sursa: NHTSA vPIC Base Transcript.';

  @override
  String get listingModelPassportSectionTitle => 'Date oficiale despre model';

  @override
  String get listingModelPassportFuelEconomyTitle => 'Consum conform sursei';

  @override
  String get listingModelPassportCombinedConsumption => 'Consum mixt';

  @override
  String get listingModelPassportCityConsumption => 'Consum în oraș';

  @override
  String get listingModelPassportHighwayConsumption => 'Consum pe drum';

  @override
  String get listingModelPassportFuelType => 'Combustibil conform sursei';

  @override
  String get listingModelPassportCo2Emissions => 'Emisii CO₂';

  @override
  String get listingModelPassportSource => 'Sursă';

  @override
  String get listingModelPassportLastUpdated => 'Actualizat:';

  @override
  String get listingModelPassportLoading => 'Se încarcă datele modelului…';

  @override
  String get listingModelPassportPendingTitle =>
      'Se încarcă datele oficiale ale modelului';

  @override
  String get listingModelPassportPendingBody =>
      'De obicei durează până la 30 de minute după publicare. Datele vor apărea automat dacă sursa oficială găsește informații pentru acest model.';

  @override
  String get listingModelPassportLimitationsTitle => 'Limitări';

  @override
  String get listingModelPassportSourceEpa => 'EPA · FuelEconomy.gov';

  @override
  String get listingModelPassportUnitLPer100km => 'l/100 km';

  @override
  String get listingModelPassportUnitGPerKm => 'g/km';

  @override
  String get listingModelPassportLimitationUsMarketOnly =>
      'Datele se referă la piața SUA și pot diferi de regiunea dvs.';

  @override
  String get listingModelPassportLimitationTrimEngineMarket =>
      'Valorile pot diferi în funcție de motor, echipare, piață și configurația exactă.';

  @override
  String get listingModelPassportLimitationModelLevel =>
      'Date la nivel de model, nu pentru vehiculul exact din anunț.';

  @override
  String get listingModelPassportLimitationSourceUnavailable =>
      'Unele date ale sursei nu sunt disponibile momentan.';

  @override
  String get listingModelPassportLimitationOpenData =>
      'Datele deschise ale sursei nu au fost verificate de Carzon și pot conține inexactități.';

  @override
  String get listingModelPassportLimitationNotHistory =>
      'Aceasta nu este istoria vehiculului, înmatriculărilor, accidentelor sau kilometrajului.';

  @override
  String get listingModelPassportLimitationNotRecall =>
      'Acestea nu sunt date despre rechemări sau campanii de siguranță.';

  @override
  String get listingModelPassportLimitationMultipleConfigurations =>
      'Pentru model pot exista mai multe configurații — sunt afișate valori medii sau tipice.';

  @override
  String get listingModelPassportLimitationBasicCatalogOnly =>
      'Date de catalog de referință, fără legătură cu un exemplar concret.';

  @override
  String get listingModelPassportLimitationGeneric =>
      'Datele sunt orientative și pot să nu corespundă vehiculului concret.';

  @override
  String get listingModelPassportFuelRegularGasoline => 'Benzină obișnuită';

  @override
  String get listingModelPassportFuelPremiumGasoline => 'Benzină premium';

  @override
  String get listingModelPassportFuelMidgradeGasoline => 'Benzină medie';

  @override
  String get listingModelPassportFuelDiesel => 'Motorină';

  @override
  String get listingModelPassportFuelElectricity => 'Electricitate';

  @override
  String get listingModelPassportFuelHybrid => 'Hibrid';

  @override
  String get listingModelPassportFuelPlugInHybrid => 'Hibrid plug-in';

  @override
  String get listingModelPassportFuelTypeGeneric =>
      'Combustibil conform datelor sursei';

  @override
  String get listingRecallTitle => 'Campanii de rechemare';

  @override
  String get listingRecallPendingTitle => 'Verificăm campaniile de siguranță';

  @override
  String get listingRecallPendingBody =>
      'Verificarea se face după marcă, model și an. De obicei durează până la 30 de minute după publicare.';

  @override
  String get listingRecallPendingLimitationNote =>
      'Aceasta nu este o verificare VIN. Pentru status exact, verificați VIN-ul la dealerul oficial, producător sau NHTSA.';

  @override
  String get listingRecallSourceBadge => 'NHTSA';

  @override
  String get listingRecallCampaignsFound => 'Verificare după model și an';

  @override
  String get listingRecallCampaignCount => 'Campanii';

  @override
  String listingRecallCampaignCountStat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count campanii găsite',
      few: '$count campanii găsite',
      one: '$count campanie găsită',
    );
    return '$_temp0';
  }

  @override
  String get listingRecallLastUpdated => 'Actualizat:';

  @override
  String get listingRecallComponent => 'Componentă';

  @override
  String get listingRecallSourceComponent => 'Componentă (sursă)';

  @override
  String get listingRecallComponentSuspensionFront =>
      'Suspensie · partea frontală';

  @override
  String get listingRecallComponentSeatBeltsRear =>
      'Centuri de siguranță · rândul din spate';

  @override
  String get listingRecallComponentEquipmentManual =>
      'Echipament · manual/serviciu';

  @override
  String get listingRecallComponentBackOverPreventionDisplay =>
      'Cameră/vizualizare spate · display';

  @override
  String get listingRecallComponentElectricalPropulsionBattery =>
      'Sistem electric · baterie de tracțiune';

  @override
  String get listingRecallComponentServiceBrakesAirSupply =>
      'Sistem de frânare · conducte';

  @override
  String get listingRecallComponentAirbagsFrontal => 'Airbag-uri · frontale';

  @override
  String get listingRecallCampaignNumber => 'Număr campanie';

  @override
  String get listingRecallManufacturer => 'Producător';

  @override
  String get listingRecallSummary => 'Descriere';

  @override
  String get listingRecallConsequence => 'Risc';

  @override
  String get listingRecallRemedy => 'Soluție';

  @override
  String get listingRecallNotes => 'Note';

  @override
  String get listingRecallReportReceivedDate => 'Data primirii raportului';

  @override
  String get listingRecallParkIt => 'Recomandare de a nu utiliza vehiculul';

  @override
  String get listingRecallParkOutside =>
      'Recomandare de a nu parca în interior';

  @override
  String get listingRecallOverTheAirUpdate => 'Actualizare over-the-air (OTA)';

  @override
  String get listingRecallFlagYes => 'Da';

  @override
  String get listingRecallLimitationsTitle => 'Limitări';

  @override
  String get listingRecallLimitationUsMarketDataOnly =>
      'Datele se referă la piața SUA și pot să nu corespundă regiunii dvs.';

  @override
  String get listingRecallLimitationModelLevelNotExactVehicle =>
      'Date la nivel de model și an, nu pentru vehiculul exact din anunț.';

  @override
  String get listingRecallLimitationNotVinVerifiedRecallStatus =>
      'Statusul rechemării nu a fost verificat după VIN — date orientative.';

  @override
  String get listingRecallLimitationMayDifferByTrimEngineMarket =>
      'Campaniile pot diferi în funcție de echipare, motor și piață.';

  @override
  String get listingRecallLimitationVerifyWithOfficialDealerOrNhtsa =>
      'Verificați statusul rechemării la dealerul oficial, producător sau pe site-ul NHTSA.';

  @override
  String get listingRecallLimitationMultipleCampaignsListed =>
      'Nu sunt afișate toate campaniile — lista poate fi incompletă.';

  @override
  String get listingRecallLimitationGeneric =>
      'Datele sunt orientative și pot să nu corespundă vehiculului concret.';

  @override
  String get listingRecallShowDetails => 'Detalii';

  @override
  String get listingRecallHideDetails => 'Ascunde';

  @override
  String listingRecallShowAllCampaigns(int count) {
    return 'Afișează toate cele $count campanii';
  }

  @override
  String get listingRecallChipParkIt => 'Nu utilizați';

  @override
  String get listingRecallChipParkOutside => 'Nu parcați în interior';

  @override
  String get listingRecallChipOverTheAirUpdate => 'OTA';

  @override
  String get notificationMessageTitle => 'Mesaj nou';

  @override
  String get notificationMessageBody =>
      'Ați primit un mesaj pentru anunțul din Carzon.';

  @override
  String get notificationFilterAlertTitle => 'Anunț nou';

  @override
  String get notificationFilterAlertBody =>
      'Există un anunț pentru filtrul salvat. Deschideți pentru a-l vedea.';

  @override
  String get notificationAndroidChannelMessagesName => 'Carzon — mesaje';

  @override
  String get notificationAndroidChannelMessagesDescription =>
      'Notificări despre mesaje noi în chat';

  @override
  String get notificationAndroidChannelFilterName => 'Carzon — alerte filtru';

  @override
  String get notificationAndroidChannelFilterDescription =>
      'Notificări despre anunțuri noi pentru filtrul salvat';
}
