BEGIN;

INSERT INTO institutions (name, website)
VALUES ('Universidade Exemplo', 'https://example.com')
ON CONFLICT (name) DO NOTHING;

INSERT INTO locations (city, state, country)
VALUES ('São Paulo', 'SP', 'Brasil')
ON CONFLICT (city, state, country) DO NOTHING;

INSERT INTO specialties (name)
VALUES ('Economia'), ('Mercado financeiro')
ON CONFLICT (name) DO NOTHING;

INSERT INTO topics (name)
VALUES ('Inflação'), ('Juros'), ('Política monetária')
ON CONFLICT (name) DO NOTHING;

INSERT INTO sources (
  slug,
  name,
  professional_title,
  bio,
  institution_id,
  location_id,
  verified
)
SELECT
  'mariana-silva',
  'Mariana Silva',
  'Economista',
  'Economista com atuação em inflação, juros e mercado financeiro.',
  i.id,
  l.id,
  TRUE
FROM institutions i
JOIN locations l
  ON l.city = 'São Paulo'
 AND l.state = 'SP'
WHERE i.name = 'Universidade Exemplo'
ON CONFLICT (slug) DO NOTHING;

INSERT INTO source_specialties (source_id, specialty_id)
SELECT s.id, sp.id
FROM sources s
JOIN specialties sp ON sp.name IN ('Economia', 'Mercado financeiro')
WHERE s.slug = 'mariana-silva'
ON CONFLICT DO NOTHING;

INSERT INTO source_topics (source_id, topic_id)
SELECT s.id, t.id
FROM sources s
JOIN topics t ON t.name IN ('Inflação', 'Juros', 'Política monetária')
WHERE s.slug = 'mariana-silva'
ON CONFLICT DO NOTHING;

INSERT INTO source_interview_formats (source_id, format_id)
SELECT s.id, f.id
FROM sources s
JOIN interview_formats f ON f.name IN ('TV ao vivo', 'TV gravada', 'Rádio', 'Podcast')
WHERE s.slug = 'mariana-silva'
ON CONFLICT DO NOTHING;

INSERT INTO source_languages (source_id, language_id)
SELECT s.id, l.id
FROM sources s
JOIN languages l ON l.name IN ('Português', 'Inglês')
WHERE s.slug = 'mariana-silva'
ON CONFLICT DO NOTHING;

INSERT INTO source_availability (
  source_id,
  remote,
  in_person,
  live,
  is_available
)
SELECT id, TRUE, TRUE, TRUE, TRUE
FROM sources
WHERE slug = 'mariana-silva'
ON CONFLICT (source_id) DO UPDATE SET
  remote = EXCLUDED.remote,
  in_person = EXCLUDED.in_person,
  live = EXCLUDED.live,
  is_available = EXCLUDED.is_available;

INSERT INTO contacts (source_id, type, value, label, is_primary)
SELECT id, 'email', 'mariana@exemplo.com', 'Contato profissional', TRUE
FROM sources
WHERE slug = 'mariana-silva'
AND NOT EXISTS (
  SELECT 1
  FROM contacts c
  WHERE c.source_id = sources.id
    AND c.type = 'email'
    AND c.value = 'mariana@exemplo.com'
);

INSERT INTO media_experiences (
  source_id,
  outlet,
  program,
  role,
  interview_url,
  occurred_at
)
SELECT
  id,
  'TV Exemplo',
  'Jornal Exemplo',
  'Entrevistada',
  'https://example.com/entrevista',
  CURRENT_DATE
FROM sources
WHERE slug = 'mariana-silva'
AND NOT EXISTS (
  SELECT 1
  FROM media_experiences me
  WHERE me.source_id = sources.id
    AND me.outlet = 'TV Exemplo'
    AND me.program = 'Jornal Exemplo'
);

COMMIT;
