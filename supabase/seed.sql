-- ============================================================
-- PienoAmico — Seed Data per sviluppo e test locale
-- Distributori di esempio nelle principali città italiane
-- ============================================================

INSERT INTO distributori (id, gestore, bandiera, tipo_impianto, nome, indirizzo, comune, provincia, posizione)
VALUES
  -- Milano
  (1001, 'ENI S.P.A.',          'Agip Eni',  'stradale',    'Eni Loreto',         'Viale Monza 1',           'Milano', 'MI', ST_MakePoint(9.2200, 45.4820)::GEOGRAPHY),
  (1002, 'Q8 ITALIA S.P.A.',    'Q8',        'stradale',    'Q8 Centrale',        'Corso Buenos Aires 50',   'Milano', 'MI', ST_MakePoint(9.2050, 45.4750)::GEOGRAPHY),
  (1003, 'IP ITALIANA S.P.A.',  'IP',        'stradale',    'IP Navigli',         'Viale Gorizia 12',        'Milano', 'MI', ST_MakePoint(9.1710, 45.4490)::GEOGRAPHY),
  (1004, 'TAMOIL ITALIA S.P.A.','Tamoil',    'stradale',    'Tamoil Linate',      'Via Forlanini 85',        'Milano', 'MI', ST_MakePoint(9.2760, 45.4490)::GEOGRAPHY),
  (1005, 'AUTOGRILL S.P.A.',    'Agip Eni',  'autostradale','Area Sosta A1 Nord', 'A1 Milano-Bologna km 10', 'Lodi',   'LO', ST_MakePoint(9.4950, 45.3100)::GEOGRAPHY),
  -- Roma
  (2001, 'ENI S.P.A.',          'Agip Eni',  'stradale',    'Eni Prati',          'Via Cola di Rienzo 40',   'Roma',   'RM', ST_MakePoint(12.4620, 41.9040)::GEOGRAPHY),
  (2002, 'TOTAL ITALIA S.P.A.', 'TotalEnergies','stradale', 'Total Termini',      'Via Marsala 20',          'Roma',   'RM', ST_MakePoint(12.5010, 41.9010)::GEOGRAPHY),
  (2003, 'Q8 ITALIA S.P.A.',    'Q8',        'stradale',    'Q8 EUR',             'Viale Europa 190',        'Roma',   'RM', ST_MakePoint(12.4710, 41.8300)::GEOGRAPHY),
  -- Napoli
  (3001, 'ENI S.P.A.',          'Agip Eni',  'stradale',    'Eni Chiaia',         'Via Caracciolo 10',       'Napoli', 'NA', ST_MakePoint(14.2310, 40.8320)::GEOGRAPHY),
  (3002, 'IP ITALIANA S.P.A.',  'IP',        'stradale',    'IP Vomero',          'Via Scarlatti 80',        'Napoli', 'NA', ST_MakePoint(14.2340, 40.8500)::GEOGRAPHY);

INSERT INTO prezzi_correnti (id_impianto, carburante, is_self, prezzo, dt_comunicazione)
VALUES
  -- Milano Eni Loreto
  (1001, 'benzina', true,  1.659, now() - INTERVAL '3 hours'),
  (1001, 'benzina', false, 1.759, now() - INTERVAL '3 hours'),
  (1001, 'gasolio', true,  1.549, now() - INTERVAL '3 hours'),
  (1001, 'gasolio', false, 1.649, now() - INTERVAL '3 hours'),
  -- Milano Q8
  (1002, 'benzina', true,  1.669, now() - INTERVAL '5 hours'),
  (1002, 'benzina', false, 1.769, now() - INTERVAL '5 hours'),
  (1002, 'gasolio', true,  1.559, now() - INTERVAL '5 hours'),
  (1002, 'gpl',     true,  0.769, now() - INTERVAL '5 hours'),
  -- Milano IP Navigli
  (1003, 'benzina', true,  1.649, now() - INTERVAL '1 hours'),
  (1003, 'benzina', false, 1.749, now() - INTERVAL '1 hours'),
  (1003, 'gasolio', true,  1.539, now() - INTERVAL '1 hours'),
  (1003, 'metano',  true,  1.349, now() - INTERVAL '1 hours'),
  -- Milano Tamoil
  (1004, 'benzina', true,  1.679, now() - INTERVAL '8 hours'),
  (1004, 'gasolio', true,  1.569, now() - INTERVAL '8 hours'),
  -- Autostrada (prezzo tipicamente più alto)
  (1005, 'benzina', false, 1.899, now() - INTERVAL '2 hours'),
  (1005, 'gasolio', false, 1.789, now() - INTERVAL '2 hours'),
  -- Roma
  (2001, 'benzina', true,  1.649, now() - INTERVAL '4 hours'),
  (2001, 'gasolio', true,  1.539, now() - INTERVAL '4 hours'),
  (2002, 'benzina', true,  1.639, now() - INTERVAL '6 hours'),
  (2002, 'gasolio', true,  1.529, now() - INTERVAL '6 hours'),
  (2003, 'benzina', true,  1.669, now() - INTERVAL '2 hours'),
  (2003, 'gasolio', true,  1.559, now() - INTERVAL '2 hours'),
  (2003, 'gpl',     true,  0.779, now() - INTERVAL '2 hours'),
  -- Napoli
  (3001, 'benzina', true,  1.679, now() - INTERVAL '7 hours'),
  (3001, 'gasolio', true,  1.569, now() - INTERVAL '7 hours'),
  (3002, 'benzina', true,  1.689, now() - INTERVAL '3 hours'),
  (3002, 'gasolio', true,  1.579, now() - INTERVAL '3 hours'),
  (3002, 'metano',  true,  1.359, now() - INTERVAL '3 hours');
