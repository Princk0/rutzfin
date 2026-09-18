// Neubrutalism KPI card — bold border + drop shadow offset
export default function KPICard({ label, value, sub, trend, color = '#ff3b00' }) {
  const isUp   = trend?.startsWith('+') || trend?.startsWith('↑')
  const isDown = trend?.startsWith('-') || trend?.startsWith('↓')

  return (
    <div className="bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0px_#1a1a1a] p-5 relative overflow-hidden group hover:-translate-y-0.5 hover:shadow-[4px_6px_0px_#1a1a1a] transition-all duration-150">
      {/* Accent top bar */}
      <div className="absolute top-0 left-0 right-0 h-[3px]" style={{ background: color }} />

      <p className="text-[10px] font-black uppercase tracking-[0.15em] text-[#1a1a1a] opacity-40 mt-1">
        {label}
      </p>

      <p className="text-3xl font-black tracking-tighter text-[#1a1a1a] mt-2 leading-none">
        {value}
      </p>

      <div className="flex items-center gap-2 mt-2">
        {trend && (
          <span className={`text-xs font-black uppercase ${
            isUp ? 'text-green-600' : isDown ? 'text-red-600' : 'text-[#1a1a1a] opacity-40'
          }`}>
            {trend}
          </span>
        )}
        {sub && (
          <span className="text-xs font-semibold text-[#1a1a1a] opacity-35">{sub}</span>
        )}
      </div>
    </div>
  )
}
