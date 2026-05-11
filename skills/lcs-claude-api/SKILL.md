---
name: lcs-claude-api
user-invocable: true
description: Build AI-powered apps with the Claude API or Anthropic SDK. Framed for LCS students building study tools, quiz generators, tutoring bots, and other AI-powered school projects. TRIGGER when: code imports `anthropic`/`@anthropic-ai/sdk`/`claude_agent_sdk`, or user asks to use Claude API, Anthropic SDKs, or Agent SDK. DO NOT TRIGGER when: code imports `openai`/other AI SDK, general programming, or ML/data-science tasks.
---

# Claude API -- AI Apps for LCS Students

Call Claude models (Haiku, Sonnet, Opus) from any LCS app or script via the `/api/claude` proxy. Students can build AI-powered study tools, quiz generators, essay feedback bots, flashcard creators, and more -- without managing API keys.

## Why This Exists

Sometimes you need a **deterministic block of code** -- a function, a build step, an app -- to make its own AI request and use the result programmatically. The `/api/claude` proxy lets you pick the right model for the job:

| Model | ID | Input $/M tok | Output $/M tok | Use for |
|-------|----|---------------|----------------|---------|
| **Haiku 4.5** | `claude-haiku-4-5-20251001` | $0.80 | $4.00 | Quick lookups, flashcard generation, classification |
| **Sonnet 4.6** | `claude-sonnet-4-6` | $3.00 | $15.00 | Essay feedback, code generation, structured output |
| **Opus 4.6** | `claude-opus-4-6` | $15.00 | $75.00 | Complex reasoning, research analysis, long context |

## Student Project Ideas

- **Flashcard Generator** -- paste notes, get study flashcards
- **Quiz Builder** -- generate practice questions from a textbook chapter
- **Essay Feedback Bot** -- submit a draft, get constructive feedback
- **Vocabulary Tutor** -- interactive Spanish/French/Latin practice
- **Math Problem Solver** -- step-by-step solutions with explanations
- **Bible Verse Finder** -- search and explain verses by topic
- **Science Lab Report Helper** -- structure and improve lab reports
- **STRIVE Project Advisor** -- get suggestions for engineering projects

## API Reference

### Endpoint

```text
POST /api/claude   (on the app server, port 8770)
```

### Request Body (JSON)

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `model` | string | `claude-haiku-4-5-20251001` | Model ID |
| `messages` | array | *required* | Array of `{role, content}` objects |
| `max_tokens` | number | 1024 | Max output tokens |
| `system` | string | *none* | System prompt |
| `temperature` | number | *API default* | 0.0 - 1.0 |

### Response

Raw Anthropic Messages API response:

```json
{
  "id": "msg_...",
  "model": "claude-haiku-4-5-20251001",
  "content": [{ "type": "text", "text": "..." }],
  "usage": { "input_tokens": 16, "output_tokens": 42 },
  "stop_reason": "end_turn"
}
```

### JavaScript (from an LCS app)

```javascript
// Detect proxy prefix (handles coder proxy URLs and srcdoc iframes)
const API_BASE = (() => {
  let path = location.pathname;
  if (path === '/' || location.href.includes('about:srcdoc')) {
    try { path = parent.location.pathname; } catch {}
  }
  const m = path.match(/^(\/proxy\/\d+)\//);
  return m ? m[1] : '';
})();

async function askClaude(prompt, model = 'claude-haiku-4-5-20251001') {
  const res = await fetch(API_BASE + '/api/claude', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model,
      max_tokens: 1024,
      messages: [{ role: 'user', content: prompt }],
    }),
  });
  const data = await res.json();
  if (data.error) throw new Error(data.error.message || data.error);
  return {
    text: data.content?.[0]?.text || '',
    inputTokens: data.usage?.input_tokens || 0,
    outputTokens: data.usage?.output_tokens || 0,
    model: data.model,
  };
}
```

### Bash / curl (from server-side scripts)

```bash
curl -s http://localhost:8770/api/claude \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-haiku-4-5-20251001",
    "max_tokens": 256,
    "messages": [{"role": "user", "content": "Explain photosynthesis in 3 sentences."}]
  }'
```

### Cost Calculation

```javascript
const PRICING = {
  'claude-opus-4-6':            { input: 15.00, output: 75.00 },
  'claude-sonnet-4-6':          { input:  3.00, output: 15.00 },
  'claude-haiku-4-5-20251001':  { input:  0.80, output:  4.00 },
};

function calcCost(model, inputTok, outputTok) {
  const p = PRICING[model];
  return (inputTok * p.input + outputTok * p.output) / 1_000_000;
}
```

## Architecture

The proxy reads the OAuth access token from `/home/adom/.claude/.credentials.json`, forwards the request to `https://api.anthropic.com/v1/messages`, and returns the raw response. 120-second timeout, CORS enabled. No API keys to manage -- it reuses the Claude Code OAuth token automatically.

## Tips for Students

1. **Start with Haiku** -- it is the cheapest and fastest. Only upgrade to Sonnet/Opus when you need better reasoning.
2. **Use system prompts** -- tell the model what role to play ("You are a patient math tutor for a high school student").
3. **Keep prompts focused** -- one clear question per request gets better answers than a wall of text.
4. **Cache results** -- if your app asks the same question often, save the response locally.
