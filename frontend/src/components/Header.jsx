// Neubrutalism-style top header bar
// Bold RUTZFIN branding with orange accent + thick black border bottom

export default function Header() {
  const today = new Date().toLocaleDateString('en-CA', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
  })

  return (
    <header className="bg-[#f5f0e8] border-b-[3px] border-[#1a1a1a] px-7 py-3 flex items-center gap-6 shrink-0 z-50">
      {/* Brand */}
      <div className="flex items-baseline gap-0.5">
        <span className="text-2xl font-black tracking-tighter text-[#1a1a1a] uppercase">
          RUTZ
        </span>
        <span className="text-2xl font-black tracking-tighter text-[#ff3b00] uppercase">
          FIN
        </span>
      </div>

      {/* Divider */}
      <div className="h-6 w-[2px] bg-[#1a1a1a] opacity-20" />

      {/* Subtitle */}
      <span className="text-xs font-bold uppercase tracking-widest text-[#1a1a1a] opacity-40">
        FinTech Platform
      </span>

      {/* Spacer */}
      <div className="flex-1" />

      {/* Live indicator */}
      <div className="flex items-center gap-2">
        <span className="relative flex h-2 w-2">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#ff3b00] opacity-75" />
          <span className="relative inline-flex rounded-full h-2 w-2 bg-[#ff3b00]" />
        </span>
        <span className="text-xs font-bold uppercase tracking-widest text-[#1a1a1a] opacity-50">
          Live
        </span>
      </div>

      {/* Date */}
      <div className="hidden md:block text-xs font-semibold text-[#1a1a1a] opacity-40 border-l-2 border-[#1a1a1a] border-opacity-20 pl-5">
        {today}
      </div>
    </header>
  )
}
