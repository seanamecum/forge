import Foundation

/// Supabase project constants. The anon key is a *publishable* client key by
/// design (Supabase docs: safe to ship in apps — row-level security is the
/// protection); the service-role key must never appear in the app.
enum SupabaseConfig {
    static let url = URL(string: "https://vxprqlniecdcxjkevoob.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ4cHJxbG5pZWNkY3hqa2V2b29iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3MzY4NjEsImV4cCI6MjA5OTMxMjg2MX0.YAa5hW56xq3zZm8_LrBOFexkwXPVl2k-kA_jtxRRSwI"
}
