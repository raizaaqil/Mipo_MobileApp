/// Isi dua nilai ini dari dashboard Supabase
/// (Project Settings > API). Panduan lengkap ada di PANDUAN_SETUP.md.
class SupabaseConfig {
  static const String url = 'https://ixxkgjlkvpbqcrvpvips.supabase.co';
  static const String anonKey = 'sb_publishable_VFDAs-W8eKgF_KiCrQ8yKQ_ul2wbXkG';

  static bool get isConfigured =>
      !url.startsWith('GANTI') && !anonKey.startsWith('GANTI');
}
