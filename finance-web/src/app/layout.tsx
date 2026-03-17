import type { Metadata } from "next";
import { Outfit } from "next/font/google";
import "./globals.css";

const outfit = Outfit({
  subsets: ["latin"],
  variable: "--font-sans",
});

export const metadata: Metadata = {
  title: "FinanceApp | Master Your Finances with Elegance",
  description: "Experience the future of personal finance. Secure bank sync, collaborative budgeting, and beautiful data visualizations. Take control of your wealth today.",
  keywords: ["personal finance", "budgeting app", "expense tracker", "Plaid integration", "financial freedom", "shared budgets"],
  authors: [{ name: "GlennnDeveloper" }],
  openGraph: {
    title: "FinanceApp | Master Your Finances with Elegance",
    description: "The most beautiful and powerful way to manage your personal finances.",
    url: "https://financeapp.example.com",
    siteName: "FinanceApp",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "FinanceApp Landing Page",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "FinanceApp | Master Your Finances with Elegance",
    description: "Take control of your wealth with the most beautiful finance app.",
    images: ["/og-image.png"],
  },
  viewport: "width=device-width, initial-scale=1",
  robots: "index, follow",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${outfit.variable} font-sans antialiased`}>
        {children}
      </body>
    </html>
  );
}
