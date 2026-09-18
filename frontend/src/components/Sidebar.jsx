import { useState } from 'react'
import { NavLink } from 'react-router-dom'

const NAV = [
  { to: '/overview',  icon: '▦', label: 'Overview'     },
  { to: '/fraud',     icon: '⚠', label: 'Fraud Alerts' },
  { to: '/loans',     icon: '⬡', label: 'Loan Health'  },
  { to: '/analytics', icon: '◈', label: 'Analytics'    },
  { to: '/branches',  icon: '⌂', label: 'Branches'     },
  { to: '/customers', icon: '◉', label: 'Customers'    },
]

function HamburgerIcon({ open }) {
  return (
    <div className="flex flex-col gap-[5px]" style={{ width: 20 }}>
      <span
        className="block h-[2px] bg-[#1a1a1a] transition-all duration-200 origin-center"
        style={{ transform: open ? 'translateY(7px) rotate(45deg)' : 'none' }}
      />
      <span
        className="block h-[2px] bg-[#1a1a1a] transition-all duration-200 origin-center"
        style={{ opacity: open ? 0 : 1, transform: open ? 'scaleX(0)' : 'none' }}
      />
      <span
        className="block h-[2px] bg-[#1a1a1a] transition-all duration-200 origin-center"
        style={{ transform: open ? 'translateY(-7px) rotate(-45deg)' : 'none' }}
      />
    </div>
  )
}

export default function Sidebar() {
  const [expanded, setExpanded] = useState(false)

  return (
    <aside
      className="shrink-0 bg-white border-r-[3px] border-[#1a1a1a] flex flex-col overflow-hidden min-h-screen"
      style={{ width: expanded ? 224 : 64, transition: 'width 220ms ease-in-out' }}
      onMouseEnter={() => setExpanded(true)}
      onMouseLeave={() => setExpanded(false)}
    >
      {/* Hamburger header */}
      <div className="flex items-center justify-center h-14 border-b-2 border-[#1a1a1a] border-opacity-10 flex-shrink-0">
        <HamburgerIcon open={expanded} />
      </div>

      {/* Nav items */}
      <nav className="flex flex-col gap-0.5 px-2 flex-1 pt-2">
        {NAV.map(({ to, icon, label }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              'flex items-center gap-3 px-3 py-2.5 text-sm font-bold transition-all duration-100 ' +
              (isActive
                ? 'bg-[#1a1a1a] text-white border-l-4 border-[#ff3b00]'
                : 'text-[#1a1a1a] opacity-50 hover:opacity-100 hover:bg-[#1a1a1a0d] border-l-4 border-transparent')
            }
          >
            <span className="text-base w-5 text-center shrink-0">{icon}</span>
            <span
              className="uppercase tracking-wide text-xs whitespace-nowrap"
              style={{ opacity: expanded ? 1 : 0, transition: 'opacity 150ms ease' }}
            >
              {label}
            </span>
          </NavLink>
        ))}
      </nav>

      {/* Footer */}
      <div
        className="p-4 border-t-2 border-[#1a1a1a] border-opacity-10 mt-auto"
        style={{ opacity: expanded ? 1 : 0, transition: 'opacity 150ms ease' }}
      >
        <p className="text-[10px] font-black uppercase tracking-wider text-[#1a1a1a] opacity-30 whitespace-nowrap">
          Kelly Prince · CS Portfolio
        </p>
      </div>
    </aside>
  )
}
