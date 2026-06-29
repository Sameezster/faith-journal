import 'package:flutter/material.dart';

/// Maps a book's OSIS code to a thematic icon shown next to its name in the
/// browser. Falls back to a generic open-book icon for codes not in the map.
const Map<String, IconData> kBibleBookIcons = {
  // -------- Old Testament --------
  'Gen': Icons.eco_outlined, // garden / creation
  'Exo': Icons.terrain, // mountain (Sinai)
  'Lev': Icons.church_outlined, // altar / tabernacle
  'Num': Icons.grid_view_outlined, // census / numbers
  'Deu': Icons.menu_book_outlined, // tablets / law
  'Jos': Icons.shield_outlined, // conquest
  'Jdg': Icons.gavel, // judges
  'Rut': Icons.grass_outlined, // gleaning / wheat
  '1Sa': Icons.workspace_premium_outlined, // crown / kingship
  '2Sa': Icons.workspace_premium_outlined,
  '1Ki': Icons.workspace_premium_outlined,
  '2Ki': Icons.workspace_premium_outlined,
  '1Ch': Icons.workspace_premium_outlined,
  '2Ch': Icons.workspace_premium_outlined,
  'Ezr': Icons.architecture_outlined, // rebuilding the temple
  'Neh': Icons.foundation_outlined, // rebuilding the wall
  'Est': Icons.diamond_outlined, // queen / royal
  'Job': Icons.psychology_outlined, // suffering / wisdom
  'Psa': Icons.music_note, // songs
  'Pro': Icons.lightbulb_outline, // wisdom
  'Ecc': Icons.hourglass_empty, // vanity / time
  'Sng': Icons.favorite_outline, // love
  'Isa': Icons.campaign_outlined, // prophecy
  'Jer': Icons.water_drop_outlined, // weeping prophet
  'Lam': Icons.water_drop_outlined,
  'Eze': Icons.visibility_outlined, // visions
  'Dan': Icons.shield_moon_outlined, // lions' den
  'Hos': Icons.heart_broken_outlined,
  'Joe': Icons.bug_report_outlined, // locusts
  'Amo': Icons.balance, // justice
  'Oba': Icons.campaign_outlined,
  'Jon': Icons.waves, // sea / whale
  'Mic': Icons.balance,
  'Nah': Icons.campaign_outlined,
  'Hab': Icons.help_outline, // questioning God
  'Zep': Icons.campaign_outlined,
  'Hag': Icons.architecture_outlined,
  'Zec': Icons.visibility_outlined,
  'Mal': Icons.campaign_outlined,
  // -------- New Testament --------
  'Mat': Icons.menu_book, // gospel
  'Mar': Icons.menu_book,
  'Luk': Icons.menu_book,
  'John': Icons.menu_book,
  'Act': Icons.directions_walk, // missionary journeys
  'Rom': Icons.mail_outline, // epistle
  '1Co': Icons.mail_outline,
  '2Co': Icons.mail_outline,
  'Gal': Icons.mail_outline,
  'Eph': Icons.mail_outline,
  'Phi': Icons.mail_outline,
  'Col': Icons.mail_outline,
  '1Th': Icons.mail_outline,
  '2Th': Icons.mail_outline,
  '1Ti': Icons.mail_outline,
  '2Ti': Icons.mail_outline,
  'Tit': Icons.mail_outline,
  'Phm': Icons.mail_outline,
  'Heb': Icons.menu_book,
  'Jas': Icons.mail_outline,
  '1Pe': Icons.mail_outline,
  '2Pe': Icons.mail_outline,
  '1Jo': Icons.mail_outline,
  '2Jo': Icons.mail_outline,
  '3Jo': Icons.mail_outline,
  'Jud': Icons.mail_outline,
  'Rev': Icons.all_inclusive, // alpha & omega
};

IconData bibleBookIcon(String osisCode) =>
    kBibleBookIcons[osisCode] ?? Icons.menu_book_outlined;
