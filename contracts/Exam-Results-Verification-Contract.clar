(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INSTITUTION_NOT_FOUND (err u101))
(define-constant ERR_RESULT_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_INVALID_GRADE (err u104))
(define-constant ERR_INVALID_INSTITUTION (err u105))

(define-map institutions
  { institution-id: uint }
  {
    name: (string-ascii 100),
    admin: principal,
    verified: bool,
    created-at: uint
  }
)

(define-map exam-results
  { result-id: uint }
  {
    student-wallet: principal,
    institution-id: uint,
    exam-name: (string-ascii 100),
    subject: (string-ascii 50),
    grade: (string-ascii 10),
    score: uint,
    max-score: uint,
    exam-date: uint,
    issued-at: uint,
    verified: bool
  }
)

(define-map student-results
  { student: principal, institution-id: uint }
  { result-ids: (list 50 uint) }
)

(define-map institution-admins
  { admin: principal }
  { institution-id: uint }
)

(define-data-var next-institution-id uint u1)
(define-data-var next-result-id uint u1)

(define-read-only (get-institution (institution-id uint))
  (map-get? institutions { institution-id: institution-id })
)

(define-read-only (get-exam-result (result-id uint))
  (map-get? exam-results { result-id: result-id })
)

(define-read-only (get-student-results (student principal) (institution-id uint))
  (map-get? student-results { student: student, institution-id: institution-id })
)

(define-read-only (get-admin-institution (admin principal))
  (map-get? institution-admins { admin: admin })
)

(define-read-only (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)

(define-read-only (is-institution-admin (institution-id uint))
  (match (map-get? institutions { institution-id: institution-id })
    institution (is-eq tx-sender (get admin institution))
    false
  )
)

(define-read-only (verify-result (result-id uint))
  (match (map-get? exam-results { result-id: result-id })
    result
    (let ((institution (unwrap! (map-get? institutions { institution-id: (get institution-id result) }) (err ERR_INSTITUTION_NOT_FOUND))))
      (ok {
        student: (get student-wallet result),
        institution: (get name institution),
        exam: (get exam-name result),
        subject: (get subject result),
        grade: (get grade result),
        score: (get score result),
        max-score: (get max-score result),
        verified: (and (get verified result) (get verified institution))
      })
    )
    (err ERR_RESULT_NOT_FOUND)
  )
)

(define-public (register-institution (name (string-ascii 100)))
  (let ((institution-id (var-get next-institution-id)))
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (map-set institutions
      { institution-id: institution-id }
      {
        name: name,
        admin: tx-sender,
        verified: false,
        created-at: stacks-block-height
      }
    )
    (map-set institution-admins
      { admin: tx-sender }
      { institution-id: institution-id }
    )
    (var-set next-institution-id (+ institution-id u1))
    (ok institution-id)
  )
)

(define-public (set-institution-admin (institution-id uint) (new-admin principal))
  (let ((institution (unwrap! (map-get? institutions { institution-id: institution-id }) ERR_INSTITUTION_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get admin institution)) ERR_NOT_AUTHORIZED)
    (map-delete institution-admins { admin: (get admin institution) })
    (map-set institutions
      { institution-id: institution-id }
      (merge institution { admin: new-admin })
    )
    (map-set institution-admins
      { admin: new-admin }
      { institution-id: institution-id }
    )
    (ok true)
  )
)

(define-public (verify-institution (institution-id uint))
  (let ((institution (unwrap! (map-get? institutions { institution-id: institution-id }) ERR_INSTITUTION_NOT_FOUND)))
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (map-set institutions
      { institution-id: institution-id }
      (merge institution { verified: true })
    )
    (ok true)
  )
)

(define-public (publish-result 
  (student-wallet principal)
  (exam-name (string-ascii 100))
  (subject (string-ascii 50))
  (grade (string-ascii 10))
  (score uint)
  (max-score uint)
  (exam-date uint)
)
  (let (
    (admin-info (unwrap! (map-get? institution-admins { admin: tx-sender }) ERR_NOT_AUTHORIZED))
    (institution-id (get institution-id admin-info))
    (institution (unwrap! (map-get? institutions { institution-id: institution-id }) ERR_INSTITUTION_NOT_FOUND))
    (result-id (var-get next-result-id))
    (current-results (default-to { result-ids: (list) } (map-get? student-results { student: student-wallet, institution-id: institution-id })))
  )
    (asserts! (get verified institution) ERR_INVALID_INSTITUTION)
    (asserts! (<= score max-score) ERR_INVALID_GRADE)
    (map-set exam-results
      { result-id: result-id }
      {
        student-wallet: student-wallet,
        institution-id: institution-id,
        exam-name: exam-name,
        subject: subject,
        grade: grade,
        score: score,
        max-score: max-score,
        exam-date: exam-date,
        issued-at: stacks-block-height,
        verified: true
      }
    )
    (map-set student-results
      { student: student-wallet, institution-id: institution-id }
      { result-ids: (unwrap! (as-max-len? (append (get result-ids current-results) result-id) u50) ERR_ALREADY_EXISTS) }
    )
    (var-set next-result-id (+ result-id u1))
    (ok result-id)
  )
)

(define-public (update-result 
  (result-id uint)
  (grade (string-ascii 10))
  (score uint)
)
  (let (
    (result (unwrap! (map-get? exam-results { result-id: result-id }) ERR_RESULT_NOT_FOUND))
    (admin-info (unwrap! (map-get? institution-admins { admin: tx-sender }) ERR_NOT_AUTHORIZED))
    (institution-id (get institution-id admin-info))
  )
    (asserts! (is-eq (get institution-id result) institution-id) ERR_NOT_AUTHORIZED)
    (asserts! (<= score (get max-score result)) ERR_INVALID_GRADE)
    (map-set exam-results
      { result-id: result-id }
      (merge result { grade: grade, score: score })
    )
    (ok true)
  )
)

(define-public (revoke-result (result-id uint))
  (let (
    (result (unwrap! (map-get? exam-results { result-id: result-id }) ERR_RESULT_NOT_FOUND))
    (admin-info (unwrap! (map-get? institution-admins { admin: tx-sender }) ERR_NOT_AUTHORIZED))
    (institution-id (get institution-id admin-info))
  )
    (asserts! (is-eq (get institution-id result) institution-id) ERR_NOT_AUTHORIZED)
    (map-set exam-results
      { result-id: result-id }
      (merge result { verified: false })
    )
    (ok true)
  )
)

(define-read-only (get-student-result-count (student principal) (institution-id uint))
  (match (map-get? student-results { student: student, institution-id: institution-id })
    results (len (get result-ids results))
    u0
  )
)

(define-read-only (get-next-institution-id)
  (var-get next-institution-id)
)

(define-read-only (get-next-result-id)
  (var-get next-result-id)
)
