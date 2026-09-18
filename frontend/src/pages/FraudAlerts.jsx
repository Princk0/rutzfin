import { useEffect, useState } from 'react'
import { api } from '../api.js'

const MOCK = [
  { alert_id:1, severity:'Critical', alert_type:'Large Transaction',   customer_name:'Michael Chen',   flagged_amount:15000, transaction_date:'2025-03-28T01:03:00', channel:'ATM',    amount_vs_avg_ratio:3.8, alert_reason:'Transaction of $15,000 exceeds the $10,000 absolute threshold.' },
  { alert_id:2, severity:'High',     alert_type:'Statistical Anomaly', customer_name:'Amara Okonkwo',  flagged_amount:4200,  transaction_date:'2025-04-02T03:14:00', channel:'Online', amount_vs_avg_ratio:3.2, alert_reason:'Transaction is 3.2x the 90-day average of $1,312.' },
  { alert_id:3, severity:'Medium',   alert_type:'After-Hours Activity',customer_name:'Priya Sharma',   flagged_amount:2800,  transaction_date:'2025-02-23T02:48:00', channel:'ATM',    amount_vs_avg_ratio:2.1, alert_reason:'Withdrawal of $2,800 via ATM occurred at 2:00 hrs.' },
  { alert_id:4, severity:'Medium',   alert_type:'Statistical Anomaly', customer_name:'Sofia Petrov',   flagged_amount:950,   transaction_date:'2025-03-12T14:30:00', channel:'POS',    amount_vs_avg_ratio:2.0, alert_reason:'Transaction is 2.0x the 90-day average of $475.' },
]

const SEV_STYLE = {
  Critical: 'border-red-600   text-red-600',
  High:     'border-orange-500 text-orange-500',
  Medium:   'border-blue-600  text-blue-600',
  Low:      'border-green-600 text-green-600',
}

export default function FraudAlerts() {
  const [alerts,  setAlerts]  = useState(MOCK)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.fraudAlerts()
      .then(d => { if (d?.length) setAlerts(d) })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-4xl font-black tracking-tighter text-[#1a1a1a] uppercase leading-none">
          Fraud<br />Alert Queue.
        </h1>
        <p className="text-sm font-semibold text-[#1a1a1a] opacity-40 mt-2 uppercase tracking-widest">
          {alerts.filter(a => !a.is_resolved).length} unresolved · sorted by severity
        </p>
      </div>

      {/* Alert cards */}
      <div className="space-y-3">
        {alerts.map((alert) => (
          <div
            key={alert.alert_id}
            className="bg-white border-2 border-[#1a1a1a] shadow-[4px_4px_0_#1a1a1a] p-5"
          >
            <div className="flex items-start justify-between gap-4">
              <div className="flex items-center gap-3">
                <span className={`inline-flex items-center px-2 py-0.5 text-xs font-black uppercase tracking-wide border-2 ${SEV_STYLE[alert.severity] || 'border-gray-400 text-gray-400'}`}>
                  {alert.severity}
                </span>
                <span className="text-xs font-black uppercase tracking-widest text-[#1a1a1a] opacity-50">
                  {alert.alert_type}
                </span>
              </div>
              <span className="text-2xl font-black text-[#ff3b00] tracking-tighter whitespace-nowrap">
                ${Number(alert.flagged_amount).toLocaleString()}
              </span>
            </div>

            <div className="mt-3 grid grid-cols-2 md:grid-cols-4 gap-3">
              <div>
                <p className="text-[9px] font-black uppercase tracking-[0.15em] text-[#1a1a1a] opacity-30">Customer</p>
                <p className="text-sm font-bold text-[#1a1a1a] mt-0.5">{alert.customer_name}</p>
              </div>
              <div>
                <p className="text-[9px] font-black uppercase tracking-[0.15em] text-[#1a1a1a] opacity-30">Date & Time</p>
                <p className="text-sm font-bold text-[#1a1a1a] mt-0.5">
                  {new Date(alert.transaction_date).toLocaleString('en-CA', { month:'short', day:'numeric', hour:'2-digit', minute:'2-digit' })}
                </p>
              </div>
              <div>
                <p className="text-[9px] font-black uppercase tracking-[0.15em] text-[#1a1a1a] opacity-30">Channel</p>
                <p className="text-sm font-bold text-[#1a1a1a] mt-0.5">{alert.channel}</p>
              </div>
              <div>
                <p className="text-[9px] font-black uppercase tracking-[0.15em] text-[#1a1a1a] opacity-30">vs. Avg</p>
                <p className="text-sm font-bold text-[#ff3b00] mt-0.5">
                  {alert.amount_vs_avg_ratio != null ? alert.amount_vs_avg_ratio + '×' : '—'}
                </p>
              </div>
            </div>

            <p className="mt-3 text-xs font-semibold text-[#1a1a1a] opacity-50 border-t-2 border-[#1a1a1a] border-opacity-10 pt-3">
              {alert.alert_reason}
            </p>
          </div>
        ))}
      </div>
    </div>
  )
}
