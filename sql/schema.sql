BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS institutions (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(180) NOT NULL UNIQUE,
  website TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS locations (
  id BIGSERIAL PRIMARY KEY,
  city VARCHAR(120) NOT NULL,
  state VARCHAR(80),
  country VARCHAR(80) NOT NULL DEFAULT 'Brasil',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (city, state, country)
);

CREATE TABLE IF NOT EXISTS sources (
  id BIGSERIAL PRIMARY KEY,
  slug VARCHAR(180) NOT NULL UNIQUE,
  name VARCHAR(180) NOT NULL,
  professional_title VARCHAR(180) NOT NULL,
  bio TEXT,
  photo_url TEXT,
  institution_id BIGINT REFERENCES institutions(id) ON DELETE SET NULL,
  location_id BIGINT REFERENCES locations(id) ON DELETE SET NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS specialties (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(160) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS topics (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(160) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS source_specialties (
  source_id BIGINT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
  specialty_id BIGINT NOT NULL REFERENCES specialties(id) ON DELETE CASCADE,
  PRIMARY KEY (source_id, specialty_id)
);

CREATE TABLE IF NOT EXISTS source_topics (
  source_id BIGINT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
  topic_id BIGINT NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  PRIMARY KEY (source_id, topic_id)
);

CREATE TABLE IF NOT EXISTS interview_formats (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS source_interview_formats (
  source_id BIGINT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
  format_id BIGINT NOT NULL REFERENCES interview_formats(id) ON DELETE CASCADE,
  PRIMARY KEY (source_id, format_id)
);

CREATE TABLE IF NOT EXISTS languages (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  code VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS source_languages (
  source_id BIGINT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
  language_id BIGINT NOT NULL REFERENCES languages(id) ON DELETE CASCADE,
  PRIMARY KEY (source_id, language_id)
);

CREATE TABLE IF NOT EXISTS source_availability (
  id BIGSERIAL PRIMARY KEY,
  source_id BIGINT NOT NULL UNIQUE REFERENCES sources(id) ON DELETE CASCADE,
  remote BOOLEAN NOT NULL DEFAULT TRUE,
  in_person BOOLEAN NOT NULL DEFAULT FALSE,
  live BOOLEAN NOT NULL DEFAULT FALSE,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  notes TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS contacts (
  id BIGSERIAL PRIMARY KEY,
  source_id BIGINT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL CHECK (
    type IN ('email', 'phone', 'whatsapp', 'press_office', 'website', 'linkedin', 'instagram', 'other')
  ),
  value TEXT NOT NULL,
  label VARCHAR(100),
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS media_experiences (
  id BIGSERIAL PRIMARY KEY,
  source_id BIGINT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
  outlet VARCHAR(180) NOT NULL,
  program VARCHAR(180),
  role VARCHAR(120),
  interview_url TEXT,
  occurred_at DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS videos (
  id BIGSERIAL PRIMARY KEY,
  source_id BIGINT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
  title VARCHAR(220),
  url TEXT NOT NULL,
  platform VARCHAR(80),
  published_at DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sources_name_trgm
  ON sources USING GIN (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_sources_title_trgm
  ON sources USING GIN (professional_title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_sources_bio_trgm
  ON sources USING GIN (bio gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_specialties_name_trgm
  ON specialties USING GIN (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_topics_name_trgm
  ON topics USING GIN (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_locations_city_trgm
  ON locations USING GIN (city gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_sources_institution_id
  ON sources (institution_id);

CREATE INDEX IF NOT EXISTS idx_sources_location_id
  ON sources (location_id);

CREATE INDEX IF NOT EXISTS idx_contacts_source_id
  ON contacts (source_id);

CREATE INDEX IF NOT EXISTS idx_media_experiences_source_id
  ON media_experiences (source_id);

CREATE INDEX IF NOT EXISTS idx_videos_source_id
  ON videos (source_id);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sources_updated_at ON sources;
CREATE TRIGGER trg_sources_updated_at
BEFORE UPDATE ON sources
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_source_availability_updated_at ON source_availability;
CREATE TRIGGER trg_source_availability_updated_at
BEFORE UPDATE ON source_availability
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

INSERT INTO interview_formats (name)
VALUES
  ('TV ao vivo'),
  ('TV gravada'),
  ('Rádio'),
  ('Podcast'),
  ('Entrevista por telefone'),
  ('Reportagem escrita')
ON CONFLICT (name) DO NOTHING;

INSERT INTO languages (name, code)
VALUES
  ('Português', 'pt-BR'),
  ('Inglês', 'en'),
  ('Espanhol', 'es')
ON CONFLICT (name) DO NOTHING;

COMMIT;
