import { Router } from "express";
import { query } from "../db.js";

const router = Router();

router.get("/", async (req, res) => {
  try {
    const {
      q,
      city,
      state,
      specialty,
      topic,
      format,
      remote,
      inPerson,
      live,
      available
    } = req.query;

    const conditions = ["s.active = TRUE"];
    const values = [];
    let index = 1;

    function addCondition(sql, value) {
      conditions.push(sql.replace("?", `$${index}`));
      values.push(value);
      index += 1;
    }

    if (q) {
      addCondition(`
        (
          s.name ILIKE '%' || ? || '%'
          OR s.professional_title ILIKE '%' || ? || '%'
          OR COALESCE(s.bio, '') ILIKE '%' || ? || '%'
          OR COALESCE(i.name, '') ILIKE '%' || ? || '%'
          OR COALESCE(l.city, '') ILIKE '%' || ? || '%'
          OR COALESCE(sp.name, '') ILIKE '%' || ? || '%'
          OR COALESCE(t.name, '') ILIKE '%' || ? || '%'
        )
      `, q);

      /*
       * O bloco acima usa o mesmo placeholder várias vezes.
       * Ajustamos isso abaixo expandindo a condição para placeholders próprios.
       */
      conditions.pop();
      values.pop();
      index -= 1;

      const qPlaceholders = [];
      for (let n = 0; n < 7; n += 1) {
        qPlaceholders.push(`$${index}`);
        values.push(q);
        index += 1;
      }

      conditions.push(`
        (
          s.name ILIKE '%' || ${qPlaceholders[0]} || '%'
          OR s.professional_title ILIKE '%' || ${qPlaceholders[1]} || '%'
          OR COALESCE(s.bio, '') ILIKE '%' || ${qPlaceholders[2]} || '%'
          OR COALESCE(i.name, '') ILIKE '%' || ${qPlaceholders[3]} || '%'
          OR COALESCE(l.city, '') ILIKE '%' || ${qPlaceholders[4]} || '%'
          OR COALESCE(sp.name, '') ILIKE '%' || ${qPlaceholders[5]} || '%'
          OR COALESCE(t.name, '') ILIKE '%' || ${qPlaceholders[6]} || '%'
        )
      `);
    }

    if (city) addCondition("l.city ILIKE '%' || ? || '%'", city);
    if (state) addCondition("l.state = ?", state.toUpperCase());
    if (specialty) addCondition("sp.name ILIKE '%' || ? || '%'", specialty);
    if (topic) addCondition("t.name ILIKE '%' || ? || '%'", topic);
    if (format) addCondition("f.name ILIKE '%' || ? || '%'", format);

    if (remote === "true") conditions.push("a.remote = TRUE");
    if (inPerson === "true") conditions.push("a.in_person = TRUE");
    if (live === "true") conditions.push("a.live = TRUE");
    if (available === "true") conditions.push("a.is_available = TRUE");

    const sql = `
      SELECT DISTINCT
        s.id,
        s.slug,
        s.name,
        s.professional_title,
        s.bio,
        s.photo_url,
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
      LEFT JOIN source_specialties ss ON ss.source_id = s.id
      LEFT JOIN specialties sp ON sp.id = ss.specialty_id
      LEFT JOIN source_topics st ON st.source_id = s.id
      LEFT JOIN topics t ON t.id = st.topic_id
      LEFT JOIN source_interview_formats sif ON sif.source_id = s.id
      LEFT JOIN interview_formats f ON f.id = sif.format_id
      WHERE ${conditions.join(" AND ")}
      ORDER BY s.name ASC
      LIMIT 100
    `;

    const result = await query(sql, values);

    res.json({
      count: result.rowCount,
      filters: {
        q: q || null,
        city: city || null,
        state: state || null,
        specialty: specialty || null,
        topic: topic || null,
        format: format || null,
        remote: remote || null,
        inPerson: inPerson || null,
        live: live || null,
        available: available || null
      },
      results: result.rows
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Erro ao pesquisar fontes" });
  }
});

export default router;
