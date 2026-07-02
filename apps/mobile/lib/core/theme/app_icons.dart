import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Central icon registry for Faith Journal.
///
/// Every icon used in the UI is named here once, so the whole app pulls from a
/// single, consistent thin-line set (Lucide). If a glyph ever needs to change,
/// it changes in one place.
///
/// Usage:  Icon(AppIcons.bible, color: AppColors.gold)
class AppIcons {
  AppIcons._();

  // ---------------------------------------------------------------------------
  // Bottom navigation
  // ---------------------------------------------------------------------------
  static const home = LucideIcons.house;
  static const bible = LucideIcons.bookOpen;
  static const journal = LucideIcons.notebook;
  static const prayer = LucideIcons.heartHandshake; // nav uses pray.png asset
  static const profile = LucideIcons.circleUser;

  // ---------------------------------------------------------------------------
  // Verse actions (bottom sheet)
  // ---------------------------------------------------------------------------
  static const save = LucideIcons.bookmark;
  static const highlight = LucideIcons.highlighter;
  static const tag = LucideIcons.tag;
  static const reflect = LucideIcons.penLine;
  static const share = LucideIcons.share2;

  // ---------------------------------------------------------------------------
  // Search & filters
  // ---------------------------------------------------------------------------
  static const search = LucideIcons.search;
  static const filter = LucideIcons.slidersHorizontal;
  static const filterFunnel = LucideIcons.listFilter;

  // ---------------------------------------------------------------------------
  // Reflections / voice
  // ---------------------------------------------------------------------------
  static const note = LucideIcons.stickyNote;
  static const noteLines = LucideIcons.fileText;
  static const bookmark = LucideIcons.bookmark;
  static const textSize = LucideIcons.aLargeSmall;
  static const mic = LucideIcons.mic;
  static const play = LucideIcons.play;
  static const pause = LucideIcons.pause;
  static const delete = LucideIcons.trash2;
  static const reRecord = LucideIcons.rotateCcw;

  // ---------------------------------------------------------------------------
  // Prayer status
  // ---------------------------------------------------------------------------
  static const prayerActive = LucideIcons.flame;
  static const prayerWaiting = LucideIcons.hourglass;
  static const prayerAnswered = LucideIcons.circleCheck;
  static const add = LucideIcons.plus;

  // ---------------------------------------------------------------------------
  // Navigation & common UI
  // ---------------------------------------------------------------------------
  static const back = LucideIcons.chevronLeft;
  static const backArrow = LucideIcons.arrowLeft;
  static const forward = LucideIcons.chevronRight;
  static const arrowRight = LucideIcons.arrowRight;
  static const person = LucideIcons.user;
  static const mail = LucideIcons.mail;
  static const lock = LucideIcons.lock;
  static const chevronDown = LucideIcons.chevronDown;
  static const close = LucideIcons.x;
  static const check = LucideIcons.check;
  static const calendar = LucideIcons.calendar;
  static const clock = LucideIcons.clock;
  static const eye = LucideIcons.eye;
  static const eyeOff = LucideIcons.eyeOff;
  static const heart = LucideIcons.heart;
  static const cross = LucideIcons.cross;
  static const sparkle = LucideIcons.sparkle;
  static const sparkles = LucideIcons.sparkles;

  // ---------------------------------------------------------------------------
  // Settings / profile rows
  // ---------------------------------------------------------------------------
  static const bibleVersion = LucideIcons.bookMarked;
  static const notifications = LucideIcons.bell;
  static const theme = LucideIcons.palette;
  static const privacy = LucideIcons.shield;
  static const help = LucideIcons.circleHelp;
  static const about = LucideIcons.info;
  static const logout = LucideIcons.logOut;
}
