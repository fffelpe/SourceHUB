import "dotenv/config";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import { query } from "./db.js";
import sourcesRouter from "./routes/sources.js";
import searchRouter from "./routes/search.js";

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    app: "SourceHub API",
    status: "online",
    version: "0.1.0"
  });
});

app.get("/api/health", async (req, res) => {
  try {
    const result = await query("SELECT NOW() AS database_time");
    res.json({
      ok: true,
      database: "connected",
      databaseTime: result.rows[0].database_time
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      ok: false,
      database: "error"
    });
  }
});

app.use("/api/sources", sourcesRouter);
app.use("/api/search", searchRouter);

app.use((req, res) => {
  res.status(404).json({ error: "Rota não encontrada" });
});

app.listen(PORT, () => {
  console.log(`SourceHub API rodando em http://localhost:${PORT}`);
});
