# FinanceApp Project Context

This is a multi-platform financial application consisting of an iOS app, a web dashboard, and a Supabase-powered backend.

## Project Overview

- **iOS App (`FinanceApp/`):** A modern iOS application built with SwiftUI and SwiftData. It uses a Clean Architecture pattern (Core, Data, Domain, Presentation) and integrates with Supabase for authentication and data persistence.
- **Web Dashboard (`finance-web/`):** A web-based management interface built with Next.js 16, React 19, Tailwind CSS 4, and Framer Motion.
- **Backend (`supabase/`):** Powered by Supabase, providing PostgreSQL database, Edge Functions, Authentication, and Storage. Includes specific migrations for Plaid integration.
- **OAuth Redirect (`oauth/`):** A simple HTML redirector to handle Plaid OAuth flows back to the iOS app via custom URL schemes (`financeapp://`).

## Main Technologies

- **Mobile:** Swift, SwiftUI, SwiftData, Biometrics (FaceID/TouchID).
- **Web:** TypeScript, Next.js 16, Tailwind CSS 4, Framer Motion, Lucide React.
- **Backend:** Supabase (Postgres), Deno (Edge Functions), SQL.
- **Integrations:** Plaid (for banking connectivity).

## Architecture & Design Patterns

### iOS (`FinanceApp/`)
- **Clean Architecture:** Organized into `Core`, `Data`, `Domain`, and `Presentation` layers.
- **State Management:** Uses `@StateObject`, `@EnvironmentObject`, and SwiftData's `@Query`/`@Model`.
- **Managers:** Centralized logic in `AppInitializationManager`, `SettingsManager`, and `AuthViewModel`.
- **Theming:** Strictly follows a dark theme with orange accents as seen in `FinanceAppApp.swift`.

### Web (`finance-web/`)
- **Next.js App Router:** Modern React patterns and server/client components.
- **Styling:** Tailwind CSS 4 with `@tailwindcss/postcss`.

## Building and Running

### Web Dashboard
```bash
cd finance-web
npm install
npm run dev
```

### Backend (Supabase)
The project includes a local Supabase CLI binary in `bin/`.
```bash
# Start local Supabase services
./bin/supabase start

# Stop local Supabase services
./bin/supabase stop

# Check status
./bin/supabase status
```

### iOS App
1. Open `FinanceApp.xcodeproj` in Xcode.
2. Ensure you have the latest iOS SDK installed.
3. Run the project on a simulator or physical device.
4. **Note:** Biometrics and Plaid OAuth redirect might require a physical device or specific simulator setup.

## Development Conventions

- **SwiftLint:** The project uses SwiftLint to enforce coding standards (`.swiftlint.yml` in root).
- **Clean Architecture:** Maintain the separation of concerns between `Domain` (Business logic), `Data` (Repositories/DTOs), and `Presentation` (SwiftUI Views/ViewModels).
- **Environment Variables:** Ensure `.env` files are correctly set up for both Supabase and the Web project (refer to `supabase/config.toml` for expected env vars like `OPENAI_API_KEY`, `S3_HOST`, etc.).
- **Database Migrations:** All schema changes should be managed through Supabase migrations in `supabase/migrations/`.

## Key Files & Directories

- `FinanceAppApp.swift`: Main entry point for the iOS application.
- `supabase/config.toml`: Configuration for the local Supabase environment.
- `supabase/20240317_setup_plaid.sql`: Database schema for Plaid integration.
- `finance-web/package.json`: Dependencies and scripts for the web dashboard.
- `oauth/index.html`: Bridge for Plaid OAuth redirects.
