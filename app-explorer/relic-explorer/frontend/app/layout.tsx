import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Relic Protocol | Decentralized Persona Network',
  description: 'The Internet 2 Gateway',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="dark">
      <body className="antialiased bg-background text-primary selection:bg-indigo-500/30">
        {children}
      </body>
    </html>
  )
}
