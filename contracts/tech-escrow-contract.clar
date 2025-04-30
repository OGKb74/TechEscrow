;; TechEscrow - A secure escrow service for IT freelancers and clients
;; This contract allows clients to create milestone-based projects and release funds
;; as freelancers complete each milestone.

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROJECT-EXISTS (err u101))
(define-constant ERR-PROJECT-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-MILESTONE-NOT-FOUND (err u104))
(define-constant ERR-MILESTONE-ALREADY-PAID (err u105))
(define-constant ERR-DISPUTE-EXISTS (err u106))
(define-constant ERR-NO-DISPUTE (err u107))
(define-constant ERR-TRANSFER-FAILED (err u108))

;; Data structures
(define-map projects
  { project-id: (string-ascii 36) }
  {
    client: principal,
    freelancer: principal,
    total-amount: uint,
    remaining-amount: uint,
    milestone-count: uint,
    completed-milestones: uint,
    in-dispute: bool
  }
)

(define-map milestones
  { project-id: (string-ascii 36), milestone-id: uint }
  {
    description: (string-utf8 256),
    amount: uint,
    completed: bool,
    paid: bool
  }
)

(define-map disputes
  { project-id: (string-ascii 36) }
  {
    reason: (string-utf8 256),
    client-approved: bool,
    freelancer-approved: bool,
    arbiter: (optional principal)
  }
)

;; Read-only functions

;; Get project details
(define-read-only (get-project (project-id (string-ascii 36)))
  (map-get? projects { project-id: project-id })
)

;; Get milestone details
(define-read-only (get-milestone (project-id (string-ascii 36)) (milestone-id uint))
  (map-get? milestones { project-id: project-id, milestone-id: milestone-id })
)

;; Get dispute details
(define-read-only (get-dispute (project-id (string-ascii 36)))
  (map-get? disputes { project-id: project-id })
)

;; Public functions

;; Create a new project with milestones
(define-public (create-project 
    (project-id (string-ascii 36)) 
    (freelancer principal) 
    (total-amount uint)
    (milestone-count uint))
  (let ((existing-project (get-project project-id)))
    (asserts! (is-none existing-project) ERR-PROJECT-EXISTS)
    (asserts! (>= (stx-get-balance tx-sender) total-amount) ERR-INSUFFICIENT-FUNDS)

    ;; Transfer STX to contract
    (try! (stx-transfer? total-amount tx-sender (as-contract tx-sender)))

    ;; Create project
    (map-set projects
      { project-id: project-id }
      {
        client: tx-sender,
        freelancer: freelancer,
        total-amount: total-amount,
        remaining-amount: total-amount,
        milestone-count: milestone-count,
        completed-milestones: u0,
        in-dispute: false
      }
    )

    (ok true)
  )
)

;; Add a milestone to a project
(define-public (add-milestone 
    (project-id (string-ascii 36)) 
    (milestone-id uint) 
    (description (string-utf8 256)) 
    (amount uint))
  (let ((project (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND)))
    ;; Check authorization
    (asserts! (is-eq tx-sender (get client project)) ERR-NOT-AUTHORIZED)
    ;; Check milestone ID is valid
    (asserts! (< milestone-id (get milestone-count project)) ERR-MILESTONE-NOT-FOUND)

    ;; Create milestone
    (map-set milestones
      { project-id: project-id, milestone-id: milestone-id }
      {
        description: description,
        amount: amount,
        completed: false,
        paid: false
      }
    )

    (ok true)
  )
)

;; Mark milestone as completed (by freelancer)
(define-public (complete-milestone (project-id (string-ascii 36)) (milestone-id uint))
  (let (
    (project (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND))
    (milestone (unwrap! (get-milestone project-id milestone-id) ERR-MILESTONE-NOT-FOUND))
  )
    ;; Check authorization
    (asserts! (is-eq tx-sender (get freelancer project)) ERR-NOT-AUTHORIZED)
    ;; Check milestone is not already completed
    (asserts! (not (get completed milestone)) ERR-MILESTONE-ALREADY-PAID)

    ;; Update milestone
    (map-set milestones
      { project-id: project-id, milestone-id: milestone-id }
      (merge milestone { completed: true })
    )

    (ok true)
  )
)

