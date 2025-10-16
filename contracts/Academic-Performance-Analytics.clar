(define-constant ERR_INVALID_PERIOD (err u400))
(define-constant ERR_NO_DATA (err u401))

(define-map performance-snapshots
  { institution-id: uint, period: uint, subject: (string-ascii 50) }
  {
    total-exams: uint,
    average-score: uint,
    pass-rate: uint,
    top-performers: uint,
    period-start: uint,
    period-end: uint
  }
)

(define-map trend-analysis
  { institution-id: uint, subject: (string-ascii 50) }
  {
    current-period: uint,
    last-average: uint,
    trend-direction: (string-ascii 10),
    volatility-index: uint,
    last-updated: uint
  }
)

(define-read-only (get-performance-snapshot (institution-id uint) (period uint) (subject (string-ascii 50)))
  (map-get? performance-snapshots { institution-id: institution-id, period: period, subject: subject })
)

(define-read-only (get-trend-analysis (institution-id uint) (subject (string-ascii 50)))
  (map-get? trend-analysis { institution-id: institution-id, subject: subject })
)

(define-read-only (calculate-trend-direction (current-avg uint) (previous-avg uint))
  (if (> current-avg previous-avg)
    "upward"
    (if (< current-avg previous-avg)
      "downward"
      "stable"
    )
  )
)

(define-public (record-performance-snapshot 
  (institution-id uint) 
  (period uint) 
  (subject (string-ascii 50))
  (total-exams uint)
  (average-score uint)
  (pass-rate uint)
  (top-performers uint)
)
  (let (
    (period-start (* period u2016))
    (period-end (+ period-start u2015))
    (snapshot-key { institution-id: institution-id, period: period, subject: subject })
  )
    (asserts! (> total-exams u0) ERR_INVALID_PERIOD)
    (asserts! (<= pass-rate u100) ERR_INVALID_PERIOD)
    (map-set performance-snapshots
      snapshot-key
      {
        total-exams: total-exams,
        average-score: average-score,
        pass-rate: pass-rate,
        top-performers: top-performers,
        period-start: period-start,
        period-end: period-end
      }
    )
    (ok true)
  )
)

(define-public (update-trend-analysis 
  (institution-id uint) 
  (subject (string-ascii 50))
  (current-average uint)
)
  (let (
    (trend-key { institution-id: institution-id, subject: subject })
    (existing-trend (map-get? trend-analysis trend-key))
    (previous-avg (match existing-trend trend (get last-average trend) u0))
    (direction (calculate-trend-direction current-average previous-avg))
    (volatility (if (> current-average previous-avg) 
                   (- current-average previous-avg) 
                   (- previous-avg current-average)))
  )
    (map-set trend-analysis
      trend-key
      {
        current-period: (/ stacks-block-height u2016),
        last-average: current-average,
        trend-direction: direction,
        volatility-index: volatility,
        last-updated: stacks-block-height
      }
    )
    (ok direction)
  )
)