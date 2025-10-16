(define-constant ERR_NOT_AUTHORIZED (err u200))
(define-constant ERR_CERTIFICATE_NOT_FOUND (err u201))
(define-constant ERR_INVALID_RESULT (err u202))
(define-constant ERR_ALREADY_ISSUED (err u203))
(define-constant ERR_INVALID_GRADE_THRESHOLD (err u204))

(define-map certificates
  { certificate-id: uint }
  {
    student: principal,
    institution-id: uint,
    result-id: uint,
    certificate-type: (string-ascii 50),
    title: (string-ascii 100),
    achievement-level: (string-ascii 20),
    issued-at: uint,
    valid: bool
  }
)

(define-map student-certificates
  { student: principal }
  { certificate-ids: (list 100 uint) }
)

(define-map badges
  { badge-id: uint }
  {
    student: principal,
    badge-type: (string-ascii 30),
    description: (string-ascii 100),
    criteria-met: (string-ascii 100),
    earned-at: uint
  }
)

(define-map student-badges
  { student: principal }
  { badge-ids: (list 50 uint) }
)

(define-data-var next-certificate-id uint u1)
(define-data-var next-badge-id uint u1)

(define-read-only (get-certificate (certificate-id uint))
  (map-get? certificates { certificate-id: certificate-id })
)

(define-read-only (get-student-certificates (student principal))
  (map-get? student-certificates { student: student })
)

(define-read-only (get-student-badges (student principal))
  (map-get? student-badges { student: student })
)

(define-read-only (get-badge (badge-id uint))
  (map-get? badges { badge-id: badge-id })
)

(define-public (issue-certificate 
  (student principal)
  (result-id uint)
  (certificate-type (string-ascii 50))
  (title (string-ascii 100))
)
  (let (
    (certificate-id (var-get next-certificate-id))
    (current-certs (default-to { certificate-ids: (list) } (map-get? student-certificates { student: student })))
  )
    (map-set certificates
      { certificate-id: certificate-id }
      {
        student: student,
        institution-id: u1,
        result-id: result-id,
        certificate-type: certificate-type,
        title: title,
        achievement-level: "Certified",
        issued-at: stacks-block-height,
        valid: true
      }
    )
    (map-set student-certificates
      { student: student }
      { certificate-ids: (unwrap! (as-max-len? (append (get certificate-ids current-certs) certificate-id) u100) ERR_ALREADY_ISSUED) }
    )
    (var-set next-certificate-id (+ certificate-id u1))
    (ok certificate-id)
  )
)

(define-public (award-badge 
  (student principal)
  (badge-type (string-ascii 30))
  (description (string-ascii 100))
  (criteria (string-ascii 100))
)
  (let (
    (badge-id (var-get next-badge-id))
    (current-badges (default-to { badge-ids: (list) } (map-get? student-badges { student: student })))
  )
    (map-set badges
      { badge-id: badge-id }
      {
        student: student,
        badge-type: badge-type,
        description: description,
        criteria-met: criteria,
        earned-at: stacks-block-height
      }
    )
    (map-set student-badges
      { student: student }
      { badge-ids: (unwrap! (as-max-len? (append (get badge-ids current-badges) badge-id) u50) ERR_ALREADY_ISSUED) }
    )
    (var-set next-badge-id (+ badge-id u1))
    (ok badge-id)
  )
)

(define-public (revoke-certificate (certificate-id uint))
  (let ((certificate (unwrap! (map-get? certificates { certificate-id: certificate-id }) ERR_CERTIFICATE_NOT_FOUND)))
    (map-set certificates
      { certificate-id: certificate-id }
      (merge certificate { valid: false })
    )
    (ok true)
  )
)

(define-read-only (verify-certificate (certificate-id uint))
  (match (map-get? certificates { certificate-id: certificate-id })
    certificate
    (ok {
      student: (get student certificate),
      title: (get title certificate),
      type: (get certificate-type certificate),
      level: (get achievement-level certificate),
      valid: (get valid certificate),
      issued: (get issued-at certificate)
    })
    ERR_CERTIFICATE_NOT_FOUND
  )
)

(define-read-only (get-student-portfolio (student principal))
  (let (
    (certs (default-to { certificate-ids: (list) } (map-get? student-certificates { student: student })))
    (badges-data (default-to { badge-ids: (list) } (map-get? student-badges { student: student })))
  )
    (ok {
      certificates: (len (get certificate-ids certs)),
      badges: (len (get badge-ids badges-data)),
      portfolio-score: (+ (* (len (get certificate-ids certs)) u10) (* (len (get badge-ids badges-data)) u5))
    })
  )
) 
 