// ─── WhatsApp guest chatbot ────────────────────────────────────────────────
// Receives incoming WhatsApp messages via webhook and answers hotel guests
// using the Claude API with tool use. Tools: check room availability, get
// prices, send media, request human handoff. Conversation memory per guest is
// stored in MongoDB.
//
// Env vars required (see .env.example):
//   ANTHROPIC_API_KEY        - Claude API key
//   WHATSAPP_TOKEN           - WhatsApp Cloud API access token (shared with invoice sending)
//   WHATSAPP_PHONE_NUMBER_ID - WhatsApp Cloud API phone number ID
//   WHATSAPP_VERIFY_TOKEN    - any secret string; must match the value set in the Meta webhook config
//   PUBLIC_BASE_URL          - public URL of this backend (for media links), e.g. https://...up.railway.app

const Anthropic = require('@anthropic-ai/sdk');
const mongoose = require('mongoose');

const GRAPH_API_VERSION = 'v21.0';
const CLAUDE_MODEL = 'claude-haiku-4-5'; // switch to 'claude-haiku-4-5' for lower cost
const MAX_TOOL_STEPS = 6;
const MAX_HISTORY_TURNS = 20; // persisted conversation turns kept per guest

// ─── Hotel knowledge base ──────────────────────────────────────────────────
// EDIT THIS to keep the bot's answers accurate. Anything not covered here, the
// bot hands off to staff rather than guessing.
const HOTEL_INFO = `
You are the friendly WhatsApp assistant for "The ODON", a hotel in Anuradhapura, Sri Lanka.

CONTACT & LOCATION
- Name: The ODON
- Address: No.10, Akkara 25, Lollugaswewa, Watawandana Rd, Anuradhapura, Sri Lanka
- Phone: +94 74 282 8422
- Email: hoteltheodon@gmail.com

ROOMS
- The hotel has 11 bookable rooms across a Ground floor and an Upper floor.
- Room types and capacity: Double (2 guests), Triple (3 guests), Family (4 guests),
  Family Plus (5 guests).

MEAL PACKAGES
- Full Board (breakfast + lunch + dinner)
- Half Board (breakfast + dinner)
- Bed & Breakfast (breakfast only)
- Room Only (no meals)
- Dinner Only (room + dinner)

STAY INFO
- Check-in time: 2:00 PM. Check-out time: 11:00 AM.
- Late check-out / extra hours are charged at LKR 1,000 per hour.
- There is a swimming pool, open until 8:00 PM.

# TODO (hotel staff): add any other facts guests commonly ask about — Wi-Fi,
# parking, air conditioning, airport transfers, nearby attractions, cancellation
# policy, pet policy, etc. Until then the bot hands those questions to staff.
`;

const SYSTEM_PROMPT = `${HOTEL_INFO}

HOW TO BEHAVE
- You are chatting with a hotel guest on WhatsApp. Be warm, concise and helpful.
  Keep replies short — this is a phone chat, not an email.
- For room PRICES, always call get_room_prices — never quote prices from memory.
- For room AVAILABILITY on specific dates, always call check_room_availability.
- When the guest asks for photos, the rates sheet, or a brochure, call send_media.
- If a guest wants to actually make, change or cancel a booking, has a complaint,
  or asks something you cannot answer from the information above, call
  request_human_handoff — do NOT guess or invent hotel details.
- Never make up prices, policies, or facts not given above or returned by a tool.
- Reply in the same language the guest writes in when you can. Currency is LKR.`;

// ─── Media library ─────────────────────────────────────────────────────────
// Files live in flutter_mongodb_backend/media/ and are served at
// <PUBLIC_BASE_URL>/media/<file>. Drop the real files in and adjust as needed.
const MEDIA = {
  rates_pdf:    { type: 'document', file: 'rates.pdf',  caption: 'Our current rates' },
  room_photos:  { type: 'image',    file: 'rooms.jpg',  caption: 'Our rooms' },
  hotel_photos: { type: 'image',    file: 'hotel.jpg',  caption: 'The ODON' },
  pool_photo:   { type: 'image',    file: 'pool.jpg',   caption: 'Our swimming pool' },
};

