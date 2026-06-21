import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Single source of truth for Carzon's UI icon vocabulary.
///
/// Carzon uses Lucide as its primary icon family — a modern, consistent
/// outline set — and this class maps semantic roles (search, favorite,
/// phone, etc.) to the concrete `IconData`. UI widgets should reference
/// these roles rather than importing Lucide directly, so the icon
/// family can be swapped in exactly one place.
///
/// The two ornamental exceptions are [brandCarFallback] (used as a
/// drawn glyph when a brand SVG is not available) and [coverCarPlaceholder]
/// (used in the cover-image placeholder). Both are intentionally kept
/// on Material icons so they sit on a different visual track than the
/// UI chrome.
class CarzonIcons {
  const CarzonIcons._();

  // ---- Navigation ----
  static const IconData navListings = LucideIcons.search;
  static const IconData navFavoritesOutline = LucideIcons.heart;
  static const IconData navFavoritesFilled = LucideIcons.heart;
  static const IconData navCreateOutline = LucideIcons.plusCircle;
  static const IconData navCreateFilled = LucideIcons.plusCircle;
  static const IconData navMyListings = LucideIcons.listChecks;
  static const IconData navProfile = LucideIcons.user;
  static const IconData navMenu = LucideIcons.menu;

  // ---- Feed / search ----
  static const IconData search = LucideIcons.search;
  static const IconData searchEmpty = LucideIcons.searchX;
  static const IconData filter = LucideIcons.slidersHorizontal;
  static const IconData close = LucideIcons.x;
  static const IconData map = LucideIcons.map;
  static const IconData swap = LucideIcons.arrowRightLeft;
  static const IconData allBrands = LucideIcons.layoutGrid;

  // ---- Listing details — chrome ----
  static const IconData back = LucideIcons.chevronLeft;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData heartOutline = LucideIcons.heart;
  static const IconData heartFilled = LucideIcons.heart;
  static const IconData compare = LucideIcons.arrowLeftRight;
  static const IconData share = LucideIcons.share;
  static const IconData history = LucideIcons.clock;

  // ---- Listing details — feature strip ----
  static const IconData calendar = LucideIcons.calendar;
  static const IconData gauge = LucideIcons.gauge;
  static const IconData location = LucideIcons.mapPin;

  // ---- Contact / bottom bar ----
  static const IconData chat = LucideIcons.messageCircle;
  static const IconData phone = LucideIcons.phone;
  static const IconData phoneCall = LucideIcons.phoneCall;
  static const IconData phoneOff = LucideIcons.phoneOff;
  static const IconData eye = LucideIcons.eye;
  static const IconData copy = LucideIcons.copy;
  static const IconData send = LucideIcons.send;

  /// WhatsApp brand mark: see `WhatsappContactIcon` + `assets/contact/whatsapp.svg` (no Lucide glyph).

  // ---- Report / info / errors ----
  static const IconData report = LucideIcons.flag;
  static const IconData info = LucideIcons.info;
  static const IconData error = LucideIcons.alertCircle;

  // ---- Auth ----
  static const IconData mailCheck = LucideIcons.mailCheck;
  static const IconData lock = LucideIcons.lock;
  static const IconData keyReset = LucideIcons.keyRound;
  static const IconData signIn = LucideIcons.logIn;
  static const IconData signOut = LucideIcons.logOut;
  static const IconData user = LucideIcons.user;
  static const IconData settings = LucideIcons.settings;
  static const IconData privacy = LucideIcons.lock;

  /// Bell outline for informational “alert” chrome (delivery not implemented MVP).
  static const IconData notificationsOutline = LucideIcons.bell;
  static const IconData darkTheme = LucideIcons.moon;

  // ---- My listings / edit / create ----
  static const IconData myListings = LucideIcons.listChecks;
  static const IconData inventoryEmpty = LucideIcons.package;
  static const IconData moreActions = LucideIcons.moreVertical;
  static const IconData addPhoto = LucideIcons.camera;
  static const IconData photoLibrary = LucideIcons.image;
  static const IconData attach = LucideIcons.paperclip;
  static const IconData switchCamera = LucideIcons.switchCamera;
  static const IconData flashOn = LucideIcons.zap;
  static const IconData flashOff = LucideIcons.zapOff;
  static const IconData brokenImage = LucideIcons.imageOff;
  static const IconData delete = LucideIcons.trash2;
  static const IconData undo = LucideIcons.rotateCcw;
  static const IconData userBlock = LucideIcons.userX;

  // ---- Ornamental (kept on Material) ----
  static const IconData brandCarFallback = Icons.directions_car;
  static const IconData coverCarPlaceholder =
      Icons.directions_car_filled_outlined;
}
