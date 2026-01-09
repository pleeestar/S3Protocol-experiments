import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "S3Protocol", description: "Consensus Gateway" };
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className="antialiased min-h-screen bg-background font-sans selection:bg-primary/20">{children}</body>
    </html>
  );
}