// ─── Tool definitions (static — cached with the system prompt) ──────────────
const TOOLS = [
  {
    name: 'check_room_availability',
    description:
      'Check how many rooms are free for a date range. Use whenever a guest asks if rooms are available for specific dates.',
    input_schema: {
      type: 'object',
      properties: {
        check_in: { type: 'string', description: 'Check-in date, YYYY-MM-DD' },
        check_out: { type: 'string', description: 'Check-out date, YYYY-MM-DD' },
      },
      required: ['check_in', 'check_out'],
    },
  },
  {
    name: 'get_room_prices',
    description:
      "Get the hotel's current room prices for every package and room type. Use whenever a guest asks about prices or rates.",
    input_schema: { type: 'object', properties: {} },
  },
  {
    name: 'send_media',
    description:
      'Send the guest a photo or document on WhatsApp. Use when the guest asks to see photos, the rates sheet, or a brochure.',
    input_schema: {
      type: 'object',
      properties: {
        media_key: {
          type: 'string',
          enum: Object.keys(MEDIA),
          description: 'Which media item to send.',
        },
      },
      required: ['media_key'],
    },
  },
  {
    name: 'request_human_handoff',
    description:
      'Flag the conversation for hotel staff to follow up. Use for actual booking requests, changes, cancellations, complaints, or anything you cannot answer.',
    input_schema: {
      type: 'object',
      properties: {
        reason: { type: 'string', description: 'Short summary of what the guest needs.' },
      },
      required: ['reason'],
    },
  },
];

// ─── Conversation memory ───────────────────────────────────────────────────
const conversationSchema = new mongoose.Schema(
  {
    phone: { type: String, required: true, unique: true, index: true },
    messages: [{ role: String, content: String, _id: false }],
    needsHumanFollowup: { type: Boolean, default: false },
  },
  { timestamps: true }
);
const Conversation =
  mongoose.models.WhatsappConversation ||
  mongoose.model('WhatsappConversation', conversationSchema);

// ─── WhatsApp Cloud API senders ────────────────────────────────────────────
async function waPost(payload) {
  const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;
  const token = process.env.WHATSAPP_TOKEN;
  const resp = await fetch(
    `https://graph.facebook.com/${GRAPH_API_VERSION}/${phoneNumberId}/messages`,
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ messaging_product: 'whatsapp', ...payload }),
    }
  );
  if (!resp.ok) console.error('WhatsApp send failed:', await resp.text());
  return resp;
}

function sendWhatsAppText(to, text) {
  return waPost({ to, type: 'text', text: { body: String(text).slice(0, 4000) } });
}

function sendWhatsAppMedia(to, mediaKey) {
  const item = MEDIA[mediaKey];
  if (!item) return Promise.resolve();
  const base = (process.env.PUBLIC_BASE_URL || '').replace(/\/$/, '');
  const link = `${base}/media/${item.file}`;
  if (item.type === 'document') {
    return waPost({
      to,
      type: 'document',
      document: { link, caption: item.caption, filename: item.file },
    });
  }
  return waPost({ to, type: 'image', image: { link, caption: item.caption } });
}

// ─── Tools ─────────────────────────────────────────────────────────────────
async function checkAvailability(checkIn, checkOut) {
  try {
    const Booking = mongoose.model('Booking');
    const RoomConfig = mongoose.model('RoomConfig');
    const ci = new Date(checkIn);
    const co = new Date(checkOut);
    if (isNaN(ci.getTime()) || isNaN(co.getTime()) || co <= ci) {
      return 'Invalid dates. Ask the guest for a valid check-in and check-out date.';
    }
    const config = await RoomConfig.findOne();
    const rooms = config && Array.isArray(config.rooms) ? config.rooms : [];
    const totalRooms = rooms.filter((r) => !r.isBlocked).length;

    const bookings = await Booking.find({ checkIn: { $lt: co }, checkOut: { $gt: ci } });
    const booked = new Set();
    for (const b of bookings) {
      if (Array.isArray(b.rooms) && b.rooms.length) {
        for (const r of b.rooms) booked.add(String(r.roomNumber));
      } else if (b.roomNumber) {
        booked.add(String(b.roomNumber));
      }
    }
    const free = Math.max(0, totalRooms - booked.size);
    return `For ${checkIn} to ${checkOut}: ${free} of ${totalRooms} rooms are free (${booked.size} already booked). This is an estimate — staff confirm the final booking.`;
  } catch (e) {
    console.error('checkAvailability failed:', e);
    return 'Could not check availability right now — suggest the guest contact staff.';
  }
}

async function getPrices() {
  try {
    const PriceConfig = mongoose.model('PriceConfig');
    const cfg = await PriceConfig.findOne();
    if (!cfg || !cfg.packages) return 'Prices are not available right now — ask staff.';
    const lines = [];
    for (const pkg of Object.keys(cfg.packages)) {
      const roomPrices = cfg.packages[pkg] || {};
      const parts = Object.keys(roomPrices).map((rt) => `${rt} LKR ${roomPrices[rt]}`);
      lines.push(`${pkg}: ${parts.join(', ')}`);
    }
    if (cfg.driverRoomPrice != null) lines.push(`Driver room: LKR ${cfg.driverRoomPrice}/night`);
    return 'Current prices, per room per night:\n' + lines.join('\n');
  } catch (e) {
    console.error('getPrices failed:', e);
    return 'Could not fetch prices right now — suggest the guest contact staff.';
  }
}

