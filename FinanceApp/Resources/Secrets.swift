import Foundation

struct Secrets {
    static let supabaseURL = URL(string: "https://guwyoxbahwvxsqyvepam.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd1d3lveGJhaHd2eHNxeXZlcGFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwODYwMjUsImV4cCI6MjA4ODY2MjAyNX0.Q66iNTJSHB5QVAanQ8Y-3kn9RbHFwMGB4rWRe-TqyUE" // Clave anon segura de Supabase
    
    // Plaid Keys (Para más adelante)
    static let plaidClientID = "YOUR_PLAID_CLIENT_ID"
    static let plaidSecret = "YOUR_PLAID_SECRET"
}
