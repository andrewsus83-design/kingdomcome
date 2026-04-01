/**
 * Kingdom Come — AI Content Filter
 *
 * Provides age-appropriate filtering for all AI-generated responses
 * served through the ai-gateway Cloudflare Worker.
 */

// ── Blocklist ────────────────────────────────────────────────────────────────

const BLOCKED_KEYWORDS: string[] = [
  // Violence / harm
  "kill", "murder", "suicide", "self-harm", "abuse", "torture", "gore",
  // Adult / inappropriate
  "sex", "sexual", "porn", "nude", "naked",
  // Drugs / alcohol
  "alcohol", "drunk", "drug", "weed", "marijuana", "cocaine",
  // Profanity (representative sample — extend as needed)
  "damn", "hell", "ass", "crap",
  // Religious antagonism
  "antichrist", "satanic ritual", "occult ritual", "witchcraft",
];

/** Age group 1 = 8-10, 2 = 11-14, 3 = 15-18 */
const BLOCKED_KEYWORDS_AGE_GROUP_1: string[] = [
  ...BLOCKED_KEYWORDS,
  "death", "dying", "war", "fight", "scary", "demon", "devil", "hell",
  "anger", "rage", "violence", "weapon", "gun", "sword",
];

// ── Allowlist topics ─────────────────────────────────────────────────────────

const TOPIC_ALLOWLIST: string[] = [
  "catholic", "faith", "prayer", "saints", "scripture", "church",
  "sacraments", "mass", "eucharist", "baptism", "confirmation", "rosary",
  "bible", "gospel", "apostles", "disciples", "jesus", "mary", "god",
  "holy spirit", "trinity", "advent", "lent", "easter", "christmas",
  "liturgy", "virtue", "love", "kindness", "forgiveness", "mercy",
  "justice", "hope", "charity", "temperance", "prudence", "fortitude",
  "heaven", "angels", "pope", "bishop", "priest", "parish", "diocese",
  "catechism", "creed", "commandments", "beatitudes", "parables",
];

// ── Types ────────────────────────────────────────────────────────────────────

export interface FilterResult {
  safe: boolean;
  filteredText: string;
  reason?: string;
}

// ── Core filter function ─────────────────────────────────────────────────────

/**
 * Filters an AI response for age-appropriateness.
 *
 * @param text      Raw text from the AI model.
 * @param ageGroup  1 = ages 8–10, 2 = ages 11–14, 3 = ages 15–18
 * @returns         FilterResult with safe flag and cleaned text.
 */
export function filterResponse(text: string, ageGroup: 1 | 2 | 3): FilterResult {
  const lowerText = text.toLowerCase();

  // Select blocklist based on age group
  const blocklist =
    ageGroup === 1 ? BLOCKED_KEYWORDS_AGE_GROUP_1 : BLOCKED_KEYWORDS;

  // Check for blocked keywords
  for (const keyword of blocklist) {
    if (lowerText.includes(keyword)) {
      return {
        safe: false,
        filteredText: getAgeAppropriateRefusal(ageGroup),
        reason: `Blocked keyword detected: "${keyword}"`,
      };
    }
  }

  // For the youngest age group, verify topic relevance
  if (ageGroup === 1) {
    const hasAllowedTopic = TOPIC_ALLOWLIST.some((topic) =>
      lowerText.includes(topic)
    );
    if (!hasAllowedTopic && text.length > 100) {
      return {
        safe: false,
        filteredText: getAgeAppropriateRefusal(ageGroup),
        reason: "Response does not contain recognized faith-related topics.",
      };
    }
  }

  // Apply light censoring: redact any stray borderline words rather than
  // rejecting entirely (covers partial matches caught during scanning).
  let filteredText = text;
  for (const keyword of BLOCKED_KEYWORDS) {
    const regex = new RegExp(`\\b${escapeRegex(keyword)}\\b`, "gi");
    filteredText = filteredText.replace(regex, "***");
  }

  return { safe: true, filteredText };
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function getAgeAppropriateRefusal(ageGroup: 1 | 2 | 3): string {
  switch (ageGroup) {
    case 1:
      return (
        "I'm sorry, I can only answer questions about our Catholic faith, " +
        "prayer, and saints. Ask me something about Jesus, Mary, or the Bible!"
      );
    case 2:
      return (
        "I'm not able to answer that question. I'm here to help you learn " +
        "about the Catholic faith, prayer, Scripture, and the saints. " +
        "Try asking me about a saint or a Bible story!"
      );
    case 3:
      return (
        "That topic is outside what I'm designed to discuss. I'm here to " +
        "support your Catholic faith journey — feel free to ask about theology, " +
        "saints, Scripture, Church history, or prayer."
      );
  }
}

function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// ── Request body validation ──────────────────────────────────────────────────

export function validateChatRequest(body: unknown): {
  valid: boolean;
  error?: string;
  message?: string;
  ageGroup?: 1 | 2 | 3;
} {
  if (typeof body !== "object" || body === null) {
    return { valid: false, error: "Request body must be a JSON object." };
  }
  const obj = body as Record<string, unknown>;

  if (typeof obj.message !== "string" || obj.message.trim().length === 0) {
    return { valid: false, error: "Field 'message' must be a non-empty string." };
  }

  const ag = obj.ageGroup;
  if (ag !== 1 && ag !== 2 && ag !== 3) {
    return { valid: false, error: "Field 'ageGroup' must be 1, 2, or 3." };
  }

  return {
    valid: true,
    message: (obj.message as string).trim().slice(0, 2000),
    ageGroup: ag as 1 | 2 | 3,
  };
}
