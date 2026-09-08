import { Router } from "express";
import { query } from "../db.js";

const router = Router();

router.get("/", async (req, res) => {
  try {
    const result = await query(`
      SELECT
        s.id,
        s.slug,
        s.name,
        s.professional_title,
        s.bio,
        s.photo_url,
        s.active,
        i.name AS institution,
        l.city,
        l.state,
        l.country,
        a.remote,
        a.in_person,
        a.live,
        a.is_available
      FROM sources s
      LEFT JOIN institutions i ON i.id = s.institution_id
      LEFT JOIN locations l ON l.id = s.location_id
      LEFT JOIN source_availability a ON a.source_id = s.id
      WHERE s.active = TRUE
      ORDER BY s.name ASC
    `);

    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erro ao listar fontes" });
  }
});

router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const sourceResult = await query(`
      SELECT
        s.*,
        i.name AS institution,
        i.website AS institution_website,
        l.city,
        l.state,
        l.country,
        a.remote,
        a.in_person,
        a.live,
        a.is_available,
        a.notes AS availability_notes
      FROM sources s
      LEFT JOIN institutions i ON i.id = s.institution_id
      LEFT JOIN locations l ON l.id = s.location_id
      LEFT JOIN source_availability a ON a.source_id = s.id
      WHERE s.id = $1
    `, [id]);

    if (sourceResult.rowCount === 0) {
      return res.status(404).json({ error: "Fonte não encontrada" });
    }

    const specialties = await query(`
      SELECT sp.id, sp.name
      FROM specialties sp
      INNER JOIN source_specialties ss ON ss.specialty_id = sp.id
      WHERE ss.source_id = $1
      ORDER BY sp.name
    `, [id]);

    const topics = await query(`
      SELECT t.id, t.name
      FROM topics t
      INNER JOIN source_topics st ON st.topic_id = t.id
      WHERE st.source_id = $1
      ORDER BY t.name
    `, [id]);

    const formats = await query(`
      SELECT f.id, f.name
      FROM interview_formats f
      INNER JOIN source_interview_formats sf ON sf.format_id = f.id
      WHERE sf.source_id = $1
      ORDER BY f.name
    `, [id]);

    const languages = await query(`
      SELECT l.id, l.name, l.code
      FROM languages l
      INNER JOIN source_languages sl ON sl.language_id = l.id
      WHERE sl.source_id = $1
      ORDER BY l.name
    `, [id]);

    const mediaExperiences = await query(`
      SELECT id, outlet, program, role, interview_url, occurred_at
      FROM media_experiences
      WHERE source_id = $1
      ORDER BY occurred_at DESC NULLS LAST, id DESC
    `, [id]);

    const contacts = await query(`
      SELECT id, type, value, label, is_primary
      FROM contacts
      WHERE source_id = $1
      ORDER BY is_primary DESC, id
    `, [id]);

    const videos = await query(`
      SELECT id, title, url, platform, published_at
      FROM videos
      WHERE source_id = $1
      ORDER BY published_at DESC NULLS LAST, id DESC
    `, [id]);

    res.json({
      ...sourceResult.rows[0],
      specialties: specialties.rows,
      topics: topics.rows,
      interviewFormats: formats.rows,
      languages: languages.rows,
      mediaExperiences: mediaExperiences.rows,
      contacts: contacts.rows,
      videos: videos.rows
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erro ao carregar fonte" });
  }
});

router.post("/", async (req, res) => {
  try {
    const {
      slug,
      name,
      professionalTitle,
      bio,
      photoUrl = null,
      institutionId = null,
      locationId = null
    } = req.body;

    if (!slug || !name || !professionalTitle) {
      return res.status(400).json({
        error: "slug, name e professionalTitle são obrigatórios"
      });
    }

    const result = await query(`
      INSERT INTO sources (
        slug,
        name,
        professional_title,
        bio,
        photo_url,
        institution_id,
        location_id
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [
      slug,
      name,
      professionalTitle,
      bio || null,
      photoUrl,
      institutionId,
      locationId
    ]);

    await query(`
      INSERT INTO source_availability (source_id)
      VALUES ($1)
      ON CONFLICT (source_id) DO NOTHING
    `, [result.rows[0].id]);

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error(error);

    if (error.code === "23505") {
      return res.status(409).json({ error: "Slug já cadastrado" });
    }

    res.status(500).json({ error: "Erro ao cadastrar fonte" });
  }
});

export default router;
