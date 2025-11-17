(define-constant ERR_INVALID_SNAPSHOT (err u600))
(define-constant ERR_SNAPSHOT_NOT_FOUND (err u601))
(define-constant ERR_ALREADY_ARCHIVED (err u602))
(define-constant ERR_INVALID_TIMEFRAME (err u603))

(define-map temporal-snapshots
  { snapshot-id: uint }
  {
    institution-id: uint,
    snapshot-block: uint,
    result-count: uint,
    snapshot-hash: (buff 32),
    frozen: bool,
    created-by: principal
  }
)

(define-map archived-results
  { result-id: uint }
  {
    archive-date: uint,
    archive-reason: (string-ascii 100),
    original-institution: uint,
    retrievable: bool,
    archival-snapshot: uint
  }
)

(define-map temporal-result-index
  { result-id: uint, block-height: uint }
  { snapshot-id: uint, active-at-block: bool }
)

(define-map institutional-snapshots
  { institution-id: uint }
  { snapshot-ids: (list 50 uint), latest-snapshot: uint }
)

(define-data-var next-snapshot-id uint u1)

(define-read-only (get-snapshot (snapshot-id uint))
  (map-get? temporal-snapshots { snapshot-id: snapshot-id })
)

(define-read-only (get-archived-result (result-id uint))
  (map-get? archived-results { result-id: result-id })
)

(define-read-only (is-result-active-at-block (result-id uint) (target-block uint))
  (match (map-get? temporal-result-index { result-id: result-id, block-height: target-block })
    index (get active-at-block index)
    false
  )
)

(define-public (create-temporal-snapshot 
  (institution-id uint) 
  (result-count uint) 
  (snapshot-hash (buff 32))
)
  (let (
    (snapshot-id (var-get next-snapshot-id))
    (current-snapshots (default-to { snapshot-ids: (list), latest-snapshot: u0 } 
                                   (map-get? institutional-snapshots { institution-id: institution-id })))
  )
    (asserts! (> result-count u0) ERR_INVALID_SNAPSHOT)
    (map-set temporal-snapshots
      { snapshot-id: snapshot-id }
      {
        institution-id: institution-id,
        snapshot-block: stacks-block-height,
        result-count: result-count,
        snapshot-hash: snapshot-hash,
        frozen: true,
        created-by: tx-sender
      }
    )
    (map-set institutional-snapshots
      { institution-id: institution-id }
      {
        snapshot-ids: (unwrap! (as-max-len? (append (get snapshot-ids current-snapshots) snapshot-id) u50) ERR_INVALID_SNAPSHOT),
        latest-snapshot: snapshot-id
      }
    )
    (var-set next-snapshot-id (+ snapshot-id u1))
    (ok snapshot-id)
  )
)

(define-public (archive-result 
  (result-id uint) 
  (reason (string-ascii 100)) 
  (institution-id uint)
)
  (let (
    (institutional-data (unwrap! (map-get? institutional-snapshots { institution-id: institution-id }) ERR_SNAPSHOT_NOT_FOUND))
  )
    (asserts! (is-none (map-get? archived-results { result-id: result-id })) ERR_ALREADY_ARCHIVED)
    (map-set archived-results
      { result-id: result-id }
      {
        archive-date: stacks-block-height,
        archive-reason: reason,
        original-institution: institution-id,
        retrievable: true,
        archival-snapshot: (get latest-snapshot institutional-data)
      }
    )
    (ok true)
  )
)

(define-public (index-result-temporally (result-id uint) (snapshot-id uint))
  (let ((snapshot (unwrap! (map-get? temporal-snapshots { snapshot-id: snapshot-id }) ERR_SNAPSHOT_NOT_FOUND)))
    (map-set temporal-result-index
      { result-id: result-id, block-height: (get snapshot-block snapshot) }
      { snapshot-id: snapshot-id, active-at-block: true }
    )
    (ok true)
  )
)

(define-read-only (query-snapshot-range (institution-id uint) (start-block uint) (end-block uint))
  (let (
    (snapshots (unwrap! (map-get? institutional-snapshots { institution-id: institution-id }) ERR_SNAPSHOT_NOT_FOUND))
  )
    (asserts! (<= start-block end-block) ERR_INVALID_TIMEFRAME)
    (ok {
      total-snapshots: (len (get snapshot-ids snapshots)),
      latest: (get latest-snapshot snapshots),
      query-start: start-block,
      query-end: end-block
    })
  )
)
