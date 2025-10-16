(define-constant ERR_INVALID_RESULT (err u500))
(define-constant ERR_AUDIT_NOT_FOUND (err u501))
(define-constant ERR_INVALID_HASH (err u502))

(define-map audit-entries
  { audit-id: uint }
  {
    result-id: uint,
    modifier: principal,
    action-type: (string-ascii 20),
    previous-hash: (buff 32),
    new-hash: (buff 32),
    field-modified: (string-ascii 30),
    old-value: (string-ascii 50),
    new-value: (string-ascii 50),
    timestamp: uint,
    block-height: uint
  }
)

(define-map result-audit-chain
  { result-id: uint }
  {
    audit-ids: (list 100 uint),
    modification-count: uint,
    last-audit-hash: (buff 32),
    integrity-verified: bool
  }
)

(define-map audit-metadata
  { result-id: uint }
  {
    first-recorded: uint,
    last-modified: uint,
    total-modifications: uint,
    suspicious-activity: bool
  }
)

(define-data-var next-audit-id uint u1)

(define-read-only (get-audit-entry (audit-id uint))
  (map-get? audit-entries { audit-id: audit-id })
)

(define-read-only (get-result-audit-chain (result-id uint))
  (map-get? result-audit-chain { result-id: result-id })
)

(define-read-only (get-audit-metadata (result-id uint))
  (map-get? audit-metadata { result-id: result-id })
)

(define-read-only (verify-audit-integrity (result-id uint) (expected-hash (buff 32)))
  (match (map-get? result-audit-chain { result-id: result-id })
    chain (ok (is-eq (get last-audit-hash chain) expected-hash))
    ERR_AUDIT_NOT_FOUND
  )
)

(define-public (record-audit-entry
  (result-id uint)
  (action-type (string-ascii 20))
  (previous-hash (buff 32))
  (new-hash (buff 32))
  (field-modified (string-ascii 30))
  (old-value (string-ascii 50))
  (new-value (string-ascii 50))
)
  (let (
    (audit-id (var-get next-audit-id))
    (current-chain (default-to { audit-ids: (list), modification-count: u0, last-audit-hash: 0x00, integrity-verified: true }
                                (map-get? result-audit-chain { result-id: result-id })))
    (current-metadata (default-to { first-recorded: u0, last-modified: u0, total-modifications: u0, suspicious-activity: false }
                                   (map-get? audit-metadata { result-id: result-id })))
  )
    (asserts! (> result-id u0) ERR_INVALID_RESULT)
    (map-set audit-entries
      { audit-id: audit-id }
      {
        result-id: result-id,
        modifier: tx-sender,
        action-type: action-type,
        previous-hash: previous-hash,
        new-hash: new-hash,
        field-modified: field-modified,
        old-value: old-value,
        new-value: new-value,
        timestamp: stacks-block-height,
        block-height: stacks-block-height
      }
    )
    (map-set result-audit-chain
      { result-id: result-id }
      {
        audit-ids: (unwrap! (as-max-len? (append (get audit-ids current-chain) audit-id) u100) ERR_INVALID_RESULT),
        modification-count: (+ (get modification-count current-chain) u1),
        last-audit-hash: new-hash,
        integrity-verified: (is-eq (get last-audit-hash current-chain) previous-hash)
      }
    )
    (map-set audit-metadata
      { result-id: result-id }
      {
        first-recorded: (if (is-eq (get first-recorded current-metadata) u0) stacks-block-height (get first-recorded current-metadata)),
        last-modified: stacks-block-height,
        total-modifications: (+ (get total-modifications current-metadata) u1),
        suspicious-activity: (not (is-eq (get last-audit-hash current-chain) previous-hash))
      }
    )
    (var-set next-audit-id (+ audit-id u1))
    (ok audit-id)
  )
)

(define-read-only (get-modification-history (result-id uint))
  (match (map-get? result-audit-chain { result-id: result-id })
    chain (ok {
      total-changes: (get modification-count chain),
      integrity-status: (get integrity-verified chain),
      latest-hash: (get last-audit-hash chain),
      audit-count: (len (get audit-ids chain))
    })
    ERR_AUDIT_NOT_FOUND
  )
)

(define-read-only (detect-suspicious-activity (result-id uint))
  (match (map-get? audit-metadata { result-id: result-id })
    metadata (get suspicious-activity metadata)
    false
  )
)
