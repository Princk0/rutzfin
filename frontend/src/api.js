// Rutzfin API service — all Flask backend calls live here
const BASE = '/api'

async function get(path) {
  const res = await fetch(BASE + path)
  if (!res.ok) throw new Error(`API error ${res.status}: ${path}`)
  return res.json()
}

async function post(path, body) {
  const res = await fetch(BASE + path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error(`API error ${res.status}: ${path}`)
  return res.json()
}

export const api = {
  dashboard:        () => get('/dashboard'),
  branches:         () => get('/branches'),
  customers:        () => get('/customers'),
  customer:        (id) => get(`/customers/${id}`),
  transactions:    (id) => get(`/transactions/${id}`),
  fraudAlerts:      () => get('/fraud/alerts'),
  loanHealth:       () => get('/loans/health'),
  monthlyTrends:    () => get('/analytics/monthly-trends'),
  customerSegments: () => get('/analytics/customer-segments'),
  transfer:        (body) => post('/transfer', body),
}
