import { Routes, Route, Navigate } from 'react-router-dom'
import Sidebar from './components/Sidebar.jsx'
import Header  from './components/Header.jsx'
import Overview    from './pages/Overview.jsx'
import FraudAlerts from './pages/FraudAlerts.jsx'
import LoanHealth  from './pages/LoanHealth.jsx'
import Analytics   from './pages/Analytics.jsx'
import Branches    from './pages/Branches.jsx'
import Customers   from './pages/Customers.jsx'

export default function App() {
  return (
    <div className="flex flex-col h-screen overflow-hidden">
      {/* ── Neubrutalism top header ── */}
      <Header />

      <div className="flex flex-1 overflow-hidden">
        {/* ── Clean Enterprise sidebar ── */}
        <Sidebar />

        {/* ── Page content ── */}
        <main className="flex-1 overflow-y-auto bg-[#f5f0e8] p-7">
          <Routes>
            <Route path="/"           element={<Navigate to="/overview" replace />} />
            <Route path="/overview"   element={<Overview />} />
            <Route path="/fraud"      element={<FraudAlerts />} />
            <Route path="/loans"      element={<LoanHealth />} />
            <Route path="/analytics"  element={<Analytics />} />
            <Route path="/branches"   element={<Branches />} />
            <Route path="/customers"  element={<Customers />} />
          </Routes>
        </main>
      </div>
    </div>
  )
}
