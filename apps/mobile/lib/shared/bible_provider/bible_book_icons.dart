import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Maps a book's OSIS code to a thematic Lucide icon shown next to its name
/// in the browser (per the client design — one consistent thin-line set).
/// Falls back to a generic open-book icon for codes not in the map.
const Map<String, IconData> kBibleBookIcons = {
  // -------- Old Testament --------
  'Gen': LucideIcons.leaf, // garden / creation
  'Exo': LucideIcons.mountain, // Sinai
  'Lev': LucideIcons.landmark, // altar / tabernacle
  'Num': LucideIcons.grip, // census / numbers
  'Deu': LucideIcons.scrollText, // the law repeated
  'Jos': LucideIcons.shield, // conquest
  'Jdg': LucideIcons.gavel, // judges
  'Rut': LucideIcons.wheat, // gleaning
  '1Sa': LucideIcons.crown, // kingship
  '2Sa': LucideIcons.music, // David's songs
  '1Ki': LucideIcons.crown,
  '2Ki': LucideIcons.crown,
  '1Ch': LucideIcons.scroll,
  '2Ch': LucideIcons.scroll,
  'Ezr': LucideIcons.bookOpen, // reading the law
  'Neh': LucideIcons.hammer, // rebuilding the wall
  'Est': LucideIcons.crown, // queen / royal
  'Job': LucideIcons.flame, // trial
  'Psa': LucideIcons.music2, // songs
  'Pro': LucideIcons.lamp, // wisdom
  'Ecc': LucideIcons.sun, // under the sun
  'Sng': LucideIcons.heart, // love
  'Isa': LucideIcons.scroll, // prophecy
  'Jer': LucideIcons.droplet, // weeping prophet
  'Lam': LucideIcons.droplets,
  'Eze': LucideIcons.eye, // visions
  'Dan': LucideIcons.shield, // lions' den
  'Hos': LucideIcons.heart,
  'Joe': LucideIcons.sun,
  'Amo': LucideIcons.wheat,
  'Oba': LucideIcons.mountain,
  'Jon': LucideIcons.fish, // sea / whale
  'Mic': LucideIcons.mountainSnow,
  'Nah': LucideIcons.flame,
  'Hab': LucideIcons.eye,
  'Zep': LucideIcons.flame,
  'Hag': LucideIcons.hammer,
  'Zec': LucideIcons.crown,
  'Mal': LucideIcons.flame,
  // -------- New Testament --------
  'Mat': LucideIcons.star, // the star / Messiah-King
  'Mar': LucideIcons.feather, // swift gospel
  'Luk': LucideIcons.heart,
  'John': LucideIcons.heart,
  'Act': LucideIcons.flame, // Pentecost
  'Rom': LucideIcons.send, // epistle
  '1Co': LucideIcons.send,
  '2Co': LucideIcons.send,
  'Gal': LucideIcons.send,
  'Eph': LucideIcons.shield, // armour of God
  'Phi': LucideIcons.heart, // joy
  'Col': LucideIcons.send,
  '1Th': LucideIcons.send,
  '2Th': LucideIcons.send,
  '1Ti': LucideIcons.users, // pastoral
  '2Ti': LucideIcons.users,
  'Tit': LucideIcons.users,
  'Phm': LucideIcons.handHeart, // reconciliation
  'Heb': LucideIcons.landmark, // temple / priesthood
  'Jas': LucideIcons.scale, // faith and works
  '1Pe': LucideIcons.anchor, // hope
  '2Pe': LucideIcons.anchor,
  '1Jo': LucideIcons.heart,
  '2Jo': LucideIcons.heart,
  '3Jo': LucideIcons.heart,
  'Jud': LucideIcons.flame,
  'Rev': LucideIcons.crown, // King of kings
};

IconData bibleBookIcon(String osisCode) =>
    kBibleBookIcons[osisCode] ?? LucideIcons.bookOpen;
