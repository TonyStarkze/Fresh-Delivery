/**
 * Unified Cloudflare Worker Proxy for AI Generation
 * Powered by Cloudflare Native Workers AI (Images) and Gemini (Text)
 * 
 * SETUP INSTRUCTIONS:
 * 1. Go to your Cloudflare Worker -> Settings -> Bindings.
 * 2. Click "Add Binding" -> "AI".
 * 3. Set the Variable Name to: AI
 * 4. Ensure you still have the GEMINI_API_KEY Secret in Settings -> Variables.
 * 5. Deploy this code.
 */

export default {
  async fetch(request, env, ctx) {
    // Handle CORS Preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    try {
      const body = await request.json();
      const task = body.task || "image"; 

      // Common Validation
      const prompt = body.prompt;
      if (!prompt || prompt.length < 3) {
        return new Response(JSON.stringify({ error: "Prompt is too short" }), {
          status: 400,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      // --- TASK: IMAGE (Cloudflare Native AI) ---
      if (task === "image") {
        console.log(`Generating native AI image for: ${prompt}`);
        
        // Correct Model ID for XL-Lightning
        const response = await env.AI.run(
          "@cf/bytedance/stable-diffusion-xl-lightning",
          { prompt: prompt }
        );

        return new Response(response, {
          headers: {
            "Content-Type": "image/png",
            "Access-Control-Allow-Origin": "*",
            "Cache-Control": "public, max-age=86400",
          },
        });
      }

      // --- TASK: TEXT (Gemini with Cloudflare Native Fallback) ---
      if (task === "text") {
        const models = ["gemini-2.5-flash", "gemini-1.5-flash", "gemini-1.5-flash-latest"];
        
        // 1. Try Gemini Models first
        for (const model of models) {
          try {
            const GEMINI_URL = `https://generativelanguage.googleapis.com/v1/models/${model}:generateContent?key=${env.GEMINI_API_KEY}`;
            const geminiResponse = await fetch(GEMINI_URL, {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }]
              }),
            });

            if (geminiResponse.ok) {
              const data = await geminiResponse.json();
              const generatedText = data.candidates?.[0]?.content?.parts?.[0]?.text || "No text generated.";
              return new Response(JSON.stringify({ text: generatedText }), {
                headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
              });
            }
          } catch (e) {
            console.error(`Gemini model ${model} failed: ${e.message}`);
          }
        }

        // 2. ULTIMATE FALLBACK: Cloudflare Native LLM (Llama 3)
        // This ensures the service NEVER fails even if Google quotas are hit.
        console.log("Gemini quotas exceeded. Falling back to Cloudflare Native AI (Llama 3)...");
        try {
          const cloudflareAiResponse = await env.AI.run('@cf/meta/llama-3-8b-instruct', {
            messages: [
              { role: 'system', content: 'You are a professional chef. Write a short, single-sentence, appetizing description for the food item requested. Do not include price or unit.' },
              { role: 'user', content: prompt }
            ],
            max_tokens: 100
          });

          return new Response(JSON.stringify({ text: cloudflareAiResponse.response }), {
            headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
          });
        } catch (err) {
          return new Response(JSON.stringify({ error: "All AI Services Busy", details: err.message }), {
            status: 500,
            headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
          });
        }
      }

      return new Response(JSON.stringify({ error: "Unknown task type" }), {
        status: 400,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });

    } catch (err) {
      console.error(`Worker Error: ${err.message}`);
      return new Response(JSON.stringify({ error: "Server Error", message: err.message }), {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }
  },
};
