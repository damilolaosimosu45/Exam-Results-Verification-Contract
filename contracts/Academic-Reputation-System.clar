(define-constant ERR_NOT_AUTHORIZED (err u300))
(define-constant ERR_INSTITUTION_NOT_FOUND (err u301))
(define-constant ERR_ALREADY_ENDORSED (err u302))

(define-map institution-metrics
  { institution-id: uint }
  {
    total-certificates: uint,
    total-revocations: uint,
    endorsement-count: uint,
    reputation-score: uint,
    last-updated: uint
  }
)

(define-map endorsements
  { endorser: principal, institution-id: uint }
  { endorsed-at: uint, weight: uint }
)

(define-map institutional-endorsers
  { institution-id: uint }
  { endorser-list: (list 20 principal) }
)

(define-read-only (get-institution-metrics (institution-id uint))
  (map-get? institution-metrics { institution-id: institution-id })
)

(define-read-only (calculate-reputation-score (institution-id uint))
  (match (map-get? institution-metrics { institution-id: institution-id })
    metrics
    (let (
      (total-certs (get total-certificates metrics))
      (revocations (get total-revocations metrics))
      (endorsement-count (get endorsement-count metrics))
      (base-score (if (> total-certs u0) (/ (* u1000 (- total-certs revocations)) total-certs) u0))
      (endorsement-bonus (* endorsement-count u50))
    )
      (+ base-score endorsement-bonus)
    )
    u0
  )
)

(define-public (update-certificate-metrics (institution-id uint) (increment-type (string-ascii 10)))
  (let (
    (current-metrics (default-to { total-certificates: u0, total-revocations: u0, endorsement-count: u0, reputation-score: u0, last-updated: u0 }
                                  (map-get? institution-metrics { institution-id: institution-id })))
  )
    (if (is-eq increment-type "issued")
      (map-set institution-metrics
        { institution-id: institution-id }
        (merge current-metrics {
          total-certificates: (+ (get total-certificates current-metrics) u1),
          reputation-score: (calculate-reputation-score institution-id),
          last-updated: stacks-block-height
        })
      )
      (if (is-eq increment-type "revoked")
        (map-set institution-metrics
          { institution-id: institution-id }
          (merge current-metrics {
            total-revocations: (+ (get total-revocations current-metrics) u1),
            reputation-score: (calculate-reputation-score institution-id),
            last-updated: stacks-block-height
          })
        )
        false
      )
    )
    (ok true)
  )
)

(define-public (endorse-institution (institution-id uint) (weight uint))
  (let (
    (endorsement-key { endorser: tx-sender, institution-id: institution-id })
    (current-endorsers (default-to { endorser-list: (list) } (map-get? institutional-endorsers { institution-id: institution-id })))
    (current-metrics (default-to { total-certificates: u0, total-revocations: u0, endorsement-count: u0, reputation-score: u0, last-updated: u0 }
                                  (map-get? institution-metrics { institution-id: institution-id })))
  )
    (asserts! (is-none (map-get? endorsements endorsement-key)) ERR_ALREADY_ENDORSED)
    (map-set endorsements endorsement-key { endorsed-at: stacks-block-height, weight: weight })
    (map-set institutional-endorsers
      { institution-id: institution-id }
      { endorser-list: (unwrap! (as-max-len? (append (get endorser-list current-endorsers) tx-sender) u20) ERR_ALREADY_ENDORSED) }
    )
    (map-set institution-metrics
      { institution-id: institution-id }
      (merge current-metrics {
        endorsement-count: (+ (get endorsement-count current-metrics) u1),
        reputation-score: (calculate-reputation-score institution-id),
        last-updated: stacks-block-height
      })
    )
    (ok true)
  )
)