async function executeTool(name, input, conv, to) {
  if (name === 'check_room_availability') {
    return checkAvailability(input.check_in, input.check_out);
  }
  if (name === 'get_room_prices') {
    return getPrices();
  }
  if (name === 'send_media') {
    if (!process.env.PUBLIC_BASE_URL) {
      return 'Media sending is not configured — tell the guest a staff member will send it.';
    }
    if (!MEDIA[input.media_key]) return 'That media item does not exist.';
    await sendWhatsAppMedia(to, input.media_key);
    return `The "${input.media_key}" has been sent to the guest on WhatsApp.`;
  }
  if (name === 'request_human_handoff') {
    conv.needsHumanFollowup = true;
    console.log(`[whatsapp-bot] Human handoff for ${conv.phone}: ${input.reason || ''}`);
    return 'Hotel staff have been notified and will follow up with the guest shortly.';
  }
  return 'Unknown tool.';
}

// ─── Claude agent loop ─────────────────────────────────────────────────────
async function runAgent(messages, to, conv) {
  const client = new Anthropic(); // reads ANTHROPIC_API_KEY

  for (let step = 0; step < MAX_TOOL_STEPS; step++) {
    const response = await client.messages.create({
      model: CLAUDE_MODEL,
      max_tokens: 1024,
      output_config: { effort: 'low' },
      system: [{ type: 'text', text: SYSTEM_PROMPT, cache_control: { type: 'ephemeral' } }],
      tools: TOOLS,
      messages,
    });

    messages.push({ role: 'assistant', content: response.content });

    if (response.stop_reason !== 'tool_use') {
      const text = response.content
        .filter((b) => b.type === 'text')
        .map((b) => b.text)
        .join('\n')
        .trim();
      return text || 'Sorry, I did not quite catch that — could you rephrase?';
    }

    const toolResults = [];
    for (const block of response.content) {
      if (block.type !== 'tool_use') continue;
      let result;
      try {
        result = await executeTool(block.name, block.input || {}, conv, to);
      } catch (e) {
        console.error('tool execution failed:', e);
        result = 'That action failed — tell the guest a staff member will help.';
      }
      toolResults.push({
        type: 'tool_result',
        tool_use_id: block.id,
        content: String(result),
      });
    }
    messages.push({ role: 'user', content: toolResults });
  }

  return 'Let me get a staff member to help you with that — they will follow up shortly.';
}

// ─── Webhook handlers ──────────────────────────────────────────────────────

// GET /whatsapp/webhook — Meta's verification handshake.
function verifyWebhook(req, res) {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];
  if (mode === 'subscribe' && token && token === process.env.WHATSAPP_VERIFY_TOKEN) {
    return res.status(200).send(challenge);
  }
  return res.sendStatus(403);
}

const processedMessageIds = new Set();

// POST /whatsapp/webhook — incoming guest messages.
async function handleIncomingMessage(req, res) {
  // WhatsApp requires a fast 200 — acknowledge before doing any work.
  res.sendStatus(200);

  try {
    const value =
      req.body &&
      req.body.entry &&
      req.body.entry[0] &&
      req.body.entry[0].changes &&
      req.body.entry[0].changes[0] &&
      req.body.entry[0].changes[0].value;
    const message = value && value.messages && value.messages[0];
    if (!message) return; // delivery/read status update — ignore

    if (processedMessageIds.has(message.id)) return; // dedupe retries
    processedMessageIds.add(message.id);
    if (processedMessageIds.size > 1000) processedMessageIds.clear();

    const from = message.from;
    if (message.type !== 'text') {
      await sendWhatsAppText(
        from,
        'Hi! Please send your question as a text message and I will be happy to help. 😊'
      );
      return;
    }
    const text = message.text && message.text.body;
    if (!text || !text.trim()) return;

    if (!process.env.ANTHROPIC_API_KEY) {
      console.error('[whatsapp-bot] ANTHROPIC_API_KEY not set');
      await sendWhatsAppText(
        from,
        'Sorry, our assistant is unavailable right now. Please call us on +94 74 282 8422.'
      );
      return;
    }

    let conv = await Conversation.findOne({ phone: from });
    if (!conv) conv = new Conversation({ phone: from, messages: [] });

    // Persisted history is plain text turns only — tool round-trips stay local.
    const history = conv.messages.map((m) => ({ role: m.role, content: m.content }));
    const userTurn = { role: 'user', content: text.trim() };

    const reply = await runAgent([...history, userTurn], from, conv);

    let turns = [...history, userTurn, { role: 'assistant', content: reply }];
    if (turns.length > MAX_HISTORY_TURNS) turns = turns.slice(-MAX_HISTORY_TURNS);
    conv.messages = turns;
    await conv.save();

    await sendWhatsAppText(from, reply);
  } catch (e) {
    console.error('[whatsapp-bot] handleIncomingMessage failed:', e);
  }
}

module.exports = { verifyWebhook, handleIncomingMessage };
