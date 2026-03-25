import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Tic-Tac-Toe vs AI",
  description: "Play Tic-Tac-Toe against an MCTS-powered AI",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full antialiased">
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
