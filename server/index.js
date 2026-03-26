import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const app = express();
const port = process.env.PORT || 8787;

app.use(cors());
app.use(express.json());

if (!process.env.OPENAI_API_KEY) {
  console.error("Missing OPENAI_API_KEY in server/.env");
  process.exit(1);
}

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

app.post("/session", async (_req, res) => {
  try {
    const sessionConfig = {
      session: {
        type: "realtime",
        model: "gpt-realtime",
        audio: {
          output: {
            voice: "marin",
          },
        },
      },
    };

    const response = await fetch(
      "https://api.openai.com/v1/realtime/client_secrets",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(sessionConfig),
      }
    );

    const data = await response.json();

    if (!response.ok) {
      console.error("OpenAI token error:", data);
      return res.status(response.status).json({
        error: "Failed to create realtime client secret",
        details: data,
      });
    }

    res.json(data);
  } catch (error) {
    console.error("Failed to create realtime client secret:", error);
    res.status(500).json({
      error: "Failed to create realtime client secret",
    });
  }
});

app.listen(port, () => {
  console.log(`Jarvis token server running on http://localhost:${port}`);
});