;; Approve and pay for a milestone (by client)
(define-public (approve-milestone (project-id (string-ascii 36)) (milestone-id uint))
  (let (
    (project (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND))
    (milestone (unwrap! (get-milestone project-id milestone-id) ERR-MILESTONE-NOT-FOUND))
  )
    ;; Check authorization
    (asserts! (is-eq tx-sender (get client project)) ERR-NOT-AUTHORIZED)
    ;; Check milestone is completed but not paid
    (asserts! (get completed milestone) ERR-MILESTONE-NOT-FOUND)
    (asserts! (not (get paid milestone)) ERR-MILESTONE-ALREADY-PAID)

    ;; Update milestone
    (map-set milestones
      { project-id: project-id, milestone-id: milestone-id }
      (merge milestone { paid: true })
    )

    ;; Update project
    (map-set projects
      { project-id: project-id }
      (merge project {
        remaining-amount: (- (get remaining-amount project) (get amount milestone)),
        completed-milestones: (+ (get completed-milestones project) u1)
      })
    )

    ;; Transfer payment to freelancer - FIX: Added try! to handle the response
    (try! (as-contract (stx-transfer? (get amount milestone) tx-sender (get freelancer project))))

    (ok true)
  )
)

;; Create a dispute (by client or freelancer)
(define-public (create-dispute (project-id (string-ascii 36)) (reason (string-utf8 256)))
  (let ((project (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND)))
    ;; Check authorization
    (asserts! (or 
      (is-eq tx-sender (get client project)) 
      (is-eq tx-sender (get freelancer project))
    ) ERR-NOT-AUTHORIZED)

    ;; Check no dispute exists
    (asserts! (is-none (get-dispute project-id)) ERR-DISPUTE-EXISTS)

    ;; Create dispute
    (map-set disputes
      { project-id: project-id }
      {
        reason: reason,
        client-approved: false,
        freelancer-approved: false,
        arbiter: none
      }
    )

    ;; Mark project as in dispute
    (map-set projects
      { project-id: project-id }
      (merge project { in-dispute: true })
    )

    (ok true)
  )
)

;; Resolve dispute (requires both parties to approve)
(define-public (approve-resolution (project-id (string-ascii 36)))
  (let (
    (project (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND))
    (dispute (unwrap! (get-dispute project-id) ERR-NO-DISPUTE))
  )
    ;; Check authorization
    (asserts! (or 
      (is-eq tx-sender (get client project)) 
      (is-eq tx-sender (get freelancer project))
    ) ERR-NOT-AUTHORIZED)

    ;; Update dispute approval based on who called
    (if (is-eq tx-sender (get client project))
      (map-set disputes
        { project-id: project-id }
        (merge dispute { client-approved: true })
      )
      (map-set disputes
        { project-id: project-id }
        (merge dispute { freelancer-approved: true })
      )
    )

    ;; Check if both approved
    (let ((updated-dispute (unwrap! (get-dispute project-id) ERR-NO-DISPUTE)))
      (if (and (get client-approved updated-dispute) (get freelancer-approved updated-dispute))
        (begin
          ;; Remove dispute
          (map-delete disputes { project-id: project-id })

          ;; Mark project as not in dispute
          (map-set projects
            { project-id: project-id }
            (merge project { in-dispute: false })
          )

          (ok true)
        )
        (ok false)
      )
    )
  )
)

;; Cancel project and refund remaining funds (only if both parties agree)
(define-public (cancel-project (project-id (string-ascii 36)))
  (let ((project (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND)))
    ;; Check authorization
    (asserts! (is-eq tx-sender (get client project)) ERR-NOT-AUTHORIZED)

    ;; Refund remaining amount to client - FIX: Added try! to handle the response
    (try! (as-contract (stx-transfer? (get remaining-amount project) tx-sender (get client project))))

    ;; Delete project
    (map-delete projects { project-id: project-id })

    (ok true)
  )
)