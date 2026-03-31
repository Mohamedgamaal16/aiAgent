CREATE TABLE IF NOT EXISTS client (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    sector VARCHAR(255),
    contact_email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    credit_limit DECIMAL(12,2) NOT NULL
);


CREATE TABLE IF NOT EXISTS invoice (
    id SERIAL PRIMARY KEY,
    client_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    issue_date TIMESTAMP NOT NULL,
    due_date TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL,
    dpd INT DEFAULT 0,

    CONSTRAINT fk_invoice_client
        FOREIGN KEY (client_id)
        REFERENCES client(id)
        ON DELETE CASCADE
);


CREATE TABLE IF NOT EXISTS payment (
    id SERIAL PRIMARY KEY,
    invoice_id INT NOT NULL,
    amount_paid DECIMAL(12,2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    method VARCHAR(50),

    CONSTRAINT fk_payment_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES invoice(id)
        ON DELETE CASCADE
);


CREATE TABLE IF NOT EXISTS interaction (
    id SERIAL PRIMARY KEY,
    invoice_id INT NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    channel VARCHAR(50),
    agent_id INT,
    notes TEXT,
    delay_reason TEXT,

    CONSTRAINT fk_interaction_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES invoice(id)
        ON DELETE CASCADE
);


CREATE TABLE IF NOT EXISTS escalation (
    id SERIAL PRIMARY KEY,
    invoice_id INT NOT NULL,
    stage VARCHAR(50),
    triggered_at TIMESTAMP,
    resolved_at TIMESTAMP,
    outcome TEXT,

    CONSTRAINT fk_escalation_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES invoice(id)
        ON DELETE CASCADE
);



-- invoice lookups
CREATE INDEX idx_invoice_client_id
ON invoice(client_id);

CREATE INDEX idx_invoice_due_date
ON invoice(due_date);

CREATE INDEX idx_invoice_status
ON invoice(status);

-- payments
CREATE INDEX idx_payment_invoice
ON payment(invoice_id);

-- interactions
CREATE INDEX idx_interaction_invoice
ON interaction(invoice_id);

-- escalations
CREATE INDEX idx_escalation_invoice
ON escalation(invoice_id);


-- =========================================================
-- Dummy seed data (idempotent)
-- =========================================================

-- clients
INSERT INTO client (id, name, sector, contact_email, phone, credit_limit) VALUES
  (1, 'Nile Retail Group', 'Retail', 'finance@nileretail.com', '+20-10-1111-1111', 150000.00),
  (2, 'Delta Manufacturing', 'Manufacturing', 'ap@deltamfg.com', '+20-10-2222-2222', 300000.00),
  (3, 'Cairo Tech Solutions', 'Technology', 'billing@cairotech.io', '+20-10-3333-3333', 200000.00),
  (4, 'Red Sea Logistics', 'Logistics', 'accounts@redsealogistics.com', '+20-10-4444-4444', 250000.00),
  (5, 'Giza Healthcare', 'Healthcare', 'payables@gizahealth.org', '+20-10-5555-5555', 180000.00)
ON CONFLICT (id) DO NOTHING;

-- invoices
INSERT INTO invoice (id, client_id, amount, issue_date, due_date, status, dpd) VALUES
  (1, 1, 42000.00, '2026-01-05 09:00:00', '2026-02-04 23:59:59', 'paid', 0),
  (2, 1, 18500.00, '2026-02-10 10:30:00', '2026-03-12 23:59:59', 'overdue', 18),
  (3, 2, 76000.00, '2026-01-15 11:15:00', '2026-02-14 23:59:59', 'partial', 9),
  (4, 3, 120000.00, '2026-02-01 08:45:00', '2026-03-03 23:59:59', 'open', 0),
  (5, 4, 54000.00, '2026-01-20 14:00:00', '2026-02-19 23:59:59', 'overdue', 25),
  (6, 5, 33000.00, '2026-02-18 16:20:00', '2026-03-20 23:59:59', 'paid', 0),
  (7, 2, 91000.00, '2026-02-25 12:00:00', '2026-03-27 23:59:59', 'open', 0),
  (8, 3, 27500.00, '2026-03-01 09:30:00', '2026-03-31 23:59:59', 'partial', 3)
ON CONFLICT (id) DO NOTHING;

-- payments
INSERT INTO payment (id, invoice_id, amount_paid, payment_date, method) VALUES
  (1, 1, 42000.00, '2026-02-02 12:10:00', 'bank_transfer'),
  (2, 3, 30000.00, '2026-02-20 10:05:00', 'bank_transfer'),
  (3, 3, 15000.00, '2026-02-28 15:40:00', 'cheque'),
  (4, 6, 33000.00, '2026-03-15 13:20:00', 'cash'),
  (5, 8, 10000.00, '2026-03-29 17:10:00', 'bank_transfer')
ON CONFLICT (id) DO NOTHING;

-- interactions
INSERT INTO interaction (id, invoice_id, date, channel, agent_id, notes, delay_reason) VALUES
  (1, 2, '2026-03-14 09:00:00', 'email', 101, 'Reminder sent to finance contact.', 'Awaiting internal approval'),
  (2, 2, '2026-03-18 11:30:00', 'phone', 102, 'Client promised payment next week.', 'Cash flow issue'),
  (3, 5, '2026-03-01 10:45:00', 'email', 103, 'Second reminder with statement attached.', 'Dispute on shipment quantity'),
  (4, 5, '2026-03-10 16:00:00', 'meeting', 104, 'Resolution meeting completed.', 'Pending management signoff'),
  (5, 8, '2026-03-30 09:20:00', 'whatsapp', 101, 'Partial payment acknowledged.', 'Client requested extension')
ON CONFLICT (id) DO NOTHING;

-- escalations
INSERT INTO escalation (id, invoice_id, stage, triggered_at, resolved_at, outcome) VALUES
  (1, 5, 'legal_notice', '2026-03-12 08:00:00', NULL, 'Notice issued, awaiting response'),
  (2, 2, 'manager_review', '2026-03-20 09:30:00', NULL, 'Account manager assigned'),
  (3, 3, 'credit_hold_warning', '2026-03-05 13:00:00', '2026-03-12 10:00:00', 'Credit hold avoided after partial settlement')
ON CONFLICT (id) DO NOTHING;

-- keep sequences aligned after explicit ids
SELECT setval('client_id_seq', COALESCE((SELECT MAX(id) FROM client), 1), true);
SELECT setval('invoice_id_seq', COALESCE((SELECT MAX(id) FROM invoice), 1), true);
SELECT setval('payment_id_seq', COALESCE((SELECT MAX(id) FROM payment), 1), true);
SELECT setval('interaction_id_seq', COALESCE((SELECT MAX(id) FROM interaction), 1), true);
SELECT setval('escalation_id_seq', COALESCE((SELECT MAX(id) FROM escalation), 1), true);